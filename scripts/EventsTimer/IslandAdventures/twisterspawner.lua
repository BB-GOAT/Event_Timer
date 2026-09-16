local info
info = {
    gettimefn = function(self)
        return GetWorldSettingsTimeLeft("twister_timetoattack")
    end,
    gettextfn = function(self, time)
        local description
        local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
        if time and target and target.name then
            description = string.format(STRINGS.eventtimer.twisterspawner.targeted, target.name, TimeToString(time))
        elseif time then
            description = string.format(ReplacePrefabName(STRINGS.eventtimer.twisterspawner.cooldown), TimeToString(time))
        end
        return description
    end,
    image = {
        atlas = "images/Twister.xml",
        tex = "Twister.tex",
        scale = 0.35,
    },
    anim = {
        scale = 0.022,
        bank = "twister",
        build = "twister_build",
        animation = "idle_loop",
        loop = true
    },
    announcefn = function(context)
        local time = context.time
        local text = context.text
        local desc
        local target, _ = Extract_by_format(text, STRINGS.eventtimer.twisterspawner.targeted)
        if target and time > 0 then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.twisterspawner.target), target, TimeToString(time))
        elseif time > 0 then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.twisterspawner.cooldown), TimeToString(time))
        end
        desc = MarkData(desc, context)
        return desc
    end,
    tipsfn = function(context)
        local time = context.time
        if time > 2 and time < 60 then
            local tips_level_2 = context.shard_id == EventTimer.CurrentShardId
            return true, info.announcefn, time, nil, tips_level_2 and 2 or 1
        elseif time == 480 or JustEntered(time) then
            return true, info.announcefn, 10, nil, 2
        elseif ready_attack(time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.twisterspawner.attack)
            desc = MarkData(desc, context)
            return true, StringToFunction(desc), 10, time, 3
        end
        return false
    end
}

return info