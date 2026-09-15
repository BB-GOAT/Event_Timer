local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("rage", "antlion"),
    anim = {
        scale = 0.05,
        bank = "antlion",
        build = "antlion_build",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 0,
            y = -5,
        },
    },
    announcefn = function(context)
        local time = context.time
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.sinkholespawner.cooldown), TimeToString(time))
        desc = MarkData(desc, context)
        return desc
    end,
    tipsfn = function(context)
        local time = context.time
        if time > 2 and time < 60 then
            return true, info.announcefn, time, nil, 2
        elseif ready_attack(time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.sinkholespawner.attack)
            desc = MarkData(desc, context)
            return true, StringToFunction(desc), 10, time, 3
        end
        return false
    end
}

return info