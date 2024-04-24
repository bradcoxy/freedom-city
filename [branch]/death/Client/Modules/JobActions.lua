-- =====================
-- 		- DEBUG -
-- =====================
	Core.GetClosestPlayer = function()
		local coords = Core.PlayerData.character:GetLocation()
		local closestDist, closestPlayer = nil

		if Player.GetCount() == 1 then return closestPlayer, closestDist end

		local players = Player.GetPairs()

		for k, v in pairs(players) do
			local plyCoords = v:GetControlledCharacter():GetLocation()
			local plyDist = coords:Distance(plyCoords)


			if (not closestDist or plyDist < closestDist) and plyDist ~= 0 then
				closestDist = plyDist
				closestPlayer = v
			end
		end

		return closestPlayer, closestDist
	end

	-- Core.ShowNotification = function(message)
	-- 	Chat.AddMessage(message)
	-- end
-- =====================
-- 		 - END -
-- =====================
function isInsidePolygon(point, polygon, zMargin)
    local zMargin = zMargin and zMargin + 100 or 150
    local intersects = false

    for i = 1, #polygon do
        local j = i % #polygon + 1
        local xi, yi, zi = polygon[i].X, polygon[i].Y, polygon[i].Z
        local xj, yj, zj = polygon[j].X, polygon[j].Y, polygon[j].Z

		-- print(zi, point.Z, zi + zMargin, zj, point.Z, zj + zMargin)
        if zi <= point.Z and point.Z <= zi + zMargin and zj <= point.Z and point.Z <= zj + zMargin then
            if (yi > point.Y) ~= (yj > point.Y) then
                local x = (xj - xi) * (point.Y - yi) / (yj - yi) + xi
                if x < point.X then
                    intersects = not intersects
                end
            end
        end
    end

    return intersects
end


local isOfferingSelfHeal = false

Events.Subscribe("pcrp-ambulancejob::client::HealMinorInjuries", function()
	local closestPlayer, closestPlayerDistance = Core.GetClosestPlayer()
	-- local closestPlayer = Player.GetAll()[1]
	-- local closestPlayerDistance = 50.0

	if (closestPlayer ~= nil and closestPlayerDistance <= Config.MaximumPlayerDistance) then
		Events.CallRemote("pcrp-ambulancejob::server::HealMinorInjuries", closestPlayer)
	else
		Core.ShowNotification(NOTIFICATIONS["no_one_near"])
	end
end)

Events.Subscribe("pcrp-ambulancejob::client::HealMajorInjuries", function()
	local closestPlayer, closestPlayerDistance = Core.GetClosestPlayer()

	if (closestPlayer ~= nil and closestPlayerDistance <= Config.MaximumPlayerDistance) then
		Events.CallRemote("pcrp-ambulancejob::server::HealMajorInjuries", closestPlayer)
	else
		Core.ShowNotification(NOTIFICATIONS["no_one_near"])
	end
end)

Events.Subscribe("pcrp-ambulancejob::client::Resuscitate", function()
	local closestPlayer, closestPlayerDistance = Core.GetClosestPlayer()

	if (closestPlayer ~= nil and closestPlayerDistance <= Config.MaximumPlayerDistance) then
		Events.CallRemote("pcrp-ambulancejob::server::Resuscitate", closestPlayer)
	else
		Core.ShowNotification(NOTIFICATIONS["no_one_near"])
	end
end)

Events.Subscribe("pcrp-ambulancejob::client::SelfHealingServices", function()
	if isOfferingSelfHeal then
		Core.ShowNotification(NOTIFICATIONS["already_offering_self_healing"])
		return
	end
	
	if Config.SelfHealingZoneRestricted then
		local player = Client.GetLocalPlayer()
		local playerCharacter = player:GetControlledCharacter()
		local playerLocation = playerCharacter:GetLocation()
		local isInZone = false

		for _, v in pairs(Config.SelfHealingZones) do
			if isInsidePolygon(playerLocation, v.polygon, v.height) then
				isInZone = true
				break
			end
		end

		if not isInZone then
			Core.ShowNotification(NOTIFICATIONS["not_in_zone"])
			return
		end
	end

	isOfferingSelfHeal = true
	ToggleActionMenuOptions(false)
	RemoveSelfHealingOption()
	Events.CallRemote("pcrp-ambulancejob::server::OfferSelfHealingServices")
end)

Events.Subscribe("pcrp-ambulancejob::client::StopSelfHealingServices", function()
	isOfferingSelfHeal = false
	ToggleActionMenuOptions(true)
	AddSelfHealingOption()
	Events.CallRemote("pcrp-ambulancejob::server::StopSelfHealingServices")
end)
