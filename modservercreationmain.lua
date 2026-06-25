local _G = GLOBAL
local rawget = _G.rawget

modimport("main/fe_patches.lua")

-- 尝试自动开启依赖模组
if rawget(_G, "TheFrontEnd") then
    local basementmod = "workshop-3750536829"
    if not _G.KnownModIndex:IsModEnabledAny(basementmod) then
        _G.KnownModIndex:Enable(basementmod)
    end
end