local AddClassPostConstruct = AddClassPostConstruct
local AddPrefabPostInit = AddPrefabPostInit
local GetWorldtypeStr = GetWorldtypeStr
local GetModenv = GetModenv
local Ismodloaded = Ismodloaded
local SaveTimeData = SaveTimeData
local SaveTextData = SaveTextData
local TimeToString = TimeToString
local ReplacePrefabName = ReplacePrefabName
local CombineLines = CombineLines
local ModLanguage = ModLanguage
local zh = ModLanguage == "zh"
local Import = Import
local MOD_util = MOD_util
local RW_Data = RW_Data
local Upvaluehelper = Upvaluehelper
GLOBAL.setfenv(1, GLOBAL)
local GetTimeFromRemoteCommand = EventTimer.GetTimeFromRemoteCommand

-- [Tips]提示猎狗和BOSS的攻击时间 / [Tips]刷新提示，优化版
if Ismodloaded("workshop-1898292532") or Ismodloaded("workshop-3059131690") then
    local modid = Ismodloaded("workshop-1898292532") and "workshop-1898292532" or "workshop-3059131690"
    local events = Ismodloaded("workshop-1898292532") and {
        hound = "hounded", -- 猎犬/蠕虫/鳄狗
        prime_mate = "piratespawner", -- 海盗袭击
        deerclops = "deerclopsspawner", -- 独眼巨鹿
        antlion = "sinkholespawner", -- 蚁狮
        bearger = "beargerspawner", -- 熊獾
        klaus_sack = "klaussackspawner", -- 赃物袋
        malbatross = "malbatrossspawner", -- 邪天翁
        toadstool = "toadstoolspawner", -- 毒菌蟾蜍
        crabking = "crabkingspawner", -- 帝王蟹
        dragonfly = "dragonfly_spawner", -- 龙蝇
        atrium_gate = "atrium_gate", -- 远古大门
        beequeenhive = "beequeenhive", -- 蜂后
        -- lunarrift_portal = "lunar_riftspawner" or "shadow_riftspawner", -- 月亮/暗影裂隙生成倒计时，另外处理
        daywalker = "daywalkerspawner", -- 梦魇疯猪
        daywalker2 = "forestdaywalkerspawner", -- 拾荒疯猪
        -- wagboss_robot = "" -- 老版本：战争瓦器人刷新倒计时
    } or Ismodloaded("workshop-3059131690") and {
        hound = "hounded", -- 猎犬/蠕虫/鳄狗
        prime_mate = "piratespawner", -- 海盗袭击
        deerclops = "deerclopsspawner", -- 独眼巨鹿
        antlion = "sinkholespawner", -- 蚁狮
        bearger = "beargerspawner", -- 熊獾
        klaus_sack = "klaussackspawner", -- 赃物袋
        malbatross = "malbatrossspawner", -- 邪天翁
        toadstool = "toadstoolspawner", -- 毒菌蟾蜍
        crabking = "crabkingspawner", -- 帝王蟹
        dragonfly = "dragonfly_spawner", -- 龙蝇
        atrium_gate = "atrium_gate", -- 远古大门
        beequeenhive = "beequeenhive", -- 蜂后
    }

    local autotipslist = GetModenv(modid) and GetModenv(modid).autotipslist
    -- 关掉TIPS模组的左上角UI
    AddPrefabPostInit("world", function(inst)
        if not autotipslist then return end
        local tips_method = _G.GetModConfigData("tips_method", modid)
        if tips_method == 1 then
            for task in pairs(inst.pendingtasks) do
                if task.fn then
                    local info = debug.getinfo(task.fn)
                    if info.source:find("mods/workshop%-1898292532/client.lua") or info.source:find("mods/workshop%-3059131690/client.lua") then
                        -- 隐藏原模组的UI
                        local _controls = Upvaluehelper.GetUpvalue(task.fn, "_controls")
                        if _controls then
                            for _,v in ipairs(autotipslist) do
                                if _controls[v] then
                                    _controls[v]:Hide()
                                end
                            end
                        end
                        task:Cancel() -- 取消原模组的每秒一次刷新UI

                        break
                    end
                end
            end
        end
    end)

    -- 初始化GetTimeFromServerMod表 (优化版tips数据更新慢的可怜，不阻止本模组自己也获取一份数据)
    if autotipslist and modid == "workshop-1898292532" then
        for i, name in ipairs(autotipslist) do
            if events[name] then
                EventTimer.GetTimeFromServerMod[events[name]] = true
            elseif name == "lunarrift_portal" then -- 月亮/暗影裂隙
                EventTimer.GetTimeFromServerMod["lunarrift_portal"] = true
                EventTimer.GetTimeFromServerMod["shadow_riftspawner"] = true
            end
        end
    end

    -- 监听TIPS模组提供的数据
    MOD_util:AddPlayerPostInit(function(world, player)
        if player ~= ThePlayer then return end
        if not player.components.tips then return end
        player.components.tips.inst:ListenForEvent("tipsevent", function()
            local autolist = player.components.tips and player.components.tips.json and player.components.tips.json.autolist or {}
            for name, data in pairs(autolist) do
                if events[name] and data.time then
                    SaveTimeData(events[name], data.time)
                elseif name == "lunarrift_portal" and data.time then
                    local event_name = TheWorld.worldprefab == "cave" and "shadow_riftspawner" or "lunar_riftspawner"
                    SaveTimeData(event_name, data.time)
                end
            end
        end)
    end)
