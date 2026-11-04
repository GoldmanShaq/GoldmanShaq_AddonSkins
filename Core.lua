local ADDON, GS = ...
_G.GoldmanShaqAddonSkins = GS

local WHITE = "Interface\\Buttons\\WHITE8x8"
GS.WHITE = WHITE
local IsAddOnLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded

---------------------------------------------------------------------
-- CONFIG: shared by every skin
---------------------------------------------------------------------
GS.cfg = {
    bg        = { 0.05, 0.05, 0.05, 0.92 },
    btnBg     = { 0.10, 0.10, 0.10, 1.00 },
    border    = { 0, 0, 0, 1 },
    borderPx  = 1,
    accent    = { 0.05, 0.82, 0.62 },   -- fallback accent if EllesmereUI isn't found
    useAccentBorder = false,
    accentLine = false,
    highlightAlpha = 0.15,
    fontName  = nil,                    -- LibSharedMedia name, e.g. "Expressway"; nil = game default
    fontSize  = 12,
    fontFlags = "",
    skinPopups = true,                  -- also skin StaticPopup dialogs (e.g. BetterAddonList set-name prompt)
}
local cfg = GS.cfg

---------------------------------------------------------------------
-- EllesmereUI accent + fonts
---------------------------------------------------------------------
function GS:GetAccent()
    local E = _G.EllesmereUI
    if type(E) == "table" then
        if type(E.GetAccentColor) == "function" then
            local ok, r, g, b = pcall(E.GetAccentColor, E)
            if ok and type(r) == "number" then return r, g, b end
            if ok and type(r) == "table" then return r[1] or r.r, r[2] or r.g, r[3] or r.b end
        end
        local c = E.accentColor or E.AccentColor or E.accent or E.ACCENT
        if type(c) == "table" then
            local r, g, b = c[1] or c.r, c[2] or c.g, c[3] or c.b
            if r and g and b then return r, g, b end
        end
    end
    return unpack(cfg.accent)
end

function GS:GetFontPath()
    if cfg.fontName then
        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        local path = LSM and LSM:Fetch("font", cfg.fontName, true)
        if path then return path end
    end
    return STANDARD_TEXT_FONT
end

function GS:EnsureFonts()
    if not self.font then
        self.font = CreateFont("GSAddonSkinsFont")
        self.headerFont = CreateFont("GSAddonSkinsHeaderFont")
    end
    local path = self:GetFontPath()
    self.font:SetFont(path, cfg.fontSize, cfg.fontFlags)
    self.headerFont:SetFont(path, cfg.fontSize + 1, cfg.fontFlags)
    return self.font, self.headerFont
end

-- exactly n physical pixels regardless of UI scale
function GS:PixelSize(frame, n)
    local _, physH = GetPhysicalScreenSize()
    local scale = frame:GetEffectiveScale()
    if not physH or physH == 0 or not scale or scale == 0 then return n end
    return (768 / physH) / scale * n
end

---------------------------------------------------------------------
-- Primitives
---------------------------------------------------------------------
-- Flat background + 1px border drawn with plain textures (no BackdropTemplate needed)
function GS:Box(f, opts)
    opts = opts or {}
    local inset = opts.inset or 0
    local ix, iy = opts.x or inset, opts.y or inset
    if not f.__gsBox then
        local bg = f:CreateTexture(nil, "BACKGROUND", nil, -8)
        bg:SetTexture(WHITE); bg.__gs = true
        local edges = {}
        for i = 1, 4 do
            local e = f:CreateTexture(nil, "BORDER")
            e:SetTexture(WHITE); e.__gs = true
            edges[i] = e
        end
        f.__gsBox = { bg = bg, edges = edges }
    end
    local box = f.__gsBox
    local px = self:PixelSize(f, cfg.borderPx)

    box.bg:ClearAllPoints()
    box.bg:SetPoint("TOPLEFT", ix, -iy)
    box.bg:SetPoint("BOTTOMRIGHT", -ix, iy)
    box.bg:SetVertexColor(unpack(opts.bg or cfg.bg))

    local e = box.edges
    e[1]:ClearAllPoints(); e[1]:SetPoint("TOPLEFT", ix, -iy);     e[1]:SetPoint("TOPRIGHT", -ix, -iy);     e[1]:SetHeight(px)
    e[2]:ClearAllPoints(); e[2]:SetPoint("BOTTOMLEFT", ix, iy);   e[2]:SetPoint("BOTTOMRIGHT", -ix, iy);   e[2]:SetHeight(px)
    e[3]:ClearAllPoints(); e[3]:SetPoint("TOPLEFT", ix, -iy);     e[3]:SetPoint("BOTTOMLEFT", ix, iy);     e[3]:SetWidth(px)
    e[4]:ClearAllPoints(); e[4]:SetPoint("TOPRIGHT", -ix, -iy);   e[4]:SetPoint("BOTTOMRIGHT", -ix, iy);   e[4]:SetWidth(px)

    local br, bg, bb, ba = unpack(opts.border or cfg.border)
    if cfg.useAccentBorder then
        local ar, ag, ab = self:GetAccent()
        br, bg, bb, ba = ar, ag, ab, 1
    end
    for _, t in ipairs(e) do t:SetVertexColor(br, bg, bb, ba) end
    return box
