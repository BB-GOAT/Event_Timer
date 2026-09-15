local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("regen_dragonfly", "dragonfly_spawner"),
    animchangefn = ChangeanimByWintersFeast,
    defaultanim = {
        scale = 0.044,
        bank = "dragonfly",
        build = "dragonfly_build",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 0,
            y = -4,
        },
    },

    winterfeastanim = {
        scale = 0.044,
        bank = "dragonfly",
        build = "dragonfly_yule_build",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 0,
            y = -4,
        },
    },
    announcefn = function(context)
        local time = context.time
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.dragonfly_spawner.cooldown), TimeToString(time))
        desc = MarkData(desc, context)
        return desc
    end,
    tipsfn = function(context)
        if ready_attack(context.time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.dragonfly_spawner.tips)
            desc = MarkData(desc, context)
            return true, StringToFunction(desc), 10, context.time, 2
        end
        return false
    end,
}

return info