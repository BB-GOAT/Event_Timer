local AddClassPostConstruct = AddClassPostConstruct
local TimeToString = TimeToString
local RW_Data = RW_Data
local env = env
GLOBAL.setfenv(1, GLOBAL)

local WarningEvent = require("widgets/warningevent")
local WarningTips = require("widgets/warningtips")
local TarnsferPanel = require("widgets/WarningEventPanel")
local Widget = require("widgets/widget")
local game_ready = false
local last_tips_cache = {} -- 记录事件是否提示过（如果保存在ThePlayer.HUD里 换人时会丢数据）


local world_type_list = {
    [STRINGS.eventtimer.worldtype.forest] = "forest",
    [STRINGS.eventtimer.worldtype.cave] = "cave",
    [STRINGS.eventtimer.worldtype.shipwrecked] = "shipwrecked",
    [STRINGS.eventtimer.worldtype.volcano] = "volcano",
    [STRINGS.eventtimer.worldtype.porkland] = "porkland",
    [STRINGS.eventtimer.worldtype.unknown] = "unknown",
}

local function GetShardInfo(shardid) -- 根据世界ID获取世界类型和名称
    local world_list = EventTimer.WorldList or {}
    local world_str = world_list[shardid] or STRINGS.eventtimer.worldtype.unknown
    local world_type = world_type_list[world_str] or "unknown"
    return world_type, world_str
end

