local remotegettimefn = function()
    if not (TheWorld:HasTag("cave") or TheWorld:HasTag("volcano")) then return end

    local cmd = [[
        local self = TheWorld.components.daywalkerspawner
        if not self then return end
        local shard_daywalkerspawner = TheWorld.shard.components.shard_daywalkerspawner
        if shard_daywalkerspawner ~= nil and shard_daywalkerspawner:GetLocationName() ~= "cavejail" or self.daywalker ~= nil or not self.days_to_spawn then
            return
        end
        return DataDumper({days_to_spawn = self.days_to_spawn})
    ]]
    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.err then
            print('[警告] daywalkerspawner remotegettimefn error:', res.err)
        elseif res and res.days_to_spawn then
            local days_to_spawn = res.days_to_spawn
            local time = (days_to_spawn + 1) * TUNING.TOTAL_DAY_TIME - CalcTimeOfDay()
            SaveTimeData("daywalkerspawner", time)
        end
    end)
end

----------------------------------------------------------------------------------------------

local daywalker -- 梦魇疯猪是否已生成
local remotegettextfn = function()
    if not (TheWorld:HasTag("cave") or TheWorld:HasTag("volcano")) then return end
    if ThePlayer.HUD.WarningEventTimeData.daywalkerspawner_time > 0 then return end

    local cmd = [[
        local self = TheWorld.components.daywalkerspawner
        if not self then return end
        return DataDumper({daywalker = self.daywalker})
    ]]

    BBGOAT_util:remote(cmd, nil, function(res)
        if res.err then
            print('[警告] daywalkerspawner remotegettextfn error:', res.err)
        elseif res then
            daywalker = res.daywalker
            if daywalker then
                local str = ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner.ready)
                SaveTextData("daywalkerspawner", str)
            else
                SaveTextData("daywalkerspawner", "")
            end
        end
    end)
end

----------------------------------------------------------------------------------------------

-- 纯本地获取方式 / 打死梦魇疯猪后删除梦魇疯猪信息
AddPrefabPostInit("daywalker", function(boss)
    boss:DoTaskInTime(0.2, function(inst)
        SaveTimeData("daywalkerspawner", 0)
        SaveTimeData("forestdaywalkerspawner", 0)
        if EventTimer.GetTimeFromRemoteCommand then
            SaveTextData("daywalkerspawner", ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner.ready)) -- 使用远程命令时，挖出疯猪时将状态改为正在出没(纯本地模式时不支持text)
        end
        if inst and inst.components and inst.components.talker and inst.components.talker.Say then
            local _Say = inst.components.talker.Say
            inst.components.talker.Say = function(self, str_say, ...)
                for _, str in pairs(STRINGS.DAYWALKER_POWERDOWN or {}) do
                    if str == str_say then
                        -- 删除梦魇疯猪信息
                        SaveTextData("daywalkerspawner", "")
                        -- 启动拾荒疯猪计时
                        SaveTimeData("forestdaywalkerspawner", (TUNING.DAYWALKER_RESPAWN_DAYS_COUNT + 1) * TUNING.TOTAL_DAY_TIME - TheWorld.state.time*TUNING.TOTAL_DAY_TIME)
                        break
                    end
                end
                return _Say(self, str_say, ...)
            end
        end
    end)
end)

----------------------------------------------------------------------------------------------

-- 梦魇疯猪
local info
info = {
    remotegettimefn = remotegettimefn,
    remotegettextfn = remotegettextfn,
    remotegettimefninterval = function() -- 直接返回CalcTimeOfDay的话会因未初始化而变为nil
        return CalcTimeOfDay()
    end,
    remotegettextfninterval = function() -- 直接返回CalcTimeOfDay的话会因未初始化而变为nil
        return CalcTimeOfDay()
    end,
    DisableClientPredictionClearText = true,
    anim = {
        scale = 0.05,
        build = "daywalker_build",
        bank = "daywalker",
        animation = "idle_creepy_loop",
        uioffset = {
            x = -2,
            y = -7
        },
        loop = true,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.daywalkerspawner_time
        local text = ThePlayer.HUD.WarningEventTimeData.daywalkerspawner_text
        if time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner.cooldown), TimeToString(time))
        elseif daywalker then
            return text
        end
    end,
    tipsfn = function()
        if not (EventTimer.GetTimeFromRemoteCommand or EventTimer.GetTimeFromServerMod) then
            local time = ThePlayer.HUD.WarningEventTimeData.daywalkerspawner_time
            if ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner.tips)), 10, time, 2
            end
        else
            if daywalker then
                return true, not (GetTime() < 10) and StringToFunction(ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner.tips)), 10, nil, 2
            end
            return false
        end
    end
}

return info