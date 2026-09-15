local STATES = {
    none = "calm_loop", -- 默认
    calm = "calm_loop", -- 平静
    warn = "warn_loop", -- 警告
    wild = "wild_loop", -- 暴动
    dawn = "dawn_loop", -- 黎明
    lock = "wild_lock", -- 锁定暴动阶段
}

local function NightmareWildAnimChange()
    local fn = function(self, context)
        local text = context.text
        if text and string.find(text, STRINGS.eventtimer.nightmareclock.phase_locked_text) then
            self.anim.animation = STATES.wild -- 暴动锁定(因为计时器面板UI里的Anim是不会播放动画的，所以改用静态动画)
        else
            self.anim.animation = STATES[TheWorld.state.nightmarephase]
        end
    end
    return 1, fn
end

local info
info = {
    gettimefn = function() -- 仅返回倒计时
        local nightmareclock = TheWorld.net.components.nightmareclock
        if not nightmareclock then
            return
        end

        local data = nightmareclock:OnSave()
        local locked = data.lockedphase
        local remainingtimeinphase = data.remainingtimeinphase

        if locked then return end

        return remainingtimeinphase
    end,
    gettextfn = function() -- 仅锁定阶段返回
        local nightmareclock = TheWorld.net.components.nightmareclock
        if not nightmareclock then
            return
        end

        local data = nightmareclock:OnSave()
        return data.lockedphase and STRINGS.eventtimer.nightmareclock.phase_locked_text
    end,
    anim = {
        scale = 0.5,
        bank = "nigthmarephaseindicator_eventtimer_server",
        build = "nigthmarephaseindicator_eventtimer_server",
        animation = "calm_loop",
        offset = {
            x = 0,
            y = 15,
        },
        uioffset = {
            x = 0,
            y = 15,
        },
    },
    animchangetaskfn = NightmareWildAnimChange,
    DisableShardRPC = true,
    announcefn = function(context)
        local time = context.time
        local text = context.text
        if string.find(text, STRINGS.eventtimer.nightmareclock.phase_locked_text) then
            return STRINGS.eventtimer.nightmareclock.phase_locked
        end
        if TheWorld.state.nightmarephase == "none" then
            return time and string.format(STRINGS.eventtimer.nightmareclock.cooldown_none, TimeToString(time))
        else
            local phase = STRINGS.eventtimer.nightmareclock.phases[TheWorld.state.nightmarephase]
            return time and phase and string.format(STRINGS.eventtimer.nightmareclock.cooldown, phase, TimeToString(time))
        end
    end
}

return info