Events.SubscribeRemote("SendToApartment", function (ply)
    local char = ply:GetControlledCharacter()

    char:SetLocation(Vector(40619,63438,1000))

    Core.GetPlayerFromCharacter(char).call('core:onPlayerSpawned')
end)