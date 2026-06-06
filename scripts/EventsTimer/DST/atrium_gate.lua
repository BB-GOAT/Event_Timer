-- 纯本地获取方式
local localgettimefn = function()
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
end

----------------------------------------------------------------------------------------------

local remotegettextfn = function(Thread)
    local cmd = [[
        local TimerPrefabs = _G.EventTimerClient.TimerPrefabs
        local HookPrefab = _G.EventTimerClient.HookPrefab
        local inst = TimerPrefabs["atrium_gate"] or HookPrefab("atrium_gate")
        if not (inst and inst.components.worldsettingstimer) then
            return DataDumper({
                not_found = true
            })
        end
        local time_1 = _G.EventTimerClient.GetWorldSettingsTimeLeft("cooldown", "atrium_gate")
        local time_2 = _G.EventTimerClient.GetWorldSettingsTimeLeft("destabilizing", "atrium_gate")
        local mode = (time_1 ~= 0 and 1) or (time_2 ~= 0 and 2)
        local time = (mode == 1 and time_1) or (mode == 2 and time_2)
        return DataDumper({
            time = time,
            cooldown_mode = mode
        })
    ]]
    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.time then
            local cooldown_mode = res.cooldown_mode
            SaveTimeData("atrium_gate", res.time)
            SaveTextData("atrium_gate",
                cooldown_mode == 1 and string.format(ReplacePrefabName(STRINGS.eventtimer.atrium_gate.cooldown), TimeToString(res.time)) or
                cooldown_mode == 2 and string.format(STRINGS.eventtimer.atrium_gate.destabilizing, TimeToString(res.time))
            )
        elseif res and res.not_found then
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
        else
            SaveTimeData("atrium_gate", 0)
            SaveTextData("atrium_gate", "")
            if res and res.err then
                print('[警告] atrium_gate remotegettextfn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end
    end)
end

----------------------------------------------------------------------------------------------

-- 远古大门
local info
info = {
    localgettimefn = localgettimefn,
    remotegettextfn = remotegettextfn,
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
        return ThePlayer.HUD.WarningEventTimeData.atrium_gate_text
    end,
}

return info