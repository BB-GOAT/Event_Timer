---------------------------------------- 如何把你的事件加入到本模组中？ ----------------------------------------

-- 首先在你的模组里写上一行
GLOBAL.WarningEvents = GLOBAL.rawget(GLOBAL, "WarningEvents") or {} -- WarningEvents表中的内容以及具体的更新数据方式见本模组 main/RPC.lua

-- 接着在GLOBAL.WarningEvents中添加一个表，名称请使用负责处理对应事件的组件名，比如猎犬事件倒计时是 scripts\components\hounded.lua 文件处理的，组件为hounded，事件名就取 hounded

local TimeToString = GLOBAL.EventTimer.env.TimeToString -- 获取全局事件计时器模组的格式化时间函数(将纯数字转换为X天X分X秒) ； 注意，如果你的模组加载优先级高于本模组（priority = -11）则无法获取到。需要自己定义此函数
local Upvaluehelper = GLOBAL.BBGOAT_utils.Upvaluehelper -- 获取getupvalue工具，文件位于【冰冰羊的模组运行库】mod内，可直接复用。具体文件路径为 ..\322330\3750536829\bbgoat_utils\bbgoat_upvaluehelper.lua


GLOBAL.WarningEvents.hounded = { -- 这个事件名称为 hounded，注意你的事件名不要和本模组自带的冲突，否则会覆盖原模组的事件倒计时。有需要请自行HOOK
    gettimefn = function(self) -- gettimefn：服务器执行的函数，返回一个数字表示倒计时还有多少秒。屏幕左上角的常驻倒计时显示的数字来自于此，若没有此项则事件不能被勾选并常驻屏幕左上角
        -- self 为组件本体，在这里self相当于 TheWorld.components.hounded 只有组件被注册后才会执行gettimefn和gettextfn
        local data = self:OnSave()
        return data and data.timetoattack -- 返回猎犬袭击的倒计时时间。类型必须为number。 同时保存在客户端的 GLOBAL.ThePlayer.HUD.WarningEventTimeData.hounded_time 表中（GLOBAL.ThePlayer.HUD.WarningEventTimeData是固定的前缀，hounded为这个事件的名称，_time是固定后缀）
    end,

    -- gettextfn：服务器执行的函数，决定事件计时器面板里显示的文本内容，若没有此项/没有返回值则面板里只显示时间（X天X分X秒）。
    gettextfn = function(self, time) -- self为组件本身，time为上方gettimefn返回的数字，其中time可能为nil (如果gettimefn没有返回数据)
        if not GLOBAL.TheWorld:HasTag("cave") or not time then return end

        local next_wave_is_wormboss = Upvaluehelper.FindUpvalue(self.DoWarningSpeech, "_wave_pre_upgraded") -- 使用工具搜索GLOBAL.TheWorld.components.hounded.DoWarningSpeech的上值 _wave_pre_upgraded
        local _wave_override_chance = self:OnSave().wave_override_chance

        if next_wave_is_wormboss then
            return string.format("巨大洞穴蠕虫将在%s后攻击", TimeToString(time))
        elseif type(_wave_override_chance) == "number" then
            return string.format("洞穴蠕虫将在%s后攻击\n巨大洞穴蠕虫概率：%s%%", TimeToString(time), _wave_override_chance * 100)
        end
        -- 返回的类型必须为string
    end,

    -- gettimefn 和 gettextfn 至少二选一 ，同时存在时 事件计时器UI优先显示text，屏幕左上角常驻内容只会显示time

    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    -- image = {
    --     atlas = "images/Hound.xml",
    --     tex = "Hound.tex",
    --     scale = 0.4, -- 缩放比例
    --     以下是可选参数
    --     offset = { -- 在屏幕左上角常驻显示的位置偏移量
    --        x = 0  -- 左减右加
    --        y = 0  -- 上加下减
    --     },
    --     uioffset = { -- 在事件计时器面板的位置偏移量
    --        x = 0  -- 左减右加
    --        y = 0  -- 上加下减
    --     },
    -- },

    -- imagechangefn，客户端执行的函数，这是一个可选函数，根据不同情况选择不同的image图片。如果你只有一种image则可以按照上面的格式直接指定
    imagechangefn = function(self, context) -- context参数说明见本文件末尾部分
        local text = context.text -- 获取服务器执行gettextfn的返回结果（也就是事件计时器面板里显示的文本内容）
        local worldtype = context.world_type -- 获取该事件是从哪个世界发来的
        local is_worm_boss = text and string.find(text, "巨大洞穴蠕虫将在") -- 由于imagechangefn在客户端执行，所以只能使用string的匹配方法来判断当前是否为巨大洞穴蠕虫，客户端不能执行 gettimefn 和 gettextfn
        if worldtype == "porkland" then
            self.image = self.porklandimage
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
    forestimage = { -- imagechangefn中用到的表
        atlas = "images/Hound.xml",
        tex = "Hound.tex",
        scale = 0.4,
    },
    caveimage = { -- imagechangefn中用到的表
        atlas = "images/Depths_Worm.xml",
        tex = "Depths_Worm.tex",
        scale = 0.25,
    },
    wormbossimage = { -- imagechangefn中用到的表
        atlas = "images/Worm_boss.xml",
        tex = "Worm_boss.tex",
        scale = 0.25,
    },

    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    -- anim = {
    --     scale = 0.099, -- 缩放比例
    --     bank = "hound", -- 库名
    --     build = "hound_ocean", -- 材质
    --     animation = "idle", -- 动画
    --     loop = true, -- 是否循环播放动画
    --     以下是可选参数
    --     offset = { -- 在屏幕左上角常驻显示的位置偏移量
    --        x = 0  -- 左减右加
    --        y = 0  -- 上加下减
    --     },
    --     uioffset = { -- 在事件计时器面板的位置偏移量
    --        x = 0  -- 左减右加
    --        y = 0  -- 上加下减
    --     },
    --     overridebuild   --类型是数组表，为事件的额外材质(必须搭配动画使用，表内依次填入build名称即可) 参数等同 AddOverrideBuild
    --     overridesymbol  --类型是键值表，替换事件的symbol(必须搭配动画使用，表内依次填入包含原有symbol与目标build和目标symbol组成的表) 参数等同 OverrideSymbol
    --     multcolour      --类型是数组表，设置动画的多颜色参数(必须搭配动画使用，表内依次填入包含r、g、b值的数组) 参数等同 SetMultColour
    --     hidesymbol      --类型是数组表，隐藏事件的symbol(必须搭配动画使用，表内依次填入symbol名称) 参数等同 HideSymbol
    --     orientation     --设置动画的方向 参数等同 SetOrientation
    -- },


    -- animchangefn，与imagechangefn类似，在客户端执行的函数，这是一个可选函数，根据不同情况选择不同的anim动画。如果只有一种anim则可以按照上面的格式直接指定
    animchangefn = function(self, context)
        local worldtype = context.world_type -- 获取该事件是从哪个世界发来的
        if worldtype == "porkland" then
            self.anim = self.porklandanim
        elseif worldtype == "shipwrecked" or worldtype == "volcano" then
            self.anim = self.islandanim
        elseif worldtype == "cave" then
            self.anim = self.caveanim
        else
            self.anim = self.forestanim
        end
    end,
    forestanim = {
        scale = 0.099,
        bank = "hound",
        build = "hound_ocean",
        animation = "idle",
        loop = true,
    },
    islandanim = {
        scale = 0.09,
        bank = "crocodog",
        build = "crocodog_poison",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 6,
            y = 0,
        },
    },
    caveanim = {
        scale = 0.066,
        bank = "worm",
        build = "worm",
        animation = "atk",
        loop = true,
    },

    -- image 和 anim 至少二选一，否则没有图片，事件计时器面板优先显示image，其次显示anim的第一帧动画。屏幕左上角的常驻计时优先显示anim，否则显示image

    DisableShardRPC = true, -- 强制禁用此事件的跨世界同步计时功能，如果你觉得这个事件的数据没必要同步就可以开启
    DisableClientPrediction = false, -- 是否标记该事件始终不需要客户端进行预测倒计时（适用于非倒计时事件，如今日月相）

    -- 宣告功能，在客户端执行的函数，这是一个可选函数，返回值类型是string，作用是在事件计时器面板点击该事件时进行宣告
    announcefn = function(context)
        local time = context.time -- 获取当前事件的倒计时时间
        local text = context.text -- 获取当前事件的文本内容
        return (text ~= "" and text) or (time > 0 and string.format("猎犬将在%s后攻击", TimeToString(time))) -- 当time为0时不返回任何内容，这样当下方的tipsfn调用时没有返回结果 就会立刻清理醒目提示内容，而不是一直等到设定的持续时间结束（虽然大部分时候设定的持续时间刚好是倒计时归零的时间，但总有意外情况）
    end,

    -- 醒目提示功能，在客户端执行的函数，这是一个可选函数，返回值依次为：布尔值(为true时触发提示，为false时不提示并重置状态)，提示信息内容（必须为一个返回字符串的函数），提示持续时间（数字类型，单位秒），延迟多久显示（数字类型，单位秒，可不填），消息等级(1-静默提醒-白色 2-声音提醒-黄色 3-声音提醒-红色)
    -- boolean, function->string, number, number|nil, number
    -- 示例：return true, function() return "text" end, 10, 10, 3
    tipsfn = function(context)
        local time = context.time -- 获取当前事件的倒计时时间

        if time == 120 or (GLOBAL.GetTime() > 1 and GLOBAL.GetTime() < 10 and time > 0 and time < 960) then -- 其中GetTime是科雷的函数，返回的是游戏本次加载后到现在的运行时间，重载游戏/进出房间/穿越世界 就会归0
            return true, GLOBAL.WarningEvents.hounded.announcefn, 10, nil, 2 -- true表示可以提醒玩家了，WarningEvents.hounded.announcefn是上面的宣告函数，10表示提示持续10秒，2表示中等消息等级
        elseif time == 120 or (GLOBAL.GetTime() > 1 and GLOBAL.GetTime() < 10 and time > 0) then -- 与上面一条的区别是少了 time < 960
            return true, GLOBAL.WarningEvents.hounded.announcefn, 10, nil, 1 -- 消息等级比上面的低
        elseif time > 2 and time <= 90 then -- 第二种情况：猎犬袭击倒计时在2~90秒内
            return true, GLOBAL.WarningEvents.hounded.announcefn, time, nil, 2
        elseif time < 2 and time > 0 then -- 服务器gettimefn获取不到猎犬袭击信息时，会被视作倒计时0秒，所以这里的time判断不能等于0
            return true, (function() return "警告：猎犬正在袭击" end), 10, time, 3 -- 第二个返回值必须是一个“返回字符串的函数”。第四个值是延迟多少秒显示，这里设置为time就能刚好在倒计时结束时发出警告
        end
        return false -- 其余情况返回一个false，重置状态
    end
}

