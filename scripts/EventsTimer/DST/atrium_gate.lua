-- 远古大门

local info
info = {
    gettimefn = function()
        if not (TimerPrefabs.atrium_gate and TimerPrefabs.atrium_gate.components.worldsettingstimer) then return end
        return GetWorldSettingsTimeLeft("cooldown", "atrium_gate")() or GetWorldSettingsTimeLeft("destabilizing", "atrium_gate")()
    end,
    gettextfn = function(time)
        if time and time > 0 then
            if GetWorldSettingsTimeLeft("cooldown", "atrium_gate")() then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.atrium_gate.cooldown), TimeToString(time))
            else
                return string.format(STRINGS.eventtimer.atrium_gate.destabilizing, TimeToString(time))
            end
        end
    end,
    anim = {
        scale = 0.055,
        bank = "atrium_gate",
        build = "atrium_gate",
        animation = "idle",
        uioffset = {
            x = -2,
            y = -5,
        },
    },
    announcefn = function(context)
        local text = context.text
        text = string.gsub(text,"\n",": ")
        return text
    end,
}

return info