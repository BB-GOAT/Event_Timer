local info
local need_tips = false
local remotegettextfn = function(Thread)
    local cmd = [[
        local self = TheWorld.components.banditmanager
        if not self then return DataDumper({ not_found = true })end
        local str = self:GetDebugString()
        local stolen_oincs, active_bandit = string.match(str, "Stolen Oincs: (%d+) Active Bandit: (%a+) Respawns In")
        local timer = TheWorld.components.worldsettingstimer
        local time = timer and not timer:IsPaused("pig_bandit_respawn_time_") and timer:GetTimeLeft("pig_bandit_respawn_time_") or 0
        return DataDumper({ stolen_oincs = stolen_oincs, active_bandit = active_bandit, time = time })
    ]]

    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.err then
            SaveTextData("banditmanager", "")
            print('[警告] banditmanager remotegettextfn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res and res.not_found then
            need_tips = false
            info.DisableClientPredictionClearText = false
            SaveTextData("banditmanager", "")
            SaveTimeData("banditmanager", 0)
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res then
            local time = checknumber(res.time) and math.max(0, res.time) or 0
            local stolen_oincs = res.stolen_oincs
            local active_bandit = res.active_bandit
            if not (stolen_oincs and active_bandit) then return end
            need_tips = active_bandit == "true"
            -- 只保留出没提示，刷新倒计时结束后仍需正常清空文本
            info.DisableClientPredictionClearText = active_bandit == "true"
            SaveTimeData("banditmanager", active_bandit == "true" and 0 or time)
            if active_bandit == "true" then
                SaveTextData("banditmanager", string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.readytext), stolen_oincs))
            elseif time > 0 then
                SaveTextData("banditmanager", string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.cooldown), TimeToString(time), stolen_oincs, active_bandit))
            else
                SaveTextData("banditmanager", "")
            end
        end
    end)
end

----------------------------------------------------------------------------------------------

AddPrefabPostInit("pigbandit", function(inst)
    if EventTimer.GetTimeFromRemoteCommand then
        -- 延后一帧，等服务器管理器完成新实体的登记
        TheWorld:DoTaskInTime(0, function() remotegettextfn() end)
    else
        info.DisableClientPredictionClearText = true
        SaveTimeData("banditmanager", 0)
        SaveTextData("banditmanager", ReplacePrefabName(STRINGS.eventtimer.banditmanager.exists))
    end
    need_tips = true
    inst:ListenForEvent("onremove", function(inst)
        if EventTimer.GetTimeFromRemoteCommand then
            -- 死亡、逃走或离开视野后重新确认服务器上的实际状态
            TheWorld:DoTaskInTime(1, function() remotegettextfn() end)
        else
            info.DisableClientPredictionClearText = false
            need_tips = false
            SaveTextData("banditmanager", "")
        end
        if inst and inst:IsValid() and inst.AnimState then
            local bank, anim, frame = inst.AnimState:GetHistoryData()
            if anim:find("death") then
                if not EventTimer.GetTimeFromRemoteCommand then
                    SaveTimeData("banditmanager", TUNING.PIG_BANDIT_DEATH_RESPAWN_TIME)
                end
                need_tips = false
            end
        end
    end)
end)

----------------------------------------------------------------------------------------------

info = {
    -- 离开视野后仍可能延迟逃走或在远处死亡，需要定期确认状态
    remotegettextfn = remotegettextfn,
    DisableSaveTime = true, -- 重载游戏后时间会变
    image = {
        atlas = "images/pig_bandit.xml",
        tex = "pig_bandit.tex",
        scale = 0.07,
    },
    anim = {
        scale = 0.07,
        build = "pig_bandit",
        bank = "townspig",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -15,
        }
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.banditmanager_time
        local text = ThePlayer.HUD.WarningEventTimeData.banditmanager_text
        if text ~= "" then
            local _time, stolen_oincs = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.banditmanager.cooldown))
            if stolen_oincs then
                return time and string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.announce_cooldown), TimeToString(time), stolen_oincs)
            else
                stolen_oincs = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.banditmanager.readytext))
                return stolen_oincs and string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.ready), stolen_oincs) or text
            end
        else
            return time > 0 and string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.announce_time), TimeToString(time)) or nil
        end
    end,
    tipsfn = function()
        return need_tips, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.banditmanager.tips)), 5, nil, 3
    end
}

return info