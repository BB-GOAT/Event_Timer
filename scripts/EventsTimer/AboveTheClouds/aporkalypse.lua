-- 大灾变倒计时/大灾变期间的事件计时/蝙蝠袭击倒计时

local Next_Aporkalypse_Time
local flag = false

local aporkalypse, aporkalypse_attack, batted

-- 大灾变倒计时
aporkalypse = {
    postinitfn = function()
        AddComponentPostInit("aporkalypse", function(self)
            local _timeuntilaporkalypse = Upvaluehelper.GetUpvalue(self.OnUpdate, "_timeuntilaporkalypse")
            self.inst:DoPeriodicTask(0.5, function()
                if _timeuntilaporkalypse then
                    Next_Aporkalypse_Time = _timeuntilaporkalypse:value()
                    SaveTimeData("aporkalypse", Next_Aporkalypse_Time)
                    SaveTextData("aporkalypse", Next_Aporkalypse_Time and Next_Aporkalypse_Time > 0 and string.format(STRINGS.eventtimer.aporkalypse.cooldown, TimeToString(Next_Aporkalypse_Time)) or "")

                    -- 状态变化，刷新相关事件计时
                    if Next_Aporkalypse_Time == 0 and not flag then
                        flag = true
                        self.inst:DoTaskInTime(1, function()
                            batted.remotegettextfn()
                            aporkalypse_attack.remotegettextfn()
                        end)
                    elseif flag then
                        flag = false
                        self.inst:DoTaskInTime(1, function()
                            batted.remotegettextfn()
                            aporkalypse_attack.remotegettextfn()
                        end)
                    end
                end
            end)
        end)
    end,
    image = {
        atlas = "images/Aporkalypse_Clock.xml",
        tex = "Aporkalypse_Clock.tex",
        scale = 0.2
    },
    DisableClientPrediction = true,
    DisableSaveTime = true,
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.aporkalypse_time
        if time > 0 then
            return string.format(STRINGS.eventtimer.aporkalypse.cooldown, TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.aporkalypse_time

        if (JustEntered(time) and time < 2400) then
            return true, string.format(STRINGS.eventtimer.aporkalypse.cooldown, TimeToString(time)), 10, nil, 1
        elseif time == 480 then
            return true, string.format(STRINGS.eventtimer.aporkalypse.tips, TimeToString(time)), 10, nil, 2
        elseif time == 0 then -- 这个写法比较特殊..为了保证大灾变确实开始了
            return true, not (GetTime() < 10) and StringToFunction(STRINGS.eventtimer.aporkalypse.tips_ready), 5, 1, 3 -- 延迟1秒是因为大灾变在1秒后才真正开始
        end
        return false
    end
}

-- 大灾变中的事件倒计时（蝙蝠袭击、远古先驱袭击）
aporkalypse_attack = {
    remotegettextfn = function(Thread)
        local cmd = [[
            local self = TheWorld.net.components.aporkalypse
            if not self then return DataDumper({ not_found = true }) end
            local next_bat_attack = BBGOAT_FN.getval(self.OnUpdate, "_bat_time")
            local next_herald_attack = BBGOAT_FN.getval(self.OnUpdate, "_herald_time")
            return DataDumper({ next_bat_attack = next_bat_attack, next_herald_attack = next_herald_attack })
        ]]
        BBGOAT_util:remote(cmd, nil, function(res)
            if res and res.err then
                SaveTimeData("aporkalypse_attack", 0)
                SaveTextData("aporkalypse_attack", "")
                print('[警告] aporkalypse_attack remotegettextfn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res then
                local next_bat_attack = res.next_bat_attack -- 蝙蝠袭击倒计时
                local next_herald_attack = res.next_herald_attack -- 远古先驱袭击倒计时
                SaveTimeData("aporkalypse_attack", next_herald_attack or 0)
                if next_bat_attack and next_herald_attack then
                    SaveTextData("aporkalypse_attack", string.format(ReplacePrefabName(STRINGS.eventtimer.aporkalypse.attack), TimeToString(next_bat_attack), TimeToString(next_herald_attack)))
                else
                    SaveTextData("aporkalypse_attack", "")
                end
            end
        end)
    end,
    DisableSaveTime = true,
    image = {
        atlas = "images/Ancient_Herald.xml",
        tex = "Ancient_Herald.tex",
        scale = 0.2,
        offset = {
            x = 0,
            y = 7,
        }
    },
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.aporkalypse_attack_text
        local next_bat_attack, next_herald_attack = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.aporkalypse.attack))
        if not (next_bat_attack and next_herald_attack) then return end
        return string.format(ReplacePrefabName(STRINGS.eventtimer.aporkalypse.announce_attack), next_bat_attack, next_herald_attack)
    end,
    tipsfn = nil, -- 几分钟就来一次，一直Tips不嫌烦么？
}

-- 蝙蝠袭击
local _bat_attack_time, _bat_regen_time
batted = {
    remotegettextfn = function(Thread)
        if Next_Aporkalypse_Time == 0 then
            SaveTimeData("batted", 0)
            SaveTextData("batted", "")
            return
        end
        local cmd = [[
            local self = TheWorld.components.batted
            if not self then return DataDumper({ not_found = true }) end
            local _bat_attack_time = BBGOAT_FN.getval(self.LongUpdate, "_bat_attack_time")
            local bat_count = self:GetNumBats()
            local _bat_regen_time = BBGOAT_FN.getval(self.LongUpdate, "_bat_regen_time")
            return DataDumper({ _bat_attack_time = _bat_attack_time, bat_count = bat_count, _bat_regen_time = _bat_regen_time })
        ]]
        BBGOAT_util:remote(cmd, nil, function(res)
            if res and res.err then
                SaveTimeData("batted", 0)
                SaveTextData("batted", "")
                print('[警告] batted remotegettextfn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res then
                local bat_count = res.bat_count
                _bat_attack_time = res._bat_attack_time
                _bat_regen_time = res._bat_regen_time
                SaveTimeData("batted", _bat_attack_time or 0)
                if _bat_attack_time and bat_count and _bat_regen_time then
                    SaveTextData("batted", string.format(STRINGS.eventtimer.batted.cooldowntext, TimeToString(_bat_attack_time), bat_count, TimeToString(_bat_regen_time)))
                else
                    SaveTextData("batted", "")
                end
            end
        end)
    end,
    remotegettextfninterval = function()
        return math.min(_bat_attack_time, _bat_regen_time) + 1
    end,
    anim = {
        scale = 0.08,
        build = "bat_vamp_build",
        bank = "bat_vamp",
        animation = "fly_loop",
        loop = true,
        uioffset = {
            x = 10,
            y = -15,
        },
        offset = {
            x = 0,
            y = -15,
        }
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.batted_time
        if time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.batted.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.batted_time
        if time > 2 and time <= 90 then
            return true, batted.announcefn, time, nil, 2
        elseif JustEntered(time) and time < 960 then
            return true, batted.announcefn, 10, nil, 2
        elseif JustEntered(time) then
            return true, batted.announcefn, 10, nil, 1
        elseif ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.batted.attack)), 10, time, 3
        end
        return false
    end
}

return aporkalypse, aporkalypse_attack, batted