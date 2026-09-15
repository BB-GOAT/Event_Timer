-- 果蝇王

local lordfruitfly_spawned -- 果蝇王是否已生成

local info
info = {
    postinitfn = function()
        if not TheNet:GetIsServer() then return end
        AddPrefabPostInit("lordfruitfly", function(inst)
            lordfruitfly_spawned = true
            inst:ListenForEvent("onremove", function()
                lordfruitfly_spawned = false
            end)
        end)
    end,
    gettimefn = GetWorldSettingsTimeLeft("lordfruitfly_spawntime"),
    gettextfn = function()
        if lordfruitfly_spawned then
            return ReplacePrefabName(STRINGS.eventtimer.farming_manager.ready)
        end
    end,
    anim = {
        scale = 0.2,
        build = "fruitfly_evil",
        bank = "fruitfly",
        animation = "idle",
        offset = {
            x = 0,
            y = -20
        },
        uioffset = {
            x = -2,
            y = -22
        },
        loop = true,
    },
    DisableShardRPC = true,
    announcefn = function(context)
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.farming_manager.cooldown), TimeToString(context.time))
        if context.shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
        end
        return desc
    end,
    tipsfn = function(context)
        if context.text == ReplacePrefabName(STRINGS.eventtimer.farming_manager.ready) and context.shard_id == EventTimer.CurrentShardId then -- 其它世界的text的前缀可能会被玩家关掉，仍需检查shard_id
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.farming_manager.tips)), 5, nil, 3
        end
        return false
    end,
}

return info