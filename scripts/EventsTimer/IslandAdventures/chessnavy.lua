local info
info = {
    gettimefn = function()
        if TheWorld.components.chessnavy then
            return TheWorld.components.chessnavy.spawn_timer
        end
    end,
    gettextfn = function(time)
        if not TheWorld.components.chessnavy then return end
        return time and time > 0 and string.format(ReplacePrefabName(STRINGS.eventtimer.chessnavy.cooldown), TimeToString(time)) or STRINGS.eventtimer.chessnavy.readytext
    end,
    anim = {
        scale = 0.09,
        bank = "knightboat",
        build = "knightboat_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 7,
            y = -2,
        },
    },
    announcefn = function(context)
        local time = context.time
        local desc
        if time > 0 then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.chessnavy.cooldown), TimeToString(time))
        else
            desc = ReplacePrefabName(STRINGS.eventtimer.chessnavy.ready)
        end
        if desc and context.shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
        end
        return desc
    end
}

return info