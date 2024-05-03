-- [[
-- 	types:
-- 	- string
-- 	- number
-- 	- player
-- 	- item
-- ]]
-- TODO: ADD OPTIONAL ARGS
function Core.CreateCommand(command, data, onUse)
	-- if Core.Commands[command] then return end
	-- if not arguments then return end

	Core.Commands[command] = { fnc = onUse, arguments = data.params, help = data.help }
end

function CommandValidation(source, command, arguments)
	if not arguments or #arguments == 0 then return {} end
	
	if not Core.Commands[command] then
		return
	end

	local expectedArgs = Core.Commands[command].arguments
	local argumentKeys = {}

	if expectedArgs then
		for k, v in ipairs(expectedArgs) do
			if arguments[k] then
				if v.type == 'number' then
					arguments[k] = tonumber(arguments[k])
	
					if not arguments[k] and not v.optional then
						return false
					end
				elseif v.type == 'string' then
					if not arguments[k] or #arguments[k] <= 0 and not v.optional then
						return false
					end
				elseif v.type == 'playerId' then
					local pID = tonumber(arguments[k])
	
					if not arguments[k] and not v.optional then
						return false
					end
	
					if (arguments[k]):lower() == 'me' then
						pID = source
					end
	
					local xTarget = Core.GetPlayerFromId(pID)
	
					if not xTarget then
						return false
					end
	
					arguments[k] = xTarget
				elseif v.type == 'item' then
					local itemName = arguments[k]
	
					if not Core.Items[itemName] and not v.optional then
						return false
					end
	
					arguments[k] = Core.Items[itemName]
				end
	
				argumentKeys[v.name] = arguments[k]
			elseif not v.optional then
				return false
			end
		end
	end

	return argumentKeys
end

-- Core.CreateCommand('blur', function(xPlayer, args)
-- 	xPlayer.call("Client:BlurScreen", args.blur == 1)
-- end, {
-- 	{ name = 'blur', type = 'number' }
-- })

-- Core.CreateCommand('cuffed', function(xPlayer, args)
-- 	xPlayer.set('isCuffed', args.cuffed == 1)
-- end, {
-- 	{ name = 'cuffed', type = 'number' }
-- })

-- Core.CreateCommand("addItem", function(xPlayer, args)
-- 	-- print('add Item', player, args)
-- 	-- local xPlayer = Core.GetPlayerFromId(player:GetID())

-- 	-- if not xPlayer then return end

-- 	local item = args.item
-- 	local count = args.count or 1
-- 	local slot = args.slot


-- 	-- print(item, count, slot)

-- 	-- local metadata = { id = math.random() }


-- 	-- print(NanosUtils.Dump(xPlayer.inventory))
	
-- 	xPlayer.inventory.AddItem(item, count, slot, metadata)
	
-- 	print(NanosUtils.Dump(xPlayer.inventory))
-- end, {
-- 	{ name = 'item', type = 'string' },
-- 	{ name = 'count', type = 'number' },
-- 	{ name = 'slot', type = 'number' } 
-- })

-- Core.CreateCommand("TestMarker", function(xPlayer)
-- 	print(xPlayer.player:GetValue('CurrentMarker'))
-- end)

-- Core.CreateCommand("taxi", function(xPlayer)
-- 	xPlayer.setJob('taxi')
-- end)

-- local showingSpawn = false

-- Core.CreateCommand("spawnm", function (xPlayer)
-- 	if showingSpawn == false then
-- 		Events.CallRemote("pcrp-core:SpawnMenu", xPlayer.player, true)
-- 		showingSpawn = true
-- 	else
-- 		Events.CallRemote("pcrp-core:SpawnMenu", xPlayer.player, false)

-- 		showingSpawn = false
-- 	end
-- end)

-- Core.CreateCommand('setVehicleFuel', function(xPlayer, args)
-- 	local character = xPlayer.player:GetControlledCharacter()

-- 	Core.SetVehicleFuel(character:GetVehicle(), args.fuel)
-- end, {
-- 	{ name = 'fuel', type = 'number' }
-- })

-- Core.CreateCommand('addcash', function(xPlayer, args)
-- 	xPlayer.addMoney(args.amount)
-- end, {
-- 	{ name = 'amount', type = 'number' }
-- })

-- Core.CreateCommand('addbank', function(xPlayer, args)
-- 	xPlayer.addBankMoney(args.amount)
-- end, {
-- 	{ name = 'amount', type = 'number' }
-- })

-- Core.CreateCommand('coords', function(xPlayer, args)

-- 	local character = xPlayer.player:GetControlledCharacter()

-- 	print(character:GetLocation())
-- 	print(character:GetRotation())
-- end, {
-- })

-- Core.CreateCommand("addXP", function(xPlayer, args)
-- 	print("RANK: ", xPlayer.getRank())
-- 	print("XP: ", xPlayer.getXP())

-- 	xPlayer.addXP(args.xp)

-- 	print("RANK: ", xPlayer.getRank())
-- 	print("XP: ", xPlayer.getXP())
-- end, {
-- 	{ name = 'xp', type = 'number' }
-- })

-- Core.CreateCommand('spawnVehicle', function(xPlayer, args)
-- 	local player = xPlayer.player
-- 	local coords = xPlayer.character:GetLocation()
-- 	local rotation = xPlayer.character:GetControlRotation()

-- 	coords = coords + Vector(0, 0, 10)
-- 	local veh = Core.CreateVehicle(args.model, coords, rotation)

-- 	xPlayer.character:EnterVehicle(veh, 0)
-- end, {
-- 	{ name = 'model', type = 'string' }
-- })

