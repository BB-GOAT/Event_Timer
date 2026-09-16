local info
info = {
    gettimefn = function(self)
        return GetWorldSettingsTimeLeft("cooldown", self)
    end,
    anim = {
        scale = 0.2,
        bank = "terrarium",
        build = "terrarium",
        animation = "idle",
        uioffset = {
            x = 0,
            y = -4,
        },
    },
    announcefn = function(context)
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.terrarium.cooldown), TimeToString(context.time))
        desc = MarkData(desc, context)
        return desc
    end,
    tipsfn = function(context)
        local time = context.time
        if ready_attack(time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.terrarium.tips)
            desc = MarkData(desc, context)
            return true, StringToFunction(desc), 10, time, 2
        end
        return false
    end,
}

return info