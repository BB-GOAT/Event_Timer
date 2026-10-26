local info = {
    remotegettimefn = function(Thread)
        if not TheWorld:HasTag("cave") then
            if Thread then KillThreadsWithID(Thread.id) end
            return
        end
        local cmd = [[
            local manager = TheWorld.components.acidbatwavemanager
            if not manager then return DataDumper({ not_found = true }) end
            local cave = manager.batbosscaves and next(manager.batbosscaves)
            local spawner = cave and cave:IsValid() and cave.components.childspawner
            local timer = spawner and cave.components.worldsettingstimer
            local time = 0
            if timer and spawner.childreninside == 0 and spawner.numchildrenoutside == 0
                and not timer:IsPaused("ChildSpawner_RegenPeriod") then
                time = timer:GetTimeLeft("ChildSpawner_RegenPeriod") or 0
            end
            return DataDumper({ time = time })
        ]]
        BBGOAT_util:remote(cmd, nil, function(res)
            if not res then return end
            if res.err or res.not_found then
                SaveTimeData("batbosscave", 0)
                if res.err then
                    print('[警告] batbosscave remotegettimefn error:', res.err)
                end
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res.time then
                SaveTimeData("batbosscave", res.time)
            end
        end)
    end,
    anim = {
        bank = "bat_boss",
        build = "bat_boss",
        animation = "fly_loop",
        loop = true,
        scale = 0.1,
        uioffset = { x = 5, y = -18 },
        offset = { x = 5, y = -18 },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.batbosscave_time
        if time and time > 0 then
            local text = string.format(STRINGS.eventtimer.batbosscave.cooldown, TimeToString(time))
            return string.format(ReplacePrefabName(STRINGS.eventtimer.batbosscave.announce), text)
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.batbosscave_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.batbosscave.tips)), 10, time, 1
        end
        return false
    end,
}

return info
