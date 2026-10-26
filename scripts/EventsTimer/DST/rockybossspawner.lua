local info = {
    remotegettimefn = function(Thread)
        if not TheWorld:HasTag("cave") then
            if Thread then KillThreadsWithID(Thread.id) end
            return
        end
        local cmd = [[
            local self = TheWorld.components.rockybossspawner
            local timer = TheWorld.components.worldsettingstimer
            if not (self and self.GetRockyBoss and timer) then
                return DataDumper({ not_found = true })
            end
            local time = 0
            if self:GetRockyBoss() == nil and not timer:IsPaused("rockyboss_timetospawn") then
                time = timer:GetTimeLeft("rockyboss_timetospawn") or 0
            end
            return DataDumper({ time = time })
        ]]
        BBGOAT_util:remote(cmd, nil, function(res)
            if not res then return end
            if res.err or res.not_found then
                SaveTimeData("rockybossspawner", 0)
                if res.err then
                    print('[警告] rockybossspawner remotegettimefn error:', res.err)
                end
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res.time then
                SaveTimeData("rockybossspawner", math.max(0, res.time))
            end
        end)
    end,
    anim = {
        bank = "rocky",
        build = "rocky_boss",
        animation = "idle_loop",
        loop = true,
        scale = 0.08,
        uioffset = { x = 0, y = -7 },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.rockybossspawner_time
        if time and time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.rockybossspawner.cooldown), TimeToString(time))
        end
    end,
}

return info
