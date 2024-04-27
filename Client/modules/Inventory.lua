local InventoryHUD = Core.RegisterHUD('inventory', 'file://ui/modules/inventory/build/index.html')


local insert = table.insert
Core.InventoryOpened = false

inventory_waiting = false;

Events.SubscribeRemote('inventory:ItemAdded', function(item, label, count)
    InventoryHUD.Call('ItemAdded', item, label, count)
end)

Events.SubscribeRemote('inventory:ItemRemoved', function(item, label, count)
    InventoryHUD.Call('ItemRemoved', item, label, count)
end)

Events.SubscribeRemote('inventory:CloseInventory', function()
    CloseInventory()
end)

InventoryHUD.Subscribe('AttemptSlotMovement', function(data)
    inventory_waiting = true
    Core.TriggerCallback('inventory:ValidateMovement', function(valid, inv, otherInventories)
        if valid then

            local sanitisedInventory = SanitiseInventory(inv)
    
            if otherInventories then
                for k, v in ipairs(otherInventories) do
                    otherInventories[k] = SanitiseInventory(v)
                end
            end
            InventoryHUD.Call('OpenInventory', {
                inventoryData = sanitisedInventory,
                nearbyInventories = otherInventories
            })
        end
        inventory_waiting = false
    end, data)
end)


InventoryHUD.Subscribe('GetNearbyPlayers', function()
    local player = Client.GetLocalPlayer()
    local char = player:GetControlledCharacter()
    
    local p_coord = char:GetLocation()

    local players = Player.GetPairs()

    local nearbyPlayers = {}
    for k, v in pairs(players) do
        local char = v:GetControlledCharacter()
        local pos = char:GetLocation()
        
        local distance = p_coord:Distance(pos)
        if (distance < 50) then
            insert(nearbyPlayers, { name = v:GetName(), profile = v:GetAccountIconURL(), distance = distance, source = v:GetID() })
        end
    end

    InventoryHUD.Call('SendNearbyPlayers', nearbyPlayers)
end)

-- Used to prevent race problem
local function CloseInventoryTimer()
    Timer.SetTimeout(function()
        if inventory_waiting then
            CloseInventoryTimer()
        else
            CloseInventory()
        end
    end, 150)
end

function CloseInventory()
    -- If waiting loop until recieved
    if inventory_waiting then
        return CloseInventoryTimer()
    end
    
    -- Core.BlurScreen(false)
    Core.ShowHUD()
    InventoryHUD.Focus(false, true)
    InventoryHUD.Call('CloseInventory')
    
    Core.InventoryOpened = false
end

function OpenInventory(forceOpen)
    Core.HideHUD()
    -- Core.BlurScreen(true)
    InventoryHUD.Focus(true, false)
    Core.InventoryOpened = true

    inventory_waiting = true
    Core.TriggerCallback('inventory:GetInventory', function(inv, otherInvs)
        InventoryHUD.Focus(true, false)
        
        local sanitisedInventory = SanitiseInventory(inv)

        if otherInvs then
            for k, v in ipairs(otherInvs) do
                otherInvs[k] = SanitiseInventory(v)
            end
        end

        local player = Client.GetLocalPlayer()
        local character = player:GetControlledCharacter()


        local source = {
            name = player:GetName(),
            profile = player:GetAccountIconURL()
        }

        InventoryHUD.Call('OpenInventory', {
            inventoryData = sanitisedInventory,
            nearbyInventories = otherInvs,
            source = source,
            forceOpen = true
        })

        InventoryHUD.Call('StatusUpdate', { status = { name = 'health', value = character:GetHealth(), colour = '#FF5555' } })

        inventory_waiting = false
    end, other)
end


function SanitiseInventory(inv)
    local sanitisedInventory = {
        id = inv.id .. '',
        pockets = inv.pockets,
        slots = inv.slots,
        label = inv.label,
        weight = inv.weight,
    }
    return sanitisedInventory
end

function RemoveItem(data)
    Events.CallRemote('inventory:DropItem', data)
    OpenInventory()
end

function GiveItem(data)
    Events.CallRemote('inventory:GiveItem', data)
    OpenInventory()
end

function UseItem(data, closeInv)
    Events.CallRemote('inventory:UseInventorySlot', data.slot, data.extra)
    
    if Core.InventoryOpened then
        OpenInventory()
    end
    
    if closeInv then
        CloseInventory()
    end
end

function SplitItem(slot, amount)
    inventory_waiting = true
    Core.TriggerCallback('inventory:SplitItem', function(valid, inv, otherInventories)
        if valid then
            InventoryHUD.Call('inventory:OpenInventory', {
                inventoryData = inv,
                nearbyInventories = otherInventories
            })
        end
        inventory_waiting = false
    end, slot, amount)
end

InventoryHUD.Subscribe('CloseInventory', CloseInventory)
InventoryHUD.Subscribe('DropItem', RemoveItem)
-- InventoryHUD.Subscribe('UseItem', RemoveItem)
InventoryHUD.Subscribe('GiveItem', GiveItem)
InventoryHUD.Subscribe('UseItem', UseItem)
InventoryHUD.Subscribe('inventory:SplitItem', SplitItem)

Core.RegisterInput('I', function()
    if Core.InventoryOpened then
        CloseInventory()
        return
    end
    
    OpenInventory(true)
end)

-- Glovebox
Core.RegisterInput('G', function()
    if not Core.IsPlayerInAnyVehicle() then return end
    if Core.InventoryOpened then
        CloseInventory()
        return
    end
    
    -- OpenInventory({ type = 'glovebox' })
end)

FastSlots = {
    ['One'] = 1,
    ['Two'] = 2,
    ['Three'] = 3,
    ['Four'] = 4,
    ['Five'] = 5,
}

Input.Subscribe("KeyPress", function(key_name)
    if key_name == 'Escape' then
        if Core.InventoryOpened then
            InventoryHUD.Call('EscapeButtonPressed')
        end

        return
    end

    local fastSlot = FastSlots[key_name]
    if not fastSlot then return end

    UseItem({slot=fastSlot, extra='pockets'})
end)