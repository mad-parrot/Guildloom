-- Guildloom: Crafting requests (shared between guildmates running Guildloom)
--
--   CR#id#prof#time#status#claimer#text   create / refresh (sent by the author)
--   CC#id#1 | CC#id#0                     claim / unclaim (sent by the crafter)
--   CD#id                                 done (author or crafter)
--   CX#id                                 cancelled (author)
--   CQ#                                   "send me the requests you know about"
local ADDON, ns = ...

local OPEN_TTL = 3 * 86400  -- open requests expire after 3 days
local DONE_TTL = 86400      -- finished ones are kept for a day
local NOTIFY_WINDOW = 600   -- only alert for requests made in the last 10 minutes
local counter = 0
local notified = {}

local STATUS_CODE = { open = "o", claimed = "c", done = "d" }
local CODE_STATUS = { o = "open", c = "claimed", d = "done" }

---------------------------------------------------------------------------
-- Notices: request alerts go to Guildloom's own notices window (built in
-- UI.lua), so they work the same with Blizzard chat, Chattynator or any
-- other chat addon. Optionally they're echoed to chat too.
---------------------------------------------------------------------------
local LOG_MAX = 60

-- Built-in alert sounds (SOUNDKIT name first, numeric ID as fallback).
local SOUNDS = {
    { value = "whisper",  label = "Whisper",           kit = "TELL_MESSAGE",          id = 3081 },
    { value = "ready",    label = "Ready check",       kit = "READY_CHECK",           id = 8960 },
    { value = "warning",  label = "Raid warning",      kit = "RAID_WARNING",          id = 8959 },
    { value = "toast",    label = "Battle.net toast",  kit = "UI_BNET_TOAST",         id = 18019 },
    { value = "invite",   label = "Group invite",      kit = "IG_PLAYER_INVITE",      id = 880 },
    { value = "ping",     label = "Map ping",          kit = "MAP_PING",              id = 3175 },
    { value = "alarm",    label = "Alarm clock",       kit = "ALARM_CLOCK_WARNING_3", id = 12889 },
    { value = "coins",    label = "Coins",             kit = "LOOT_WINDOW_COIN_SOUND", id = 120 },
    { value = "auction",  label = "Auction house",     kit = "AUCTION_WINDOW_OPEN",   id = 5274 },
}

local function LSM()
    return LibStub and LibStub("LibSharedMedia-3.0", true)
end

