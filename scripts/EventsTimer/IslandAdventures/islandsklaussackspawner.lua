local remotegettimefn = function(Thread)
    GetWorldSettingsTimeLeft("klaussack_tropical_spawntimer", nil, function(res)
        if res and res.err then
            SaveTimeData("islandsklaussackspawner", 0)
            print('[警告] islandsklaussackspawner remotegettimefn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res and res.time then
            SaveTimeData("islandsklaussackspawner", res.time)
        elseif res and res.not_found then
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
        end
    end)
end

----------------------------------------------------------------------------------------------

local despawnday
local remotegettextfn = function(Thread)
    if ThePlayer.HUD.WarningEventTimeData.islandsklaussackspawner_time > 0 then return end -- 赃物袋在生成倒计时，不存在消失时间

    local cmd = [[
        local self = TheWorld.components.islandsklaussackspawner
        if not self then return DataDumper({ not_found = true }) end

        local function sack_can_despawn(inst)
            if not IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) and
                inst.components.entitytracker:GetEntity("klaus") == nil and
                inst.components.entitytracker:GetEntity("key") == nil then
                return true
            end
            return false
        end

        local sack = BBGOAT_FN.getval(self.GetDebugString, "_sack")
        if sack and sack:IsValid() and sack.despawnday and sack_can_despawn(sack) then
            return DataDumper({ despawnday = sack.despawnday })
        else
            return DataDumper({ despawnday = nil })
        end
    ]]

    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.err then
            SaveTextData("islandsklaussackspawner", "")
            print('[警告] islandsklaussackspawner remotegettextfn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res and res.not_found then
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res then
            despawnday = res.despawnday
            if despawnday then
                local str = string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.despawntext), despawnday)
                SaveTextData("islandsklaussackspawner", str)
            else
                -- 没有消失数据，只能显示个刷新倒计时，那清空文本也是一样的效果
                SaveTextData("islandsklaussackspawner", "")
            end
        end
    end)
end

----------------------------------------------------------------------------------------------

-- 纯本地获取方式 / 开袋后刷新一遍数据
if not EventTimer.GetTimeFromServerMod["islandsklaussackspawner"] then
    AddPrefabPostInit("klaus_sack", function(inst)
        if not (TheWorld:HasTag("island") or TheWorld:HasTag("volcano")) then return end
        inst:ListenForEvent("onremove", function(inst)
            local pos = inst:GetPosition()
            local bundle = TheSim:FindEntities(pos.x, 0, pos.z, 4, {"bundle"}, { 'FX', 'DECOR', 'INLIMBO', 'NOCLICK', 'player' })
            if #bundle > 0 then
                if IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) then
                    if EventTimer.GetTimeFromRemoteCommand then
                        -- 从远程指令刷新时间
                        remotegettimefn()
                        SaveTextData("islandsklaussackspawner", "")
                    else
                        -- 纯本地
                        SaveTimeData("islandsklaussackspawner", TUNING.KLAUSSACK_EVENT_RESPAWN_TIME)
                    end
                end
            end
        end)
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    remotegettimefn = remotegettimefn,
    remotegettextfn = not IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) and remotegettextfn, -- 没开冬季盛宴活动的情况下，天亮的时候触发一次
    remotegettextfninterval = function() -- 直接返回CalcTimeOfDay的话会因未初始化而变为nil
        return CalcTimeOfDay()
    end,
    ForceEnableRemotegettextfn = true, -- 第三方模组并不能给赃物袋消失时间
    DisableClientPredictionClearText = true,
    anim = {
        scale = 0.1,
        bank = "klaus_bag",
        build = "klaus_bag_tropical",
        animation = "idle",
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.islandsklaussackspawner_time
        local text = ThePlayer.HUD.WarningEventTimeData.islandsklaussackspawner_text
        local despawnday = Extract_by_format(text, STRINGS.eventtimer.islandsklaussackspawner.despawntext)
        if despawnday then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.islandsklaussackspawner.despawn), despawnday)
        elseif time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.islandsklaussackspawner.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.islandsklaussackspawner_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.islandsklaussackspawner.tips)), 10, time, 2
        end
        return false
    end
}

return info