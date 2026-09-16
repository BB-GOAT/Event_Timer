local info
info = {
    gettimefn = function(self)
        return GetWorldSettingsTimeLeft("ROC_RESPAWN_TIMER")
    end,
    gettextfn = function(self, time)
        local data = self:OnSave()
        if data.roc then
            return ReplacePrefabName(STRINGS.eventtimer.rocmanager.exists)
        end
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
    announcefn = function(context)
        local time = context.time
        local text = context.text
        local desc
        if string.find(text, ReplacePrefabName(STRINGS.eventtimer.rocmanager.exists)) then
            desc = ReplacePrefabName(STRINGS.eventtimer.rocmanager.exists)
        elseif time > 0 then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.rocmanager.cooldown), TimeToString(time))
        end
        desc = MarkData(desc, context)
        return desc
    end,
    tipsfn = function(context)
        local time = context.time
        local text = context.text
        if time > TUNING.SEG_TIME and time <= 90 then -- 如果没有目标玩家就从0变成30，为了防止重复tips需修改此处
            return true, info.announcefn, 10, nil, 2
        elseif JustEntered(time) and time < 960 then
            return true, info.announcefn, 10, nil, 2
        elseif text == ReplacePrefabName(STRINGS.eventtimer.rocmanager.exists) then
            local desc = ReplacePrefabName(STRINGS.eventtimer.rocmanager.tips)
            desc = MarkData(desc, context)
            return true, StringToFunction(desc), 10, nil, 3
        elseif JustEntered(time) then
            return true, info.announcefn, 10, nil, 1
        end
        return false
    end
}

return info