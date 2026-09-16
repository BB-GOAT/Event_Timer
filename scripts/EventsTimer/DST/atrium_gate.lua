-- 远古大门

local info
info = {
    gettimefn = function(self)
        if not (self and self.components.worldsettingstimer) then return end
        return GetWorldSettingsTimeLeft("cooldown", self) or GetWorldSettingsTimeLeft("destabilizing", self)
    end,
    gettextfn = function(self, time)
        if time and time > 0 then
            if GetWorldSettingsTimeLeft("cooldown", self) then
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