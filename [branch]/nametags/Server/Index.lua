Events.Subscribe('core:playerSpawned', function(player)
    local xPlayer = Core.GetPlayerFromId(player:GetID())

    Events.BroadcastRemote('NameTags:PlayerConnection', player, xPlayer.getName())

    for k, kPlayer in pairs(Player.GetPairs()) do
        local yPlayer = Core.GetPlayerFromId(kPlayer:GetID())
        if yPlayer then
            Events.CallRemote('NameTags:AddExistingPlayer', player, kPlayer, yPlayer.getName())
        end
    end
end)

Player.Subscribe("Destroy", function(player)
    Events.BroadcastRemote('NameTags:PlayerDisconnection', player:GetID())
end)