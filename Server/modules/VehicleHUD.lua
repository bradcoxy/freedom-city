local fuel_interval

HCharacter.Subscribe("EnterVehicle", function(self, vehicle, seat_index)
    local player = self:GetPlayer()
    Core.UpdateFuel(player)
end)

HCharacter.Subscribe("LeaveVehicle", function(self, vehicle)
    local player = self:GetPlayer()
    Core.UpdateFuel(player)
end)

function Core.UpdateFuel(player)
    if player == nil then return end
    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local vehicle = xPlayer.getVehicle()
    if vehicle then
        fuel_interval = Timer.SetInterval(function()
            local vehData = Core.GetVehicleData(vehicle)
            if not vehData then return end
            local engine = math.floor(vehData.getEngineHealth() + 0.5)

            --print(vehData.getFuel())
            --print(vehData.maxfuel)
            Events.CallRemote('helix-vehiclehud:UpdateCar', player, (vehData.getFuel()/vehData.maxfuel)*100, vehData.getEngineHealth())
        end, 1000)
    else
        if fuel_interval then
            Timer.ClearInterval(fuel_interval)
        end
    end
end
