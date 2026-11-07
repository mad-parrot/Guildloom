-- Guildloom: Core (roster data, profession data, guild sync)
local ADDON, ns = ...

local PREFIX = "Guildloom"
local min = math.min
local MAX_MSG = 250

ns.members = {}   -- array of member tables
ns.byName  = {}   -- [Name-Realm] = member
ns.ranks   = {}   -- [rankIndex] = rank name (0 = Guild Master)
ns.comm    = {}   -- [messageKind] = function(sender, body), filled by modules

local DEFAULTS = {
    tab        = "ranks",
    inactiveDays   = 30,
    hideActiveAlts = true,
    noticeAutoShow = true,   -- pop the notices window open on important alerts
    noticeChat     = false,  -- also echo alerts into the chat window
    noticeSound    = true,
    noticeSoundKey = "whisper", -- see SOUNDS in Requests.lua, or "lsm:<name>"
    skin       = "blizzard",
    scale      = 1,
    opacity    = 0.97,
    onlineOnly = false,
    sort       = 1,
    collapsed  = {},
    profs      = {},     -- [guildKey][Name-Realm] = { t = time, src = "self"|"sync"|"guild", list = {...} }
}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
function ns.Print(...)
    print("|cff4fc3f7Guildloom|r:", ...)
end

local realmCache
local function MyRealm()
    if not realmCache then
        local r = GetNormalizedRealmName and GetNormalizedRealmName()
        if r and r ~= "" then realmCache = r end
        return r or (GetRealmName() or ""):gsub("[%s%-]", "")
    end
    return realmCache
end

function ns.FullName(name)
    if not name or name == "" then return nil end
    if name:find("-", 1, true) then return name end
    return name .. "-" .. MyRealm()
end

function ns.MyName()
    return ns.FullName(UnitName("player"))
end

-- Character name without the realm part.
function ns.Short(full)
    return full and (full:match("^([^%-]+)") or full) or "?"
end

local timers = {}
function ns.Debounce(key, delay, fn)
    if timers[key] then return end
    timers[key] = true
    C_Timer.After(delay, function()
        timers[key] = nil
        fn()
    end)
end

local function Refresh()
    if ns.RefreshUI then ns.RefreshUI() end
end

---------------------------------------------------------------------------
-- Roster
---------------------------------------------------------------------------
function ns.RequestRoster()
    if not IsInGuild() then return end
    if C_GuildInfo and C_GuildInfo.GuildRoster then
        C_GuildInfo.GuildRoster()
    elseif GuildRoster then
        GuildRoster()
    end
end

