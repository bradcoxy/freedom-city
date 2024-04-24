local createdShops = {}

--- Gets the item data from shop with shopID
--- @param shopID string ID of the current player's shop
--- @param item string ID of the item that player's buying
--- @return table shopItemData Data of the item that player's buying
function GetShopItem(shopID, item)
	local shopItemsData = Config.Shops[shopID].Items

	for _, _item in pairs(shopItemsData) do
		if _item.item == item then
			return _item
		end
	end

	return nil
end

Player.Subscribe("Possess", function(player)
	Events.CallRemote("pcrp-ambulancejob::client::ToggleMedicalShops", player, false)
end)

Events.Subscribe("OnJobUpdate", function(player, newJob)
	local id = player:GetID()
	local xPlayer = Core.GetPlayerFromId(id)

	if (xPlayer.job.name == "ambulance") then
		Events.CallRemote("pcrp-ambulancejob::client::ToggleMedicalShops", player, true)
	else
		Events.CallRemote("pcrp-ambulancejob::client::ToggleMedicalShops", player, false)
	end
end)

Events.SubscribeRemote("pcrp-ambulancejob::server::BuyMedicalSupplies", function(player, shopID, item, amount)
	local xPlayer = Core.GetPlayerFromId(player:GetID())
	local playerMoney = xPlayer.getMoney()
	local shopItemData = GetShopItem(shopID, item)

	if shopItemData == nil then
		xPlayer.showNotification(NOTIFICATIONS["something_went_wrong_client"])
		return
	end

	local itemPrice = shopItemData.price * amount

	if playerMoney < itemPrice then
		xPlayer.showNotification(NOTIFICATIONS["not_enough_money"])
		return
	end

	xPlayer.removeMoney(itemPrice)
	xPlayer.inventory.AddItem(item, amount)
	xPlayer.showNotification((NOTIFICATIONS["bought_item"]):format(amount, shopItemData.label, itemPrice))
end)
