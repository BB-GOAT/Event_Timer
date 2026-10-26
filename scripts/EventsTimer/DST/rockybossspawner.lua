local TIMER_NAME = "rockyboss_timetospawn"

local info = {
    gettimefn = function(self)
        if self:GetRockyBoss() == nil then
            return GetWorldSettingsTimeLeft(TIMER_NAME, self.inst)
        end
    end,
    anim = {
        bank = "rocky",
        build = "rocky_boss",
        animation = "idle_loop",
        loop = true,
        scale = 0.08,
        uioffset = {
            x = 0,
            y = -7,
        },
    },
    announcefn = function(context)
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.rockybossspawner.cooldown), TimeToString(context.time))
        desc = MarkData(desc, context)
        return desc
    end,
    -- tipsfn = function(context) -- 石虾王是尝试刷新，不能保证一定刷新了，要保证的话需要使用gettextfn常驻已刷新提示，还是算了
    --     if ready_attack(context.time) then
    --         local desc = ReplacePrefabName(STRINGS.eventtimer.rockybossspawner.tips)
    --         desc = MarkData(desc, context)
    --         return true, StringToFunction(desc), 10, context.time, 1
    --     end
    --     return false
    -- end,
}

return info
