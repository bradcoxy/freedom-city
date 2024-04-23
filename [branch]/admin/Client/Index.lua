--[[-------------------------------------
--   @brief   Helix Admin Menu         --
--                                     --
--                                     --
--   @author  @Kravs                   --
--   @version 0.0.1                    --
--   @date    May 2023                 --
---------------------------------------]]



-------------------------------------
---   [UI]   -----------
-------------------------------------
Package.Require('PhysicsGun.lua')

local AdminMenu = {}

AdminMenu.UI = WebUI("Admin HUD", "file:///UI/index.html")
AdminMenu.Allowed = false

local uiStatus = false

--- @brief Open the Admin Menu UI
--- @param state boolean
function AdminMenu.OpenUI(state)
    if state == nil then return end

    local playerCount = AdminMenu.GetPlayersCount()
    local players = AdminMenu.GetAllPlayers()

    if (state == true) then
        AdminMenu.UI:CallEvent("AdminMenu:OpenUI", state, players, playerCount)
        AdminMenu.UI:BringToFront()
        uiStatus = true
        Input.SetMouseEnabled(true)
        Input.SetInputEnabled(false)
        return
    end

    AdminMenu.UI:CallEvent("AdminMenu:OpenUI", state, nil, nil)
    Input.SetMouseEnabled(false)
    Input.SetInputEnabled(true)

    uiStatus = false
end

AdminMenu.UI:Subscribe("GetPlayerInfo", function(selectedPlayer)
    Events.CallRemote("Server:GetPlayerInfo", selectedPlayer)
end)

Events.SubscribeRemote("Client:PlayerInfo", function(playerInfo)
    AdminMenu.UI:CallEvent("UpdatePlayerInfo", playerInfo)
end)

AdminMenu.UI:Subscribe("GoToPlayer", function(playerIdentifier)
    local target = AdminMenu.GetPlayerFromIdentifier(playerIdentifier)
    if target then
        Events.CallRemote("Goto:Teleport", target)
    else
        -- notify that target is not online
    end
end)

AdminMenu.UI:Subscribe("BringPlayer", function(playerIdentifier)
    local allPlayers = Player.GetAll()
    local my_player = Client.GetLocalPlayer()
    local target = AdminMenu.GetPlayerFromIdentifier(playerIdentifier)

    if target then
        Events.CallRemote("Bring:Teleport", target)
    else
        -- notify that target is not online
    end
end)

AdminMenu.UI:Subscribe("KillPlayer", function(playerIdentifier)
    local allPlayers = Player.GetAll()
    local my_player = Client.GetLocalPlayer()
    local target = AdminMenu.GetPlayerFromIdentifier(playerIdentifier)

    if target then
        Events.CallRemote("Player:Kill", target)
    else
        -- notify that target is not online
    end
end)

AdminMenu.UI:Subscribe("RevivePlayer", function(playerIdentifier)
    local allPlayers = Player.GetAll()
    local my_player = Client.GetLocalPlayer()
    local target = AdminMenu.GetPlayerFromIdentifier(playerIdentifier)

    if target then
        Events.CallRemote("Player:Revive", target)
    else
        -- notify that target is not online
    end
end)

AdminMenu.UI:Subscribe("TogglePhysicsGun", function ()
    print('physics gun ', physicsToggle)
    physicsToggle = not physicsToggle
end)

AdminMenu.UI:Subscribe("KickPlayer", function(playerIdentifier, reason)
    local allPlayers = Player.GetAll()
    local my_player = Client.GetLocalPlayer()
    local target = AdminMenu.GetPlayerFromIdentifier(playerIdentifier)

    if target then
        Events.CallRemote("Player:Kick", target, reason)
    else
        -- notify that target is not online
    end
end)

AdminMenu.UI:Subscribe('BanPlayer', function(playerIdentifier)
    local target = AdminMenu.GetPlayerFromIdentifier(playerIdentifier)

    if target then
        Events.CallRemote("Player:Ban", target)
    end
end)

AdminMenu.UI:Subscribe("SetPlayerJob", function(playerIdentifier, job)
    local allPlayers = Player.GetAll()
    local my_player = Client.GetLocalPlayer()
    local target = AdminMenu.GetPlayerFromIdentifier(playerIdentifier)

    if target then
        Events.CallRemote("Player:SetJob", target, job)
    else
        -- notify that target is not online
    end
end)

