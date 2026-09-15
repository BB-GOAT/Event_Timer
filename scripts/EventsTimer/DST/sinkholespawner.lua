local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("rage", "antlion"),
    anim = {
        scale = 0.05,
        bank = "antlion",
        build = "antlion_build",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 0,
            y = -5,
        },
    },
    announcefn = function(context)
        local time = context.time
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.sinkholespawner.cooldown), TimeToString(time))
        if context.shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
        end
        return desc
    end,
    tipsfn = function(context)
        local time = context.time
        if time > 2 and time < 60 then
            return true, info.announcefn, time, nil, 2
        elseif ready_attack(time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.sinkholespawner.attack)
            if context.shard_id ~= EventTimer.CurrentShardId then
                desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
            end
            return true, StringToFunction(desc), 10, time, 3
        end
        return false
    end
}

return info