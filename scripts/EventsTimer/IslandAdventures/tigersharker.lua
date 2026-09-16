local info
info = {
    gettimefn = function(self)
        if not self.TimeUntilCanAppear and self.TimeUntilRespawn then return end
        local appear_time = self:TimeUntilCanAppear()
        local respawn_time = self:TimeUntilRespawn()
        return math.max(appear_time, respawn_time)
    end,
    gettextfn = function(self, time)
        if self.shark then
            return ReplacePrefabName(STRINGS.eventtimer.tigersharker.exists)
        elseif self.CanSpawn and self:CanSpawn(true, true) then
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
        desc = MarkData(desc, context)
        return desc
    end,
    tipsfn = function(context)
        local time = context.time
        if ready_attack(time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.tigersharker.tips)
            desc = MarkData(desc, context)
            return true, StringToFunction(desc), 10, time, 2
        end
        return false
    end
}

return info