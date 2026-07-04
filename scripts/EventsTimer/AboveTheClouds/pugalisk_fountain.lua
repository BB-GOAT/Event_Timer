-- 纯本地获取方式
local localgettimefn = function()
    local need_hook = true
    local status
    AddPrefabPostInit("pugalisk_fountain", function(inst)
        -- 刷帧监听动画
        if not need_hook then return end
        need_hook = false
        inst:DoPeriodicTask(0.1, function()
            if inst and inst:IsValid() and inst.AnimState then
                local bank, anim, frame = inst.AnimState:GetHistoryData()
                if anim == "flow_pst" and (status == 1 or not status) then -- 泉水消失
                    status = 0
                    SaveTimeData("pugalisk_fountain", TUNING.PUGALISK_RESPAWN)
                elseif anim == "flow_loop" and (status == 0 or not status) then -- 泉水已充满
                    status = 1
                    SaveTimeData("pugalisk_fountain", 0)
                end
            end
        end)
        inst:ListenForEvent("onremove", function(inst)
            need_hook = true
        end)
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    localgettimefn = localgettimefn,
    remotegettimefn = function(Thread)
        local cmd = [[
            local TimerPrefabs = _G.EventTimerClient.TimerPrefabs
            local HookPrefab = _G.EventTimerClient.HookPrefab
            local inst = TimerPrefabs["pugalisk_fountain"] or HookPrefab("pugalisk_fountain")
            if not inst then return DataDumper({ not_found = true }) end
            local time = inst and inst.resettaskinfo and inst:TimeRemainingInTask(inst.resettaskinfo)
            return DataDumper({ time = time })
        ]]
        BBGOAT_util:remote(cmd, nil, function(res)
            if res and res.err then
                SaveTimeData("pugalisk_fountain", 0)
                print('[警告] pugalisk_fountain remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("pugalisk_fountain", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
    image = {
        atlas = "images/lifeplant.xml",
        tex = "lifeplant.tex",
        scale = 0.8,
    },
    anim = {
        scale = 0.02,
        bank = "fountain",
        build = "python_fountain",
        animation = "flow_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = 0,
        }
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.pugalisk_fountain_time
        if time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.pugalisk_fountain.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.pugalisk_fountain_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.pugalisk_fountain.tips)), 5, time, 1
        end
        return false
    end
}

return info