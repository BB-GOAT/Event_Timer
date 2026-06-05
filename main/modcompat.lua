local AddPrefabPostInit = AddPrefabPostInit
-- local AddGamePostInit = AddGamePostInit
local GetModenv = GetModenv
local Ismodloaded = Ismodloaded
local SaveTimeData = SaveTimeData
local ModLanguage = ModLanguage
local zh = ModLanguage == "zh"
local RW_Data = RW_Data
local MOD_util = MOD_util
local Upvaluehelper = Upvaluehelper
GLOBAL.setfenv(1, GLOBAL)

-- [Tips]提示猎狗和BOSS的攻击时间
if Ismodloaded("workshop-1898292532") then
    local events = {
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
    }

    local autotipslist = GetModenv('workshop-1898292532') and GetModenv('workshop-1898292532').autotipslist
    -- 关掉TIPS模组的左上角UI
    AddPrefabPostInit("world", function(inst)
        if not autotipslist then return end
        local tips_method = _G.GetModConfigData("tips_method", "workshop-1898292532")
        if tips_method == 1 then
            for task in pairs(inst.pendingtasks) do
                if task.fn then
                    local info = debug.getinfo(task.fn)
                    if info.source:find("mods/workshop%-1898292532/client.lua") then
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

    -- 初始化GetTimeFromServerMod表
    if autotipslist then
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

----------------------------------------检测重复功能的模组---------------------------------------

-- local function checkmod()
--     local tips = zh and "[全局事件计时器] 检测到你开启了 %s 模组，与本模组功能重复，请关闭它" or "[Global Events Timer] Detected that you have enabled the %s mod, which has overlapping functions with this mod. Please disable it."

--     if Ismodloaded("workshop-3478447677") then
--         local text = string.format(tips, zh and "[Tips]提示系统(优化不卡顿版)" or "[Tips]提示系统(优化版)")
--         c_announce(text)
--     end

--     if Ismodloaded("workshop-3059131690") then
--         local text = string.format(tips, zh and "[Tips]刷新提示，优化版" or "Tips Optimized")
--         c_announce(text)
--     end

--     if Ismodloaded("workshop-3511498282") then
--         local text = string.format(tips, zh and "饥饥事件计时器" or "Don't Event Timer")
--         c_announce(text)
--     end

--     if Ismodloaded("workshop-3517520518") then
--         local text = string.format(tips, zh and "饥饥事件计时器加强" or "Don't Event Timer Plus")
--         c_announce(text)
--     end

--     if Ismodloaded("workshop-3127230863") then
--         local text = string.format(tips, zh and "Boss生成倒计时" or "Boss Spawn Countdown")
--         c_announce(text)
--     end

--     if Ismodloaded("workshop-2510473186") then
--         local text = string.format(tips, zh and "Boss预测器" or "Boss Attack Predictor")
--         c_announce(text)
--     end
-- end

----------------------------------------兼容萌萌的新的模组设置---------------------------------------

if not MOD_util:CanAddSetting() then
    print("[全局事件计时器] 未检测到玩家开启萌萌的新的【模组设置】")
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