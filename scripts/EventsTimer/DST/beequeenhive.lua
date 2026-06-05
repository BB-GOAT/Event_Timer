-- 纯本地获取方式
local localgettimefn = function()
    AddPrefabPostInit("beequeenhivegrown", function()
        SaveTimeData("beequeenhive", 0)
    end)

    HookDeath("beequeen", "beequeenhive", function(event)
        SaveTimeData(event, TUNING.BEEQUEEN_RESPAWN_TIME)
    end)
end

----------------------------------------------------------------------------------------------

local remotegettimefn = function(Thread)
    local cmd = [[
        local TimerPrefabs = _G.EventTimerClient.TimerPrefabs
        local HookPrefab = _G.EventTimerClient.HookPrefab
        local beequeenhive = TimerPrefabs["beequeenhive"] or HookPrefab("beequeenhive")
        if not beequeenhive or not beequeenhive:IsValid() then
            return DataDumper({
                not_found = true
            })
        end

        local timer = beequeenhive.components.timer
        if not timer then
            return DataDumper({
                not_found = true
            })
        end

        local stagetimne = TUNING.BEEQUEEN_RESPAWN_TIME / 3
        local time
        if timer:GetTimeLeft("hivegrowth1") then
            time = 2 * stagetimne + timer:GetTimeLeft("hivegrowth1")
        elseif timer:GetTimeLeft("hivegrowth2") then
            time = stagetimne + timer:GetTimeLeft("hivegrowth2")
        else
            time = timer:GetTimeLeft("hivegrowth")
        end
        return DataDumper( { time = time } )
    ]]
    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.err then
            SaveTimeData("beequeenhive", 0)
            print('[警告] beequeenhive remotegettimefn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res and res.time then
            SaveTimeData("beequeenhive", res.time)
        elseif res and res.not_found then
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
        end
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    localgettimefn = localgettimefn,
    remotegettimefn = remotegettimefn,
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
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.beequeenhive_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.beequeenhive.cooldown), TimeToString(time))
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.beequeenhive_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.beequeenhive.tips)), 10, time, 2
        end
        return false
    end,
}

return info