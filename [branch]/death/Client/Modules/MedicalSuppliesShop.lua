local canUseShops = false
local inShop = false

Package.Subscribe("Load", function ()
	CreateShops()
end)

--- Used to open the medical supplies shop
--- @param shopID string ID of the shop player is using
function OpenShop(shopID)
	local elements = {}
	local shopID = string.gsub(shopID, "MSS%-", "")

	for _, itemData in pairs(Config.Shops[shopID].Items) do
		elements[#elements+1] = {
			label = ("%s - $%s"):format(itemData.label, itemData.price),
			value = itemData.item,
		}
	end

	Core.OpenMenu("select", {
		title = "Medical Supplies",
		description = "",
		elements = elements
	}, function(data, menu)
		menu.close()

		ItemBuyDialog(function(buyAmount)
			if buyAmount == 0 then
				return
			end

			Events.CallRemote("pcrp-ambulancejob::server::BuyMedicalSupplies", shopID, data.value, buyAmount)
		end, data.label)
	end, function(menu)
		menu.close()
	end)
end

--- Used to get amount of the item player wants to buy
--- @param cb function Callback function, returns the amount
--- @param description string Label for the menu
function ItemBuyDialog(cb, description)
	Core.OpenMenu('input', {
		title = "How much do you want to buy?",
		description = description,
		inputType = 'number' -- optional
	}, function(data, menu)
		if (data < 0) then
			Core.ShowNotification(NOTIFICATIONS["invalid_input_value"])
		else
			menu.close()
			cb(data)
		end
		-- if data >= 0 and data <= 1000 then
			-- Events.CallRemote("Taxi::Server::UpdateRate", data)
			-- Core.ShowNotification("Rate changed to: " .. data, 'info', math.random(2000, 5000))
		-- else
			-- Core.ShowNotification("Please enter a valid number")
		-- end
	end, function(menu)
		cb(0)
		menu.close()
	end)
end

Events.SubscribeRemote("pcrp-ambulancejob::client::ToggleMedicalShops", function(toggle)
	canUseShops = toggle
end)


--- Creates the shop markers
function CreateShops()
	for k, v in pairs(Config.Shops) do
		local point = Core.CreateMarker({
			coords = v.Location,
			distance = 150.0,
			marker = {
				type = 'pco-markers::SM_MarkerArrow',
			},
			prompt = {
				text = 'Medical Supplies',
				key = 'F'
			},
			interactions = 'F'
		})

		point:showMarker()
	
		function point:nearby()
			if not canUseShops then return end
			if isBusy then return end

			if self.currentDistance <= 150.0 then
				self:showPrompt()
				
				if self:isKeyJustReleased('F') then
					isBusy = true

					OpenShop(k)
	
					isBusy = false
				end
			else
				self:hidePrompt()
			end
		end

		function point:onExit()
			self:hidePrompt()
		end
	end
end