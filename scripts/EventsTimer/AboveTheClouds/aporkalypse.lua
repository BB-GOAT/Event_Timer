-- 大灾变倒计时/大灾变期间的事件计时/蝙蝠袭击倒计时

local Next_Aporkalypse_Time
local aporkalypse, aporkalypse_attack, batted

local sync_task
local CreateSyncAnimTask = function(time, key)
    if not sync_task then
        if not checknumber(time) or not TheWorld then return end -- 事情为什么会变成这样呢
        sync_task = TheWorld:DoTaskInTime(time, function()
            SendModRPCToClient("EventTimer", "change_anim_or_image", "aporkalypse", EventTimer.CurrentShardId, "image", key)
        end)
    end
end

-- 大灾变倒计时
aporkalypse = {
    postinitfn = function()
        if not TheNet:GetIsServer() then return end
        AddPrefabPostInit("world", function(inst)
            if inst:HasTag("porkland") then
                inst:ListenForEvent("aporkalypseclocktick", function(src, data)
                    Next_Aporkalypse_Time = data and data.timeuntilaporkalypse
                end)
            end
        end)
    end,
    gettimefn = function(self)
        if Next_Aporkalypse_Time == 0 then
            local next_herald_attack = Upvaluehelper.GetUpvalue(self.OnUpdate, "_herald_time") -- 远古先驱袭击倒计时
            CreateSyncAnimTask(next_herald_attack, "Ancient_Herald_image")
            return next_herald_attack
        else
            CreateSyncAnimTask(Next_Aporkalypse_Time, "Aporkalypse_Clock_image")
            return Next_Aporkalypse_Time
        end
    end,
    gettextfn = function(self, next_herald_attack)
        if not Next_Aporkalypse_Time or Next_Aporkalypse_Time > 0 then return end
        local next_bat_attack = Upvaluehelper.GetUpvalue(self.OnUpdate, "_bat_time") -- 蝙蝠袭击倒计时
        if not (next_bat_attack and next_herald_attack) then return end
        return string.format(ReplacePrefabName(STRINGS.eventtimer.aporkalypse.attack), TimeToString(next_bat_attack), TimeToString(next_herald_attack))
    end,
    imagechangefn = function(self, context)
        if Extract_by_format(context.text, ReplacePrefabName(STRINGS.eventtimer.aporkalypse.attack)) then
            self.image = self.Ancient_Herald_image
        else
            self.image = self.Aporkalypse_Clock_image
        end
    end,
    Aporkalypse_Clock_image = {
        atlas = "images/Aporkalypse_Clock.xml",
        tex = "Aporkalypse_Clock.tex",
        scale = 0.2
    },
    Ancient_Herald_image = {
        atlas = "images/Ancient_Herald.xml",
        tex = "Ancient_Herald.tex",
        scale = 0.2,
        offset = {
            x = 0,
            y = 7,
        }
    },
    announcefn = function(context)
        local time = context.time
        local text = context.text
        local desc
        local next_bat_attack, next_herald_attack
        if text ~= "" then
            next_bat_attack, next_herald_attack = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.aporkalypse.attack))
        end
        if next_bat_attack and next_herald_attack then -- 大灾变袭击信息
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.aporkalypse.announce_attack), next_bat_attack, next_herald_attack)
        else -- 大灾变倒计时
            desc = string.format(STRINGS.eventtimer.aporkalypse.cooldown, TimeToString(time))
        end
        desc = MarkData(desc, context)
        return desc
    end,
    tipsfn = function(context)
        if Extract_by_format(context.text, ReplacePrefabName(STRINGS.eventtimer.aporkalypse.attack)) then return end -- 非大灾变倒计时，不运行

        local time = context.time
        if (JustEntered(time) and time < 2400) then
            local desc = string.format(STRINGS.eventtimer.aporkalypse.cooldown, TimeToString(time))
            desc = MarkData(desc, context)
            return true, StringToFunction(desc), 10, nil, 1
        elseif time == 480 then
            local desc = string.format(STRINGS.eventtimer.aporkalypse.tips, TimeToString(time))
            desc = MarkData(desc, context)
            return true, StringToFunction(desc), 10, nil, 2
        elseif time == 0 then -- 这个写法比较特殊..为了保证大灾变确实开始了
            local desc = STRINGS.eventtimer.aporkalypse.tips_ready
            desc = MarkData(desc, context)
            return true, (GetTime() > 10) and StringToFunction(desc), 5, 1, 3 -- 延迟1秒是因为大灾变在1秒后才真正开始
        end
        return false
    end
}

-- 蝙蝠袭击
batted = {
    gettimefn = function(self)
        if Next_Aporkalypse_Time and Next_Aporkalypse_Time > 0 then
            local next_attack_in = Upvaluehelper.GetUpvalue(self.LongUpdate, "_bat_attack_time")
            return next_attack_in
        else
            local self = TheWorld.net.components.aporkalypse
            if not self then return end
            local time = Upvaluehelper.GetUpvalue(self.OnUpdate, "_bat_time")
            return time
        end
    end,
    gettextfn = function(self, next_attack_in)
        if Next_Aporkalypse_Time and Next_Aporkalypse_Time > 0 then
            local bat_count = self:GetNumBats()
            local regen_in = Upvaluehelper.GetUpvalue(self.LongUpdate, "_bat_regen_time")
            if not (bat_count and regen_in and next_attack_in) then return end
            return string.format(STRINGS.eventtimer.batted.cooldowntext, TimeToString(next_attack_in), bat_count, TimeToString(regen_in))
        end
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
    -- DisableShardRPC = true,
    announcefn = function(context)
        local time = context.time
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.batted.cooldown), TimeToString(time))
        desc = MarkData(desc, context)
        return desc
    end,
    tipsfn = function(context)
        local time = context.time
        if time > 2 and time <= 90 then
            return true, batted.announcefn, time, nil, 2
        elseif JustEntered(time) and time < 960 then
            return true, batted.announcefn, 10, nil, 2
        elseif JustEntered(time) then
            return true, batted.announcefn, 10, nil, 1
        elseif ready_attack(time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.batted.attack)
            desc = MarkData(desc, context)
            return true, StringToFunction(desc), 10, time, 3
        end
        return false
    end
}

return aporkalypse, aporkalypse_attack, batted