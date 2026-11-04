-- Skin for "Addon Manargl" (AddonMrgl) by sfmict
local ADDON, GS = ...

local function Collect()
    local found = {}
    for name, obj in pairs(_G) do
        if type(name) == "string"
            and (name:find("^AddonMrgl") or name:find("^AddonMgr") or name:find("^AddonManargl"))
            and type(obj) == "table" and type(obj.GetObjectType) == "function"
            and not (obj.IsForbidden and obj:IsForbidden())
        then
            local ot = obj:GetObjectType()
            if ot == "Frame" or ot == "Button" then
                local parent = obj:GetParent()
                -- only top-level windows; children are reached by SkinTree
                if parent == UIParent or parent == nil then found[#found + 1] = obj end
            end
        end
    end
    return found
end

local function Run()
    for _, f in ipairs(Collect()) do GS:SkinFrame(f) end
end

GS:Register("AddonMrgl", function()
    Run()
    -- window may be built lazily, so scan again shortly after and on demand
    C_Timer.After(2, Run)
    for _, s in ipairs(GS.skins) do
        if s.addon == "AddonMrgl" then s.rescan = Run end
    end
end)
