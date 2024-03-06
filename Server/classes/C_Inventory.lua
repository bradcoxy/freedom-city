Core.Inventories = {}
Core.InventoryDrops = {}

local remove    = table.remove
local insert    = table.insert
local time      = os.time
local abs       = math.abs
local floor     = math.floor

-- Creates a proxy, this essentially makes the table obvserved and every index is serialised
local function CreateProxy(t, a, b)
    return setmetatable({}, {
        __index = function(_, key)
            return a[key]
        end,
        __newindex = function(_, k, v)
            a[k] = v
            if not t[b] then t[b] = {} end
            t[b][k] = v
        end
    })
end

function Core.CreateInventory(name, _type, level, weight, label)
    name = name .. ''
    Core.Inventories[name] = InventoryInitialise(name, _type, level, weight, label)
    print("INVENTROY CREATED =>", name)
    return Core.Inventories[name]
end

function Core.GetInventory(name)
    return Core.Inventories[name]
end

function Core.DestroyInventory(name)
    Core.Inventories[name] = nil
end

function InventoryInitialise(name, _type, level, weight, label, coords)
    local self = {}
    
    self.pockets = {}
    self.equipment = {}
    self.clothing = {}
    self.slots = {}
    self.itemRegistry = {}

    self.id = name;
    self.type = _type;

    self.label = label;
    self.slotsActive = 0;
    self.weight = {0, weight or 0}


    if (_type == 'drop') then
        self.pockets = nil
        self.equipment = nil
        self.clothing = nil
        self.label = 'Drop'
        self.weight[2] = 150000
    end

    function self.UpdateHolder(xPlayer)
        self.holder = xPlayer
    end

    function self.Update(data)
        local _data = data.data;
        local slots = _data.slots;
        local weight = _data.weight;
        
        for k, v in pairs(slots) do
            self.AddItem(v.name, v.count, tonumber(k), v.metadata)
        end

        self.weight = weight;
    end

    function self.AddItem(item, count, metadata, slot, extra)
        slot = tonumber(slot)

        if not extra then
            extra = 'slots'
        end
        if extra == 'default' then
            extra = 'slots'
        end

        local itemData = Core.Items[item]
        
        if not itemData then
            return print("Item does not exist")
        end

        if metadata and type(metadata) ~= 'table' then
            metadata = nil
        end

        if not self.itemRegistry[item] then
            self.itemRegistry[item] = {}
        end

        if itemData.unique then
            slot, extra = self.FindEmptySlot()
            insert(self.itemRegistry[item], { slot = slot, type = extra })

            self[extra][slot] = { name = item, type = itemData.type, count = count, slot = slot, metadata = metadata, label = itemData.label, description = itemData.description, weight = itemData.weight, unique = itemData.unique, rarity = itemData.rarity or 'Common' }

            if self.holder then
                print('calling item added')
                self.holder.call("inventory:ItemAdded", item, slot, metadata, count)
            end

            if item == 'money' and self.holder then
                self.holder.addMoney(count, true)
            end

            self.weight[1] = self.weight[1] + (itemData.weight * count)

            return
        end

        if not slot and metadata then
            local ret = self.FindItemByMetadata(item, metadata)
            if ret then
                slot = ret.slot
                if not extra then
                    extra = ret.type
                end
            end
        end
        
        if not slot then
            slot, extra = self.FindEmptySlot()
        end

        if not self.FindItemInRegistry(item, slot, extra) then
            insert(self.itemRegistry[item], {slot = slot, type = extra})
            
            self[extra][slot] = { name = item, type = itemData.type, count = count, slot = slot, metadata = metadata, label = itemData.label, description = itemData.description, weight = itemData.weight, unique = itemData.unique, rarity = itemData.rarity or 'Common' }
            self.weight[1] = self.weight[1] + (itemData.weight * count)
        else
            self[extra][slot].count = self[extra][slot].count + count
            self.weight[1] = self.weight[1] + (itemData.weight * count)
        end

        if self.holder then
            -- if item == 'money' then
            --     self.holder.addMoney(count, true)
            -- end
            self.holder.call("inventory:ItemAdded", item, itemData.label, count)
        end

    end

    function self.RemoveItem(item, count, metadata, slot, extra)
        slot = tonumber(slot)

        if not extra then
            extra = 'slots'
        end
        if extra == 'default' then
            extra = 'slots'
        end

        local itemData = Core.Items[item]
        if not itemData then
            return print("Item does not exist")
        end

        if not self.itemRegistry[item] or #self.itemRegistry[item] == 0 then
            return print("Item not in inv")
        end

        if metadata and type(metadata) ~= 'table' then
            metadata = nil
        end

        if not slot and metadata then
            local ret = self.FindItemByMetadata(item, metadata)
            if ret then
                slot = ret.slot
                if not extra then
                    extra = ret.type
                end
            end
        end

        local registryIdx = nil
        if not slot then
            slot, registryIdx = self.FindItemInRegistry(item)
            if not extra then
                extra = slot.type
            end
            slot = slot.slot
        end


        self[extra][slot].count = self[extra][slot].count - count
        self.weight[1] = self.weight[1] - itemData.weight * count

        if self[extra][slot].count <= 0 then
            self[extra][slot] = nil
            remove(self.itemRegistry[item], registryIdx)
        end

        if self.holder then
            -- if item == 'money' then
            --     self.holder.removeMoney(count, true)
            -- end
            self.holder.call("inventory:ItemRemoved", item, itemData.label, count)
        end
    end

    function self.GetSlot(slot, invType)
        if not invType then
            invType = 'slots'
        end
        
        if invType == 'default' then
            invType = 'slots'
        end

        return self[invType][slot]
    end

    function self.GetItem(item, slot, metadata)
        if not Core.Items[item] then
            return print("Item does not exist")
        end

        if not self.itemRegistry[item] or #self.itemRegistry[item] == 0 then
            print('item not in reg')
            return
        end

        if slot and self.slots[slot].name == item then
            return self.slots[slot], slot
        end

        if metadata then
            local ret = self.FindItemByMetadata(item, metadata)
            if ret then
                return self[ret.type][ret.slot], ret
            end
        end
        
        for k, v in ipairs(self.itemRegistry[item]) do
            print('looping')
            return self.slots[v], v
        end
    end

    function self.FindItemByMetadata(item, metadata)
        print('SEARCHING FOR METADATA =>', HELIXTable.Dump(metadata))
        if not Core.Items[item] then
            return print("Item does not exist")
        end
        
        if not self.itemRegistry[item] then
            return nil
        end

        for k, v in ipairs(self.itemRegistry[item]) do
            if v.slot and v.type and table.compare(metadata, self[v.type][v.slot].metadata) then
                return v
            end
        end
    end

    function self.FindItemInRegistry(item, slot, inv)
        if not self.itemRegistry[item] then return end

        if not slot then
            return self.itemRegistry[item][1], 1
        end

        for k, v in ipairs(self.itemRegistry[item]) do
            if v.slot == slot and invType == inv then
                return v, k
            end
        end
    end

    function self.FindEmptySlot()
        if self.pockets and not pocketsFull then
            for i=1, 6 do
                if not self.pockets[i] then
                    return i, "pockets"
                end
            end
        end

        for i=1, 60 do
            if not self.slots[i] then
                return i, "slots"
            end
        end
    end

    function self.SwapSlots(slotA, slotB)
        local fromSlot = slotA.slot
        local toSlot = slotB.slot
        local fromSlotExtra = slotA.extra
        local toSlotExtra = slotB.extra

        if (toSlotExtra == 'default') then
            toSlotExtra = 'slots'
        end
        if (fromSlotExtra == 'default') then
            fromSlotExtra = 'slots'
        end

        if not self[toSlotExtra][toSlot] then return self.MoveSlot(slotA, slotB) end
        if not self[fromSlotExtra][fromSlot] then return self.MoveSlot(slotB, slotA) end

        local slotCp = self[fromSlotExtra][fromSlot]

        for k, v in ipairs(self.itemRegistry[self[fromSlotExtra][fromSlot].name]) do
            if v.slot == fromSlot then
                self.itemRegistry[self[fromSlotExtra][fromSlot].name][k].slot = toSlot
                self.itemRegistry[self[fromSlotExtra][fromSlot].name][k].type = toSlotExtra
                break
            end
        end
        
        for k, v in ipairs(self.itemRegistry[self[toSlotExtra][toSlot].name]) do
            if v.slot == toSlot then
                self.itemRegistry[self[toSlotExtra][toSlot].name][k].slot = fromSlot
                self.itemRegistry[self[toSlotExtra][toSlot].name][k].type = fromSlotExtra
                break
            end
        end
        
        -- Update slot numbers
        slotCp.slot = toSlot
        self[toSlotExtra][toSlot].slot = fromSlot

        -- Swap data
        self[fromSlotExtra][fromSlot] = self[toSlotExtra][toSlot]
        self[toSlotExtra][toSlot] = slotCp

    end

    function self.MoveSlot(slot, destSlot)        
        local fromSlot = slot.slot
        local toSlot = destSlot.slot
        local fromSlotExtra = slot.extra
        local toSlotExtra = destSlot.extra

        if (toSlotExtra == 'default') then
            toSlotExtra = 'slots'
        end
        if (fromSlotExtra == 'default') then
            fromSlotExtra = 'slots'
        end

        if not self[fromSlotExtra][fromSlot] then return print('no item in slot') end
        if self[toSlotExtra][toSlot] then return self.SwapSlots(destSlot, slot) end

        local slotCp = self[fromSlotExtra][fromSlot]

        slotCp.slot = toSlot;
        slotCp.inventoryType = toSlotExtra;

        for k, v in ipairs(self.itemRegistry[self[fromSlotExtra][fromSlot].name]) do
            if v.slot == fromSlot then
                self.itemRegistry[self[fromSlotExtra][fromSlot].name][k].slot = toSlotNumber
                self.itemRegistry[self[fromSlotExtra][fromSlot].name][k].type = toSlotExtra
                break
            end
        end
        
        self[fromSlotExtra][fromSlot] = nil
        self[toSlotExtra][toSlot] = slotCp
    end

    function self.SwapItems(itemA, itemB)
        if not itemA.slot or not itemB.slot then
            return print('items are invalid')
        end

        -- Copy items
        local itemCp = itemA
        local itemBslot = itemB.slot

        -- Swap Items and then update their slots
        itemA = itemB
        itemA.slot = itemCp.slot
        itemB = itemCp
        itemB.slot = itemBslot

        local _, itemAregIdx = self.FindItemInRegistry(itemA.name, itemA.slot)
        local _, itemBregIdx = self.FindItemInRegistry(itemB.name, itemB.slot)

        -- Update slot table
        self.slots[itemBslot] = itemA
        self.slots[itemCp.slot] = itemB

        -- Update item Registry
        self.itemRegistry[itemA.name] = itemBslot
        self.itemRegistry[itemB.name] = itemCp.slot

    end

    function self.SetInventoryLevel(level)
        if not CoreCFG.InventoryLevels[level] then return end
        -- self.inventoryLevel = level
    end

    function self.Save()
        -- local x = self
        
        local id = self.id;
        -- local slotAmount = self.slotAmount;
        
        if self.type == 'player' then
            id = self.holder.charid    
            -- slotAmount = slotAmount - 11;
        end

        local save_data = JSON.stringify({ slots = self.slots })

        local res = DB:Execute(("INSERT IGNORE INTO `inventory_data` (name, type, data, weight) VALUES ('%s', '%s', '%s', '%s')"):format(id, self.type, save_data, JSON.stringify(self.weight)))
        
        if res == 0 then
            DB:Execute(("UPDATE `inventory_data` SET type = '%s', data = '%s', weight = '%s' WHERE name = '%s'"):format(self.type, save_data, JSON.stringify(self.weight), id))
        end
    end

    -- initialised = true

    return self
