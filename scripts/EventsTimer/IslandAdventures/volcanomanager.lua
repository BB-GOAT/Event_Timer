local info
info = {
    postinitfn = function()
        AddPrefabPostInit("world", function()
            info.DisableShardRPC = TheWorld:HasTag("volcano") -- 火山世界不同步火山爆发倒计时，海难世界同步
            if GetWorldtypeStr() ~= "shipwrecked" and GetWorldtypeStr() ~= "volcano" then
                info.tipsfn = nil -- 非海难火山世界不提示火山爆发
            end
        end)
    end,
    gettimefn = function()
        if not TheWorld.components.volcanomanager then
            return
        end

        local ActualTime = (TUNING.TOTAL_DAY_TIME * (TheWorld.state.time * 100)) / 100
        local ActualSeg = math.floor(ActualTime / 30)
        local TimeInSeg = ActualTime - (ActualSeg * 30)
        local SegUntilEruption = TheWorld.components.volcanomanager:GetNumSegmentsUntilEruption() or 0
        local SecondUntilEruption = math.floor((SegUntilEruption * 30) - TimeInSeg)

        return SecondUntilEruption > 0 and SecondUntilEruption or 0
    end,
    anim = {
        scale = 0.0077,
        bank = "volcano",
        build = "volcano",
        animation = "active_idle_pst",
        loop = true,
    },
    announcefn = function(context)
        local time = context.time
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.volcanomanager.cooldown), TimeToString(time))
        if context.shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
        end
        return desc
    end,
    tipsfn = function(context) -- 非海难火山世界不提示
        local time = context.time
        if time > 2 and time < 60 then
            return true, info.announcefn, time, nil, 2
        elseif JustEntered(time) and time <= 480 then
            return true, info.announcefn, 10, nil, 2
        elseif JustEntered(time) and time > 480 then
            return true, info.announcefn, 10, nil, 1
        elseif ready_attack(time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.volcanomanager.attack)
            if context.shard_id ~= EventTimer.CurrentShardId then
                desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
            end
            return true, StringToFunction(desc), 10, time, 3
        end
        return false
    end,
}

return info