local roc
local info
info = {
    remotegettimefn = function(Thread)
        GetWorldSettingsTimeLeft("ROC_RESPAWN_TIMER", nil, function(res)
            if res and res.err then
                SaveTimeData("rocmanager", 0)
                print('[警告] rocmanager remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("rocmanager", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
    remotegettextfn = function(Thread)
        local cmd = [[
            local self = TheWorld.net.components.rocmanager
            if not self then return DataDumper({ not_found = true }) end
            local data = self:OnSave()
            return DataDumper({ roc = data.roc })
        ]]
        BBGOAT_util:remote(cmd, nil, function(res)
            if res and res.err then
                SaveTextData("rocmanager", "")
                print('[警告] rocmanager remotegettextfn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res then
                roc = res.roc
                SaveTextData("rocmanager", roc and ReplacePrefabName(STRINGS.eventtimer.rocmanager.exists) or "")
            end
        end)
    end,
    image = {
        atlas = "images/Roc.xml",
        tex = "Roc.tex",
    },
    anim = {
        scale = 0.008,
        build = "roc_head_build",
        bank = "head",
        animation = "idle_loop",
        loop = true,
        offset = {
            x = 0,
            y = -15,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.rocmanager_time
        if roc then
            return ReplacePrefabName(STRINGS.eventtimer.rocmanager.exists)
        elseif time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.rocmanager.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.rocmanager_time
        if time > TUNING.SEG_TIME and time <= 90 then -- 如果没有目标玩家就从0变成30，为了防止重复tips需修改此处
            return true, info.announcefn, 10, nil, 2
        elseif JustEntered(time) and time < 960 then
            return true, info.announcefn, 10, nil, 2
        elseif roc then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.rocmanager.tips)), 10, nil, 3
        elseif JustEntered(time) then
            return true, info.announcefn, 10, nil, 1
        end
        return false
    end
}

return info