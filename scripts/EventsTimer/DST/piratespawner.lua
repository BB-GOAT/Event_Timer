local info
info = {
    anim = {
        scale = 0.12,
        build = "monkey_small",
        bank = "monkey_small",
        animation = "row_loop",
        loop = true,
        uioffset = {
            x = -2,
            y = -7,
        }
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.piratespawner_time
        return string.format(STRINGS.eventtimer.piratespawner.cooldown, TimeToString(time))
    end,
    tipsfn = nil -- 开始袭击的时候对应的玩家会说台词，不需要我来提醒
}

return info