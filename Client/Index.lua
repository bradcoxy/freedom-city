Core.HUDList = {}

Package.Require('/Client/modules/UserInterfaceManagment.lua')
Package.Require('/Client/Functions.lua')
Package.Require('/Client/utils/Utils.lua')

Package.Require('/Client/modules/Menus.lua')
Package.Require('/Client/modules/Multichar.lua')
Package.Require('/Client/modules/Interaction.lua')
Package.Require('/Client/modules/Notifications.lua')

Package.Require('/Client/modules/JobLevels.lua')
Package.Require('/Client/modules/Inventory.lua')
Package.Require('/Client/modules/HUD.lua')
Package.Require('/Client/modules/Tags.lua')
Package.Require('/Client/modules/SpawnMenu.lua')
Package.Require('/Client/modules/VehicleHUD.lua')


Package.Require('/Client/classes/C_Markers.lua')
Package.Require('/Client/classes/C_Camera.lua')


local HUD = Core.GetHUD('main')
local InventoryHUD = Core.GetHUD('inventory')

Core.RegisterInput('Q', function(key)
    local menusOpened = Core.GetMenusOpened()
    if not menusOpened then return end

    for k, v in pairs(menusOpened) do
        local HUD = Core.GetHUD(k)
        HUD.Call(v.closeEvent)
        HUD.Focus(false, true)
        Core.MenusOpened[k] = {}
    end
end)

Core.RegisterInput('LeftControl', function(key)
    if not Core.PlayerData.insideVehicle then return end
    local vehicle = Core.PlayerData.insideVehicle
    if vehicle:GetValue('running') then return end

    Events.CallRemote("core:onVehicleEngineStart", vehicle)
    Core.RemoveInteraction("LeftControl")
end)

