local info
info = {
    gettimefn = function(self)
        return self.TimeUntilCanSpawn and self:TimeUntilCanSpawn()
    end,
    gettextfn = function(self, time)
        if time and time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.krakener.cooldown), TimeToString(time))
        end
        return ReplacePrefabName(STRINGS.eventtimer.krakener.ready)
    end,
    animchangefn = ChangeanimByWintersFeast,
    defaultanim = {
        scale = 0.025,
        bank = "quacken",
        build = "quacken",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -3,
        },
    },
    winterfeastanim = {
        scale = 0.025,
        bank = "quacken",
        build = "quacken_yule",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -3,
        },
    },
    announcefn = function(context)
        local time = context.time
        local desc
        if time > 0 then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.krakener.cooldown), TimeToString(time))
        else
            desc = ReplacePrefabName(STRINGS.eventtimer.krakener.ready)
        end
        desc = MarkData(desc, context)
        return desc
    end,
    tipsfn = function(context)
        local time = context.time
        if ready_attack(time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.krakener.tips)
            desc = MarkData(desc, context)
            return true, StringToFunction(desc), 10, time, 2
        end
        return false
    end
}

return info