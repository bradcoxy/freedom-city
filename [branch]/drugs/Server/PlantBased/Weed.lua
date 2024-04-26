local Weed = {}

Weed.Plants = {}
Weed.PlantIDs = {}
Weed.PlantProps = {}
Weed.GrowthStages = {
    [1] = {
        asset = 'drug-plants::SM_Weed_Stage1',
        minGrowth = 0,
        maxGrowth = 20,
    },
    [2] = {
        asset = 'drug-plants::SM_Weed_Stage2',
        minGrowth = 20,
        maxGrowth = 40,
    },
    [3] = {
        asset = 'drug-plants::SM_Weed_Stage3',
        minGrowth = 40,
        maxGrowth = 60,
    },
    [4] = {
        asset = 'drug-plants::SM_Weed_Stage4',
        minGrowth = 60,
        maxGrowth = 100,
    },
}

Weed.Types = {
    ['og_kush'] = {
        label = 'OG Kush',
        seedPrice = 90,
    },
    ['purple_kush'] = {
        label = 'Purple Kush',
        seedPrice = 80,
    },
    ['blue_dream'] = {
        label = 'Blue Dream',
        seedPrice = 70,
    },
    ['blue_haze'] = {
        label = 'Blue Haze',
        seedPrice = 60,
    },
    ['banana_kush'] = {
        label = 'Banana Kush',
        seedPrice = 50,
    },
    ['paraguayo'] = {
        label = 'Paraguayo',
        seedPrice = 5,
    }
}

local random = math.random

Package.Subscribe('Load', function ()
    for weed, weedInfo in pairs(Weed.Types) do

        weedInfo.seed = ('%s_seed'):format(weed)
        weedInfo.raw = ('%s_raw'):format(weed)
        weedInfo.dried = ('%s_dried'):format(weed)

        Core.CreateItem({
            [weed] = {
                label = weedInfo.label,
                unique = false,
                description = 'Good times.',
                type = 'item',
            },
            [weedInfo.raw] = {
                label = ('Raw %s'):format(weedInfo.label),
                unique = false,
                description = 'Good times.',
                type = 'item',
            },
            [weedInfo.dried] = {
                label = ('Dry %s'):format(weedInfo.label),
                unique = false,
                description = 'Good times.',
                type = 'item',
            },
            [weedInfo.seed] = {
                label = ('%s Seed'):format(weedInfo.label),
                unique = false,
                description = 'A chance.',
                type = 'item',
            }
        })

        --Core.CreateUseableItem(weed, )
        --Core.CreateUseableItem(weedInfo.raw, )
        --Core.CreateUseableItem(weedInfo.dried, )
        Core.CreateUseableItem(weedInfo.seed, Weed.UsedSeed)
    end

    Weed:GetPlants()
end)

function Weed:GetPlants()
    PersistentDatabase.GetByKey('WeedPlants', function(success, data)
        data = JSON.parse(data)
        if success and data[1] then
            local plants = data[1]['value']['plants']

            for k, plant in pairs(plants) do
                if not plant.identifier then return end

                local plantKey = #self.Plants + 1
                self.Plants[plantKey] = plant
                self.PlantIDs[plant.identifier] = plantKey
                self:CreatePlant(plantKey)

                print('found weed plant #', plant.identifier, plant.location)
            end
        end
    end)
end

function Weed:GetPlantGrowthStage(growthAmount)
    if not growthAmount then return end

    for _, growthStgData in pairs(self.GrowthStages) do
        if growthAmount >= growthStgData.minGrowth and growthAmount <= growthStgData.maxGrowth then
            return growthStgData
        end
    end
end

function Weed:CreatePlant(plantKey)
    if not self.Plants[plantKey] then return end

    local plant = self.Plants[plantKey]
    local growthStage = self:GetPlantGrowthStage(plant.growth)

    if self.PlantProps[plant.identifier] then
        print('called to create a Weed plant which was already created.')
        return
    end

    if not growthStage then
        print('unable to find growth stage for weed plant with growth', plant.growth)
        return
    end

    allPlantLocations[plant.identifier] = plant.location
    self.PlantProps[plant.identifier] = Prop(plant.location, plant.rotation, growthStage.asset, 2, false, 0, 1)
