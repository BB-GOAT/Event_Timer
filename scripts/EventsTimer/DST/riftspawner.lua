local lunar_rift_worlds = {
    forest = true,
    shipwrecked = true,
}

local shadow_rift_worlds = {
    cave = true,
    volcano = true,
}

local info
info = {
    gettimefn = function(self) -- 当裂隙出现时，不显示
        if (lunar_rift_worlds[GetWorldtypeStr()] and (table.typecheckedgetfield(EventTimer.EventTimerData, "string", "lunarrift_portal", EventTimer.CurrentShardId, "text") or "") == "")
            or (shadow_rift_worlds[GetWorldtypeStr()] and (table.typecheckedgetfield(EventTimer.EventTimerData, "string", "shadowrift_portal", EventTimer.CurrentShardId, "text") or "") == "")
        then
            return GetWorldSettingsTimeLeft("rift_spawn_timer")
        end
    end,
    imagechangefn = ChangeimageByWorld,
    forestimage = {
        atlas = "minimap/minimap_data.xml",
        tex = "lunarrift_portal.png",
        scale = 0.8,
        offset = {
            x = 0,
            y = 13,
        },
    },
    caveimage = {
        atlas = "minimap/minimap_data.xml",
        tex = "shadowrift_portal.png",
        scale = 0.8,
        offset = {
            x = 0,
            y = 13,
        },
    },
    animchangefn = ChangeanimByWorld,
    forestanim = {
        scale = 0.05,
        build = "lunar_rift_portal",
        bank = "lunar_rift_portal",
        animation = "stage_3_loop",
        offset = {
            x = 0,
            y = -16,
        },
        loop = true,
    },
    announcefn = function(context)
        local str = (lunar_rift_worlds[context.world_type] and STRINGS.eventtimer.riftspawner.lunar_cooldown)
                    or (shadow_rift_worlds[context.world_type] and STRINGS.eventtimer.riftspawner.shadow_cooldown)
                    or ReplacePrefabName(STRINGS.eventtimer.riftspawner.cooldown)
        local desc = string.format(str, TimeToString(context.time))
        desc = MarkData(desc, context)
        return desc
    end,
}

return info