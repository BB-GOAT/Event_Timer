local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("mockfly_timetoattack"),
    gettextfn = function(time)
        local self = TheWorld.components.mock_dragonflyspawner
        if not self then return end
        local description
        local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
        if time and target and target.name then
            description = string.format(STRINGS.eventtimer.mock_dragonflyspawner.targeted, target.name, TimeToString(time))
        elseif time then
            description = string.format(ReplacePrefabName(STRINGS.eventtimer.mock_dragonflyspawner.cooldown), TimeToString(time))
        end

        return description
    end,
    image = {
        atlas = "images/Dragonfly.xml",
        tex = "Dragonfly.tex",
        scale = 0.2,
        offset = {
            x = 0,
            y = 13,
        }
    },
    anim = {
        scale = 0.044,
        bank = "dragonfly",
        build = "dragonfly_build",
        animation = "idle",
        loop = true,
    },
    announcefn = function(context)
        local time = context.time
        local text = context.text
        local desc
        local target, _ = Extract_by_format(text, STRINGS.eventtimer.mock_dragonflyspawner.targeted)
        if target and time > 0 then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.mock_dragonflyspawner.target), target, TimeToString(time))
        elseif time > 0 then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.mock_dragonflyspawner.cooldown), TimeToString(time))
        end
        if desc and context.shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
        end
        return desc
    end,
    tipsfn = function(context)
        local time = context.time
        if time > 2 and time < 60 then
            local tips_level_2 = context.shard_id == EventTimer.CurrentShardId
            return true, info.announcefn, time, nil, tips_level_2 and 2 or 1
        elseif time == 480 or JustEntered(time) then
            return true, info.announcefn, 10, nil, 2
        elseif ready_attack(time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.mock_dragonflyspawner.attack)
            if desc and context.shard_id ~= EventTimer.CurrentShardId then
                desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
            end
            return true, StringToFunction(desc), 10, time, 3
        end
        return false
    end
}

return info