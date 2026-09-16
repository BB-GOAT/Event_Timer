local info
info = {
    gettimefn = function(self)
        return self.spawn_timer
    end,
    gettextfn = function(self, time)
        return time and time > 0 and string.format(ReplacePrefabName(STRINGS.eventtimer.chessnavy.cooldown), TimeToString(time)) or STRINGS.eventtimer.chessnavy.readytext
    end,
    anim = {
        scale = 0.09,
        bank = "knightboat",
        build = "knightboat_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 7,
            y = -2,
        },
    },
    announcefn = function(context)
        local time = context.time
        local desc
        if time > 0 then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.chessnavy.cooldown), TimeToString(time))
        else
            desc = ReplacePrefabName(STRINGS.eventtimer.chessnavy.ready)
        end
        desc = MarkData(desc, context)
        return desc
    end
}

return info