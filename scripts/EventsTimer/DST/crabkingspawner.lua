-- 纯本地获取方式
local localgettimefn = function()
    HookDeath("crabking", "crabkingspawner", function(event)
        SaveTimeData(event, TUNING.CRABKING_RESPAWN_TIME)
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    localgettimefn = localgettimefn,
    remotegettimefn = function(Thread)
        GetWorldSettingsTimeLeft("regen_crabking", "crabking_spawner", function(res)
            if res and res.err then
                SaveTimeData("crabkingspawner", 0)
                print('[警告] crabkingspawner remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("crabkingspawner", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
    anim = {
        scale = 0.022,
        bank = "king_crab",
        build = "crab_king_build",
        animation = "inert",
        loop = true,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.crabkingspawner_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.crabkingspawner.cooldown), TimeToString(time))
    end
}

return info