end

function Weed:PlantSeed(player, seedType)
    if not player then return end
    if not self.Types[seedType] then
        player.showNotification('You cannot plant this seed.')
        return
    end

    if self:ClosestPlant(player.character:GetLocation()) then
        player.showNotification('Too close to another plant.')
        return
    end

    local character = player.character
    local growthStage = self.GrowthStages[1]
    local plantKey = #self.Plants + 1
    local plantID = random(111111, 999999)
    local plant = Prop(character:GetLocation(), Rotator(0, 0, 0), growthStage.asset, 2, false, 0, 1)

    plant:SetVisibility(false)
    plant:AttachTo(character, 1)
    plant:SetRelativeLocation(Vector(120.0, 0.0, -95.0))
    plant:Detach()
    plant:SetVisibility(true)

    Timer.SetTimeout(function ()
        local plantData = {
            identifier = plantID,
            planter = player.charid,
            location = plant:GetLocation(),
            rotation = plant:GetRotation(),
            type = seedType,
            water = 100,
            nutrients = 100,
            quality = 100,
            growth = 0,
        }

        self.Plants[plantKey] = plantData
        self.PlantIDs[plantID] = plantKey
        self.PlantProps[plantID] = plant

        allPlantLocations[plantID] = character:GetLocation()

        Events.BroadcastRemote('Weed:ReceivePlants', self.Plants)

        --DB:Execute('INSERT INTO user_plants (identifier, planter, location, rotation, type, quality, water, nutrients, growth) VALUES (:0, :0, :0, :0, :0, :0, :0, :0, :0)', plantData.identifier, plantData.planter, JSON.stringify(plantData.location), JSON.stringify(plantData.rotation), plantData.type, plantData.quality, plantData.water, plantData.nutrients, plantData.growth)
        PersistentDatabase.Insert('WeedPlants', JSON.stringify({plants = self.Plants}), function () end)
    end, 100)

    player.showNotification('You\'ve planted a seed.')
    print('Weed seed planted #', plantID, plant:GetLocation())
end

function Weed:ClosestPlant(location)
    if not location then return end

    for _, otherLocation in pairs(allPlantLocations) do
        if location:Distance(otherLocation) <= 150.0 then
            return true
        end
    end
    return false
end

function Weed:UpdatePlant(plantKey)
    if not self.Plants[plantKey] then return end

    local plant = self.Plants[plantKey]

    if plant.grown then return end

    plant.water = plant.water > 0 and plant.water - random(1, 5) or 0
    plant.nutrients = plant.nutrients > 0 and plant.nutrients - random(1, 5) or 0

    if plant.water > 50 and plant.nutrients > 50 then
        plant.growth = plant.growth + random(5, 10)

        if plant.growth >= 100 then
            plant.growth = 100
            plant.grown = true
        end

        local growthStage = self:GetPlantGrowthStage(plant.growth)
        if growthStage then
            self.PlantProps[plant.identifier]:SetMesh(growthStage.asset)
        end
    end

    if plant.water < 25 and plant.nutrients < 25 then
        plant.quality = plant.quality > 0 and plant.quality - random(1, 2) or 0
    end

    --DB:Execute(('UPDATE user_plants SET quality = %s, water = %s, nutrients = %s, growth = %s, grown = %s WHERE identifier = %s'):format(plant.quality, plant.water, plant.nutrients, plant.growth, plant.grown and 1 or 0, plant.identifier))
    PersistentDatabase.Insert('WeedPlants', JSON.stringify({plants = self.Plants}), function () end)
end

function Weed:UpdatePlants()
    for plantKey in pairs(self.Plants) do
        self:UpdatePlant(plantKey)
    end
end

function Weed.UsedSeed(player, item)
    Weed:PlantSeed(player, string.gsub(item, '_seed', ''))
end

function Weed.RetrievePlant(player, plantKey)
    if not Weed.Plants[plantKey] then return end

    print(HELIXTable.Dump(Weed.Plants[plantKey]))
    Events.CallRemote('Weed:ShowPlant', player, Weed.Plants[plantKey])
end

