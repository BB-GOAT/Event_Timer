-- 洞穴地震

local up_i, pre_fn
local info
info = {
    postinitfn = function()
        if not TheNet:GetIsServer() then return end
        AddComponentPostInit("quaker", function(self)
            local _, i, prefn = Upvaluehelper.GetUpvalue(self.GetDebugString, "_task")
            up_i = i
            pre_fn = prefn
        end)
    end,
    gettimefn = function(self)
        local name, _task = debug.getupvalue(pre_fn, up_i)
        if _task and GetTaskRemaining(_task) then
            return GetTaskRemaining(_task)
        end
    end,
    image = {
        atlas = "images/inventoryimages.xml",
        tex = "rocks.tex",
        scale = 0.8,
    },
    DisableShardRPC = true, -- 我觉得同步这个意义不大
    announcefn = function(context)
        local time = context.time
        return string.format(STRINGS.eventtimer.quaker.cooldown, TimeToString(time))
    end,
}

return info