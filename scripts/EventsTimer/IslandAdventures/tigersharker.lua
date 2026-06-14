local remotegettimefn = function(Thread)
    local cmd = [[
        local self = TheWorld.components.tigersharker
        if not self then return DataDumper({ not_found = true }) end

        local appear_time = self:TimeUntilCanAppear()
        local respawn_time = self:TimeUntilRespawn()
        local time = math.max(appear_time, respawn_time)
        return DataDumper({ time = time })
    ]]
    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.err then
            SaveTimeData("tigersharker", 0)
            print('[警告] tigersharker remotegettimefn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res and res.time then
            SaveTimeData("tigersharker", res.time)
        elseif res and res.not_found then
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
        end
    end)
end

----------------------------------------------------------------------------------------------

local remotegettextfn = function(Thread)
    local cmd = [[
        local self = TheWorld.components.tigersharker
        if not self then return DataDumper({ not_found = true })end
        if self.shark then
            return DataDumper({ shark = self.shark })
        elseif self:CanSpawn(true, true) then
            return DataDumper({ canspawn = true })
        end
        return DataDumper({ nospawn = true })
    ]]

    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.err then
            SaveTextData("tigersharker", "")
            print('[警告] tigersharker remotegettextfn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res then
            local shark = res.shark
            local canspawn = res.canspawn
            local nospawn = res.nospawn
            if shark then
                SaveTextData("tigersharker", ReplacePrefabName(STRINGS.eventtimer.tigersharker.exists))
            elseif canspawn then
                local time = ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData and ThePlayer.HUD.WarningEventTimeData.tigersharker_time
                if time and time > 0 then
                    SaveTextData("tigersharker", string.format(ReplacePrefabName(STRINGS.eventtimer.tigersharker.cooldown), TimeToString(time)))
                else
                    SaveTextData("tigersharker", STRINGS.eventtimer.tigersharker.readytext)
                end
            elseif nospawn then
                SaveTextData("tigersharker", ReplacePrefabName(STRINGS.eventtimer.tigersharker.nospawn))
            end
        end
    end)
end

----------------------------------------------------------------------------------------------

-- 虎鲨出现/消失时刷新数据
if not EventTimer.GetTimeFromServerMod["tigersharker"] and EventTimer.GetTimeFromRemoteCommand then
    AddPrefabPostInit("tigearshark", function(inst)
        -- remotegettimefn() -- 时间理论上是0，更新了个寂寞
        remotegettextfn()
        inst:ListenForEvent("onremove", function()
            remotegettimefn()
            remotegettextfn()
        end)
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    remotegettimefn = remotegettimefn,
    remotegettextfn = remotegettextfn,
    DisableClientPredictionClearText = true,
    anim = {
        scale = 0.03,
        bank = "tigershark",
        build = "tigershark_ground_build",
        animation = "taunt",
        loop = true,
        uioffset = {
            x = -6,
            y = -6,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.tigersharker_time
        local text = ThePlayer.HUD.WarningEventTimeData.tigersharker_text
        local exists = string.find(text, ReplacePrefabName(STRINGS.eventtimer.tigersharker.exists))
        local nospawn = string.find(text, ReplacePrefabName(STRINGS.eventtimer.tigersharker.nospawn))
        if exists then
            return ReplacePrefabName(STRINGS.eventtimer.tigersharker.exists)
        elseif nospawn then
            return ReplacePrefabName(STRINGS.eventtimer.tigersharker.nospawn)
        elseif time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.tigersharker.cooldown), TimeToString(time))
        else
            return ReplacePrefabName(STRINGS.eventtimer.tigersharker.ready)
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.tigersharker_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.tigersharker.tips)), 10, time, 2
        end
        return false
    end
}

return info