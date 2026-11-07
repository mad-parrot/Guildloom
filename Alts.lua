-- Guildloom: Alt linking
--
-- Links come from two places:
--   * notes: "alt of Mad Parrot", "Mad Parrot's alt", "alt: Elvis", "(Elvis alt)",
--     "alt - Elvis", "main: Elvis"... (public or officer note; the name must be a
--     guild member; names with spaces work)
--   * manual links you set in the Alts tab (saved per guild, only for you).
--     A manual "unlink" also overrides a note.
local ADDON, ns = ...

ns.mainOf    = {}  -- [altFull] = mainFull
ns.altsOf    = {}  -- [mainFull] = { altFull, ... }
ns.altSource = {}  -- [altFull] = "note" | "manual"

-- Names can contain spaces on Forever ("Mad Parrot"), so after finding a
-- marker we try the longest run of words first (up to 4) against the roster.
local MAX_WORDS = 4
local SEP = "[,;/|%(%)%[%]]"   -- characters that end a name
-- Marker followed by the name: "alt of Mad Parrot", "main: Elvis", "alt (Elvis)"
local AFTER = { "alt of", "alt to", "alt:", "alt %-", "alt%-", "alt %(", "main:", "main is", "main %-" }
-- Name followed by the marker: "Mad Parrot's alt", "(Mad Parrot alt)"
local BEFORE = { "'s alt", " alt%)" }

local function Words(s)
    local t = {}
    for w in s:gmatch("%S+") do t[#t + 1] = w end
    return t
end

local function Clean(s)
    s = s:gsub("^%p+", "")
    s = s:gsub("%p+$", "")
    return s
end

-- Try word runs, longest first. fromStart = take words from the start (after a
-- marker) or from the end (before a marker).
local function MatchWords(text, fromStart, byLower, self)
    local w = Words(text)
    for n = math.min(MAX_WORDS, #w), 1, -1 do
        local first = fromStart and 1 or (#w - n + 1)
        local cand = Clean(table.concat(w, " ", first, first + n - 1))
        local mm = byLower[cand]
        if mm and mm ~= self then return mm end
    end
end

function ns.GetManualAlts()
    local k = ns.GuildKey()
    if not k or not ns.db then return {} end
    ns.db.alts = ns.db.alts or {}
    ns.db.alts[k] = ns.db.alts[k] or {}
    return ns.db.alts[k]  -- [altFull] = mainFull, or false = "ignore note"
end

local function FromNotes(m, byLower)
    for _, note in ipairs({ m.note or "", m.onote or "" }) do
        local low = note:lower()
        if low:find("alt", 1, true) or low:find("main", 1, true) then
            for _, marker in ipairs(AFTER) do
                local _, e = low:find(marker)
                if e then
                    local rest = low:sub(e + 1)
                    local cut = rest:find(SEP)
                    if cut then rest = rest:sub(1, cut - 1) end
                    local mm = MatchWords(rest, true, byLower, m)
                    if mm then return mm end
                end
            end
            for _, marker in ipairs(BEFORE) do
                local s = low:find(marker)
                if s then
                    local head = low:sub(1, s - 1)
                    -- keep only what follows the last separator
                    local last = 0
                    for i = #head, 1, -1 do
                        if head:sub(i, i):find(SEP) then last = i; break end
                    end
                    local mm = MatchWords(head:sub(last + 1), false, byLower, m)
                    if mm then return mm end
                end
            end
        end
    end
end

function ns.RebuildAlts()
    wipe(ns.mainOf); wipe(ns.altsOf); wipe(ns.altSource)
    if not ns.db then return end
    local manual = ns.GetManualAlts()
    local byLower = {}
    for _, m in ipairs(ns.members) do byLower[m.short:lower()] = m end

    for alt, main in pairs(manual) do
        if main and ns.byName[alt] and ns.byName[main] and alt ~= main then
            ns.mainOf[alt], ns.altSource[alt] = main, "manual"
        end
    end
    for _, m in ipairs(ns.members) do
        if manual[m.name] == nil and not ns.mainOf[m.name] then
            local mm = FromNotes(m, byLower)
            if mm then ns.mainOf[m.name], ns.altSource[m.name] = mm.name, "note" end
        end
    end

    -- Point alts-of-alts at the top main; drop anything circular.
    local fixed = {}
    for alt, main in pairs(ns.mainOf) do
        local seen, top = { [alt] = true }, main
        while ns.mainOf[top] and not seen[top] do
            seen[top] = true
            top = ns.mainOf[top]
        end
        if seen[top] or top == alt then top = nil end
        fixed[alt] = top
    end
    wipe(ns.mainOf)
    for alt, main in pairs(fixed) do
        if main then ns.mainOf[alt] = main end
    end

    for alt, main in pairs(ns.mainOf) do
        local t = ns.altsOf[main]
        if not t then t = {}; ns.altsOf[main] = t end
        t[#t + 1] = alt
    end
end

function ns.MainOf(m)
    local f = m and ns.mainOf[m.name]
    return f and ns.byName[f]
end

function ns.AltsOf(m)
    local out = {}
    for _, a in ipairs((m and ns.altsOf[m.name]) or {}) do
        if ns.byName[a] then out[#out + 1] = ns.byName[a] end
    end
    table.sort(out, function(a, b) return a.short < b.short end)
    return out
end

local function Changed()
    ns.RebuildAlts()
    if ns.RefreshUI then ns.RefreshUI() end
end

function ns.SetMain(alt, main)
    if not alt or not main or alt == main then return end
    local manual = ns.GetManualAlts()
    local mainFull = ns.mainOf[main.name] or main.name -- picked an alt? use its main
    if mainFull == alt.name then return end
    manual[alt.name] = mainFull
    -- Anything that pointed at the new alt now points at its main.
    for a, mm in pairs(manual) do
        if mm == alt.name then manual[a] = mainFull end
    end
    for _, a in ipairs(ns.altsOf[alt.name] or {}) do manual[a] = mainFull end
    Changed()
end

function ns.Unlink(alt)
    if not alt then return end
    -- false = "not an alt", which also stops a note from re-linking it
    ns.GetManualAlts()[alt.name] = false
    Changed()
end

-- Hours since ANY character of this player was online (0 = online now).
function ns.PlayerLastOnline(m)
    local mainFull = ns.mainOf[m.name] or m.name
    local chars = { ns.byName[mainFull] or m }
    for _, a in ipairs(ns.altsOf[mainFull] or {}) do chars[#chars + 1] = ns.byName[a] end
    local best
    for _, c in ipairs(chars) do
        if c then
            local h = c.online and 0 or c.lastOnline
            if not best or h < best then best = h end
        end
    end
    return best or m.lastOnline, chars
end
