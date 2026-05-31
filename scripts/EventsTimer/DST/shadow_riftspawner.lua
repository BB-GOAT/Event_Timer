-- 纯本地获取方式
-- if not (EventTimer.GetTimeFromRemoteCommand or EventTimer.GetTimeFromServerMod) then
    AddPrefabPostInit("shadowrift_portal", function()
        SaveTimeData("shadow_riftspawner", 0)
    end)
    AddPrefabPostInit("charlie_hand", function(inst)
        inst:DoTaskInTime(0.2, function(inst)
            inst:ListenForEvent("onremove", function(inst)
                if inst and inst:IsValid() and inst.AnimState then
                    local bank, anim, frame = inst.AnimState:GetHistoryData()
                    if anim:find("grab_pst") then
                        SaveTimeData("shadow_riftspawner", TUNING.RIFTS_SPAWNDELAY) -- 暗影裂隙生成倒计时
                        SaveTimeData("atrium_gate", TUNING.ATRIUM_GATE_COOLDOWN) -- 远古大门重置倒计时
                    end
                end
            end)
        end)
    end)
-- end

----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------

-- 暗影裂隙生成倒计时
local info
info = {
    image = {
        atlas = "minimap/minimap_data.xml",
        tex = "shadowrift_portal.png",
        scale = 0.8,
        offset = {
            x = 0,
            y = 13,
        },
    },
    -- anim = {
    --     scale = 0.05,
    --     build = "shadowrift_portal",
    --     bank = "shadowrift_portal",
    --     animation = "scrapbook",
    -- },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.shadow_riftspawner_time
        return time and time > 0 and string.format(STRINGS.eventtimer.riftspawner.shadow_cooldown, TimeToString(time))
    end,
}

return info