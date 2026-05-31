-- 纯本地获取方式
-- if not (EventTimer.GetTimeFromRemoteCommand or EventTimer.GetTimeFromServerMod) then
    HookDeath("dragonfly", "dragonfly_spawner", function(event)
        SaveTimeData(event, TUNING.DRAGONFLY_RESPAWN_TIME)
    end)
-- end

----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------

local info
info = {
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