end

-- 饥饥事件计时器
if Ismodloaded("workshop-3511498282") then
    -- 关闭饥饥事件计时器的模组UI
    AddClassPostConstruct("widgets/controls", function()
        if ThePlayer.HUD and ThePlayer.HUD.timebox then
            ThePlayer.HUD.timebox:Hide()
        end
    end)

    -- 事件列表
    local events = {
        hound = "hounded", -- 猎犬/蠕虫/鳄狗
        deerclops_timetoattack = "deerclopsspawner", -- 独眼巨鹿
        klaussack_spawntimer = "klaussackspawner", -- 赃物袋
        rage = "sinkholespawner", -- 蚁狮
        bearger_timetospawn = "beargerspawner", -- 熊獾
        dragonfly_spawner = "dragonfly_spawner", -- 龙蝇
        beequeen = "beequeenhive", -- 蜂后
        regen_crabking = "crabkingspawner", -- 帝王蟹
        lordfruitfly_spawntime = "farming_manager", -- 果蝇王
        piratespawner = "piratespawner", -- 海盗袭击
        forestdaywalkerspawner = "forestdaywalkerspawner", -- 拾荒疯猪
        -- 致命亮茄 另外处理
        -- 裂隙生成倒计时 另外处理
        daywalkerspawner = "daywalkerspawner", -- 梦魇疯猪生成倒计时
        shadowthrall = "shadowthrallmanager", -- 梦魇裂隙/墨荒
        toadstool_respawntask = "toadstoolspawner", -- 毒菌蟾蜍
        -- 远古大门 另外处理
        quaker = "quaker", -- 地震
    }

    -- 初始化GetTimeFromServerMod表
    for _, name in pairs(events) do
        EventTimer.GetTimeFromServerMod[name] = true
    end
    EventTimer.GetTimeFromServerMod["lunarthrall_plantspawner"] = true -- 致命亮茄
    EventTimer.GetTimeFromServerMod["lunar_riftspawner"] = true -- 月亮裂隙
    EventTimer.GetTimeFromServerMod["shadow_riftspawner"] = true -- 暗影裂隙
    EventTimer.GetTimeFromServerMod["atrium_gate"] = true -- 远古大门

    -- 检查数据有效性
    local valid_data = {}
    local check_data_valid = function(name, time)
        if not name then return end
        if not valid_data[name] then
            valid_data[name] = {
                time_last = 0, -- 上次记录的时间
                time_sametick = 0, -- 重复次数
                time_valid = false, -- 数据是否有效(这个字段用于防止一直触发time = 0)
            }
        end

        if not time or time == 0 or valid_data[name].time_last == time then
            valid_data[name].time_sametick = valid_data[name].time_sametick + 1
        else
            valid_data[name].time_sametick = 0
        end
        valid_data[name].time_last = time

        if valid_data[name].time_sametick > math.ceil(2 / TUNING.SYNC) then -- 数据过期
            if valid_data[name].time_valid then
                valid_data[name].time_valid = false
                return false
            end
        else -- 数据有效
            valid_data[name].time_valid = true
            return true
        end
    end

    -- 获取裂隙类型
    local rift_type
    local function get_rift_type()
        if TheWorld then
            rift_type = GetWorldtypeStr() == "cave" and "shadow_riftspawner" or "lunar_riftspawner"
        end
        return rift_type
    end

    -- 亮茄相关事件
    local lunarthrall_plantspawner_events = {
        lunarthrall_plantspawner_wave = "waves_to_release", -- 剩余波次
        lunarthrall_plantspawner_next = "_nextspawn", -- 下一波
        lunarthrall_plantspawner_spawn = "_spawntask", -- 波次刷新
    }

    -- 远古大门相关事件
    local atrium_gate_events = {
        cooldown = 1,
        destabilizing = 2,
    }

    -- 处理RPC数据
    local function ReFresh(list)
        for _, item in pairs(list) do
            if events[item.name] then -- 通用
                if check_data_valid(item.name, item.time) then
                    SaveTimeData(events[item.name], item.time)
                else
                    SaveTimeData(events[item.name], 0)
                end
            elseif item.name == "rift_spawn_timer" then -- 裂隙
                local event_name = rift_type or get_rift_type()
                if check_data_valid(event_name, item.time) then
                    SaveTimeData(event_name, item.time)
                end
            elseif lunarthrall_plantspawner_events[item.name] then -- 亮茄
                if item.name == "lunarthrall_plantspawner_wave" or check_data_valid(item.name, item.time) then
                    lunarthrall_plantspawner_events[lunarthrall_plantspawner_events[item.name]] = item.time
                else
                    lunarthrall_plantspawner_events[lunarthrall_plantspawner_events[item.name]] = nil
                end

                local nextspawn_str, spawntask_str, waves_to_release_str
                if lunarthrall_plantspawner_events._nextspawn then
                     nextspawn_str = string.format(STRINGS.eventtimer.lunarthrall_plantspawner.spawn, TimeToString(lunarthrall_plantspawner_events._nextspawn))
                elseif lunarthrall_plantspawner_events._spawntask then
                    spawntask_str = string.format(STRINGS.eventtimer.lunarthrall_plantspawner.next_wave, TimeToString(lunarthrall_plantspawner_events._spawntask))
                end
                if lunarthrall_plantspawner_events.waves_to_release and lunarthrall_plantspawner_events.waves_to_release > 0 then
                    waves_to_release_str = string.format(STRINGS.eventtimer.lunarthrall_plantspawner.remain_waves, lunarthrall_plantspawner_events.waves_to_release)
                end

                SaveTextData("lunarthrall_plantspawner", CombineLines(nextspawn_str, spawntask_str, waves_to_release_str))
            elseif atrium_gate_events[item.name] then -- 远古大门
                if check_data_valid(item.name, item.time) then
                    local cooldown_mode = atrium_gate_events[item.name]
                    SaveTimeData("atrium_gate", item.time)
                    SaveTextData("atrium_gate",
                        cooldown_mode == 1 and string.format(ReplacePrefabName(STRINGS.eventtimer.atrium_gate.cooldown), TimeToString(item.time)) or
                        cooldown_mode == 2 and string.format(STRINGS.eventtimer.atrium_gate.destabilizing, TimeToString(item.time))
                    )
                else
                    atrium_gate_events[item.name] = nil
                    SaveTimeData("atrium_gate", 0)
                    SaveTextData("atrium_gate", "")
                end
            end
        end
    end

    -- 修改饥饥事件计时器的CLIENT_MOD_RPC_HANDLER
    if CLIENT_MOD_RPC.tips and CLIENT_MOD_RPC.tips.timer and CLIENT_MOD_RPC.tips.timer.id then
        local id = CLIENT_MOD_RPC.tips.timer.id
        local old_handler = CLIENT_MOD_RPC_HANDLERS["tips"][id]
        CLIENT_MOD_RPC_HANDLERS["tips"][id] = function(player, data, ...)
            old_handler(player, data, ...)
            data = json.decode(data)
            if type(data) == "table" then
                ReFresh(data)
            end
        end
    end
