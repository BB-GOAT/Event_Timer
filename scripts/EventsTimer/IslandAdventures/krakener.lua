local info
info = {
    gettimefn = function(self)
        if self.kraken or (self.spawn_chance_mod or 1) <= 0 then return end
        return self.TimeUntilCanSpawn and self:TimeUntilCanSpawn()
    end,
    gettextfn = function(self, time)
        if self.kraken then
            return STRINGS.eventtimer.krakener.exists
        elseif (self.spawn_chance_mod or 1) <= 0 then
            return
        elseif time and time > 0 then
            return string.format(STRINGS.eventtimer.krakener.cooldown, TimeToString(time))
        elseif self.CanSpawn and self:CanSpawn() then
            return STRINGS.eventtimer.krakener.ready
        end
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
        local exists = ReplacePrefabName(STRINGS.eventtimer.krakener.exists)
        local ready = ReplacePrefabName(STRINGS.eventtimer.krakener.ready)
        if string.find(context.text, exists, 1, true) then
            desc = exists
        elseif time > 0 then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.krakener.cooldown), TimeToString(time))
        elseif string.find(context.text, ready, 1, true) then
            desc = ready
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