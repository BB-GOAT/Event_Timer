local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("pig_bandit_respawn_time_"),
    gettextfn = function(time)
        local self = TheWorld.components.banditmanager
        if not self then return end
        local str = self:GetDebugString()
        local stolen_oincs, active_bandit = string.match(str, "Stolen Oincs: (%d+) Active Bandit: (%a+) Respawns In")
        if not (stolen_oincs and active_bandit) then return end
        active_bandit = active_bandit == "true" and STRINGS.UI.CONTROLSSCREEN.YES or active_bandit == "false" and STRINGS.UI.CONTROLSSCREEN.NO or active_bandit
        if active_bandit == STRINGS.UI.CONTROLSSCREEN.YES then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.readytext), stolen_oincs)
        elseif time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.cooldown), TimeToString(time), stolen_oincs, active_bandit)
        end
    end,
    image = {
        atlas = "images/pig_bandit.xml",
        tex = "pig_bandit.tex",
        scale = 0.07,
    },
    anim = {
        scale = 0.07,
        build = "pig_bandit",
        bank = "townspig",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -15,
        }
    },
    DisableShardRPC = true,
    announcefn = function(context)
        local time = context.time
        local text = context.text
        local _time, stolen_oincs = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.banditmanager.cooldown))
        local desc
        if stolen_oincs then
            desc = string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.announce_cooldown), TimeToString(time), stolen_oincs)
        else
            stolen_oincs = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.banditmanager.readytext))
            desc = stolen_oincs and string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.ready), stolen_oincs)
        end
        if desc and context.shard_id ~= EventTimer.CurrentShardId then
            desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
        end
        return desc
    end,
    tipsfn = function(context)
        local text = context.text
        local ready = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.banditmanager.readytext))
        if ready then
            local desc = ReplacePrefabName(STRINGS.eventtimer.banditmanager.tips)
            if context.shard_id ~= EventTimer.CurrentShardId then
                desc = string.format(STRINGS.eventtimer.worldid, context.shard_id) .. "(" .. context.world_str .. ") : " .. desc -- 添加世界前缀标识，不被玩家的模组设置影响（怎么感觉有点屎山）
            end
            return true, StringToFunction(desc), 5, nil, 3
        end
        return false
    end
}

return info