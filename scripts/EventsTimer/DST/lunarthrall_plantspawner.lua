local remotegettextfninterval
local remotegettextfn = function(Thread)
    local cmd = [[
        local count = 0
        for guid, ent in pairs(Ents) do
            if ent.prefab == "lunarthrall_plant" then
                count = count + 1
            end
        end
        local self = TheWorld.components.lunarthrall_plantspawner
        if not self then return end

        return DataDumper(
            {
                count = count,
                _nextspawn = self._nextspawn and GetTaskRemaining(self._nextspawn),
                _spawntask = self._spawntask and GetTaskRemaining(self._spawntask),
                waves_to_release = self.waves_to_release
            }
        )
    ]]

    BBGOAT_util:remote(cmd, nil, function(res)
        remotegettextfninterval = nil
        if res and res.err then
            SaveTextData("lunarthrall_plantspawner", "")
            print('[警告] lunarthrall_plantspawner remotegettextfn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res and res.count then
            if res.count == 0 and not res.waves_to_release then
                SaveTextData("lunarthrall_plantspawner", "")
                return
            end
            local description = string.format(STRINGS.eventtimer.lunarthrall_plantspawner.infested_count, res.count)
            if res._nextspawn then
                remotegettextfninterval = res._nextspawn + 5
                description = description .. "\n" .. string.format(STRINGS.eventtimer.lunarthrall_plantspawner.spawn, TimeToString(res._nextspawn))
            elseif res._spawntask then
                remotegettextfninterval = res._spawntask + 5
                description = description .. "\n" .. string.format(STRINGS.eventtimer.lunarthrall_plantspawner.next_wave, TimeToString(res._spawntask))
            end
            if res.waves_to_release and res.waves_to_release > 0 then
                description = description .. "\n" .. string.format(STRINGS.eventtimer.lunarthrall_plantspawner.remain_waves, res.waves_to_release)
            end

            if checknumber(remotegettextfninterval) and remotegettextfninterval < 0 then -- 防止该死的负数
                remotegettextfninterval = 5
            end

            SaveTextData("lunarthrall_plantspawner", description)
        end
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    remotegettextfn = remotegettextfn,
    remotegettextfninterval = function()
        return remotegettextfninterval
    end,
    DisableClientPredictionClearText = true,
    image = {
        atlas = "minimap/minimap_data.xml",
        tex = "lunarthrall_plant.png",
        scale = 0.8,
    },
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.lunarthrall_plantspawner_text
        text = string.gsub(text,"\n",", ")
        return STRINGS.NAMES.LUNARTHRALL_PLANT .. ": " .. text
    end,
}

return info