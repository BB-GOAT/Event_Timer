local SyncTimer = GLOBAL.EventTimer.SyncTimer
local UpdateTime = GLOBAL.EventTimer.UpdateTime
local STRINGS = GLOBAL.STRINGS

local SERVER_SIDE = GLOBAL.TheNet:GetIsServer() -- 专服+主机环境
local CLIENT_SIDE = not GLOBAL.TheNet:IsDedicated() -- 客户端+主机环境

-- local checknumber = GLOBAL.checknumber
-- local checkstring = GLOBAL.checkstring

local current_shardid -- 当前世界ID
local world_list = {}
local warningtimer = {} -- 所有事件的time、text、time_shardrpc、text_shardrpc数据，包含nil数据 注意判空
local ClientWarningTimer = {}

local cache_players = {}
AddPlayerPostInit(function(player)
    player:DoTaskInTime(0, function()
        cache_players[player.userid] = player
        player:ListenForEvent("onremove", function()
            cache_players[player.userid] = nil
        end)
    end)
end)

-- 检查数据是否变化
local function need_sync(player, event, data, type, shardid)
    if not player or not player.event_timer_geted_shard_data then return false end -- 主机环境服主止步于此
    if not player.event_timer_last_sync_data then player.event_timer_last_sync_data = {} end

    if not player.event_timer_last_sync_data[event .. "_" .. type .. "_" .. shardid] or
           player.event_timer_last_sync_data[event .. "_" .. type .. "_" .. shardid] ~= data
    then
        player.event_timer_last_sync_data[event .. "_" .. type .. "_" .. shardid] = data
        return true
    end
    return false
end

-- 获取玩家事件数据
local function GetPlayerEventData(event, textdata, userid)
    if GLOBAL.WarningEvents[event].playerly_datatype == "time" then
        return "time", StringToTime(textdata[userid]) or 0
    end
    return "text", textdata[userid] or ""
end

---@param event string 事件名
---@param type "event_timerpc"|"event_textrpc"
---@param data number|string 数据
---@param shardid number 世界ID
---@param targetplayer table|nil 仅向指定玩家同步，省略时同步给所有玩家
function SyncEventData(event, data, type, shardid, targetplayer) -- 同步数据到客户端
    if GLOBAL.WarningEvents[event].playerly then -- 单独处理playerly数据
        if GLOBAL.type(data) ~= "string" then return end
        local textdata
        if data == "" then
            textdata = {}
        else
            textdata = GLOBAL.json.decode(data)
        end
        if GLOBAL.type(textdata) ~= "table" then return end
        for _, player in pairs(targetplayer and { targetplayer } or cache_players) do
            local data_type, value = GetPlayerEventData(event, textdata, player.userid)
            local rpc_type = data_type == "time" and "event_timerpc" or "event_textrpc"
            if need_sync(player, event, value, rpc_type, shardid) then
                SendModRPCToClient(CLIENT_MOD_RPC["EventTimer"][rpc_type], player.userid, event, value, shardid)
            end
        end

        if CLIENT_SIDE and not targetplayer then -- 主机玩家
            ClientWarningTimer:OnHostEventDirty(event, shardid, textdata)
        end
    else
        for k,v in ipairs(targetplayer and { targetplayer } or GLOBAL.AllPlayers) do
            if need_sync(v, event, data, type, shardid) then
                SendModRPCToClient(CLIENT_MOD_RPC["EventTimer"][type], v.userid, event, data, shardid)
            end
        end

        if CLIENT_SIDE and not targetplayer then -- 主机玩家
            ClientWarningTimer:OnHostEventDirty(event, shardid)
        end
    end
end
local SyncEventData = SyncEventData

----------------------------------------多层世界同步---------------------------------------