-- All choices for the settings drop-down: built-ins, then SharedMedia sounds.
function ns.SoundOptions()
    local out = {}
    for _, s in ipairs(SOUNDS) do out[#out + 1] = { value = s.value, label = s.label } end
    local lsm = LSM()
    if lsm then
        local names = lsm:List("sound") or {}
        for _, name in ipairs(names) do
            if name ~= "None" then out[#out + 1] = { value = "lsm:" .. name, label = name .. "  (SharedMedia)" } end
        end
    end
    return out
end

-- force = play even if alert sounds are switched off (previewing in settings)
function ns.PlayNoticeSound(key, force)
    if not force and ns.db and ns.db.noticeSound == false then return end
    key = key or (ns.db and ns.db.noticeSoundKey) or "whisper"
    if key:sub(1, 4) == "lsm:" then
        local lsm = LSM()
        local file = lsm and lsm:Fetch("sound", key:sub(5), true)
        if file and PlaySoundFile and pcall(PlaySoundFile, file, "Master") then return end
        key = "whisper" -- that pack isn't installed anymore
    end
    local s = SOUNDS[1]
    for _, e in ipairs(SOUNDS) do if e.value == key then s = e end end
    local id = (SOUNDKIT and SOUNDKIT[s.kit]) or s.id
    -- "Master" so it still plays when sound effects are turned down.
    if PlaySound and not pcall(PlaySound, id, "Master") then pcall(PlaySound, id) end
end

local function PlayAlert()
    ns.PlayNoticeSound()
end

function ns.GetNoticeLog()
    if not ns.db then return {} end
    ns.db.noticeLog = ns.db.noticeLog or {}
    return ns.db.noticeLog
end

-- important = play a sound and pop the notices window open
function ns.Notice(msg, important)
    local log = ns.GetNoticeLog()
    local entry = { t = time(), m = msg, i = important and true or nil }
    log[#log + 1] = entry
    while #log > LOG_MAX do table.remove(log, 1) end

    local shown = ns.AddNoticeLine and ns.AddNoticeLine(entry, important)
    if (ns.db and ns.db.noticeChat) or not shown then
        DEFAULT_CHAT_FRAME:AddMessage("|cff4fc3f7Guildloom|r: " .. msg)
    end
    if important then PlayAlert() end
end

function ns.GetRequests()
    local k = ns.GuildKey()
    if not k or not ns.db then return {} end
    ns.db.requests = ns.db.requests or {}
    ns.db.requests[k] = ns.db.requests[k] or {}
    return ns.db.requests[k]
end

function ns.PruneRequests()
    local now, reqs = time(), ns.GetRequests()
    for id, r in pairs(reqs) do
        if (r.status == "done" and now - (r.ut or r.t) > DONE_TTL)
           or (r.status ~= "done" and now - r.t > OPEN_TTL) then
            reqs[id] = nil
        end
    end
end

local function Changed()
    if ns.UpdateBadge then ns.UpdateBadge() end
    if ns.RefreshUI then ns.RefreshUI() end
end

local function Broadcast(r, queued)
    local msg = ("CR#%s#%s#%d#%s#%s#%s"):format(r.id, r.prof or "", r.t,
        STATUS_CODE[r.status] or "o", r.by or "", r.text)
    if queued then ns.SendQueued(msg) else ns.Send(msg) end
end

-- Can I (probably) make this?
function ns.CanICraftRequest(r)
    return ns.ICanCraft(r.text, r.prof)
end

local function MaybeNotify(r)
    if notified[r.id] or r.status ~= "open" then return end
    if r.from == ns.MyName() or time() - r.t > NOTIFY_WINDOW then return end
    notified[r.id] = true
    local can = ns.CanICraftRequest(r)
    local what = r.text .. (r.prof ~= "" and (" (" .. r.prof .. ")") or "")
    if can then
        ns.Notice(("|cffffd100%s needs %s - you can craft this!|r"):format(ns.Short(r.from), what), true)
    else
        -- Logged in the Guildloom tab only; no sound.
        ns.Notice(("%s requested %s."):format(ns.Short(r.from), what), false)
    end
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------
function ns.CreateRequest(text, prof)
    text = (text or ""):gsub("[\r\n]", " ")
    if #text > 150 then text = text:sub(1, 150) end -- addon messages max out at 255 bytes
    if text:gsub("%s", "") == "" then return end
    counter = counter + 1
    local r = {
        id = ("%s:%d:%d"):format(UnitName("player"), time(), counter),
        from = ns.MyName(), text = text, prof = prof or "",
        t = time(), status = "open",
    }
    ns.GetRequests()[r.id] = r
    Broadcast(r)
    ns.Notice(("You requested %s%s. Guildmates with Guildloom have been notified."):format(
        text, r.prof ~= "" and (" (" .. r.prof .. ")") or ""), false)
    Changed()
end

function ns.ClaimRequest(id, claim)
    local r = ns.GetRequests()[id]
    if not r then return end
    if claim then
        if r.status ~= "open" then return end
        r.status, r.by = "claimed", ns.MyName()
    else
        if r.by ~= ns.MyName() then return end
        r.status, r.by = "open", nil
    end
    r.ut = time()
    ns.Send(("CC#%s#%s"):format(id, claim and "1" or "0"))
    Changed()
end

function ns.CompleteRequest(id)
    local r = ns.GetRequests()[id]
    if not r then return end
    r.status, r.ut = "done", time()
    ns.Send("CD#" .. id)
    Changed()
end

function ns.CancelRequest(id)
    local reqs = ns.GetRequests()
    local r = reqs[id]
    if not r or r.from ~= ns.MyName() then return end
    reqs[id] = nil
    ns.Send("CX#" .. id)
    Changed()
end

-- Open requests (not mine) that I can make: drives the minimap badge.
function ns.CountCraftableRequests()
    local n, me = 0, ns.MyName()
    for _, r in pairs(ns.GetRequests()) do
        if r.status == "open" and r.from ~= me and ns.CanICraftRequest(r) then n = n + 1 end
    end
    return n
end

---------------------------------------------------------------------------
-- Incoming messages
---------------------------------------------------------------------------
ns.comm.CR = function(sender, body)
    local id, prof, t, st, by, text = body:match("^([^#]+)#([^#]*)#(%d+)#(%a)#([^#]*)#(.*)$")
    if not id then return end
    -- The id starts with the author's name; ignore anyone else using it.
    if id:match("^([^:]+)") ~= ns.Short(sender) then return end
    local reqs = ns.GetRequests()
    local r = reqs[id]
    if not r then
        r = { id = id, from = sender }
        reqs[id] = r
    end
    r.text, r.prof, r.t = text, prof, tonumber(t)
    r.status = CODE_STATUS[st] or "open"
    r.by = (by ~= "" and by) or nil
    r.ut = time()
    ns.PruneRequests()
    MaybeNotify(r)
    Changed()
end

ns.comm.CC = function(sender, body)
    local id, flag = body:match("^([^#]+)#([01])$")
    local r = id and ns.GetRequests()[id]
    if not r then return end
    local mine = r.from == ns.MyName()
    if flag == "1" and r.status == "open" then
        r.status, r.by = "claimed", sender
        if mine then ns.Notice(("|cff4ade80%s is crafting your %s.|r"):format(ns.Short(sender), r.text), true) end
    elseif flag == "0" and r.by == sender then
        r.status, r.by = "open", nil
        if mine then ns.Notice(("%s dropped your request for %s - it's open again."):format(ns.Short(sender), r.text), false) end
    end
    r.ut = time()
    Changed()
end

ns.comm.CD = function(sender, body)
    local r = ns.GetRequests()[body]
    if r and r.status ~= "done" and (r.from == sender or r.by == sender) then
        r.status, r.ut = "done", time()
        if r.from == ns.MyName() then
            ns.Notice(("|cff4ade80%s marked your %s as done - check your mailbox!|r"):format(ns.Short(sender), r.text), true)
        end
        Changed()
    end
end

ns.comm.CX = function(sender, body)
    local reqs = ns.GetRequests()
    local r = reqs[body]
    if r and r.from == sender then
        reqs[body] = nil
        Changed()
    end
end

ns.comm.CQ = function()
    -- Everyone re-sends only the requests they authored.
    ns.Debounce("cqReply", 1 + math.random() * 4, function()
        local me = ns.MyName()
        for _, r in pairs(ns.GetRequests()) do
            if r.from == me then Broadcast(r, true) end
        end
    end)
end

---------------------------------------------------------------------------
-- Login: ask what's open
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(_, _, isLogin, isReload)
    if isLogin or isReload then
        C_Timer.After(10, function()
            if not IsInGuild() then return end
            ns.PruneRequests()
            ns.Send("CQ#")
            Changed()
        end)
    end
end)