local function AddWarningEvents(self)
    self.inst:DoTaskInTime(2,function()
        game_ready = true
    end)

    local warningtips_root = self:AddChild(Widget("WarningTipsResolutionRoot"))
    warningtips_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    warningtips_root:SetHAnchor(ANCHOR_LEFT)
    warningtips_root:SetVAnchor(ANCHOR_TOP)
    warningtips_root:SetClickable(false)

    local warningtips_design_root = warningtips_root:AddChild(Widget("WarningTipsDesignRoot"))
    warningtips_design_root:SetScale(2/3) -- SCALEMODE_PROPORTIONAL以1280x720为基准，乘以2/3后转为1920x1080设计坐标。
    warningtips_design_root:SetClickable(false)

    local warningtips_messages = {}
    local function sort_message()
        for i, msg in ipairs(warningtips_messages) do
            local w, h = msg:GetTextSize() -- 获取完整消息文字区域大小
            if w and h then
                msg.target_x = w + 40

                if i > 1 then -- 其它消息，依次根据上个消息的位置调整坐标
                    local up_y = warningtips_messages[i - 1].target_y
                    local up_w, up_h = warningtips_messages[i - 1]:GetTextSize()
                    msg.target_y = up_y - up_h - h - 50
                else
                    msg.target_y = msg.base_y -- 第一条消息，Y轴设为基础坐标
                end

                msg:SetMoveTarget(msg.target_x, msg.target_y)
            end
        end
    end

    local function remove_message(message)
        if message.removing then return end
        message.removing = true

        if message.remove_task then -- 取消自动销毁任务，避免重复清理
            message.remove_task:Cancel()
            message.remove_task = nil
        end

        message:FadeOut()

        message.inst:DoTaskInTime(1, function()
            message:Kill()

            for i = #warningtips_messages, 1, -1 do
                if warningtips_messages[i] == message then
                    table.remove(warningtips_messages, i)
                    break
                end
            end

            sort_message()
        end)
    end

    -- 醒目提示
    function self:ShowTips(timefn, second, level, context)
        if type(timefn) ~= "function" then return end

        local text = timefn(context)
        if type(text) ~= "string" or text == "" then return end

        warningtips_root:MoveToFront()
        local message = warningtips_design_root:AddChild(WarningTips(text, level)) -- 创建新的提示控件

        -- 新消息置顶，旧消息由 sort_message 重排到下方
        table.insert(warningtips_messages, 1, message)
        sort_message()

        -- 启动定时器
        message.inst:DoPeriodicTask(0.5, function() -- 更新倒计时时间
            if not message:SetText(timefn(context)) then
                remove_message(message)
                return
            end

            sort_message() -- 整理所有消息
        end)

        -- 定时销毁与整理其它消息
        message.remove_task = TheWorld:DoTaskInTime((second or 10), function()
            message.remove_task = nil
            remove_message(message)
        end)
    end

    ---------------------------------------------------------------------------------------------------------------

    -- 屏幕左上角倒计时
    local warningevents_root = self:AddChild(Widget("WarningEventsResolutionRoot"))
    warningevents_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    warningevents_root:SetHAnchor(ANCHOR_LEFT)
    warningevents_root:SetVAnchor(ANCHOR_TOP)
    warningevents_root:SetClickable(false)

    local warningevents_design_root = warningevents_root:AddChild(Widget("WarningEventsDesignRoot"))
    warningevents_design_root:SetScale(2/3) -- SCALEMODE_PROPORTIONAL以1280x720为基准，乘以2/3后转为1920x1080设计坐标。
    warningevents_design_root:SetClickable(false)

    local eventsdata
    local Panel_data_list = {}
    local context_cache = {}
    local panel_data_cache = {}
    local panel_data_snapshot = {}
    local panel_data_revision = 0
    TarnsferPanel.UpdateDestItem = function(self)
        -- TrueScrollList:SetItemsData 会重新应用所有可见行，仅在面板数据实际变化时刷新。
        if self._event_timer_panel_data_revision ~= panel_data_revision then
            self.scrollpanel:SetItemsData(Panel_data_list) -- 面板数据
            self._event_timer_panel_data_revision = panel_data_revision
        end
    end

    function self:UpdateWarningEvents()
        if not eventsdata then
            eventsdata = self.WarningEventTimeData -- 由RPC.lua提供
            if not eventsdata then return end
        end

        local i = 0
        local panel_count = 0
        local line_num = 2
        local scale = TheFrontEnd:GetProportionalHUDScale()
        for warningevent, data_list in pairs(eventsdata) do
            local data = WarningEvents[warningevent]
            for shard_id in pairs(data_list) do
                local row = math.floor(i/line_num)
                local line = i - row * line_num
                local x = (row * 150 + 80) * scale
                local y = (-line * 70 - 30) * scale
                local warningevent_child = warningevent .. "_" .. shard_id

                if not self[warningevent_child] then
                    self[warningevent_child] = warningevents_design_root:AddChild(WarningEvent(data.anim, data.image))
                    self[warningevent_child]:Hide()
                    self[warningevent_child].force = RW_Data:GetValue(warningevent) -- 读取存储的数据来决定是否显示计时器在屏幕左上角
                end

                self[warningevent_child]:SetScale(scale)
                self[warningevent_child]:SetPosition(x, y, 0)
                local time = eventsdata[warningevent][shard_id].time or 0

                local world_type, world_str = GetShardInfo(shard_id)
                local context = context_cache[warningevent_child]
                if not context then
                    context = setmetatable( -- 传入给事件模块的信息
                        {
                            shard_id = shard_id, -- 事件所处世界ID
                        },
                        {
                            __index = function(t, key)
                                return eventsdata[warningevent][shard_id][key] -- time 和 text 在这里获取
                            end
                        }
                    )
                    context_cache[warningevent_child] = context
                end
                context.world_type = world_type
                context.world_str = world_str
                context.warningevent_child = self[warningevent_child]

                if data.gettimefn or data.playerly then
                    -- 每轮新计时更新一次anim或image
                    if not self[warningevent_child].last_time or (time > self[warningevent_child].last_time) or (math.abs(time - self[warningevent_child].last_time) > 10) then
                        -- 2种图片都更新，万一前面的更新没了还能有后面的补上
                        if data.animchangefn then
                            data:animchangefn(context)
                        end
                        if data.imagechangefn then
                            data:imagechangefn(context)
                        end
                        self[warningevent_child]:RefreshAnimImage(data.anim, data.image)
                    end
                    self[warningevent_child].last_time = time

                    if not self[warningevent_child].force or (time == 0) then
                        if self[warningevent_child].shown then
                            self[warningevent_child]:Hide()
                        end
                    else
                        if not self[warningevent_child].shown then
                            self[warningevent_child]:Show()
                        end
                        self[warningevent_child]:OnUpdate(time)
                        i = i + 1
                    end
                end

                if data.tipsfn and game_ready and EventTimer.TimerTips then
                    local need_tips, tipstextfn, tipstime, delay, level = data.tipsfn(context) -- 加载事件列表的tips函数
                    last_tips_cache[warningevent_child] = last_tips_cache[warningevent_child] or false
                    if need_tips and not last_tips_cache[warningevent_child] then
                        last_tips_cache[warningevent_child] = true
                        if delay and TheWorld then
                            TheWorld:DoTaskInTime(delay, function() -- 延迟提示
                                self:ShowTips(tipstextfn, tipstime, level, context)
                            end)
                        elseif TheWorld then
                            self:ShowTips(tipstextfn, tipstime, level, context)
                        end
                    elseif not need_tips then
                        last_tips_cache[warningevent_child] = false
                    end
                end

                -- 更新面板数据
                local text = eventsdata[warningevent][shard_id].text or ""
                local panel_text
                if type(text) == "string" and text ~= "" then
                    panel_text = text
                elseif type(time) == "number" and time > 0 then
                    panel_text = TimeToString(time)
                end
                if panel_text then
                    local tmp_data = panel_data_cache[warningevent_child]
                    if not tmp_data then
                        tmp_data = setmetatable(
                            {
                                name = warningevent, -- 事件名称
                                context = context
                            },
                            {
                                __index = function(t, k)
                                    return context[k] or WarningEvents[warningevent][k]
                                end,
                                __newindex = function(t, k, v)
                                    if k == "text" then
                                        rawset(t, k, v)
                                    else
                                        rawset(WarningEvents[warningevent], k, v)
                                    end
                                end
                            }
                        )
                        panel_data_cache[warningevent_child] = tmp_data
                    end
                    tmp_data.text = panel_text
                    panel_count = panel_count + 1
                    Panel_data_list[panel_count] = tmp_data
                end

            end
        end
        -- 原地更新列表，移除本轮不再显示的尾部条目，避免残留或重复。
        for index = #Panel_data_list, panel_count + 1, -1 do
            Panel_data_list[index] = nil
        end

        -- 面板数据表会原地复用，不能直接比较表地址；只记录会影响行显示的字段。
        local panel_data_changed = #panel_data_snapshot ~= panel_count
        if not panel_data_changed then
            for index = 1, panel_count do
                local data = Panel_data_list[index]
                local snapshot = panel_data_snapshot[index]
                if not snapshot
                    or snapshot.data ~= data
                    or snapshot.text ~= data.text
                    or snapshot.image ~= data.image
                    or snapshot.anim ~= data.anim
                    or snapshot.nobackground ~= data.nobackground
                    or snapshot.has_time ~= (data.time and data.time > 0)
                    or snapshot.force ~= (data.name and self[data.name .. "_" .. data.context.shard_id] and self[data.name .. "_" .. data.context.shard_id].force)
                then
                    panel_data_changed = true
                    break
                end
            end
        end

        if panel_data_changed then
            for index = 1, panel_count do
                local data = Panel_data_list[index]
                local warningevent_child = data.name .. "_" .. data.context.shard_id
                local child = self[warningevent_child]
                panel_data_snapshot[index] = {
                    data = data,
                    text = data.text,
                    image = data.image,
                    anim = data.anim,
                    nobackground = data.nobackground,
                    has_time = data.time and data.time > 0,
                    force = child and child.force,
                }
            end
            for index = panel_count + 1, #panel_data_snapshot do
                panel_data_snapshot[index] = nil
            end
            panel_data_revision = panel_data_revision + 1
        end
    end
