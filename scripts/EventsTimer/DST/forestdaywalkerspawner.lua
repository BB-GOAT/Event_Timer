-- 拾荒疯猪，参考了 饥饥事件计时器 的代码 https://steamcommunity.com/sharedfiles/filedetails/?id=3511498282 @不要看上我的菊

local info
info = {
    postinitfn = function()
        if not TheNet:GetIsServer() then return end
        AddPrefabPostInit("world", function()
            if not (TheWorld:HasTag("forest") or TheWorld:HasTag("island")) then
                info.gettimefn = function() end -- 防止奇怪的模组给我一个虚假的计时
            end
        end)
    end,
    gettimefn = function(self)
        if not self then return end
        local shard_daywalkerspawner = TheWorld.shard.components.shard_daywalkerspawner
        if shard_daywalkerspawner ~= nil and shard_daywalkerspawner:GetLocationName() ~= "forestjunkpile"
            or self.daywalker ~= nil
            or self.bigjunk ~= nil
            or not self.days_to_spawn
            or not CalcTimeOfDay then
            return
        end
        return (self.days_to_spawn + 1) * TUNING.TOTAL_DAY_TIME - CalcTimeOfDay()
    end,
    gettextfn = function(self, time)
        if self.bigjunk ~= nil then
            return ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.ready)
        elseif self.daywalker ~= nil then
            return ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.exists)
        end
    end,
    anim = {
        scale = 0.05,
        build = "daywalker_build",
        bank = "daywalker",
        animation = "idle_creepy_loop",
        overridebuild = { "daywalker_phase3" },
        uioffset = {
            x = -2,
            y = -7
        },
        loop = true,
    },
    announcefn = function(context)
        local time = context.time
        local desc
        if time > 0 then -- 可能会出现 世界1(森林) x天x分x秒的情况，所以优先检查时间
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.cooldown), TimeToString(time))
            desc = MarkData(desc, context)
        elseif not Extract_by_format(context.text, STRINGS.eventtimer.forestdaywalkerspawner.cooldown) then
            desc = string.gsub(context.text,"\n",": ")
        end
        return desc
    end,
    tipsfn = function(context)
        if string.find(context.text, ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.ready)) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.tips)
            desc = MarkData(desc, context)
            return true, (GetTime() > 10) and StringToFunction(desc), 10, nil, 2
        end
        return false
    end
}

return info