end

local function Kill(o)
    if o and o.SetAlpha then o:SetAlpha(0) end
    if o and o.Hide then o:Hide() end
end

local STRIP_KEYS = {
    "NineSlice", "Bg", "BG", "Background", "InsetBg", "TitleBg", "TopTileStreaks",
    "PortraitContainer", "portrait", "Portrait", "Border", "ShadowOverlay",
    "TopLeftCorner", "TopRightCorner", "BottomLeftCorner", "BottomRightCorner",
    "TopBorder", "BottomBorder", "LeftBorder", "RightBorder",
}

-- Remove default frame chrome (template art, NineSlice, backdrops)
function GS:Strip(f)
    for _, k in ipairs(STRIP_KEYS) do Kill(f[k]) end
    if f.Inset then
        Kill(f.Inset.NineSlice); Kill(f.Inset.Bg)
    end
    local n = f.GetName and f:GetName()
    if n then
        for _, s in ipairs({ "Bg", "TitleBg", "TopTileStreaks", "Inset" }) do
            local o = _G[n .. s]
            if o and o ~= f.Inset then Kill(o) end
        end
    end
    if f.SetBackdrop then
        pcall(f.SetBackdrop, f, nil)
        if not f.__gsNoBackdrop then
            f.__gsNoBackdrop = true
            f.SetBackdrop = function() end   -- stop the addon re-applying it
        end
    end
end

-- Hide chrome textures that sit on BACKGROUND/BORDER of a top-level frame
function GS:StripRegions(f)
    for _, r in ipairs({ f:GetRegions() }) do
        if r.GetObjectType and r:GetObjectType() == "Texture" and not r.__gs then
            local layer = r:GetDrawLayer()
            if layer == "BACKGROUND" or layer == "BORDER" then Kill(r) end
        end
    end
end

---------------------------------------------------------------------
-- Widget skins
---------------------------------------------------------------------
local function IsPanelButton(b)
    if b.Left and b.Middle and b.Right then return true end
    local n = b.GetName and b:GetName()
    if n and _G[n .. "Left"] and _G[n .. "Middle"] and _G[n .. "Right"] then return true end
    local nt = b.GetNormalTexture and b:GetNormalTexture()
    if nt then
        local tex = nt.GetTexture and nt:GetTexture()
        local atlas = nt.GetAtlas and nt:GetAtlas()
        if type(tex) == "string" and tex:find("UI%-Panel%-Button") then return true end
        if type(atlas) == "string" and atlas:find("UI%-Panel%-Button") then return true end
    end
    return false
end
GS.IsPanelButton = IsPanelButton

local function Tint(h, a)
    local ar, ag, ab = GS:GetAccent()
    h:SetColorTexture(ar, ag, ab, a or cfg.highlightAlpha)
end

function GS:SkinButton(b)
    if b.__gsBtn then return end
    b.__gsBtn = true
    for _, k in ipairs({ "Left", "Middle", "Right", "Center", "LeftSeparator", "RightSeparator" }) do Kill(b[k]) end
    local n = b:GetName()
    if n then for _, s in ipairs({ "Left", "Middle", "Right" }) do Kill(_G[n .. s]) end end
    for _, fn in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture" }) do
        local t = b[fn] and b[fn](b)
        if t then t:SetAlpha(0) end
    end
    self:Box(b, { bg = cfg.btnBg })

    b:SetHighlightTexture(WHITE)
    local h = b:GetHighlightTexture()
    if h then
        h:ClearAllPoints(); h:SetAllPoints(b)
        h:SetBlendMode("BLEND")
        Tint(h)
    end
    local fs = b.GetFontString and b:GetFontString()
    if fs then fs:SetFont(self:GetFontPath(), cfg.fontSize, cfg.fontFlags) end
