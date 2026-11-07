-- Guildloom: Recipes (collect your learned recipes, share them, search everyone's)
--
-- Your recipes are read whenever you open one of your profession windows.
-- Sharing is cheap: everyone broadcasts a short fingerprint per profession,
-- and the full list is only sent when someone's copy is missing or outdated.
--   H#Alchemy=12-3f9a;Mining=4-77     fingerprints of my recipe lists
--   RQ#Name#Alchemy                    "Name, please send your Alchemy list"
--   RC#Alchemy#1#3#id,id,id,...        chunk 1 of 3 of a recipe list
local ADDON, ns = ...

local floor = math.floor
local B36 = "0123456789abcdefghijklmnopqrstuvwxyz"
local CHUNK = 200
local nameCache = {}

local function ToB36(n)
    n = floor(n)
    if n <= 0 then return "0" end
    local s = ""
    while n > 0 do
        local d = n % 36
        s = B36:sub(d + 1, d + 1) .. s
        n = floor(n / 36)
    end
    return s
end

local function Hash(ids)
    local sum = 0
    for _, id in ipairs(ids) do
        if type(id) == "number" then
            sum = (sum + id * 7 + 13) % 1000000007
        else
            for i = 1, #id do sum = (sum * 31 + id:byte(i)) % 1000000007 end
        end
    end
    return #ids .. "-" .. ToB36(sum)
end

function ns.GetRecipeData()
    local k = ns.GuildKey()
    if not k or not ns.db then return {} end
    ns.db.recipes = ns.db.recipes or {}
    ns.db.recipes[k] = ns.db.recipes[k] or {}
    return ns.db.recipes[k]
end

-- Recipe IDs are spell IDs on the modern client; the classic fallback stores names.
function ns.RecipeName(id)
    if type(id) == "string" then return id end
    local n = nameCache[id]
    if n then return n end
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
        local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, id)
        if ok and info and info.name and info.name ~= "" then n = info.name end
    end
    if not n and C_Spell and C_Spell.GetSpellName then n = C_Spell.GetSpellName(id) end
    if not n and GetSpellInfo then n = (GetSpellInfo(id)) end
    if n then nameCache[id] = n end
    return n
end

-- Strip an item link down to its name, lowercase, trimmed.
function ns.SearchKey(text)
    local q = (text or ""):match("%[(.-)%]") or text or ""
    q = q:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    q = q:lower():gsub("^%s+", ""):gsub("%s+$", "")
    return q
end

---------------------------------------------------------------------------
-- Collecting my own recipes
---------------------------------------------------------------------------
local function CurrentProfession()
    local T = C_TradeSkillUI
    if not T then return nil end
    -- Ignore other people's linked/guild/NPC crafting windows.
    for _, fn in ipairs({ "IsTradeSkillLinked", "IsTradeSkillGuild", "IsNPCCrafting" }) do
        if T[fn] then
            local ok, v = pcall(T[fn])
            if ok and v then return nil end
        end
    end
    if T.GetBaseProfessionInfo then
        local ok, info = pcall(T.GetBaseProfessionInfo)
        if ok and info and info.professionName and info.professionName ~= "" then return info.professionName end
    end
    if T.GetTradeSkillLine then
        local ok, _, name = pcall(T.GetTradeSkillLine)
        if ok and name and name ~= "" then return name end
    end
end

