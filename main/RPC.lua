local SyncTimer = GetModConfigData("SyncTimer")
local UpdateTime = GetModConfigData("UpdateTime")
local tostring = GLOBAL.tostring
-- local checknumber = GLOBAL.checknumber
-- local checkstring = GLOBAL.checkstring

local warningtimer = {} -- 所有事件的time、text、time_shardrpc、text_shardrpc数据，包含nil数据 注意判空
local ClientWarningTimer = {}

local function need_sync(player, event, type, data)
    if not player.event_timer_last_sync_data then player.event_timer_last_sync_data = {} end

    if not player.event_timer_last_sync_data[event .. "_" .. type] or
           player.event_timer_last_sync_data[event .. "_" .. type] ~= data
    then
        player.event_timer_last_sync_data[event .. "_" .. type] = data
        return true
    end
    return false
end

---@param event string 事件名
---@param type "event_timerpc"|"event_textrpc"
local function SyncEventData(event, type) -- 同步数据到客户端
    local data
    if type == "event_timerpc" then
        local time = warningtimer[event .. "_time"]
        local shard_time = warningtimer[event .. "_time_shardrpc"]
        data = (time and time > 0 and time) or (shard_time and shard_time > 0 and shard_time) or 0
    elseif type == "event_textrpc" then
        local text = warningtimer[event .. "_text"]
        local shard_text = warningtimer[event .. "_text_shardrpc"]
        data = (text and text ~= "" and text) or (shard_text and shard_text ~= "" and shard_text) or ""
    else
        MOD_util:Warning("SyncEventData: 检测到非法调用，event = " .. tostring(event) .. "\ttype = " .. tostring(type))
        return
    end

    for k,v in ipairs(AllPlayers) do
        if need_sync(v, event, type, data) then
            SendModRPCToClient(CLIENT_MOD_RPC["EventTimer"][type], v.userid, event, data)
        end
    end
end

----------------------------------------多层世界同步---------------------------------------

AddShardModRPCHandler("EventTimer", "event_time_shardrpc", function(shardid, event, timedata, worldtype)
    if GLOBAL.TheShard:GetShardId() == tostring(shardid) then return end
    if not SyncTimer then return end -- 未开启同步功能，取消同步
    -- if not (checkstring(event) and checknumber(timedata) and checkstring(worldtype)) then return end

    local event_time_shardrpc = event .. "_time_shardrpc"
    local event_text_shardrpc = event .. "_text_shardrpc"

    warningtimer[event_time_shardrpc] = timedata
    SyncEventData(event, "event_timerpc")

    warningtimer[event_text_shardrpc] = timedata > 0 and string.format(STRINGS.eventtimer.worldid, shardid) .. "(" .. worldtype .. ")\n" .. TimeToString(timedata) or "" -- 同时设置text，以显示来自哪个世界
    SyncEventData(event, "event_textrpc")
end)

AddShardModRPCHandler("EventTimer", "event_text_shardrpc", function(shardid, event, textdata, worldtype)
    if GLOBAL.TheShard:GetShardId() == tostring(shardid) then return end
    if not SyncTimer then return end -- 未开启同步功能，取消同步
    -- if not (checkstring(event) and checkstring(textdata) and checkstring(worldtype)) then return end

    local event_text_shardrpc = event .. "_text_shardrpc"

    textdata = textdata ~= "" and (string.format(STRINGS.eventtimer.worldid, shardid) .. "(" .. worldtype .. ")\n" .. textdata)
    warningtimer[event_text_shardrpc] = textdata or ""
    SyncEventData(event, "event_textrpc")
end)

---------------------------------------客机RPC---------------------------------------

AddClientModRPCHandler("EventTimer", "event_timerpc", function(event, time)
    -- if not (checkstring(event) and checknumber(time)) then return end
    warningtimer[event .. "_time"] = time
    ClientWarningTimer:OnWarningEventDirty(event, "time", true)
end)

AddClientModRPCHandler("EventTimer", "event_textrpc", function(event, text)
    -- if not (checkstring(event) and checkstring(text)) then return end
    warningtimer[event .. "_text"] = text
    ClientWarningTimer:OnWarningEventDirty(event, "text", true)
end)

---------------------------------------服务器更新逻辑---------------------------------------