local ShardId
AddShardModRPCHandler("EventTimer", "event_time_shardrpc", function(shardid, event, timedata)
    if ShardId == shardid then return end
    if not SyncTimer then return end -- 未开启同步功能，取消同步
    if not warningtimer[event] then return end
    -- if not (checkstring(event) and checknumber(timedata) and checkstring(worldtype)) then return end

    if not warningtimer[event][shardid] then
        warningtimer[event][shardid] = { time = 0, text = "" }
    end

    warningtimer[event][shardid].time = timedata
    warningtimer[event][shardid].text = timedata > 0 and TimeToString(timedata) or ""

    SyncEventData(event, timedata, "event_timerpc", shardid)
    SyncEventData(event, warningtimer[event][shardid].text, "event_textrpc", shardid)
end)

AddShardModRPCHandler("EventTimer", "event_text_shardrpc", function(shardid, event, textdata)
    if ShardId == shardid then return end
    if not SyncTimer then return end -- 未开启同步功能，取消同步
    if not warningtimer[event] then return end
    -- if not (checkstring(event) and checkstring(textdata) and checkstring(worldtype)) then return end

    if not warningtimer[event][shardid] then
        warningtimer[event][shardid] = { time = 0, text = "" }
    end

    warningtimer[event][shardid].text = textdata or ""
    SyncEventData(event, warningtimer[event][shardid].text, "event_textrpc", shardid)
end)

AddShardModRPCHandler("EventTimer", "sync_world_type", function(shardid, worldtype) -- 同步所有世界类型，然后发给客户端
    if ShardId == shardid then return end
    world_list[shardid] = worldtype
    SendModRPCToClient(CLIENT_MOD_RPC["EventTimer"]["sync_world_data"], nil, 'world_list', shardid, worldtype)
end)

---------------------------------------服务器RPC---------------------------------------

AddModRPCHandler("EventTimer", "get_shard_data", function(player)
    if player and not player.event_timer_geted_shard_data then
        for shardid, worldtype in pairs(world_list) do
            SendModRPCToClient(CLIENT_MOD_RPC["EventTimer"]["sync_world_data"], player.userid, 'world_list', shardid, worldtype)
        end
        SendModRPCToClient(CLIENT_MOD_RPC["EventTimer"]["sync_world_data"], player.userid, 'current_shardid', ShardId)

        player:DoTaskInTime(1, function ()
            player.event_timer_geted_shard_data = true
            -- 世界信息发送后补发已有事件，避免等待下一轮更新而错过入场提示
            for event, shards in pairs(warningtimer) do
                for shardid, data in pairs(shards) do
                    SyncEventData(event, data.time or 0, "event_timerpc", shardid, player)
                    SyncEventData(event, data.text or "", "event_textrpc", shardid, player)
                end
            end
        end)
    end
end)

---------------------------------------客机RPC---------------------------------------

-- 分成2个RPC可以少传一个type参数（节省宽带？）
AddClientModRPCHandler("EventTimer", "event_timerpc", function(event, time, shardid)
    -- if not (checkstring(event) and checknumber(time)) then return end
    ClientWarningTimer:OnWarningEventDirty(event, "time", shardid, time)
end)

AddClientModRPCHandler("EventTimer", "event_textrpc", function(event, text, shardid)
    -- if not (checkstring(event) and checkstring(text)) then return end
    ClientWarningTimer:OnWarningEventDirty(event, "text", shardid, text)
end)

-- 同步Shard数据
AddClientModRPCHandler("EventTimer", "sync_world_data", function(data_type, shardid, worldtype)
    if data_type == 'world_list' then
        world_list[shardid] = worldtype
    elseif data_type == 'current_shardid' then
        current_shardid = shardid
        GLOBAL.EventTimer.CurrentShardId = current_shardid -- 方便从其它地方获取当前所处世界ID
    end
end)

---------------------------------------服务器更新逻辑---------------------------------------

