local Heroin = {}

Heroin.Plants = {}
Heroin.PlantIDs = {}
Heroin.PlantProps = {}
Heroin.GrowthStages = {
    [1] = {
        asset = 'drug-plants::SM_Heroine_Stage1',
        minGrowth = 0,
        maxGrowth = 20,
    },
    [2] = {
        asset = 'drug-plants::SM_Heroine_Stage2',
        minGrowth = 20,
        maxGrowth = 40,
    },
    [3] = {
        asset = 'drug-plants::SM_Heroine_Stage3',
        minGrowth = 40,
        maxGrowth = 60,
    },
    [4] = {
        asset = 'drug-plants::SM_Heroine_Stage4',
        minGrowth = 60,
        maxGrowth = 100,
    },
}

Heroin.Types = {
    ['afgan_poppy'] = {
        label = 'Afgan Poppy',
        seedPrice = 90,
    },
    ['mexican_poppy'] = {
        label = 'Mexican Poppy',
        seedPrice = 70,
    },
    ['burmese_poppy'] = {
        label = 'Burmese Poppy',
        seedPrice = 50,
    },
}

local random = math.random

Package.Subscribe('Load', function ()
    for heroin, heroinInfo in pairs(Heroin.Types) do

        heroinInfo.seed = ('%s_seed'):format(heroin)
        heroinInfo.raw = ('%s_raw'):format(heroin)
        heroinInfo.dried = ('%s_dried'):format(heroin)

        Core.CreateItem({
            [heroin] = {
                label = heroinInfo.label,
                unique = false,
                description = 'Good times.',
                type = 'item',
            },
            [heroinInfo.raw] = {
                label = ('Raw %s'):format(heroinInfo.label),
                unique = false,
                description = 'Good times.',
                type = 'item',
            },
            [heroinInfo.dried] = {
                label = ('Dry %s'):format(heroinInfo.label),
                unique = false,
                description = 'Good times.',
                type = 'item',
            },
            [heroinInfo.seed] = {
                label = ('%s Seed'):format(heroinInfo.label),
                unique = false,
                description = 'A chance.',
                type = 'item',
            }
        })

        --Core.CreateUseableItem(heroin, )
        --Core.CreateUseableItem(heroinInfo.raw, )
        --Core.CreateUseableItem(heroinInfo.dried, )
        Core.CreateUseableItem(heroinInfo.seed, Heroin.UsedSeed)
    end

    Heroin:GetPlants()
end)

function Heroin:GetPlants()
    PersistentDatabase.GetByKey('HeroinPlants', function(success, data)
        data = JSON.parse(data)
        if success and data[1] then
            local plants = data[1]['value']['plants']

            for k, plant in pairs(plants) do
                if not plant.identifier then return end

                local plantKey = #self.Plants + 1
                self.Plants[plantKey] = plant
                self.PlantIDs[plant.identifier] = plantKey
                self:CreatePlant(plantKey)

                print('found heroin plant #', plant.identifier, plant.location)
            end
        end
    end)
end

function Heroin:GetPlantGrowthStage(growthAmount)
    if not growthAmount then return end

    for _, growthStgData in pairs(self.GrowthStages) do
        if growthAmount >= growthStgData.minGrowth and growthAmount <= growthStgData.maxGrowth then
            return growthStgData
        end
    end
end

function Heroin:CreatePlant(plantKey)
    if not self.Plants[plantKey] then return end

    local plant = self.Plants[plantKey]
    local growthStage = self:GetPlantGrowthStage(plant.growth)

    if self.PlantProps[plant.identifier] then
        print('called to create a Heroin plant which was already created.')
        return
    end

    if not growthStage then
        print('unable to find growth stage for heroin plant with growth', plant.growth)
        return
    end

    allPlantLocations[plant.identifier] = plant.location
    self.PlantProps[plant.identifier] = Prop(plant.location, plant.rotation, growthStage.asset, 2, false, 0, 1)
end

function Heroin:PlantSeed(player, seedType)
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

        Events.BroadcastRemote('Heroin:ReceivePlants', self.Plants)

        --DB:Execute('INSERT INTO user_plants (identifier, planter, location, rotation, type, quality, water, nutrients, growth) VALUES (:0, :0, :0, :0, :0, :0, :0, :0, :0)', plantData.identifier, plantData.planter, JSON.stringify(plantData.location), JSON.stringify(plantData.rotation), plantData.type, plantData.quality, plantData.water, plantData.nutrients, plantData.growth)
        PersistentDatabase.Insert('HeroinPlants', JSON.stringify({plants = self.Plants}), function () end)
    end, 100)

    player.showNotification('You\'ve planted a seed.')
    print('Heroin seed planted #', plantID, plant:GetLocation())
end

function Heroin:ClosestPlant(location)
    if not location then return end

    for _, otherLocation in pairs(allPlantLocations) do
        if location:Distance(otherLocation) <= 150.0 then
            return true
        end
    end
    return false
end

