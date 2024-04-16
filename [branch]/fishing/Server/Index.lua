local Fishing = {}

Fishing.Zones = {
    ['fishingZone1'] = {
        --- Displayable 'Label' of the zone
        label = 'Mount Niagra Fishing Spot',
        coords =  Vector(1703.5999755859, -3789.5, 5.0),
        rotator = Rotator(0.0, 360, 0.0),
        size = 5,
        chance = 90,
        fish = {
            -- different types of fish.
            'tuna',
            'salmon',
            'tilapia',
            'cod',
        },
    },
    ['fishingZone2'] = {
        label = 'Mount Chilliad Fishing Spot',
        coords = Vector(1703.5, -5829.8999023438, 5.0),
        rotator = Rotator(0.0, 360, 0.0),
        size = 5,
        chance = 90,
        fish = {
            'tilapia',
            'cod',
            'tuna',
            'salmon',
        },
    },
}

Fishing.Fish = {
    ['tuna'] = {
        label =  'Tuna',
        price = 450,
        current_price_inc = 10,
    },
    ['salmon'] = {
        label =  'Salmon',
        price = 650,
        current_price_inc = 5,
    },
    ['tilapia'] = {
        label =  'Tilapia',
        price = 850,
        current_price_inc = 20,
    },
    ['cod'] = {
        label =  'COD',
        price = 1050,
        current_price_inc = 25,
    },
}

Fishing.Mongers = {
    ['fishingMonger1'] = {
        coords = Vector(712.59997558594, -4565.5, 98.099998474121),
        rotation = Rotator(0.0, 360, 0.0),
        model = 'helix::SK_Male'
    }
}

function Fishing.StartFishing(player, zone)
    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local currentZone = Fishing.Zones[zone]
    local fishChance = currentZone.chance or 50
    local randomChance = math.random(0, 100)
    local randomFish = math.random(1, #currentZone.fish)
    local fishCaught = nil

    if randomChance <= fishChance then
        fishCaught = currentZone.fish[randomFish]
    end

    Timer.SetTimeout(function ()
        if not fishCaught then
            xPlayer.showNotification('The fish escaped, try again.')
            return
        end
        xPlayer.showNotification(('You caught %s.'):format(Fishing.Fish[fishCaught].label))
        xPlayer.inventory.AddItem(fishCaught, math.random(1, 5))
    end, 2000)
end

function Fishing.SellFish(player, fishData)
    if not player then return end
    if not Fishing.Fish[fishData.fish] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local fishToSell = Fishing.Fish[fishData.fish]
    local amount = fishData.amount
    local price = fishToSell.price * amount
    local priceIncreased = fishToSell.current_price_inc or 0

    if priceIncreased > 0 then
        price = HELIXMath.Round(price + price / 100 * priceIncreased)
    end

    xPlayer.addMoney(price)
    xPlayer.showNotification('You sold '..fishToSell.label..' for $'..price..'.')
    --- Remove the item
    for _, value in pairs(xPlayer.inventory.itemRegistry[fishData.fish]) do
        local item = xPlayer.inventory.GetSlot(value.slot, value.type)
        if item.count >= amount then
            xPlayer.inventory.RemoveItem(item.name, amount, item.metadata, item.slot, value.type)
        end
    end
    --- Incorporate this inside inventory class ^^^.
end

function Fishing.GetFish(player)
    if not player then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local has = {}

    for fish in pairs(Fishing.Fish) do
        local found = xPlayer.inventory.GetItem(fish)
        if found  then
            local item = xPlayer.inventory.GetSlot(found.slot, found.type)
            has[fish] = has[fish] and has[fish] + item.count or item.count
        end
    end
    xPlayer.call('Fishing:SellC', has)
end

Package.Subscribe('Load', function()
    for _, monger in pairs(Fishing.Mongers) do
        local ped = Character(monger.coords, monger.rotation, 'helix::SK_Male_Chest')

        ped:SetMesh('helix::SK_Man_Outwear_03')
        ped:AddSkeletalMeshAttached('headwear', 'helix::SK_Male_Head')
        ped:AddSkeletalMeshAttached('hands', 'helix::SK_Male_Hands')
        ped:AddSkeletalMeshAttached('bottomwear', 'helix::SK_Man_Pants_09')
        ped:AddSkeletalMeshAttached('footwear', 'helix::SK_Man_Boots_17')
        ped:SetInvulnerable(true)
    end

    for fishName, fish in pairs(Fishing.Fish) do
        Core.CreateItem({
            [fishName] = {
                label = fish.label,
                unique = true,
                description = string.format('A %s', fish.label),
                type = 'item',
            }
        })
    end

    for key, value in pairs(Player.GetPairs()) do
        Events.CallRemote('Fishing:ZonesMongersFish', value, Fishing.Zones, Fishing.Mongers, Fishing.Fish)
    end
end)

Events.SubscribeRemote('Fishing:Start', Fishing.StartFishing)
Events.SubscribeRemote('Fishing:Sell', Fishing.SellFish)
Events.SubscribeRemote('Fishing:GetFish', Fishing.GetFish)
Events.Subscribe('core:playerSpawned', function(self)
    Events.CallRemote('Fishing:ZonesMongersFish', self, Fishing.Zones, Fishing.Mongers, Fishing.Fish)
end)