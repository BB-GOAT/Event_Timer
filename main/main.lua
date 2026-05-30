-- main, what can i say?

AddPrefabPostInit("world",function(inst)
    inst:DoPeriodicTask(0.5, function()
        local ThePlayer = GLOBAL.ThePlayer
        if not ThePlayer or not ThePlayer.HUD then
            return
        end
        ThePlayer.HUD:UpdateWarningEvents()
    end)

    -- 更新倒计时数据
    -- inst:DoPeriodicTask(GLOBAL.EventTimer.UpdateTime, function()
    --     for warningevent, data in pairs(WarningEvents) do
    --         local time
    --         if data.gettimefn then
    --             time = data.gettimefn()
    --             if time then
    --                 if time < 0 then time = 0 end -- 避免被负数影响
    --                 SaveTimeData(warningevent, time)
    --             end
    --         end

    --         -- if data.gettextfn then
    --         --     local text = data.gettextfn(time)
    --         --     if text then

    --         --     end
    --         -- end
    --     end
    -- end)
end)

MOD_util:AddPlayerPostInit(function(world, player)
    if player ~= GLOBAL.ThePlayer then return end
    -- 从远程命令获取时间数据
    if GLOBAL.EventTimer.GetTimeFromRemoteCommand then
        player:DoTaskInTime(2, function()
            BBGOAT_util:remote() -- 初始化工具
        end)

        local GetTimeThread, GetTextThread
        local function GetTimeFromRemoteCommand()
            for warningevent, data in pairs(WarningEvents) do
                if data.remotegettimefn then
                    data.remotegettimefn() -- 存数据的过程应该在fn内完成
                end
                GLOBAL.Sleep(0.5)
            end
            GLOBAL.KillThreadsWithID(GetTimeThread.id)
            GetTimeThread = nil
        end
        local function GetTextFromRemoteCommand()
            for warningevent, data in pairs(WarningEvents) do
                if data.remotegettextfn then
                    data.remotegettextfn() -- 存数据的过程应该在fn内完成
                end
                GLOBAL.Sleep(0.5)
            end
            GLOBAL.KillThreadsWithID(GetTextThread.id)
            GetTextThread = nil
        end

        player:DoTaskInTime(3, function()
            GetTimeThread = GLOBAL.StartThread(GetTimeFromRemoteCommand, "EventTimerModGetTimeFromRemoteCommand")
            GetTextThread = GLOBAL.StartThread(GetTextFromRemoteCommand, "EventTimerModGetTextFromRemoteCommand")
        end)

        TheWorld:DoPeriodicTask(30, function() -- 30秒更新一次
            GetTimeThread = GLOBAL.StartThread(GetTimeFromRemoteCommand, "EventTimerModGetTimeFromRemoteCommand")
            GetTextThread = GLOBAL.StartThread(GetTextFromRemoteCommand, "EventTimerModGetTextFromRemoteCommand")
        end)
    end
end)