----------------------------------------------------------------------------------------------

-- 纯本地获取方式
if not (EventTimer.GetTimeFromRemoteCommand or EventTimer.GetTimeFromServerMod) then
    -- 根据警告等级（2~4）和当前等级内的触发次数，估算 Boss 距离到达的秒数并播报
    -- 等级越高 = 越近；同一等级每次触发间隔约 15 秒
    local record_table = {}
    local function DoBossWarning(level, times)
        -- 特殊情况：level4 第 3 次触发意味着 Boss 即将到达
        local time
        if level == 4 and times == 3 then
            time = 3
        else
            -- 通用公式：(5 - level) * 30 - 15 * (times - 1)
            -- level=2,times=1 → 90s；level=4,times=1 → 30s；以此类推
            time = (5 - level) * 30 - 15 * (times - 1)
        end

        local data_time = ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData["deerclopsspawner_time"]
        if (time < data_time) or (data_time == 0) then
            SaveTimeData("deerclopsspawner", time)
        end
    end

    for i = 2, 4 do
        local level = tostring(i)
        AddPrefabPostInit("deerclopswarning_lvl" .. level, function(inst)
            -- 取消上一个重置任务（若存在），并重新设置 60 秒后的自动重置
            -- 作用：如果 60 秒内没有新警告触发，则清空计数，准备下一轮
            if record_table.task then
                record_table.task:Cancel()
                record_table.task = nil
            end

            -- 重置其他等级的计数
            for k, v in pairs(record_table) do
                if type(v) == "number" and k ~= level then
                    record_table[k] = 0
                end
            end

            -- 累加触发次数，超过上限则循环回 1
            -- 上限 = level - 1（lvl2 上限 1 次，lvl3 上限 2 次，lvl4 上限 3 次）
            record_table[level] = (record_table[level] or 0) + 1
            if record_table[level] > i - 1 then
                record_table[level] = 1
            end

            -- 发送警告消息
            DoBossWarning(i, record_table[level])

            record_table.task = TheWorld:DoTaskInTime(60, function()
                record_table.task = nil
                record_table = {} -- 重置状态
            end)
        end)
    end
end

----------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------

local info
info = {
    animchangefn = ChangeanimByWintersFeast,
    defaultanim = {
        scale = 0.044,
        bank = "deerclops",
        build = "deerclops_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -6,
        },
    },
    winterfeastanim = {
        scale = 0.046,
        bank = "deerclops",
        build = "deerclops_yule",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = -2,
            y = -8,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.deerclopsspawner_time
        local text = ThePlayer.HUD.WarningEventTimeData.deerclopsspawner_text
        local target, _ = Extract_by_format(text, STRINGS.eventtimer.deerclopsspawner.targeted)
        if target and time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.deerclopsspawner.target), target, TimeToString(time))
        elseif time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.deerclopsspawner.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.deerclopsspawner_time
        if time > 2 and time <= 60 and GetWorldtypeStr() == "forest" then
            return true, info.announcefn, time, nil, 2
        elseif time == 480 or JustEntered(time) then
            return true, info.announcefn, 10, nil, 2
        elseif ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.deerclopsspawner.attack)), 10, time, 3
        end
        return false
    end
}

return info