function Weed.FeedPlant(player, plantid)
    if not Weed.PlantIDs[plantid] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local plantKey = Weed.PlantIDs[plantid]
    local plant = Weed.Plants[plantKey]

    if plant.grown then
        xPlayer.showNotification('You cannot feed this plant anymore.')
        return
    end

    plant.nutrients = plant.nutrients + 15
    if plant.nutrients > 100 then
        plant.nutrients = 100
    end

    xPlayer.showNotification('You\'ve provided nutrients for this plant.')
    xPlayer.call('Weed:UpdateCurrentPlant', plant)
end

function Weed.WaterPlant(player, plantid)
    if not Weed.PlantIDs[plantid] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local plantKey = Weed.PlantIDs[plantid]
    local plant = Weed.Plants[plantKey]

    if plant.grown then
        xPlayer.showNotification('You cannot water this plant anymore.')
        return
    end

    plant.water = plant.water + 15
    if plant.water > 100 then
        plant.water = 100
    end

    xPlayer.showNotification('You\'ve provided water for this plant.')
    xPlayer.call('Weed:UpdateCurrentPlant', plant)
end

function Weed.GetHarvest(quality)
    return quality >= 10 and math.floor((quality / 2) * 3) or 10
end

function Weed.GetSeed(quality)
    return quality >= 10 and math.floor((quality / 4) + 10) or 5
end

function Weed.HarvestPlant(player, plantid)
    if not Weed.PlantIDs[plantid] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local plantKey = Weed.PlantIDs[plantid]
    local plant = Weed.Plants[plantKey]

    if not plant.grown then
        xPlayer.showNotification('This plant hasn\'t finished growing.')
        return
    end

    allPlantLocations[plantid] = nil
    Weed.Plants[plantKey] = nil
    Weed.PlantIDs[plantid] = nil
    Weed.PlantProps[plantid]:Destroy()

    PersistentDatabase.Insert('WeedPlants', JSON.stringify({plants = Weed.Plants}), function (deleted)
        if deleted then
            local harvestAmount = Weed.GetHarvest(plant.quality)
            local seedAmount = Weed.GetSeed(plant.quality)

            Events.BroadcastRemote('Weed:ReceivePlants', Weed.Plants)
            xPlayer.call('Weed:ClosePlant')
            xPlayer.showNotification(('You\'ve harvested this plant. Harvested %s grams of cannabis and %s seeds.'):format(harvestAmount, seedAmount))
        end
    end)
end

function Weed.DestroyPlant(player, plantid)
    if not Weed.PlantIDs[plantid] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local plantKey = Weed.PlantIDs[plantid]

    allPlantLocations[plantid] = nil
    Weed.Plants[plantKey] = nil
    Weed.PlantIDs[plantid] = nil
    Weed.PlantProps[plantid]:Destroy()

    PersistentDatabase.Insert('WeedPlants', JSON.stringify({plants = Weed.Plants}), function(deleted)
        if deleted then
            Events.BroadcastRemote('Weed:ReceivePlants', Weed.Plants)
            xPlayer.showNotification('You\'ve destroyed this plant.')
        end
    end)
end

Timer.SetInterval(function ()
    Weed:UpdatePlants()
end, 10000)

Events.SubscribeRemote('Weed:FeedPlant', Weed.FeedPlant)
Events.SubscribeRemote('Weed:WaterPlant', Weed.WaterPlant)
Events.SubscribeRemote('Weed:HarvestPlant', Weed.HarvestPlant)
Events.SubscribeRemote('Weed:DestroyPlant', Weed.DestroyPlant)
Events.SubscribeRemote('Weed:RetrivePlant', Weed.RetrievePlant)

--- @brief sends the plants to the client side
Events.Subscribe('core:playerSpawned', function(player)
    Timer.SetTimeout(function ()
        Events.CallRemote('Weed:ReceivePlants', player, Weed.Plants)
    end, 2000)
end)

Chat.Subscribe('PlayerSubmit', function(message, player)
    local xPlayer = Core.GetPlayerFromId(player:GetID())

	if message == 'getseed' then
        xPlayer.inventory.AddItem('og_kush_seed', 1)
    end
end)
