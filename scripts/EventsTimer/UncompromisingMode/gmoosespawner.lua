local info
info = {
    gettimefn = function(self)
        return GetWorldSettingsTimeLeft("mothergoose_timetoattack")
    end,
    gettextfn = function(self, time)
        local description
        local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
        if time and target and target.name then
            description = string.format(STRINGS.eventtimer.gmoosespawner.targeted, target.name, TimeToString(time))
        elseif time then
            description = string.format(ReplacePrefabName(STRINGS.eventtimer.gmoosespawner.cooldown), TimeToString(time))
        end

        return description
    end,
    image = {
        atlas = "images/Moose.xml",
        tex = "Moose.tex",
        scale = 0.2,
        offset = {
            x = 0,
            y = 15,
        }
    },
    anim = {
        scale = 0.044,
        bank = "goosemoose",
        build = "goosemoose_build",
        animation = "idle",
        loop = true,
    },
    announcefn = function(context)
        local time = context.time
        local text = context.text
        local desc
        local target, _ = Extract_by_format(text, STRINGS.eventtimer.gmoosespawner.targeted)
        if target and time > 0 then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.gmoosespawner.target), target, TimeToString(time))
        elseif time > 0 then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.gmoosespawner.cooldown), TimeToString(time))
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
            local desc = ReplacePrefabName(STRINGS.eventtimer.gmoosespawner.attack)
            desc = MarkData(desc, context)
            return true, StringToFunction(desc), 10, time, 3
        end
        return false
    end
}

return info