AdminMenu.UI:Subscribe("ToggleNoclip", function(playerIdentifier)
    local allPlayers = Player.GetAll()
    local my_player = Client.GetLocalPlayer()
    local target = AdminMenu.GetPlayerFromIdentifier(playerIdentifier)
    print("????????????")
    if target then
        Events.CallRemote("Player:ToggleNoclip", target)
    else
        -- notify that target is not online
    end
end)

AdminMenu.UI:Subscribe("ToggleGodMode", function(playerIdentifier)
    local allPlayers = Player.GetAll()
    local my_player = Client.GetLocalPlayer()
    local target = AdminMenu.GetPlayerFromIdentifier(playerIdentifier)

    if target then
        Events.CallRemote("Player:ToggleGodMode", target)
    else
        -- notify that target is not online
    end
end)

AdminMenu.UI:Subscribe("ToggleVisibility", function(playerIdentifier)
    local allPlayers = Player.GetAll()
    local my_player = Client.GetLocalPlayer()
    local target = AdminMenu.GetPlayerFromIdentifier(playerIdentifier)

    if target then
        Events.CallRemote("Player:ToggleVisibility", target)
    else
        -- notify that target is not online
    end
end)

AdminMenu.UI:Subscribe("FixVehicle", function(playerIdentifier)
    local allPlayers = Player.GetAll()
    local my_player = Client.GetLocalPlayer()
    local target = AdminMenu.GetPlayerFromIdentifier(playerIdentifier)

    if target then
        Events.CallRemote("Player:FixVehicle", target)
    else
        -- notify that target is not online
    end
end)

AdminMenu.UI:Subscribe("DeleteVehicle", function(playerIdentifier)
    local allPlayers = Player.GetAll()
    local my_player = Client.GetLocalPlayer()
    local target = AdminMenu.GetPlayerFromIdentifier(playerIdentifier)

    if target then
        Events.CallRemote("Player:DeleteVehicle", target)
    else
        -- notify that target is not online
    end
end)

AdminMenu.UI:Subscribe("GiveCar", function(playerIdentifier, carModel)
    local target = AdminMenu.GetPlayerFromIdentifier(playerIdentifier)
    if target then
        Events.CallRemote("Player:GiveVehicle", target, carModel)
    else
        -- notify that target is not online
    end
end)

AdminMenu.UI:Subscribe("HandleAccountMoney", function(playerIdentifier, type, operation, amount)
    local target = AdminMenu.GetPlayerFromIdentifier(playerIdentifier)
    if target then
        print(type, operation, amount)
        Events.CallRemote("Player:HandleAccountMoney", target, type, operation, amount)
    else
        -- notify that target is not online
    end
end)

-------------------------------------
---   [Local Functions]   -----------
-------------------------------------

--- @brief Get the player count
function AdminMenu.GetPlayersCount()
    local players = Player.GetAll()
    if (players) then
        return #players
    end
end

--- @brief Get all players
function AdminMenu.GetAllPlayers()
    local players = Player.GetAll()
    local playersTable = {}
    if (players) then
        for k, player in pairs(players) do
            local playerTab = {}
            local identifier = player:GetAccountID()
            local playerName = player:GetName()
            table.insert(playersTable, { identifier = identifier, name = playerName, player = tostring(player) })
        end
        print(NanosUtils.Dump(playersTable))
        return playersTable
    end
end

function AdminMenu.GetPlayerFromIdentifier(identifier)
    local allPlayers = Player.GetAll()
    for i, target in pairs(allPlayers) do
        if (target:GetAccountID() == identifier) then
            return target
        end
    end
end

-------------------------------------
---   [Game Events]   -----------
-------------------------------------

--- @brief Subscribe to KeyPress Event to open the Admin Menu
Input.Subscribe("KeyPress", function(key_name, delta)
    if key_name == "F1" then
        if AdminMenu.Allowed then
            if uiStatus == false then
                AdminMenu.OpenUI(true)
            else
                AdminMenu.OpenUI(false)
                Input.SetInputEnabled(true)
            end
        end
    end
    return true
end)


Events.SubscribeRemote('Client:AdminAllowed', function(bool)
    AdminMenu.Allowed = bool
end)