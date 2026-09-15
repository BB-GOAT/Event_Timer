local info
info = {
    gettimefn = function()
        local self = TheWorld.components.tigersharker
        if not self then return end
        local appear_time = self:TimeUntilCanAppear()
        local respawn_time = self:TimeUntilRespawn()
        return math.max(appear_time, respawn_time)
    end,
    gettextfn = function(time)
        local self = TheWorld.components.tigersharker
        if not self then return end
        if self.shark then
            return ReplacePrefabName(STRINGS.eventtimer.tigersharker.exists)
        elseif self:CanSpawn(true, true) then
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.tigersharker.cooldown), TimeToString(time))
            else
                return STRINGS.eventtimer.tigersharker.readytext
            end
        end
        return ReplacePrefabName(STRINGS.eventtimer.tigersharker.nospawn)
    end,
    anim = {
        scale = 0.03,
        bank = "tigershark",
        build = "tigershark_ground_build",
        animation = "taunt",
        loop = true,
        uioffset = {
            x = -6,
            y = -6,
        },
    },
    announcefn = function(context)
        local time = context.time
        local text = context.text
        local exists = string.find(text, ReplacePrefabName(STRINGS.eventtimer.tigersharker.exists))
        local nospawn = string.find(text, ReplacePrefabName(STRINGS.eventtimer.tigersharker.nospawn))
        local desc
        if exists then
            desc = ReplacePrefabName(STRINGS.eventtimer.tigersharker.exists)
        elseif nospawn then
            desc = ReplacePrefabName(STRINGS.eventtimer.tigersharker.nospawn)
        elseif time > 0 then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.tigersharker.cooldown), TimeToString(time))
        else
            desc = ReplacePrefabName(STRINGS.eventtimer.tigersharker.ready)
        end
        if desc and context.shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
        end
        return desc
    end,
    tipsfn = function(context)
        local time = context.time
        if ready_attack(time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.tigersharker.tips)
            if context.shard_id ~= EventTimer.CurrentShardId then
                desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
            end
            return true, StringToFunction(desc), 10, time, 2
        end
        return false
    end
}

return info