local function CollectMine()
    if not IsInGuild() then return end
    local prof, ids = nil, {}

    if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs then
        prof = CurrentProfession()
        if prof then
            for _, id in ipairs(C_TradeSkillUI.GetAllRecipeIDs() or {}) do
                local info = C_TradeSkillUI.GetRecipeInfo(id)
                if info and info.learned then
                    ids[#ids + 1] = id
                    if info.name then nameCache[id] = info.name end
                end
            end
        end
    elseif GetNumTradeSkills and GetTradeSkillLine and GetTradeSkillInfo then
        prof = GetTradeSkillLine()
        for i = 1, GetNumTradeSkills() or 0 do
            local name, kind = GetTradeSkillInfo(i)
            if name and kind ~= "header" and kind ~= "subheader" then ids[#ids + 1] = name end
        end
    end
    if not prof or prof == "" or prof == "UNKNOWN" or #ids == 0 then return end

    table.sort(ids)
    local me = ns.MyName()
    local data = ns.GetRecipeData()
    data[me] = data[me] or {}
    local h = Hash(ids)
    if data[me][prof] and data[me][prof].h == h then return end
    data[me][prof] = { h = h, ids = ids, t = time() }
    ns.BroadcastRecipeHashes()
    if ns.RefreshUI then ns.RefreshUI() end
    if ns.UpdateBadge then ns.UpdateBadge() end
end

function ns.BroadcastRecipeHashes()
    local mine = ns.GetRecipeData()[ns.MyName()]
    if not mine then return end
    local parts = {}
    for prof, e in pairs(mine) do parts[#parts + 1] = prof .. "=" .. e.h end
    if #parts > 0 then ns.Send("H#" .. table.concat(parts, ";")) end
end

local lastSent = {}
local function SendRecipes(prof)
    local mine = ns.GetRecipeData()[ns.MyName()]
    local e = mine and mine[prof]
    if not e then return end
    if GetTime() - (lastSent[prof] or -999) < 30 then return end
    lastSent[prof] = GetTime()

    local chunks, cur = {}, {}
    local len = 0
    for _, id in ipairs(e.ids) do
        local tok = type(id) == "number" and ToB36(id) or ("~" .. id:gsub("[,#]", ""))
        if len + #tok + 1 > CHUNK and #cur > 0 then
            chunks[#chunks + 1] = table.concat(cur, ",")
            cur, len = {}, 0
        end
        cur[#cur + 1] = tok
        len = len + #tok + 1
    end
    if #cur > 0 then chunks[#chunks + 1] = table.concat(cur, ",") end
    for i, c in ipairs(chunks) do
        ns.SendQueued(("RC#%s#%d#%d#%s"):format(prof, i, #chunks, c))
    end
end

---------------------------------------------------------------------------
-- Incoming messages
---------------------------------------------------------------------------
local scheduledAt, seenReq = {}, {}

ns.comm.H = function(sender, body)
    local have = ns.GetRecipeData()[sender]
    local short = ns.Short(sender)
    for prof, h in body:gmatch("([^=;]+)=([^;]+)") do
        local cur = have and have[prof]
        if not cur or cur.h ~= h then
            local key = short .. "#" .. prof
            if GetTime() - (scheduledAt[key] or -999) > 60 then
                local at = GetTime()
                scheduledAt[key] = at
                -- Random delay: if someone else asks first, everyone gets the list anyway.
                C_Timer.After(1 + math.random() * 5, function()
                    if (seenReq[key] or 0) > at then return end
                    ns.Send(("RQ#%s#%s"):format(short, prof))
                end)
            end
        end
    end
end

ns.comm.RQ = function(_, body)
    local target, prof = body:match("^([^#]+)#(.+)$")
    if not target then return end
    seenReq[target .. "#" .. prof] = GetTime()
    if target == UnitName("player") then
        C_Timer.After(0.5 + math.random(), function() SendRecipes(prof) end)
    end
end

local buffers = {}
ns.comm.RC = function(sender, body)
    local prof, seq, total, payload = body:match("^([^#]+)#(%d+)#(%d+)#(.*)$")
    if not prof then return end
    seq, total = tonumber(seq), tonumber(total)
    local key = sender .. "#" .. prof
    local b = buffers[key]
    if seq == 1 or not b or b.total ~= total then
        b = { total = total, parts = {}, n = 0 }
        buffers[key] = b
    end
    if not b.parts[seq] then
        b.parts[seq] = payload
        b.n = b.n + 1
    end
    if b.n < b.total then return end
    buffers[key] = nil

    local ids = {}
    for i = 1, b.total do
        for tok in (b.parts[i] or ""):gmatch("[^,]+") do
            if tok:sub(1, 1) == "~" then
                ids[#ids + 1] = tok:sub(2)
            else
                ids[#ids + 1] = tonumber(tok, 36)
            end
        end
    end
    local data = ns.GetRecipeData()
    data[sender] = data[sender] or {}
    data[sender][prof] = { h = Hash(ids), ids = ids, t = time() }
    ns.Debounce("reciperefresh", 1, function()
        if ns.RefreshUI then ns.RefreshUI() end
    end)
end

---------------------------------------------------------------------------
-- Search
---------------------------------------------------------------------------
-- All roster members whose shared recipes contain the search text.
function ns.SearchRecipes(q, limit)
    local res = {}
    if not q or #q < 3 then return res end
    local rdata = ns.GetRecipeData()
    for _, m in ipairs(ns.members) do
        local rd = rdata[m.name]
        if rd then
            for prof, e in pairs(rd) do
                for _, id in ipairs(e.ids) do
                    local n = ns.RecipeName(id)
                    if n and n:lower():find(q, 1, true) then
                        res[#res + 1] = { m = m, recipe = n, prof = prof }
                        if #res >= limit then return res end
                    end
                end
            end
        end
    end
    return res
end

local function OnlineFirst(a, b)
    local ma, mb = a.m or a, b.m or b
    if ma.online ~= mb.online then return ma.online end
    return ma.short < mb.short
end

-- Who can make this? Returns members with a matching recipe, and (if a
-- profession is given) members who have the profession but no recipe data.
function ns.FindCrafters(text, prof)
    local q = ns.SearchKey(text)
    local crafters, haveProf = {}, {}
    if #q < 3 then return crafters, haveProf, q end
    local rdata, pdata = ns.GetRecipeData(), ns.GetProfData()
    for _, m in ipairs(ns.members) do
        local found
        local rd = rdata[m.name]
        if rd then
            for p, e in pairs(rd) do
                if not prof or prof == "" or p == prof then
                    for _, id in ipairs(e.ids) do
                        local n = ns.RecipeName(id)
                        if n and n:lower():find(q, 1, true) then found = n; break end
                    end
                end
                if found then break end
            end
        end
        if found then
            crafters[#crafters + 1] = { m = m, recipe = found }
        elseif prof and prof ~= "" and not (rd and rd[prof]) then
            local e = pdata[m.name]
            if e and e.list then
                for _, p in ipairs(e.list) do
                    if p.n == prof then haveProf[#haveProf + 1] = m; break end
                end
            end
        end
    end
    table.sort(crafters, OnlineFirst)
    table.sort(haveProf, OnlineFirst)
    return crafters, haveProf, q
end

-- Do I have a recipe matching this text? (fast path: only my own data)
function ns.ICanCraft(text, prof)
    local q = ns.SearchKey(text)
    local mine = ns.GetRecipeData()[ns.MyName()]
    if mine and #q >= 3 then
        for p, e in pairs(mine) do
            if not prof or prof == "" or p == prof then
                for _, id in ipairs(e.ids) do
                    local n = ns.RecipeName(id)
                    if n and n:lower():find(q, 1, true) then return true, n end
                end
            end
        end
    end
    -- Fall back to "I have that profession" when I haven't opened it yet.
    if prof and prof ~= "" and not (mine and mine[prof]) then
        local list = ns.GetMemberProfs(ns.MyName())
        for _, p in ipairs(list or {}) do
            if p.n == prof then return true end
        end
    end
    return false
end

function ns.RecipeCoverage()
    local n, rdata = 0, ns.GetRecipeData()
    for _, m in ipairs(ns.members) do
        if rdata[m.name] and next(rdata[m.name]) then n = n + 1 end
    end
    return n
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
for _, e in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED",
                     "NEW_RECIPE_LEARNED", "TRADE_SKILL_UPDATE", "PLAYER_ENTERING_WORLD" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event, isLogin, isReload)
    if event == "PLAYER_ENTERING_WORLD" then
        if isLogin or isReload then C_Timer.After(9, ns.BroadcastRecipeHashes) end
        return
    end
    ns.Debounce("collectRecipes", 1.5, CollectMine)
end)
