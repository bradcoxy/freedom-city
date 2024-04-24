--[[ Package.Subscribe("Load", function()
	for i = 1, #Config.SelfHealingZones do
		local zone = Config.SelfHealingZones[i]

		for j = 1, #zone.polygon do
			local point1 = zone.polygon[j]
			local point2 = zone.polygon[j + 1]

			if not point2 then
				point2 = zone.polygon[1]
			end

			local X, Y, Z = point1.X, point1.Y, point1.Z
			local X2, Y2, Z2 = point2.X, point2.Y, point2.Z

			local heightZ = Z + zone.height
			local polygonVector = Vector(X, Y, Z)
			local polygonVector2 = Vector(X2, Y2, Z2)

			Debug.DrawLine(polygonVector, polygonVector2, Color.RED, 9999.0)

			if zone.height then
				local heightZ2 = Z2 + zone.height
				local polygonHeightVector = Vector(X, Y, heightZ)
				local polygonHeightVector2 = Vector(X2, Y2, heightZ2)

				Debug.DrawLine(polygonHeightVector, polygonHeightVector2, Color.RED, 9999.0)
				Debug.DrawLine(polygonHeightVector, polygonVector2, Color.RED, 9999.0)
				Debug.DrawLine(polygonHeightVector2, polygonVector, Color.RED, 9999.0)
			end
		end

		-- if zone.height then
		-- 	for j = 1, #zone.polygon do
		-- 		for k = 1, #zone.polygon do
		-- 			local point1 = zone.polygon[j]
		-- 			local point2 = zone.polygon[k]

		-- 			local X, Y, Z = point1.X, point1.Y, point1.Z+zone.height
		-- 			local X2, Y2, Z2 = point2.X, point2.Y, point2.Z+zone.height

		-- 			local polygonVector = Vector(X, Y, Z)
		-- 			local polygonVector2 = Vector(X2, Y2, Z2)

		-- 			Debug.DrawLine(polygonVector, polygonVector2, Color.RED, 9999.0)
		-- 		end
		-- 	end
		-- end

		-- Debug.DrawLine(zone.polygon[#zone.polygon], zone.polygon[1], Color.RED, 9999.0)

		local isInZoneCanvas = Canvas(
			true,
			Color.TRANSPARENT,
			0.5,
			true
		)

		-- Subscribes for Update, we can only Draw inside this event
		isInZoneCanvas:Subscribe("Update", function(self, width, height)
			local playerLocation = Client.GetLocalPlayer():GetControlledCharacter():GetLocation()

			-- Draws a Text in the middle of the screen
			self:DrawText(
			("[RESTRICTED ZONE #%s] %s"):format(i, isInsidePolygon(playerLocation, zone.polygon, zone.height)),
			Vector2D(width * 0.5, height * 0.15 + i * 20))
		end)

		-- Forces the canvas to repaint, this will make it trigger the Update event
		isInZoneCanvas:Repaint()
	end
end) ]]
