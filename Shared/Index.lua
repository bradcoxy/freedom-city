Core = {}
Core.VehicleModels = {}

-- Enumerators
Package.Require("Enums.lua")

-- Configs
Package.Require("Config/General.lua")
Package.Require("Config/Items.lua")
Package.Require("Config/Notifications.lua")
Package.Require("Config/Player.lua")
Package.Require("Config/Ranks.lua")
-- Package.Require("Config/Taxi.lua")
Package.Require("Config/Multichar.lua")
-- Package.Require("Config/Fishing.lua")
Package.Require("Config/SubwayStations.lua")
Package.Require("Config/VehicleShops.lua")
Package.Require("Config/SkillTree.lua")
Package.Require("Config/Vehicles.lua")


-- Data Files
Package.Require('Data/__Clothing.lua')
Package.Require('Data/__Gender.lua')
-- Package.Require('Data/__Vehicles.lua')
Package.Require('Data/__Weapons.lua')
Package.Require('Data/__Items.lua')
Package.Require('Data/Parsing.lua')

-- Locales
Package.Require('Locales.lua')
Package.Require('Locales/en.lua')

-- Functions
Package.Require('Functions.lua')


-- Utility
Package.Require("Utils.lua")

Core.Players = {}
Core.Characters = {}
Core.Commands = {}

Core.Markers = {}
Core.RegisteredKeys = {}
Core.ButtonsPressed = {}
Core.Interactions = {}

Core.VehiclesRegistry = {}
Core.VehiclesSpawned = {}

Core.ServerCallbacks = {}


Core.SubwayStations = {
    ["Station 1"] = {
        name = "Station 1",
        coords = Vector(214.5, -991.90002441406, 98.199996948242),
        rotation = Rotator(0.0, 180.0, 0.0),
        travelCost = 10,
    },
    ["Station 2"] = {
        name = "Station 2",
        coords =  Vector(2546.1999511719, -190.30000305176, 98.199996948242),
        rotation = Rotator(0.0, 180.0, 0.0),
        travelCost = 12,
    },
    ["Station 3"] = {
        name = "Station 3",
        coords =   Vector(3550.6000976562, -140.10000610352, 98.199996948242),
        rotation = Rotator(0.0, 180.0, 0.0),
        travelCost = 15,
    },
}


Core.DeathTimings = CoreCFG.DeathTimings
Core.Ranks = CoreCFG.Ranks

-- Setup the max ranks if not set
for k, v in ipairs(Core.Ranks) do
    if Core.Ranks[k + 1] then
        Core.Ranks[k].max = Core.Ranks[k + 1].xp
    end
end

-- Fill inventory levels table
local curLevel = nil
local maxInventoryLevel = 0
for k, v in pairs(CoreCFG.InventoryLevels) do
    if curLevel == nil then
        curLevel = v
    end
    if k > maxInventoryLevel then
        maxInventoryLevel = k
    end
end
for i=1, maxInventoryLevel do
    if not CoreCFG.InventoryLevels[i] then
        CoreCFG.InventoryLevels[i] = curLevel
    else
        curLevel = CoreCFG.InventoryLevels[i]
    end
end

Core.DailyReward = CoreCFG.DailyReward -- Reward for playing without disconnecting
Core.DailyTime = CoreCFG.DailyTime -- 4 hours


Package.Export('Core', Core)