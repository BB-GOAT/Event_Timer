GLOBAL.setfenv(1, GLOBAL)

-- for server
if not TheNet:GetIsServer() then
    return
end

local old_WarningEvents
function ShowAllEvent()
    if not old_WarningEvents then
        old_WarningEvents = deepcopy(WarningEvents)
    end

    for _, tb in pairs(WarningEvents) do
        if not tb.playerly then
            tb.gettimefn = function(...)
                return 666
            end
            tb.gettextfn = function(...)
                return "测试测试(世界233)\n第一行长文字123\n第二行长文字长文字长文字长文字\n第三行最长最长最长最长最长最长的文字"
            end
        end
    end
end

function DefaultEvent()
    if not old_WarningEvents then
        old_WarningEvents = deepcopy(WarningEvents)
    end
    WarningEvents = deepcopy(old_WarningEvents)

    for warningevent in pairs(WarningEvents) do
        EventTimer.EventTimerData[warningevent] = {
            [EventTimer.CurrentShardId] = {}
        }

        EventTimer.env.SyncEventData(warningevent, 0, "event_timerpc", EventTimer.CurrentShardId)
        EventTimer.env.SyncEventData(warningevent, "", "event_textrpc", EventTimer.CurrentShardId)
        SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_time_shardrpc"], nil, warningevent, 0)
        SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_text_shardrpc"], nil, warningevent, "")
    end
end