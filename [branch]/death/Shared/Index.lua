Package.Require("Notifications.lua")

Config = {}

Config.Debug = true

-- Expressed in percentage (%)
-- Defines how much health should the player receive (percentage of max health)
Config.MinorHealValue = 25

-- Item required to be able to heal minor injuries
Config.MinorHealItem = "bandage"

-- Item required to be able to fully heal
Config.MajorHealItem = "medicalkit"

-- Item required to be able to revive
Config.ReviveItem = "defibrillator" 

-- Should the self healing be restricted to specific zones?
Config.SelfHealingZoneRestricted = true

-- Spawn location for players after death timer has run out.
Config.respawnLocation = Vector(0, 0, 100)
Config.respawnRotation = Rotator(0, 0, 0)

-- Zones in which self healing services can be offered
-- Active if Config.SelfHealingZoneRestricted == true 
Config.SelfHealingZones = {
	{
		height = 500.0,
		polygon = {
			Vector(1000.0, 500.0, 0.5),
			Vector(1250.0, 1300.0, 0.5),
			Vector(1150.0, 1600.0, 0.5),
			Vector(550.0, 1600.0, 0.5),
			Vector(50.0, 2400.0, 0.5),
			Vector(-700.0, 2100.0, 0.5),
			Vector(-800.0, 1200.0, 0.5),
			Vector(-1000.0, -250.0, 0.5),
			Vector(-1600.0, -1000.0, 0.5),
			Vector(-800.0, -1600.0, 0.5),
			Vector(250.0, -1700.0, 0.5),
			Vector(1000.0, -1200.0, 0.5),
			Vector(1400.0, -500.0, 0.5),
			Vector(1200.0, -200.0, 0.5)
		}
	},
}

-- Cost of using self healing services
Config.SelfHealingCost = 5000

-- Maximum distance in which the closest player will be detected
Config.MaximumPlayerDistance = 300

-- Shops configuration
Config.Shops = {
	["shop_1"] = {
		Location = Vector(410.9, -73.4, 10.0),
		Items = {
			{
				item = "bandage",
				label = "Bandage",
				price = 2000,
			},

			{
				item = "medicalkit",
				label = "Medical Kit",
				price = 2500
			},

			{
				item = "defibrillator",
				label = "Defibrillator",
				price = 3000
			}
		}
	}
}