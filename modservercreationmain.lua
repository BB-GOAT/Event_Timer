local menv = env
GLOBAL.setfenv(1, GLOBAL)

local eventname = "fe_unload_".. menv.modname
local iconname = menv.modname .. "_dynamic_icon"
local UIAnim = require("widgets/uianim")

if not rawget(_G, "EventTimerFePatches") then
    _G.EventTimerFePatches = {}
end

menv.FrontEndAssets = {
    Asset("ANIM", "anim/global_events_timer_dynamic_icon.zip"),
}

local function DoFnForCurrentScreen(fn)
	scheduler:ExecuteInTime(0, function()
		for _, screen in ipairs(TheFrontEnd.screenstack) do
			if screen.name == "ServerCreationScreen" then
				fn(screen)
				break
			end
		end
	end)
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
    if not _G.EventTimerFePatches.DynamicIconEnabled then return end
	if self.currentmodname == menv.modname then
		AddDynamicIcon(self, "detailimage", 0.55, 3, 2.5)
	elseif self[iconname] then
		self[iconname]:Kill()
		self[iconname] = nil
	end
end

local function PatchModIcon(widget, data)
    if not _G.EventTimerFePatches.DynamicIconEnabled then return end
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


if not _G.EventTimerFePatches["HookedFrontendUnloadMod_" .. menv.modname] then
    local _FrontendUnloadMod = ModManager.FrontendUnloadMod
    ModManager.FrontendUnloadMod = function(self, unloaded_modname, ...)
        if not unloaded_modname or unloaded_modname == menv.modname then
            TheGlobalInstance:PushEvent(eventname)
        end
        return _FrontendUnloadMod(self, unloaded_modname, ...)
    end
    
    _G.EventTimerFePatches["HookedFrontendUnloadMod_" .. menv.modname] = true
end

local function PreLoad(self)
    local _update_fn
    local mods_page

	if self.mods_tab then -- 创建世界的模组列表页面
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

        _G.EventTimerFePatches.DynamicIconEnabled = false
        ModUnloadFrontEndAssets(menv.modname)
    end)

    _G.EventTimerFePatches.DynamicIconEnabled = true
    PatchModDetails(mods_page)
end

if rawget(_G, "TheFrontEnd") then
    menv.ReloadFrontEndAssets()
    DoFnForCurrentScreen(PreLoad)

	-- 尝试自动开启依赖模组
    local basementmod = rawget(_G, "BBGOAT_utils") and BBGOAT_utils.server_folder_name
    if basementmod and not KnownModIndex:IsModEnabledAny(basementmod) then
        KnownModIndex:Enable(basementmod)
    elseif not basementmod then -- 麻烦呐
        local _languages = {
            zh = true, --Chinese for Steam
            zhr = true, --Chinese for WeGame
            ch = true, --Chinese mod
            chs = true, --Chinese mod
            sc = true, --simple Chinese
            chinese = true, --Chinese mod
            zht = true, --traditional Chinese for Steam
            tc = true, --traditional Chinese
            cht = true, --Chinese mod
        }
        local lang = LanguageTranslator and LanguageTranslator.defaultlang
        local isCH = lang and _languages[lang]
        local PopupDialogScreen = require "screens/redux/popupdialog"
        TheFrontEnd:PushScreen(PopupDialogScreen(
            menv.modinfo.name,
            isCH and "模组基础运行库缺失！\n你缺少了模组基础运行库，你必须去订阅才能继续使用本模组" or
                    "Mod Runtime Library Missing!\nYou are missing the required runtime library for this mod. Please subscribe to it before continuing to use this mod.",
            {
                {
                    text = isCH and "订阅/启用运行库模组" or "Subscribe/Enable mod",
                    cb = function()
                        local modname = "workshop-3750536829"
                        if table.contains(TheSim:GetModDirectoryNames(), modname) then
                            KnownModIndex:Enable(modname)
                            KnownModIndex:Save()
                            TheGlobalInstance:DoTaskInTime(0.5, function()
                                TheNet:Disconnect(true)
                                TheSim:ResetError()
                                StartNextInstance()
                            end)
                        else
                            TheSim:SubscribeToMod("workshop-3750536829")
                            TheFrontEnd:PopScreen()
                            TheFrontEnd:PushScreen(PopupDialogScreen(
                                isCH and "已订阅" or "Subscribed",
                                isCH and "请前往客户端模组列表启用【冰冰羊的模组运行库】模组" or "Please go to the client mods list to enable the runtime library mod named\n\"BBGOAT Utils\"",
                                {
                                    {
                                        text = isCH and "好的" or "OK",
                                        cb = function()
                                            TheFrontEnd:PopScreen()
                                            c_reset()
                                        end
                                    }
                                }
                            ))
                        end
                    end
                },
                {
                    text = isCH and "返回" or "Back",
                    cb = function()
                        KnownModIndex:Disable(menv.modname)
                        TheGlobalInstance:PushEvent(eventname) -- 取消注册模组动态图标
                        TheFrontEnd:PopScreen()
                    end
                },
            }
        ))
    end
end