-- main, what can i say?

MOD_util:AddPlayerPostInit(function(world, player)
    if player ~= GLOBAL.ThePlayer then return end
    -- 从远程命令获取时间数据
    if GLOBAL.EventTimer.GetTimeFromRemoteCommand then
        player:DoTaskInTime(2, function()
            local cmd = [[
if not rawget(_G, "EventTimerClient") then
    rawset(_G, "EventTimerClient" , {})
    _G.EventTimerClient.TimerPrefabs = {}

    local function HookPrefab(prefab)
        for guid, ent in pairs(Ents) do
            if ent.prefab == prefab then
                _G.EventTimerClient.TimerPrefabs[prefab] = ent
                ent:ListenForEvent("onremove", function()
                    _G.EventTimerClient.TimerPrefabs[prefab] = nil
                end)
                return ent
            end
        end
    end

    _G.EventTimerClient.GetWorldSettingsTimeLeft = function(name, prefab)
        local ent = TheWorld
        if prefab then
            ent = _G.EventTimerClient.TimerPrefabs[prefab] or HookPrefab(prefab)
        end
        if ent and ent.components.worldsettingstimer then
            if not ent.components.worldsettingstimer:IsPaused(name) then
                local time = ent.components.worldsettingstimer:GetTimeLeft(name)
                return time
            end
        end
        return 0
    end
end
            ]]
            BBGOAT_util:remote(cmd, nil, function(res)
                if res and res.err then
                    print("[警告] 在服务器初始化EventTimerClient失败：\n" .. tostring(res.err))
                end
            end) -- 初始化工具
        end)

        local MainThread
        local GetTimeThreadList, GetTextThreadList = {}, {}
        local MainFn = function()
            for warningevent, data in pairs(WarningEvents) do
                if data.remotegettimefn then
                    GetTimeThreadList[warningevent] = GLOBAL.StartThread(function()
                        while true do
                            local ThePlayer = GLOBAL.ThePlayer
                            if ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData then
                                -- print("DEBUG: 正在触发事件" .. warningevent .. "的远程timefn")
                                data.remotegettimefn() -- 存数据的过程应该在fn内完成
                            end
                            GLOBAL.Sleep(data.remotegettimefninterval or 30) -- 该事件每30秒请求一次
                        end
                    end, "EventTimerModGetTimeFromRemoteCommand_" .. warningevent)

                    GLOBAL.Sleep(0.5) -- gettime 和 gettext 间隔0.5秒
                end
                if data.remotegettextfn then
                    GetTextThreadList[warningevent] = GLOBAL.StartThread(function()
                        while true do
                            local ThePlayer = GLOBAL.ThePlayer
                            if ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData then
                                -- print("DEBUG: 正在触发事件" .. warningevent .. "的远程textfn")
                                data.remotegettextfn() -- 存数据的过程应该在fn内完成
                            end
                            GLOBAL.Sleep(data.remotegettextfninterval or 30) -- 该事件每30秒请求一次
                        end
                    end, "EventTimerModGetTextFromRemoteCommand_" .. warningevent)

                    GLOBAL.Sleep(1) -- 每个事件至少间隔1秒请求
                end
            end

            -- 主线程执行完成，自我销毁
            GLOBAL.KillThreadsWithID(MainThread.id)
            MainThread = nil
        end

        -- 玩家初始化后3秒开始主任务
        player:DoTaskInTime(3, function()
            MainThread = GLOBAL.StartThread(MainFn, "EventTimerModMainThread")
        end)

        function GetRemoteThreadList() -- 用于给其它代码获取线程列表
            return GetTimeThreadList, GetTextThreadList
        end

        print("DEBUG: 全局事件计时器客户端版 初始化远程请求线程完成")
    end
end, true) -- 换人后不重复执行