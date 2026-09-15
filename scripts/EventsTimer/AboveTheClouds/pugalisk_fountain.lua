local info
info = {
    gettimefn = function()
        local self = TimerPrefabs["pugalisk_fountain"]
        return self and self.resettaskinfo and self:TimeRemainingInTask(self.resettaskinfo)
    end,
    image = {
        atlas = "images/lifeplant.xml",
        tex = "lifeplant.tex",
        scale = 0.8,
    },
    anim = {
        scale = 0.02,
        bank = "fountain",
        build = "python_fountain",
        animation = "flow_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = 0,
        }
    },
    announcefn = function(context)
        local time = context.time
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.pugalisk_fountain.cooldown), TimeToString(time))
        desc = MarkData(desc, context)
        return desc
    end,
    tipsfn = function(context)
        local time = context.time
        if ready_attack(time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.pugalisk_fountain.tips)
            desc = MarkData(desc, context)
            return true, StringToFunction(desc), 5, time, 1
        end
        return false
    end
}

return info