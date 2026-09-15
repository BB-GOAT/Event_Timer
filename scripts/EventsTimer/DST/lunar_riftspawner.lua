-- 月亮裂隙生成倒计时（为了跨世界同步数据修改了事件名。原事件名 riftspawner）

local allow_worlds = {
    forest = true,
    shipwrecked = true,
}

local info
info = {
    gettimefn = function() -- 当裂隙出现时，不显示
        if allow_worlds[GetWorldtypeStr()] and
            EventTimer.EventTimerData and
            EventTimer.EventTimerData.rift_portal and
            EventTimer.EventTimerData.rift_portal[EventTimer.CurrentShardId].text == ""
        then
            return GetWorldSettingsTimeLeft("rift_spawn_timer")()
        end
    end,
    image = {
        atlas = "minimap/minimap_data.xml",
        tex = "lunarrift_portal.png",
        scale = 0.8,
        offset = {
            x = 0,
            y = 13,
        },
    },
    anim = {
        scale = 0.05,
        build = "lunar_rift_portal",
        bank = "lunar_rift_portal",
        animation = "stage_3_loop",
        offset = {
            x = 0,
            y = -16,
        },
        loop = true,
    },
    announcefn = function(context)
        local time = context.time
        local desc = string.format(STRINGS.eventtimer.riftspawner.lunar_cooldown, TimeToString(time))
        desc = MarkData(desc, context)
        return desc
    end,
}

return info