function Heroin:UpdatePlant(plantKey)
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
    PersistentDatabase.Insert('HeroinPlants', JSON.stringify({plants = self.Plants}), function () end)
end

function Heroin:UpdatePlants()
    for plantKey in pairs(self.Plants) do
        self:UpdatePlant(plantKey)
    end
end

function Heroin.UsedSeed(player, item)
    Heroin:PlantSeed(player, string.gsub(item, '_seed', ''))
end

function Heroin.RetrievePlant(player, plantKey)
    if not Heroin.Plants[plantKey] then return end

    print(HELIXTable.Dump(Heroin.Plants[plantKey]))
    Events.CallRemote('Heroin:ShowPlant', player, Heroin.Plants[plantKey])
end

function Heroin.FeedPlant(player, plantid)
    if not Heroin.PlantIDs[plantid] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local plantKey = Heroin.PlantIDs[plantid]
    local plant = Heroin.Plants[plantKey]

    if plant.grown then
        xPlayer.showNotification('You cannot feed this plant anymore.')
        return
    end

    plant.nutrients = plant.nutrients + 15
    if plant.nutrients > 100 then
        plant.nutrients = 100
    end

    xPlayer.showNotification('You\'ve provided nutrients for this plant.')
    xPlayer.call('Heroin:UpdateCurrentPlant', plant)
end

function Heroin.WaterPlant(player, plantid)
    if not Heroin.PlantIDs[plantid] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local plantKey = Heroin.PlantIDs[plantid]
    local plant = Heroin.Plants[plantKey]

    if plant.grown then
        xPlayer.showNotification('You cannot water this plant anymore.')
        return
    end

    plant.water = plant.water + 15
    if plant.water > 100 then
        plant.water = 100
    end

    xPlayer.showNotification('You\'ve provided water for this plant.')
    xPlayer.call('Heroin:UpdateCurrentPlant', plant)
end

function Heroin.GetHarvest(quality)
    return quality >= 10 and math.floor((quality / 2) * 3) or 10
end

function Heroin.GetSeed(quality)
    return quality >= 10 and math.floor((quality / 4) + 10) or 5
end

function Heroin.HarvestPlant(player, plantid)
    if not Heroin.PlantIDs[plantid] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local plantKey = Heroin.PlantIDs[plantid]
    local plant = Heroin.Plants[plantKey]

    if not plant.grown then
        xPlayer.showNotification('This plant hasn\'t finished growing.')
        return
    end

    allPlantLocations[plantid] = nil
    Heroin.Plants[plantKey] = nil
    Heroin.PlantIDs[plantid] = nil
    Heroin.PlantProps[plantid]:Destroy()

    PersistentDatabase.Insert('HeroinPlants', JSON.stringify({plants = Heroin.Plants}), function (deleted)
        if deleted then
            local harvestAmount = Heroin.GetHarvest(plant.quality)
            local seedAmount = Heroin.GetSeed(plant.quality)

            Events.BroadcastRemote('Heroin:ReceivePlants', Heroin.Plants)
            xPlayer.call('Heroin:ClosePlant')
            xPlayer.showNotification(('You\'ve harvested this plant. Harvested %s grams of cannabis and %s seeds.'):format(harvestAmount, seedAmount))
        end
    end)
end

function Heroin.DestroyPlant(player, plantid)
    if not Heroin.PlantIDs[plantid] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local plantKey = Heroin.PlantIDs[plantid]

    allPlantLocations[plantid] = nil
    Heroin.Plants[plantKey] = nil
    Heroin.PlantIDs[plantid] = nil
    Heroin.PlantProps[plantid]:Destroy()

    PersistentDatabase.Insert('HeroinPlants', JSON.stringify({plants = Heroin.Plants}), function(deleted)
        if deleted then
            Events.BroadcastRemote('Heroin:ReceivePlants', Heroin.Plants)
            xPlayer.showNotification('You\'ve destroyed this plant.')
        end
    end)
end

Timer.SetInterval(function ()
    Heroin:UpdatePlants()
end, 10000)

Events.SubscribeRemote('Heroin:FeedPlant', Heroin.FeedPlant)
Events.SubscribeRemote('Heroin:WaterPlant', Heroin.WaterPlant)
Events.SubscribeRemote('Heroin:HarvestPlant', Heroin.HarvestPlant)
Events.SubscribeRemote('Heroin:DestroyPlant', Heroin.DestroyPlant)
Events.SubscribeRemote('Heroin:RetrivePlant', Heroin.RetrievePlant)

--- @brief sends the plants to the client side
Events.Subscribe('core:playerSpawned', function(player)
    Timer.SetTimeout(function ()
        Events.CallRemote('Heroin:ReceivePlants', player, Heroin.Plants)
    end, 2000)
end)

Chat.Subscribe('PlayerSubmit', function(message, player)
    local xPlayer = Core.GetPlayerFromId(player:GetID())

	if message == 'getseedH' then
        xPlayer.inventory.AddItem('afgan_poppy_seed', 1)
    end
end)