local valid_data = {}
local initialdelay = 0 -- 首次运行延迟多久开始
local function AddTimerDescriptor(self, warningevent, data)
    if valid_data[warningevent] then
        MOD_util:Warning('检测到重复AddTimerDescriptor : ' .. warningevent)
        return -- 重复注册？返回
    end

    initialdelay = initialdelay + 1
    local inst = self.inst or self
    -- 注册时立即占位，防止首次更新前重复启动任务
    local descriptor = {
        inst = inst,
        time_last = 0,
        time_sametick = 0,
        time_valid = false,
        text_sametick = 0,
        text_valid = false,
    }
    valid_data[warningevent] = descriptor
    descriptor.task = inst:DoPeriodicTask(UpdateTime, function()
        if valid_data[warningevent] ~= descriptor then return end
        if not (ShardId and warningtimer[warningevent]) then return end

        local time
        if data.gettimefn then
            time = data.gettimefn(self)
            if time and time < 0 then time = 0 end -- 避免被负数影响
            time = time and math.floor(time + 0.5) -- 四舍五入

            -- 判断时间是否有变化
            if not time or time == 0 or valid_data[warningevent].time_last == time then
                valid_data[warningevent].time_sametick = (valid_data[warningevent].time_sametick) + 1
            else
                valid_data[warningevent].time_sametick = 0
            end

            valid_data[warningevent].time_last = time -- 更新上次记录的时间

            if valid_data[warningevent].time_sametick > math.ceil(2 / UpdateTime) then -- 重复次数过多，删除数据
                if valid_data[warningevent].time_valid then
                    valid_data[warningevent].time_valid = false -- 标记数据无效
                    warningtimer[warningevent][ShardId].time = 0 -- 更新本世界数据
                    SyncEventData(warningevent, 0, "event_timerpc", ShardId)

                    if SyncTimer and not data.DisableShardRPC then -- 更新其它世界数据
                        SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_time_shardrpc"], nil, warningevent, 0)
                    end
                end
            elseif time and time > 0  then -- 时间有效
                valid_data[warningevent].time_valid = true -- 标记数据有效
                warningtimer[warningevent][ShardId].time = time -- 更新本世界数据
                SyncEventData(warningevent, time, "event_timerpc", ShardId)

                if SyncTimer and not data.DisableShardRPC then -- 更新其它世界数据
                    SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_time_shardrpc"], nil, warningevent, time)
                end
            else -- 无效数据
                warningtimer[warningevent][ShardId].time = 0
                SyncEventData(warningevent, 0, "event_timerpc", ShardId)
            end
        end
        if data.gettextfn then
            local text = data.gettextfn(self, time)

            -- 更新本世界数据
            warningtimer[warningevent][ShardId].text = text or ""
            SyncEventData(warningevent, warningtimer[warningevent][ShardId].text, "event_textrpc", ShardId)

            -- 更新其它世界数据
            if SyncTimer and not data.DisableShardRPC and not data.playerly then
                -- 标记无效数据
                if not text or text == "" then
                    valid_data[warningevent].text_sametick = (valid_data[warningevent].text_sametick) + 1
                else
                    valid_data[warningevent].text_sametick = 0
                end

                if valid_data[warningevent].text_sametick > math.ceil(2 / UpdateTime) then -- 数据多次不变，删除其它世界的数据
                    if valid_data[warningevent].text_valid then
                        valid_data[warningevent].text_valid = false -- 标记数据无效
                        SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_text_shardrpc"], nil, warningevent, "")
                    end
                elseif text and text ~= "" then
                    valid_data[warningevent].text_valid = true -- 标记数据有效
                    SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_text_shardrpc"], nil, warningevent, text)
                end
            end
        end
    end, initialdelay * GLOBAL.FRAMES)
    return descriptor
end

local TimerPrefabList = {
    ["dragonfly_spawner"] = true, -- 龙蝇
    ["beequeenhive"] = true, -- 巨大的蜂窝
    ["terrarium"] = true, -- 盒中泰拉
    ["crabking_spawner"] = true, -- 帝王蟹
    ["atrium_gate"] = true, -- 远古大门
    ["lunarrift_portal"] = true, -- 月亮裂隙
    ["shadowrift_portal"] = true, -- 暗影裂隙
    ["pugalisk_fountain"] = true, -- 云霄国度：不老泉
}

