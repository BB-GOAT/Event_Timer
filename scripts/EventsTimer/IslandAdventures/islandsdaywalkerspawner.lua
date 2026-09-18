-- 海难-拾荒疯猪

local info
info = {
    postinitfn = function()
        if not TheNet:GetIsServer() then return end
        AddPrefabPostInit("world", function()
            if not TheWorld:HasTag("island") then
                info.gettimefn = function() end -- 防止奇怪的模组给我一个虚假的计时
            end
        end)
    end,
    gettimefn = function(self)
        local shard_daywalkerspawner = TheWorld.shard.components.shard_daywalkerspawner_tropical
        if shard_daywalkerspawner ~= nil and shard_daywalkerspawner:GetLocationName() ~= "islandsjunkpile"
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
            return ReplacePrefabName(STRINGS.eventtimer.islandsdaywalkerspawner.ready)
        elseif self.daywalker ~= nil then
            return ReplacePrefabName(STRINGS.eventtimer.islandsdaywalkerspawner.exists)
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
            y = -7,
        },
        loop = true,
    },
    announcefn = function(context)
        local time = context.time
        local desc
        if time > 0 then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.islandsdaywalkerspawner.cooldown), TimeToString(time))
            desc = MarkData(desc, context)
        elseif not Extract_by_format(context.text, STRINGS.eventtimer.islandsdaywalkerspawner.cooldown) then
            desc = string.gsub(context.text,"\n",": ")
        end
        return desc
    end,
    tipsfn = function(context)
        if string.find(context.text, ReplacePrefabName(STRINGS.eventtimer.islandsdaywalkerspawner.ready)) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.islandsdaywalkerspawner.tips)
            desc = MarkData(desc, context)
            return true, (GetTime() > 10) and StringToFunction(desc), 10, nil, 2
        end
        return false
    end,
}

return info