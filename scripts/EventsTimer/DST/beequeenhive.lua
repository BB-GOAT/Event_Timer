local stagetimne = TUNING.BEEQUEEN_RESPAWN_TIME / 3
local info
info = {
    gettimefn = function(beequeenhive)
        if not beequeenhive or not beequeenhive:IsValid() then
            return
        end

        local timer = beequeenhive.components.timer
        if not timer then
            return
        end

        if timer:GetTimeLeft("hivegrowth1") then
            return 2 * stagetimne + timer:GetTimeLeft("hivegrowth1")
        elseif timer:GetTimeLeft("hivegrowth2") then
            return stagetimne + timer:GetTimeLeft("hivegrowth2")
        else
            return timer:GetTimeLeft("hivegrowth")
        end
    end,
    anim = {
        scale = 0.055,
        bank = "bee_queen",
        build = "bee_queen_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -10,
        },
    },
    announcefn = function(context)
        local time = context.time
        local shard_id = context.shard_id
        local desc = string.format(ReplacePrefabName(STRINGS.eventtimer.beequeenhive.cooldown), TimeToString(time))
        if shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, shard_id) .. "(" .. context.world_str .. ") : " .. desc
        end
        return desc
    end,
    tipsfn = function(context)
        local time = context.time
        if ready_attack(time) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.beequeenhive.tips)
            desc = MarkData(desc, context)
            return true, StringToFunction(desc), 10, time, 2
        end
        return false
    end,
}

return info