local OtherPrefabList = {
    ["walrus_camp"] = "world", -- 海象营地
}

GLOBAL.EventTimer.AddTimerDescriptor = function(warningevent, data)
    if GLOBAL.type(warningevent) ~= "string" then
        GLOBAL.error(string.format("bad argument #1 to 'EventTimer.AddTimerDescriptor' (string expected, got %s)", type(warningevent)))
    end
    if GLOBAL.type(data) ~= "table" then
        GLOBAL.error(string.format("bad argument #2 to 'EventTimer.AddTimerDescriptor' (table expected, got %s)", type(data)))
    end

    -- AddPrefabPostInit 和 AddComponentPostInit 保证了有实体的时候计时器才开始工作，避免浪费性能。缺点是必须在游戏加载完成前就注册，否则无效
    if data.timerprefab then
        local function TrackPrefab(self)
            local descriptor = AddTimerDescriptor(self, warningevent, data)
            if not descriptor then return end
            self:ListenForEvent("onremove", function()
                if valid_data[warningevent] ~= descriptor then return end
                MOD_util:Warning(GLOBAL.tostring(warningevent) .. "事件依赖的实体" .. GLOBAL.tostring(data.timerprefab) .. "已被移除")
                if descriptor.task then
                    descriptor.task:Cancel()
                    descriptor.task = nil
                end
                valid_data[warningevent] = nil
                if ShardId and warningtimer[warningevent] then
                    warningtimer[warningevent][ShardId] = { time = 0, text = "" }
                    SyncEventData(warningevent, 0, "event_timerpc", ShardId)
                    SyncEventData(warningevent, "", "event_textrpc", ShardId)
                    if SyncTimer and not data.DisableShardRPC then
                        SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_time_shardrpc"], nil, warningevent, 0)
                        SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_text_shardrpc"], nil, warningevent, "")
                    end
                end

                -- 只在当前实体移除时寻找接替者，正常更新不扫描实体
                if self == GLOBAL.TheWorld or not (GLOBAL.TheWorld and GLOBAL.TheWorld:IsValid()) then return end
                for _, candidate in pairs(GLOBAL.Ents) do
                    if candidate ~= self and candidate.prefab == data.timerprefab and candidate:IsValid() then
                        TrackPrefab(candidate)
                        break
                    end
                end
            end)
        end
        AddPrefabPostInit(data.timerprefab, TrackPrefab)
    else
        AddComponentPostInit(warningevent, function(self)
            AddTimerDescriptor(self, warningevent, data)
        end)
    end
end

if SERVER_SIDE then
    for warningevent, data in pairs(GLOBAL.WarningEvents) do
        if TimerPrefabList[warningevent] then
            data.timerprefab = warningevent
        elseif OtherPrefabList[warningevent] then
            data.timerprefab = OtherPrefabList[warningevent]
        end

        GLOBAL.EventTimer.AddTimerDescriptor(warningevent, data)
    end

    GLOBAL.setmetatable(GLOBAL.WarningEvents, {
        __newindex = function(self, warningevent, data)
            GLOBAL.EventTimer.AddTimerDescriptor(warningevent, data) -- 自动注册
            GLOBAL.rawset(self, warningevent, data)
        end,
        __metatable = "[全局事件计时器] 此元表已锁定"
    })
end

-- 同步固定世界类型标识，显示时再按客户端语言转换
local function GetWorldType()
    local TheWorld = GLOBAL.TheWorld
    if TheWorld:HasTag("porkland") then
        return "porkland"
    elseif TheWorld:HasTag("island") then
        return "shipwrecked"
    elseif TheWorld:HasTag("volcano") then
        return "volcano"
    elseif TheWorld:HasTag("cave") then
        return "cave"
    elseif TheWorld:HasTag("forest") then
        return "forest"
    else
        return "unknown"
    end
