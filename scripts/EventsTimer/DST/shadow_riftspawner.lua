-- 暗影裂隙生成倒计时（为了跨世界同步数据修改了事件名。原事件名 riftspawner）

local allow_worlds = {
    cave = true,
    volcano = true,
}

local info
info = {
    gettimefn = function() -- 当裂隙出现时，不显示
        if allow_worlds[GetWorldtypeStr()] and
            EventTimer.EventTimerData and
            EventTimer.EventTimerData.shadowrift_portal and
            EventTimer.EventTimerData.shadowrift_portal[EventTimer.CurrentShardId].text == ""
        then
            return GetWorldSettingsTimeLeft("rift_spawn_timer")()
        end
    end,
    image = {
        atlas = "minimap/minimap_data.xml",
        tex = "shadowrift_portal.png",
        scale = 0.8,
        offset = {
            x = 0,
            y = 13,
        },
    },
    -- anim = {
    --     scale = 0.05,
    --     build = "shadowrift_portal",
    --     bank = "shadowrift_portal",
    --     animation = "scrapbook",
    -- },
    announcefn = function(context)
        local time = context.time
        local desc = string.format(STRINGS.eventtimer.riftspawner.shadow_cooldown, TimeToString(time))
        if context.shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
        end
        return desc
    end,
}

return info