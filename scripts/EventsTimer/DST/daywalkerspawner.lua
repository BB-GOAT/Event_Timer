-- 梦魇疯猪

local info
info = {
    postinitfn = function()
        if not TheNet:GetIsServer() then return end
        AddPrefabPostInit("world", function()
            if not (TheWorld:HasTag("cave") or TheWorld:HasTag("volcano")) then
                info.gettimefn = function() end -- 防止奇怪的模组给我一个虚假的计时
            end
        end)
    end,
    gettimefn = function()
        local self = TheWorld.components.daywalkerspawner
        if not self then return end
        local shard_daywalkerspawner = TheWorld.shard.components.shard_daywalkerspawner
        if shard_daywalkerspawner ~= nil and shard_daywalkerspawner:GetLocationName() ~= "cavejail" or self.daywalker ~= nil or not self.days_to_spawn or not CalcTimeOfDay then
            return
        end
        return (self.days_to_spawn + 1) * TUNING.TOTAL_DAY_TIME - CalcTimeOfDay()
    end,
    gettextfn = function()
        local self = TheWorld.components.daywalkerspawner
        if not self then return end
        if self.daywalker ~= nil then
            return ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner.ready)
        end
    end,
    anim = {
        scale = 0.05,
        build = "daywalker_build",
        bank = "daywalker",
        animation = "idle_creepy_loop",
        uioffset = {
            x = -2,
            y = -7
        },
        loop = true,
    },
    announcefn = function(context)
        local time = context.time
        local text = context.text
        if time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner.cooldown), TimeToString(time))
        else
            text = string.gsub(text,"\n",": ")
            return text
        end
    end,
    tipsfn = function(context)
        local text = context.text
        if string.find(text, ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner.ready)) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner.tips)
            if context.shard_id ~= EventTimer.CurrentShardId then
                desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
            end
            return true, (GetTime() > 10) and StringToFunction(desc), 10, nil, 2
        end
        return false
    end
}

return info