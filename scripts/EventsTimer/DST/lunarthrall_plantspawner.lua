local remotegettextfn = function(Thread)
    local cmd = [[
        local self = TheWorld.components.lunarthrall_plantspawner
        if not self then return end

        if not _G.EventTimerClient.lunarthrall_plant_inst then
            _G.EventTimerClient.lunarthrall_plant_inst = {}
            local prefab = _G.Prefabs["lunarthrall_plant"]
            local _fn = prefab.fn
            prefab.fn = function()
                local inst = _fn()
                table.insert(_G.EventTimerClient.lunarthrall_plant_inst, inst)
                inst:ListenForEvent("onremove", function(inst)
                    table.removearrayvalue(_G.EventTimerClient.lunarthrall_plant_inst, inst)
                end)
                return inst
            end
        end

        return DataDumper(
            {
                count = #_G.EventTimerClient.lunarthrall_plant_inst,
                _nextspawn = self._nextspawn and GetTaskRemaining(self._nextspawn),
                _spawntask = self._spawntask and GetTaskRemaining(self._spawntask),
                waves_to_release = self.waves_to_release
            }
        )
    ]]

    BBGOAT_util:remote(cmd, nil, function(res)
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
                description = description .. "\n" .. string.format(STRINGS.eventtimer.lunarthrall_plantspawner.spawn, TimeToString(res._nextspawn))
            elseif res._spawntask then
                description = description .. "\n" .. string.format(STRINGS.eventtimer.lunarthrall_plantspawner.next_wave, TimeToString(res._spawntask))
            end
            if res.waves_to_release and res.waves_to_release > 0 then
                description = description .. "\n" .. string.format(STRINGS.eventtimer.lunarthrall_plantspawner.remain_waves, res.waves_to_release)
            end

            SaveTextData("lunarthrall_plantspawner", description)
        end
    end)
end

----------------------------------------------------------------------------------------------

if EventTimer.GetTimeFromRemoteCommand then
    AddPrefabPostInit("lunarthrall_plant", function(inst)
        inst:ListenForEvent("onremove", function(inst)
            if inst and inst:IsValid() and inst.AnimState then
                local bank, anim, frame = inst.AnimState:GetHistoryData()
                if anim:find("death") then
                    remotegettextfn()
                end
            end
        end)
    end)
end

----------------------------------------------------------------------------------------------
local info
info = {
    remotegettextfn = remotegettextfn,
    remotegettextfninterval = 10,
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