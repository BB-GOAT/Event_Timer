local info
info = {
    remotegettimefn = function(Thread)
        local cmd = [[
            if TheWorld and TheWorld.components.deerherdspawner then
                local data = TheWorld.components.deerherdspawner:OnSave()
                local time = data and data._timetospawn
                return DataDumper({time = time})
            end
            return DataDumper({ not_found = true })
        ]]
        BBGOAT_util:remote(cmd, nil, function(res)
            if res and res.err then
                SaveTimeData("deerherdspawner", 0)
                print('[警告] deerherdspawner remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("deerherdspawner", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
    anim = {
        scale = 0.088,
        bank = "deer",
        build = "deer_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = -6,
            y = -6,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.deerherdspawner_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.deerherdspawner.cooldown), TimeToString(time))
    end
}

return info