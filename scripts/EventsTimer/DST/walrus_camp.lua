local walrus_house_list = {}
local function GetWorldSettingsTimeLeft(name, ent)
    if ent and ent.components.worldsettingstimer then
        if not ent.components.worldsettingstimer:IsPaused(name) then
            local time = ent.components.worldsettingstimer:GetTimeLeft(name)
            return time and time < 65535 and time
        end
    end
end

local function GetSeparator(i)
    local items_per_line = #walrus_house_list
    items_per_line = items_per_line < 5 and 1 or items_per_line < 9 and 2 or 3
    if (i - 1) % items_per_line == 0 then
        return "\n"
    else
        return " "
    end
end

local info
info = {
    postinitfn = function()
        if not TheNet:GetIsServer() then return end
        -- 收集世界上的海象巢
        AddPrefabPostInit("walrus_camp", function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            table.insert(walrus_house_list, {ent = inst, x = x, z = z})
            table.sort(walrus_house_list, function(a, b) -- 按坐标排序，使得每次序号一致
                return a.x < b.x
            end)
            inst:ListenForEvent("onremove", function(inst)
                for i, v in ipairs(walrus_house_list) do
                    if v.ent == inst then
                        table.remove(walrus_house_list, i)
                        break
                    end
                end
            end)
        end)
    end,
    gettextfn = function()
        if not (TheWorld and TheWorld.state.iswinter) then return end
        local lines = {}
        for i, info in ipairs(walrus_house_list) do
            local inst = info.ent
            local time_str = TimeToString(GetWorldSettingsTimeLeft("walrus", inst)) or STRINGS.eventtimer.walrus_camp.ready
            table.insert(lines, string.format(STRINGS.eventtimer.walrus_camp.cooldown, i, time_str))
        end
        local description = ""
        for i, line in ipairs(lines) do
            description = description .. (i == 1 and "" or GetSeparator(i)) .. line
        end
        return description
    end,
    DisableShardRPC = true,
    anim = {
        scale = 0.05,
        bank = "walrus_house",
        build = "walrus_house",
        animation = "idle",
        loop = true,
    },
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.walrus_camp_text
        text = string.gsub(text, "\n", " ")
        return ReplacePrefabName("<prefab=walrus_camp>") .. " : " .. text
    end
}

return info