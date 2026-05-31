-- 纯本地获取方式
-- if not (EventTimer.GetTimeFromRemoteCommand or EventTimer.GetTimeFromServerMod) then
    HookDeath("crabking", "crabkingspawner", function(event)
        SaveTimeData(event, TUNING.CRABKING_RESPAWN_TIME)
    end)
-- end

----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------

local info
info = {
    anim = {
        scale = 0.022,
        bank = "king_crab",
        build = "crab_king_build",
        animation = "inert",
        loop = true,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.crabkingspawner_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.crabkingspawner.cooldown), TimeToString(time))
    end
}

return info