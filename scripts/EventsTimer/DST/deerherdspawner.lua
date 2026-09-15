local info
info = {
    gettimefn = function()
        if TheWorld.components.deerherdspawner then
            local data = TheWorld.components.deerherdspawner:OnSave()
            return data and data._timetospawn
        end
    end,
    anim = {
        scale = 0.088,
        bank = "deer",
        build = "deer_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = -6,
            y = -6,
        },
    },
    announcefn = function(context)
        local time = context.time
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.deerherdspawner.cooldown), TimeToString(time))
        if desc and context.shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc
        end
        return desc
    end
}

return info