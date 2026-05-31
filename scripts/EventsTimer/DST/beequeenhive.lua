-- 纯本地获取方式
-- if not (EventTimer.GetTimeFromRemoteCommand or EventTimer.GetTimeFromServerMod) then
    AddPrefabPostInit("beequeenhivegrown", function()
        SaveTimeData("beequeenhive", 0)
    end)

    HookDeath("beequeen", "beequeenhive", function(event)
        SaveTimeData(event, TUNING.BEEQUEEN_RESPAWN_TIME)
    end)
-- end

----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------

local info
info = {
    anim = {
        scale = 0.055,
        bank = "bee_queen",
        build = "bee_queen_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -10,
        },
    },
    DisableShardRPC = true,
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.beequeenhive_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.beequeenhive.cooldown), TimeToString(time))
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.beequeenhive_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.beequeenhive.tips)), 10, time, 2
        end
        return false
    end,
}

return info