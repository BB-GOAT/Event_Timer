local info
info = {
    gettimefn = function(self)
        return GetWorldSettingsTimeLeft("regen_crabking", self)
    end,
    anim = {
        scale = 0.022,
        bank = "king_crab",
        build = "crab_king_build",
        animation = "inert",
        loop = true,
    },
    announcefn = function(context)
        local time = context.time
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.crabkingspawner.cooldown), TimeToString(time))
        desc = MarkData(desc, context)
        return desc
    end
}

return info