-- Core.CreateCommand('dv', function(xPlayer, args)
-- 	local player = xPlayer.player
-- 	local char = xPlayer.character

-- 	-- print(char, char:GetVehicle())

-- 	local vehicleData = Core.GetVehicleData(char:GetVehicle())

	
-- 	char:GetVehicle():Destroy()
-- 	-- vehicleData.RemoveVehicle()
-- end)

-- Core.CreateCommand("removeXP", function(xPlayer, args)
-- 	print("RANK: ", xPlayer.getRank())
-- 	print("XP: ", xPlayer.getXP())


-- 	xPlayer.removeXP(args.xp)

-- 	print("RANK: ", xPlayer.getRank())
-- 	print("XP: ", xPlayer.getXP())
-- end, {
-- 	{ name = 'xp', type = 'number' }
-- })

-- Core.CreateCommand("setName", function(xPlayer, args)
-- 	xPlayer.setName(args.name)	
-- end, {
-- 	{ name = 'name', type = 'string' }
-- })

-- Core.CreateCommand("useItem", function(xPlayer, args)
	
-- 	local item = args.item
--     print(item)
	
-- 	local _, slot = xPlayer.inventory.GetItem(item)
--     print(item, slot)


--     Core.UseItem(xPlayer, item, slot)
-- end, {
-- 	{ name = 'item', type = 'string' }
-- })

-- Core.CreateCommand("setName", function(xPlayer, args)
-- 	xPlayer.setName(args.name)	
-- end, {
-- 	{ name = 'name', type = 'string' }
-- })



-- Core.CreateCommand("revive", function(xPlayer, args)
-- 	xPlayer.revive()
-- end, {
-- 	{ name = 'id', type = 'number' }
-- })

-- Core.CreateCommand("kill", function(xPlayer, args)
-- 	xPlayer.slay()
-- end, {
-- 	{ name = 'id', type = 'number' }
-- })


-- Core.CreateCommand("swapItem", function(xPlayer, args)
-- 	print('add Item', player, args)
	
-- 	local item = args.item
-- 	local slot = args.slot
-- 	local metadata = {}

-- 	local itemA = xPlayer.inventory.GetItem('test', 1, { id = 1 })
-- 	local itemB = xPlayer.inventory.GetItem('test', 2, { id = 2 })
-- 	xPlayer.inventory.SwapItems(itemA, itemB)
	
-- 	print('items ===== items')
-- 	print(NanosUtils.Dump(itemA))
-- 	print(NanosUtils.Dump(itemB))
-- end, {
-- 	{ name = 'item', type = 'string' },
-- 	{ name = 'slot', type = 'number' } 
-- })

Core.CreateCommand('giveitem', {
    help = 'Gives an item to a player',
    params = {
        {
            name = 'target',
            type = 'playerId',
            help = 'Target player\'s server id',
        },
        {
            name = 'item',
            type = 'string',
            help = 'Name of the item to give',
        },
        {
            name = 'count',
            type = 'number',
            help = 'Amount of the item to give, or blank to give 1',
            optional = true,
        },
        {
            name = 'metadata',
            help = 'Sets the item\'s "metadata.type"',
            optional = true,
        },
    }
}, function(xPlayer, args, raw)
	print(HELIXTable.Dump(Core.Items))
	args.target.inventory.AddItem(args.item, args.count, args.metadata)
	-- print(args.target.source, args.count, args.item, args.metadata)
	-- print(HELIXTable.Dump(args))
end)


-- Core.CreateCommand("getItem", function(xPlayer, args)
-- 	if not xPlayer then return end

-- 	local item = args.item
-- 	-- local count = tonumber(args[2]) or 1
-- 	-- local slot = tonumber(args[3])
-- 	local metadata = {}


-- 	print(NanosUtils.Dump(xPlayer.inventory.GetItem(item, nil, metadata)))

-- 	-- print(NanosUtils.Dump(xPlayer.inventory))
	
-- 	-- xPlayer.inventory.AddItem(item, count, slot, metadata)
	
-- 	-- print(NanosUtils.Dump(xPlayer.inventory))
-- end, {
-- 	{ name = 'item', type = 'string' },
-- 	-- { name = 'slot', type = 'number' } 
-- })

-- Core.CreateCommand('giveitem', {
--     help = 'Gives an item to a player',
--     params = {
--         {
--             name = 'target',
--             type = 'playerId',
--             help = 'Target player\'s server id',
--         },
--         {
--             name = 'item',
--             type = 'string',
--             help = 'Name of the item to give',
--         },
--         {
--             name = 'count',
--             type = 'number',
--             help = 'Amount of the item to give, or blank to give 1',
--             optional = true,
--         },
--         {
--             name = 'metatype',
--             help = 'Sets the item\'s "metadata.type"',
--             optional = true,
--         },
--     },
--     restricted = 'group.admin'
-- }, function(source, args, raw)
--     local item = Items(args.item)
 
--     if item then
--         Inventory.AddItem(args.target, item.name, args.count or 1, args.metatype)
--     end
-- end)


Chat.Subscribe("PlayerSubmit", function(text, player)
	if not (text):sub(1, 1) == '/' then
		return
	end
	
	local xPlayer = Core.GetPlayerFromId(player:GetID())
	local command = (text):gsub('/', '')
	local arguments = {}
	
	for word in command:gmatch("%w+") do table.insert(arguments, word) end

	command = arguments[1]
	table.remove(arguments, 1)
	
	if not Core.Commands[command] then
		return
	end
	
	if #arguments > 0 then
		arguments = CommandValidation(xPlayer.source, command, arguments)
		if not arguments then
			return false
		end
	end
	
	Core.Commands[command].fnc(xPlayer, arguments, command)
end)