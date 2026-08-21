local menv = env
GLOBAL.setfenv(1, GLOBAL)

local eventname = "fe_unload_".. menv.modname
local iconname = menv.modname .. "_dynamic_icon"
local UIAnim = require("widgets/uianim")

if not rawget(_G, "EventTimerClientFePatches") then
    _G.EventTimerClientFePatches = {}
end

menv.FrontEndAssets = {
    Asset("ANIM", "anim/global_events_timer_dynamic_icon.zip"),
}

local function DoFnForCurrentScreen(fn)
	local CurrentScreen = TheFrontEnd:GetActiveScreen()
	if CurrentScreen then
		fn(CurrentScreen)
	end
end

local function AddDynamicIcon(self, root, s, x, y)
	if self[iconname] then
		return
	end

	self[iconname] = self[root]:AddChild(UIAnim())
	self[iconname]:GetAnimState():SetBuild("global_events_timer_dynamic_icon")
	self[iconname]:GetAnimState():SetBank("global_events_timer_dynamic_icon")
	self[iconname]:GetAnimState():PlayAnimation("global_events_timer_dynamic_icon", true)
    -- self[iconname]:GetAnimState():PushAnimation("", true)
    -- self[iconname]:GetAnimState():SetTime(22 * FRAMES)
    self[iconname]:SetPosition(x or 0, y or 0)
	if s then
		self[iconname]:SetScale(s)
	end

	self[iconname].inst:ListenForEvent(eventname, function()
		self[iconname]:Kill()
		self[iconname] = nil
	end, TheGlobalInstance)
end

local function PatchModDetails(self)
    if not _G.EventTimerClientFePatches.DynamicIconEnabled then return end
	if self.currentmodname == menv.modname then
		AddDynamicIcon(self, "detailimage", 0.55, 3, 2.5)
	elseif self[iconname] then
		self[iconname]:Kill()
		self[iconname] = nil
	end
end

local function PatchModIcon(widget, data)
    if not _G.EventTimerClientFePatches.DynamicIconEnabled then return end
	local opt = widget.moditem
	local mod_data = (data or widget.data)
	if mod_data and mod_data.mod and mod_data.mod.modname == menv.modname then
		-- Fox: It seems that it triggers too fast if we change world tabs
		if not data and opt[iconname] then
			opt[iconname]:Kill()
			opt[iconname] = nil
		end
		AddDynamicIcon(opt, "image", 0.45, 3, 0)
	elseif opt[iconname] then
		opt[iconname]:Kill()
		opt[iconname] = nil
	end
end


if not _G.EventTimerClientFePatches["HookedFrontendUnloadMod_" .. menv.modname] then
    local _FrontendUnloadMod = ModManager.FrontendUnloadMod
    ModManager.FrontendUnloadMod = function(self, unloaded_modname, ...)
        if not unloaded_modname or unloaded_modname == menv.modname then
            TheGlobalInstance:PushEvent(eventname)
        end
        return _FrontendUnloadMod(self, unloaded_modname, ...)
    end

    _G.EventTimerClientFePatches["HookedFrontendUnloadMod_" .. menv.modname] = true
end

local function PreLoad(self)
    local _update_fn
    local mods_page

	if self.mods_page then -- 主页的模组列表页面
        mods_page = self.mods_page
	elseif self.mods_tab then -- 创建世界的模组列表页面
        mods_page = self.mods_tab
    else
        return
	end

    if mods_page.mods_scroll_list then
        for i, widget in ipairs(mods_page.mods_scroll_list:GetListWidgets()) do
            PatchModIcon(widget)
        end
    end

    if not mods_page[menv.modname .. "_hooked_mods_page"] then
        local _ShowModDetails = mods_page.ShowModDetails
        mods_page.ShowModDetails = function(self, idx, ...)
            _ShowModDetails(self, idx, ...)
            PatchModDetails(self)
        end

        if mods_page.mods_scroll_list.update_fn and not _update_fn then
            _update_fn = mods_page.mods_scroll_list.update_fn
            mods_page.mods_scroll_list.update_fn = function(context, widget, data, index, ...)
                _update_fn(context, widget, data, index, ...)
                PatchModIcon(widget, data)
            end
        end

        mods_page[menv.modname .. "_hooked_mods_page"] = true
    end

    TheGlobalInstance:ListenForEvent(eventname, function()
        -- mods_page.mods_scroll_list.update_fn = _update_fn
        -- mods_page.ShowModDetails = _ShowModDetails
        _G.EventTimerClientFePatches.DynamicIconEnabled = false
        ModUnloadFrontEndAssets(menv.modname)
    end)

    _G.EventTimerClientFePatches.DynamicIconEnabled = true
    PatchModDetails(mods_page)
end

local function LoadFrontEndAssets()
    if not _G.EventTimerClientFePatches.DynamicIconEnabled then -- 如果动态图标正在工作 还重载资源 游戏会崩溃
        ModReloadFrontEndAssets(menv.FrontEndAssets, menv.modname)
    end
end

if rawget(_G, "TheFrontEnd") then
    LoadFrontEndAssets()
    DoFnForCurrentScreen(PreLoad)
else -- 由modmain触发
    menv.AddClassPostConstruct("screens/redux/modsscreen", function(self)
        if not self.res_event_timer_client_dynamic_icon then
            self.res_event_timer_client_dynamic_icon = true
            LoadFrontEndAssets()
            PreLoad(self)
        end
    end)

    menv.AddClassPostConstruct("screens/redux/servercreationscreen", function(self)
        if not self.res_event_timer_client_dynamic_icon then
            self.res_event_timer_client_dynamic_icon = true
            LoadFrontEndAssets()
            PreLoad(self)
        end
    end)
end