local Cocaine = {}

Cocaine.Plants = {}
Cocaine.PlantIDs = {}
Cocaine.PlantProps = {}
Cocaine.GrowthStages = {
    [1] = {
        asset = 'drug-plants::SM_Cocaine_Stage1',
        minGrowth = 0,
        maxGrowth = 20,
    },
    [2] = {
        asset = 'drug-plants::SM_Cocaine_Stage2',
        minGrowth = 20,
        maxGrowth = 40,
    },
    [3] = {
        asset = 'drug-plants::SM_Cocaine_Stage3',
        minGrowth = 40,
        maxGrowth = 60,
    },
    [4] = {
        asset = 'drug-plants::SM_Cocaine_Stage4',
        minGrowth = 60,
        maxGrowth = 100,
    },
}

Cocaine.Types = {
    ['columbian_coca'] = {
        label = 'Columbian Coca',
        seedPrice = 90,
    },
    ['bolivian_coca'] = {
        label = 'Bolivian Coca',
        seedPrice = 70,
    },
    ['peruvian_coca'] = {
        label = 'Peruvian Coca',
        seedPrice = 50,
    },
}

local random = math.random

Package.Subscribe('Load', function ()
    for cocaine, cocaineInfo in pairs(Cocaine.Types) do

        cocaineInfo.seed = ('%s_seed'):format(cocaine)
        cocaineInfo.raw = ('%s_raw'):format(cocaine)
        cocaineInfo.dried = ('%s_dried'):format(cocaine)

        Core.CreateItem({
            [cocaine] = {
                label = cocaineInfo.label,
                unique = false,
                description = 'Good times.',
                type = 'item',
            },
            [cocaineInfo.raw] = {
                label = ('Raw %s'):format(cocaineInfo.label),
                unique = false,
                description = 'Good times.',
                type = 'item',
            },
            [cocaineInfo.dried] = {
                label = ('Dry %s'):format(cocaineInfo.label),
                unique = false,
                description = 'Good times.',
                type = 'item',
            },
            [cocaineInfo.seed] = {
                label = ('%s Seed'):format(cocaineInfo.label),
                unique = false,
                description = 'A chance.',
                type = 'item',
            }
        })

        --Core.CreateUseableItem(cocaine, )
        --Core.CreateUseableItem(cocaineInfo.raw, )
        --Core.CreateUseableItem(cocaineInfo.dried, )
        Core.CreateUseableItem(cocaineInfo.seed, Cocaine.UsedSeed)
    end

    Cocaine:GetPlants()
end)

function Cocaine:GetPlants()
    PersistentDatabase.GetByKey('CocainePlants', function(success, data)
        data = JSON.parse(data)
        if success and data[1] then
            local plants = data[1]['value']['plants']

            for k, plant in pairs(plants) do
                if not plant.identifier then return end

                local plantKey = #self.Plants + 1
                self.Plants[plantKey] = plant
                self.PlantIDs[plant.identifier] = plantKey
                self:CreatePlant(plantKey)

                print('found cocaine plant #', plant.identifier, plant.location)
            end
        end
    end)
end

function Cocaine:GetPlantGrowthStage(growthAmount)
    if not growthAmount then return end

    for _, growthStgData in pairs(self.GrowthStages) do
        if growthAmount >= growthStgData.minGrowth and growthAmount <= growthStgData.maxGrowth then
            return growthStgData
        end
    end
end

function Cocaine:CreatePlant(plantKey)
    if not self.Plants[plantKey] then return end

    local plant = self.Plants[plantKey]
    local growthStage = self:GetPlantGrowthStage(plant.growth)

    if self.PlantProps[plant.identifier] then
        print('called to create a Cocaine plant which was already created.')
        return
    end

    if not growthStage then
        print('unable to find growth stage for cocaine plant with growth', plant.growth)
        return
    end

    allPlantLocations[plant.identifier] = plant.location
    self.PlantProps[plant.identifier] = Prop(plant.location, plant.rotation, growthStage.asset, 2, false, 0, 1)
end

function Cocaine:PlantSeed(player, seedType)
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

        Events.BroadcastRemote('Cocaine:ReceivePlants', self.Plants)

        --DB:Execute('INSERT INTO user_plants (identifier, planter, location, rotation, type, quality, water, nutrients, growth) VALUES (:0, :0, :0, :0, :0, :0, :0, :0, :0)', plantData.identifier, plantData.planter, JSON.stringify(plantData.location), JSON.stringify(plantData.rotation), plantData.type, plantData.quality, plantData.water, plantData.nutrients, plantData.growth)
        PersistentDatabase.Insert('CocainePlants', JSON.stringify({plants = self.Plants}), function () end)
    end, 100)

    player.showNotification('You\'ve planted a seed.')
    print('Cocaine seed planted #', plantID, plant:GetLocation())
end

function Cocaine:ClosestPlant(location)
    if not location then return end

    for _, otherLocation in pairs(allPlantLocations) do
        if location:Distance(otherLocation) <= 150.0 then
            return true
        end
    end
    return false
end

