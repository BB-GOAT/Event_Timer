local info
info = {
    remotegettimefn = function(Thread)
        local cmd = [[
            if TheWorld.components.krakener then
                local time = TheWorld.components.krakener:TimeUntilCanSpawn()
                return DataDumper({ time = time })
            end
            return DataDumper({ not_found = true })
        ]]
        BBGOAT_util:remote(cmd, nil, function(res)
            if res and res.err then
                SaveTimeData("krakener", 0)
                SaveTextData("krakener", "")
                print('[警告] krakener remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("krakener", res.time)
                SaveTextData("krakener", res.time > 0 and string.format(ReplacePrefabName(STRINGS.eventtimer.krakener.cooldown), TimeToString(res.time)) or ReplacePrefabName(STRINGS.eventtimer.krakener.ready))
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
    DisableClientPredictionClearText = true,
    anim = {
        scale = 0.027,
        bank = "quacken",
        build = "quacken",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -6,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.krakener_time
        if time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.krakener.cooldown), TimeToString(time))
        end
        return ReplacePrefabName(STRINGS.eventtimer.krakener.ready)
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.krakener_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.krakener.tips)), 10, time, 2
        end
        return false
    end
}

return info