end

---------------------------------------客户端更新逻辑---------------------------------------

local function Client_Init()
    local ReplacePrefabName = ReplacePrefabName
    local TimeToString = TimeToString
    local TimerMode = GLOBAL.EventTimer.TimerMode

    local day_str = STRINGS.eventtimer.time.day
    local hour_str = STRINGS.eventtimer.time.hour
    local min_str = STRINGS.eventtimer.time.minutes
    local sec_str = STRINGS.eventtimer.time.seconds

    local Getformat_format_1 = "(%d+)".. day_str .. "(%d+)" .. min_str .. "(%d+)" .. sec_str
    local Getformat_format_2 = "(%d+)" .. hour_str .. "(%d+)" .. min_str .. "(%d+)" .. sec_str

    local function get_new_text(datatext)
        local format = TimerMode == 2 and Getformat_format_2 or Getformat_format_1
        local daytime = TimerMode == 2 and 3600 or GLOBAL.TUNING.TOTAL_DAY_TIME
        -- 只替换时间片段，玩家名字和其它文本中的百分号不参与格式化
        return datatext:gsub(format, function(d, m, s)
            local time = tonumber(d) * daytime + tonumber(m) * 60 + tonumber(s)
            return TimeToString(math.max(0, time - 1))
        end)
    end

    local eventstime = {} -- ThePlayer.HUD.WarningEventTimeData

    function ClientWarningTimer:OnWarningEventDirty(warningevent, type, shardid, data)
        if not data then return end
        -- 初始化
        eventstime[warningevent] = eventstime[warningevent] or {}
        if not eventstime[warningevent][shardid] then
            eventstime[warningevent][shardid] = {
                time = 0,
                text = ""
            }
        end

        if type == "text" then
            -- 同步数据保留Prefab标记，收到后才按本机语言替换名称
            data = ReplacePrefabName(data)
            if GLOBAL.EventTimer.MarkDataSource and shardid ~= current_shardid then
                local world_str = STRINGS.eventtimer.worldtype[world_list[shardid]] or STRINGS.eventtimer.worldtype.unknown
                data = data ~= "" and (string.format(STRINGS.eventtimer.worldid, shardid) .. "(" .. world_str .. ")\n" .. data) or ""
            end
        end

        eventstime[warningevent][shardid][type] = data
        self:RefreshPrediction(warningevent, shardid)
    end

    local client_prediction_tasks = {} -- 客户端预测倒计时任务
    function ClientWarningTimer:RefreshPrediction(warningevent, shardid) -- 刷新客户端预测倒计时
        local data = eventstime[warningevent] and eventstime[warningevent][shardid]
        local event_tasks = client_prediction_tasks[warningevent]
        if event_tasks and event_tasks[shardid] then
            event_tasks[shardid]:Cancel()
            event_tasks[shardid] = nil
        end

        if data and ((data.time or 0) > 0 or (data.text or "") ~= "")
            and GLOBAL.EventTimer.ClientPrediction and not GLOBAL.WarningEvents[warningevent].DisableClientPrediction
            and UpdateTime > 1 and GLOBAL.TheWorld
        then
            if not event_tasks then
                event_tasks = {}
                client_prediction_tasks[warningevent] = event_tasks
            end
            event_tasks[shardid] = GLOBAL.TheWorld:DoPeriodicTask(1, function() self:UpdateClientPrediction(warningevent, shardid) end)
        end
    end

    -- 更新客户端预测倒计时，每个事件单独每秒运行一次
    function ClientWarningTimer:UpdateClientPrediction(warningevent, shardid)
        if not GLOBAL.EventTimer.ClientPrediction or GLOBAL.WarningEvents[warningevent].DisableClientPrediction
            or not (eventstime[warningevent] and eventstime[warningevent][shardid])
        then
            self:RefreshPrediction(warningevent, shardid)
            return
        end

        ----------------------------------------time---------------------------------------

        local time = eventstime[warningevent][shardid].time or 0 -- 本世界time
        time = time - 1
        if time >= 0 then
            eventstime[warningevent][shardid].time = time
        end

        ----------------------------------------text---------------------------------------

        local new_text
        local datatext = eventstime[warningevent][shardid].text or "" -- 本世界text
        if datatext ~= "" then
            new_text = get_new_text(datatext)
            -- 如果get_new_text失败了，直接使用上方的time
            if not new_text then
                if time >= 0 then
                    new_text = TimeToString(time)
                end
            end
        end
        if new_text then
            eventstime[warningevent][shardid].text = new_text -- 更新text
        end
    end

    function ClientWarningTimer:OnHostEventDirty(warningevent, shardid, playerly_data)
        if GLOBAL.WarningEvents[warningevent].playerly then
            if not GLOBAL.ThePlayer then return end
            if GLOBAL.type(playerly_data) ~= "table" then return end
            local data_type, value = GetPlayerEventData(warningevent, playerly_data, GLOBAL.ThePlayer.userid)
            self:OnWarningEventDirty(warningevent, data_type, shardid, value)
        else -- 非玩家数据
            local row = warningtimer[warningevent] and warningtimer[warningevent][shardid]
            if row then -- 主机也使用独立的展示数据，避免本地化和预测改写同步数据
                self:OnWarningEventDirty(warningevent, "time", shardid, row.time or 0)
                self:OnWarningEventDirty(warningevent, "text", shardid, row.text or "")
            end
        end
    end

    function ClientWarningTimer:OnUpdate()
        if not GLOBAL.ThePlayer or not GLOBAL.ThePlayer.HUD then
            return
        end
        if not GLOBAL.ThePlayer.HUD.WarningEventTimeData then
            GLOBAL.ThePlayer.HUD.WarningEventTimeData = eventstime
        end
        GLOBAL.ThePlayer.HUD:UpdateWarningEvents()
    end
