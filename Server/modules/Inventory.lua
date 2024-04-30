Events.Subscribe('core:playerSpawned', function(player)
	local plyId = player:GetID()
	local xPlayer = Core.Players[plyId]

--[[ 	local res = DB:Select(("SELECT data, weight FROM `inventory_data` WHERE name = '%s'"):format(xPlayer.charid))
	if res[1] then
		print(res[1].data, res[1].weight)
		xPlayer.inventory.Update({ data = JSON.parse(res[1].data), weight = JSON.parse(res[1].weight) })
	end ]]

	PersistentDatabase.GetByKey(('%s_Inventory'):format(xPlayer.charid), function(success, data)
		data = JSON.parse(data)
		if success and data[1] then
			xPlayer.inventory.Update(data[1]['value'])
			print(HELIXTable.Dump(data[1]['value']))
		end
	end)
end)