end

function table.compare(t1,t2,ignore_mt)
    local ty1 = type(t1)
    local ty2 = type(t2)

    if ty1 ~= ty2 then return false end
    -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    -- as well as tables which have the metamethod __eq
    local mt = getmetatable(t1)
    if not ignore_mt and mt and mt.__eq then return t1 == t2 end
    for k1,v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not table.compare(v1,v2) then return false end
    end
    for k2,v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not table.compare(v1,v2) then return false end
    end
    return true
end

Core.CreateCallback('inventory:ValidateMovement', function(player, cb, data)
    local xPlayer = Core.GetPlayerFromId(player:GetID())

    local fromSlot = data.fromSlot
    local toSlot = data.toSlot

    -- print("ATTEMPTING TO GRAB INV => ", fromSlot.id)
    local fromInventory = Core.GetInventory(fromSlot.id);
    -- print(fromInventory)
    -- local fromSlotNumber = tonumber(fromSlot.slot);
    
    -- if toInvType == 'outfit' then
    --     print(fromInventory, fromSlot, NanosUtils.Dump(fromInventory.GetSlot(fromSlot)))
    --     return
    -- end
    
    -- Equipment system WIP
    -- if toInvType == 'equipment' then
    --     local equipment = xPlayer.equipment
    --     local fromInvSlot = fromInventory.GetSlot(fromSlot)

    --     if equipment[fromInvSlot.name] == false then
    --         xPlayer.setEquipment(fromInvSlot.name, true)
    --     elseif equipment[fromInvSlot.name] ~= nil then
    --         xPlayer.setEquipment(fromInvSlot.name, false)
    --     end

    --     return cb(true, { inventory = fromInventory, equipment = xPlayer.equipment })
    -- end
    
    local toInventory = Core.GetInventory(toSlot.id);
    -- local toSlotNumber = tonumber(toSlot.slot);
    
    -- The slot is locked
    -- print("FROM INVENTORY SLOT DATA")
    -- print(fromSlot, fromInventory.slotAmount)
    -- if fromSlot > fromInventory.slotAmount then
    --     return cb(false, { inventory = fromInventory, equipment = xPlayer.equipment })
    -- end
    
    -- print("TO INVENTORY SLOT DATA")
    -- print(toSlot, toInventory.slotAmount)
    -- if toSlot > toInventory.slotAmount then
    --     return cb(false, { inventory = fromInventory, equipment = xPlayer.equipment })
    -- end
    print('!!inventory ids!! => ', fromSlot.id, toSlot.id)
    if (fromSlot.id == toSlot.id) then
        -- internal inventory swap. i.e swapping items around
        fromInventory.MoveSlot(fromSlot, toSlot);
        
        local invTarget = xPlayer.getInventoryTarget()
        local otherInvs = GetOtherInventories(xPlayer, { type = invTarget })

        return cb(true, xPlayer.inventory, otherInvs)
    end
    
    local fromInvSlot = fromInventory.GetSlot(fromSlot.slot, fromSlot.extra)
    local toInvSlot = toInventory.GetSlot(toSlot.slot, toSlot.extra)

    if not toInvSlot then
        local count = fromInvSlot.count
        local name = fromInvSlot.name
        local metadata = fromInvSlot.metadata
        
        fromInventory.RemoveItem(name, count, metadata, fromSlot.slot, fromSlot.extra)
        toInventory.AddItem(name, count, metadata, toSlot.slot, toSlot.extra)

        -- if fromInventory.type == 'drop' then
        --     -- TODO: OPTIMISE
        --     print("ACTIVE SLOTS =>", fromInventory.slotsActive)
        --     if fromInventory.slotsActive <= 1 then
        --         Core.InventoryDrops[fromInventory.id].marker:Destroy()
        --         Core.DestroyInventory(fromInventory.id)
        --         Core.InventoryDrops[fromInventory.id] = nil
        --     end
        -- end
    else
        -- Swap items from inventory
        local fromData = {
            name = fromInvSlot.name,
            count = fromInvSlot.count,
            slot = fromSlot.slot,
            extra = fromSlot.extra,
            metadata = fromInvSlot.metadata
        }

        local toData = {
            name = toInvSlot.name,
            count = toInvSlot.count,
            slot = toSlot.slot,
            extra = toSlot.extra,
            metadata = toInvSlot.metadata
        }
        
        fromInventory.RemoveItem(fromData.name, fromData.count, fromData.metadata, fromData.slot, fromData.extra)
        toInventory.RemoveItem(toData.name, toData.count, toData.metadata, toData.slot, toData.extra)
        
        toInventory.AddItem(fromData.name, fromData.count, fromData.metadata, fromData.slot, fromData.extra)
        fromInventory.AddItem(toData.name, toData.count, toData.metadata, toData.slot, toData.extra)
    end

    -- local otherInvs

    -- if toInventory.type ~= 'drop' and fromInventory.type ~= 'drop' then
    --     otherInvs = { type = {[toInventory.type] = true, [fromInventory.type] = true} }
    -- end
    
    otherInvs = GetOtherInventories(xPlayer, otherInvs)

    cb(true, xPlayer.inventory, otherInvs)
end)

