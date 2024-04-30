local InventoryHUD = Core.RegisterHUD('inventory', 'file://ui/modules/inventory/build/index.html')
local insert = table.insert
Core.InventoryOpened = false

Events.SubscribeRemote('inventory:ItemAdded', function(item, label, count)
    InventoryHUD.Call('ItemAdded', item, label, count)
end)

Events.SubscribeRemote('inventory:ItemRemoved', function(item, label, count)
    InventoryHUD.Call('ItemRemoved', item, label, count)
end)

InventoryHUD.Subscribe('AttemptSlotMovement', function(data)
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

function Core.CloseInventory()
    -- Core.BlurScreen(false)
    Core.ShowHUD()
    InventoryHUD.Focus(false, true)
    InventoryHUD.Call('CloseInventory')
    
    Core.InventoryOpened = false
end

function Core.OpenInventory(forceOpen)
    Core.HideHUD()
    -- Core.BlurScreen(true)
    InventoryHUD.Focus(true, false)
    Core.InventoryOpened = true

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

        -- print(HELIXTable.Dump(sanitisedInventory))

        InventoryHUD.Call('OpenInventory', {
            inventoryData = sanitisedInventory,
            nearbyInventories = otherInvs,
            source = source,
            forceOpen = true
        })

        print(character:GetHealth())
        InventoryHUD.Call('StatusUpdate', { status = { name = 'health', value = character:GetHealth(), colour = '#FF5555' } })
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
    Core.OpenInventory()
end

function GiveItem(data)
    Events.CallRemote('inventory:GiveItem', data)
    Core.OpenInventory()
end

function UseItem(data, closeInv)
    Events.CallRemote('inventory:UseInventorySlot', data.slot, data.extra)
    
    if Core.InventoryOpened then
        Core.OpenInventory()
    end
    
    if closeInv then
        Core.CloseInventory()
    end
end

function SplitItem(slot, amount)
    Core.TriggerCallback('inventory:SplitItem', function(valid, inv, otherInventories)
        if valid then
            InventoryHUD.Call('inventory:OpenInventory', {
                inventoryData = inv,
                nearbyInventories = otherInventories
            })
        end
    end, slot, amount)
end

InventoryHUD.Subscribe('CloseInventory', Core.CloseInventory)
InventoryHUD.Subscribe('DropItem', RemoveItem)
-- InventoryHUD.Subscribe('UseItem', RemoveItem)
InventoryHUD.Subscribe('GiveItem', GiveItem)
InventoryHUD.Subscribe('UseItem', UseItem)
InventoryHUD.Subscribe('inventory:SplitItem', SplitItem)

Core.RegisterInput('I', function()
    if Core.InventoryOpened then
        Core.CloseInventory()
        return
    end
    
    Core.OpenInventory(true)
end)

-- Glovebox
Core.RegisterInput('G', function()
    if not Core.IsPlayerInAnyVehicle() then return end
    if Core.InventoryOpened then
        Core.CloseInventory()
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