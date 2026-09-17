local SyncTimer = GLOBAL.EventTimer.SyncTimer
local UpdateTime = GLOBAL.EventTimer.UpdateTime
local unpack = GLOBAL.unpack
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
function SyncEventData(event, data, type, shardid) -- 同步数据到客户端
    if GLOBAL.WarningEvents[event].playerly then -- 单独处理playerly数据
        if GLOBAL.type(data) ~= "string" then return end
        local textdata
        if data == "" then
            textdata = {}
        else
            textdata = GLOBAL.json.decode(data)
        end
        if GLOBAL.type(textdata) ~= "table" then return end
        for userid, player in pairs(cache_players) do
            local data_type, value = GetPlayerEventData(event, textdata, userid)
            local rpc_type = data_type == "time" and "event_timerpc" or "event_textrpc"
            if need_sync(player, event, value, rpc_type, shardid) then
                SendModRPCToClient(CLIENT_MOD_RPC["EventTimer"][rpc_type], userid, event, value, shardid)
            end
        end

        if CLIENT_SIDE then -- 主机玩家
            ClientWarningTimer:OnHostEventDirty(event, shardid, textdata)
        end
    else
        for k,v in ipairs(GLOBAL.AllPlayers) do
            if need_sync(v, event, data, type, shardid) then
                SendModRPCToClient(CLIENT_MOD_RPC["EventTimer"][type], v.userid, event, data, shardid)
            end
        end

        if CLIENT_SIDE then -- 主机玩家
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
        warningtimer[event][shardid] = {}
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
        warningtimer[event][shardid] = {}
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
    inst:DoPeriodicTask(UpdateTime, function()
        -- 初始化数据重复次数表
        if not (ShardId and warningtimer[warningevent]) then return end
        if not valid_data[warningevent] then
            valid_data[warningevent] = {
                time_last = 0, -- 上次记录的时间
                time_sametick = 0, -- 重复次数
                time_valid = false, -- 数据是否有效(这个字段用于防止一直触发time = 0)

                text_sametick = 0,
                text_valid = false,
            }
        end

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
        GLOBAL.error(string.format("bad argument #1 to 'AddTimerDescriptor' (string expected, got %s)", type(warningevent)))
    end
    if GLOBAL.type(data) ~= "table" then
        GLOBAL.error(string.format("bad argument #2 to 'AddTimerDescriptor' (table expected, got %s)", type(data)))
    end

    if data.timerprefab then
        AddPrefabPostInit(data.timerprefab, function(self)
            AddTimerDescriptor(self, warningevent, data)
            self:ListenForEvent("onremove", function()
                MOD_util:Warning(GLOBAL.tostring(warningevent) .. "事件依赖的实体" .. GLOBAL.tostring(data.timerprefab) .. "已被移除")
                valid_data[warningevent] = nil
                warningtimer[warningevent][ShardId] = {}
                SyncEventData(warningevent, 0, "event_timerpc", ShardId)
                SyncEventData(warningevent, "", "event_textrpc", ShardId)
                if not data.DisableShardRPC then
                    SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_time_shardrpc"], nil, warningevent, 0)
                    SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_text_shardrpc"], nil, warningevent, "")
                end
            end)
        end)
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

-- 返回当前世界类型对应的字符串
local function GetWorldType()
    local TheWorld = GLOBAL.TheWorld
    if TheWorld:HasTag("porkland") then
        return STRINGS.eventtimer.worldtype.porkland
    elseif TheWorld:HasTag("island") then
        return STRINGS.eventtimer.worldtype.shipwrecked
    elseif TheWorld:HasTag("volcano") then
        return STRINGS.eventtimer.worldtype.volcano
    elseif TheWorld:HasTag("cave") then
        return STRINGS.eventtimer.worldtype.cave
    elseif TheWorld:HasTag("forest") then
        return STRINGS.eventtimer.worldtype.forest
    else
        return STRINGS.eventtimer.worldtype.unknown
    end
end

---------------------------------------客户端更新逻辑---------------------------------------

local function Client_Init()
    local Extract_by_format = Extract_by_format
    local ReplacePrefabName = ReplacePrefabName
    local TimeToString = TimeToString
    local StringToTime = StringToTime
    local TimerMode = GLOBAL.EventTimer.TimerMode

    local day_str = STRINGS.eventtimer.time.day
    local hour_str = STRINGS.eventtimer.time.hour
    local min_str = STRINGS.eventtimer.time.minutes
    local sec_str = STRINGS.eventtimer.time.seconds

    local Getformat_format_1 = "(%d+)".. day_str .. "(%d+)" .. min_str .. "(%d+)" .. sec_str
    local Getformat_format_2 = "(%d+)" .. hour_str .. "(%d+)" .. min_str .. "(%d+)" .. sec_str

    local function Getformat(text)
        local format = TimerMode == 2 and Getformat_format_2 or Getformat_format_1
        return string.gsub(text, format, "%%s")
    end

    local function get_new_text(v, datatext)
        local results = { Extract_by_format(datatext, v) }
        if results[1] then
            for k1, v1 in pairs(results) do
                if string.find(v1, min_str .. "(.*)" .. sec_str) then
                    v1 = StringToTime(v1) -- 尝试将字符串转为数字
                    if type(v1) == "number" then
                        v1 = v1 - 1
                        if v1 < 0 then
                            results[k1] = TimeToString(0) -- 小于0时停止计算
                        else
                            results[k1] = TimeToString(v1) -- 减一后转换为字符串保存到results对应的值里
                        end
                    end
                end
            end
            v = v:gsub("%%([^sd%%])", "%%%%%1")
            v = v:gsub("%%$", "%%%%")
            local new_text = string.format(ReplacePrefabName(v), unpack(results))
            return new_text
        else
            return
        end
    end

    local eventstime = {} -- ThePlayer.HUD.WarningEventTimeData
    for warningevent, data in pairs(GLOBAL.WarningEvents) do
        -- 个人事件需要单独的展示数据
        if not SERVER_SIDE or data.playerly then -- 客户端初始全部数据，主机玩家初始playerly数据
            eventstime[warningevent] = {}
        end
    end

    function ClientWarningTimer:OnWarningEventDirty(warningevent, type, shardid, data)
        if not data then return end
        -- 初始化
        if not eventstime[warningevent][shardid] then
            eventstime[warningevent][shardid] = {
                time = 0,
                text = ""
            }
        end

        -- 为其它世界的事件添加前缀标记。值得一提的是主机玩家会因为这个功能重复标记其它世界的数据，但如果存在主机玩家就不存在多层世界。
        if type == "text" and GLOBAL.EventTimer.MarkDataSource and shardid ~= current_shardid then
            data = data ~= "" and (string.format(STRINGS.eventtimer.worldid, shardid) .. "(" .. (world_list[shardid] or "???") .. ")\n" .. data) or ""
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
            new_text = get_new_text(Getformat(datatext), datatext)
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
            eventstime[warningevent] = warningtimer[warningevent] -- 直接使用权威值
            local row = eventstime[warningevent] and eventstime[warningevent][shardid]
            if row then -- 设置默认值避免nil
                row.time = row.time or 0
                row.text = row.text or ""
            end
            self:RefreshPrediction(warningevent, shardid)
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

local cache_world_type = STRINGS.eventtimer.worldtype.unknown -- 默认：未知世界类型
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
                [ShardId] = {}
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