-- 最小化示例
GLOBAL.WarningEvents.hounded = { -- 这个事件名称为 hounded，注意你的事件名不要和原模组的冲突，否则会覆盖原模组的事件倒计时
    -- gettimefn：服务器执行的函数，返回一个数字表示倒计时还有多少秒。
    gettimefn = function()
        if GLOBAL.TheWorld.components.hounded then
            local data = GLOBAL.TheWorld.components.hounded:OnSave()
            return data and data.timetoattack -- 返回猎犬袭击的倒计时时间。类型必须为number。 同时保存在客户端的 GLOBAL.ThePlayer.HUD.WarningEventTimeData.hounded_time 表中（GLOBAL.ThePlayer.HUD.WarningEventTimeData是固定的前缀，hounded为这个事件的名称，_time是固定后缀
        end
    end,
    anim = { -- 事件图标动画
        scale = 0.099, -- 缩放比例
        bank = "hound", -- 库名
        build = "hound_ocean", -- 材质
        animation = "idle", -- 动画
    },
}

-- 如果你想添加的事件计时 数据来源不是来自某个组件，而是来自某个prefab，则需要用到timerprefab字段
-- 再举个例子
GLOBAL.WarningEvents.beequeenhive = {
    timerprefab = "beequeenhive", -- 事件数据来自Prefab：beequeenhive
    gettimefn = function(self) -- 此处的self为 AddPrefabPostInit("beequeenhive", function(self) end) 中的self
        local stagetimne = TUNING.BEEQUEEN_RESPAWN_TIME / 3
        if not self or not self:IsValid() then
            return
        end

        local timer = self.components.timer
        if not timer then
            return
        end

        if timer:GetTimeLeft("hivegrowth1") then
            return 2 * stagetimne + timer:GetTimeLeft("hivegrowth1")
        elseif timer:GetTimeLeft("hivegrowth2") then
            return stagetimne + timer:GetTimeLeft("hivegrowth2")
        else
            return timer:GetTimeLeft("hivegrowth")
        end
    end,
    -- 接着是 anim、announcefn、tipsfn ... 这里不做展示
}


