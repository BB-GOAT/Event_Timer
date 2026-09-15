local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("deerclops_timetoattack"),
    gettextfn = function(time)
        local self = TheWorld.components.deerclopsspawner
        if not self then return end
        local description
        local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
        if time and target and target.name then
            description = string.format(STRINGS.eventtimer.deerclopsspawner.targeted, target.name, TimeToString(time))
        elseif time then
            description = string.format(ReplacePrefabName(STRINGS.eventtimer.deerclopsspawner.cooldown), TimeToString(time))
        end

        return description
    end,
    animchangefn = ChangeanimByWintersFeast,
    defaultanim = {
        scale = 0.044,
        bank = "deerclops",
        build = "deerclops_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -6,
        },
    },
    winterfeastanim = {
        scale = 0.046,
        bank = "deerclops",
        build = "deerclops_yule",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = -2,
            y = -8,
        },
    },
    announcefn = function(context)
        local time = context.time
        local text = context.text
        local desc
        local target, _ = Extract_by_format(text, STRINGS.eventtimer.deerclopsspawner.targeted)
        if target and time > 0 then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.deerclopsspawner.target), target, TimeToString(time))
        elseif time > 0 then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.deerclopsspawner.cooldown), TimeToString(time))
        end
        desc = MarkData(desc, context)
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
            local desc = ReplacePrefabName(STRINGS.eventtimer.deerclopsspawner.attack)
            desc = MarkData(desc, context)
            return true, StringToFunction(desc), 10, time, 3
        end
        return false
    end
}

return info