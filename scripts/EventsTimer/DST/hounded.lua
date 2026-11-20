-- 巨大洞穴蠕虫：根据世界设置与玩家生存天数预测

-- 是否为巨大洞穴蠕虫袭击文本
local function IsWormBossText(text)
    local formats = STRINGS.eventtimer.hounded.cooldowns -- 巨大洞穴蠕虫的两种倒计时格式
    return text and text ~= "" and (
        Extract_by_format(text, ReplacePrefabName(formats.worm_boss)) or
        Extract_by_format(text, ReplacePrefabName(formats.worm_boss_uncertain))
    ) and true or false
end

---用已知本世界玩家作为必选成员，其余全服玩家作为可选成员，求平均生存天数范围。
---忽略规划后玩家进出及生存天数跨档；列表生存天数是显示天数，需要减一。
---@return number|nil minimum 最低可能平均生存天数；缺少有效资料时返回nil
---@return number|nil maximum 最高可能平均生存天数
local function GetWormBossAgeRange()
    local clients = TheNet:GetClientTable() -- 全服玩家资料，包含其他世界
    local known = {} -- 已确认在本世界的玩家userid集合
    local optional = {} -- 世界归属未知的玩家生存天数
    local total, count = 0, 0 -- 必选玩家的总生存天数与人数
    if not clients or not ThePlayer or not ThePlayer.userid then return end
    known[ThePlayer.userid] = true
    for _, player in ipairs(AllPlayers or {}) do -- 客户端当前可见的本世界玩家
        if player.userid then known[player.userid] = true end
    end
    for _, client in ipairs(clients) do -- 全服玩家
        if client.userid and client.userid ~= "" then
            if type(client.playerage) ~= "number" or client.playerage < 1 then return end
            local age = math.max(0, client.playerage - 1) -- 与服务器age:GetAgeInDays一致的生存天数
            if known[client.userid] then
                total, count = total + age, count + 1
            else
                optional[#optional + 1] = age
            end
        end
    end
    if count == 0 then return end
    table.sort(optional)
    local minimum, maximum = total / count, total / count -- 两端平均生存天数
    local low_sum, high_sum = total, total -- 逐步加入生存天数最短/最长玩家后的生存天数和
    for i = 1, #optional do
        low_sum = low_sum + optional[i]
        high_sum = high_sum + optional[#optional - i + 1]
        minimum = math.min(minimum, low_sum / (count + i))
        maximum = math.max(maximum, high_sum / (count + i))
    end
    return minimum, maximum
end

---按世界设置和当前生存天数范围建立预警时长候选；资料不足时保留全部候选。
---@return number[] durations 按从小到大排列的候选时长，单位秒
local function GetWormBossDurations()
    local overrides = TheWorld.topology and TheWorld.topology.overrides -- 当前世界设置
    local setting = overrides and overrides.wormattacks -- 蠕虫袭击频率
    if setting == "rare" or setting == "often" then return { 90 } end
    if setting == "always" then return { 60 } end
    if setting and setting ~= "default" then return { 60, 90, 120 } end
    local minimum, maximum = GetWormBossAgeRange() -- 本世界玩家平均生存天数的可能范围
    if not minimum then return { 60, 90, 120 } end
    local durations = {} -- 与生存天数范围相交的预警时长候选
    if maximum >= 50 then durations[#durations + 1] = 60 end
    if maximum >= 8 and minimum < 50 then durations[#durations + 1] = 90 end
    if minimum < 8 then durations[#durations + 1] = 120 end
    return durations
end

----------------------------------------------------------------------------------------------

-- 猎犬/洞穴蠕虫/鳄狗/巨大洞穴蠕虫 Anim刷新
local HoundedAnimChangeFn
local function HoundedAnimChange(self)
    if TheNet:IsDedicated() then
        return
    end

    local last_anim
    if not HoundedAnimChangeFn then
        HoundedAnimChangeFn = function()
            local text = ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData and ThePlayer.HUD.WarningEventTimeData.hounded_text
            local is_worm_boss = IsWormBossText(text)
            local worldtype = GetWorldtypeStr()
            if worldtype == "shipwrecked" or worldtype == "volcano" then
                self.anim = self.islandanim
            elseif is_worm_boss then
                self.anim = self.wormbossanim
            elseif worldtype == "cave" then
                self.anim = self.caveanim
            elseif worldtype == "porkland" then
                self.anim = {
                    scale = 0.08,
                    build = "bat_vamp_build",
                    bank = "bat", -- 云霄国度是 bat_vamp
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
                }
            else
                self.anim = self.forestanim
            end

            if (self.anim and self.anim.bank ~= last_anim) and ThePlayer and ThePlayer.HUD and ThePlayer.HUD.hounded then
                last_anim = self.anim.bank
                ThePlayer.HUD.hounded:SetEventAnim(self.anim)
            end
        end
    end
    HoundedAnimChangeFn()
end

-- 监听热带冒险的区域变化事件
MOD_util:AddPlayerPostInit(function(world, player)
    player:ListenForEvent("regionchange_client", function(inst, data)
        if HoundedAnimChangeFn then
            HoundedAnimChangeFn()
        end
    end)
end)

----------------------------------------------------------------------------------------------

-- 纯本地获取方式
local need_tips = false -- 检测到巨大蠕虫生成后，等待tipsfn消费的攻击提示
local localgettimefn = function()
    local hounded_warning = {
        hound = true, -- 猎犬
        worm  = true, -- 洞穴蠕虫
        crocodog = true, -- 鳄狗
    }
    local current_level -- 本轮已收到的最高预警等级，5表示巨大洞穴蠕虫
    local reset_task
    local function ResetWarningAfter(time)
        if reset_task then
            reset_task:Cancel()
        end
        reset_task = TheWorld:DoTaskInTime(time, function()
            current_level = nil
            reset_task = nil
        end)
    end

    for attacker in pairs(hounded_warning) do
        for i = 1, 4 do
            local level = tostring(i)
            AddPrefabPostInit(attacker .. "warning_lvl" .. level, function(inst)
                -- 按预警等级上限估算：1→120秒，2→90秒，3→60秒，4→30秒
                if not current_level or current_level < i then
                    current_level = i
                    local initial_time = (5 - i) * 30
                    SaveTextData("hounded", "", true)
                    SaveTimeData("hounded", initial_time)
                    -- 袭击后复位；即使漏收后续等级，也不会阻塞下一轮预警
                    ResetWarningAfter(initial_time + 30)
                end
            end)
        end
    end

    AddPrefabPostInit("wormwarning_worm_boss", function(inst) -- 巨大洞穴蠕虫预警实体
        if current_level == 5 then
            -- 卡顿时预警可能持续超过本地倒计时，延后清理以免把同一轮当成新一轮
            ResetWarningAfter(150)
            return
        end
        current_level = 5
        local durations = GetWormBossDurations() -- 世界设置与生存天数范围允许的时长候选
        local initial_time = durations[#durations] -- 无法确定档位时采用最大倒计时值
        local formats = STRINGS.eventtimer.hounded.cooldowns
        local format = #durations == 1 and formats.worm_boss or formats.worm_boss_uncertain -- 巨大洞穴蠕虫的确定或上限文案
        SaveTextData("hounded", string.format(ReplacePrefabName(format), TimeToString(initial_time)), true)
        SaveTimeData("hounded", initial_time)
        ResetWarningAfter(initial_time + 30)
    end)

    AddPrefabPostInit("worm_boss", function(inst) -- 巨大洞穴蠕虫
        local data = ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData
        -- 只提前结束本轮预测；自然倒计时已进入攻击提示阶段时不重复提醒
        if current_level ~= 5 or not data or data.hounded_time <= 0 then return end
        -- 先清零，令tipsfn返回false以复位提示缓存，再触发一次攻击提示
        local should_tip = data.hounded_time > 1 -- 归零前记录是否尚未自然发出攻击提示
        SaveTimeData("hounded", 0)
        need_tips = should_tip
        SaveTextData("hounded", "", true)
    end)
end

----------------------------------------------------------------------------------------------

local next_wave_is_wormboss, _wave_override_chance
local remotegettextfn = function(Thread)
    if not TheWorld:HasTag("cave") then return end
    local cmd = [[
        local self = TheWorld.components.hounded
        if not self then return DataDumper({ not_found = true })end

        local next_wave_is_wormboss = BBGOAT_FN.getval(self.DoWarningSpeech, "_wave_pre_upgraded")
        local data = self:OnSave()
        local settings = BBGOAT_FN.getval(self.SetWaveOverrideSettings, "_wave_override_settings") or {}
        local setting = settings.worm_boss or 1
        local tracker = TheWorld.components.atriumritualorgantracker
        local _wave_override_chance = data.wave_override_chance or 0

        if setting == 0 then
            _wave_override_chance = 0
        elseif setting == 9999 or data.wave_upgraded_record or
            (tracker and tracker:NeedsRitualOrgan("atrium_ritual_organ_worm")) then
            _wave_override_chance = 1
        else
            _wave_override_chance = math.max(0, math.min(1, _wave_override_chance * setting))
        end

        return DataDumper({next_wave_is_wormboss = next_wave_is_wormboss, _wave_override_chance = _wave_override_chance})
    ]]

    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.err then
            SaveTextData("hounded", "")
            print('[警告] hounded remotegettextfn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res and res.not_found then
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res then
            next_wave_is_wormboss = res.next_wave_is_wormboss
            _wave_override_chance = res._wave_override_chance
            if next_wave_is_wormboss then
                local str = string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss), TimeToString(ThePlayer.HUD.WarningEventTimeData.hounded_time))
                SaveTextData("hounded", str, true)
            elseif checknumber(_wave_override_chance) and _wave_override_chance > 0 then
                local str = string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.worm_boss_chance), TimeToString(ThePlayer.HUD.WarningEventTimeData.hounded_time), _wave_override_chance * 100)
                SaveTextData("hounded", str, true)
            else
                SaveTextData("hounded", "", true)
            end
        end
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    localgettimefn = localgettimefn,
    remotegettimefn = function(Thread)
        local cmd = [[
            local self = TheWorld.components.hounded
            if not self then return DataDumper({ not_found = true }) end

            local _spawnmode = BBGOAT_FN.getval(self.OnUpdate, "_spawnmode")
            if _spawnmode == "never" then
                return DataDumper({ not_found = true })
            end
        
            local data = self:OnSave()
            local time = data and data.timetoattack
            if time then
                return DataDumper({ time = time })
            else
                return DataDumper({ not_found = true })
            end
        ]]
        BBGOAT_util:remote(cmd, nil, function(res)
            if res and res.err then
                SaveTimeData("hounded", 0)
                print('[警告] hounded remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("hounded", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
    remotegettextfn = remotegettextfn,
    DisableSaveTime = true, -- 不同世界都有这个事件，保存了会数据冲突
    imagechangefn = function(self)
        local text = ThePlayer.HUD.WarningEventTimeData.hounded_text
        local is_worm_boss = IsWormBossText(text)
        local worldtype = GetWorldtypeStr()
        if worldtype == "porkland" then
            self.image = nil
        elseif worldtype == "shipwrecked" or worldtype == "volcano" then
            self.image = self.islandimage
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
    animchangefn = HoundedAnimChange,
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
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.hounded_time
        local text = ThePlayer.HUD.WarningEventTimeData.hounded_text
        local is_worm_boss = IsWormBossText(text)
        return (is_worm_boss and text) or (time > 0 and string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns[GetWorldtypeStr()]), TimeToString(time)))
    end,
    tipsfn = function()
        if need_tips then
            need_tips = false
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.hounded.attack.worm_boss)), 10, nil, 3
        end
        local time = ThePlayer.HUD.WarningEventTimeData.hounded_time
        local text = ThePlayer.HUD.WarningEventTimeData.hounded_text
        local is_worm_boss = IsWormBossText(text)

        if time > 2 and time <= 120 then
            return true, info.announcefn, time, nil, 2
        elseif JustEntered(time) and time < 960 then
            return true, info.announcefn, 10, nil, 2
        elseif JustEntered(time) then
            return true, info.announcefn, 10, nil, 1
        elseif ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.hounded.attack[is_worm_boss and "worm_boss" or GetWorldtypeStr()])), 10, time, 3
        end
        return false
    end
}

return info
