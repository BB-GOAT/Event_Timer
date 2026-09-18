-- 猎犬/洞穴蠕虫/鳄狗/巨大洞穴蠕虫 Anim刷新
local function HoundedAnimChangeFn(self, context)
    local text = context.text
    local worldtype = context.shard_id == EventTimer.CurrentShardId and GetWorldtypeStr() or context.world_type
    local is_worm_boss = text and Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss))
    if is_worm_boss then
        self.anim = self.wormbossanim
    elseif worldtype == "shipwrecked" or worldtype == "volcano" then
        self.anim = self.islandanim
    elseif worldtype == "cave" then
        self.anim = self.caveanim
    elseif worldtype == "porkland" then
        self.anim = self.porklandanim
    else
        self.anim = self.forestanim
    end
end

-- 监听热带冒险的区域变化事件
MOD_util:AddPlayerPostInit(function(world, player)
    player:ListenForEvent("regionchange_client", function(inst, data)
        if table.typecheckedgetfield(ThePlayer, "table", "HUD", "WarningEventTimeData", "hounded") and EventTimer.CurrentShardId then
            HoundedAnimChangeFn(WarningEvents["hounded"], { world_type = GetWorldtypeStr() })
            local warningevent_child = ThePlayer.HUD["hounded_" .. EventTimer.CurrentShardId]
            if warningevent_child then
                warningevent_child:SetEventAnim(WarningEvents["hounded"].anim)
            end
        end
    end)
end)

local _activeplayers
local info
info = {
    postinitfn = function()
        if not TheNet:GetIsServer() then return end
        AddComponentPostInit("hounded", function(self)
            _activeplayers = Upvaluehelper.GetUpvalue(self.OnUpdate, "_activeplayers")
            self.inst:DoTaskInTime(0.1, function()
                local _spawnmode = Upvaluehelper.GetUpvalue(self.OnUpdate, "_spawnmode")
                if _spawnmode == "never" then
                    info.gettimefn = nil
                    info.gettextfn = nil
                end
            end)
        end)
    end,
    gettimefn = function(self)
        local data = self:OnSave()
        local _attackplanned = data.attackplanned
        if not _attackplanned or (_activeplayers and #_activeplayers == 0) then
            return
        end
        return data and data.timetoattack
    end,
    gettextfn = function(self, time)
        if not time then return end

        local next_wave_is_wormboss = Upvaluehelper.GetUpvalue(self.DoWarningSpeech, "_wave_pre_upgraded")
        local _wave_override_chance = self:OnSave().wave_override_chance

        if next_wave_is_wormboss then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss), TimeToString(time))
        elseif checknumber(_wave_override_chance) and _wave_override_chance > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.worm_boss_chance), TimeToString(time), _wave_override_chance * 100)
        end
    end,
    imagechangefn = function(self, context)
        local text = context.text
        local worldtype = context.shard_id == EventTimer.CurrentShardId and GetWorldtypeStr() or context.world_type -- 兼容【热带冒险】
        local is_worm_boss = text and Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss))
        if worldtype == "porkland" then
            self.image = nil
        elseif worldtype == "shipwrecked" or worldtype == "volcano" then
            self.image = nil
        elseif is_worm_boss then
            self.image = self.wormbossimage
        elseif worldtype == "cave" then
            self.image = self.caveimage
        else
            self.image = self.forestimage
        end
    end,
    forestimage = {
        atlas = "images/Hound.xml",
        tex = "Hound.tex",
        scale = 0.35,
    },
    caveimage = {
        atlas = "images/Depths_Worm.xml",
        tex = "Depths_Worm.tex",
        scale = 0.2,
    },
    wormbossimage = {
        atlas = "images/Worm_boss.xml",
        tex = "Worm_boss.tex",
        scale = 0.2,
    },
    animchangefn = HoundedAnimChangeFn,
    forestanim = {
        scale = 0.099,
        bank = "hound",
        build = "hound_ocean",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 0,
            y = 0,
        },
        offset = {
            x = 0,
            y = 0,
        }
    },
    islandanim = {
        scale = 0.09,
        bank = "crocodog",
        build = "crocodog",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 6,
            y = 0,
        },
        offset = {
            x = 0,
            y = 0,
        }
    },
    caveanim = {
        scale = 0.066,
        bank = "worm",
        build = "worm",
        animation = "atk",
        loop = true,
        uioffset = {
            x = 0,
            y = 0,
        },
        offset = {
            x = 0,
            y = 0,
        }
    },
    porklandanim = {
        scale = 0.08,
        build = "bat_vamp_build",
        bank = "bat", -- 岛屿冒险猪镇是 bat | 云霄国度是 bat_vamp
        animation = "fly_loop",
        loop = true,
        uioffset = {
            x = 10,
            y = -15,
        },
        offset = {
            x = 0,
            y = -15,
        }
    },
    wormbossanim = {
        scale = 0.066,
        bank = "worm_boss",
        build = "worm_boss",
        animation = "head_idle_loop",
        orientation = 1,
        loop = true,
        uioffset = {
            x = 0,
            y = 0,
        },
        offset = {
            x = 0,
            y = 0,
        }
    },
    -- DisableShardRPC = true,
    announcefn = function(context)
        local time = context.time
        local text = context.text
        local world_type = context.shard_id == EventTimer.CurrentShardId and GetWorldtypeStr() or context.world_type
        local desc
        local is_worm_boss = text ~= "" and Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss))
        if is_worm_boss then
            desc = text
        else
            desc = time > 0 and string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns[world_type]), TimeToString(time))
        end
        desc = MarkData(desc, context)
        return desc
    end,
    tipsfn = function(context)
        if context.shard_id ~= EventTimer.CurrentShardId then return end

        local time = context.time
        local text = context.text
        local world_type = context.shard_id == EventTimer.CurrentShardId and GetWorldtypeStr() or context.world_type
        local is_worm_boss = text ~= "" and Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss))

        if time > 2 and time <= 90 then
            return true, info.announcefn, time, nil, 2
        elseif JustEntered(time) and time < 960 then
            return true, info.announcefn, 10, nil, 2
        elseif JustEntered(time) then
            return true, info.announcefn, 10, nil, 1
        elseif ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.hounded.attack[is_worm_boss and "worm_boss" or world_type])), 10, time, 3
        end
        return false
    end
}

return info