-- 总结：gettimefn/gettextfn 在服务器执行，imagechangefn/animchangefn/announcefn/tipsfn 在客户端执行，客户端无法调用 gettimefn/gettextfn

-- gettimefn/gettextfn 的返回类型和保存位置要严格遵守：
-- gettimefn 必须返回 number（秒），同名数据保存到 GLOBAL.ThePlayer.HUD.WarningEventTimeData.<event>_time。
-- gettextfn 必须返回 string，保存到 GLOBAL.ThePlayer.HUD.WarningEventTimeData.<event>_text

-- 最后，将本模组和你的模组一起启用即可
-- 本模组的各事件记录在 main/warningevents.lua 里


---------------------------------------- 其它 ----------------------------------------

-- context 参数，由 main/UI.lua 处理 内容包括 shard_id、世界类型、世界中文名、Widget对象等
-- 在UI.lua中，它是这么定义的
local context = setmetatable( -- 传入给事件模块的信息
    {
        shard_id = shard_id, -- 该事件所处世界ID（数字）
        world_type = world_type, -- 该事件所处世界类型（forest、cave、shipwrecked、volcano、porkland、unknown）
        world_str = world_str, -- 该事件所处世界中/英文名（森林、洞穴、海难、火山、猪镇、未知）（Forest、Cave、Shipwrecked、Volcano、Hamlet、Unknown）
        warningevent_child = self[warningevent_child], -- ThePlayer.HUD中本事件添加的Widget对象
    },
    {
        __index = function(t, key)
            return eventsdata[warningevent][shard_id][key] -- 包含当前事件的当前 time 和 text ，也就是服务器执行 gettimefn 和 gettextfn 的返回结果。time的默认值为0，text的默认值为空字符串
        end
    }
)