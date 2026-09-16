local info
info = {
    gettimefn = function(self)
        return GetWorldSettingsTimeLeft("malbatross_timetospawn")
    end,
    anim = {
        scale = 0.035,
        bank = "malbatross",
        build = "malbatross_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 5,
            y = -10,
        },
    },
    announcefn = function(context)
        local time = context.time
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.malbatrossspawner.cooldown), TimeToString(time))
        desc = MarkData(desc, context)
        return desc
    end
}

return info