function GetOtherInventories(xPlayer, other)
    if other ~= nil and other.type == nil then other = nil end
    local otherInventories = nil


    if other then
        otherInventories = {}

        if (type(other.type) == 'table' and other.type['glovebox']) or other.type == 'glovebox' then
            -- If player leaves vehicle
            if not xPlayer.insideVehicle then return nil end
            local vehData = Core.GetVehicleData(xPlayer.insideVehicle)
            if not Core.GetInventory(vehData.vin) then
                otherInventories[1] = Core.CreateInventory(vehData.vin, 'glovebox', 1, 100, 'Glovebox')
            else
                otherInventories[1] = Core.GetInventory(vehData.vin)
            end
        end
    else
        otherInventories = {}

        local coords = xPlayer.character:GetLocation()    

        for k, v in pairs(Core.InventoryDrops) do
            if v.coords:Distance(coords) <= 275 then
                insert(otherInventories, v.inventory)
            end
        end

        if #otherInventories == 0 then
            otherInventories = nil
        end
    end

    if otherInventories ~= nil and #otherInventories == 0 then
        otherInventories = nil
    end

    return otherInventories
end

Core.CreateCallback('inventory:GetInventory', function(player, cb, other)
    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local otherInventories = GetOtherInventories(xPlayer, other)

    -- print(HELIXTable.Dump(otherInventories))
    -- if otherInventories then
    --     xPlayer.setInventoryTarget((other and other.type) or nil)
    -- end

    print(HELIXTable.Dump(xPlayer.inventory))

    cb(xPlayer.inventory, otherInventories)
end)

