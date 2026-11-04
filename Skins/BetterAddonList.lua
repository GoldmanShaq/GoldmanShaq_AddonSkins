-- Skin for BetterAddonList (nebularg). It decorates Blizzard's AddonList frame
-- (search box, set dropdown, save/load buttons, lock checkboxes), so we skin AddonList.
local ADDON, GS = ...

local skin = GS:Register("BetterAddonList", function()
    local function Setup()
        local f = _G.AddonList
        if not f then return end
        GS:SkinFrame(f)

        -- scroll rows are recycled, so skin them as they are (re)built
        if type(_G.AddonList_InitButton) == "function" then
            hooksecurefunc("AddonList_InitButton", function(entry) GS:SkinTree(entry, 1) end)
        end
        if type(_G.AddonList_Update) == "function" then
            hooksecurefunc("AddonList_Update", function() GS:SkinTree(f) end)
        end

        -- BetterAddonList asks for a set name through a StaticPopup
        if GS.cfg.skinPopups then GS:SkinPopups() end
    end

    if _G.AddonList then
        Setup()
    else
        -- Blizzard_AddOnList may load later
        local w = CreateFrame("Frame")
        w:RegisterEvent("ADDON_LOADED")
        w:SetScript("OnEvent", function(self)
            if _G.AddonList then
                self:UnregisterAllEvents()
                Setup()
            end
        end)
    end
end)

skin.rescan = function()
    local f = _G.AddonList
    if f then GS:SkinFrame(f) end
end