--- @brief Event to close all menus (created to close menus that open UI's or menus that open menus)
Events.Subscribe("CloseAllMenus", function ()
    local menusOpened = Core.GetMenusOpened()
    if not menusOpened then return end

    for k, v in pairs(menusOpened) do
        local HUD = Core.GetHUD(k)
        HUD.Call(v.closeEvent)
        HUD.Focus(false, true)

        Core.MenusOpened[k] = {}
    end
end)


Events.Subscribe("Core:VehicleCreated", function(_, vehiclesSpawned)
    Core.VehiclesSpawned = vehiclesSpawned;
end)


Character.Subscribe("EnterVehicle", function(self, vehicle, seat_index)
    local charPly = self:GetPlayer()

    if charPly == nil then return end

    if (charPly:GetAccountID() ~= Client.GetLocalPlayer():GetAccountID()) then
        return
    end

    if seat_index ~= 0 then
        return
    end
    
    Core.ToggleSpeedometer(true)
end)

Character.Subscribe("LeaveVehicle", function(self, vehicle)
    local charPly = self:GetPlayer()

    if charPly == nil then return end

    if (charPly:GetAccountID() ~= Client.GetLocalPlayer():GetAccountID()) then
        return
    end

    Core.RemoveInteraction("LeftControl")
    Core.ToggleSpeedometer(false)
end)

Character.Subscribe("HealthChange", function(self, old_health, new_health)
    local charPly = self:GetPlayer()

    if charPly == nil then return end

    if (charPly:GetAccountID() ~= Client.GetLocalPlayer():GetAccountID()) then
        return
    end


    local char = charPly:GetControlledCharacter()

    local maxHealth = char:GetMaxHealth()
    
    local stat = {
        health = { value = new_health, max = maxHealth }
    }
    
    HUD.Call('helix-hud:UpdateStatus', stat)
end)


Character.Subscribe("HealthChange", function(self, old_health, new_health)
    InventoryHUD.Call('StatusUpdate', { status = { name = 'health', value = new_health, colour = '#FF5555' } })
end)

Events.SubscribeRemote("core:onStatusTick", function(stats)
    if not Core.PlayerData then
        Core.PlayerData = {}
    end
    
    Core.PlayerData.stats = stats

    for k, v in ipairs(stats) do
        if (v.name == 'hunger' or v.name == 'thirst') and v.value <= 100 then
            -- Client.GetLocalPlayer():GetControlledCharacter():ApplyDamage(10)
        end

        -- InventoryHUD.Call('StatusUpdate', { status = { name = v.name, value = v.value, colour = '#ffffff' } })
    end

    
    HUD.Call('helix-hud:UpdateStatus', stats)
end)

Events.SubscribeRemote('ClientFromServerTriggerCallback', function(name, ...)
    if Core.ServerCallbacks[name] == nil then
        return
    end

    if type(Core.ServerCallbacks[name]) == 'function' then
        Core.ServerCallbacks[name](...)
    else
        Core.ServerCallbacks[name]:resolve(...)
    end

    Core.ServerCallbacks[name] = nil
end)

Events.SubscribeRemote('InitialiseMarkers', function(markerTbl)
    for k, v in pairs(markerTbl) do
        if Core.Markers[k] then
            Core.Markers[k].marker = v.marker
        else
            Core.Markers[k] = { marker = v.marker }
        end
    end
end)

Events.SubscribeRemote('ShowNotification', function(msg, duration, ...)
    Core.ShowNotification(msg, duration)
end)

Events.SubscribeRemote('core:onEnterMarker', function(marker, dist, name)
    Core.Markers[name].onEnter(marker, dist)
end)

Events.SubscribeRemote('core:onLeaveMarker', function(marker, dist, name)
    if not Core.Markers[name].onExit then return end
    Core.Markers[name].onExit(marker, dist)
end)

Events.SubscribeRemote("pcrp-core:HideHUD", function()
    Core.CloseInventory()
    Core.HideHUD()
end)

Events.SubscribeRemote("pcrp-core:ShowHUD", function()
    Core.ShowHUD()
end)

Events.SubscribeRemote('core:playerSpawned', function(playerData)
    Core.PlayerData = playerData
end)

Client.Subscribe("SpawnLocalPlayer", function(local_player)    
    local_player:Subscribe('ValueChange', function(local_player, key, value)
        if key == 'playerData' then
            print("UPDATING PLAYER DATA")
            Console.Log(HELIXTable.Dump(value))
            Core.PlayerData = value
            -- for k, v in pairs(Core.Markers) do
            --     if v.onUpdate then
            --         v.onUpdate()
            --     end
            -- end
        end
    end)
end)

local PromptHUD = Core.RegisterHUD('prompt', 'file://ui/modules/prompt/prompt.html')

PromptHUD.Subscribe('interaction:completed', function(key)
    if not Core.Interactions[key] then return end
    for k, v in ipairs(Core.RegisteredKeys[key]) do
        v.onPress(key)
    end
end)

Input.Register("CancelProgress", "BackSpace")
Input.Bind("CancelProgress", InputEvent.Pressed, function()
    if (current_prog_id == nil) then return end
    
    current_prog_canceled = true

    local mainHUD = Core.GetHUD('main');
    mainHUD.Call('progressbar:CancelProgress')  
end)

MovementKeys = {
    ['W'] = true,
    ['A'] = true,
    ['S'] = true,
    ['D'] = true,
    ['Space'] = true,
    ['LeftControl'] = true,
    ['Z'] = true
}

Input.Subscribe("KeyDown", function(key_name, delta)
    if current_prog_id == nil then return end
    if current_prog_disabled == nil then return end

    if current_prog_disabled.movement then
        if MovementKeys[key_name] then
            return false
        end
    end

end)

current_prog_id = nil
current_prog_canceled = false
current_prog_disabled = nil

if CoreCFG.Debug then
--[[     local DEBUG_COORDS = Canvas(
        true,
        Color.TRANSPARENT,
        0,
        true
      ) ]]
      
    -- Subscribes for Update, we can only Draw inside this event
--[[     DEBUG_COORDS:Subscribe("Update", function(self, width, height)
        local player = Client.GetLocalPlayer()
        if not player then return end
        player = player:GetCameraLocation()
    
        local str = "X = " .. player.X .. ", Y = " .. player.Y .. ", Z = " .. player.Z
        -- Draws a Text in the middle of the screen
        self:DrawText(str, Vector2D(width * 0.5, height * 0.15))
    end) ]]
    
--[[     Console.Subscribe("LogEntry", function(text, type)
        -- LogEntry was called
        Chat.AddMessage(text)
    end) ]]
end
