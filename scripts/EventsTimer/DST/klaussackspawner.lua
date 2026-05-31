-- 纯本地获取方式
-- if not (EventTimer.GetTimeFromRemoteCommand or EventTimer.GetTimeFromServerMod) then
    AddPrefabPostInit("klaus_sack", function(inst)
        inst:ListenForEvent("onremove", function(inst)
            local pos = inst:GetPosition()
            local bundle = TheSim:FindEntities(pos.x, 0, pos.z, 4, {"bundle"}, { 'FX', 'DECOR', 'INLIMBO', 'NOCLICK', 'player' })
            if #bundle > 0 then
                if IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) then
                    SaveTimeData("klaussackspawner", TUNING.KLAUSSACK_EVENT_RESPAWN_TIME)
                end
            end
        end)
    end)
-- end

----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------

local info
info = {
    anim = {
        scale = 0.1,
        bank = "klaus_bag",
        build = "klaus_bag",
        animation = "idle",
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.klaussackspawner_time
        local text = ThePlayer.HUD.WarningEventTimeData.klaussackspawner_text
        local despawnday = Extract_by_format(text, STRINGS.eventtimer.klaussackspawner.despawntext)
        if despawnday then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.despawn), despawnday)
        elseif time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.klaussackspawner_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.tips)), 10, time, 2
        end
        return false
    end
}

return info