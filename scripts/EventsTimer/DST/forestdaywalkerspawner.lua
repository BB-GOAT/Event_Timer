-- 纯本地获取方式
-- if not (EventTimer.GetTimeFromRemoteCommand or EventTimer.GetTimeFromServerMod) then
    AddPrefabPostInit("daywalker2", function(boss)
        boss:DoTaskInTime(0.2, function(inst)
            SaveTimeData("daywalkerspawner", 0)
            SaveTimeData("forestdaywalkerspawner", 0)
            if inst and inst.components and inst.components.talker and inst.components.talker.Say then
                local _Say = inst.components.talker.Say
                inst.components.talker.Say = function(self, str_say, ...)
                    for _, str in pairs(STRINGS.DAYWALKER_POWERDOWN or {}) do
                        if str == str_say then
                            SaveTimeData("daywalkerspawner", (TUNING.DAYWALKER_RESPAWN_DAYS_COUNT + 1) * TUNING.TOTAL_DAY_TIME - TheWorld.state.time*TUNING.TOTAL_DAY_TIME)
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

-- 拾荒疯猪
local info
info = {
    anim = {
        scale = 0.05,
        build = "daywalker_build",
        bank = "daywalker",
        animation = "idle_creepy_loop",
        overridebuild = { "daywalker_phase3" },
        uioffset = {
            x = -2,
            y = -7
        },
        loop = true,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.forestdaywalkerspawner_time
        local text = ThePlayer.HUD.WarningEventTimeData.forestdaywalkerspawner_text
        if time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.cooldown), TimeToString(time))
        else
            text = string.gsub(text,"\n",": ")
            return text
        end
    end,
    tipsfn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.forestdaywalkerspawner_text
        if string.find(text, ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.ready)) then
            return true, not (GetTime() < 10) and StringToFunction(ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.tips)), 10, nil, 2
        end
        return false
    end
}

return info