function Cocaine:UpdatePlant(plantKey)
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
    PersistentDatabase.Insert('CocainePlants', JSON.stringify({plants = self.Plants}), function () end)
end

function Cocaine:UpdatePlants()
    for plantKey in pairs(self.Plants) do
        self:UpdatePlant(plantKey)
    end
end

function Cocaine.UsedSeed(player, item)
    Cocaine:PlantSeed(player, string.gsub(item, '_seed', ''))
end

function Cocaine.RetrievePlant(player, plantKey)
    if not Cocaine.Plants[plantKey] then return end

    print(HELIXTable.Dump(Cocaine.Plants[plantKey]))
    Events.CallRemote('Cocaine:ShowPlant', player, Cocaine.Plants[plantKey])
end

function Cocaine.FeedPlant(player, plantid)
    if not Cocaine.PlantIDs[plantid] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local plantKey = Cocaine.PlantIDs[plantid]
    local plant = Cocaine.Plants[plantKey]

    if plant.grown then
        xPlayer.showNotification('You cannot feed this plant anymore.')
        return
    end

    plant.nutrients = plant.nutrients + 15
    if plant.nutrients > 100 then
        plant.nutrients = 100
    end

    xPlayer.showNotification('You\'ve provided nutrients for this plant.')
    xPlayer.call('Cocaine:UpdateCurrentPlant', plant)
end

function Cocaine.WaterPlant(player, plantid)
    if not Cocaine.PlantIDs[plantid] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local plantKey = Cocaine.PlantIDs[plantid]
    local plant = Cocaine.Plants[plantKey]

    if plant.grown then
        xPlayer.showNotification('You cannot water this plant anymore.')
        return
    end

    plant.water = plant.water + 15
    if plant.water > 100 then
        plant.water = 100
    end

    xPlayer.showNotification('You\'ve provided water for this plant.')
    xPlayer.call('Cocaine:UpdateCurrentPlant', plant)
end

function Cocaine.GetHarvest(quality)
    return quality >= 10 and math.floor((quality / 2) * 3) or 10
end

function Cocaine.GetSeed(quality)
    return quality >= 10 and math.floor((quality / 4) + 10) or 5
end

function Cocaine.HarvestPlant(player, plantid)
    if not Cocaine.PlantIDs[plantid] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local plantKey = Cocaine.PlantIDs[plantid]
    local plant = Cocaine.Plants[plantKey]

    if not plant.grown then
        xPlayer.showNotification('This plant hasn\'t finished growing.')
        return
    end

    allPlantLocations[plantid] = nil
    Cocaine.Plants[plantKey] = nil
    Cocaine.PlantIDs[plantid] = nil
    Cocaine.PlantProps[plantid]:Destroy()

    PersistentDatabase.Insert('CocainePlants', JSON.stringify({plants = Cocaine.Plants}), function (deleted)
        if deleted then
            local harvestAmount = Cocaine.GetHarvest(plant.quality)
            local seedAmount = Cocaine.GetSeed(plant.quality)

            Events.BroadcastRemote('Cocaine:ReceivePlants', Cocaine.Plants)
            xPlayer.call('Cocaine:ClosePlant')
            xPlayer.showNotification(('You\'ve harvested this plant. Harvested %s grams of cannabis and %s seeds.'):format(harvestAmount, seedAmount))
        end
    end)
end

function Cocaine.DestroyPlant(player, plantid)
    if not Cocaine.PlantIDs[plantid] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local plantKey = Cocaine.PlantIDs[plantid]

    allPlantLocations[plantid] = nil
    Cocaine.Plants[plantKey] = nil
    Cocaine.PlantIDs[plantid] = nil
    Cocaine.PlantProps[plantid]:Destroy()

    PersistentDatabase.Insert('CocainePlants', JSON.stringify({plants = Cocaine.Plants}), function(deleted)
        if deleted then
            Events.BroadcastRemote('Cocaine:ReceivePlants', Cocaine.Plants)
            xPlayer.showNotification('You\'ve destroyed this plant.')
        end
    end)
end

Timer.SetInterval(function ()
    Cocaine:UpdatePlants()
end, 10000)

Events.SubscribeRemote('Cocaine:FeedPlant', Cocaine.FeedPlant)
Events.SubscribeRemote('Cocaine:WaterPlant', Cocaine.WaterPlant)
Events.SubscribeRemote('Cocaine:HarvestPlant', Cocaine.HarvestPlant)
Events.SubscribeRemote('Cocaine:DestroyPlant', Cocaine.DestroyPlant)
Events.SubscribeRemote('Cocaine:RetrivePlant', Cocaine.RetrievePlant)

--- @brief sends the plants to the client side
Events.Subscribe('core:playerSpawned', function(player)
    Timer.SetTimeout(function ()
        Events.CallRemote('Cocaine:ReceivePlants', player, Cocaine.Plants)
    end, 2000)
end)

Chat.Subscribe('PlayerSubmit', function(message, player)
    local xPlayer = Core.GetPlayerFromId(player:GetID())

	if message == 'getseedC' then
        xPlayer.inventory.AddItem('columbian_coca_seed', 1)
    end
end)