function ns.ScanRoster()
    wipe(ns.members); wipe(ns.byName); wipe(ns.ranks)
    if not IsInGuild() then return end

    local numRanks = GuildControlGetNumRanks and GuildControlGetNumRanks() or 0
    for i = 1, numRanks do
        ns.ranks[i - 1] = GuildControlGetRankName(i)
    end

    local total = GetNumGuildMembers() or 0
    for i = 1, total do
        local name, rankName, rankIndex, level, classDisplay, zone, note, officerNote,
              online, status, classFile, _, _, isMobile = GetGuildRosterInfo(i)
        if name then
            local full = ns.FullName(name)
            local charName, realm = full:match("^(.-)%-(.+)$")
            local m = {
                name      = full,
                short     = charName or full,   -- display name, realm stripped
                realm     = realm,
                rank      = rankName or "?",
                rankIndex = rankIndex or 0,
                level     = level or 0,
                class     = classDisplay,
                classFile = classFile,
                zone      = zone,
                note      = note or "",
                onote     = officerNote or "",
                online    = online and true or false,
                mobile    = isMobile and true or false,
                status    = status,
                lastOnline = 0, -- hours since last online
            }
            if not m.online and GetGuildRosterLastOnline then
                local y, mo, d, h = GetGuildRosterLastOnline(i)
                m.lastOnline = (((y or 0) * 365 + (mo or 0) * 30 + (d or 0)) * 24) + (h or 0)
            end
            ns.members[#ns.members + 1] = m
            ns.byName[full] = m
            if ns.ranks[m.rankIndex] == nil then ns.ranks[m.rankIndex] = m.rank end
        end
    end
    if ns.RebuildAlts then ns.RebuildAlts() end
end

function ns.GuildName()
    return (GetGuildInfo("player"))
end

---------------------------------------------------------------------------
-- Profession storage
---------------------------------------------------------------------------
function ns.GuildKey()
    local g, _, _, gRealm = GetGuildInfo("player")
    if not g then return nil end
    return g .. "-" .. (gRealm or MyRealm() or "")
end

function ns.GetProfData()
    local k = ns.GuildKey()
    if not k or not ns.db then return {} end -- throwaway table: nothing is saved without a guild
    ns.db.profs[k] = ns.db.profs[k] or {}
    return ns.db.profs[k]
end

function ns.GetMemberProfs(full)
    local e = ns.GetProfData()[full]
    return e and e.list
end

---------------------------------------------------------------------------
-- Own professions
---------------------------------------------------------------------------
local PROF_HEADERS = {
    ["Professions"] = true, ["Secondary Skills"] = true,
}
if TRADE_SKILLS then PROF_HEADERS[TRADE_SKILLS] = true end
if SECONDARY_SKILLS then PROF_HEADERS[SECONDARY_SKILLS] = true end

local function CollectOwnProfessions()
    local list = {}

    -- Mainline-style API (Forever runs on the modern client)
    if GetProfessions and GetProfessionInfo then
        local a, b, c, d, e = GetProfessions()
        for _, idx in ipairs({ a or 0, b or 0, c or 0, d or 0, e or 0 }) do
            if idx ~= 0 then
                local name, icon, rank, maxRank, _, _, skillLine = GetProfessionInfo(idx)
                if name then
                    list[#list + 1] = { n = name, s = rank or 0, m = maxRank or 0, i = icon, id = skillLine or 0 }
                end
            end
        end
    end

    -- Classic-style skill list fallback
    if #list == 0 and GetNumSkillLines and GetSkillLineInfo then
        local inProf = false
        for i = 1, GetNumSkillLines() do
            local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
            if isHeader then
                inProf = PROF_HEADERS[name] or false
            elseif inProf and name then
                list[#list + 1] = { n = name, s = rank or 0, m = maxRank or 0, id = 0 }
            end
        end
    end
    return list
end

---------------------------------------------------------------------------
-- Guild sync (addon messages)
--   P#id,skill,max,icon,name;id,skill,max,icon,name   -> my professions
--   R#                                                 -> request everyone's professions
---------------------------------------------------------------------------
local function Send(msg)
    if not IsInGuild() then return end
    pcall(function()
        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage(PREFIX, msg, "GUILD")
        elseif SendAddonMessage then
            SendAddonMessage(PREFIX, msg, "GUILD")
        end
    end)
end
ns.Send = Send

-- Bulk messages (recipe lists, request sync) go through a queue so we stay
-- under the client's addon-message throttle (~1 message per second sustained).
local queue, pumping = {}, false
local function Pump()
    if #queue == 0 then pumping = false; return end
    Send(table.remove(queue, 1))
    C_Timer.After(1.1, Pump)
end
function ns.SendQueued(msg)
    queue[#queue + 1] = msg
    if not pumping then
        pumping = true
        Pump()
    end
end

local function Encode(list)
    local msg = "P#"
    local first = true
    for _, p in ipairs(list) do
        local chunk = table.concat({
            p.id or 0, p.s or 0, p.m or 0, tostring(p.i or 0):gsub("[,;#]", ""),
            (p.n:gsub("[,;#]", "")),
        }, ",")
        local add = (first and "" or ";") .. chunk
        if #msg + #add > MAX_MSG then break end
        msg = msg .. add
        first = false
    end
    return msg
end

local function Decode(body)
    local list = {}
    for chunk in body:gmatch("[^;]+") do
        local id, s, m, i, n = chunk:match("^(%d+),(%d+),(%d+),([^,]*),(.+)$")
        if n then
            local icon = tonumber(i) or ((i ~= "" and i ~= "0") and i or nil)
            if icon == 0 then icon = nil end
            list[#list + 1] = { id = tonumber(id), s = tonumber(s) or 0, m = tonumber(m) or 0, i = icon, n = n }
        end
    end
    return list
end

local lastSent
function ns.UpdateOwn(force)
    if not IsInGuild() then return end
    local list = CollectOwnProfessions()
    if #list == 0 then return end
    ns.GetProfData()[ns.MyName()] = { t = time(), src = "self", list = list }
    local msg = Encode(list)
    if force or msg ~= lastSent then
        Send(msg)
        lastSent = msg
    end
    Refresh()
end

local lastReq = 0
function ns.RequestSync()
    if not IsInGuild() then return end
    if GetTime() - lastReq < 15 then return end
    lastReq = GetTime()
    Send("R#")
    if ns.RefreshGuildTradeSkills then ns.RefreshGuildTradeSkills() end
end

---------------------------------------------------------------------------
-- Built-in guild profession directory (if the client exposes it)
---------------------------------------------------------------------------
function ns.ScanGuildTradeSkills()
    if not (GetNumGuildTradeSkill and GetGuildTradeSkillInfo) then return end
    local ok, err = pcall(function()
        local n = GetNumGuildTradeSkill() or 0
        for i = 1, n do
            local skillID, isCollapsed, _, headerName = GetGuildTradeSkillInfo(i)
            if headerName and isCollapsed and ExpandGuildTradeSkillHeader then
                ExpandGuildTradeSkillHeader(skillID) -- fires GUILD_TRADESKILL_UPDATE again
            end
        end

        local found = {}
        local counts = {}
        local curName, curIcon, curID
        n = GetNumGuildTradeSkill() or 0
        for i = 1, n do
            local skillID, _, icon, headerName, _, _, numPlayers, playerName, playerFull, _, _, _, skill = GetGuildTradeSkillInfo(i)
            if headerName then
                if headerName:find("[DNT]", 1, true) then
                    curName = nil -- Blizzard test entries
                else
                    curName, curIcon, curID = headerName, icon, skillID
                    counts[headerName] = { count = numPlayers or 0, icon = icon, id = skillID }
                end
            elseif playerName and curName then
                local full = ns.FullName(playerFull or playerName)
                found[full] = found[full] or {}
                table.insert(found[full], { n = curName, s = skill or 0, m = 0, i = curIcon, id = curID or 0 })
            end
        end

        if next(counts) and ns.db then
            local k = ns.GuildKey()
            if k then
                ns.db.profCounts = ns.db.profCounts or {}
                ns.db.profCounts[k] = counts
            end
        end

        local data = ns.GetProfData()
        for full, list in pairs(found) do
            local e = data[full]
            -- Addon-shared data is more detailed (has max skill); keep it if present.
            if not e or e.src == "guild" then
                data[full] = { t = time(), src = "guild", list = list }
            end
        end
    end)
    if not ok then ns.guildTradeSkillError = tostring(err) end
end

-- Ask the server for the directory, then read it (don't rely only on the event).
local lastQuery = 0
function ns.GetProfCounts()
    local k = ns.GuildKey()
    return (k and ns.db and ns.db.profCounts and ns.db.profCounts[k]) or {}
end

function ns.RefreshGuildTradeSkills()
    if not IsInGuild() then return end
    ns.ScanGuildTradeSkills()
    if not QueryGuildRecipes or GetTime() - lastQuery < 10 then return end
    lastQuery = GetTime()

    -- The directory normally lists online members only. Try temporarily
    -- enabling "show offline" for the query, then put the setting back.
    local restore = false
    if GetGuildRosterShowOffline and SetGuildRosterShowOffline and not GetGuildRosterShowOffline() then
        SetGuildRosterShowOffline(true)
        restore = true
    end
    pcall(QueryGuildRecipes)

    for _, delay in ipairs({ 1, 3 }) do
        C_Timer.After(delay, function()
            ns.ScanGuildTradeSkills()
            if delay == 3 and restore then SetGuildRosterShowOffline(false) end
            Refresh()
        end)
    end
end

-- /gp debug: print exactly what the client returns.
function ns.DebugGuildTradeSkills()
    local P = ns.Print
    if not (GetNumGuildTradeSkill and GetGuildTradeSkillInfo) then
        P("Guild profession directory API not available.")
        return
    end
    local n = GetNumGuildTradeSkill() or 0
    P(("Entries: %d | Expand: %s | ShowOffline: %s | Last error: %s"):format(n,
        ExpandGuildTradeSkillHeader and "yes" or "no",
        GetGuildRosterShowOffline and tostring(GetGuildRosterShowOffline()) or "n/a",
        ns.guildTradeSkillError or "none"))
    for i = 1, min(n, 25) do
        local count = select("#", GetGuildTradeSkillInfo(i))
        local parts = {}
        for j = 1, count do
            parts[j] = tostring((select(j, GetGuildTradeSkillInfo(i))))
        end
        print(("|cff8e96a8%d:|r %s"):format(i, table.concat(parts, " | ")))
    end
    if n > 25 then P("(" .. (n - 25) .. " more not shown)") end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("GUILD_ROSTER_UPDATE")
ev:RegisterEvent("PLAYER_GUILD_UPDATE")
ev:RegisterEvent("SKILL_LINES_CHANGED")
ev:RegisterEvent("CHAT_MSG_ADDON")
pcall(ev.RegisterEvent, ev, "GUILD_TRADESKILL_UPDATE")

local H = {}

function H.ADDON_LOADED(name)
    if name == ADDON then
        -- One-time import from the addon's old name (if the old saved file was copied over).
        if not GuildloomDB and type(GuildPlusDB) == "table" then
            GuildloomDB = GuildPlusDB
            C_Timer.After(8, function() ns.Print("Imported your settings and data from GuildPlus.") end)
        end
        GuildPlusDB = nil
        GuildloomDB = GuildloomDB or {}
        for k, v in pairs(DEFAULTS) do
            if GuildloomDB[k] == nil then
                GuildloomDB[k] = type(v) == "table" and {} or v
            end
        end
        ns.db = GuildloomDB
        if ns.OnInit then ns.OnInit() end
    end
end

function H.PLAYER_LOGIN()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
    elseif RegisterAddonMessagePrefix then
        RegisterAddonMessagePrefix(PREFIX)
    end
end

function H.PLAYER_ENTERING_WORLD(isLogin, isReload)
    if isLogin or isReload then
        C_Timer.After(6, function()
            ns.RequestRoster()
            ns.UpdateOwn(true)
            ns.RequestSync()
        end)
    end
end

function H.GUILD_ROSTER_UPDATE()
    ns.Debounce("roster", 0.3, function()
        ns.ScanRoster()
        Refresh()
    end)
    -- Members logging in show up in the directory; pick them up now and then.
    ns.Debounce("gtsRoster", 120, ns.RefreshGuildTradeSkills)
end

function H.PLAYER_GUILD_UPDATE()
    ns.RequestRoster()
    H.GUILD_ROSTER_UPDATE()
end

function H.SKILL_LINES_CHANGED()
    ns.Debounce("own", 3, function() ns.UpdateOwn(false) end)
end

function H.GUILD_TRADESKILL_UPDATE()
    ns.Debounce("gts", 1, function()
        ns.ScanGuildTradeSkills()
        Refresh()
    end)
end

function H.CHAT_MSG_ADDON(prefix, text, channel, sender)
    if prefix ~= PREFIX or channel ~= "GUILD" or not text then return end
    sender = ns.FullName(sender)
    if sender == ns.MyName() then return end

    local kind, body = text:match("^(%u+)#(.*)$")
    if not kind then return end
    if kind == "R" then
        -- Spread replies out so a big guild doesn't answer all at once.
        ns.Debounce("reply", 1 + math.random() * 7, function()
            ns.UpdateOwn(true)
            if ns.BroadcastRecipeHashes then ns.BroadcastRecipeHashes() end
        end)
    elseif kind == "P" then
        local list = Decode(body)
        if #list > 0 then
            ns.GetProfData()[sender] = { t = time(), src = "sync", list = list }
            ns.Debounce("syncrefresh", 0.5, Refresh)
        end
    elseif ns.comm[kind] then
        local ok, err = pcall(ns.comm[kind], sender, body)
        if not ok then ns.lastCommError = kind .. ": " .. tostring(err) end
    end
end

ev:SetScript("OnEvent", function(_, event, ...)
    local fn = H[event]
    if fn then fn(...) end
end)
