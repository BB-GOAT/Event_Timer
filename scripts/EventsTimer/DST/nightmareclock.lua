local STATES = {
    none = "calm_loop", -- 默认
    calm = "calm_loop", -- 平静
    warn = "warn_loop", -- 警告
    wild = "wild_loop", -- 暴动
    dawn = "dawn_loop", -- 黎明
    lock = "wild_lock", -- 锁定暴动阶段
}

local sync_task
local function NightmareWildAnimChange(context)
    local text = context.text
    if text and string.find(text, STRINGS.eventtimer.nightmareclock.phase_locked_text) then
        ChangeAnimOrImage("nightmareclock", context.shard_id, "anim", "animation", STATES.wild) -- 暴动锁定(因为计时器面板UI里的Anim是不会播放动画的，所以改用静态动画)
    else
        ChangeAnimOrImage("nightmareclock", context.shard_id, "anim", "animation", STATES[TheWorld.state.nightmarephase])
    end
    sync_task = nil
end

local CreateSyncAnimTask = function(context)
    local time = context.time
    if not sync_task then
        if not checknumber(time) or not TheWorld then return end -- 事情为什么会变成这样呢
        sync_task = TheWorld:DoTaskInTime(time, function()
            NightmareWildAnimChange(context)
        end)
    end
end

local info
info = {
    gettimefn = function(self) -- 仅返回倒计时
        local data = self:OnSave()
        local locked = data.lockedphase
        local remainingtimeinphase = data.remainingtimeinphase

        if locked then return end

        return remainingtimeinphase
    end,
    gettextfn = function(self, time) -- 仅锁定阶段返回
        local data = self:OnSave()
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
    end,
    tipsfn = function(context) -- 邪修用法？？？
        CreateSyncAnimTask(context) -- 为了context
        return false
    end
}

return info