local cache_world_type = STRINGS.eventtimer.worldtype.unknown -- 默认：未知世界类型
local valid_data = {}
local function UpdateEventData()
    for warningevent, data in pairs(GLOBAL.WarningEvents) do

        -- 初始化数据重复次数表
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
            time = data.gettimefn()
            if time and time < 0 then time = 0 end -- 避免被负数影响

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
                    warningtimer[warningevent .. "_time"] = 0 -- 更新本世界数据
                    SyncEventData(warningevent, "event_timerpc")

                    if SyncTimer and not data.DisableShardRPC then -- 更新其它世界数据
                        SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_time_shardrpc"], nil, warningevent, 0, cache_world_type)
                    end
                end
            elseif time and time > 0  then -- 时间有效
                valid_data[warningevent].time_valid = true -- 标记数据有效
                warningtimer[warningevent .. "_time"] = time -- 更新本世界数据
                SyncEventData(warningevent, "event_timerpc")

                if SyncTimer and not data.DisableShardRPC then -- 更新其它世界数据
                    SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_time_shardrpc"], nil, warningevent, time, cache_world_type)
                end
            else -- 无效数据
                warningtimer[warningevent .. "_time"] = 0
                SyncEventData(warningevent, "event_timerpc")
            end
        end
        if data.gettextfn then
            local text = data.gettextfn(time)

            -- 更新本世界数据
            warningtimer[warningevent .. "_text"] = text or ""
            SyncEventData(warningevent, "event_textrpc")

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
                        SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_text_shardrpc"], nil, warningevent, "", "")
                    end
                elseif text and text ~= "" then
                    valid_data[warningevent].text_valid = true -- 标记数据有效
                    SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_text_shardrpc"], nil, warningevent, text, cache_world_type)
                end
            end
        end
    end
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
    else
        return STRINGS.eventtimer.worldtype.forest
    end
end

---------------------------------------客户端更新逻辑---------------------------------------

local Extract_by_format = Extract_by_format
local ReplacePrefabName = ReplacePrefabName
local TimeToString = TimeToString
local StringToTime = StringToTime
local TimerMode = GetModConfigData("BossTimer")

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
for warningevent in pairs(GLOBAL.WarningEvents) do
    -- 初始化eventstime表，防止数据为nil
    eventstime[warningevent .. "_text"] = ""
    eventstime[warningevent .. "_time"] = 0
end

local client_prediction_tasks = {} -- 客户端预测倒计时任务
function ClientWarningTimer:OnWarningEventDirty(warningevent, type, fromserver)
    if type == "text" then
        eventstime[warningevent .. "_text"] = warningtimer[warningevent .. "_text"] or ""
    else
        eventstime[warningevent .. "_time"] = warningtimer[warningevent .. "_time"] or 0
    end

    if GLOBAL.EventTimer.ClientPrediction then
        if fromserver and client_prediction_tasks[warningevent] then
            client_prediction_tasks[warningevent]:Cancel()
            client_prediction_tasks[warningevent] = nil
        end

        if not client_prediction_tasks[warningevent] and UpdateTime > 1 then
            client_prediction_tasks[warningevent] = GLOBAL.TheWorld:DoPeriodicTask(1, function() self:UpdateClientPrediction(warningevent) end)
        end
    elseif client_prediction_tasks[warningevent] then
        client_prediction_tasks[warningevent]:Cancel()
        client_prediction_tasks[warningevent] = nil
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

function ClientWarningTimer:UpdateClientPrediction(warningevent) -- 每个事件单独每秒运行一次
    local Dirty = false

    ----------------------------------------time---------------------------------------

    local time = warningtimer[warningevent .. "_time"] or 0 -- 本世界time
    time = time - 1
    if time >= 0 then
        warningtimer[warningevent .. "_time"] = time
        Dirty = true
    end

    ----------------------------------------text---------------------------------------

    local new_text

    local datatext = warningtimer[warningevent .. "_text"] or "" -- 本世界text

    if datatext ~= "" then
        new_text = get_new_text(Getformat(datatext), datatext)

        -- 如果上方的匹配失败了，直接使用上上方的time
        if not new_text then
            if time >= 0 then
                new_text = TimeToString(time)
            end
        end
    end

    if new_text then
        warningtimer[warningevent .. "_text"] = new_text -- 更新text
        Dirty = true
    end

    if Dirty then
        -- 更新数据
        self:OnWarningEventDirty(warningevent, "text")
        self:OnWarningEventDirty(warningevent, "time")
    end
end

---------------------------------------主入口---------------------------------------

AddPrefabPostInit("world", function(self)
    if not GLOBAL.TheNet:IsDedicated() then
        self:DoPeriodicTask(0.5, function() ClientWarningTimer:OnUpdate() end)
    end

    if not TheWorld.ismastersim then return end

    GLOBAL.EventTimer.EventTimerData = warningtimer -- 方便从其它地方获取事件数据
    self:DoPeriodicTask(UpdateTime, UpdateEventData)
    cache_world_type = GetWorldType()
end)