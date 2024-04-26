Core.UsableItems = {}
Core.SavedVariables = {}
Core.Markers = {}

function Core.RegisterSavedVariable(variable, table, column, default)
	Core.SavedVariables[variable] = { table = table, column = column or variable, default = default }
end

function Core.GetPlayerFromId(plyId)
	return Core.Players[plyId]
end

function Core.GetPlayerFromCharacter(character)
	return Core.Characters[character] -- same thing as Core.Players but indexed by character
end

function Core.AddNametag(prop, text)
    nametag = TextRender(
        Vector(),               -- Any Location
        Rotator(),              -- Any Rotation
        text,       -- Text
        Vector(0.2, 0.25, 0.25),  -- 50% Scale
        Color(1, 1, 1),         -- White
        FontType.Roboto,        -- Roboto Font
        TextRenderAlignCamera.AlignCameraRotation -- Follow Camera Rotation
    )

    nametag:AttachTo(prop)
    nametag:SetRelativeLocation(Vector(50, -20, 70))
    
	prop:SetValue("nametag", nametag, true)
end

function Core.GetNearestVehicle(player)
	local coords = player:GetControlledCharacter():GetLocation()
	local closestDist, closestVeh = nil

	if #Core.VehiclesSpawned == 0 then return closestVeh, closestDist end

	for k, v in ipairs(Core.VehiclesSpawned) do

		local vehCoords = v.vehicle:GetLocation()
		local vehDist = coords:Distance(vehCoords)
		if not closestDist or vehDist < closestDist then
			closestDist = vehDist
			closestVeh = v.vehicle
		end

	end

	return closestVeh, closestDist
end

function Core.CreateMarker(name, props, text, distance, propDisable)
	local drawText
	local textString
	local PropDis = propDisable or false
	local coords = props.coords
	local rotation = props.rotation or Rotator(0, 0, 0)
	local model = props.model or "pco-markers::SM_MarkerArrow"
	local collision = props.collision or 1

	local CCDmode = (collision == 1 and CCDMode.Enabled) or CCDMode.Disabled 

	if not coords then 
		return
	end

	if text ~= nil then
		drawText = text.drawText or false
		textString = text.textString
	end

	if text == nil or not text.textString then
		drawText = false
	end

	if distance ~= nil and type(distance) ~= 'table' then
		distance = { distance }
	end

	local marker
	if (props.ped) then
		marker = Character(coords, rotation, "helix::SK_Male", CollisionType.Normal, true, 100, "helix::A_Male_01_Death", "helix::A_Male_01_Pain")
		marker:SetCapsuleSize(20, 92)
		marker:SetInvulnerable(true)
	else
		if not PropDis then
			marker = Prop(
				coords,
				rotation,
				model,
				collision, --collision
				false, --gravity enabled
				0, -- grab disabled
				CCDmode -- CCD mode automatically
			)

			if props.invisible then
				marker:SetVisibility(not props.invisible)
			end
		end

	end

	-- local idx
	local marker_id = name or #Core.Markers + 1
	-- if type(name) == 'table' then
		-- idx = #name + 1
		-- marker_id = idx
	-- end
	if not PropDis then
 	 marker:SetValue('id', marker_id, true)
	end

	if distance ~= nil then
		local events = {
			['BeginOverlap'] = true,
			['EndOverlap'] = true
		}
	
		for k, v in ipairs(distance) do
			local t_v = v * 50
			if not props.type then
				marker_trigger = Trigger(coords, Rotator(), Vector(t_v), 0, false, Color(0, 0, 0), { Actor })
			else
				marker_trigger = Trigger(coords, Rotator(), Vector(t_v), props.type, false, Color(0, 0, 0), { Actor })
			end
	
			
			marker_trigger:SetValue('marker', marker)
	
			for x, y in pairs(events) do
				marker_trigger:Subscribe(x, function(marker_trigger, character)
					if not character.GetPlayer then return end -- Not a player
					
					local player = character:GetPlayer()
					
					if not player then return end
					
					local pID = player:GetID()
					
					local xPlayer = Core.GetPlayerFromId(pID)
					
					if not xPlayer then return end
	
					-- if not updateFn(xPlayer) then return end
					
					
					if x == 'BeginOverlap' then
						xPlayer.setMarker({ marker = marker, location = v, name = name })
						-- xPlayer.set("CurrentMarker", { marker = marker, location = v, name = name }, true)
						xPlayer.call("core:onEnterMarker", marker, v, name)
					else
						-- xPlayer.set("CurrentMarker", nil, true)
						xPlayer.setMarker(nil)
						xPlayer.call("core:onLeaveMarker", marker, v, name)
					end
	
					-- y(xPlayer, marker, v, name)
				end)
			end
		end
	end

	if drawText then
		Core.AddNametag(marker, textString)
	end

	Core.Markers[marker_id] = { marker = marker, name = marker_id }

	return marker, idx
end

function Core.CreateVehicle(vehicleModel, coords, heading, vin, fuel)
	if not vehicleModel then return end
	if not coords then return end

	local vehicleVin = vin or nil
	local vehicleFuel = fuel or 25.0

	--if not Core.VehicleModels[vehicleModel] then return end
	
