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
        if context.shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
        end
        return desc
    end,
    tipsfn = function(context)
        local time = context.time
        if ready_attack(time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.pugalisk_fountain.tips)
            if context.shard_id ~= EventTimer.CurrentShardId then
                desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
            end
            return true, StringToFunction(desc), 5, time, 1
        end
        return false
    end
}

return info