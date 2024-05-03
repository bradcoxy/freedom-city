--[[
local SpawnUI = Core.RegisterHUD('spawn', 'file://ui/modules/spawnmenu/build/index.html')

local SpawnTypes = {
    FamilyOnline = 1,
    BattlePass = 2,
    SpawnPlace = 3
}

local SpawnSettings = {
    {
        type = SpawnTypes.FamilyOnline,
        values = {
            online = 100,
            value = "Test"
        }
    },
    {
        type = SpawnTypes.BattlePass,
        values = {
            label = "Buy Battle Pass to see your family",
            value = "Sell"
        }
    },
    {
        type = SpawnTypes.BattlePass,
        values = {
            label = "Buy Battle Pass to see your family",
            value = "Sell 2"
        }
    },
    {
        type = SpawnTypes.SpawnPlace,
        values = {
            subheader = "Random",
            label = "RANDOM PLACE",
            value = "Spawn"
        }
    },
    {
        type = SpawnTypes.SpawnPlace,
        values = {
            subheader = "Random",
            label = "RANDOM PLACE",
            value = "Spawn"
        }
    },
    {
        type = SpawnTypes.SpawnPlace,
        values = {
            subheader = "Random",
            label = "RANDOM PLACE",
            value = "Spawn"
        }
    },
    {
        type = SpawnTypes.SpawnPlace,
        values = {
            subheader = "Random",
            label = "RANDOM PLACE",
            value = "Spawn"
        }
    }
}

function ToggleSpawnMenu(state)
    SpawnUI.Focus(state, not state)
    SpawnUI.Call("SetupMenu", SpawnSettings)
    SpawnUI.Call("SetVisible", state)
    
    if state then
        Core.HideHUD()
    else
        Core.ShowHUD()
    end
end

Events.SubscribeRemote('pcrp-core:SpawnMenu', function(state)
    ToggleSpawnMenu(state)
end)

SpawnUI.Subscribe("SelectSpawn", function()
    ToggleSpawnMenu(false)

    Events.CallRemote("SendToApartment")
end)
]]