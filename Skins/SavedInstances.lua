-- Skin for SavedInstances' LibQTip tooltips
local ADDON, GS = ...

GS:Register("SavedInstances", function()
    local LibQTip = LibStub and LibStub("LibQTip-1.0", true)
    if not LibQTip then return end
    local cfg = GS.cfg
    local WHITE = GS.WHITE

    local function MakeEdge(parent)
        local e = {}
        for i = 1, 4 do
            e[i] = parent:CreateTexture(nil, "BORDER")
            e[i]:SetTexture(WHITE)
        end
        return e
    end

    local function LayoutEdges(tt, px)
        px = GS:PixelSize(tt, px)
        local e = tt.__ellesEdges
        e[1]:ClearAllPoints(); e[1]:SetPoint("TOPLEFT");    e[1]:SetPoint("TOPRIGHT");    e[1]:SetHeight(px)
        e[2]:ClearAllPoints(); e[2]:SetPoint("BOTTOMLEFT"); e[2]:SetPoint("BOTTOMRIGHT"); e[2]:SetHeight(px)
        e[3]:ClearAllPoints(); e[3]:SetPoint("TOPLEFT");    e[3]:SetPoint("BOTTOMLEFT");  e[3]:SetWidth(px)
        e[4]:ClearAllPoints(); e[4]:SetPoint("TOPRIGHT");   e[4]:SetPoint("BOTTOMRIGHT"); e[4]:SetWidth(px)
    end

    local function Apply(tt)
        if not tt then return end

        if tt.SetBackdrop then
            tt:SetBackdrop(nil)
            if not tt.__ellesNoBackdrop then
                tt.__ellesNoBackdrop = true
                tt.SetBackdrop = function() end
            end
        end
        if tt.NineSlice then tt.NineSlice:Hide() end

        if not tt.__ellesBG then
            tt.__ellesBG = tt:CreateTexture(nil, "BACKGROUND", nil, -8)
            tt.__ellesBG:SetTexture(WHITE)
            tt.__ellesBG:SetAllPoints()
            tt.__ellesEdges = MakeEdge(tt)
            tt.__ellesAccent = tt:CreateTexture(nil, "ARTWORK")
            tt.__ellesAccent:SetTexture(WHITE)
            tt.__ellesAccent:SetPoint("TOPLEFT", 0, 0)
            tt.__ellesAccent:SetPoint("TOPRIGHT", 0, 0)
            tt.__ellesAccent:SetHeight(1)
        end

        local ar, ag, ab = GS:GetAccent()
        tt.__ellesBG:SetVertexColor(unpack(cfg.bg))

        LayoutEdges(tt, cfg.borderPx)
        local br, bg, bb, ba = unpack(cfg.border)
        if cfg.useAccentBorder then br, bg, bb, ba = ar, ag, ab, 1 end
        for _, t in ipairs(tt.__ellesEdges) do t:SetVertexColor(br, bg, bb, ba) end

        if cfg.accentLine then
            tt.__ellesAccent:SetVertexColor(ar, ag, ab, 1)
            tt.__ellesAccent:Show()
        else
            tt.__ellesAccent:Hide()
        end

        local font, headerFont = GS:EnsureFonts()
        if tt.SetFont then tt:SetFont(font) end
        if tt.SetHeaderFont then tt:SetHeaderFont(headerFont) end

        -- row highlight: bake alpha into a colour texture so it never covers text
        local hr, hg, hb, ha = ar, ag, ab, cfg.highlightAlpha
        local seen = {}
        local function Tint(t)
            if t and not seen[t] and t.GetObjectType and t:GetObjectType() == "Texture" then
                seen[t] = true
                t:SetTexture(nil)
                t:SetColorTexture(hr, hg, hb, ha)
                t:SetTexCoord(0, 1, 0, 1)
                t:SetVertexColor(1, 1, 1, 1)
                t:SetDrawLayer("BACKGROUND", 7)
            end
        end
        Tint(tt.highlightTexture)
        Tint(tt.highlight)
        local hf = tt.highlight
        if hf and hf.GetRegions then
            for _, region in ipairs({ hf:GetRegions() }) do Tint(region) end
        end
    end

    local function Skin(tt)
        if not tt then return end
        Apply(tt)
        if not tt.__ellesHooked then
            tt.__ellesHooked = true
            tt:HookScript("OnShow", Apply)
        end
    end

    hooksecurefunc(LibQTip, "Acquire", function(self, key)
        if type(key) == "string" and key:find("^SavedInstances") then
            Skin(LibQTip.activeTooltips and LibQTip.activeTooltips[key])
        end
    end)

    if LibQTip.activeTooltips then
        for key, tt in pairs(LibQTip.activeTooltips) do
            if type(key) == "string" and key:find("^SavedInstances") then Skin(tt) end
        end
    end
end)
