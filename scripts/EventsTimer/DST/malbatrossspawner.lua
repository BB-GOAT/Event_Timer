local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("malbatross_timetospawn"),
    anim = {
        scale = 0.035,
        bank = "malbatross",
        build = "malbatross_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 5,
            y = -10,
        },
    },
    announcefn = function(context)
        local time = context.time
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.malbatrossspawner.cooldown), TimeToString(time))
        if context.shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
        end
        return desc
    end
}

return info