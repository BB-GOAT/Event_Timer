-- 镀金骑士冷却倒计时

local target_time_interval
local info
info = {
    remotegettimefn = function(Thread)
        local cmd = [[
            local player = ThePlayer
            if player and player:IsValid() then
                local debuff = player.components.debuffable and player.components.debuffable:GetDebuff("yoth_princesscooldown_buff")
                if debuff then
                    local time = debuff.components and debuff.components.timer and debuff.components.timer:GetTimeLeft("buffover")
                    return DataDumper({ time = time })
                end
            end
        ]]

        BBGOAT_util:remote(cmd, nil, function(res)
            if res and res.time then
                SaveTimeData("flotsamgenerator", res.time)
                target_time_interval = res.time + 1
            else
                SaveTimeData("flotsamgenerator", 0)
                target_time_interval = nil
                if res and res.err then
                    print('[警告] flotsamgenerator remotegettimefn error:', res.err)
                    if Thread then KillThreadsWithID(Thread.id) end
                end
            end
        end)
    end,
    remotegettextfninterval = function()
        return target_time_interval
    end,
    anim = {
        scale = 0.08,
        bank = "knight",
        build = "knight_yoth_build",
        animation = "idle_loop",
        uioffset = {
            x = 0,
            y = -10,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.yoth_knightmanager_time
        return string.format(ReplacePrefabName(STRINGS.eventtimer.yoth_knightmanager.announce), time)
    end,
    tipsfn = function ()
        local time = ThePlayer.HUD.WarningEventTimeData.yoth_knightmanager_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.yoth_knightmanager.tips)), 10, time, 2
        end
        return false
    end
}

return info