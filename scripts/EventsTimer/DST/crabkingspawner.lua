local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("regen_crabking", "crabking_spawner"),
    anim = {
        scale = 0.022,
        bank = "king_crab",
        build = "crab_king_build",
        animation = "inert",
        loop = true,
    },
    announcefn = function(context)
        local time = context.time
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.crabkingspawner.cooldown), TimeToString(time))
        if desc and context.shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc
        end
        return desc
    end
}

return info