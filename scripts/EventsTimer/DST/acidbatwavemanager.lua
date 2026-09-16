-- 硝石蝙蝠袭击信息，参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616

local easing = require("easing")
local function DescribeBatWaveData(self, data)
    local description

    local chance_string
    if data.target_prefab_count and data.odds_to_spawn_wave then
        local official_chance = data.odds_to_spawn_wave
        local estimated_chance = easing.inQuad(data.target_prefab_count, 0, 1, self.max_target_prefab)

        chance_string = string.format(ReplacePrefabName(STRINGS.eventtimer.acidbatwavemanager.chance),
            official_chance * 100,
            estimated_chance * 100
        )
    end

    local spawn_wave_string
    if data.spawn_wave_time then
        -- 下波袭击
        local items_percent = data.target_prefab_count / self.max_target_prefab
        local number_of_bats = math.floor(items_percent * (TUNING.ACIDBATWAVE_SPAWN_COUNT_MAX - TUNING.ACIDBATWAVE_SPAWN_COUNT_MIN) + TUNING.ACIDBATWAVE_SPAWN_COUNT_MIN)

        local next_spawn_time = (data.spawn_wave_time - GetTime()) + self.update_time_seconds
        spawn_wave_string = string.format(ReplacePrefabName(STRINGS.eventtimer.acidbatwavemanager.next_wave_spawn),
            number_of_bats,
            TimeToString(next_spawn_time)
        )
    end

    local wave_cooldown_string
    if data.next_wave_time then
        -- This is the cooldown (i.e. "immunity period") after being subject to a bat raid.
        local wave_cooldown = (data.next_wave_time - GetTime())
        if wave_cooldown >= 0 then
            wave_cooldown_string = string.format(ReplacePrefabName(STRINGS.eventtimer.acidbatwavemanager.cooldown), TimeToString(wave_cooldown))
        end
    end

    if spawn_wave_string then
        description = spawn_wave_string
    elseif wave_cooldown_string then
        description = wave_cooldown_string
    else
        -- 只在没有下次袭击时间时才显示袭击概率
        description = chance_string
    end

    return description
end

local info
info = {
    gettextfn = function(self)
        local text_list = {}
        for _, player in pairs(AllPlayers) do
            if player and player:IsValid() and player.userid then
                local my_watcher_data = self.watching[player]
                if my_watcher_data then
                    text_list[player.userid] = DescribeBatWaveData(self, my_watcher_data)
                end
            end
        end
        return json.encode(text_list)
    end,
    image = {
        atlas = "images/Bat.xml",
        tex = "Bat.tex",
        scale = 0.2
    },
    playerly = true, -- 指明是针对单个玩家的事件
    playerly_datatype = "text", -- 每个玩家的数据类型
    announcefn = function(context)
        return context.text
    end
}

return info