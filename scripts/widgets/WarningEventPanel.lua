local RW_Data = EventTimer.env.RW_Data
local TimeToString = EventTimer.env.TimeToString

local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local UIAnim = require "widgets/uianim"

local WarningEventHUD = Class(Widget, function(self, owner)
    Widget._ctor(self, "WarningEventHUD")
    self.owner = owner
    self.isopen = true
    self:SetScaleMode(SCALEMODE_PROPORTIONAL) -- 等比缩放模式
    self:SetMaxPropUpscale(MAX_HUD_SCALE) -- 设置界面最大比例上限
    self:SetPosition(0, 0, 0) -- 设置坐标
    self:SetVAnchor(ANCHOR_MIDDLE) -- 垂直居中对齐
    self:SetHAnchor(ANCHOR_MIDDLE) -- 水平居中对齐

    self.scalingroot = self:AddChild(Widget("warningeventscalingroot"))
    self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())
    --监听从暂停状态恢复到继续状态，更新尺寸
    self.inst:ListenForEvent(
        "continuefrompause",
        function()
            if self.isopen then
                self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())
            end
        end,
        TheWorld
    )
    --监听界面尺寸变化，更新尺寸
    self.inst:ListenForEvent(
        "refreshhudsize",
        function(hud, scale)
            if self.isopen then
                self.scalingroot:SetScale(scale)
            end
        end,
        owner.inst
    )

    -- TEMPLATES.RectangleWindow() 方法的构造方法参数如下
    -- TEMPLATES.RectangleWindow(sizeX, sizeY, title_text, bottom_buttons, button_spacing, body_text)
    -- sizeX: 宽
    -- sizeY: 高
    -- title_text 面板title
    -- bottom_buttons 底部按钮
    -- button_spacing 按钮间距
    -- body_text 面板的文本
    self.panel = self.scalingroot:AddChild(TEMPLATES.RectangleWindow(464, 520, STRINGS.eventtimer.ui_title,
    {
        {
            text = STRINGS.UI.OPTIONS.CLOSE,
            cb = function()
                self.owner.EventTimerButton:ToggleEventTimerUI()
            end,
            offset = nil
        },
    }))

    ------------------------------------scroll-----------------------------------------

    -- 初始化每一项的方法
    local function DestItemCtor(content, index)
        local widget = Widget("widget-"..index)

        widget:SetOnGainFocus(function()
            self.scrollpanel:OnWidgetFocus(widget)
        end)
        -- self:InitDestItem() 每一项里的控件布局
        widget.destitem = widget:AddChild(self:InitDestItem())

        return widget
    end

    -- 给每一项赋值，添加事件的方法
    local function DestApply(context, widget, data, index)
        widget.destitem:Hide()

        local text = data and data.text
        if not text then
            if widget.destitem.checkbox then
                widget.destitem.checkbox:Hide()
            end
            widget._event_timer_data = nil
            return
        end

        if data.animchangefn then
            data:animchangefn(data.context)
        end

        if data.imagechangefn then
            data:imagechangefn(data.context)
        end

        local image_data = data.image and data.image.atlas and data.image.tex and data.image or nil
        local anim_data = not image_data and data.anim or nil
        local asset_kind = image_data and "image" or anim_data and "anim" or nil
        local asset = image_data or anim_data
        local asset_x, asset_y, asset_scale
        local asset_atlas, asset_tex
        local asset_bank, asset_build, asset_animation, asset_loop, asset_orientation

        if image_data then
            asset_x = -180 + (image_data.uioffset and image_data.uioffset.x or 0)
            asset_y = image_data.uioffset and image_data.uioffset.y or 0
            asset_scale = image_data.scale or 0.099
            asset_atlas = image_data.atlas
            asset_tex = image_data.tex
        elseif anim_data then
            asset_x = -180 + (anim_data.uioffset and anim_data.uioffset.x or 0)
            asset_y = -15 + (anim_data.uioffset and anim_data.uioffset.y or 0)
            asset_scale = anim_data.scale or 0.099
            asset_bank = anim_data.bank
            asset_build = anim_data.build
            asset_animation = anim_data.animation or "idle"
            asset_loop = anim_data.loop
            asset_orientation = anim_data.orientation
        end

        local destitem = widget.destitem
        local has_time = data.time and data.time > 0
        local warningevent_child
        local force
        if has_time then
            warningevent_child = data.name .. "_" .. data.shard_id
            if not (ThePlayer and ThePlayer.HUD[warningevent_child]) then
                return
            end
            force = ThePlayer.HUD[warningevent_child].force
        end

        -- TrueScrollList 可能重复应用同一行；内容没有变化时不再触碰控件树。
        if widget._event_timer_data == data
            and widget._event_timer_text == text
            and widget._event_timer_asset_kind == asset_kind
            and widget._event_timer_asset == asset
            and widget._event_timer_asset_x == asset_x
            and widget._event_timer_asset_y == asset_y
            and widget._event_timer_asset_scale == asset_scale
            and widget._event_timer_asset_atlas == asset_atlas
            and widget._event_timer_asset_tex == asset_tex
            and widget._event_timer_asset_bank == asset_bank
            and widget._event_timer_asset_build == asset_build
            and widget._event_timer_asset_animation == asset_animation
            and widget._event_timer_asset_loop == asset_loop
            and widget._event_timer_asset_orientation == asset_orientation
            and widget._event_timer_nobackground == data.nobackground
            and widget._event_timer_has_time == has_time
            and widget._event_timer_force == force
        then
            destitem:Show()
            return
        end

        local item_data_changed = widget._event_timer_data ~= data
        local has_time_changed = widget._event_timer_has_time ~= has_time
        local asset_changed = widget._event_timer_asset_kind ~= asset_kind
            or widget._event_timer_asset ~= asset
            or widget._event_timer_asset_x ~= asset_x
            or widget._event_timer_asset_y ~= asset_y
            or widget._event_timer_asset_scale ~= asset_scale
            or widget._event_timer_asset_atlas ~= asset_atlas
            or widget._event_timer_asset_tex ~= asset_tex
            or widget._event_timer_asset_bank ~= asset_bank
            or widget._event_timer_asset_build ~= asset_build
            or widget._event_timer_asset_animation ~= asset_animation
            or widget._event_timer_asset_loop ~= asset_loop
            or widget._event_timer_asset_orientation ~= asset_orientation

        widget._event_timer_data = data
        widget._event_timer_text = text
        widget._event_timer_asset_kind = asset_kind
        widget._event_timer_asset = asset
        widget._event_timer_asset_x = asset_x
        widget._event_timer_asset_y = asset_y
        widget._event_timer_asset_scale = asset_scale
        widget._event_timer_asset_atlas = asset_atlas
        widget._event_timer_asset_tex = asset_tex
        widget._event_timer_asset_bank = asset_bank
        widget._event_timer_asset_build = asset_build
        widget._event_timer_asset_animation = asset_animation
        widget._event_timer_asset_loop = asset_loop
        widget._event_timer_asset_orientation = asset_orientation
        widget._event_timer_nobackground = data.nobackground
        widget._event_timer_has_time = has_time
        widget._event_timer_force = force

        -- 设置文字
        destitem.describe:SetString(text)

        if destitem.background then
            if data.nobackground then
                destitem.background:Hide()
            else
                destitem.background:Show()
            end
        end

        -- 资源没有变化时保留原控件；资源类型或配置变化时才重建。
        if asset_changed then
            if asset_kind == "image" then
                if destitem.anim then
                    destitem.anim:Kill()
                    destitem.anim = nil
                end
                if not destitem.image then
                    destitem.image = destitem:AddChild(Image(asset_atlas, asset_tex))
                else
                    destitem.image:SetTexture(asset_atlas, asset_tex)
                end
                destitem.image:SetPosition(asset_x, asset_y, 0)
                destitem.image:SetScale(asset_scale)
            elseif asset_kind == "anim" then
                if destitem.image then
                    destitem.image:Kill()
                    destitem.image = nil
                end
                if destitem.anim then
                    destitem.anim:Kill()
                end
                destitem.anim = destitem:AddChild(UIAnim())
                destitem.anim:SetPosition(asset_x, asset_y, 0)
                destitem.anim:SetScale(asset_scale)
                destitem.anim:GetAnimState():SetBank(asset_bank)
                destitem.anim:GetAnimState():SetBuild(asset_build)
                destitem.anim:GetAnimState():PlayAnimation(asset_animation, asset_loop)
                if anim_data.hidesymbol then
                    for _, s in ipairs(anim_data.hidesymbol) do
                        destitem.anim:GetAnimState():HideSymbol(s)
                    end
                end
                if anim_data.overridesymbol then
                    destitem.anim:GetAnimState():OverrideSymbol(anim_data.overridesymbol[1], anim_data.overridesymbol[2], anim_data.overridesymbol[3])
                end
                if anim_data.overridebuild then
                    local _, b = next(anim_data.overridebuild)
                    destitem.anim:GetAnimState():AddOverrideBuild(b)
                end
                if anim_data.multcolour then
                    destitem.anim:GetAnimState():SetMultColour(anim_data.multcolour[1], anim_data.multcolour[2], anim_data.multcolour[3], anim_data.multcolour[4])
                end
                if anim_data.orientation then
                    destitem.anim:GetAnimState():SetOrientation(anim_data.orientation)
                end
                destitem.anim:GetAnimState():Pause()
            else
                if destitem.image then
                    destitem.image:Kill()
                    destitem.image = nil
                end
                if destitem.anim then
                    destitem.anim:Kill()
                    destitem.anim = nil
                end
            end
        end

        if has_time then
            local checkbox_created = false
            if not destitem.checkbox then
                destitem.checkbox = destitem:AddChild(ImageButton(
                    "images/global_redux.xml","checkbox_normal.tex", "checkbox_focus.tex", "checkbox_focus_check.tex", nil, nil, {1,1}, {0,0}
                ))
                destitem.checkbox:SetPosition(184, 0)
                destitem.checkbox:SetScale(1)
                checkbox_created = true
            end
            destitem.checkbox:Show()

            -- 更新复选框状态
            if force then
                destitem.checkbox:SetTextures( "images/global_redux.xml", "checkbox_normal_check.tex", "checkbox_focus_check.tex", "checkbox_focus.tex" )
            else
                destitem.checkbox:SetTextures( "images/global_redux.xml", "checkbox_normal.tex", "checkbox_focus.tex", "checkbox_focus_check.tex" )
            end

            if item_data_changed or has_time_changed or checkbox_created then
                -- 设置复选框按下后执行的函数
                destitem.checkbox:SetOnClick(function()
                    for shard_id in pairs(ThePlayer.HUD.WarningEventTimeData[data.name] or {}) do
                        local warningevent_child = data.name .. "_" .. shard_id
                        if ThePlayer.HUD[warningevent_child] then
                            ThePlayer.HUD[warningevent_child].force = not ThePlayer.HUD[warningevent_child].force

                            -- 根据切换结果设置 checkbox 状态
                            if ThePlayer.HUD[warningevent_child].force then
                                RW_Data:SetValue(data.name, true)
                                destitem.checkbox:SetTextures( "images/global_redux.xml", "checkbox_normal_check.tex", "checkbox_focus_check.tex", "checkbox_focus.tex" )
                            else
                                RW_Data:SetValue(data.name, nil)
                                destitem.checkbox:SetTextures( "images/global_redux.xml", "checkbox_normal.tex", "checkbox_focus.tex", "checkbox_focus_check.tex" )
                            end
                        end
                    end

                    RW_Data:Save()
                end)
            end
        elseif destitem.checkbox then
            destitem.checkbox:Hide()
        end

        if item_data_changed then
            -- 点击倒计时后触发的事件
            destitem.backing:SetOnClick(function()
                if type(data.announcefn) == "function" then
                    local res = data.announcefn(data.context)
                    if type(res) == "string" then
                        TheNet:Say(STRINGS.LMB .. ' ' .. res, TheInput:IsKeyDown(KEY_CTRL))
                    end
                end
            end)
        end

        destitem:Show()
    end

    -- 将滚动条添加到self.panel里去
    self.scrollpanel = self.panel:AddChild(TEMPLATES.ScrollingGrid({}, {
        num_columns = 1,              -- 有几个滚动条
        num_visible_rows = 4,         -- 滚动条内最多显示多少行
        item_ctor_fn = DestItemCtor,  -- 每一项的构造方法
        apply_fn = DestApply,         -- 给每一项赋值，添加事件等
        widget_width = 470,           -- 每一项的宽
        widget_height = 110,          -- 每一项的高
        peek_percent = 0,             -- 在底部可以看到多少行，相当于拉到底了还能往上拉多少
        allow_bottom_empty_row = true -- 是否允许底部有空行
    }))
    -----------------------------------------------------------------------------------
    self:UpdateDestItem() -- 立刻更新一次数据，防止暂停时没数据
    -- Scheduler:ExecutePeriodic(period, fn, limit, initialdelay, id, ...)
    self.updatetask = scheduler:ExecutePeriodic(FRAMES * 10, self.UpdateDestItem, nil, 0, "updatedestitems", self) -- 持续刷新数据

    -- 最后要把滚动条挂到父组件上的 self.default_focus 对象上去
    self.default_focus = self.scrollpanel
