local EMS_ITEMS <const> = {
	["bandage"] = {
		["name"] = "bandage",
		["label"] = "Bandage",
		["weight"] = 100,
		["unique"] = true,
		["useable"] = true,
		["type"] = "misc",
		["image"] = "test.png",
		["description"] = "Used to heal minor injuries."
	},

	["medicalkit"] = {
		["name"] = "medicalkit",
		["label"] = "Medical Kit",
		["weight"] = 100,
		["unique"] = true,
		["useable"] = true,
		["type"] = "misc",
		["image"] = "test.png",
		["description"] = "Used to heal major injuries."
	},

	["defibrillator"] = {
		["name"] = "defibrillator",
		["label"] = "Defibrillator",
		["weight"] = 100,
		["unique"] = true,
		["useable"] = true,
		["type"] = "misc",
		["image"] = "test.png",
		["description"] = "Used to reanimate people."
	}
}

Package.Subscribe("Load", function()
	Core.CreateItem(EMS_ITEMS)

	for item, itemData in pairs(EMS_ITEMS) do
		if item ~= "defibrillator" then
			Core.CreateUseableItem(item, function(xPlayer, item, slot)
				xPlayer.inventory.RemoveItem(item, 1, slot)

				if item == "bandage" then
					HealMinorInjuries(xPlayer)
					xPlayer.showNotification(NOTIFICATIONS["minor_injuries_treated_self"])
				elseif item == "medicalkit" then
					HealMajorInjuries(xPlayer)
					xPlayer.showNotification(NOTIFICATIONS["major_injuries_treated_self"])
				end
			end)
		end
	end
end)
