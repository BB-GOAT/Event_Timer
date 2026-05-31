-- 纯本地获取方式
-- if not (EventTimer.GetTimeFromRemoteCommand or EventTimer.GetTimeFromServerMod) then
    AddPrefabPostInit("atrium_gate", function(inst)
        inst:DoTaskInTime(0.2, function(inst)
            if inst and inst:IsValid() and inst.AnimState then
                local bank, anim, frame = inst.AnimState:GetHistoryData()
                if anim:find("idle") then
                    SaveTimeData("atrium_gate", 0)
                end
            end
        end)
    end)

    HookDeath("stalker_atrium", "atrium_gate", function(event, inst)
        -- local time = TUNING.ATRIUM_GATE_DESTABILIZE_TIME + TUNING.ATRIUM_GATE_DESTABILIZE_WARNING_TIME
        -- SaveTimeData(event, time) -- 远古犀牛倒计时（远古遗迹重置倒计时）
        -- inst:DoTaskInTime(time, function() -- 这样穿越世界时会丢数据
        --     SaveTimeData(event, TUNING.ATRIUM_GATE_COOLDOWN + TUNING.ATRIUM_GATE_DESTABILIZE_DELAY) -- 远古大门冷却倒计时
        -- end)
        SaveTimeData(event, TUNING.ATRIUM_GATE_COOLDOWN + TUNING.ATRIUM_GATE_DESTABILIZE_DELAY + TUNING.ATRIUM_GATE_DESTABILIZE_TIME + TUNING.ATRIUM_GATE_DESTABILIZE_WARNING_TIME)
    end)
-- end

----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------

-- 远古大门
local info
info = {
    anim = {
        scale = 0.055,
        bank = "atrium_gate",
        build = "atrium_gate",
        animation = "idle",
        uioffset = {
            x = -2,
            y = -5,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.atrium_gate_time
        local text = ThePlayer.HUD.WarningEventTimeData.atrium_gate_text
        if string.find(text, ReplacePrefabName("<prefab=atrium_gate>")) then
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.atrium_gate.cooldown), TimeToString(time))
        else
            return time and string.format(STRINGS.eventtimer.atrium_gate.destabilizing, TimeToString(time))
        end
    end,
}

return info