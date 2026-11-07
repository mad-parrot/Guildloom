-- Guildloom: UI (panel, tabs, virtual list, overview)
local ADDON, ns = ...

local floor, max, min = math.floor, math.max, math.min
local WHITE = "Interface\\Buttons\\WHITE8x8"
local ROW_H = 22

local C = {
    bg        = { 0.055, 0.062, 0.078, 0.97 },
    panel     = { 0.095, 0.105, 0.130, 1 },
    header    = { 0.13, 0.15, 0.19, 1 },
    border    = { 0.20, 0.22, 0.27, 1 },
    accent    = { 0.31, 0.76, 0.97, 1 },
    accentDim = { 0.31, 0.76, 0.97, 0.18 },
    hover     = { 0.31, 0.76, 0.97, 0.10 },
    text      = { 0.92, 0.93, 0.96, 1 },
    dim       = { 0.56, 0.59, 0.66, 1 },
    online    = { 0.29, 0.87, 0.50, 1 },
    offline   = { 0.33, 0.35, 0.40, 1 },
    mobile    = { 0.40, 0.65, 1.00, 1 },
    good      = { 0.29, 0.87, 0.50, 1 },
    well      = { 0.095, 0.105, 0.130, 1 }, -- large content panels (may be translucent)
    title     = { 0.92, 0.93, 0.96, 1 },    -- window titles
    btnText   = { 0.92, 0.93, 0.96, 1 },    -- button labels
}

-- True while the "Blizzard" skin (real game frame art) is active.
local BLZ, SHADOW = false, false

---------------------------------------------------------------------------
-- Skins. Each palette overwrites the C colour tables in place, and every
-- widget registered below gets re-coloured, so switching is instant.
---------------------------------------------------------------------------
local DEFAULT_SKIN = "blizzard"
local SKINS = {
    -- Default. The game's own frame art: metal portrait frame, red buttons, input boxes.
    { key = "blizzard", name = "Blizzard (default)", backdrop = "blizzard", wellAlpha = 0.45, shadow = true,
        bgTex = "Interface\\FrameGeneral\\UI-Background-Marble", bgTint = { 0.36, 0.37, 0.42 }, colors = {
        bg = { 0.06, 0.06, 0.07 }, panel = { 0.10, 0.10, 0.11 }, header = { 0.18, 0.18, 0.20 },
        border = { 0.38, 0.38, 0.40 }, accent = { 1.00, 0.82, 0.00 }, text = { 1.00, 1.00, 1.00 }, dim = { 0.66, 0.66, 0.68 },
        well = { 0.00, 0.00, 0.00 }, title = { 1.00, 0.82, 0.00 }, btnText = { 1.00, 0.82, 0.00 } } },
    { key = "midnight", name = "Midnight", colors = {
        bg = { 0.055, 0.062, 0.078 }, panel = { 0.095, 0.105, 0.130 }, header = { 0.13, 0.15, 0.19 },
        border = { 0.20, 0.22, 0.27 }, accent = { 0.31, 0.76, 0.97 }, text = { 0.92, 0.93, 0.96 }, dim = { 0.56, 0.59, 0.66 } } },
    { key = "classic", name = "Classic Gold", backdrop = "tooltip", colors = {
        bg = { 0.04, 0.04, 0.04 }, panel = { 0.08, 0.07, 0.05 }, header = { 0.17, 0.13, 0.06 },
        border = { 0.50, 0.42, 0.24 }, accent = { 1.00, 0.82, 0.00 }, text = { 1.00, 0.96, 0.86 }, dim = { 0.70, 0.64, 0.52 } } },
    -- Old-school look: gold-trimmed dialog border over tiled stone.
    { key = "rustic", name = "Rustic Stone", backdrop = "stone", wellAlpha = 0.55, shadow = true,
        bgTex = "Interface\\FrameGeneral\\UI-Background-Rock", bgTint = { 0.42, 0.38, 0.34 }, colors = {
        bg = { 0.09, 0.07, 0.05 }, panel = { 0.14, 0.10, 0.06 }, header = { 0.30, 0.18, 0.07 },
        border = { 0.58, 0.45, 0.22 }, accent = { 1.00, 0.82, 0.00 }, text = { 0.96, 0.92, 0.82 }, dim = { 0.74, 0.66, 0.50 },
        well = { 0.07, 0.05, 0.03 }, title = { 1.00, 0.82, 0.00 } } },
    { key = "horde", name = "Horde", colors = {
        bg = { 0.07, 0.03, 0.03 }, panel = { 0.12, 0.05, 0.05 }, header = { 0.22, 0.07, 0.06 },
        border = { 0.36, 0.13, 0.10 }, accent = { 0.96, 0.32, 0.22 }, text = { 0.97, 0.91, 0.89 }, dim = { 0.68, 0.54, 0.52 } } },
    { key = "alliance", name = "Alliance", colors = {
        bg = { 0.03, 0.05, 0.10 }, panel = { 0.05, 0.08, 0.16 }, header = { 0.08, 0.13, 0.26 },
        border = { 0.18, 0.26, 0.45 }, accent = { 0.98, 0.80, 0.30 }, text = { 0.92, 0.94, 1.00 }, dim = { 0.56, 0.63, 0.78 } } },
    { key = "emerald", name = "Emerald Dream", colors = {
        bg = { 0.03, 0.07, 0.05 }, panel = { 0.05, 0.11, 0.08 }, header = { 0.07, 0.18, 0.12 },
        border = { 0.14, 0.32, 0.22 }, accent = { 0.36, 0.90, 0.56 }, text = { 0.90, 0.97, 0.92 }, dim = { 0.53, 0.69, 0.59 } } },
    { key = "void", name = "Void", colors = {
        bg = { 0.05, 0.03, 0.08 }, panel = { 0.09, 0.05, 0.14 }, header = { 0.15, 0.08, 0.24 },
        border = { 0.29, 0.17, 0.43 }, accent = { 0.76, 0.47, 1.00 }, text = { 0.95, 0.92, 1.00 }, dim = { 0.63, 0.57, 0.73 } } },
}
local SKIN_BY_KEY = {}
for _, s in ipairs(SKINS) do SKIN_BY_KEY[s.key] = s end

local FLAT_BD = { bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 }
local TOOLTIP_BD = {
    bgFile = "Interface\\Tooltip\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltip\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
local DIALOG_BD = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left = 6, right = 6, top = 6, bottom = 6 },
}
-- Background only; the border comes from the game's NineSlice frame art.
local BLZ_BD = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    tile = true, tileSize = 32,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

-- Frame style of a skin: backdrop, how far content sits from the edge, and
-- whether the Blizzard frame art is in use.
local function WindowStyle(skin, w)
    if skin.backdrop == "blizzard" then
        if w.chrome and w.chrome.o then return BLZ_BD, 3, true end
        return DIALOG_BD, 8 -- frame art unavailable: fall back to the dialog border
    end
    if skin.backdrop == "stone" then return DIALOG_BD, 8 end
    if skin.backdrop == "tooltip" then return TOOLTIP_BD, 4 end
    return FLAT_BD, 1
end

-- Style a top-level window (main window, notices) for the given skin.
local function StyleWindow(w, head, skin, alpha)
    local bd, pad, blz = WindowStyle(skin, w)
    w:SetBackdrop(bd)
    if skin.bgTex then
        -- Textured: keep the art's own colours.
        w:SetBackdropColor(1, 1, 1, alpha)
        w:SetBackdropBorderColor(1, 1, 1, 1)
        if not w.stone then
            w.stone = w:CreateTexture(nil, "BACKGROUND", nil, -7)
            w.stone:SetHorizTile(true)
            w.stone:SetVertTile(true)
        end
        local i = blz and 3 or 6
        w.stone:ClearAllPoints()
        w.stone:SetPoint("TOPLEFT", i, -i)
        w.stone:SetPoint("BOTTOMRIGHT", -i, i)
        w.stone:SetTexture(skin.bgTex, "REPEAT", "REPEAT")
        w.stone:SetVertexColor(unpack(skin.bgTint or { 1, 1, 1 }))
        w.stone:SetAlpha(alpha)
        w.stone:Show()
    else
        w:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], alpha)
        w:SetBackdropBorderColor(unpack(C.border))
        if w.stone then w.stone:Hide() end
    end
    if head and not blz then
        head:ClearAllPoints()
        head:SetPoint("TOPLEFT", pad, -pad)
        head:SetPoint("TOPRIGHT", -pad, -pad)
    end
    return pad, blz
end
ns.StyleWindow = StyleWindow

local skinned = { bd = {}, text = {}, tex = {}, fn = {}, chrome = {}, inputs = {}, swap = {}, buttons = {} }

---------------------------------------------------------------------------
-- Blizzard frame art. Everything is created only when the Blizzard skin is
-- first used, and each piece falls back to the flat look if the game
-- doesn't provide it.
---------------------------------------------------------------------------
-- A mouse-transparent overlay with one of the game's NineSlice borders.
local function NineSlice(parent, layout, off)
    if not (NineSliceUtil and NineSliceUtil.ApplyLayoutByName) then return nil end
    local o = CreateFrame("Frame", nil, parent)
    o:SetAllPoints()
    o:EnableMouse(false)
    o:SetFrameLevel(parent:GetFrameLevel() + off)
    local ok = pcall(NineSliceUtil.ApplyLayoutByName, o, layout)
    if not ok or not (o.TopLeftCorner or o.TopEdge) then o:Hide(); return nil end
    if o.Center then o.Center:Hide() end -- we draw our own background
    return o
end

local function ApplyChrome(e)
    if BLZ and e.o == nil then e.o = NineSlice(e.f, e.layout, e.off) or false end
    if e.o then
        e.o:SetFrameLevel(e.f:GetFrameLevel() + e.off)
        e.o:SetShown(BLZ)
    end
end