end

-- Boss预测器
if Ismodloaded("workshop-2510473186") then

    -- 关闭Boss预测器的模组UI
    AddClassPostConstruct("widgets/controls", function(hud)
        if hud.houndswidget then
            hud.houndswidget:Hide()
        end
        if hud.bosseswidget then
            hud.bosseswidget:Hide()
        end
        if hud.riftswidget then
            hud.riftswidget:Hide()
        end
    end)

    local bosses_table = Import(MODS_ROOT .. "workshop-2510473186/main/tables/bosses.lua", GetModenv("workshop-2510473186"))
    -- 事件列表
    local events = {
        bearger           = "beargerspawner",      -- 熊獾
        deerclops         = "deerclopsspawner",    -- 独眼巨鹿
        klaus             = "klaussackspawner",    -- 赃物袋
        fruitfly          = "farming_manager",     -- 果蝇王
        malbatross        = "malbatrossspawner",   -- 邪天翁
        toadstool         = "toadstoolspawner",    -- 毒菌蟾蜍
        antlion           = "sinkholespawner",     -- 蚁狮
        beequeenhive      = "beequeenhive",        -- 蜂后
        dragonfly_spawner = "dragonfly_spawner",   -- 龙蝇
        crabking_spawner  = "crabkingspawner",     -- 帝王蟹
        nightmare_werepig = "daywalkerspawner",    -- 梦魇疯猪
        scrappy_werepig   = "forestdaywalkerspawner" -- 拾荒疯猪
    }

    -- 远古大门相关事件
    local atrium_gate_events = {
        atrium_gate_cooldown = 1,
        atrium_gate_destable = 2,
    }

    -- 初始化GetTimeFromServerMod表
    for _, name in pairs(events) do
        EventTimer.GetTimeFromServerMod[name] = true
    end
    EventTimer.GetTimeFromServerMod["atrium_gate"] = true -- 远古大门
    EventTimer.GetTimeFromServerMod["lunarthrall_plantspawner"] = true -- 致命亮茄
    EventTimer.GetTimeFromServerMod["rift_portal"] = true -- 月亮裂隙信息
    EventTimer.GetTimeFromServerMod["lunar_riftspawner"] = true -- 月亮裂隙
    EventTimer.GetTimeFromServerMod["shadow_riftspawner"] = true -- 暗影裂隙

    -- 获取裂隙类型
    local riftspawner_type, rift_portal_type
    local function get_rift_type()
        local is_cave = GetWorldtypeStr() == "cave"
        riftspawner_type = is_cave and "shadow_riftspawner" or "lunar_riftspawner"
        rift_portal_type = is_cave and "shadowrift_portal" or "rift_portal"
    end

    local network_worlds = { "forest", "cave", "shipwrecked", "volcanoworld", "porkland" }
    for i, world in ipairs(network_worlds) do
        AddPrefabPostInit(world .. "_network", function(inst)
            inst:ListenForEvent("hound_time_to_attack_dirty", function(inst)
                SaveTimeData("hounded", inst.boss_attack_predictor.net_hound_time_to_attack:value()) -- 猎犬/洞穴蠕虫/鳄狗
            end)

            if bosses_table then
                for name in pairs(bosses_table.worldtimerkey) do
                    local time_to_attack_dirty = name .. "_time_to_attack_dirty"
                    local net_time_to_attack = "net_" .. name .. "_time_to_attack"
                    if events[name] then
                        inst:ListenForEvent(time_to_attack_dirty, function(inst)
                            local timeleft = inst.boss_attack_predictor[net_time_to_attack]:value()
                            if timeleft == nil or timeleft < 0 then
                                SaveTimeData(events[name], 0)
                            else
                                SaveTimeData(events[name], timeleft)
                            end
                        end)
                    elseif atrium_gate_events[name] then -- 远古大门
                        local cooldown_mode = atrium_gate_events[name]
                        inst:ListenForEvent(time_to_attack_dirty, function(inst)
                            local timeleft = inst.boss_attack_predictor[net_time_to_attack]:value()
                            if timeleft == nil or timeleft < 0 then
                                SaveTimeData("atrium_gate", 0)
                                SaveTextData("atrium_gate", "")
                            else
                                SaveTimeData("atrium_gate", timeleft)
                                SaveTextData("atrium_gate",
                                    cooldown_mode == 1 and string.format(ReplacePrefabName(STRINGS.eventtimer.atrium_gate.cooldown), TimeToString(timeleft)) or
                                    cooldown_mode == 2 and string.format(STRINGS.eventtimer.atrium_gate.destabilizing, TimeToString(timeleft))
                                )
                            end
                        end)
                    end
                end
            else
                MOD_util:Warning("Boss预测器模组的bosses_table获取失败")
            end

            -- 裂隙相关
            local rift_time_to_next_phase, rift_wave_left
            local rift_current_phase = 0 -- 裂隙阶段默认为0
            get_rift_type() -- 获取裂隙事件名

            -- 更新裂隙信息
            local function ReFreshRiftData()
                if rift_current_phase == 0 and rift_time_to_next_phase then
                    SaveTimeData(riftspawner_type, rift_time_to_next_phase) -- 裂隙生成倒计时
                    SaveTextData(rift_portal_type, "") -- 清空裂隙信息
                elseif rift_current_phase and rift_current_phase > 0 then
                    SaveTimeData(riftspawner_type, 0) -- 清空裂隙生成倒计时
                    -- 裂隙阶段信息
                    local stage_info = string.format(STRINGS.eventtimer.riftspawner.stage, rift_current_phase, TUNING.RIFT_LUNAR1_MAXSTAGE) -- 阶段信息，内容类似：阶段 1 / 3
                    if rift_time_to_next_phase then
                        if (rift_portal_type == "rift_portal" and rift_current_phase ~= TUNING.RIFT_LUNAR1_MAXSTAGE) or (rift_portal_type == "shadowrift_portal" and rift_current_phase ~= TUNING.RIFT_SHADOW1_MAXSTAGE) then
                            stage_info = stage_info .. ": " .. string.format(STRINGS.eventtimer.rift_portal.next_stage, TimeToString(rift_time_to_next_phase)) -- 补充信息：%s后进入下一阶段
                        elseif rift_portal_type == "shadowrift_portal" and rift_current_phase == TUNING.RIFT_SHADOW1_MAXSTAGE then
                            stage_info = stage_info .. ": " .. string.format(ReplacePrefabName(STRINGS.eventtimer.shadowrift_portal.close), TimeToString(rift_time_to_next_phase)) -- 暗影裂隙关闭倒计时
                        end
                    end
                    SaveTextData(rift_portal_type, stage_info)
                end
            end

            -- 更新亮茄信息
            local function ReFreshLunarThrallData()
                local remain_waves, next_wave
                if rift_wave_left then
                    remain_waves = string.format(STRINGS.eventtimer.lunarthrall_plantspawner.remain_waves, rift_wave_left)
                end
                if rift_current_phase == 3 and rift_time_to_next_phase then
                    next_wave = string.format(STRINGS.eventtimer.lunarthrall_plantspawner.next_wave, TimeToString(rift_time_to_next_phase))
                end
                SaveTextData("lunarthrall_plantspawner", CombineLines(next_wave, remain_waves) or "")
            end

            inst:ListenForEvent("rift_time_to_next_phase_dirty", function(inst) -- 监听裂隙距离下一阶段剩余时间/亮茄下一波入侵时间
                local timeleft = inst.boss_attack_predictor.net_rift_time_to_next_phase:value()
                if timeleft == nil or timeleft < 0 then
                    rift_time_to_next_phase = nil
                else
                    rift_time_to_next_phase = timeleft
                end
                ReFreshRiftData()
                ReFreshLunarThrallData()
            end)
            inst:ListenForEvent("rift_current_phase_dirty", function(inst) -- 监听裂隙当前阶段
                rift_current_phase = inst.boss_attack_predictor.net_rift_current_phase:value()
                ReFreshRiftData()
            end)
            inst:ListenForEvent("rift_wave_left_dirty", function(inst) -- 监听亮茄剩余波数
                local waveleft = inst.boss_attack_predictor.net_rift_wave_left:value()
                if waveleft == nil or waveleft < 0 then
                    rift_wave_left = nil
                else
                    rift_wave_left = waveleft
                end
                ReFreshLunarThrallData()
            end)
        end)
    end
