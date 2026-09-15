local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("klaussack_tropical_spawntimer"),
    gettextfn = function(time)
        local self = TheWorld.components.islandsklaussackspawner
        if not self then return end
        local function sack_can_despawn(inst)
            if not IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) and
                inst.components.entitytracker:GetEntity("klaus") == nil and
                inst.components.entitytracker:GetEntity("key") == nil then
                return true
            end
            return false
        end
        local sack = Upvaluehelper.GetUpvalue(self.GetDebugString, "_sack")
        if sack and sack:IsValid() and sack.despawnday and sack_can_despawn(sack) then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.islandsklaussackspawner.despawntext), sack.despawnday)
        else
            return time and TimeToString(time)
        end
    end,
    anim = {
        scale = 0.1,
        bank = "klaus_bag",
        build = "klaus_bag_tropical",
        animation = "idle",
    },
    announcefn = function(context)
        local time = context.time
        local text = context.text
        local desc
        local despawnday = Extract_by_format(text, STRINGS.eventtimer.islandsklaussackspawner.despawntext)
        if despawnday then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.islandsklaussackspawner.despawn), despawnday)
        elseif time then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.islandsklaussackspawner.cooldown), TimeToString(time))
        end
        if desc and context.shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
        end
        return desc
    end,
    tipsfn = function(context)
        local time = context.time
        if ready_attack(time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.islandsklaussackspawner.tips)
            if context.shard_id ~= EventTimer.CurrentShardId then
                desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
            end
            return true, StringToFunction(desc), 10, time, 2
        end
        return false
    end
}

return info