end)

-- function WarningEventHUD:UpdateDestItem() -- 由UI.lua提供
-- end

-- 关闭面板
function WarningEventHUD:Close()
    if self.isopen then
        self.attach = nil
        self.panel:Kill()
        self.isopen = false
        self.updatetask:Cancel()
        self.updatetask = nil
    end
end

-- 定义每一项内的控件布局
function WarningEventHUD:InitDestItem()
    local dest = Widget("destination")
    local width, height = 470, 110
    dest.backing = dest:AddChild(TEMPLATES.ListItemBackground(width, height, function() end))
    dest.backing.move_on_click = true -- 按下后有视觉反馈

    -- 图片/动画背景
    dest.background = dest:AddChild(Image("images/scrapbook.xml", "inv_item_background.tex"))
    dest.background:SetPosition(-180, 0, 0)
    dest.background:SetScale(0.5, 0.5)

    -- TEXT控件
    dest.describe = dest:AddChild(Text(BODYTEXTFONT, 30)) -- 添加TEXT控件 字体，大小，文字
    dest.describe:SetColour(255, 255, 255, 1)
    dest.describe:SetVAlign(ANCHOR_MIDDLE) -- 设置上下对齐
    dest.describe:SetHAlign(ANCHOR_MIDDLE) -- 设置左右对齐
    dest.describe:SetPosition(10, 0, 0) -- 设置坐标 X，Y，Z
    dest.describe:SetRegionSize(400, 100) -- 设置文字区域大小
    dest.describe:SetScale(0.8, 0.8) -- 设置文字大小

    -- 将定义好的组件返回
    return dest
end

return WarningEventHUD