end

----------------------------------------兼容萌萌的新的模组设置---------------------------------------

if TheNet:IsDedicated() then return end
if not rawget(_G, "MOD_util") then
    print("[全局事件计时器 - 客户端版] 未检测到玩家开启萌萌的新的【基础运行库】")
    return
end
local MOD_util = _G.MOD_util
if not MOD_util:CanAddSetting() then
    print("[全局事件计时器 - 客户端版] 未检测到玩家开启萌萌的新的【模组设置】")
	return
end

local function ChangeModConfig(name, saved)
    local config = KnownModIndex:LoadModConfigurationOptions(EventTimer.env.modname, true)
    for i,v in pairs(config) do
        if v.name == name then
            config[i].saved = saved
        end
    end

    KnownModIndex:SaveConfigurationOptions(function() end, EventTimer.env.modname, config, true)
end

local pagename = zh and "事件计时器" or "Events Timer"
local pageorder = 1
local buttonname = pagename
local pagetitle = zh and "全局事件计时器模组设置" or "Global Events Timer Config"
local enabledisableoption = {
    { text = zh and "开启" or "Enabled", data = true },
    { text = zh and "关闭" or "Disabled", data = false },
}
MOD_util:CreatePage(pagename, {
    title = pagetitle,
    buttondata = { name = buttonname },
    order = pageorder,
    all_options = {
        {
            description = zh and "客户端预测倒计时" or "Client Predicted Countdown", -- 名称
            key = "EventsTimer_ClientPrediction", -- 对应设置项
            default = true, -- 默认选项
            options = enabledisableoption, -- 选项列表
            onapplyfn = function()
                EventTimer.ClientPrediction = MOD_util:GetMOption("EventsTimer_ClientPrediction", true)
                ChangeModConfig("ClientPrediction", EventTimer.ClientPrediction)
            end
        },
        {
            description = zh and "醒目提示" or "Highlight Tips",
            key = "EventsTimer_ShowTips",
            default = true,
            options = enabledisableoption,
            onapplyfn = function()
                EventTimer.TimerTips = MOD_util:GetMOption("EventsTimer_ShowTips", true)
                ChangeModConfig("ShowTips", EventTimer.TimerTips)
            end
        },
        {
            description = zh and "UI开关何时显示" or "UI Button Visibility",
            key = "EventsTimer_UIButton",
            default = "always",
            options = {
                {text = zh and "始终显示" or "Always Visible", data = "always"},
                {text = zh and "在暂停页面显示" or "Pause Menu", data = "pause_screen"},
            },
            onapplyfn = function()
                EventTimer.UIButton = MOD_util:GetMOption("EventsTimer_UIButton", true)
                ChangeModConfig("UIButton", EventTimer.UIButton)

                if table.typecheckedgetfield(ThePlayer, "table","HUD", "EventTimerButton") then
                    ThePlayer.HUD.EventTimerButton:Refresh()
                end
            end
        },
        {
            description = zh and "重置计时器面板打开按钮位置" or "Reset timer panel open button position",
            onclickfn = function()
                if table.typecheckedgetfield(ThePlayer, "table","HUD", "EventTimerButton", "openbutton") and EventTimer.UIButton == "always" then
                    local x, y = -55, 200
                    ThePlayer.HUD.EventTimerButton.openbutton:SetPosition(x, y, 0)
                    RW_Data:SetValue("pos", nil) -- 删除记录也能恢复默认位置
                    RW_Data:Save()
                end
            end
        },
    }
}
)