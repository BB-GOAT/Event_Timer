-- 纯本地获取方式
local localgettimefn = function()
    HookDeath("dragonfly", "dragonfly_spawner", function(event)
        SaveTimeData(event, TUNING.DRAGONFLY_RESPAWN_TIME)
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    localgettimefn = localgettimefn,
    remotegettimefn = function(Thread)
        GetWorldSettingsTimeLeft("regen_dragonfly", "dragonfly_spawner", function(res)
            if res and res.err then
                SaveTimeData("dragonfly_spawner", 0)
                print('[警告] dragonfly_spawner remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("dragonfly_spawner", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
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
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.dragonfly_spawner_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.dragonfly_spawner.cooldown), TimeToString(time))
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.dragonfly_spawner_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.dragonfly_spawner.tips)), 10, time, 2
        end
        return false
    end,
}

return info