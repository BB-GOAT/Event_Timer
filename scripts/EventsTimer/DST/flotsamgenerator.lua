-- 瓶中信
-- 参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616

local target_time_interval = 5
local info
info = {
    remotegettimefn = function(Thread)
        local cmd = [[
            local _guaranteed_spawn_tasks
            if TheWorld.components.flotsamgenerator and TheWorld.components.flotsamgenerator.ScheduleGuaranteedSpawn then
                _guaranteed_spawn_tasks = BBGOAT_FN.getval(TheWorld.components.flotsamgenerator.ScheduleGuaranteedSpawn, "_guaranteed_spawn_tasks")
            end
            if not _guaranteed_spawn_tasks then return DataDumper({ not_found = true }) end
            local player = ThePlayer
            if player and player:IsValid() then
                local tasks = _guaranteed_spawn_tasks[player]
                if tasks then
                    for v, task in pairs(tasks) do
                        if v.prefabs[1] == "messagebottle" then
                            return DataDumper({ time = GetTaskRemaining(task) })
                        end
                    end
                end
            end
        ]]

        BBGOAT_util:remote(cmd, nil, function(res)
            if res and res.time then
                SaveTimeData("flotsamgenerator", res.time)
                target_time_interval = res.time + 1
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
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
    image = {
        atlas = "images/inventoryimages2.xml",
        tex = "messagebottle.tex",
        scale = 0.9,
        offset = {
           x = 0,
           y = 8,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.flotsamgenerator_time
        return string.format(ReplacePrefabName(STRINGS.eventtimer.flotsamgenerator.announce), TimeToString(time))
    end
}

return info