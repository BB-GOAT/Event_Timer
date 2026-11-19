-- 梦魇裂隙/墨荒信息，参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616

-- 纯本地获取方式
local localgettimefn = function()
    local thrall_prefabs = {"shadowthrall_hands", "shadowthrall_horns", "shadowthrall_wings", "shadowthrall_mouth"}
    for _, prefab in ipairs(thrall_prefabs) do
        AddPrefabPostInit(prefab, function(thrall)
            thrall:DoTaskInTime(0.2, function(inst)
                if inst.AnimState then
                    local bank, anim, frame = inst.AnimState:GetHistoryData()
                    if anim and not anim:find("death") then
                        -- 魔杖提前召唤或重新发现存活墨荒时，清除旧冷却。
                        SaveTextData("shadowthrallmanager", "")
                        SaveTimeData("shadowthrallmanager", 0)
                    end
                end
                inst:ListenForEvent("onremove", function(inst)
                    if inst and inst:IsValid() and inst.AnimState then
                        local bank, anim, frame = inst.AnimState:GetHistoryData()
                        if anim and anim:find("death") then
                            local pos = inst:GetPosition()
                            local other_ents = TheSim:FindEntities(pos.x, 0, pos.z, 64, nil, { 'FX', 'DECOR', 'INLIMBO', 'NOCLICK', 'player' })
                            local have_other_thrall = false
                            for _, ent in ipairs(other_ents) do
                                if table.contains(thrall_prefabs, ent.prefab) then
                                    have_other_thrall = true
                                    break
                                end
                            end
                            if not have_other_thrall then
                                SaveTextData("shadowthrallmanager", "")
                                SaveTimeData("shadowthrallmanager", TUNING.FISSURE_COOLDOWN_DEFEATED_ANY_THRALLS)
                            end
                        end
                    end
                end)
            end)
        end)
    end
end

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
        if not self then return DataDumper({ not_found = true }) end

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
                SaveTimeData("shadowthrallmanager", 0)
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
                SaveTimeData("shadowthrallmanager", res.cooldown)
                fissure_string = string.format(STRINGS.eventtimer.shadowthrallmanager.fissure_cooldown, TimeToString(res.cooldown))
                target_text_interval = res.cooldown + 1
            end

            local description = CombineLines(thrall_string, fissure_string)
            SaveTextData("shadowthrallmanager", description)
        elseif res and res.not_found then
            SaveTimeData("shadowthrallmanager", 0)
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
        else
            target_text_interval = nil
            SaveTextData("shadowthrallmanager", "")
            if res and not res.err then
                SaveTimeData("shadowthrallmanager", 0)
            end
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
    localgettimefn = localgettimefn,
    remotegettextfn = remotegettextfn,
    remotegettextfninterval = function()
        return math.min(60, target_text_interval or 60)
    end,
    DisableClientPredictionClearText = true, -- 没有倒计时时仍保留等待玩家和存活墨荒信息
    image = {
        atlas = "images/Dreadstone_Outcrop.xml",
        tex = "Dreadstone_Outcrop.tex",
        scale = 0.4,
        uioffset = {
            x = 0,
            y = -2,
        },
        offset = {
            x = 0,
            y = 10,
        },
    },
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.shadowthrallmanager_text
        if text ~= "" then
            text = string.gsub(text,"\n",", ")
            return STRINGS.NAMES.SHADOWTHRALL_MOUTH .. ": " .. text
        end
        local time = ThePlayer.HUD.WarningEventTimeData.shadowthrallmanager_time
        if time > 0 then
            return STRINGS.NAMES.SHADOWTHRALL_MOUTH .. ": " .. string.format(STRINGS.eventtimer.shadowthrallmanager.fissure_cooldown, TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.shadowthrallmanager_time
        if ready_attack(time) then
            return true, StringToFunction(STRINGS.eventtimer.shadowthrallmanager.tips), 10, time, 1
        end
        return false
    end,
}

return info