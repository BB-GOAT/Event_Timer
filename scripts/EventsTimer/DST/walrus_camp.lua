local walrus_house_num
local function GetSeparator(i)
    local items_per_line = walrus_house_num
    items_per_line = items_per_line < 5 and 1 or items_per_line < 9 and 2 or 3
    if (i - 1) % items_per_line == 0 then
        return "\n"
    else
        return " "
    end
end

----------------------------------------------------------------------------------------------

-- 纯本地获取方式
local localgettimefn = function()
    local walrus_list = {} -- 需要计时的海象重生列表

    local SessionId
    local function SaveData()
        local filedata = RW_Data:GetValue("WarningEventTimeData") or {}
        SessionId = SessionId or (TheWorld and TheWorld.net and TheWorld.net.components.shardstate and TheWorld.net.components.shardstate:GetMasterSessionId())
        local world_data = SessionId and filedata[SessionId]
        if world_data then
            world_data["walrus_camp"] = walrus_list

            world_data.save_time = os.time() -- 记录此存档最后一次更新事件记录的时间，以便清理长期未游玩的存档数据
            RW_Data:SetValue("WarningEventTimeData", filedata)
        end
    end

    local function RefreshData()
        SaveData()
        walrus_house_num = #walrus_list -- 更新海象数量

        local lines = {}
        for i, targe_time in ipairs(walrus_list) do
            local time_left = targe_time - GetWorldTime()
            if time_left > 0 then
                local time_str = TimeToString(time_left)
                table.insert(lines, string.format(STRINGS.eventtimer.walrus_camp.cooldown, i, time_str))
            end
        end
        local description = ""
        for i, line in ipairs(lines) do
            description = description .. (i == 1 and "" or GetSeparator(i)) .. line
        end
        SaveTextData("walrus_camp", description)
    end
    AddPrefabPostInit("walrus", function(inst)
        inst:ListenForEvent("onremove", function(inst)
            if inst and inst:IsValid() and inst.AnimState then
                local bank, anim, frame = inst.AnimState:GetHistoryData()
                if anim:find("death") then
                    local world_time = GetWorldTime()
                    local targe_time = world_time + TUNING.WALRUS_REGEN_PERIOD
                    table.insert(walrus_list, targe_time)
                    TheWorld:DoTaskInTime(TUNING.WALRUS_REGEN_PERIOD, function()
                        table.removetablevalue(walrus_list, targe_time)
                        RefreshData()
                    end)
                    RefreshData()
                end
            end
        end)
    end)

    -- 读取数据
    AddLoadDataFilePostInit(function(world_data)
        walrus_list = world_data["walrus_camp"] or walrus_list
        RefreshData()
    end)
end

----------------------------------------------------------------------------------------------

local remotegettextfn = function(Thread)
    if not (TheWorld and TheWorld.state.iswinter) then SaveTextData("walrus_camp", "") return end
    local cmd = [[
        local function GetWorldSettingsTimeLeft(name, ent)
            if ent and ent.components.worldsettingstimer then
                if not ent.components.worldsettingstimer:IsPaused(name) then
                    local time = ent.components.worldsettingstimer:GetTimeLeft(name)
                    return time
                end
            end
        end

        if not _G.EventTimerClient.walrus_house_list then
            _G.EventTimerClient.walrus_house_list = {}
            for guid, ent in pairs(Ents) do
                if ent.prefab == "walrus_camp" then
                    local x, y, z = ent.Transform:GetWorldPosition()
                    table.insert(_G.EventTimerClient.walrus_house_list, {ent = ent, x = x, z = z})
                end
            end
        end

        local data = {}
        for i, info in ipairs(_G.EventTimerClient.walrus_house_list) do
            local pos_x, pos_z = info.x, info.z
            local time = GetWorldSettingsTimeLeft("walrus", info.ent) or -1
            table.insert(data, {time = time, pos_x = pos_x, pos_z = pos_z})
        end
        return DataDumper({data = data})
    ]]
    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.data then
            walrus_house_num = #res.data
            table.sort(res.data, function(a, b) -- 按坐标排序，使得每次序号一致
                return a.pos_x < b.pos_x
            end)
            local lines = {}
            for i, info in ipairs(res.data) do
                local time_str = info.time <= 0 and STRINGS.eventtimer.walrus_camp.ready or TimeToString(info.time)
                table.insert(lines, string.format(STRINGS.eventtimer.walrus_camp.cooldown, i, time_str))
            end
            local description = ""
            for i, line in ipairs(lines) do
                description = description .. (i == 1 and "" or GetSeparator(i)) .. line
            end
            SaveTextData("walrus_camp", description)
        else
            SaveTextData("walrus_camp", "")
            if res and res.err then
                print('[警告] walrus_camp remotegettextfn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end
    end)
end

-- 海象死亡时立刻更新一次数据
if EventTimer.GetTimeFromRemoteCommand then
    AddPrefabPostInit("walrus", function(inst)
        inst:ListenForEvent("onremove", function(inst)
            if inst and inst:IsValid() and inst.AnimState then
                local bank, anim, frame = inst.AnimState:GetHistoryData()
                if anim:find("death") then
                    remotegettextfn()
                end
            end
        end)
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    localgettimefn = localgettimefn,
    remotegettextfn = remotegettextfn,
    DisableClientPredictionClearText = true,
    anim = {
        scale = 0.05,
        bank = "walrus_house",
        build = "walrus_house",
        animation = "idle",
        loop = true,
    },
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.walrus_camp_text
        text = string.gsub(text, "\n", " ")
        return ReplacePrefabName("<prefab=walrus_camp>") .. " : " .. text
    end
}

return info