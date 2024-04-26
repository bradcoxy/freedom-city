Package.Require('PlantBased/Weed.lua')
Package.Require('PlantBased/Cocaine.lua')
Package.Require('PlantBased/Heroin.lua')

allPlantLocations = {}
Package.Subscribe('Load', function ()
    Core.CreateItem({
        ['pot'] = {
            label = 'Pot',
            unique = true,
            description = 'For planting seeds.',
            type = 'item',
        },
    })
end)