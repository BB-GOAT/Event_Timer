local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("regen_dragonfly", "dragonfly_spawner"),
    animchangefn = ChangeanimByWintersFeast,
    defaultanim = {
        scale = 0.044,
        bank = "dragonfly",
        build = "dragonfly_build",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 0,
            y = -4,
        },
    },

    winterfeastanim = {
        scale = 0.044,
        bank = "dragonfly",
        build = "dragonfly_yule_build",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 0,
            y = -4,
        },
    },
    announcefn = function(context)
        local time = context.time
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.dragonfly_spawner.cooldown), TimeToString(time))
        if context.shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
        end
        return desc
    end,
    tipsfn = function(context)
        if ready_attack(context.time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.dragonfly_spawner.tips)
            if context.shard_id ~= EventTimer.CurrentShardId then
                desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
            end
            return true, StringToFunction(desc), 10, context.time, 2
        end
        return false
    end,
}

return info