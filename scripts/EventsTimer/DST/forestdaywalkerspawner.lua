local remotegettimefn = function(Thread)
    if not (TheWorld:HasTag("forest") or TheWorld:HasTag("island")) then
        if Thread then KillThreadsWithID(Thread.id) end
        return
    end

    local cmd = [[
        local self = TheWorld.components.forestdaywalkerspawner
        if not self then
            return DataDumper({
                not_found = true
            })
        end
        local shard_daywalkerspawner = TheWorld.shard.components.shard_daywalkerspawner
        if shard_daywalkerspawner ~= nil and shard_daywalkerspawner:GetLocationName() ~= "forestjunkpile" or self.daywalker ~= nil or self.bigjunk ~= nil or not self.days_to_spawn then
            return
        end
        return DataDumper({days_to_spawn = self.days_to_spawn})
    ]]
    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.err then
            -- SaveTimeData("forestdaywalkerspawner", 0) -- 也许还有本地数据
            print('[警告] forestdaywalkerspawner remotegettimefn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res and res.days_to_spawn then
            local days_to_spawn = res.days_to_spawn
            local time = (days_to_spawn + 1) * TUNING.TOTAL_DAY_TIME - CalcTimeOfDay()
            SaveTimeData("forestdaywalkerspawner", time)
        elseif res and res.not_found then
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
        end
    end)
end

----------------------------------------------------------------------------------------------

local bigjunk, daywalker -- 拾荒疯猪是否已就位，拾荒疯猪是否正在出没
local remotegettextfn = function(Thread)
    if not (TheWorld:HasTag("forest") or TheWorld:HasTag("island")) then
        if Thread then KillThreadsWithID(Thread.id) end
        return
    end
    if ThePlayer.HUD.WarningEventTimeData.forestdaywalkerspawner_time > 0 then return end

    local cmd = [[
        local self = TheWorld.components.forestdaywalkerspawner
        if not self then
            return DataDumper({
                not_found = true
            })
        end
        return DataDumper({bigjunk = self.bigjunk ~= nil, daywalker = self.daywalker ~= nil})
    ]]

    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.err then
            SaveTextData("forestdaywalkerspawner", "")
            print('[警告] forestdaywalkerspawner remotegettextfn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res and res.not_found then
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res then
            bigjunk = res.bigjunk
            daywalker = res.daywalker
            if bigjunk then
                local str = ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.ready)
                SaveTextData("forestdaywalkerspawner", str)
            elseif daywalker then
                local str = ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.exists)
                SaveTextData("forestdaywalkerspawner", str)
            else
                SaveTextData("forestdaywalkerspawner", "")
            end
        end
    end)
end

----------------------------------------------------------------------------------------------

-- 纯本地获取方式 / 打死拾荒疯猪后删除拾荒疯猪信息
AddPrefabPostInit("daywalker2", function(boss)
    boss:DoTaskInTime(0.2, function(inst)
        SaveTimeData("daywalkerspawner", 0)
        SaveTimeData("forestdaywalkerspawner", 0)
        if EventTimer.GetTimeFromRemoteCommand then
            SaveTextData("forestdaywalkerspawner", ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.exists)) -- 使用远程命令时，挖出疯猪时将状态改为正在出没(纯本地模式时不支持text)
        end
        if inst and inst.components and inst.components.talker and inst.components.talker.Say then
            local _Say = inst.components.talker.Say
            inst.components.talker.Say = function(self, str_say, ...)
                for _, str in pairs(STRINGS.DAYWALKER_POWERDOWN or {}) do
                    if str == str_say then
                        -- 删除拾荒疯猪信息
                        SaveTextData("forestdaywalkerspawner", "")
                        -- 启动梦魇疯猪计时
                        SaveTimeData("daywalkerspawner", (TUNING.DAYWALKER_RESPAWN_DAYS_COUNT + 1) * TUNING.TOTAL_DAY_TIME - TheWorld.state.time*TUNING.TOTAL_DAY_TIME)
                        break
                    end
                end
                return _Say(self, str_say, ...)
            end
        end
    end)
end)

----------------------------------------------------------------------------------------------

-- 拾荒疯猪
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
        overridebuild = { "daywalker_phase3" },
        uioffset = {
            x = -2,
            y = -7
        },
        loop = true,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.forestdaywalkerspawner_time
        local text = ThePlayer.HUD.WarningEventTimeData.forestdaywalkerspawner_text
        if time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.cooldown), TimeToString(time))
        elseif (bigjunk or daywalker) then
            return text
        end
    end,
    tipsfn = function()
        if EventTimer.GetTimeFromServerMod["forestdaywalkerspawner"] or not EventTimer.GetTimeFromRemoteCommand then
            local time = ThePlayer.HUD.WarningEventTimeData.forestdaywalkerspawner_time
            if ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.tips)), 10, time, 2
            end
        else
            if (bigjunk or daywalker) then
                return true, not (GetTime() < 45) and StringToFunction(ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.tips)), 10, nil, 2
            end
            return false
        end
    end
}

return info