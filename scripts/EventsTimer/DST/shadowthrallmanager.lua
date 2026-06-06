-- 梦魇裂隙/墨荒信息，参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616

local target_text_interval = 5
local THRALL_NAMES = setmetatable({
    shadowthrall_hands = STRINGS.NAMES.SHADOWTHRALL_HANDS_ALLEGIANCE,
    shadowthrall_horns = STRINGS.NAMES.SHADOWTHRALL_HORNS_ALLEGIANCE,
    shadowthrall_wings = STRINGS.NAMES.SHADOWTHRALL_WINGS_ALLEGIANCE,
    shadowthrall_mouth = STRINGS.NAMES.SHADOWTHRALL_MOUTH_ALLEGIANCE,
}, {
    __index = function(self, index)
        rawset(self, index, "???")
        return rawget(self, index)
    end
})

local remotegettextfn = function(Thread)
    local cmd = [[
        local self = TheWorld.components.shadowthrallmanager
        if not self then
            return DataDumper({
                not_found = true
            })
        end

        local data = self:OnSave()
        local fissure = self:GetControlledFissure()
        local thralls_alive = {}
        local thralls_alive_ents = {}
        if fissure then
            if data.thrall_hands ~= nil then
                local ent = Ents[data.thrall_hands]
                thralls_alive[#thralls_alive+1] = ent
                if ent then
                    thralls_alive_ents[#thralls_alive_ents+1] = ent.prefab
                end
            end
            if data.thrall_horns ~= nil then
                local ent = Ents[data.thrall_horns]
                thralls_alive[#thralls_alive+1] = ent
                if ent then
                    thralls_alive_ents[#thralls_alive_ents+1] = ent.prefab
                end
            end
            if data.thrall_wings ~= nil then
                local ent = Ents[data.thrall_wings]
                thralls_alive[#thralls_alive+1] = ent
                if ent then
                    thralls_alive_ents[#thralls_alive_ents+1] = ent.prefab
                end
            end
        end

        return DataDumper({
            fissure = fissure ~= nil,
            thralls_alive = #thralls_alive,
            thralls_alive_ents = thralls_alive_ents,
            spawnthrallstime = data.spawnthrallstime,
            dreadstonecooldown = data.dreadstonecooldown,
            cooldown = data.cooldown,
        })
    ]]

    BBGOAT_util:remote(cmd, nil, function(res)
        if res and (res.fissure or res.cooldown) then
            target_text_interval = 5
            local thrall_string -- 奴隶
            local fissure_string -- 裂隙
            -- 检查是否有裂缝（和奴隶）
            if res.fissure then
                local thralls_alive_string = {}

                for i, prefab in ipairs(res.thralls_alive_ents) do
                    thralls_alive_string[i] = THRALL_NAMES[prefab]
                end

                thralls_alive_string = table.concat(thralls_alive_string, ", ")

                -- 裂缝可以“靠近”玩家，但如果玩家离得不够近，就不会产生墨荒。
                if res.thralls_alive == 0 and res.spawnthrallstime then
                    thrall_string = STRINGS.eventtimer.shadowthrallmanager.waiting_for_players
                else
                    thrall_string = string.format(STRINGS.eventtimer.shadowthrallmanager.thralls_alive, res.thralls_alive, thralls_alive_string)
                end

                if res.dreadstonecooldown then
                    fissure_string = string.format(ReplacePrefabName(STRINGS.eventtimer.shadowthrallmanager.dreadstone_regen), TimeToString(res.dreadstonecooldown))
                end
            elseif res.cooldown then
                fissure_string = string.format(STRINGS.eventtimer.shadowthrallmanager.fissure_cooldown, TimeToString(res.cooldown))
                target_text_interval = res.cooldown + 1
            end

            local description = CombineLines(thrall_string, fissure_string)
            SaveTextData("shadowthrallmanager", description)
        elseif res and res.not_found then
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
        else
            target_text_interval = nil
            SaveTextData("shadowthrallmanager", "")
            if res and res.err then
                print('[警告] shadowthrallmanager remotegettextfn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    remotegettextfn = remotegettextfn,
    remotegettextfninterval = function()
        return target_text_interval
    end,
    DisableClientPredictionClearText = true, -- 正常情况下没有time信息，需要此选项避免text被删除
    image = {
        atlas = "images/Dreadstone_Outcrop.xml",
        tex = "Dreadstone_Outcrop.tex",
        scale = 0.4,
        uioffset = {
            x = 0,
            y = -2,
        },
    },
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.shadowthrallmanager_text
        if text ~= "" then
            text = string.gsub(text,"\n",", ")
            return STRINGS.NAMES.SHADOWTHRALL_MOUTH .. ": " .. text
        end
        -- 用于兼容宣告第三方模组提供的数据
        local time = ThePlayer.HUD.WarningEventTimeData.shadowthrallmanager_time
        if time > 0 then
            return STRINGS.NAMES.SHADOWTHRALL_MOUTH .. ": " .. string.format(STRINGS.eventtimer.shadowthrallmanager.fissure_cooldown, TimeToString(time))
        end
    end,
}

return info