Core.CreateCallback('inventory:SplitItem', function(player, cb, slot, amount)
    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local inventory = xPlayer.inventory
    
    slot = tonumber(slot)
    amount = tonumber(amount)
    
    if not inventory.slots[slot] then return cb(false) end
    if inventory.slots[slot].count < amount then return cb(false) end
    
    local name = inventory.slots[slot].name
    local metadata = inventory.slots[slot].metadata
    
    xPlayer.inventory.RemoveItem(name, amount, metadata, slot)
    xPlayer.inventory.AddItem(name, amount, metadata)

    local invTarget = xPlayer.getInventoryTarget()
    local otherInventories

    if invTarget then
        otherInventories = GetOtherInventories(xPlayer, { type = xPlayer.getInventoryTarget() })
    end
    
    cb(true, Core.GetInventory(xPlayer.source), otherInventories)
end)

Events.SubscribeRemote('inventory:UseInventorySlot', function(player, slot, extra)
    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local inventory = xPlayer.inventory

    slot = tonumber(slot)

    print(slot, extra)

    if not inventory[extra][slot] then return end

    Core.UseItem(xPlayer, inventory[extra][slot].name, slot, extra)
end)

Events.SubscribeRemote('inventory:DropItem', function(player, data)
    local itemSlot = data.item.slot
    local itemName = data.item.name
    local itemCount = data.item.count
    local itemExtra = data.inventory.extra

    local xPlayer = Core.GetPlayerFromId(player:GetID())

    xPlayer.inventory.RemoveItem(itemName, itemCount, nil, itemSlot, itemExtra)

    local coords = xPlayer.character:GetLocation()
    local nearestInventory = GetNearestInventory(coords)

    if nearestInventory then
        nearestInventory.inventory.AddItem(itemName, itemCount)
        return
    end

    local x = floor(abs(coords.X))
    local y = floor(abs(coords.Y))
    
    -- TODO: FIX ITEM AMOUNT DROP
    local identifier = ("%sx%s"):format(x, y)
    local newInventory = Core.CreateInventory(identifier, 'drop')
    
    newInventory.AddItem(itemName, itemCount)

    coords = Vector(coords.X, coords.Y, coords.Z - 100)
    Core.InventoryDrops[identifier] = {
        createdAt = time(),
        inventory = newInventory,
        coords = coords,
        marker = Core.CreateMarker( identifier, {
            coords = coords
        })
    }
end)

Events.SubscribeRemote('inventory:GiveItem', function(player, data)
    local itemSlot = data.item.slot
    local itemName = data.item.name
    local itemCount = data.item.count
    local itemExtra = data.inventory.extra

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local xTarget = Core.GetPlayerFromId(data.target)

    xPlayer.inventory.RemoveItem(itemName, itemCount, nil, itemSlot, itemExtra)
    xTarget.inventory.AddItem(itemName, itemCount)
end)

function GetNearestInventory(coords)
    for k, v in pairs(Core.InventoryDrops) do
        if v.coords:Distance(coords) <= 275 then
            return v
        end
    end
end