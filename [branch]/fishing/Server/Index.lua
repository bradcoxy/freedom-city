local Fishing = {}

Fishing.Zones = {
    ['fishingZone1'] = {
        --- Displayable 'Label' of the zone
        label = 'Mount Niagra Fishing Spot',
        coords =  Vector(1703.5999755859, -3789.5, 5.0),
        rotator = Rotator(0.0, 360, 0.0),
        size = 5,
        chance = 50,
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
        chance = 50,
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
        print('fish caught in line : '..fishCaught)
    end

    if not fishCaught then
        xPlayer.showNotification('You couldn\'t catch anything, try again.')
        return
    end

    Timer.SetTimeout(function ()
        xPlayer.showNotification(('You caught %s.'):format(Fishing.Fish[fishCaught].label))
        -- allows the player to fish again
        Events.CallRemote('Fishing:ClientEvent', player, 'finished_fishing')
    end, 3000)
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
end)

Events.SubscribeRemote('Fishing:Start', Fishing.StartFishing)
Events.SubscribeRemote('Fishing:Sell', Fishing.SellFish)
Player.Subscribe('Ready', function(self)
    Events.CallRemote('Fishing:ZonesMongersFish', self, Fishing.Zones, Fishing.Mongers, Fishing.Fish)
end)