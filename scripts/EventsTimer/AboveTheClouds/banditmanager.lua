local remotegettimefn = function(Thread)
    GetWorldSettingsTimeLeft("pig_bandit_respawn_time_", nil, function(res)
        if res and res.err then
            SaveTimeData("banditmanager", 0)
            print('[警告] banditmanager remotegettimefn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res and res.time then
            SaveTimeData("banditmanager", res.time)
        elseif res and res.not_found then
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
        end
    end)
end

----------------------------------------------------------------------------------------------

local remotegettextfn = function(Thread)
    if not TheWorld:HasTag("cave") then return end
    local cmd = [[
        local self = TheWorld.components.banditmanager
        if not self then return DataDumper({ not_found = true })end
        local str = self:GetDebugString()
        local stolen_oincs, active_bandit = string.match(str, "Stolen Oincs: (%d+) Active Bandit: (%a+) Respawns In")
        return DataDumper({ stolen_oincs = stolen_oincs, active_bandit = active_bandit })
    ]]

    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.err then
            SaveTextData("banditmanager", "")
            print('[警告] banditmanager remotegettextfn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res.not_found then
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res then
            local time = ThePlayer.HUD.WarningEventTimeData.banditmanager_time
            local stolen_oincs = res.stolen_oincs
            local active_bandit = res.active_bandit
            if not (stolen_oincs and active_bandit) then return end
            if active_bandit == "true" then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.readytext), stolen_oincs)
            elseif time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.cooldown), TimeToString(time), stolen_oincs, active_bandit)
            end
        end
    end)
end

----------------------------------------------------------------------------------------------

local need_tips = false
AddPrefabPostInit("pigbandit", function(inst)
    if EventTimer.GetTimeFromRemoteCommand then
        remotegettimefn()
        remotegettextfn()
    else
        SaveTimeData("banditmanager", 0)
    end
    need_tips = true
    inst:ListenForEvent("onremove", function(inst)
        if inst and inst:IsValid() and inst.AnimState then
            local bank, anim, frame = inst.AnimState:GetHistoryData()
            if anim:find("death") then
                if EventTimer.GetTimeFromRemoteCommand then
                    -- 从远程指令刷新时间
                    TheWorld:DoTaskInTime(1, function()
                        remotegettimefn()
                        remotegettextfn()
                    end)
                else
                    SaveTimeData("banditmanager", TUNING.PIG_BANDIT_DEATH_RESPAWN_TIME)
                end
                need_tips = false
            end
        end
    end)
end)

----------------------------------------------------------------------------------------------

local info
info = {
    -- 不要定时获取数据，而是满足条件时获取
    -- remotegettimefn = remotegettimefn,
    -- remotegettextfn = remotegettextfn,
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
    DisableShardRPC = true,
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.banditmanager_time
        local text = ThePlayer.HUD.WarningEventTimeData.banditmanager_text
        if text ~= "" then
            local _time, stolen_oincs = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.banditmanager.cooldown))
            if stolen_oincs then
                return time and string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.announce_cooldown), TimeToString(time), stolen_oincs)
            else
                stolen_oincs = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.banditmanager.readytext))
                return stolen_oincs and string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.ready), stolen_oincs)
            end
        else
            return string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.announce_time), TimeToString(time))
        end
    end,
    tipsfn = function()
        return need_tips, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.banditmanager.tips)), 5, nil, 3
    end
}

return info