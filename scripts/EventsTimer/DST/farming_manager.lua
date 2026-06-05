-- 本地监听果蝇王是否生成，生成后提示玩家
local need_tips = false
AddPrefabPostInit("lordfruitfly", function(inst)
    need_tips = true
    inst:ListenForEvent("onremove", function(inst)
        if inst and inst:IsValid() and inst.AnimState then
            local bank, anim, frame = inst.AnimState:GetHistoryData()
            if anim:find("death") then
                need_tips = false
            end
        end
    end)
end)

----------------------------------------------------------------------------------------------

local info
info = {
    remotegettimefn = function(Thread)
        GetWorldSettingsTimeLeft("lordfruitfly_spawntime", nil, function(res)
            if res and res.err then
                SaveTimeData("farming_manager", 0)
                print('[警告] farming_manager remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("farming_manager", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
    anim = {
        scale = 0.2,
        build = "fruitfly_evil",
        bank = "fruitfly",
        animation = "idle",
        offset = {
            x = 0,
            y = -20
        },
        uioffset = {
            x = -2,
            y = -22
        },
        loop = true,
    },
    DisableShardRPC = true,
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.farming_manager_time
        if time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.farming_manager.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        if need_tips then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.farming_manager.tips)), 5, nil, 3
        end
        return false
    end,
}

return info