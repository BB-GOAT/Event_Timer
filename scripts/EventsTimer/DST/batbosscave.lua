local TIMER_NAME = "ChildSpawner_RegenPeriod"

local function GetCave(world)
    local manager = world.components.acidbatwavemanager
    local cave = manager and manager.batbosscaves and next(manager.batbosscaves)
    return cave and cave:IsValid() and cave or nil
end

local info = {
    timerprefab = "world",
    gettimefn = function(world)
        local inst = GetCave(world)
        local spawner = inst and inst.components.childspawner
        if spawner and spawner.childreninside == 0 and spawner.numchildrenoutside == 0 then
            return GetWorldSettingsTimeLeft(TIMER_NAME, inst)
        end
    end,
    gettextfn = function(world, time)
        if time and time > 0 then
            return string.format(STRINGS.eventtimer.batbosscave.cooldown, TimeToString(time))
        end
    end,
    anim = {
        bank = "bat_boss",
        build = "bat_boss",
        animation = "fly_loop",
        loop = true,
        scale = 0.1,
        uioffset = {
            x = 5,
            y = -18,
        },
        offset = {
            x = 5,
            y = -18
        }
    },
    announcefn = function(context)
        if context.text ~= "" then
            local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.batbosscave.announce), context.text:gsub("\n", "    "))
            return desc
        end
    end,
    tipsfn = function(context)
        if ready_attack(context.time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.batbosscave.tips)
            desc = MarkData(desc, context)
            return true, StringToFunction(desc), 10, context.time, 1
        end
        return false
    end,
}

return info