-- Give a backdrop frame a Blizzard border in the Blizzard skin. Its own flat
-- border is hidden then (unless keepBorder, for windows styled separately).
local function Chrome(f, layout, off, keepBorder)
    local e = { f = f, layout = layout, off = off or 8 }
    skinned.chrome[#skinned.chrome + 1] = e
    f.chrome = e
    ApplyChrome(e)
    if not keepBorder then
        local orig = f.SetBackdropBorderColor
        f.SetBackdropBorderColor = function(s, ...)
            if BLZ and e.o then return orig(s, 0, 0, 0, 0) end
            return orig(s, ...)
        end
        if BLZ and e.o then orig(f, 0, 0, 0, 0) end
    end
    return e
end

-- Swap our small "x" for the game's red close button in the Blizzard skin.
local function BlizzClose(parent, flatX, onClick, x, y)
    local ok, b = pcall(CreateFrame, "Button", nil, parent, "UIPanelCloseButton")
    if not ok or not b then return nil end
    b:SetPoint("TOPRIGHT", x or 0, y or 0)
    b:SetFrameLevel(parent:GetFrameLevel() + 12)
    b:SetScript("OnClick", onClick)
    b:SetShown(BLZ)
    if BLZ then flatX:Hide() end
    skinned.swap[#skinned.swap + 1] = { flatX, b }
    return b
end

-- Input box art, copied from the game's own InputBoxTemplate.
local inputArt
local function GetInputArt()
    if inputArt ~= nil then return inputArt end
    inputArt = false
    local ok, p = pcall(CreateFrame, "EditBox", nil, UIParent, "InputBoxTemplate")
    if ok and p then
        p:SetAutoFocus(false)
        p:Hide()
        local l, m, r = p.Left, p.Middle or p.Mid, p.Right
        if l and m and r then inputArt = { l, m, r } end
    end
    return inputArt
end

local function CopyTex(dst, src)
    local atlas = src.GetAtlas and src:GetAtlas()
    if atlas then
        dst:SetAtlas(atlas)
    else
        dst:SetTexture(src:GetTexture())
        dst:SetTexCoord(src:GetTexCoord())
    end
end

local function ApplyInput(e)
    if BLZ and e.art == nil then
        local src = GetInputArt()
        if src then
            local b = e.box
            local l, m, r = b:CreateTexture(nil, "BACKGROUND"), b:CreateTexture(nil, "BACKGROUND"), b:CreateTexture(nil, "BACKGROUND")
            CopyTex(l, src[1]); CopyTex(m, src[2]); CopyTex(r, src[3])
            l:SetPoint("TOPLEFT"); l:SetPoint("BOTTOMLEFT"); l:SetWidth(8)
            r:SetPoint("TOPRIGHT"); r:SetPoint("BOTTOMRIGHT"); r:SetWidth(8)
            m:SetPoint("TOPLEFT", l, "TOPRIGHT")
            m:SetPoint("BOTTOMRIGHT", r, "BOTTOMLEFT")
            e.art = { l, m, r }
        else
            e.art = false
        end
    end
    if e.art then
        for _, t in ipairs(e.art) do t:SetShown(BLZ) end
        if BLZ then e.ob(e.box, 0, 0, 0, 0); e.oc(e.box, 0, 0, 0, 0) end
    end
end

-- Make an edit box look like a Blizzard input box in the Blizzard skin.
local function InputSkin(box)
    local e = { box = box, ob = box.SetBackdropColor, oc = box.SetBackdropBorderColor }
    local function on() return BLZ and e.art end
    box.SetBackdropColor = function(s, ...) if on() then return e.ob(s, 0, 0, 0, 0) end return e.ob(s, ...) end
    box.SetBackdropBorderColor = function(s, ...) if on() then return e.oc(s, 0, 0, 0, 0) end return e.oc(s, ...) end
    skinned.inputs[#skinned.inputs + 1] = e
    ApplyInput(e)
end

-- Drives the (mouse-transparent) red button art from the real button.
local function BlzButtonUpdate(s)
    local b = s:GetParent()
    local en = b:IsEnabled() and true or false
    if (s:IsEnabled() and true or false) ~= en then s:SetEnabled(en) end
    local over = en and b:IsMouseOver()
    local state = (over and IsMouseButtonDown("LeftButton")) and "PUSHED" or "NORMAL"
    if s.state ~= state then s.state = state; s:SetButtonState(state) end
    local hl = (over or b.active) and true or false
    if s.hl ~= hl then
        s.hl = hl
        if hl then s:LockHighlight() else s:UnlockHighlight() end
    end
end

local function Hex(c)
    return ("|cff%02x%02x%02x"):format(floor(c[1] * 255 + 0.5), floor(c[2] * 255 + 0.5), floor(c[3] * 255 + 0.5))
end
ns.Hex = Hex

-- Colour a texture from a palette entry and remember it for re-skinning.
local function Paint(tex, color, alpha)
    tex:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
    skinned.tex[#skinned.tex + 1] = { tex, color, alpha }
end

---------------------------------------------------------------------------
-- Small widget helpers
---------------------------------------------------------------------------
local function SetBD(f, bg, border)
    bg, border = bg or C.bg, border or C.border
    f:SetBackdrop(FLAT_BD)
    f:SetBackdropColor(unpack(bg))
    f:SetBackdropBorderColor(unpack(border))
    skinned.bd[#skinned.bd + 1] = { f, bg, border }
end

local function Text(parent, size, color, justify)
    color = color or C.text
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(STANDARD_TEXT_FONT, size or 12, "")
    fs:SetTextColor(unpack(color))
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(false)
    if SHADOW then fs:SetShadowColor(0, 0, 0, 1); fs:SetShadowOffset(1, -1) end
    skinned.text[#skinned.text + 1] = { fs, color }
    return fs
end

local function FlatButton(parent, label, w)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(w or 90, 22)
    -- Red game button art (Blizzard skin) sits above the button, and the
    -- label sits above that on its own layer frame (b.top).
    local ok, blz = pcall(CreateFrame, "Button", nil, b, "UIPanelButtonTemplate")
    if ok and blz then
        blz:SetAllPoints()
        blz:EnableMouse(false)
        blz:SetFrameLevel(b:GetFrameLevel() + 1)
        blz:SetScript("OnUpdate", BlzButtonUpdate)
        blz:SetShown(BLZ)
        b.blz = blz
    end
    b.top = CreateFrame("Frame", nil, b)
    b.top:SetAllPoints()
    b.top:SetFrameLevel(b:GetFrameLevel() + 2)
    local ob, oc = b.SetBackdropColor, b.SetBackdropBorderColor
    b.SetBackdropColor = function(s, ...) if BLZ and s.blz then return ob(s, 0, 0, 0, 0) end return ob(s, ...) end
    b.SetBackdropBorderColor = function(s, ...) if BLZ and s.blz then return oc(s, 0, 0, 0, 0) end return oc(s, ...) end
    skinned.buttons[#skinned.buttons + 1] = b
    SetBD(b, C.panel, C.border)
    b.text = Text(b.top, 11, C.btnText, "CENTER")
    b.text:SetPoint("CENTER")
    b.text:SetText(label)
    function b:SetActive(on)
        self.active = on
        self:SetBackdropColor(unpack(on and C.accentDim or C.panel))
        self:SetBackdropBorderColor(unpack(on and C.accent or C.border))
    end
    b:SetScript("OnEnter", function(s) s:SetBackdropBorderColor(unpack(C.accent)) end)
    b:SetScript("OnLeave", function(s) s:SetBackdropBorderColor(unpack(s.active and C.accent or C.border)) end)
    return b
end

local function ClassColor(classFile)
    local t = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
    local c = classFile and t and t[classFile]
    if c then return c.r, c.g, c.b end
    return 0.8, 0.8, 0.8
end

local CLASS_TEX = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local function SetClassIcon(tex, classFile)
    local coords = CLASS_ICON_TCOORDS and classFile and CLASS_ICON_TCOORDS[classFile]
    if coords then
        tex:SetTexture(CLASS_TEX)
        tex:SetTexCoord(unpack(coords))
        tex:Show()
    else
        tex:Hide()
    end
end

local function SetIcon(tex, icon)
    if icon and icon ~= 0 and icon ~= "" then
        tex:SetTexture(icon)
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        tex:Show()
    else
        tex:Hide()
    end
end

local function LastSeen(m)
    if m.online then return m.mobile and "|cff66a6ffMobile|r" or "|cff4ade80Online|r" end
    local h = m.lastOnline or 0
    if h < 1 then return "< 1h ago"
    elseif h < 24 then return h .. "h ago"
    elseif h < 24 * 30 then return floor(h / 24) .. "d ago"
    elseif h < 24 * 365 then return floor(h / 720) .. "mo ago"
    else return floor(h / 8760) .. "y ago" end
end

local function Whisper(name)
    if ChatFrameUtil and ChatFrameUtil.SendTell then
        ChatFrameUtil.SendTell(name)
    elseif ChatFrame_SendTell then
        ChatFrame_SendTell(name)
    end
end

local function Invite(name)
    if C_PartyInfo and C_PartyInfo.InviteUnit then
        C_PartyInfo.InviteUnit(name)
    elseif InviteUnit then
        InviteUnit(name)
    end
end

local function SkillText(p)
    if p.m and p.m > 0 then return p.s .. " / " .. p.m end
    return tostring(p.s)
end

---------------------------------------------------------------------------
-- State helpers
---------------------------------------------------------------------------
ns.query = ""

-- Groups that start collapsed until the user opens them.
local DEFAULT_COLLAPSED = {
    ["profs:__nodata"] = true,
    ["requests:done"] = true,
    ["alts:__unlinked"] = true,
}

local function IsCollapsed(key, default)
    local v = ns.db.collapsed[key]
    if v == nil then return default or DEFAULT_COLLAPSED[key] or false end
    return v
end

local function ToggleCollapsed(key, default)
    ns.db.collapsed[key] = not IsCollapsed(key, default)
end

local function Matches(m, extra, ignoreOnline)
    if ns.db.onlineOnly and not ignoreOnline and not m.online then return false end
    local q = ns.query
    if q == "" then return true end
    local hay = (m.short .. " " .. m.note .. " " .. m.onote .. " " .. (m.zone or "") .. " " ..
                (m.class or "") .. " " .. m.rank .. " " .. (extra or "")):lower()
    return hay:find(q, 1, true) ~= nil
end

local function Filtering()
    return ns.query ~= "" or ns.db.onlineOnly
end

local function ByOnlineLevelName(a, b)
    if a.online ~= b.online then return a.online end
    if a.level ~= b.level then return a.level > b.level end
    return a.short < b.short
end

---------------------------------------------------------------------------
-- Rank management (promote / demote / kick)
---------------------------------------------------------------------------
local function MyRankIndex()
    local _, _, ri = GetGuildInfo("player")
    return ri or 99
end

local function LowestRankIndex()
    local lo = 0
    for r in pairs(ns.ranks) do lo = max(lo, r) end
    return lo
end

local function IsMe(m) return m.name == ns.MyName() end
local function IsGM() return IsGuildLeader and IsGuildLeader() and true or false end
local function HasPromote() return CanGuildPromote and CanGuildPromote() and true or false end
local function HasDemote() return CanGuildDemote and CanGuildDemote() and true or false end

-- Returns ok, reason
local function CanPromote(m)
    if IsMe(m) then return false, "You can't promote yourself." end
    if not HasPromote() then return false, "Your rank doesn't have permission to promote." end
    if m.rankIndex - 1 <= MyRankIndex() then return false, "You can only promote members to ranks below your own." end
    return true
end

local function CanDemote(m)
    if IsMe(m) then return false, "You can't demote yourself." end
    if not HasDemote() then return false, "Your rank doesn't have permission to demote." end
    if m.rankIndex <= MyRankIndex() then return false, "You can only demote members ranked below you." end
    if m.rankIndex >= LowestRankIndex() then return false, "Already at the lowest rank." end
    return true
end

local CG = C_GuildInfo or {}
local function GuildAction(newFn, oldFn, name)
    if newFn then newFn(name) elseif oldFn then oldFn(name) end
    C_Timer.After(0.5, ns.RequestRoster)
end
-- Character name only: Forever's internal realm suffix isn't accepted by these calls.
local function Promote(m) GuildAction(CG.Promote, GuildPromote, m.short) end
local function Demote(m) GuildAction(CG.Demote, GuildDemote, m.short) end
local function Kick(name) GuildAction(CG.Uninvite, GuildUninvite, name) end

StaticPopupDialogs["GUILDLOOM_KICK"] = {
    text = "Remove |cffffd100%s|r from the guild?",
    button1 = YES or "Yes",
    button2 = NO or "No",
    OnAccept = function(_, data) if data then Kick(data) end end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = true,
    preferredIndex = 3,
}

---------------------------------------------------------------------------
-- Main frame
---------------------------------------------------------------------------
local F = CreateFrame("Frame", "GuildloomFrame", UIParent, "BackdropTemplate")
F:SetSize(680, 540)
F:SetPoint("CENTER")
F:SetToplevel(true)
F:SetClampedToScreen(true)
F:SetMovable(true)
F:SetResizable(true)
F:EnableMouse(true)
if F.SetResizeBounds then F:SetResizeBounds(580, 420, 1100, 1000)
elseif F.SetMinResize then F:SetMinResize(580, 420); F:SetMaxResize(1100, 1000) end
if F.SetDontSavePosition then F:SetDontSavePosition(true) end
SetBD(F, C.bg, C.border)
Chrome(F, "PortraitFrameTemplate", 8, true)
F:Hide()
tinsert(UISpecialFrames, "GuildloomFrame")

-- Title bar ---------------------------------------------------------------
local titleBar = CreateFrame("Frame", nil, F)
titleBar:SetPoint("TOPLEFT", 1, -1)
titleBar:SetPoint("TOPRIGHT", -1, -1)
titleBar:SetHeight(34)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
local tbg = titleBar:CreateTexture(nil, "BACKGROUND")
tbg:SetAllPoints()
Paint(tbg, C.panel)

local logo = titleBar:CreateTexture(nil, "ARTWORK")
logo:SetSize(20, 20)
logo:SetPoint("LEFT", 10, 0)
SetIcon(logo, "Interface\\Icons\\INV_Shirt_GuildTabard_01")

local title = Text(titleBar, 14, C.title)
title:SetPoint("LEFT", logo, "RIGHT", 8, 0)

local subtitle = Text(titleBar, 11, C.dim, "RIGHT")
subtitle:SetPoint("RIGHT", -62, 0)

local close = CreateFrame("Button", nil, titleBar)
close:SetSize(26, 26)
close:SetPoint("RIGHT", -5, 0)
close.t = Text(close, 16, C.dim, "CENTER")
close.t:SetPoint("CENTER", 0, 1)
close.t:SetText("x")
close:SetScript("OnEnter", function(s) s.t:SetTextColor(1, 0.4, 0.4) end)
close:SetScript("OnLeave", function(s) s.t:SetTextColor(unpack(C.dim)) end)
close:SetScript("OnClick", function() F:Hide() end)
do
    local bc = BlizzClose(F, close, function() F:Hide() end, 1, 0)
    -- Older clients use the bigger 32px close button with a different offset.
    if bc and bc:GetWidth() >= 30 then bc:ClearAllPoints(); bc:SetPoint("TOPRIGHT", 4, 5) end
end

local gear = CreateFrame("Button", nil, titleBar)
gear:SetSize(18, 18)
gear:SetPoint("RIGHT", close, "LEFT", -4, 0)
gear.icon = gear:CreateTexture(nil, "ARTWORK")
gear.icon:SetAllPoints()
gear.icon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
gear.icon:SetAlpha(0.7)
gear:SetScript("OnEnter", function(s)
    s.icon:SetAlpha(1)
    GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
    GameTooltip:AddLine("Settings & skins")
    GameTooltip:Show()
end)
gear:SetScript("OnLeave", function(s) s.icon:SetAlpha(0.7); GameTooltip:Hide() end)
gear:SetScript("OnClick", function() ns.ToggleSettingsPopup() end)

local function SaveFreePosition()
    local l, t = F:GetLeft(), F:GetTop()
    if not l then return end
    ns.db.pos = { l, t }
    F:ClearAllPoints()
    F:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t)
end

titleBar:SetScript("OnDragStart", function() F:StartMoving() end)
titleBar:SetScript("OnDragStop", function()
    F:StopMovingOrSizing()
    if F.SetUserPlaced then F:SetUserPlaced(false) end
    SaveFreePosition()
end)

-- Resize grip
local grip = CreateFrame("Button", nil, F)
grip:SetSize(14, 14)
grip:SetPoint("BOTTOMRIGHT", -2, 2)
grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
grip:SetScript("OnMouseDown", function() F:StartSizing("BOTTOMRIGHT") end)
grip:SetScript("OnMouseUp", function()
    F:StopMovingOrSizing()
    if F.SetUserPlaced then F:SetUserPlaced(false) end
    ns.db.size = { F:GetWidth(), F:GetHeight() }
    ns.ApplyPosition()
end)

-- Tabs --------------------------------------------------------------------
local TABS = {
    { key = "overview", text = "Overview" },
    { key = "ranks",    text = "Ranks" },
    { key = "profs",    text = "Professions" },
    { key = "requests", text = "Requests" },
    { key = "activity", text = "Activity" },
    { key = "alts",     text = "Alts" },
}

local tabBar = CreateFrame("Frame", nil, F)
tabBar:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
tabBar:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)
tabBar:SetHeight(30)
local tabLine = tabBar:CreateTexture(nil, "ARTWORK")
tabLine:SetPoint("BOTTOMLEFT"); tabLine:SetPoint("BOTTOMRIGHT")
tabLine:SetHeight(1)
Paint(tabLine, C.border)

local tabButtons = {}
local SelectTab -- forward

for i, def in ipairs(TABS) do
    local b = CreateFrame("Button", nil, tabBar)
    b.key = def.key
    b.text = Text(b, 12, C.dim, "CENTER")
    b.text:SetPoint("CENTER", 0, 1)
    b.text:SetText(def.text)
    b:SetSize(b.text:GetStringWidth() + 28, 30)
    if i == 1 then b:SetPoint("BOTTOMLEFT", 8, 0)
    else b:SetPoint("BOTTOMLEFT", tabButtons[i - 1], "BOTTOMRIGHT", 2, 0) end
    b.line = b:CreateTexture(nil, "OVERLAY")
    b.line:SetPoint("BOTTOMLEFT", 6, 0); b.line:SetPoint("BOTTOMRIGHT", -6, 0)
    b.line:SetHeight(2)
    Paint(b.line, C.accent)
    b:SetScript("OnEnter", function(s) if ns.db.tab ~= s.key then s.text:SetTextColor(unpack(C.text)) end end)
    b:SetScript("OnLeave", function(s) if ns.db.tab ~= s.key then s.text:SetTextColor(unpack(C.dim)) end end)
    b:SetScript("OnClick", function(s) SelectTab(s.key) end)
    tabButtons[i] = b
end

-- Toolbar -----------------------------------------------------------------
local toolbar = CreateFrame("Frame", nil, F)
toolbar:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 10, -8)
toolbar:SetPoint("TOPRIGHT", tabBar, "BOTTOMRIGHT", -10, -8)
toolbar:SetHeight(24)

local search = CreateFrame("EditBox", nil, toolbar, "BackdropTemplate")
search:SetPoint("LEFT")
search:SetSize(240, 24)
SetBD(search, C.panel, C.border)
InputSkin(search)
search:SetAutoFocus(false)
search:SetFontObject(ChatFontNormal)
search:SetTextInsets(24, 8, 0, 0)
search:SetMaxLetters(40)
local sIcon = search:CreateTexture(nil, "OVERLAY")
sIcon:SetSize(14, 14)
sIcon:SetPoint("LEFT", 6, 0)
sIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
sIcon:SetVertexColor(unpack(C.dim))
skinned.fn[#skinned.fn + 1] = function() sIcon:SetVertexColor(unpack(C.dim)) end
local sHint = Text(search, 11, C.dim)
sHint:SetPoint("LEFT", 24, 0)
sHint:SetText("Search name, note, zone, profession...")
search:SetScript("OnEditFocusGained", function(s) s:SetBackdropBorderColor(unpack(C.accent)); sHint:Hide() end)
search:SetScript("OnEditFocusLost", function(s)
    s:SetBackdropBorderColor(unpack(C.border))
    sHint:SetShown(s:GetText() == "")
end)
search:SetScript("OnEscapePressed", function(s) s:SetText(""); s:ClearFocus() end)
search:SetScript("OnEnterPressed", function(s) s:ClearFocus() end)
search:SetScript("OnTextChanged", function(s)
    ns.query = (s:GetText() or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if not s:HasFocus() then sHint:SetShown(s:GetText() == "") end
    ns.RefreshUI()
end)

local function ButtonTip(b, title, body)
    b:HookScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:AddLine(title)
        if body then GameTooltip:AddLine(body, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    b:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

local onlineBtn = FlatButton(toolbar, "Online only", 92)
onlineBtn:SetScript("OnClick", function(s)
    ns.db.onlineOnly = not ns.db.onlineOnly
    s:SetActive(ns.db.onlineOnly)
    ns.RefreshUI()
end)

local expandBtn = FlatButton(toolbar, "Collapse all", 92)

-- Activity tab: inactivity threshold
local DAY_STEPS = { 7, 14, 30, 60, 90, 180 }
local daysBtn = FlatButton(toolbar, "30+ days", 84)
daysBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
daysBtn:SetScript("OnClick", function(_, button)
    local cur, idx = ns.db.inactiveDays or 30, 3
    for i, d in ipairs(DAY_STEPS) do if d == cur then idx = i end end
    idx = button == "RightButton" and (idx - 2) % #DAY_STEPS + 1 or idx % #DAY_STEPS + 1
    ns.db.inactiveDays = DAY_STEPS[idx]
    ns.RefreshUI()
end)
ButtonTip(daysBtn, "Inactive for at least...", "Left-click: longer   Right-click: shorter")

local altsBtn = FlatButton(toolbar, "Skip active alts", 112)
altsBtn:SetScript("OnClick", function()
    ns.db.hideActiveAlts = not ns.db.hideActiveAlts
    ns.RefreshUI()
end)
ButtonTip(altsBtn, "Skip active alts",
    "Don't list a character as inactive when another character of the same player (linked in the Alts tab) has been online recently.")

local newReqBtn = FlatButton(toolbar, "+ New request", 110)
newReqBtn:SetScript("OnClick", function() ns.ToggleRequestForm() end)

local syncBtn = FlatButton(toolbar, "Sync", 70)
syncBtn:SetScript("OnClick", function()
    ns.UpdateOwn(true)
    ns.RequestSync()
    ns.Print("Requested profession data from guild members running Guildloom.")
end)
syncBtn:SetScript("OnEnter", function(s)
    s:SetBackdropBorderColor(unpack(C.accent))
    GameTooltip:SetOwner(s, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:AddLine("Sync professions")
    GameTooltip:AddLine("Shares your professions and asks guildmates who use Guildloom to share theirs.", 1, 1, 1, true)
    GameTooltip:Show()
end)
syncBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

-- Lay out whichever toolbar buttons the current tab shows.
local leftButtons = { onlineBtn, expandBtn, daysBtn, altsBtn }
local rightButtons = { syncBtn, newReqBtn }
local function LayoutToolbar()
    local w = toolbar:GetWidth()
    if not w or w <= 0 then w = 640 end
    local used, prev = 0, search
    for _, b in ipairs(leftButtons) do
        if b:IsShown() then
            b:ClearAllPoints()
            b:SetPoint("LEFT", prev, "RIGHT", 8, 0)
            prev = b
            used = used + b:GetWidth() + 8
        end
    end
    local prevR
    for _, b in ipairs(rightButtons) do
        if b:IsShown() then
            b:ClearAllPoints()
            if prevR then b:SetPoint("RIGHT", prevR, "LEFT", -8, 0) else b:SetPoint("RIGHT") end
            prevR = b
            used = used + b:GetWidth() + 8
        end
    end
    search:SetWidth(max(110, min(240, w - used - 8)))
end
toolbar:SetScript("OnSizeChanged", LayoutToolbar)

-- Footer ------------------------------------------------------------------
local footer = Text(F, 10, C.dim)
footer:SetPoint("BOTTOMLEFT", 12, 8)
footer:SetPoint("BOTTOMRIGHT", -24, 8)

-- Content -----------------------------------------------------------------
local content = CreateFrame("Frame", nil, F)
content:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 0, -8)
content:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -10, 26)

---------------------------------------------------------------------------
-- Virtual list
---------------------------------------------------------------------------
local list = CreateFrame("Frame", nil, content, "BackdropTemplate")
list:SetAllPoints()
SetBD(list, C.well, C.border)
Chrome(list, "InsetFrameTemplate", 6)
list:EnableMouseWheel(true)
list.rows, list.items, list.offset, list.offsets = {}, {}, 0, {}

local slider = CreateFrame("Slider", nil, list)
slider:SetPoint("TOPRIGHT", -2, -2)
slider:SetPoint("BOTTOMRIGHT", -2, 2)
slider:SetWidth(5)
slider:SetOrientation("VERTICAL")
slider:SetMinMaxValues(0, 0)
slider:SetValueStep(1)
if slider.SetObeyStepDuringDrag then slider:SetObeyStepDuringDrag(true) end
local track = slider:CreateTexture(nil, "BACKGROUND")
track:SetAllPoints()
track:SetColorTexture(1, 1, 1, 0.05)
local thumb = slider:CreateTexture(nil, "OVERLAY")
Paint(thumb, C.accent, 0.7)
thumb:SetSize(5, 40)
slider:SetThumbTexture(thumb)
list.slider = slider

local emptyText = Text(list, 12, C.dim, "CENTER")
emptyText:SetPoint("CENTER")
emptyText:SetWordWrap(true)
emptyText:SetWidth(380)

local function RowTooltip(self)
    local it = self.item
    if not it then return end
    if it.tooltip then it.tooltip(self); return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if it.header then
        if not it.tip then GameTooltip:Hide(); return end
        GameTooltip:AddLine(it.text)
        GameTooltip:AddLine(it.tip, 1, 1, 1, true)
        GameTooltip:Show()
        return
    end
    local m = it.m
    GameTooltip:AddLine(m.short, ClassColor(m.classFile))
    if m.realm and m.realm ~= GetNormalizedRealmName() then
        GameTooltip:AddLine(m.realm, 0.5, 0.5, 0.5)
    end
    GameTooltip:AddLine(("Level %d %s"):format(m.level, m.class or ""), 1, 1, 1)
    GameTooltip:AddDoubleLine("Rank", m.rank, 0.6, 0.6, 0.6, 1, 1, 1)
    local main = ns.MainOf and ns.MainOf(m)
    if main then
        GameTooltip:AddDoubleLine("Alt of", main.short, 0.6, 0.6, 0.6, ClassColor(main.classFile))
    elseif ns.AltsOf then
        local alts = ns.AltsOf(m)
        if #alts > 0 then
            local names = {}
            for _, a in ipairs(alts) do names[#names + 1] = a.short end
            GameTooltip:AddDoubleLine("Alts", table.concat(names, ", "), 0.6, 0.6, 0.6, 1, 1, 1)
        end
    end
    if m.online then
        GameTooltip:AddDoubleLine("Zone", m.zone or "?", 0.6, 0.6, 0.6, 1, 1, 1)
    else
        GameTooltip:AddDoubleLine("Last seen", LastSeen(m), 0.6, 0.6, 0.6, 1, 1, 1)
    end
    if m.note ~= "" then GameTooltip:AddLine("Note: " .. m.note, 0.9, 0.85, 0.6, true) end
    if m.onote ~= "" then GameTooltip:AddLine("Officer: " .. m.onote, 1, 0.6, 0.4, true) end
    local profs = ns.GetMemberProfs(m.name)
    if profs and #profs > 0 then
        GameTooltip:AddLine(" ")
        for _, p in ipairs(profs) do
            GameTooltip:AddDoubleLine(p.n, SkillText(p), 0.31, 0.76, 0.97, 1, 1, 1)
        end
    end
    if ns.pickAltFor and ns.db.tab == "alts" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click to make this the main of " .. ns.pickAltFor.short, 0.31, 0.76, 0.97)
    elseif not it.manage then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click: whisper   Right-click: invite", 0.5, 0.5, 0.5)
    end
    GameTooltip:Show()
end

local function RowClick(self, button)
    local it = self.item
    if not it then return end
    if it.header then
        ToggleCollapsed(it.key, it.defaultCollapsed)
        ns.RefreshUI()
        return
    end
    -- Alts tab "pick the main" mode: the clicked member becomes the main.
    if ns.pickAltFor and ns.db.tab == "alts" and it.m then
        local alt = ns.pickAltFor
        if it.m.name ~= alt.name then
            ns.pickAltFor = nil
            ns.SetMain(ns.byName[alt.name] or alt, it.m)
            ns.Print(("%s is now linked as an alt of %s."):format(alt.short, (ns.MainOf(alt) or it.m).short))
        end
        ns.RefreshUI()
        return
    end
    if it.manage then return end -- rank/activity view: no whisper/invite on click
    local m = it.m
    if m.name == ns.MyName() then return end
    -- Forever's roster appends an internal realm name the chat system doesn't
    -- accept, so target the character name only.
    local target = m.short
    if button == "RightButton" then
        if m.online then Invite(target) end
    else
        Whisper(target)
    end
end

local function MiniButton(parent, tex)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(20, 18)
    SetBD(b, C.panel, C.border)
    if tex then
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetSize(14, 14)
        b.icon:SetPoint("CENTER")
        b.icon:SetTexture(tex)
    else
        b.label = Text(b, 12, { 1, 0.45, 0.45, 1 }, "CENTER")
        b.label:SetPoint("CENTER", 0, 1)
        b.label:SetText("x")
    end
    function b:SetUsable(on)
        self.usable = on
        if on then self:Enable() else self:Disable() end
        local a = on and 1 or 0.3
        if self.icon then self.icon:SetDesaturated(not on); self.icon:SetAlpha(a) end
        if self.label then self.label:SetAlpha(a) end
    end
    b:SetScript("OnEnter", function(s)
        if s.usable then s:SetBackdropBorderColor(unpack(C.accent)) end
        if s.ShowTip then s:ShowTip() end
    end)
    b:SetScript("OnLeave", function(s)
        s:SetBackdropBorderColor(unpack(C.border))
        GameTooltip:Hide()
    end)
    return b
end

local function ActionTip(btn, title, ok, reason)
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    GameTooltip:AddLine(title, 1, 1, 1)
    if not ok and reason then GameTooltip:AddLine(reason, 1, 0.4, 0.4, true) end
    GameTooltip:Show()
end

local function CreateManageButtons(r)
    r.kickBtn = MiniButton(r)
    r.kickBtn:SetPoint("RIGHT", -8, 0)
    r.downBtn = MiniButton(r, "Interface\\Buttons\\Arrow-Down-Up")
    r.upBtn = MiniButton(r, "Interface\\Buttons\\Arrow-Up-Up")

    r.upBtn:SetScript("OnClick", function()
        local m = r.item and r.item.m
        if m and CanPromote(m) then Promote(m) end
    end)
    r.upBtn.ShowTip = function(s)
        local m = r.item and r.item.m
        if not m then return end
        local ok, why = CanPromote(m)
        ActionTip(s, "Promote to " .. (ns.ranks[m.rankIndex - 1] or "?"), ok, why)
    end

    r.downBtn:SetScript("OnClick", function()
        local m = r.item and r.item.m
        if m and CanDemote(m) then Demote(m) end
    end)
    r.downBtn.ShowTip = function(s)
        local m = r.item and r.item.m
        if not m then return end
        local ok, why = CanDemote(m)
        ActionTip(s, "Demote to " .. (ns.ranks[m.rankIndex + 1] or "?"), ok, why)
    end

    r.kickBtn:SetScript("OnClick", function()
        local m = r.item and r.item.m
        if m and IsGM() and not IsMe(m) then
            StaticPopup_Show("GUILDLOOM_KICK", m.short, nil, m.short)
        end
    end)
    r.kickBtn.ShowTip = function(s)
        local m = r.item and r.item.m
        if not m then return end
        local me = IsMe(m)
        ActionTip(s, "Remove from guild", not me, "You can't remove yourself.")
    end
end

local function SetManageButtons(r, m)
    if not m then
        r.upBtn:Hide(); r.downBtn:Hide(); r.kickBtn:Hide()
        r.right:SetPoint("RIGHT", r, "RIGHT", -10, 0)
        return
    end
    local gm = IsGM()
    r.kickBtn:SetShown(gm)                 -- kick: Guild Master only
    r.kickBtn:SetUsable(not IsMe(m))
    r.downBtn:ClearAllPoints()
    if gm then r.downBtn:SetPoint("RIGHT", r.kickBtn, "LEFT", -3, 0)
    else r.downBtn:SetPoint("RIGHT", r, "RIGHT", -8, 0) end
    r.upBtn:ClearAllPoints()
    r.upBtn:SetPoint("RIGHT", r.downBtn, "LEFT", -3, 0)
    r.upBtn:Show(); r.downBtn:Show()       -- arrows: visible to everyone
    r.upBtn:SetUsable((CanPromote(m)))     -- ...but only usable with permission
    r.downBtn:SetUsable((CanDemote(m)))
    r.right:SetPoint("RIGHT", r.upBtn, "LEFT", -10, 0)
end

-- Up to two small text buttons on the right of a row (Requests / Alts tabs).
local function CreateActionButtons(r)
    r.acts = {}
    for i = 1, 2 do
        local b = FlatButton(r, "", 60)
        b:SetHeight(18)
        b:Hide()
        b:SetScript("OnClick", function(s) if s.fn then s.fn() end end)
        b:HookScript("OnEnter", function(s)
            if s.tip then
                GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
                GameTooltip:AddLine(s.tip, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        b:HookScript("OnLeave", function() GameTooltip:Hide() end)
        r.acts[i] = b
    end
end

local function SetActionButtons(r, actions)
    local prev
    for i, b in ipairs(r.acts) do
        local a = actions and actions[i]
        if a then
            b.text:SetText(a.label)
            b:SetWidth(max(44, b.text:GetStringWidth() + 16))
            b.fn, b.tip = a.fn, a.tip
            b:ClearAllPoints()
            if prev then b:SetPoint("RIGHT", prev, "LEFT", -4, 0)
            else b:SetPoint("RIGHT", r, "RIGHT", -8, 0) end
            b:SetActive(a.primary and true or false)
            b:Show()
            prev = b
        else
            b:Hide()
        end
    end
    if prev then r.right:SetPoint("RIGHT", prev, "LEFT", -10, 0) end
end

local function CreateRow()
    local r = CreateFrame("Button", nil, list)
    r:SetHeight(ROW_H)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.hl = r:CreateTexture(nil, "HIGHLIGHT")
    r.hl:SetAllPoints()
    Paint(r.hl, C.hover)
    r.edge = r:CreateTexture(nil, "ARTWORK")
    r.edge:SetPoint("TOPLEFT"); r.edge:SetPoint("BOTTOMLEFT")
    r.edge:SetWidth(2)
    Paint(r.edge, C.accent)

    r.toggle = Text(r, 13, C.accent, "CENTER")
    r.toggle:SetPoint("LEFT", 4, 0)
    r.toggle:SetWidth(14)
    r.dot = r:CreateTexture(nil, "ARTWORK")
    r.dot:SetSize(6, 6)
    r.dot:SetPoint("LEFT", 9, 0)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(16, 16)
    r.icon:SetPoint("LEFT", 22, 0)

    r.name = Text(r, 12)
    r.name:SetPoint("LEFT", 44, 0)
    r.name:SetWidth(150)
    r.mid = Text(r, 11, C.dim)
    r.mid:SetPoint("LEFT", 200, 0)
    r.mid:SetWidth(150)
    r.extra = Text(r, 11, C.dim)
    r.extra:SetPoint("LEFT", 360, 0)
    r.extra:SetWidth(110)
    r.right = Text(r, 11, C.text, "RIGHT")
    r.right:SetPoint("RIGHT", -10, 0)
    r.right:SetWidth(140)

    r.barBg = r:CreateTexture(nil, "ARTWORK")
    r.barBg:SetPoint("RIGHT", -10, 0)
    r.barBg:SetSize(150, 12)
    r.barBg:SetColorTexture(1, 1, 1, 0.06)
    r.bar = r:CreateTexture(nil, "ARTWORK", nil, 1)
    r.bar:SetPoint("LEFT", r.barBg, "LEFT")
    r.bar:SetHeight(12)
    r.barText = Text(r, 10, C.text, "CENTER")
    r.barText:SetPoint("CENTER", r.barBg)

    CreateManageButtons(r)
    CreateActionButtons(r)

    r:SetScript("OnClick", RowClick)
    r:SetScript("OnEnter", RowTooltip)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return r
end

local function SetRow(r, it, idx)
    r.item = it
    if it.header then
        r.bg:SetColorTexture(unpack(C.header))
        r.edge:Show()
        r.toggle:SetText(it.collapsed and "+" or "-")
        r.toggle:Show()
        r.dot:Hide()
        r.icon:SetDesaturated(false)
        r.icon:SetAlpha(1)
        SetIcon(r.icon, it.icon)
        r.name:SetText(it.text)
        r.name:SetTextColor(unpack(C.text))
        r.name:SetWidth(r.headerW or 260)
        r.mid:SetText("")
        r.extra:SetText("")
        r.right:SetText(it.right or "")
        r.right:SetTextColor(unpack(C.dim))
        r.right:Show()
        r.barBg:Hide(); r.bar:Hide(); r.barText:Hide()
        r.right:SetWidth(r.rightW or 140)
        SetManageButtons(r, nil)
        SetActionButtons(r, nil)
        return
    end
    SetManageButtons(r, it.manage and it.m or nil)
    SetActionButtons(r, it.actions)
    r.mid:SetWidth(it.midW or r.midW or 150)
    r.right:SetWidth(it.rightW or r.rightW or 140)

    local m = it.m
    r.bg:SetColorTexture(1, 1, 1, (idx % 2 == 0) and 0.025 or 0)
    r.edge:Hide()
    r.toggle:Hide()
    r.dot:Show()
    r.dot:SetColorTexture(unpack(m.online and (m.mobile and C.mobile or C.online) or C.offline))
    SetClassIcon(r.icon, m.classFile)
    r.icon:SetDesaturated(not m.online)
    r.icon:SetAlpha(m.online and 1 or 0.6)

    local cr, cg, cb = ClassColor(m.classFile)
    if not m.online then cr, cg, cb = cr * 0.6, cg * 0.6, cb * 0.6 end
    r.name:SetWidth(r.nameW or 150)
    r.name:SetText(m.short)
    r.name:SetTextColor(cr, cg, cb)
    r.mid:SetText(it.mid or "")
    r.extra:SetText(it.extra or "")

    if it.bar then
        r.right:Hide()
        r.barBg:Show(); r.bar:Show(); r.barText:Show()
        local frac = max(0, min(1, it.bar))
        r.bar:SetWidth(max(1, (r.barW or 150) * frac))
        local col = frac >= 1 and C.good or C.accent
        r.bar:SetColorTexture(col[1], col[2], col[3], 0.75)
        r.barText:SetText(it.barText or "")
    else
        r.barBg:Hide(); r.bar:Hide(); r.barText:Hide()
        r.right:Show()
        r.right:SetText(it.right or "")
        r.right:SetTextColor(unpack(C.text))
    end
end

function list:GPRefresh()
    local n = self.numVisible or 0
    local total = #self.items
    local maxOff = max(0, total - n)
    if self.offset > maxOff then self.offset = maxOff end
    slider:SetMinMaxValues(0, maxOff)
    slider:SetValue(self.offset)
    slider:SetShown(maxOff > 0)
    for i = 1, n do
        local r = self.rows[i]
        local it = self.items[self.offset + i]
        if it then SetRow(r, it, self.offset + i); r:Show()
        else r.item = nil; r:Hide() end
    end
    emptyText:SetShown(total == 0)
end

function list:GPLayout()
    local h = self:GetHeight() - 4
    local n = max(1, floor(h / ROW_H))
    self.numVisible = n
    local narrow = self:GetWidth() < 560
    for i = 1, n do
        local r = self.rows[i]
        if not r then r = CreateRow(); self.rows[i] = r end
        -- Responsive columns: drop the "last seen" column in narrow windows.
        r.nameW   = narrow and 110 or 150
        r.headerW = narrow and 170 or 260
        r.barW    = narrow and 90 or 150
        r.mid:ClearAllPoints()
        r.mid:SetPoint("LEFT", narrow and 158 or 200, 0)
        r.midW    = narrow and 80 or 150
        r.rightW  = narrow and 90 or 140
        r.mid:SetWidth(r.midW)
        r.extra:SetShown(not narrow)
        r.barBg:SetWidth(r.barW)
        r.right:SetWidth(r.rightW)
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", self, "TOPLEFT", 2, -2 - (i - 1) * ROW_H)
        r:SetPoint("RIGHT", slider, "LEFT", -3, 0)
    end
    for i = n + 1, #self.rows do self.rows[i]:Hide(); self.rows[i].item = nil end
    self:GPRefresh()
end

function list:GPSetItems(items, emptyMsg)
    self.items = items
    emptyText:SetText(emptyMsg or "Nothing to show.")
    self:GPRefresh()
end

slider:SetScript("OnValueChanged", function(_, v)
    v = floor(v + 0.5)
    if v ~= list.offset then
        list.offset = v
        list:GPRefresh()
    end
end)
list:SetScript("OnMouseWheel", function(_, delta)
    local step = IsShiftKeyDown() and 15 or 3
    slider:SetValue(list.offset - delta * step)
end)
list:SetScript("OnSizeChanged", function(self) self:GPLayout() end)

---------------------------------------------------------------------------
-- Item builders
---------------------------------------------------------------------------
local Build = {}

function Build.ranks(items)
    local groups = {}
    local maxRank = -1
    for r in pairs(ns.ranks) do maxRank = max(maxRank, r) end
    for _, m in ipairs(ns.members) do
        maxRank = max(maxRank, m.rankIndex)
        if Matches(m) then
            local g = groups[m.rankIndex]
            if not g then g = {}; groups[m.rankIndex] = g end
            g[#g + 1] = m
        end
    end
    local headers = {}
    for r = 0, maxRank do
        local g = groups[r] or {}
        if #g > 0 or not Filtering() then
            local online = 0
            for _, m in ipairs(g) do if m.online then online = online + 1 end end
            local key = "ranks:" .. r
            local collapsed = IsCollapsed(key)
            local h = {
                header = true, key = key, collapsed = collapsed,
                text = (ns.ranks[r] or ("Rank " .. (r + 1))) .. (r == 0 and ("  " .. Hex(C.dim) .. "(Guild Master)|r") or ""),
                right = ("|cff4ade80%d|r online   %d members"):format(online, #g),
            }
            items[#items + 1] = h
            headers[#headers + 1] = key
            if not collapsed then
                table.sort(g, ByOnlineLevelName)
                for _, m in ipairs(g) do
                    items[#items + 1] = { m = m, manage = true, mid = m.note, extra = LastSeen(m), right = "Lv " .. m.level }
                end
            end
        end
    end
    return headers
end

local function OnlineFirstM(a, b)
    if a.m.online ~= b.m.online then return a.m.online end
    return a.m.short < b.m.short
end

function Build.profs(items)
    local data = ns.GetProfData()
    local groups, order, nodata = {}, {}, {}

    -- Recipe search: typing 3+ letters also searches everyone's shared recipes.
    local recipeHeader
    if #ns.query >= 3 then
        local res = ns.SearchRecipes(ns.query, 150)
        if #res > 0 then
            recipeHeader = "profs:__recipes"
            local collapsed = IsCollapsed(recipeHeader)
            items[#items + 1] = {
                header = true, key = recipeHeader, collapsed = collapsed,
                text = ("Recipes matching \"%s\""):format(ns.query),
                right = (#res >= 150 and "150+" or #res) .. " found",
                tip = "From recipe lists shared by guildmates running Guildloom. A crafter's list is shared after they open that profession window once.",
            }
            if not collapsed then
                table.sort(res, OnlineFirstM)
                for _, e in ipairs(res) do
                    items[#items + 1] = { m = e.m, mid = e.recipe, midW = 190, extra = "", right = e.prof .. "   " .. LastSeen(e.m), rightW = 170 }
                end
            end
        end
    end
    for _, m in ipairs(ns.members) do
        local e = data[m.name]
        if e and e.list and #e.list > 0 then
            for _, p in ipairs(e.list) do
                if Matches(m, p.n) then
                    local g = groups[p.n]
                    if not g then
                        g = { name = p.n, icon = p.i, list = {}, cap = 0 }
                        groups[p.n] = g
                        order[#order + 1] = g
                    end
                    if not g.icon and p.i then g.icon = p.i end
                    g.cap = max(g.cap, p.m or 0, p.s or 0)
                    g.list[#g.list + 1] = { m = m, p = p }
                end
            end
        elseif Matches(m) then
            nodata[#nodata + 1] = m
        end
    end
    -- Professions the game says exist in the guild, even if nobody is named yet.
    local counts = ns.GetProfCounts()
    if not ns.db.onlineOnly then
        for name, c in pairs(counts) do
            if not groups[name] and (c.count or 0) > 0
               and (ns.query == "" or name:lower():find(ns.query, 1, true)) then
                local g = { name = name, icon = c.icon, list = {}, cap = 0 }
                groups[name] = g
                order[#order + 1] = g
            end
        end
    end
    table.sort(order, function(a, b) return a.name < b.name end)

    local headers = {}
    if recipeHeader then headers[1] = recipeHeader end
    for _, g in ipairs(order) do
        local key = "profs:" .. g.name
        local collapsed = IsCollapsed(key)
        local maxed = 0
        for _, e in ipairs(g.list) do
            if e.p.m and e.p.m > 0 and e.p.s >= e.p.m then maxed = maxed + 1 end
        end
        local c = counts[g.name]
        local total = c and c.count or 0
        if not g.icon and c then g.icon = c.icon end
        local who = (total > #g.list)
            and ("%d of %d known"):format(#g.list, total)
            or ("%d members"):format(#g.list)
        items[#items + 1] = {
            header = true, key = key, collapsed = collapsed, icon = g.icon, text = g.name,
            right = who .. ("   |cff4ade80%d|r maxed"):format(maxed),
            tip = (total > #g.list) and ("The guild has %d members with %s. The game only names members while they are online - the rest are filled in automatically as they log in (or right away if they use Guildloom)."):format(total, g.name) or nil,
        }
        headers[#headers + 1] = key
        if not collapsed then
            table.sort(g.list, function(a, b)
                if a.p.s ~= b.p.s then return a.p.s > b.p.s end
                return ByOnlineLevelName(a.m, b.m)
            end)
            local cap = max(g.cap, 1)
            for _, e in ipairs(g.list) do
                local denom = (e.p.m and e.p.m > 0) and e.p.m or cap
                items[#items + 1] = {
                    m = e.m, mid = e.m.rank, extra = LastSeen(e.m),
                    bar = e.p.s / denom, barText = SkillText(e.p),
                }
            end
        end
    end

    if #nodata > 0 then
        local key = "profs:__nodata"
        local collapsed = IsCollapsed(key, true)
        items[#items + 1] = {
            header = true, key = key, collapsed = collapsed, defaultCollapsed = true,
            text = Hex(C.dim) .. "No profession data|r",
            right = #nodata .. " members",
            tip = "These members haven't shared their professions yet. They need Guildloom installed (or the game's guild profession directory must list them).",
        }
        headers[#headers + 1] = key
        if not collapsed then
            table.sort(nodata, ByOnlineLevelName)
            for _, m in ipairs(nodata) do
                items[#items + 1] = { m = m, mid = m.rank, extra = LastSeen(m), right = "Lv " .. m.level }
            end
        end
    end
    return headers
end

---------------------------------------------------------------------------
-- Requests tab
---------------------------------------------------------------------------
local function Ago(t)
    local s = max(0, time() - (t or time()))
    if s < 60 then return "just now"
    elseif s < 3600 then return floor(s / 60) .. "m ago"
    elseif s < 86400 then return floor(s / 3600) .. "h ago"
    else return floor(s / 86400) .. "d ago" end
end

-- Requests can come from people who have since left the guild.
local function MemberOrStub(full)
    return ns.byName[full] or {
        name = full, short = ns.Short(full), rank = "", rankIndex = 99, level = 0,
        note = "", onote = "", online = false, lastOnline = 0,
    }
end

local function RequestTooltip(r)
    return function(owner)
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        local link = r.text:match("|H(.-)|h")
        local shown = false
        if link then shown = pcall(GameTooltip.SetHyperlink, GameTooltip, link) end
        if not shown then GameTooltip:AddLine(r.text, 1, 1, 1, true) end
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Requested by", ns.Short(r.from), 0.6, 0.6, 0.6, 1, 1, 1)
        if r.prof ~= "" then GameTooltip:AddDoubleLine("Profession", r.prof, 0.6, 0.6, 0.6, 1, 1, 1) end
        GameTooltip:AddDoubleLine("Posted", Ago(r.t), 0.6, 0.6, 0.6, 1, 1, 1)
        if r.by then
            GameTooltip:AddDoubleLine(r.status == "done" and "Crafted by" or "Being crafted by",
                ns.Short(r.by), 0.6, 0.6, 0.6, 1, 0.82, 0)
        end
        local crafters = ns.FindCrafters(r.text, r.prof)
        if #crafters > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Known crafters", C.accent[1], C.accent[2], C.accent[3])
            for i = 1, min(8, #crafters) do
                local c = crafters[i]
                local cr, cg, cb = ClassColor(c.m.classFile)
                GameTooltip:AddDoubleLine(c.m.short, c.m.online and "online" or LastSeen(c.m), cr, cg, cb, 0.7, 0.7, 0.7)
            end
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click: whisper the requester", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end
end

local function RequestItem(r, me)
    local mine, byMe = r.from == me, r.by == me
    local acts = {}
    if r.status == "open" then
        if mine then
            acts[1] = { label = "Cancel", fn = function() ns.CancelRequest(r.id) end, tip = "Remove your request." }
        else
            acts[1] = { label = "I'll craft it", primary = ns.CanICraftRequest(r),
                fn = function() ns.ClaimRequest(r.id, true) end,
                tip = "Tell everyone you're making this, so nobody else does it twice." }
        end
    elseif r.status == "claimed" then
        if byMe then
            acts[1] = { label = "Done", primary = true, fn = function() ns.CompleteRequest(r.id) end, tip = "Crafted and sent." }
            acts[2] = { label = "Drop", fn = function() ns.ClaimRequest(r.id, false) end, tip = "Give the request back to the guild." }
        elseif mine then
            acts[1] = { label = "Received", primary = true, fn = function() ns.CompleteRequest(r.id) end, tip = "Mark as done." }
            acts[2] = { label = "Cancel", fn = function() ns.CancelRequest(r.id) end, tip = "Remove your request." }
        end
    elseif mine then
        acts[1] = { label = "Remove", fn = function() ns.CancelRequest(r.id) end }
    end

    local status
    if r.status == "claimed" then
        status = "|cffffd100" .. ns.Short(r.by or "?") .. " crafting|r"
    elseif r.status == "done" then
        status = "|cff4ade80Done|r" .. (r.by and (" by " .. ns.Short(r.by)) or "")
    else
        status = (r.prof ~= "" and r.prof or "Any profession")
    end
    return {
        m = MemberOrStub(r.from), mid = r.text, midW = 170, extra = "",
        right = status .. "  " .. Hex(C.dim) .. Ago(r.t) .. "|r", rightW = 170,
        actions = acts, tooltip = RequestTooltip(r),
    }
end

function Build.requests(items)
    ns.PruneRequests()
    local me, q = ns.MyName(), ns.query
    local groups = { open = {}, claimed = {}, done = {} }
    for _, r in pairs(ns.GetRequests()) do
        local hay = (r.text .. " " .. (r.prof or "") .. " " .. ns.Short(r.from) .. " " ..
                    (r.by and ns.Short(r.by) or "")):lower()
        if q == "" or hay:find(q, 1, true) then
            local g = groups[r.status] or groups.open
            g[#g + 1] = r
        end
    end
    local headers = {}
    for _, d in ipairs({ { "open", "Open requests" }, { "claimed", "Being crafted" }, { "done", "Done (last 24h)" } }) do
        local key, rows = "requests:" .. d[1], groups[d[1]]
        if #rows > 0 or d[1] == "open" then
            table.sort(rows, function(a, b) return a.t > b.t end)
            local collapsed = IsCollapsed(key)
            items[#items + 1] = {
                header = true, key = key, collapsed = collapsed, text = d[2],
                right = #rows .. (#rows == 1 and " request" or " requests"),
            }
            headers[#headers + 1] = key
            if not collapsed then
                for _, r in ipairs(rows) do items[#items + 1] = RequestItem(r, me) end
            end
        end
    end
    return headers
end

---------------------------------------------------------------------------
-- Activity tab (officer tool)
---------------------------------------------------------------------------
function Build.activity(items)
    local limit = (ns.db.inactiveDays or 30) * 24
    local groups, maxRank, total = {}, -1, 0
    for _, m in ipairs(ns.members) do
        if not m.online and m.lastOnline >= limit and Matches(m, nil, true) then
            local playerLast = ns.PlayerLastOnline(m)
            if not (ns.db.hideActiveAlts and playerLast < limit) then
                local g = groups[m.rankIndex]
                if not g then g = {}; groups[m.rankIndex] = g end
                g[#g + 1] = m
                total = total + 1
                maxRank = max(maxRank, m.rankIndex)
            end
        end
    end
    ns.activityTotal = total
    local headers = {}
    for r = 0, maxRank do
        local g = groups[r]
        if g then
            local key = "activity:" .. r
            local collapsed = IsCollapsed(key)
            items[#items + 1] = {
                header = true, key = key, collapsed = collapsed,
                text = ns.ranks[r] or ("Rank " .. (r + 1)),
                right = #g .. " inactive",
            }
            headers[#headers + 1] = key
            if not collapsed then
                table.sort(g, function(a, b)
                    if a.lastOnline ~= b.lastOnline then return a.lastOnline > b.lastOnline end
                    return a.short < b.short
                end)
                for _, m in ipairs(g) do
                    local main = ns.MainOf(m)
                    items[#items + 1] = {
                        m = m, manage = true,
                        mid = main and ("Alt of " .. main.short) or m.note,
                        extra = LastSeen(m), right = "Lv " .. m.level,
                    }
                end
            end
        end
    end
    return headers
end

---------------------------------------------------------------------------
-- Alts tab
---------------------------------------------------------------------------
local function AltRow(m, role) -- role: "main" | "alt" | nil (not linked)
    local acts = {}
    local picking = ns.pickAltFor
    if picking then
        if picking.name == m.name then
            acts[1] = { label = "Cancel", primary = true, fn = function() ns.pickAltFor = nil; ns.RefreshUI() end }
        end
    elseif role == "alt" then
        acts[1] = { label = "Unlink", fn = function() ns.Unlink(m) end, tip = "This character is not an alt." }
    elseif role == nil then
        acts[1] = { label = "Set main...", fn = function() ns.pickAltFor = m; ns.RefreshUI() end,
                    tip = "Mark this character as an alt, then click its main character." }
    end
    local mid
    if role == "main" then mid = Hex(C.accent) .. "Main|r"
    elseif role == "alt" then mid = "Alt" .. (ns.altSource[m.name] == "note" and (Hex(C.dim) .. "  (from note)|r") or "")
    else mid = m.note end
    return { m = m, mid = mid, extra = LastSeen(m), right = "Lv " .. m.level, actions = acts }
end

function Build.alts(items)
    local headers = {}
    if ns.pickAltFor then
        items[#items + 1] = {
            header = true, key = "alts:__pick", collapsed = false,
            text = Hex(C.accent) .. "Now click the MAIN character of " .. ns.pickAltFor.short .. "|r",
            right = "", tip = "Click any member below. Press Cancel on the highlighted character to stop.",
        }
    end

    local mains, linked = {}, {}
    for mainFull in pairs(ns.altsOf) do
        if ns.byName[mainFull] then mains[#mains + 1] = ns.byName[mainFull] end
    end
    table.sort(mains, function(a, b) return a.short < b.short end)

    for _, main in ipairs(mains) do
        local alts = ns.AltsOf(main)
        local chars = { main }
        for _, a in ipairs(alts) do chars[#chars + 1] = a end
        local show, onlineChar = false, nil
        for _, c in ipairs(chars) do
            linked[c.name] = true
            if Matches(c) then show = true end
            if c.online and not onlineChar then onlineChar = c end
        end
        if show then
            local key = "alts:" .. main.name
            local collapsed = IsCollapsed(key)
            items[#items + 1] = {
                header = true, key = key, collapsed = collapsed,
                text = main.short .. "  " .. Hex(C.dim) .. "(" .. main.rank .. ")|r",
                right = (onlineChar and ("|cff4ade80" .. onlineChar.short .. " online|r   ") or "") .. #chars .. " characters",
            }
            headers[#headers + 1] = key
            if not collapsed then
                items[#items + 1] = AltRow(main, "main")
                for _, a in ipairs(alts) do items[#items + 1] = AltRow(a, "alt") end
            end
        end
    end

    local rest = {}
    for _, m in ipairs(ns.members) do
        if not linked[m.name] and Matches(m) then rest[#rest + 1] = m end
    end
    if #rest > 0 then
        local key = "alts:__unlinked"
        local collapsed = IsCollapsed(key) and not ns.pickAltFor
        items[#items + 1] = {
            header = true, key = key, collapsed = collapsed,
            text = Hex(C.dim) .. "Not linked|r", right = #rest .. " members",
            tip = "Use \"Set main...\" to link a character by hand, or put \"alt of <name>\" in its public or officer note.",
        }
        headers[#headers + 1] = key
        if not collapsed then
            table.sort(rest, ByOnlineLevelName)
            for _, m in ipairs(rest) do items[#items + 1] = AltRow(m, nil) end
        end
    end
    return headers
end

local currentHeaders = {}
expandBtn:SetScript("OnClick", function()
    -- If anything is expanded, collapse everything; otherwise expand everything.
    local anyOpen = false
    for _, key in ipairs(currentHeaders) do
        if not IsCollapsed(key) then anyOpen = true break end
    end
    for _, key in ipairs(currentHeaders) do ns.db.collapsed[key] = anyOpen end
    ns.RefreshUI()
end)

---------------------------------------------------------------------------
-- Overview
---------------------------------------------------------------------------
local OV = CreateFrame("Frame", nil, content)
OV:SetAllPoints()
OV:Hide()

OV.cards = {}
for i = 1, 4 do
    local c = CreateFrame("Frame", nil, OV, "BackdropTemplate")
    SetBD(c, C.well, C.border)
    Chrome(c, "InsetFrameTemplate", 6)
    c:SetHeight(64)
    c.value = Text(c, 22, C.text)
    c.value:SetPoint("TOPLEFT", 12, -10)
    c.label = Text(c, 10, C.dim)
    c.label:SetPoint("BOTTOMLEFT", 12, 10)
    c.stripe = c:CreateTexture(nil, "ARTWORK")
    c.stripe:SetPoint("TOPLEFT", 1, -1); c.stripe:SetPoint("TOPRIGHT", -1, -1)
    c.stripe:SetHeight(2)
    Paint(c.stripe, C.accent)
    OV.cards[i] = c
end

local function Panel(titleText)
    local p = CreateFrame("Frame", nil, OV, "BackdropTemplate")
    SetBD(p, C.well, C.border)
    Chrome(p, "InsetFrameTemplate", 6)
    p.title = Text(p, 12, C.text)
    p.title:SetPoint("TOPLEFT", 12, -10)
    p.title:SetText(titleText)
    p.bars = {}
    return p
end
OV.left = Panel("Classes")
OV.right = Panel("Professions")

local function GetBar(p, i)
    local b = p.bars[i]
    if not b then
        b = CreateFrame("Frame", nil, p)
        b:SetHeight(22)
        b.label = Text(b, 11, C.text)
        b.label:SetPoint("TOPLEFT")
        b.value = Text(b, 11, C.dim, "RIGHT")
        b.value:SetPoint("TOPRIGHT")
        b.track = b:CreateTexture(nil, "BACKGROUND")
        b.track:SetPoint("TOPLEFT", 0, -15)
        b.track:SetPoint("TOPRIGHT", 0, -15)
        b.track:SetHeight(5)
        b.track:SetColorTexture(1, 1, 1, 0.06)
        b.fill = b:CreateTexture(nil, "ARTWORK")
        b.fill:SetPoint("TOPLEFT", b.track, "TOPLEFT")
        b.fill:SetHeight(5)
        p.bars[i] = b
    end
    return b
end

local function FillPanel(p, rows, width)
    local inner = width - 24
    local maxRows = max(0, floor((p:GetHeight() - 40) / 26))
    if maxRows == 0 then maxRows = 10 end
    local top = 1
    for _, r in ipairs(rows) do top = max(top, r.count) end
    local shown = 0
    for i, r in ipairs(rows) do
        if i > maxRows then break end
        local b = GetBar(p, i)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", 12, -34 - (i - 1) * 26)
        b:SetWidth(inner)
        b.label:SetText(r.label)
        b.label:SetTextColor(r.r or 1, r.g or 1, r.b or 1)
        b.value:SetText(r.value)
        b.fill:SetWidth(max(1, inner * r.count / top))
        b.fill:SetColorTexture(r.r or C.accent[1], r.g or C.accent[2], r.b or C.accent[3], 0.85)
        b:Show()
        shown = i
    end
    for i = shown + 1, #p.bars do p.bars[i]:Hide() end
    if not p.empty then
        p.empty = Text(p, 11, C.dim, "CENTER")
        p.empty:SetPoint("CENTER")
        p.empty:SetWidth(width - 30)
        p.empty:SetWordWrap(true)
    end
    p.empty:SetShown(#rows == 0)
end

function OV:Update()
    local w = self:GetWidth()
    if not w or w <= 0 then w = 640 end
    local cw = (w - 24) / 4
    for i, c in ipairs(self.cards) do
        c:ClearAllPoints()
        c:SetWidth(cw)
        c:SetPoint("TOPLEFT", (i - 1) * (cw + 8), 0)
    end
    local pw = (w - 8) / 2
    self.left:ClearAllPoints()
    self.left:SetPoint("TOPLEFT", 0, -72)
    self.left:SetPoint("BOTTOMLEFT")
    self.left:SetWidth(pw)
    self.right:ClearAllPoints()
    self.right:SetPoint("TOPRIGHT", 0, -72)
    self.right:SetPoint("BOTTOMRIGHT")
    self.right:SetWidth(pw)

    local maxLvl = (GetMaxLevelForPlayerExpansion and GetMaxLevelForPlayerExpansion())
                or (GetMaxPlayerLevel and GetMaxPlayerLevel()) or 60
    local total, online, lvlSum, atMax = #ns.members, 0, 0, 0
    local classes, classOrder = {}, {}
    for _, m in ipairs(ns.members) do
        if m.online then online = online + 1 end
        lvlSum = lvlSum + m.level
        if m.level >= maxLvl then atMax = atMax + 1 end
        local k = m.classFile or "UNKNOWN"
        local c = classes[k]
        if not c then
            c = { label = m.class or "Unknown", count = 0, online = 0, key = k }
            classes[k] = c
            classOrder[#classOrder + 1] = c
        end
        c.count = c.count + 1
        if m.online then c.online = c.online + 1 end
    end

    self.cards[1].value:SetText(total)
    self.cards[1].label:SetText("MEMBERS")
    self.cards[2].value:SetText(("|cff4ade80%d|r"):format(online))
    self.cards[2].label:SetText(("ONLINE NOW (%d%%)"):format(total > 0 and floor(online / total * 100 + 0.5) or 0))
    self.cards[3].value:SetText(total > 0 and ("%.1f"):format(lvlSum / total) or "-")
    self.cards[3].label:SetText("AVERAGE LEVEL")
    self.cards[4].value:SetText(atMax)
    self.cards[4].label:SetText(("AT MAX LEVEL (%d)"):format(maxLvl))

    table.sort(classOrder, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.label < b.label
    end)
    local crow = {}
    for _, c in ipairs(classOrder) do
        local r, g, b = ClassColor(c.key)
        crow[#crow + 1] = { label = c.label, value = ("%d  (|cff4ade80%d|r on)"):format(c.count, c.online),
                            count = c.count, r = r, g = g, b = b }
    end
    FillPanel(self.left, crow, pw)
    self.left.empty:SetText("No members.")

    local data = ns.GetProfData()
    local profs, porder, shared = {}, {}, 0
    for _, m in ipairs(ns.members) do
        local e = data[m.name]
        if e and e.list and #e.list > 0 then
            shared = shared + 1
            for _, p in ipairs(e.list) do
                local g = profs[p.n]
                if not g then g = { label = p.n, count = 0, sum = 0 }; profs[p.n] = g; porder[#porder + 1] = g end
                g.count = g.count + 1
                g.sum = g.sum + (p.s or 0)
            end
        end
    end
    -- Merge in the guild-wide totals from the game's profession directory.
    for name, c in pairs(ns.GetProfCounts()) do
        local g = profs[name]
        if not g and (c.count or 0) > 0 then
            g = { label = name, count = 0, sum = 0 }
            profs[name] = g
            porder[#porder + 1] = g
        end
        if g then g.total = c.count end
    end
    for _, g in ipairs(porder) do g.sortCount = max(g.count, g.total or 0) end
    table.sort(porder, function(a, b)
        if a.sortCount ~= b.sortCount then return a.sortCount > b.sortCount end
        return a.label < b.label
    end)
    local prow = {}
    for _, g in ipairs(porder) do
        local value
        if g.total and g.total > g.count then
            value = ("%d in guild  (%d known)"):format(g.total, g.count)
        elseif g.count > 0 then
            value = ("%d  (avg %d)"):format(g.count, floor(g.sum / g.count + 0.5))
        else
            value = tostring(g.total or 0)
        end
        prow[#prow + 1] = { label = g.label, count = g.sortCount, value = value }
    end
    self.right.title:SetText(("Professions  %s%d/%d shared|r"):format(Hex(C.dim), shared, total))
    FillPanel(self.right, prow, pw)
    self.right.empty:SetText("No profession data yet.\nGuildmates with Guildloom share theirs automatically - press Sync on the Professions tab.")
end

OV:SetScript("OnSizeChanged", function(self) if self:IsShown() then self:Update() end end)

---------------------------------------------------------------------------
-- Refresh / tab switching
---------------------------------------------------------------------------
function ns.RefreshUI()
    if ns.UpdateSideTabs then ns.UpdateSideTabs() end
    if not F:IsShown() or not ns.db then return end

    local gname = ns.GuildName()
    local brand = Hex(C.accent) .. "Guild|rloom"
    title:SetText(gname and (brand .. "  " .. Hex(C.dim) .. gname .. "|r") or brand)
    local online = 0
    for _, m in ipairs(ns.members) do if m.online then online = online + 1 end end
    subtitle:SetText(("|cff4ade80%d|r online  /  %d members"):format(online, #ns.members))

    local tab = ns.db.tab
    for _, b in ipairs(tabButtons) do
        local sel = b.key == tab
        b.line:SetShown(sel)
        b.text:SetTextColor(unpack(sel and C.text or C.dim))
    end

    -- Toolbar: which controls each tab uses
    local isList = tab ~= "overview"
    search:SetShown(isList)
    onlineBtn:SetShown(tab == "ranks" or tab == "profs" or tab == "alts")
    expandBtn:SetShown(isList)
    daysBtn:SetShown(tab == "activity")
    altsBtn:SetShown(tab == "activity")
    syncBtn:SetShown(tab == "profs")
    newReqBtn:SetShown(tab == "requests")
    onlineBtn:SetActive(ns.db.onlineOnly)
    altsBtn:SetActive(ns.db.hideActiveAlts)
    daysBtn.text:SetText((ns.db.inactiveDays or 30) .. "+ days")
    LayoutToolbar()

    if not IsInGuild() then
        OV:Hide(); list:Show()
        footer:SetText("")
        list:GPSetItems({}, "You are not in a guild.")
        return
    end

    if tab == "overview" then
        list:Hide(); OV:Show()
        footer:SetText("Shift + mouse wheel scrolls faster in lists.")
        OV:Update()
        return
    end

    OV:Hide(); list:Show()
    local items = {}
    wipe(currentHeaders)
    local headers = Build[tab](items)
    if headers then for _, k in ipairs(headers) do currentHeaders[#currentHeaders + 1] = k end end
    local any = false
    for _, k in ipairs(currentHeaders) do
        if not IsCollapsed(k) then any = true break end
    end
    expandBtn.text:SetText(any and "Collapse all" or "Expand all")

    local empty = Filtering() and "No members match your filter." or "No members."
    if tab == "profs" then
        local data, shared = ns.GetProfData(), 0
        for _, m in ipairs(ns.members) do if data[m.name] then shared = shared + 1 end end
        footer:SetText(("Professions from %d of %d members, recipes from %d. Type 3+ letters to search recipes."):format(
            shared, #ns.members, ns.RecipeCoverage()))
    elseif tab == "ranks" then
        footer:SetText(IsGM()
            and "Arrows promote / demote, x removes from guild. Greyed-out arrows mean the rank rules don't allow it."
            or "Arrows promote / demote. They are greyed out when your rank doesn't have permission.")
    elseif tab == "requests" then
        footer:SetText("Requests are shared with guildmates running Guildloom. Crafters get a chat alert when they can help.")
        empty = "No requests yet. Press \"+ New request\" to ask the guild for something."
    elseif tab == "activity" then
        footer:SetText(("%d of %d members haven't been online for %d+ days%s."):format(
            ns.activityTotal or 0, #ns.members, ns.db.inactiveDays or 30,
            ns.db.hideActiveAlts and " (alts of active players skipped)" or ""))
        empty = "Nobody has been inactive that long."
    elseif tab == "alts" then
        local nAlts = 0
        for _ in pairs(ns.mainOf) do nAlts = nAlts + 1 end
        footer:SetText(ns.pickAltFor and ("Click the main character of " .. ns.pickAltFor.short .. ".")
            or (("%d alts linked. Notes like \"alt of Mad Parrot\" are detected automatically."):format(nAlts)))
    end
    list:GPSetItems(items, empty)
end

function SelectTab(key)
    if ns.db.tab ~= key then
        list.offsets[ns.db.tab] = list.offset
        ns.db.tab = key
        list.offset = list.offsets[key] or 0
        ns.pickAltFor = nil
    end
    if key == "profs" or key == "overview" then ns.RefreshGuildTradeSkills() end
    ns.RefreshUI()
end

---------------------------------------------------------------------------
-- Window positioning
---------------------------------------------------------------------------
function ns.ApplyPosition()
    local db = ns.db
    F:ClearAllPoints()
    if db.size then F:SetSize(db.size[1], db.size[2]) else F:SetSize(680, 540) end
    if db.pos then
        F:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.pos[1], db.pos[2])
    else
        F:SetPoint("CENTER")
    end
end

function ns.Toggle()
    if F:IsShown() then
        F:Hide()
        return
    end
    ns.RequestRoster()
    ns.ApplyPosition()
    F:Show()
    if ns.db.tab == "profs" or ns.db.tab == "overview" then ns.RefreshGuildTradeSkills() end
end

F:SetScript("OnShow", function()
    ns.ScanRoster()
    if list:GetHeight() > 0 then list:GPLayout() end
    ns.RefreshUI()
end)

---------------------------------------------------------------------------
-- Minimap button (left-click: open/close, right-click: sync, drag: move)
---------------------------------------------------------------------------
local mmb = CreateFrame("Button", "GuildloomMinimapButton", Minimap)
mmb:SetSize(31, 31)
mmb:SetFrameStrata("MEDIUM")
mmb:SetFrameLevel(8)
mmb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mmb:RegisterForDrag("LeftButton")
mmb:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local mmBg = mmb:CreateTexture(nil, "BACKGROUND")
mmBg:SetSize(20, 20)
mmBg:SetPoint("TOPLEFT", 7, -5)
mmBg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

local mmIcon = mmb:CreateTexture(nil, "ARTWORK")
mmIcon:SetSize(18, 18)
mmIcon:SetPoint("TOPLEFT", 7, -6)
mmIcon:SetTexture("Interface\\Icons\\INV_Shirt_GuildTabard_01")
mmIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

local mmBorder = mmb:CreateTexture(nil, "OVERLAY")
mmBorder:SetSize(53, 53)
mmBorder:SetPoint("TOPLEFT")
mmBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local function PlaceMinimapButton()
    local a = math.rad((ns.db and ns.db.minimapAngle) or 200)
    local r = (Minimap:GetWidth() / 2) + 10
    mmb:ClearAllPoints()
    mmb:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

local function MinimapDragUpdate()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local s = Minimap:GetEffectiveScale()
    ns.db.minimapAngle = math.deg(math.atan2(py / s - my, px / s - mx))
    PlaceMinimapButton()
end

mmb:SetScript("OnDragStart", function(s)
    s:LockHighlight()
    s:SetScript("OnUpdate", MinimapDragUpdate)
end)
mmb:SetScript("OnDragStop", function(s)
    s:UnlockHighlight()
    s:SetScript("OnUpdate", nil)
end)
mmb:SetScript("OnClick", function(_, button)
    if button == "RightButton" then
        ns.UpdateOwn(true)
        ns.RequestSync()
        ns.Print("Sync requested.")
    elseif IsShiftKeyDown() then
        ns.ToggleNotices()
    else
        ns.Toggle()
    end
end)
-- Badge: open requests I can craft
local badge = CreateFrame("Frame", nil, mmb)
badge:SetSize(15, 15)
badge:SetPoint("TOPRIGHT", 1, 1)
badge:SetFrameLevel(mmb:GetFrameLevel() + 5)
badge.bg = badge:CreateTexture(nil, "OVERLAY")
badge.bg:SetAllPoints()
badge.bg:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
badge.bg:SetVertexColor(0.9, 0.2, 0.2)
badge.text = badge:CreateFontString(nil, "OVERLAY")
badge.text:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
badge.text:SetPoint("CENTER", 0, 0)
badge:Hide()

local craftableCount = 0
function ns.UpdateBadge()
    if not ns.db then return end
    craftableCount = IsInGuild() and ns.CountCraftableRequests() or 0
    badge:SetShown(craftableCount > 0)
    badge.text:SetText(craftableCount > 9 and "9+" or tostring(craftableCount))
    for _, b in ipairs(tabButtons) do
        if b.key == "requests" then
            b.text:SetText(craftableCount > 0 and ("Requests (" .. craftableCount .. ")") or "Requests")
            b:SetWidth(b.text:GetStringWidth() + 28)
        end
    end
end

mmb:SetScript("OnEnter", function(s)
    GameTooltip:SetOwner(s, "ANCHOR_LEFT")
    GameTooltip:AddLine(Hex(C.accent) .. "Guild|rloom")
    if craftableCount > 0 then
        GameTooltip:AddLine(("%d open request%s you can craft"):format(craftableCount, craftableCount == 1 and "" or "s"), 1, 0.82, 0)
    end
    GameTooltip:AddLine("Left-click: open / close", 1, 1, 1)
    GameTooltip:AddLine("Shift-click: notices window", 1, 1, 1)
    GameTooltip:AddLine("Right-click: sync professions", 1, 1, 1)
    GameTooltip:AddLine("Drag: move this button", 0.6, 0.6, 0.6)
    local unread = ns.UnreadNotices and ns.UnreadNotices() or 0
    if unread > 0 then
        GameTooltip:AddLine(("%d new notice%s"):format(unread, unread == 1 and "" or "s"), 0.31, 0.76, 0.97)
    end
    GameTooltip:Show()
end)
mmb:SetScript("OnLeave", function() GameTooltip:Hide() end)

function ns.UpdateMinimapButton()
    if ns.db.minimapHide then
        mmb:Hide()
    else
        mmb:Show()
        PlaceMinimapButton()
    end
end

---------------------------------------------------------------------------
-- Init + slash commands
---------------------------------------------------------------------------
local settingsViews = {}

-- Apply the selected skin, scale and opacity to everything.
function ns.ApplySkin()
    local db = ns.db
    local skin = SKIN_BY_KEY[db.skin] or SKINS[1]
    for k, v in pairs(skin.colors) do
        local t = C[k]
        if t then t[1], t[2], t[3] = v[1], v[2], v[3] end
    end
    local a = C.accent
    C.accentDim[1], C.accentDim[2], C.accentDim[3] = a[1], a[2], a[3]
    C.hover[1], C.hover[2], C.hover[3] = a[1], a[2], a[3]
    -- Optional palette entries fall back to panel / text.
    local w = skin.colors.well or skin.colors.panel
    C.well[1], C.well[2], C.well[3], C.well[4] = w[1], w[2], w[3], skin.wellAlpha or 1
    local tc = skin.colors.title or skin.colors.text
    C.title[1], C.title[2], C.title[3] = tc[1], tc[2], tc[3]
    local bt = skin.colors.btnText or skin.colors.text
    C.btnText[1], C.btnText[2], C.btnText[3] = bt[1], bt[2], bt[3]

    -- Blizzard frame art first, so the colour pass below knows what's in use.
    BLZ, SHADOW = skin.backdrop == "blizzard", skin.shadow and true or false
    for _, e in ipairs(skinned.chrome) do ApplyChrome(e) end
    for _, e in ipairs(skinned.inputs) do ApplyInput(e) end
    for _, b in ipairs(skinned.buttons) do if b.blz then b.blz:SetShown(BLZ) end end
    for _, e in ipairs(skinned.swap) do e[1]:SetShown(not BLZ); e[2]:SetShown(BLZ) end

    for _, e in ipairs(skinned.bd) do
        e[1]:SetBackdropColor(unpack(e[2]))
        e[1]:SetBackdropBorderColor(unpack(e[3]))
    end
    for _, e in ipairs(skinned.text) do
        e[1]:SetTextColor(unpack(e[2]))
        e[1]:SetShadowColor(0, 0, 0, 1)
        e[1]:SetShadowOffset(SHADOW and 1 or 0, SHADOW and -1 or 0)
    end
    for _, e in ipairs(skinned.tex) do
        local c = e[2]
        e[1]:SetColorTexture(c[1], c[2], c[3], e[3] or c[4] or 1)
    end
    for _, fn in ipairs(skinned.fn) do fn() end

    -- Main window frame style (flat, tooltip border, stone dialog or game frame).
    local pad, blzWin = StyleWindow(F, titleBar, skin, db.opacity or 0.97)
    local extra = pad - 1
    tabBar:ClearAllPoints()
    toolbar:ClearAllPoints()
    title:ClearAllPoints()
    subtitle:ClearAllPoints()
    gear:ClearAllPoints()
    footer:ClearAllPoints()
    if blzWin then
        -- Game layout: title centred in the metal title strip, portrait at
        -- the top left, tabs beside it, member count bottom right.
        titleBar:ClearAllPoints()
        titleBar:SetPoint("TOPLEFT", 58, -1)
        titleBar:SetPoint("TOPRIGHT", -24, -1)
        titleBar:SetHeight(20)
        tabBar:SetPoint("TOPLEFT", F, "TOPLEFT", 62, -22)
        tabBar:SetPoint("TOPRIGHT", F, "TOPRIGHT", -8, -22)
        toolbar:SetPoint("TOPLEFT", F, "TOPLEFT", 12, -60)
        toolbar:SetPoint("TOPRIGHT", F, "TOPRIGHT", -12, -60)
        title:SetFont(STANDARD_TEXT_FONT, 12, "")
        title:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
        subtitle:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -22, 10)
        gear:SetPoint("RIGHT", titleBar, "RIGHT", -2, 0)
        footer:SetPoint("BOTTOMLEFT", 12 + extra, 8 + extra)
        footer:SetPoint("BOTTOMRIGHT", subtitle, "BOTTOMLEFT", -12, 0)
        if not F.portrait then
            local h = CreateFrame("Frame", nil, F)
            h:SetAllPoints()
            local t = h:CreateTexture(nil, "ARTWORK")
            t:SetSize(60, 60)
            t:SetPoint("TOPLEFT", -5, 7)
            local icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01"
            if not (SetPortraitToTexture and pcall(SetPortraitToTexture, t, icon)) then t:SetTexture(icon) end
            F.portrait = h
        end
        -- Under the frame art, so the metal ring overlaps the portrait.
        F.portrait:SetFrameLevel(F:GetFrameLevel() + 7)
    else
        titleBar:SetHeight(34)
        tabBar:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
        tabBar:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)
        toolbar:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 10, -8)
        toolbar:SetPoint("TOPRIGHT", tabBar, "BOTTOMRIGHT", -10, -8)
        title:SetFont(STANDARD_TEXT_FONT, 14, "")
        title:SetPoint("LEFT", logo, "RIGHT", 8, 0)
        subtitle:SetPoint("RIGHT", titleBar, "RIGHT", -62, 0)
        gear:SetPoint("RIGHT", close, "LEFT", -4, 0)
        footer:SetPoint("BOTTOMLEFT", 12 + extra, 8 + extra)
        footer:SetPoint("BOTTOMRIGHT", -24 - extra, 8 + extra)
    end
    if F.portrait then F.portrait:SetShown(blzWin) end
    logo:SetShown(not blzWin)
    tbg:SetShown(not blzWin)
    content:ClearAllPoints()
    content:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 0, -8)
    content:SetPoint("BOTTOMRIGHT", F, "BOTTOMRIGHT", -10 - extra, 26 + extra)
    grip:ClearAllPoints()
    grip:SetPoint("BOTTOMRIGHT", -2 - extra, 2 + extra)
    grip:SetFrameLevel(F:GetFrameLevel() + 10)
    F:SetScale(db.scale or 1)

    for _, v in ipairs(settingsViews) do v:Update() end
    if ns.OnSkinApplied then ns.OnSkinApplied() end
    ns.RefreshUI()
end

-- Settings widgets ----------------------------------------------------------
local function RawText(parent, size)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(STANDARD_TEXT_FONT, size, "")
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    return fs
end

-- A preview tile drawn in the skin's own colours.
local function MakeSwatch(parent, skin, onClick)
    local c = skin.colors
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(150, 40)
    b:SetBackdrop(FLAT_BD)
    b:SetBackdropColor(c.panel[1], c.panel[2], c.panel[3], 1)
    if skin.bgTex then
        local st = b:CreateTexture(nil, "BACKGROUND", nil, 1)
        st:SetPoint("TOPLEFT", 1, -1)
        st:SetPoint("BOTTOMRIGHT", -1, 1)
        st:SetTexture(skin.bgTex, "REPEAT", "REPEAT")
        st:SetHorizTile(true)
        st:SetVertTile(true)
        st:SetVertexColor(unpack(skin.bgTint or { 1, 1, 1 }))
    end
    b.name = RawText(b, 12)
    b.name:SetPoint("TOPLEFT", 10, -7)
    b.name:SetText(skin.name)
    b.name:SetTextColor(c.text[1], c.text[2], c.text[3])
    for i, k in ipairs({ "bg", "header", "accent", "dim" }) do
        local d = b:CreateTexture(nil, "ARTWORK")
        d:SetSize(14, 7)
        d:SetPoint("BOTTOMLEFT", 10 + (i - 1) * 17, 7)
        d:SetColorTexture(c[k][1], c[k][2], c[k][3], 1)
    end
    b.check = b:CreateTexture(nil, "OVERLAY")
    b.check:SetSize(20, 20)
    b.check:SetPoint("RIGHT", -6, 0)
    b.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    b.skin = skin
    function b:SetSelected(on)
        local bc = on and c.accent or c.border
        self:SetBackdropBorderColor(bc[1], bc[2], bc[3], 1)
        self.check:SetShown(on)
    end
    b:SetScript("OnClick", function() onClick(skin.key) end)
    return b
end

local function MakeSlider(parent, label, minV, maxV, step, fmt, get, set, applyOnRelease)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(308, 36)
    f.label = Text(f, 11, C.text)
    f.label:SetPoint("TOPLEFT")
    f.label:SetText(label)
    f.value = Text(f, 11, C.dim, "RIGHT")
    f.value:SetPoint("TOPRIGHT")
    local s = CreateFrame("Slider", nil, f, "BackdropTemplate")
    s:SetPoint("TOPLEFT", 0, -18)
    s:SetPoint("TOPRIGHT", 0, -18)
    s:SetHeight(10)
    SetBD(s, C.panel, C.border)
    s:SetOrientation("HORIZONTAL")
    s:SetMinMaxValues(minV, maxV)
    s:SetValueStep(step)
    if s.SetObeyStepDuringDrag then s:SetObeyStepDuringDrag(true) end
    s:EnableMouse(true)
    local th = s:CreateTexture(nil, "OVERLAY")
    th:SetSize(8, 14)
    Paint(th, C.accent)
    s:SetThumbTexture(th)
    local function Snap(v) return floor(v / step + 0.5) * step end
    s:SetScript("OnValueChanged", function(_, v)
        v = Snap(v)
        f.value:SetText(fmt(v))
        if not f.updating and not applyOnRelease then set(v) end
    end)
    -- Scale changes the window under the mouse, so apply it on release.
    s:SetScript("OnMouseUp", function()
        if applyOnRelease then set(Snap(s:GetValue())) end
    end)
    function f:Update()
        self.updating = true
        s:SetValue(get())
        self.value:SetText(fmt(get()))
        self.updating = false
    end
    return f
end

local function MakeCheck(parent, label, get, set)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(308, 20)
    local box = CreateFrame("Frame", nil, b, "BackdropTemplate")
    box:SetSize(16, 16)
    box:SetPoint("LEFT")
    SetBD(box, C.panel, C.border)
    local ck = box:CreateTexture(nil, "OVERLAY")
    ck:SetSize(20, 20)
    ck:SetPoint("CENTER")
    ck:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    local t = Text(b, 11, C.text)
    t:SetPoint("LEFT", box, "RIGHT", 8, 0)
    t:SetText(label)
    b:SetScript("OnClick", function()
        set(not get())
        ck:SetShown(get() and true or false)
    end)
    function b:Update() ck:SetShown(get() and true or false) end
    return b
end

-- Drop-down with a scrollable list (mouse wheel when there are many options).
local function MakeDropdown(parent, width, getOptions, get, set)
    local b = FlatButton(parent, "", width)
    b.text:ClearAllPoints()
    b.text:SetPoint("LEFT", 10, 0)
    b.text:SetPoint("RIGHT", -22, 0)
    b.text:SetJustifyH("LEFT")
    local arrow = (b.top or b):CreateTexture(nil, "OVERLAY")
    arrow:SetSize(14, 14)
    arrow:SetPoint("RIGHT", -6, -1)
    arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")

    local menu = CreateFrame("Frame", nil, b, "BackdropTemplate")
    SetBD(menu, C.panel, C.accent)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -2)
    menu:SetWidth(width)
    menu:EnableMouse(true)
    menu:EnableMouseWheel(true)
    menu:Hide()
    menu.rows, menu.offset, menu.opts = {}, 0, {}
    local VISIBLE, RH = 12, 20

    local function Fill()
        local opts = menu.opts
        local n = min(VISIBLE, #opts)
        for i = 1, n do
            local r = menu.rows[i]
            if not r then
                r = CreateFrame("Button", nil, menu)
                r:SetHeight(RH)
                r:SetPoint("TOPLEFT", 1, -1 - (i - 1) * RH)
                r:SetPoint("RIGHT", menu, "RIGHT", -1, 0)
                r.sel = r:CreateTexture(nil, "BACKGROUND")
                r.sel:SetAllPoints()
                Paint(r.sel, C.accentDim)
                r.hl = r:CreateTexture(nil, "HIGHLIGHT")
                r.hl:SetAllPoints()
                Paint(r.hl, C.hover)
                r.text = Text(r, 11, C.text)
                r.text:SetPoint("LEFT", 10, 0)
                r.text:SetPoint("RIGHT", -6, 0)
                r:SetScript("OnClick", function(s)
                    set(s.value)
                    menu:Hide()
                    b:Update()
                end)
                menu.rows[i] = r
            end
            local o = opts[menu.offset + i]
            r.value = o.value
            r.text:SetText(o.label)
            r.sel:SetShown(o.value == get())
            r:Show()
        end
        for i = n + 1, #menu.rows do menu.rows[i]:Hide() end
        menu:SetHeight(n * RH + 2)
    end

    menu:SetScript("OnMouseWheel", function(_, delta)
        local maxOff = max(0, #menu.opts - VISIBLE)
        menu.offset = max(0, min(maxOff, menu.offset - delta * 3))
        Fill()
    end)
    b:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide(); return end
        menu.opts = getOptions()
        -- Open scrolled so the current choice is visible.
        local idx = 1
        for i, o in ipairs(menu.opts) do if o.value == get() then idx = i end end
        menu.offset = max(0, min(max(0, #menu.opts - VISIBLE), idx - floor(VISIBLE / 2)))
        Fill()
        menu:Show()
    end)
    b:HookScript("OnHide", function() menu:Hide() end)

    function b:Update()
        local cur, label = get(), get()
        for _, o in ipairs(getOptions()) do if o.value == cur then label = o.label end end
        self.text:SetText(label)
    end
    return b
end

local function Percent(x) return ("%d%%"):format(floor(x * 100 + 0.5)) end

-- Builds one settings view (used both in game Options and the in-window popup).
local function BuildSettings(parent)
    local v = CreateFrame("Frame", nil, parent)
    v:SetSize(308, 300)
    local h = Text(v, 14, C.text)
    h:SetPoint("TOPLEFT")
    h:SetText("Guildloom settings")
    local l = Text(v, 10, C.dim)
    l:SetPoint("TOPLEFT", 0, -26)
    l:SetText("SKIN")

    v.swatches = {}
    for i, skin in ipairs(SKINS) do
        local sw = MakeSwatch(v, skin, function(key)
            ns.db.skin = key
            ns.ApplySkin()
        end)
        local col, row = (i - 1) % 2, floor((i - 1) / 2)
        sw:SetPoint("TOPLEFT", col * 158, -42 - row * 48)
        v.swatches[i] = sw
    end
    local y = -42 - math.ceil(#SKINS / 2) * 48 - 10

    v.scale = MakeSlider(v, "Window scale", 0.7, 1.4, 0.05, Percent,
        function() return ns.db.scale or 1 end,
        function(x) ns.db.scale = x; ns.ApplySkin() end, true)
    v.scale:SetPoint("TOPLEFT", 0, y)

    v.opacity = MakeSlider(v, "Background opacity", 0.4, 1, 0.05, Percent,
        function() return ns.db.opacity or 0.97 end,
        function(x)
            ns.db.opacity = x
            StyleWindow(F, titleBar, SKIN_BY_KEY[ns.db.skin] or SKINS[1], x)
        end, false)
    v.opacity:SetPoint("TOPLEFT", 0, y - 46)

    v.minimap = MakeCheck(v, "Show minimap button",
        function() return not ns.db.minimapHide end,
        function(on) ns.db.minimapHide = not on; ns.UpdateMinimapButton() end)
    v.minimap:SetPoint("TOPLEFT", 0, y - 92)

    v.noticeAuto = MakeCheck(v, "Open the notices window when an alert arrives",
        function() return ns.db.noticeAutoShow ~= false end,
        function(on) ns.db.noticeAutoShow = on end)
    v.noticeAuto:SetPoint("TOPLEFT", 0, y - 118)

    v.noticeChat = MakeCheck(v, "Also post alerts in chat",
        function() return ns.db.noticeChat end,
        function(on) ns.db.noticeChat = on end)
    v.noticeChat:SetPoint("TOPLEFT", 0, y - 144)

    v.noticeSound = MakeCheck(v, "Play a sound for request alerts",
        function() return ns.db.noticeSound ~= false end,
        function(on) ns.db.noticeSound = on end)
    v.noticeSound:SetPoint("TOPLEFT", 0, y - 170)

    local soundLabel = Text(v, 11, C.text)
    soundLabel:SetPoint("TOPLEFT", 24, y - 202)
    soundLabel:SetText("Sound")
    v.sound = MakeDropdown(v, 170, ns.SoundOptions,
        function() return ns.db.noticeSoundKey or "whisper" end,
        function(val)
            ns.db.noticeSoundKey = val
            ns.PlayNoticeSound(val, true) -- preview
        end)
    v.sound:SetPoint("TOPLEFT", 76, y - 197)
    local testSound = FlatButton(v, "Test", 54)
    testSound:SetPoint("LEFT", v.sound, "RIGHT", 6, 0)
    testSound:SetScript("OnClick", function() ns.PlayNoticeSound(nil, true) end)

    local reset = FlatButton(v, "Reset window position", 150)
    reset:SetPoint("TOPLEFT", 0, y - 236)
    local notices = FlatButton(v, "Notices window", 150)
    notices:SetPoint("LEFT", reset, "RIGHT", 8, 0)
    notices:SetScript("OnClick", function() ns.ToggleNotices() end)
    reset:SetScript("OnClick", function()
        ns.db.pos, ns.db.size = nil, nil
        ns.ApplyPosition()
    end)
    v:SetHeight(-(y - 236) + 24)

    function v:Update()
        local cur = ns.db.skin or DEFAULT_SKIN
        for _, sw in ipairs(self.swatches) do sw:SetSelected(sw.skin.key == cur) end
        self.scale:Update()
        self.opacity:Update()
        self.minimap:Update()
        self.noticeAuto:Update()
        self.noticeChat:Update()
        self.noticeSound:Update()
        self.sound:Update()
    end
    settingsViews[#settingsViews + 1] = v
    return v
end

-- Notices window ------------------------------------------------------------
-- Request alerts live in their own small window, independent of any chat
-- addon (Blizzard chat, Chattynator, ...).
local NW = CreateFrame("Frame", "GuildloomNotices", UIParent, "BackdropTemplate")
NW:SetSize(400, 190)
NW:SetFrameStrata("MEDIUM")
NW:SetClampedToScreen(true)
NW:SetMovable(true)
NW:SetResizable(true)
NW:EnableMouse(true)
if NW.SetResizeBounds then NW:SetResizeBounds(260, 110, 900, 600)
elseif NW.SetMinResize then NW:SetMinResize(260, 110) end
if NW.SetDontSavePosition then NW:SetDontSavePosition(true) end
SetBD(NW, C.bg, C.border)
Chrome(NW, "ButtonFrameTemplateNoPortrait", 8, true)
NW:Hide()

local nwHead = CreateFrame("Frame", nil, NW)
nwHead:SetPoint("TOPLEFT", 1, -1)
nwHead:SetPoint("TOPRIGHT", -1, -1)
nwHead:SetHeight(22)
nwHead:EnableMouse(true)
nwHead:RegisterForDrag("LeftButton")
local nwHeadBg = nwHead:CreateTexture(nil, "BACKGROUND")
nwHeadBg:SetAllPoints()
Paint(nwHeadBg, C.panel)
local nwTitle = Text(nwHead, 11, C.text)
nwTitle:SetPoint("LEFT", 8, 0)

local function HeadButton(label, w)
    local b = CreateFrame("Button", nil, nwHead)
    b:SetSize(w, 20)
    b.t = Text(b, 10, C.dim, "CENTER")
    b.t:SetPoint("CENTER", 0, 1)
    b.t:SetText(label)
    b:SetScript("OnEnter", function(s) s.t:SetTextColor(unpack(C.accent)) end)
    b:SetScript("OnLeave", function(s) s.t:SetTextColor(unpack(C.dim)) end)
    return b
end
local nwClose = HeadButton("x", 20)
nwClose.t:SetFont(STANDARD_TEXT_FONT, 13, "")
nwClose:SetPoint("RIGHT", -2, 0)
nwClose:SetScript("OnClick", function() NW:Hide() end)
do
    local bc = BlizzClose(NW, nwClose, function() NW:Hide() end, 1, 0)
    if bc and bc:GetWidth() >= 30 then bc:ClearAllPoints(); bc:SetPoint("TOPRIGHT", 4, 5) end
end
local nwClear = HeadButton("Clear", 40)
nwClear:SetPoint("RIGHT", nwClose, "LEFT", -2, 0)
local nwOpen = HeadButton("Requests", 58)
nwOpen:SetPoint("RIGHT", nwClear, "LEFT", -2, 0)
nwOpen:SetScript("OnClick", function()
    if not F:IsShown() then ns.Toggle() end
    SelectTab("requests")
end)

local function SaveNoticePos()
    local l, t = NW:GetLeft(), NW:GetTop()
    if not l or not ns.db then return end
    ns.db.noticePos = { l, t }
    ns.db.noticeSize = { NW:GetWidth(), NW:GetHeight() }
    NW:ClearAllPoints()
    NW:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t)
end
nwHead:SetScript("OnDragStart", function() NW:StartMoving() end)
nwHead:SetScript("OnDragStop", function()
    NW:StopMovingOrSizing()
    if NW.SetUserPlaced then NW:SetUserPlaced(false) end
    SaveNoticePos()
end)

local nwGrip = CreateFrame("Button", nil, NW)
nwGrip:SetSize(12, 12)
nwGrip:SetPoint("BOTTOMRIGHT", -2, 2)
nwGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
nwGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
nwGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
nwGrip:SetScript("OnMouseDown", function() NW:StartSizing("BOTTOMRIGHT") end)
nwGrip:SetScript("OnMouseUp", function()
    NW:StopMovingOrSizing()
    if NW.SetUserPlaced then NW:SetUserPlaced(false) end
    SaveNoticePos()
end)

local nwMsg = CreateFrame("ScrollingMessageFrame", nil, NW)
nwMsg:SetPoint("TOPLEFT", nwHead, "BOTTOMLEFT", 8, -4)
nwMsg:SetPoint("BOTTOMRIGHT", -14, 8)
nwMsg:SetFontObject(ChatFontNormal)
nwMsg:SetJustifyH("LEFT")
nwMsg:SetFading(false)
nwMsg:SetMaxLines(200)
nwMsg:SetHyperlinksEnabled(true)
nwMsg:EnableMouseWheel(true)
nwMsg:SetScript("OnMouseWheel", function(s, delta)
    if delta > 0 then
        if IsShiftKeyDown() then s:ScrollToTop() else s:ScrollUp() end
    else
        if IsShiftKeyDown() then s:ScrollToBottom() else s:ScrollDown() end
    end
end)
nwMsg:SetScript("OnHyperlinkClick", function(_, link, text, button)
    if SetItemRef then SetItemRef(link, text, button) end
end)
nwMsg:SetScript("OnHyperlinkEnter", function(s, link)
    GameTooltip:SetOwner(s, "ANCHOR_CURSOR")
    if pcall(GameTooltip.SetHyperlink, GameTooltip, link) then GameTooltip:Show() else GameTooltip:Hide() end
end)
nwMsg:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)

nwClear:SetScript("OnClick", function()
    wipe(ns.GetNoticeLog())
    nwMsg:Clear()
end)

local function RenderNotice(e)
    local stamp = Hex(C.dim) .. date("%H:%M", e.t) .. "|r  "
    nwMsg:AddMessage(stamp .. e.m, C.text[1], C.text[2], C.text[3])
end

local unreadNotices = 0
local function UpdateNoticeTitle()
    nwTitle:SetText(Hex(C.accent) .. "Guild|rloom  notices")
end

function ns.ShowNotices()
    local db = ns.db
    if db.noticeSize then NW:SetSize(db.noticeSize[1], db.noticeSize[2]) end
    NW:ClearAllPoints()
    if db.noticePos then
        NW:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", db.noticePos[1], db.noticePos[2])
    else
        NW:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 40, 280)
    end
    unreadNotices = 0
    UpdateNoticeTitle()
    NW:Show()
    nwMsg:ScrollToBottom()
end

function ns.ToggleNotices()
    if NW:IsShown() then NW:Hide() else ns.ShowNotices() end
end

function ns.UnreadNotices() return unreadNotices end

function ns.OnSkinApplied()
    local db = ns.db or {}
    local pad, blz = StyleWindow(NW, nwHead, SKIN_BY_KEY[db.skin] or SKINS[1], C.bg[4] or 0.97)
    if blz then
        nwHead:ClearAllPoints()
        nwHead:SetPoint("TOPLEFT", 3, -1)
        nwHead:SetPoint("TOPRIGHT", -24, -1)
    end
    nwHead:SetHeight(blz and 20 or 22)
    nwHeadBg:SetShown(not blz)
    nwClear:ClearAllPoints()
    if BLZ then nwClear:SetPoint("RIGHT", nwHead, "RIGHT", -2, 0)
    else nwClear:SetPoint("RIGHT", nwClose, "LEFT", -2, 0) end
    nwMsg:SetPoint("BOTTOMRIGHT", -14 - (pad - 1), 8 + (pad - 1))
    nwGrip:ClearAllPoints()
    nwGrip:SetPoint("BOTTOMRIGHT", -2 - (pad - 1), 2 + (pad - 1))
    nwGrip:SetFrameLevel(NW:GetFrameLevel() + 10)
    NW:SetScale(db.scale or 1)
    UpdateNoticeTitle()
end

-- Restore recent notices from the saved log after login.
function ns.LoadNoticeHistory()
    nwMsg:Clear()
    for _, e in ipairs(ns.GetNoticeLog()) do RenderNotice(e) end
end

-- Called by ns.Notice (Requests.lua). Returns true when the window handled it.
function ns.AddNoticeLine(entry, important)
    if not ns.db then return false end
    RenderNotice(entry)
    if important and ns.db.noticeAutoShow ~= false and not NW:IsShown() then
        ns.ShowNotices()
    elseif not NW:IsShown() then
        unreadNotices = unreadNotices + 1
    end
    return true
end

-- New crafting request form -------------------------------------------------
local reqForm

local function KnownProfessions()
    local set, out = {}, {}
    for name in pairs(ns.GetProfCounts()) do set[name] = true end
    for _, e in pairs(ns.GetProfData()) do
        for _, p in ipairs(e.list or {}) do set[p.n] = true end
    end
    for n in pairs(set) do out[#out + 1] = n end
    table.sort(out)
    table.insert(out, 1, "") -- "Any"
    return out
end

function ns.ToggleRequestForm()
    if not F:IsShown() then ns.Toggle() end
    if not reqForm then
        local f = CreateFrame("Frame", nil, F, "BackdropTemplate")
        SetBD(f, C.panel, C.accent)
        f:SetSize(420, 236)
        f:SetPoint("CENTER", content, "CENTER", 0, 20)
        f:SetFrameLevel(F:GetFrameLevel() + 60)
        f:EnableMouse(true)
        Chrome(f, "Dialog", 8)

        local title = Text(f, 14, C.title)
        title:SetPoint("TOPLEFT", 14, -12)
        title:SetText("New crafting request")
        local x = CreateFrame("Button", nil, f)
        x:SetSize(20, 20)
        x:SetPoint("TOPRIGHT", -4, -4)
        x.t = Text(x, 14, C.dim, "CENTER")
        x.t:SetPoint("CENTER", 0, 1)
        x.t:SetText("x")
        x:SetScript("OnClick", function() f:Hide() end)
        BlizzClose(f, x, function() f:Hide() end, -4, -4)

        local l1 = Text(f, 11, C.dim)
        l1:SetPoint("TOPLEFT", 14, -40)
        l1:SetText("What do you need?  Type it, or shift-click an item to link it.")

        local box = CreateFrame("EditBox", nil, f, "BackdropTemplate")
        box:SetPoint("TOPLEFT", 14, -58)
        box:SetPoint("TOPRIGHT", -14, -58)
        box:SetHeight(24)
        SetBD(box, C.bg, C.border)
        InputSkin(box)
        box:SetAutoFocus(false)
        box:SetFontObject(ChatFontNormal)
        box:SetTextInsets(8, 8, 0, 0)
        box:SetMaxBytes(150)
        box:SetScript("OnEditFocusGained", function(s)
            s:SetBackdropBorderColor(unpack(C.accent))
            if f.menu then f.menu:Hide() end
        end)
        box:SetScript("OnEditFocusLost", function(s) s:SetBackdropBorderColor(unpack(C.border)) end)
        box:SetScript("OnEscapePressed", function(s) s:ClearFocus(); f:Hide() end)
        f.box = box

        -- Profession drop-down
        local profBtn = FlatButton(f, "", 220)
        profBtn:SetPoint("TOPLEFT", 14, -92)
        profBtn.text:ClearAllPoints()
        profBtn.text:SetPoint("LEFT", 10, 0)
        profBtn.text:SetJustifyH("LEFT")
        local arrow = profBtn:CreateTexture(nil, "OVERLAY")
        arrow:SetSize(14, 14)
        arrow:SetPoint("RIGHT", -6, -1)
        arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")

        local menu = CreateFrame("Frame", nil, profBtn, "BackdropTemplate")
        SetBD(menu, C.panel, C.accent)
        menu:SetFrameStrata("DIALOG")
        menu:SetPoint("TOPLEFT", profBtn, "BOTTOMLEFT", 0, -2)
        menu:SetWidth(220)
        menu:EnableMouse(true)
        menu:Hide()
        menu.items = {}

        local function ProfIcon(name)
            local c = ns.GetProfCounts()[name]
            if c and c.icon then return c.icon end
            for _, e in pairs(ns.GetProfData()) do
                for _, p in ipairs(e.list or {}) do
                    if p.n == name and p.i then return p.i end
                end
            end
        end

        local function OpenMenu()
            local profs = KnownProfessions()
            for i, p in ipairs(profs) do
                local b = menu.items[i]
                if not b then
                    b = CreateFrame("Button", nil, menu)
                    b:SetHeight(22)
                    b:SetPoint("TOPLEFT", 1, -1 - (i - 1) * 22)
                    b:SetPoint("RIGHT", menu, "RIGHT", -1, 0)
                    b.sel = b:CreateTexture(nil, "BACKGROUND")
                    b.sel:SetAllPoints()
                    Paint(b.sel, C.accentDim)
                    b.hl = b:CreateTexture(nil, "HIGHLIGHT")
                    b.hl:SetAllPoints()
                    Paint(b.hl, C.hover)
                    b.icon = b:CreateTexture(nil, "ARTWORK")
                    b.icon:SetSize(16, 16)
                    b.icon:SetPoint("LEFT", 8, 0)
                    b.text = Text(b, 11, C.text)
                    b.text:SetPoint("LEFT", 30, 0)
                    b:SetScript("OnClick", function(s)
                        f.prof = s.value
                        menu:Hide()
                        f:UpdateInfo()
                    end)
                    menu.items[i] = b
                end
                b.value = p
                b.text:SetText(p == "" and "Any profession" or p)
                SetIcon(b.icon, p ~= "" and ProfIcon(p) or nil)
                b.sel:SetShown((f.prof or "") == p)
                b:Show()
            end
            for i = #profs + 1, #menu.items do menu.items[i]:Hide() end
            menu:SetHeight(#profs * 22 + 2)
            menu:Show()
        end
        profBtn:SetScript("OnClick", function()
            if menu:IsShown() then menu:Hide() else OpenMenu() end
        end)
        f:HookScript("OnHide", function() menu:Hide() end)
        f.menu = menu

        local info = Text(f, 11, C.text)
        info:SetPoint("TOPLEFT", 14, -124)
        info:SetPoint("TOPRIGHT", -14, -124)
        info:SetHeight(66)
        info:SetWordWrap(true)
        info:SetJustifyV("TOP")

        local post = FlatButton(f, "Post request", 110)
        post:SetPoint("BOTTOMRIGHT", -14, 12)
        post:SetActive(true)
        local cancel = FlatButton(f, "Cancel", 80)
        cancel:SetPoint("RIGHT", post, "LEFT", -8, 0)
        cancel:SetScript("OnClick", function() f:Hide() end)
        post:SetScript("OnClick", function()
            local t = box:GetText() or ""
            if t:gsub("%s", "") == "" then box:SetFocus(); return end
            ns.CreateRequest(t, f.prof or "")
            box:SetText("")
            f:Hide()
            SelectTab("requests")
            ns.Print("Request posted to the guild.")
        end)
        box:SetScript("OnEnterPressed", function() post:Click() end)

        function f:UpdateInfo()
            profBtn.text:SetText(Hex(C.dim) .. "Profession:|r  " .. ((self.prof and self.prof ~= "") and self.prof or "Any"))
            local crafters, haveProf, q = ns.FindCrafters(box:GetText(), self.prof)
            if #q < 3 then
                info:SetText(Hex(C.dim) .. "Type at least 3 letters to see who can craft it.|r")
                return
            end
            local s
            if #crafters > 0 then
                local parts = {}
                for i = 1, min(6, #crafters) do
                    local c = crafters[i]
                    parts[#parts + 1] = (c.m.online and "|cff4ade80" or Hex(C.dim)) .. c.m.short .. "|r"
                end
                s = "Can craft it: " .. table.concat(parts, ", ") .. (#crafters > 6 and (" +" .. (#crafters - 6)) or "")
            else
                s = Hex(C.dim) .. "Nobody has shared a matching recipe yet - the request still goes to everyone.|r"
            end
            if #haveProf > 0 then
                local p2 = {}
                for i = 1, min(6, #haveProf) do p2[#p2 + 1] = haveProf[i].short end
                s = s .. "\n" .. Hex(C.dim) .. "Also have " .. self.prof .. ": " .. table.concat(p2, ", ") .. "|r"
            end
            info:SetText(s)
        end
        box:SetScript("OnTextChanged", function() f:UpdateInfo() end)
        reqForm = f
        f:Hide()
    end
    if reqForm:IsShown() then
        reqForm:Hide()
    else
        reqForm:Show()
        reqForm.box:SetFocus()
        reqForm:UpdateInfo()
    end
end

-- Shift-clicking an item while the request box has focus links it there.
local lastLink, lastLinkTime
local function InsertIntoForm(link)
    if not (link and reqForm and reqForm:IsShown() and reqForm.box:HasFocus()) then return end
    if link == lastLink and GetTime() - (lastLinkTime or 0) < 0.2 then return end -- both hooks fired
    lastLink, lastLinkTime = link, GetTime()
    reqForm.box:Insert(link)
end
if ChatEdit_InsertLink then hooksecurefunc("ChatEdit_InsertLink", InsertIntoForm) end
if ChatFrameUtil and ChatFrameUtil.InsertLink then hooksecurefunc(ChatFrameUtil, "InsertLink", InsertIntoForm) end

-- In-window popup (gear button in the title bar).
local pop
function ns.ToggleSettingsPopup()
    if not F:IsShown() then ns.Toggle() end
    if not pop then
        pop = CreateFrame("Frame", nil, F, "BackdropTemplate")
        SetBD(pop, C.panel, C.accent)
        pop:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", -8, -4)
        pop:SetFrameLevel(F:GetFrameLevel() + 60)
        pop:EnableMouse(true)
        local v = BuildSettings(pop)
        v:SetPoint("TOPLEFT", 14, -14)
        pop:SetSize(v:GetWidth() + 28, v:GetHeight() + 28)
        local x = CreateFrame("Button", nil, pop)
        x:SetSize(20, 20)
        x:SetPoint("TOPRIGHT", -4, -4)
        x.t = Text(x, 14, C.dim, "CENTER")
        x.t:SetPoint("CENTER", 0, 1)
        x.t:SetText("x")
        x:SetScript("OnClick", function() pop:Hide() end)
        Chrome(pop, "Dialog", 8)
        BlizzClose(pop, x, function() pop:Hide() end, -4, -4)
        pop.view = v
        pop:Hide()
    end
    pop:SetShown(not pop:IsShown())
    if pop:IsShown() then pop.view:Update() end
end

-- Game Options > AddOns > Guildloom
local function RegisterOptions()
    local panel = CreateFrame("Frame")
    panel.name = "Guildloom"
    local v = BuildSettings(panel)
    v:SetPoint("TOPLEFT", 16, -16)
    panel:SetScript("OnShow", function() v:Update() end)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local cat = Settings.RegisterCanvasLayoutCategory(panel, "Guildloom")
        Settings.RegisterAddOnCategory(cat)
        ns.settingsCategory = cat
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

function ns.OnInit()
    if ns.db.size then F:SetSize(ns.db.size[1], ns.db.size[2]) end
    local valid = false
    for _, t in ipairs(TABS) do if t.key == ns.db.tab then valid = true end end
    if not valid then ns.db.tab = "ranks" end
    if not SKIN_BY_KEY[ns.db.skin or ""] then ns.db.skin = DEFAULT_SKIN end
    pcall(RegisterOptions)
    ns.ApplySkin()
    ns.UpdateMinimapButton()
    ns.LoadNoticeHistory()
    C_Timer.After(12, ns.UpdateBadge)
end

SLASH_GUILDLOOM1 = "/loom"
SLASH_GUILDLOOM2 = "/guildloom"
SLASH_GUILDLOOM3 = "/gp" -- old shortcut, kept for convenience
SlashCmdList.GUILDLOOM = function(msg)
    msg = (msg or ""):lower():match("^%s*(%S*)")
    if msg == "debug" then
        ns.RefreshGuildTradeSkills()
        C_Timer.After(1.5, ns.DebugGuildTradeSkills)
    elseif msg == "sync" then
        ns.UpdateOwn(true)
        ns.RequestSync()
        ns.Print("Sync requested.")
    elseif msg == "testalert" then
        ns.Notice("|cffffd100Test alert - this is how a request you can craft will look (with sound).|r", true)
        if not NW:IsShown() then ns.ShowNotices() end
    elseif msg == "notices" or msg == "log" then
        ns.ToggleNotices()
    elseif msg == "settings" or msg == "skin" or msg == "options" then
        ns.ToggleSettingsPopup()
    elseif msg == "minimap" then
        ns.db.minimapHide = not ns.db.minimapHide
        ns.UpdateMinimapButton()
        ns.Print("Minimap button " .. (ns.db.minimapHide and "hidden" or "shown") .. ".")
    elseif msg == "reset" then
        ns.db.pos, ns.db.size, ns.db.minimapAngle = nil, nil, nil
        ns.ApplyPosition()
        ns.UpdateMinimapButton()
        ns.Print("Window and minimap button position reset.")
    elseif msg == "help" then
        ns.Print("/loom - open/close | /loom settings | /loom sync | /loom testalert | /loom notices | /loom minimap | /loom reset")
    else
        ns.Toggle()
    end
end
