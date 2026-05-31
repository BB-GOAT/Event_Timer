-- 纯本地获取方式
-- if not (EventTimer.GetTimeFromRemoteCommand or EventTimer.GetTimeFromServerMod) then
    AddPrefabPostInit("lunarrift_portal", function()
        SaveTimeData("lunar_riftspawner", 0)
    end)

    local need_save = false
    AddPrefabPostInit("wagstaff_npc_pstboss", function(inst)
        need_save = true
        inst:DoTaskInTime(0.2, function(inst)
            if inst and inst.components and inst.components.talker and inst.components.talker.Say then
                local _Say = inst.components.talker.Say
                inst.components.talker.Say = function(self, str_say, ...)
                    for _, str in pairs({STRINGS.WAGSTAFF_NPC_CAPTURESTOP1, STRINGS.WAGSTAFF_NPC_CAPTURESTOP3}) do
                        if str == str_say and need_save then
                            need_save = false
                            SaveTimeData("lunar_riftspawner", TUNING.RIFTS_SPAWNDELAY)
                            break
                        end
                    end
                    return _Say(self, str_say, ...)
                end
            end
        end)
    end)
-- end

----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------

-- 月亮裂隙生成倒计时
local info
info = {
    gettimefn = function() -- 当裂隙出现时，不显示
        if TheWorld and TheWorld:HasTag("forest") and TheWorld.net.components.warningtimer.inst.replica.warningtimer.rift_portal_text:value() == "" then
            return GetWorldSettingsTimeLeft("rift_spawn_timer")()
        end
    end,
    image = {
        atlas = "minimap/minimap_data.xml",
        tex = "lunarrift_portal.png",
        scale = 0.8,
        offset = {
            x = 0,
            y = 13,
        },
    },
    anim = {
        scale = 0.05,
        build = "lunar_rift_portal",
        bank = "lunar_rift_portal",
        animation = "stage_3_loop",
        offset = {
            x = 0,
            y = -16,
        },
        loop = true,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.lunar_riftspawner_time
        return time > 0 and string.format(STRINGS.eventtimer.riftspawner.lunar_cooldown, TimeToString(time))
    end,
}

return info