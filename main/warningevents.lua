local RequireEvent = RequireEvent

-- 判断某个模组是否加载
local function Ismodloaded(name)
	return GLOBAL.KnownModIndex:IsModEnabledAny(name)
end

GLOBAL.setfenv(1, GLOBAL)

WarningEvents = rawget(_G, "WarningEvents") or {}
local GameEvents
GameEvents = {
    ---------------------------------------- Forest ----------------------------------------

    hounded = RequireEvent("DST/hounded"), -- 猎犬/洞穴蠕虫/鳄狗/吸血蝙蝠
    deerclopsspawner = RequireEvent("DST/deerclopsspawner"), -- 独眼巨鹿
    -- deerherdspawner = RequireEvent("DST/deerherdspawner"), -- 无眼鹿(无法纯本地)
    klaussackspawner = RequireEvent("DST/klaussackspawner"), -- 赃物袋
    -- sinkholespawner = RequireEvent("DST/sinkholespawner"), -- 蚁狮(无法纯本地)
    beargerspawner = RequireEvent("DST/beargerspawner"), -- 熊獾
    dragonfly_spawner = RequireEvent("DST/dragonfly_spawner"), -- 龙蝇
    beequeenhive = RequireEvent("DST/beequeenhive"), -- 蜂后
    terrarium = RequireEvent("DST/terrarium"), -- 盒中泰拉
    malbatrossspawner = RequireEvent("DST/malbatrossspawner"), -- 邪天翁
    crabkingspawner = RequireEvent("DST/crabkingspawner"), -- 帝王蟹
    -- moon = RequireEvent("DST/moon"), -- 月相(不需要纯本地)
    -- farming_manager = RequireEvent("DST/farming_manager"), -- 果蝇王(无法纯本地)
    -- piratespawner = RequireEvent("DST/piratespawner"), -- 海盗袭击(无法纯本地)
    forestdaywalkerspawner = RequireEvent("DST/forestdaywalkerspawner"), -- 拾荒疯猪
    -- messagebottlemanager = RequireEvent("DST/messagebottlemanager"), -- 宝藏信息(无法纯本地)
    -- lunarthrall_plantspawner = RequireEvent("DST/lunarthrall_plantspawner"), -- 致命亮茄(无法纯本地)
    lunar_riftspawner = RequireEvent("DST/lunar_riftspawner"), -- 月亮裂隙生成倒计时
    shadow_riftspawner = RequireEvent("DST/shadow_riftspawner"), -- 暗影裂隙生成倒计时
    -- rift_portal = RequireEvent("DST/rift_portal"), -- 月亮裂隙信息(无法纯本地)

    ---------------------------------------- Cave ----------------------------------------

    -- shadowrift_portal = RequireEvent("DST/shadowrift_portal"), -- 暗影裂隙信息(无法纯本地)
    daywalkerspawner = RequireEvent("DST/daywalkerspawner"), -- 梦魇疯猪
    -- shadowthrallmanager = RequireEvent("DST/shadowthrallmanager"), -- 梦魇裂隙/墨荒(暂未确定)
    toadstoolspawner = RequireEvent("DST/toadstoolspawner"), -- 毒菌蟾蜍
    atrium_gate = RequireEvent("DST/atrium_gate"), -- 远古大门
    nightmareclock = RequireEvent("DST/nightmareclock"), -- 遗迹当前阶段(纯本地)
    -- quaker = RequireEvent("DST/quaker"), -- 地震

    ---------------------------------------- Player ----------------------------------------

    -- -- 针对单个玩家的事件，不支持gettimefn，gettextfn返回一个包含所有玩家信息的json字符串。不支持跨世界同步
    -- flotsamgenerator = RequireEvent("DST/flotsamgenerator"), -- 瓶中信
    -- yoth_knightmanager = RequireEvent("DST/yoth_knightmanager"), -- 镀金骑士
}
for k, v in pairs(GameEvents) do
    WarningEvents[k] = v
end

local ShipwreckedEvents = rawget(_G, "IA_SW_ENABLED") and {
    ---------------------------------------- IA-SW ---------------------------------------
    -- chessnavy = RequireEvent("IslandAdventures/chessnavy"),
    -- volcanoactivity = RequireEvent("IslandAdventures/volcanoactivity"),
    -- volcanomanager = RequireEvent("IslandAdventures/volcanomanager"),
    twisterspawner = RequireEvent("IslandAdventures/twisterspawner"),
    -- krakener = RequireEvent("IslandAdventures/krakener"),
    -- tigersharker = RequireEvent("IslandAdventures/tigersharker"),
    -- islandsklaussackspawner = RequireEvent("IslandAdventures/islandsklaussackspawner"),
} or {}

-- 将海难计时添加到WarningEvents
for k, v in pairs(ShipwreckedEvents) do
    WarningEvents[k] = v
end

-- local HamletEvents = rawget(_G, "IA_HAM_ENABLED") and
-- {   ---------------------------------------- IA-HAM ---------------------------------------
--     -- TODO
-- }
-- or Ismodloaded("workshop-3322803908") and
-- {   ---------------------------------------- Above The Clouds ---------------------------------------
--     pugalisk_fountain = RequireEvent("AboveTheClouds/pugalisk_fountain"),
--     banditmanager = RequireEvent("AboveTheClouds/banditmanager"),
--     aporkalypse = RequireEvent("AboveTheClouds/aporkalypse"),
--     aporkalypse_attack = select(2, RequireEvent("AboveTheClouds/aporkalypse")),
--     batted = select(3, RequireEvent("AboveTheClouds/aporkalypse")),
--     rocmanager = RequireEvent("AboveTheClouds/rocmanager"),
-- } or {}

-- -- 将猪镇计时添加到WarningEvents
-- for k, v in pairs(HamletEvents) do
--     WarningEvents[k] = v
-- end

-- local UncompromisingEvents = TUNING.DSTU ~= nil and
-- {
--     gmoosespawner = RequireEvent("UncompromisingMode/gmoosespawner"),
--     mock_dragonflyspawner = RequireEvent("UncompromisingMode/mock_dragonflyspawner"),
--     -- 巨鹿和原版的一样，不需要加
-- } or {}

-- -- 将永不妥协计时添加到WarningEvents
-- for k, v in pairs(UncompromisingEvents) do
--     WarningEvents[k] = v
-- end

-- 初始化事件
for k, v in pairs(WarningEvents) do
    if v.postinitfn then
        v.postinitfn()
    end
end