end

AddClassPostConstruct("screens/playerhud", AddWarningEvents)

---------------------------------------------------------------------------------------------------------------

local UIAnimButton = require("widgets/uianimbutton")
local Button = require("widgets/button")
local EventUIButton = Class(Button, function(self, owner)
    Button._ctor(self)
    self.owner = owner

    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self:SetVAnchor(ANCHOR_RIGHT)
    self:SetHAnchor(ANCHOR_BOTTOM)

    -- 在屏幕添加一个按钮，用来触发面板的显示与关闭
    self.openbutton = self:AddChild(UIAnimButton("pocketwatch","pocketwatch_marble","cooldown_long"))

    -- 设置位置
    local data_pos = RW_Data:GetValue("pos")
    if data_pos and data_pos.x and data_pos.y then
        self.openbutton:SetPosition(data_pos.x, data_pos.y, 0)
    else
        self.openbutton:SetPosition(-55, 200, 0)
    end
    self.openbutton:SetFocusAnim("cooldown_long", true) -- 设置鼠标对准时播放的动画
    self.openbutton.animstate:Pause() -- 默认暂停动画
    self.openbutton:SetScale(0.3, 0.3) -- 设置缩放比
    self.openbutton:SetHoverText(STRINGS.eventtimer.ui_desc, { offset_y = 70 })
    self.openbutton.hovertext:SetScale(0.9, 0.9) -- 重新设置提示大小
    self.openbutton.onclick = function()
        self:ToggleEventTimerUI()
    end

    self.openbutton.OnControl = self.OnControl -- 将UIAnimButton的OnControl 改为 Button的OnControl

    -- 鼠标对准时播放动画
    self.openbutton:SetOnFocus(function()
        self.openbutton.animstate:Resume()
    end)

    -- 鼠标离开时暂停动画
    self.openbutton:SetOnLoseFocus(function()
        self.openbutton.animstate:Pause()
    end)


    -- 鼠标右键拖拽
    self.openbutton.OnMouseButton = function(_self, button, down, x, y)
        if button == MOUSEBUTTON_RIGHT and down then
            _self:BBGoat_FollowMouse()
            _self.hovertext_root:Hide()
            _self.hovertext:Hide()
        elseif button == MOUSEBUTTON_RIGHT then
            _self:StopFollowMouse()
            local pos = _self:GetPosition()
            local world_pos = _self:GetWorldPosition()

            _self.hovertext_root:Show()
            _self.hovertext_root:SetPosition(world_pos.x, world_pos.y + 70)
            _self.hovertext:Show()

            data_pos = { x = pos.x, y = pos.y}
            RW_Data:SetValue("pos", data_pos)
            RW_Data:Save()
        end
    end

    self:Refresh()
end)

