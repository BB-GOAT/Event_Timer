-- 纯本地获取方式
local localgettimefn = function()
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
end

----------------------------------------------------------------------------------------------

local info
info = {
    localgettimefn = localgettimefn,
    remotegettimefn = function(Thread)
        GetWorldSettingsTimeLeft("cooldown", "terrarium", function(res)
            if res and res.err then
                SaveTimeData("terrarium", 0)
                print('[警告] terrarium remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("terrarium", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
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