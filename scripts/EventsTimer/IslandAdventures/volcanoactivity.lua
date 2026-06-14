local target_time_interval
local info
info = {
    postinitfn = function()
        AddPrefabPostInit("world", function()
            if GetWorldtypeStr() ~= "shipwrecked" then
                info.tipsfn = nil -- 非海难火山世界不提示火山爆发
            end
        end)
    end,
    remotegettimefn = function(Thread)
        local cmd = [[
            local self = TheWorld.net.components.volcanoactivity
            if not self then return DataDumper({ not_found = true }) end

            local _eruption = BBGOAT_FN.getval(self.OnUpdate, "_eruption")
            local _eruption_timer = BBGOAT_FN.getval(self.OnUpdate, "_eruption_timer")
            local _firerain_duration = BBGOAT_FN.getval(self.OnUpdate, "_firerain_duration")
            local remaining_time
            if _eruption and _eruption:value() then
                remaining_time = _firerain_duration - _eruption_timer:value()
            end
            return DataDumper({ time = remaining_time })
        ]]
        BBGOAT_util:remote(cmd, nil, function(res)
            if res and res.err then
                SaveTimeData("volcanoactivity", 0)
                SaveTextData("volcanoactivity", "")
                print('[警告] volcanoactivity remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("volcanoactivity", res.time)
                SaveTextData("volcanoactivity", res.time > 0 and string.format(STRINGS.eventtimer.volcanoactivity.eruption, TimeToString(res.time)) or "")
                target_time_interval = res.time + 1
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            else -- 火山未爆发
                SaveTimeData("volcanoactivity", 0)
                SaveTextData("volcanoactivity", "")
                local time = ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData and ThePlayer.HUD.WarningEventTimeData.volcanomanager_time
                target_time_interval = time ~= 0 and (time + 1) or nil
            end
        end)
    end,
    remotegettimefninterval = function()
        return target_time_interval
    end,
    image = {
        atlas = "images/Volcano_Active.xml",
        tex = "Volcano_Active.tex",
        scale = 0.8,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.volcanoactivity_time
        return time > 0 and string.format(STRINGS.eventtimer.volcanoactivity.eruption, TimeToString(time))
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.volcanoactivity_time
        if time > 0 then
            return true, info.announcefn, time, nil, 1 -- 无声音 常驻显示爆发剩余时间
        end
    end
}

return info