-- 开关面板
function EventUIButton:ToggleEventTimerUI()
    if self.eventui then
        self.eventui:Close()
        self.eventui = nil
    else
        self.eventui = self.owner:AddChild(TarnsferPanel(self.owner))
    end
end

-- 刷新UI按钮显示状态
function EventUIButton:Refresh()
    if EventTimer.UIButton ~= "always" then
        self.openbutton:Hide()
    else
        self.openbutton:Show()
    end
end

AddClassPostConstruct("screens/playerhud", function(self)
    self.EventTimerButton = self:AddChild(EventUIButton(self))
end)

-- 为暂停页面添加按钮
AddClassPostConstruct("screens/redux/pausescreen", function(self)
    local EventUIButton = self.menu:AddChild(UIAnimButton("pocketwatch","pocketwatch_marble","cooldown_long"))

    EventUIButton:SetFocusAnim("cooldown_long", true) -- 设置鼠标对准时播放的动画
    EventUIButton.animstate:Pause()
    EventUIButton:SetScale(0.5)

    EventUIButton:SetClickable(true)
    EventUIButton.onclick = function()
        if not ThePlayer then return end
        self:unpause()
        ThePlayer.HUD.EventTimerButton:ToggleEventTimerUI()
    end

    EventUIButton.OnControl = Button.OnControl -- 将UIAnimButton的OnControl 改为 Button的OnControl

    EventUIButton:SetHoverText(STRINGS.LMB .. STRINGS.eventtimer.ui_title, { offset_y = 70 })
    EventUIButton:SetPosition(-RESOLUTION_X * 0.17, -RESOLUTION_Y * 0.35, 0)

    -- 鼠标对准时播放动画
    EventUIButton:SetOnFocus(function()
        EventUIButton.animstate:Resume()
    end)

    -- 鼠标离开时暂停动画
    EventUIButton:SetOnLoseFocus(function()
        EventUIButton.animstate:Pause()
    end)

    if EventTimer.UIButton == "pause_screen" then
        EventUIButton:Show()
    else
        EventUIButton:Hide()
    end
end)

local function canactive()
    local ActiveScreen = TheFrontEnd and TheFrontEnd:GetActiveScreen()
    if not ActiveScreen then return false end
    if not (ActiveScreen.IsEditing and ActiveScreen:IsEditing()) then
        return true
    end
    return false
end

-- 使用快捷键开关计时器面板
local down_handler = nil -- 按键事件处理器
env.KeyBind = function(_, key)
  -- 禁用旧绑定
  if down_handler then down_handler:Remove() end

  -- 新建绑定或无绑定
  local function f(_key, down)
    return (_key == key and down ) and canactive() and ThePlayer and ThePlayer.HUD.EventTimerButton:ToggleEventTimerUI()
  end

  down_handler = key and (key >= 1000 and TheInput:AddMouseButtonHandler(f) or TheInput:AddKeyHandler(f) or nil)
end