end

function GS:SkinCheck(b)
    if b.__gsCheck then return end
    b.__gsCheck = true
    for _, fn in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture" }) do
        local t = b[fn] and b[fn](b)
        if t then t:SetAlpha(0) end
    end
    self:Box(b, { bg = cfg.btnBg, inset = 4 })
    local ar, ag, ab = self:GetAccent()
    local ct = b:GetCheckedTexture()
    if ct then
        ct:SetTexture(WHITE); ct:SetTexCoord(0, 1, 0, 1)
        ct:SetVertexColor(ar, ag, ab, 1)
        ct:ClearAllPoints()
        ct:SetPoint("TOPLEFT", 7, -7); ct:SetPoint("BOTTOMRIGHT", -7, 7)
    end
    local dct = b.GetDisabledCheckedTexture and b:GetDisabledCheckedTexture()
    if dct then dct:SetAlpha(0) end
    b:SetHighlightTexture(WHITE)
    local h = b:GetHighlightTexture()
    if h then
        h:ClearAllPoints(); h:SetPoint("TOPLEFT", 4, -4); h:SetPoint("BOTTOMRIGHT", -4, 4)
        Tint(h)
    end
end

function GS:SkinEdit(e)
    if e.__gsEdit then return end
    local n = e:GetName()
    local hasTemplate = (e.Left and e.Middle and e.Right) or (n and _G[n .. "Left"]) or e.searchIcon or e.clearButton
    if not hasTemplate then return end
    e.__gsEdit = true
    for _, k in ipairs({ "Left", "Middle", "Right" }) do
        Kill(e[k]); if n then Kill(_G[n .. k]) end
    end
    self:Box(e, { bg = cfg.btnBg })
    e:SetTextInsets(6, 6, 0, 0)
    e:SetFont(self:GetFontPath(), cfg.fontSize, cfg.fontFlags)
end

function GS:SkinCloseButton(b)
    if not b or b.__gsClose then return end
    b.__gsClose = true
    for _, fn in ipairs({ "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture" }) do
        local t = b[fn] and b[fn](b)
        if t then t:SetAlpha(0) end
    end
    local fs = b:CreateFontString(nil, "OVERLAY")
    fs:SetFont(self:GetFontPath(), cfg.fontSize + 4, cfg.fontFlags)
    fs:SetPoint("CENTER", 0, 0)
    fs:SetText("\195\151")   -- ×
    fs:SetTextColor(0.8, 0.8, 0.8)
    b:HookScript("OnEnter", function() fs:SetTextColor(GS:GetAccent()) end)
    b:HookScript("OnLeave", function() fs:SetTextColor(0.8, 0.8, 0.8) end)
end

function GS:SkinScrollBar(sb)
    if not sb or sb.__gsScroll then return end
    sb.__gsScroll = true
    local ar, ag, ab = self:GetAccent()
    local thumb = (sb.Track and sb.Track.Thumb) or sb.ThumbTexture or sb.thumbTexture
    if thumb then
        if thumb.GetObjectType and thumb:GetObjectType() == "Texture" then
            thumb:SetColorTexture(ar, ag, ab, 0.6)
        else
            for _, k in ipairs({ "Begin", "Middle", "End" }) do Kill(thumb[k]) end
            local t = thumb:CreateTexture(nil, "ARTWORK")
            t:SetColorTexture(ar, ag, ab, 0.6); t.__gs = true
            t:SetAllPoints()
        end
    end
end


-- Modern (11.x+) dropdown buttons: WowStyle1DropdownTemplate etc.
function GS:SkinDropdown(d)
    if d.__gsDD then return end
    d.__gsDD = true
    Kill(d.Background)
    for _, k in ipairs({ "Left", "Middle", "Right" }) do Kill(d[k]) end
    self:Box(d, { bg = cfg.btnBg })
    if d.Text and d.Text.SetFont then d.Text:SetFont(self:GetFontPath(), cfg.fontSize, cfg.fontFlags) end
end

-- Legacy UIDropDownMenuTemplate frames (also LibUIDropDownMenu)
function GS:SkinLegacyDropdown(d)
    if d.__gsLDD then return end
    d.__gsLDD = true
    local n = d:GetName()
    for _, s in ipairs({ "Left", "Middle", "Right" }) do Kill(_G[n .. s]) end
    self:Box(d, { bg = cfg.btnBg, x = 0, y = 4 })
    local text = _G[n .. "Text"]
    if text then text:SetFont(self:GetFontPath(), cfg.fontSize, cfg.fontFlags) end
