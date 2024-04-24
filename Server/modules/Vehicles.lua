Vehicle.Subscribe("CharacterEnter", function(vehicle, character, seat)
	if seat ~= 0 then
		return
	end
	
	local vehData = Core.GetVehicleData(vehicle)
	
	if not vehData then
		CreateVehicleClass(vehicle, 100.0)
		vehData = Core.GetVehicleData(vehicle)
	end

	local xPlayer = Core.GetPlayerFromCharacter(character)

	xPlayer.setVehicle(vehicle)
	vehData.setRunning(false)
	vehData.updateVehicle()
end)

Events.SubscribeRemote("core:onVehicleEngineStart", function(player, vehicle)
	print(player, vehicle)
	if not vehicle then return end
	local vehData = Core.GetVehicleData(vehicle)
	print(vehData)
	
	vehData.setRunning(true)
end)

Events.Subscribe("AttemptToFuelVehicle", function(player, vehicle)
	if not player then return end
	if not vehicle then return end

	local xPlayer = Core.GetPlayerFromId(player:GetID())
	local vehData = Core.GetVehicleData(vehicle)
	
	if not vehData then return end

	xPlayer.call("StartGasPumpInteraction", vehicle, vehData.getFuel())
end)


Events.Subscribe("GasStation:RefuelVehicle", function(player, vehicle, addedFuel)
	if not player then return end
	
	local xPlayer = Core.GetPlayerFromId(player:GetID())
	local closestVeh = Core.GetNearestVehicle(player)
	local vehData = Core.GetVehicleData(vehicle)

	if not vehData then return end
	
	vehData.setFuel(vehData.getFuel() + addedFuel)
end)

Vehicle.Subscribe("CharacterLeave", function(vehicle, character, seat)
	if seat ~= 0 then
		return
	end

	local vehData = Core.GetVehicleData(vehicle)
	local xPlayer = Core.GetPlayerFromCharacter(character)

	xPlayer.setVehicle(nil)
	vehData.setRunning(false)
end)

Vehicle.Subscribe("TakeDamage", function(self, damage, bone, type, from_direction, instigator, causer)
	print('damage taken =>', self, damage, bone, type, from_direction, instigator, causer)
end)

Vehicle.Subscribe("Hit", function(self, impact_force, normal_impulse, impact_location, velocity)
	-- TODO: In future with newer vehicles check if impact was near the engine
	local vehData = Core.GetVehicleData(self)

	if not vehData then return end
	local engineHealth = vehData.getEngineHealth()
	
	if engineHealth <= 0 then
		return
	end

	local vehicleDmg = impact_force * 0.01
	print("VEHICLE DAMAGE => ", vehicleDmg, engineHealth)
	-- print(vehicleDmg, engineHealth)
	engineHealth = engineHealth - vehicleDmg
	print("VEHICLE DAMAGE => ", vehicleDmg, engineHealth)
	-- print(vehicleDmg, engineHealth)

	vehData.setEngineHealth(engineHealth);
	print(vehData.getEngineHealth())
end)

Timer.SetInterval(function()
	for k, v in ipairs(Core.VehiclesSpawned) do
		if v.running then
			Core.SetVehicleFuel(v.vehicle, v.fuel - 1.0)
		end
	end
end, 5000)

-- Core.CreateCommand('freeCam', function(xPlayer)
-- 	xPlayer.player:UnPossess()
-- end)