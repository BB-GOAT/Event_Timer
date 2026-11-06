-- 洞穴地震

local info
info = {
    remotegettimefn = function(Thread)
        local cmd = [[
            local self = TheWorld.net.components.quaker
            if not self then return DataDumper({ not_found = true }) end
            local _task = BBGOAT_FN.getval(self.GetDebugString, "_task")
            return DataDumper({ time = _task and GetTaskRemaining(_task) or 0 })
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
            local quaker = TheWorld.net and TheWorld.net.components.quaker
            local text = quaker and quaker:IsQuaking() and STRINGS.eventtimer.quaker.remaining or STRINGS.eventtimer.quaker.cooldown
            return string.format(text, TimeToString(time))
        end
    end,
}

return info