end

---------------------------------------主入口---------------------------------------

local cache_world_type = "unknown" -- 默认：未知世界类型
AddPrefabPostInit("world", function(self)
    if CLIENT_SIDE then
        Client_Init()
        self:DoPeriodicTask(0.5, function() ClientWarningTimer:OnUpdate() end)
    end
    GLOBAL.EventTimer.WorldList = world_list -- 方便从其它地方获取世界列表

    --------------------------------------------------
    if not GLOBAL.TheWorld.ismastersim then return end
    --------------------------------------------------

    ShardId = GLOBAL.tonumber(GLOBAL.TheShard:GetShardId())
    current_shardid = ShardId -- 主机不请求get_shard_data，直接设置本地世界ID
    GLOBAL.EventTimer.CurrentShardId = ShardId -- 方便从其它地方获取当前所处世界ID

    -- 初始化事件数据表
    for warningevent in pairs(GLOBAL.WarningEvents) do
        if not warningtimer[warningevent] then
            warningtimer[warningevent] = {
                [ShardId] = {
                    time = 0,
                    text = "",
                }
            }
        end
    end

    cache_world_type = GetWorldType() -- 当前世界类型，用于同步给玩家
    world_list[ShardId] = cache_world_type

    GLOBAL.EventTimer.EventTimerData = warningtimer -- 方便从其它地方获取事件数据
end)

-- 服务器世界互联时同步世界类型
local _Shard_UpdateWorldState = GLOBAL.Shard_UpdateWorldState
GLOBAL.Shard_UpdateWorldState = function(...)
    SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["sync_world_type"], nil, cache_world_type)
    return _Shard_UpdateWorldState(...)
end

-- 玩家进入游戏后同步世界类型数据
if not SERVER_SIDE then
    MOD_util:AddPlayerPostInit(function(world, player)
        if player ~= GLOBAL.ThePlayer then return end
        SendModRPCToServer(MOD_RPC["EventTimer"]["get_shard_data"])
    end, false)
end
