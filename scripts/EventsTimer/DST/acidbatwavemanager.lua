local info = {
    DisableSaveTime = true,
    DisableClientPredictionClearText = true, -- 没有倒计时时仍保留袭击概率
    remotegettextfninterval = 10, -- 与服务器组件的更新周期一致
    remotegettextfn = function(Thread)
        local cmd = [[
            local self = TheWorld.components.acidbatwavemanager
            if not self then return DataDumper({ not_found = true }) end
            local data = ThePlayer and ThePlayer:IsValid() and self.watching[ThePlayer]
            if not data then return DataDumper({ time = 0 }) end
            local now = GetTime()
            if data.spawn_wave_time then
                local items_percent = data.target_prefab_count / self.max_target_prefab
                local count = math.floor(items_percent * (TUNING.ACIDBATWAVE_SPAWN_COUNT_MAX - TUNING.ACIDBATWAVE_SPAWN_COUNT_MIN) + TUNING.ACIDBATWAVE_SPAWN_COUNT_MIN)
                return DataDumper({
                    mode = "spawn",
                    time = data.spawn_wave_time - now + self.update_time_seconds,
                    count = count,
                })
            elseif data.next_wave_time and data.next_wave_time >= now then
                return DataDumper({ mode = "cooldown", time = data.next_wave_time - now })
            elseif data.target_prefab_count and data.odds_to_spawn_wave then
                local estimated = require("easing").inQuad(data.target_prefab_count, 0, 1, self.max_target_prefab)
                return DataDumper({
                    mode = "chance", time = 0,
                    chance = data.odds_to_spawn_wave * 100,
                    estimated = estimated * 100,
                })
            end
            return DataDumper({ time = 0 })
        ]]
        BBGOAT_util:remote(cmd, nil, function(res)
            if res.err or res.not_found then
                SaveTimeData("acidbatwavemanager", 0)
                SaveTextData("acidbatwavemanager", "")
                if res.err then
                    print('[警告] acidbatwavemanager remotegettextfn error:', res.err)
                end
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res.time then
                local time = res.time
                local strings = STRINGS.eventtimer.acidbatwavemanager
                local text = ""
                if res.mode == "spawn" then
                    text = string.format(ReplacePrefabName(strings.next_wave_spawn), res.count, TimeToString(time))
                elseif res.mode == "cooldown" then
                    text = string.format(ReplacePrefabName(strings.cooldown), TimeToString(time))
                elseif res.mode == "chance" then
                    text = string.format(ReplacePrefabName(strings.chance), res.chance, res.estimated)
                end
                SaveTimeData("acidbatwavemanager", time)
                SaveTextData("acidbatwavemanager", text)
            end
        end)
    end,
    image = {
        atlas = "images/Bat.xml",
        tex = "Bat.tex",
        scale = 0.2,
    },
    announcefn = function()
        return ThePlayer.HUD.WarningEventTimeData.acidbatwavemanager_text
    end,
}

return info
