-- 纯本地获取方式
local localgettimefn = function()
    local phase_task

    local function CancelPhaseTask()
        if phase_task then
            phase_task:Cancel()
            phase_task = nil
        end
    end

    local function ClearPrediction()
        CancelPhaseTask()
        SaveTimeData("atrium_gate", 0)
        SaveTextData("atrium_gate", "")
    end

    local function RefreshPrediction(end_time)
        CancelPhaseTask()
        local time = end_time - GetWorldTime()
        if time <= 0 then
            ClearPrediction()
            return
        end

        -- 文件中保留最终冷却结束时间，界面只显示当前阶段的剩余时间
        local resetting = time > TUNING.ATRIUM_GATE_COOLDOWN -- 大门冷却时长；超过此值说明遗迹尚未重置
        if resetting then
            time = time - TUNING.ATRIUM_GATE_COOLDOWN -- 扣除重置后的大门冷却时长，得到重置剩余时间
        end
        SaveTimeData("atrium_gate", time, true)
        SaveTextData("atrium_gate", string.format(
            ReplacePrefabName(resetting and STRINGS.eventtimer.atrium_gate.destabilizing or STRINGS.eventtimer.atrium_gate.cooldown),
            TimeToString(time)
        ))
        phase_task = TheWorld:DoTaskInTime(time, function()
            phase_task = nil
            RefreshPrediction(end_time)
        end)
    end

    AddPrefabPostInit("atrium_gate", function(inst)
        inst:DoTaskInTime(0.2, function(inst)
            if inst and inst:IsValid() and inst.AnimState then
                local bank, anim, frame = inst.AnimState:GetHistoryData()
                if anim:find("idle") then
                    ClearPrediction()
                end
            end
        end)
    end)

    AddPrefabPostInit("stalker_atrium", function(inst) -- 远古织影者
        ClearPrediction()
        local started = false
        local function OnDeath(inst)
            -- 正常死亡时音乐状态同步为3，衰败消失不会进入此状态
            if started or not (inst._music and inst._music:value() == 3) then
                return
            end
            started = true
            local time = TUNING.ATRIUM_GATE_DESTABILIZE_DELAY -- 开始失稳前的延迟
                + TUNING.ATRIUM_GATE_DESTABILIZE_TIME -- 失稳持续时间，结束时重置遗迹
                + TUNING.ATRIUM_GATE_COOLDOWN -- 遗迹重置后的大门冷却时长
            SaveTimeData("atrium_gate", time)
            RefreshPrediction(GetWorldTime() + time)
        end

        if TheWorld.ismastersim then
            inst:ListenForEvent("death", OnDeath) -- 主机直接接收死亡事件
        else
            inst:ListenForEvent("musicdirty", OnDeath) -- 客机接收死亡音乐状态的网络同步
        end
    end)

    AddLoadDataFilePostInit(function(world_data)
        local end_time = world_data.atrium_gate
        if checknumber(end_time) then
            RefreshPrediction(end_time)
        end
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