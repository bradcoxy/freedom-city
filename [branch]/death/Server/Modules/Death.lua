local Death = {}

--- @brief processes death after the timer has run out.
--- @param player table -- player object from core
function Death:TimerFinished(player)
    if not player then return end
    if not player.character then return end

    player.character:SetLocation(Config.respawnLocation)
    player.character:SetRotation(Config.respawnRotation)

    player.revive()
    player.showNotification('You\'ve been sent to the hospital.')
end

--- @brief notifies all the active ems.
--- @param player table -- player object from core
function Death:NotifyAmbulance(player)
    if not player then return end
    if not player.character then return end
    if not player.get('isDead') then
        print('player is calling the ambulance but is not dead.')
        return
    end

    for k, ply in pairs(Core.Players) do
        if ply.character and ply.job.name == 'ambulance' then
            ply.showNotification(player.source..' is injured.')
        end
    end
end

Events.SubscribeRemote('Death:ServerEvent', function (player, eventType, eventData)
    local xPlayer = Core.GetPlayerFromId(player:GetID())

    if eventType == 'deathTimerFinished' then
        Death:TimerFinished(xPlayer)
    end

    if eventType == 'callAmbulance' then
        Death:NotifyAmbulance(xPlayer)
    end
end)