--[[ 	local vehicleCfg = Core.VehicleModels[vehicleModel];
	if vehicleCfg == nil then return end
	
	local vehicleMaxFuel = vehicleCfg.maxfuel

	local vehicle = HELIXVehicle.Inherit((vehicleCfg.name):upper())

	function vehicle:Constructor(location, rotation)
		self.Super:Constructor(location or Vector(), rotation or Rotator(), vehicleCfg.asset)
	
		for k, v in ipairs(vehicleCfg.doors) do
			self:SetDoor(k - 1, v.offsetLoc, v.seatLoc, v.seatRot, v.triggerRadius, v.leaveLateralOffset)
		end
	end

	local veh_ent = vehicle(coords, heading)

	CreateVehicleClass(veh_ent, vehicleModel, vehicleFuel, vehicleVin, vehicleMaxFuel) ]]

	local vehicle = Vehicle(coords or Vector(), heading or Rotator(), "helix::SK_Pickup", CollisionType.Normal, true, false, true, "helix::A_Vehicle_Engine_10")

	-- Configure it's Engine power and Aerodynamics
	vehicle:SetEngineSetup(700, 5000)
	vehicle:SetAerodynamicsSetup(2500)
	
	-- Configure it's Steering Wheel and Headlights location
	vehicle:SetSteeringWheelSetup(Vector(0, 27, 120), 24)
	vehicle:SetHeadlightsSetup(Vector(270, 0, 70))
	
	-- Configures each Wheel
	vehicle:SetWheel(0, "Wheel_Front_Left",  27, 18, 45, Vector(), true,  true, false, false, false, 1500, 3000, 1000, 1, 3, 20, 20, 250, 50, 10, 10, 0, 0.5, 0.5)
	vehicle:SetWheel(1, "Wheel_Front_Right", 27, 18, 45, Vector(), true,  true, false, false, false, 1500, 3000, 1000, 1, 3, 20, 20, 250, 50, 10, 10, 0, 0.5, 0.5)
	vehicle:SetWheel(2, "Wheel_Rear_Left",   27, 18,  0, Vector(), false, true,  true, false, false, 1500, 3000, 1000, 1, 4, 20, 20, 250, 50, 10, 10, 0, 0.5, 0.5)
	vehicle:SetWheel(3, "Wheel_Rear_Right",  27, 18,  0, Vector(), false, true,  true, false, false, 1500, 3000, 1000, 1, 4, 20, 20, 250, 50, 10, 10, 0, 0.5, 0.5)
	
	-- Adds 6 Doors/Seats
	vehicle:SetDoor(0, Vector(  50, -75, 105), Vector(   8, -32.5,  95), Rotator(0,  0,  10), 70, -150)
	vehicle:SetDoor(1, Vector(  50,  75, 105), Vector(  25,    50,  90), Rotator(0,  0,   0), 70,  150)
	vehicle:SetDoor(2, Vector( -90, -75, 130), Vector( -90,  -115, 155), Rotator(0,  90, 20), 60, -150)
	vehicle:SetDoor(3, Vector( -90,  75, 130), Vector( -90,   115, 155), Rotator(0, -90, 20), 60,  150)
	vehicle:SetDoor(4, Vector(-195, -75, 130), Vector(-195,  -115, 155), Rotator(0,  90, 20), 60, -150)
	vehicle:SetDoor(5, Vector(-195,  75, 130), Vector(-195,   115, 155), Rotator(0, -90, 20), 60,  150)
	
	-- Make it ready (so clients only create Physics once and not for each function call above)
	vehicle:RecreatePhysics()

	CreateVehicleClass(vehicle, vehicleModel, vehicleFuel, vehicleVin, 100)
	
	return vehicle
end

function Core.SetVehicleFuel(vehicle, fuel)
	local vehicleData = Core.GetVehicleData(vehicle)

	if not vehicleData then return end
		
	vehicleData.setFuel(fuel)
end

function Core.CreateItem(name, info)
    if type(name) == 'table' then
		for k, v in pairs(name) do
			Core.CreateItem(k, v)
		end
		return
	end

	if Core.Items[name] then
        print('Item Trying To Add, Already Exists! ',name)
        return
    end

	if not info.label then
		return print("Item needs a label")
	end

	if not info.name then
		info.name = name
	end

	if not info.weight then
		info.weight = 1
	end

	if not info.unique then
		info.unique = false
	end

	if not info.type then
		info.type = 'item'
	end

	if not info.description then
		info.description = '...'
	end

	Core.Items[name] = info

	if info.type == 'hunger' or info.type == 'thirst' then
		Core.CreateUseableItem(name, function(xPlayer, item, slot)
			xPlayer.inventory.RemoveItem(item, 1)
			xPlayer.stats[info.type] = xPlayer.stats[info.type] + info.change or 0.0
			xPlayer.updateData()
		end)
	end

	if info.type == 'clothing' and info.name and Core.Clothing[info.name] then
		Core.CreateUseableItem(name, function(xPlayer, item, slot)
			local clothing = Core.Clothing[info.name]
			xPlayer.setSkin(clothing.target, info.name)
		end)
	end
end

function Core.CreateCallback(name, cb)
    Core.ServerCallbacks[name] = cb
end

function Core.TriggerCallback(name, source, cb, ...)
    if not Core.ServerCallbacks[name] then return end
    Core.ServerCallbacks[name](source, cb, ...)
end

-- Events
Events.SubscribeRemote('ServerTriggerCallback', function(player, name, ...)
    Core.TriggerCallback(name, player, function(...)
        Events.CallRemote('ClientFromServerTriggerCallback', player, name, ...)
    end, ...)
end)

function Core.UseItem(player, item, slot, extra)
	if not Core.UsableItems[item] then
        return
    end

	Core.UsableItems[item](player, item, slot, extra)
end

function Core.CreateUseableItem(item, cb)
    Core.UsableItems[item] = cb
end