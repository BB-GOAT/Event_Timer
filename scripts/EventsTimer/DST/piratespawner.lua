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
        local text = ThePlayer.HUD.WarningEventTimeData.piratespawner_text
        text = string.gsub(text, "\n", ", ")
        return text
    end,
    tipsfn = nil -- 开始袭击的时候对应的玩家会说台词，不需要我来提醒
}

return info