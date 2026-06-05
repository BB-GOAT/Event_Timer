-- 纯本地获取方式
local localgettimefn = function()
    HookDeath("malbatross", "malbatrossspawner", function(event)
        SaveTimeData(event, TUNING.MALBATROSS_SPAWNDELAY_BASE)
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    localgettimefn = localgettimefn,
    remotegettimefn = function(Thread)
        GetWorldSettingsTimeLeft("malbatross_timetospawn", nil, function(res)
            if res and res.err then
                SaveTimeData("malbatrossspawner", 0)
                print('[警告] malbatrossspawner remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("malbatrossspawner", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
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
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.malbatrossspawner_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.malbatrossspawner.cooldown), TimeToString(time))
    end
}

return info