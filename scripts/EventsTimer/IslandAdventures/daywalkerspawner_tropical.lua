-- 火山-梦魇疯猪

local function HasVolcanoIsland()
    if TheWorld:HasTag("volcano") then
        return true
    end

    local topology = TheWorld.topology
    return topology ~= nil
        and topology.overrides ~= nil
        and topology.overrides.volcanoisland ~= "none"
end

local info
info = {
    postinitfn = function()
        if not TheNet:GetIsServer() then return end
        AddPrefabPostInit("world", function()
            if not HasVolcanoIsland() then
                info.gettimefn = function() end
            end
        end)
    end,
    gettimefn = function(self)
        local shard_daywalkerspawner = TheWorld.shard.components.shard_daywalkerspawner_tropical
        if shard_daywalkerspawner ~= nil and shard_daywalkerspawner:GetLocationName() ~= "volcanojail"
            or self.daywalker ~= nil
            or not self.spawnpoints
            or #self.spawnpoints == 0
            or not self.days_to_spawn
            or not CalcTimeOfDay then
            return
        end
        return (self.days_to_spawn + 1) * TUNING.TOTAL_DAY_TIME - CalcTimeOfDay()
    end,
    gettextfn = function(self, time)
        if self.daywalker ~= nil then
            return ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner_tropical.ready)
        end
    end,
    anim = {
        scale = 0.05,
        build = "daywalker_build",
        bank = "daywalker",
        animation = "idle_creepy_loop",
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
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner_tropical.cooldown), TimeToString(time))
            desc = MarkData(desc, context)
        elseif not Extract_by_format(context.text, STRINGS.eventtimer.daywalkerspawner_tropical.cooldown) then
            desc = string.gsub(context.text,"\n",": ")
        end
        return desc
    end,
    tipsfn = function(context)
        if string.find(context.text, ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner_tropical.ready)) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner_tropical.tips)
            desc = MarkData(desc, context)
            return true, (GetTime() > 10) and StringToFunction(desc), 10, nil, 2
        end
        return false
    end,
}

return info