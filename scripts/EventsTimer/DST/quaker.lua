-- 洞穴地震

local info
info = {
    remotegettimefn = function(Thread)
        local cmd = [[
            local self = TheWorld.net.components.quaker
            if not self then
                return DataDumper({
                    not_found = true
                })
            end
            local _task = BBGOAT_FN.getval(self.GetDebugString, "_task")
            if _task and GetTaskRemaining(_task) then
                local time = GetTaskRemaining(_task)
                return DataDumper({ time = time })
            end
        ]]
        BBGOAT_util:remote(cmd, nil, function(res)
            if res and res.err then
                SaveTimeData("quaker", 0)
                print('[警告] quaker remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("quaker", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
    image = {
        atlas = "images/inventoryimages.xml",
        tex = "rocks.tex",
        scale = 0.8,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.quaker_time
        if time > 0 then
            return string.format(STRINGS.eventtimer.quaker.cooldown, TimeToString(time))
        end
    end,
}

return info