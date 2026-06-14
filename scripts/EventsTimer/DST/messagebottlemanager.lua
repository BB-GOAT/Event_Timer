local remotegettextfn = function(Thread)
    local cmd = [[
            local self = TheWorld.components.messagebottlemanager
            if not self then return DataDumper({ not_found = true }) end
            local count = 0
            for _ in pairs(self.active_treasure_hunt_markers) do
                count = count + 1
            end
            if count > 0 then
                return DataDumper({count = count, max = TUNING.MAX_ACTIVE_TREASURE_HUNTS})
            end
        ]]
    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.err then
            SaveTextData("messagebottlemanager", "")
            print('[警告] messagebottlemanager remotegettextfn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res and res.count then
            if res.count > 0 then
                local str = string.format(STRINGS.eventtimer.messagebottlemanager.text, res.count, res.max or TUNING.MAX_ACTIVE_TREASURE_HUNTS)
                SaveTextData("messagebottlemanager", str)
            else
                SaveTextData("messagebottlemanager", "")
            end
        elseif res and res.not_found then
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
        end
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    remotegettextfn = remotegettextfn,
    DisableClientPrediction = true, -- 这个事件无法预测倒计时
    image = {
        atlas = "minimap/minimap_data.xml",
        tex = "messagebottletreasure_marker.png",
        scale = 0.9,
    },
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.messagebottlemanager_text
        text = string.gsub(text, "\n", ": ")
        return text
    end,
}

return info