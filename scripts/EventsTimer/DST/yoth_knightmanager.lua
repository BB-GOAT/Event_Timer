-- 纯本地获取方式
local localgettimefn = function()
    HookDeath("knight_yoth", "yoth_knightmanager", function(event)
        local player = ThePlayer
        local inventory = player and player.replica.inventory
        if not inventory then return end

        local x, y, z = player.Transform:GetWorldPosition()
        for _, ent in ipairs(TheSim:FindEntities(x, y, z, 80, nil, {"FX", "DECOR", "INLIMBO", "NOCLICK", "player"})) do
            if ent.prefab == "knight_yoth" and not IsEntityDead(ent) then
                return
            end
        end

        -- 身上有公主裙或公主帽时开始倒计时
        local item_lists = {inventory:GetItems(), inventory:GetEquips(), {inventory:GetActiveItem()}}
        for container_inst in pairs(inventory:GetOpenContainers() or {}) do
            local container = container_inst.replica.container
            if container then
                item_lists[#item_lists + 1] = container:GetItems()
            end
        end
        for _, items in ipairs(item_lists) do
            for _, item in pairs(items) do
                if item.prefab == "costume_princess_body" or item.prefab == "mask_princesshat" then
                    SaveTimeData(event, TUNING.YOTH_PRINCESS_SUMMON_COOLDOWN)
                    return
                end
            end
        end
    end)
end

----------------------------------------------------------------------------------------------

local target_time_interval
local info
info = {
    localgettimefn = localgettimefn,
    remotegettimefn = function(Thread)
        local cmd = [[
            local player = ThePlayer
            if player and player:IsValid() then
                local debuff = player.components.debuffable and player.components.debuffable:GetDebuff("yoth_princesscooldown_buff")
                if debuff then
                    local time = debuff.components and debuff.components.timer and debuff.components.timer:GetTimeLeft("buffover")
                    return DataDumper({ time = time })
                end
            end
        ]]

        BBGOAT_util:remote(cmd, nil, function(res)
            if res and res.time then
                SaveTimeData("yoth_knightmanager", res.time)
                target_time_interval = res.time + 1
            else
                SaveTimeData("yoth_knightmanager", 0)
                target_time_interval = nil
                if res and res.err then
                    print('[警告] yoth_knightmanager remotegettimefn error:', res.err)
                    if Thread then KillThreadsWithID(Thread.id) end
                end
            end
        end)
    end,
    remotegettimefninterval = function()
        return math.min(60, target_time_interval or 60)
    end,
    anim = {
        scale = 0.08,
        bank = "knight",
        build = "knight_yoth_build",
        animation = "idle_loop",
        uioffset = {
            x = 0,
            y = -10,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.yoth_knightmanager_time
        return string.format(ReplacePrefabName(STRINGS.eventtimer.yoth_knightmanager.announce), TimeToString(time))
    end,
    tipsfn = function ()
        local time = ThePlayer.HUD.WarningEventTimeData.yoth_knightmanager_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.yoth_knightmanager.tips)), 10, time, 2
        end
        return false
    end
}

return info