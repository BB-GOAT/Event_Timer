-- 纯本地获取方式
-- if not (EventTimer.GetTimeFromRemoteCommand or EventTimer.GetTimeFromServerMod) then
    local eyes_prefab = {"eyeofterror", "twinofterror1", "twinofterror2"}
    for _, prefab in ipairs(eyes_prefab) do
        AddPrefabPostInit(prefab, function(boss)
            boss:DoTaskInTime(0.2, function(inst)
                SaveTimeData("terrarium", 0)
                inst:ListenForEvent("onremove", function(inst)
                    if inst and inst:IsValid() and inst.AnimState then
                        local bank, anim, frame = inst.AnimState:GetHistoryData()
                        if anim:find("death") then
                            local pos = inst:GetPosition()
                            local other_ents = TheSim:FindEntities(pos.x, 0, pos.z, 64, nil, { 'FX', 'DECOR', 'INLIMBO', 'NOCLICK', 'player' })
                            local have_other_eye = false
                            for _, ent in ipairs(other_ents) do
                                if table.contains(eyes_prefab, ent.prefab) then
                                    have_other_eye = true
                                    break
                                end
                            end
                            if not have_other_eye then
                                SaveTimeData("terrarium", TUNING.EYEOFTERROR_SPAWNDELAY)
                            end
                        end
                    end
                end)
            end)
        end)
    end
-- end

----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------

local info
info = {
    anim = {
        scale = 0.2,
        bank = "terrarium",
        build = "terrarium",
        animation = "idle",
        uioffset = {
            x = 0,
            y = -4,
        },
    },
    DisableShardRPC = true,
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.terrarium_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.terrarium.cooldown), TimeToString(time))
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.terrarium_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.terrarium.tips)), 10, time, 2
        end
        return false
    end,
}

return info