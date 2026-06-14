local info
info = {
    remotegettimefn = function(Thread)
        local cmd = [[
            if TheWorld.components.chessnavy then
                local time = TheWorld.components.chessnavy.spawn_timer
                return DataDumper({ time = time })
            end
            return DataDumper({ not_found = true })
        ]]
        BBGOAT_util:remote(cmd, nil, function(res)
            if res and res.err then
                SaveTimeData("chessnavy", 0)
                SaveTextData("chessnavy", "")
                print('[警告] chessnavy remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("chessnavy", res.time)
                SaveTextData("chessnavy", res.time == 0 and STRINGS.eventtimer.chessnavy.readytext or "")
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
    DisableClientPredictionClearText = true,
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
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.chessnavy_time
        if time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.chessnavy.cooldown), TimeToString(time))
        end
        return ReplacePrefabName(STRINGS.eventtimer.chessnavy.ready)
    end
}

return info