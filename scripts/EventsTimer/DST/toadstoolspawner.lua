-- 纯本地获取方式
local localgettimefn = function()
    AddPrefabPostInit("toadstool_cap", function(inst)
        inst:DoTaskInTime(0.2, function(inst)
            if inst and inst:IsValid() and inst.AnimState then
                local bank, anim, frame = inst.AnimState:GetHistoryData()
                if anim:find("idle") then
                    SaveTimeData("toadstoolspawner", 0)
                end
            end
        end)
    end)

    for _, prefab in pairs({"toadstool", "toadstool_dark"}) do
        HookDeath(prefab, "toadstoolspawner", function(event)
            SaveTimeData(event, TUNING.TOADSTOOL_RESPAWN_TIME)
        end)
    end
end

----------------------------------------------------------------------------------------------

local info
info = {
    localgettimefn = localgettimefn,
    remotegettimefn = function(Thread)
        GetWorldSettingsTimeLeft("toadstool_respawntask", nil, function(res)
            if res and res.err then
                SaveTimeData("toadstoolspawner", 0)
                print('[警告] toadstoolspawner remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("toadstoolspawner", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
    anim = {
        scale = 0.03,
        bank = "toadstool",
        build = "toadstool_build",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 0,
            y = -5,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.toadstoolspawner_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.toadstoolspawner.cooldown), TimeToString(time))
    end
}

return info