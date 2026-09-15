local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("toadstool_respawntask"),
    anim = {
        scale = 0.03,
        bank = "toadstool",
        build = "toadstool_build",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 0,
            y = -5,
        },
    },
    announcefn = function(context)
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.toadstoolspawner.cooldown), TimeToString(context.time))
        if context.shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
        end
        return desc
    end
}

return info