end

-- Blizzard StaticPopup dialogs (global: affects every addon's popup)
function GS:SkinPopups()
    if self.popupsDone then return end
    self.popupsDone = true
    for i = 1, 4 do
        local f = _G["StaticPopup" .. i]
        if f then self:SkinFrame(f) end
    end
end

---------------------------------------------------------------------
-- Frame tree walker (idempotent; safe to call repeatedly)
---------------------------------------------------------------------
function GS:SkinTree(frame, depth)
    depth = depth or 0
    if depth > 8 or not frame.GetChildren then return end
    if depth == 0 and frame.ScrollBar then self:SkinScrollBar(frame.ScrollBar) end
    for _, child in ipairs({ frame:GetChildren() }) do
        if not (child.IsForbidden and child:IsForbidden()) then
            local t = child:GetObjectType()
            local n = child.GetName and child:GetName()
            if type(child.SetupMenu) == "function" then
                self:SkinDropdown(child)
            elseif t == "CheckButton" then
                self:SkinCheck(child)
            elseif t == "Button" then
                if IsPanelButton(child) then self:SkinButton(child) end
            elseif t == "EditBox" then
                self:SkinEdit(child)
            elseif t == "Frame" and n and _G[n .. "Left"] and _G[n .. "Middle"] and _G[n .. "Button"] and _G[n .. "Text"] then
                self:SkinLegacyDropdown(child)
            end
            if child.ScrollBar then self:SkinScrollBar(child.ScrollBar) end
            if child.NineSlice then Kill(child.NineSlice) end
            self:SkinTree(child, depth + 1)
        end
    end
end

-- Top-level window: strip chrome, add flat box, skin close button and children
function GS:SkinFrame(f)
    if not f or (f.IsForbidden and f:IsForbidden()) then return end
    if not f.__gsFrame then
        f.__gsFrame = true
        f:HookScript("OnShow", function() GS:SkinFrame(f) end)
    end
    self:Strip(f)
    self:StripRegions(f)
    self:Box(f)
    local n = f:GetName()
    self:SkinCloseButton(f.CloseButton or (n and _G[n .. "CloseButton"]))
    self:SkinTree(f)
end

---------------------------------------------------------------------
-- Registry: a skin only runs if its target addon is loaded
---------------------------------------------------------------------
GS.skins = {}
function GS:Register(addonName, fn)
    local entry = { addon = addonName, fn = fn }
    table.insert(self.skins, entry)
    return entry
end

local function RunPending()
    for _, s in ipairs(GS.skins) do
        if not s.done and IsAddOnLoaded(s.addon) then
            s.done = true
            local ok, err = pcall(s.fn, GS)
            if not ok then print("|cffff5555GoldmanShaq_AddonSkins|r error in " .. s.addon .. ": " .. tostring(err)) end
        end
    end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function() RunPending() end)

---------------------------------------------------------------------
-- Dev helper: /gsskin dump <GlobalFrameName>  -> prints the frame tree
-- so skins for new addons can target real frame names.
---------------------------------------------------------------------
local function KeyOf(parent, child)
    for k, v in pairs(parent) do
        if v == child and type(k) == "string" then return "." .. k end
    end
    return ""
end

function GS:Dump(frame, depth, state)
    depth = depth or 0
    state = state or { n = 0 }
    if state.n > 250 or depth > 5 then return end
    local pad = string.rep("  ", depth)
    for _, child in ipairs({ frame:GetChildren() }) do
        state.n = state.n + 1
        print(("%s%s %s%s %s"):format(pad, child:GetObjectType(), child:GetName() or "<anon>", KeyOf(frame, child),
            child.GetNumChildren and ("(" .. child:GetNumChildren() .. ")") or ""))
        self:Dump(child, depth + 1, state)
    end
end

SLASH_GSSKIN1 = "/gsskin"
SlashCmdList["GSSKIN"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    if cmd == "dump" and arg ~= "" then
        local f = _G[arg]
        if f and f.GetChildren then
            print("GS dump of " .. arg)
            GS:Dump(f)
        else
            print("GS: no frame named '" .. arg .. "'. Try /fstack to find names.")
        end
    elseif cmd == "reskin" then
        for _, s in ipairs(GS.skins) do if s.rescan then pcall(s.rescan) end end
        print("GS: re-skin requested")
    else
        print("/gsskin dump <FrameName> - print child frames (for writing new skins)")
        print("/gsskin reskin - re-scan and re-skin lazily created frames")
    end
end
