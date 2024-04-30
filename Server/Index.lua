Package.Require('/Server/Utils.lua')
Package.Require('/Server/Functions.lua')

Package.Require('/Server/modules/Database.lua')

Package.Require('/Server/classes/C_Inventory.lua')
Package.Require('/Server/classes/C_Status.lua')
Package.Require('/Server/classes/C_Player.lua')
Package.Require('/Server/classes/C_Vehicle.lua')
-- Package.Require('/Server/classes/C_GasPump.lua')

Package.Require('/Server/modules/Camera.lua')
Package.Require('/Server/modules/Multichar.lua')
Package.Require('/Server/modules/Vehicles.lua')
Package.Require('/Server/modules/JobLevels.lua')
Package.Require('/Server/modules/Inventory.lua')
-- Package.Require('/Server/modules/Jobs.lua')
Package.Require('/Server/modules/Notifications.lua')
Package.Require('/Server/modules/DailyRewards.lua')
Package.Require('/Server/modules/Commands.lua')
Package.Require('/Server/modules/SpawnMenu.lua')
Package.Require('/Server/modules/VehicleHUD.lua')
-- Package.Require('/Server/modules/SkillTree.lua')
Package.Require('/Server/Caching.lua')

-- Package.Require('/Server/modules/jobs/TaxiJob.lua')

Core.RegisterSavedVariable('isCuffed', 'users', nil, false)

Events.SubscribeRemote('pcrp-core:PlayAnimation', function(player, anim, slot_flag, loop, blend_in_time, blend_out_time, play_rate, stop_all_montages)
	local id = player:GetID()
    local xPlayer = Core.GetPlayerFromId(id)
    local character = xPlayer.character

	character:PlayAnimation(anim, slot_flag, loop, blend_in_time, blend_out_time, play_rate, stop_all_montages)
    xPlayer.set('currentAnim', anim)
end)

Events.SubscribeRemote('pcrp-core:StopAnimation', function(player, anim)
    local id = player:GetID()
    local xPlayer = Core.GetPlayerFromId(id)
    local character = xPlayer.character
    
    if not anim then
        anim = xPlayer.get('currentAnim')
        xPlayer.set('currentAnim', nil)
    end
    
    character:StopAnimation(anim)
end)

function OnPlayerSpawn(player)
	local plyId = player:GetID()

	if Core.Players[plyId] then return end
	
	local plyIdentifier = player:GetAccountID()
	local plyName = player:GetName()
	
	local plyStats = CoreCFG.DefaultStats
	local plyAccounts = CoreCFG.DefaultAccounts
	local plyXP = CoreCFG.DefaultXP
	local plyJob = CoreCFG.DefaultJob
	local plySkin = CoreCFG.DefaultSkin

	-- TODO:	OPTIMISE USING STORED QUERIES
	--			ADD SUPPORT FOR ADDITONAL DATA TYPES
	local plyVars = {}
--[[ 	for k, v in pairs(Core.SavedVariables) do
		local result = DB:Select(("SELECT %s FROM %s"):format(v.column, v.table))
		if result[1] and result[1][v.column] then
			local x = result[1][v.column]
			-- If default is a boolean then convert the db value to boolean
			if type(v.default) == 'boolean' then
				x = x == 1 and true or false
			end

			-- If default is a table then convert the db value to table
			if type(v.default) == 'table' then
				x = x and JSON.parse(x) or {}
			end

			plyVars[k] = x
		else
			plyVars[k] = v.default
		end
	end ]]

	local xPlayer = CreatePlayerData(player, plyId, plyIdentifier, plyName, plyAccounts, plyStats, plyXP, plyJob, plySkin, plyVars)
	Core.Players[plyId] = xPlayer;

	local markerTbl = {}

	for k, v in pairs(Core.Markers) do
		markerTbl[k] = { marker = v.marker }
	end

	xPlayer.call('InitialiseMarkers', markerTbl)


	xPlayer.updateData()
end

function OnPlayerReady(player)
	local new_char = HELIXCharacter(Vector(0, 0, 500), Rotator(0, 0, 0), player)
	
	new_char:SetCapsuleSize(20, 90)

	if CoreCFG.MulticharEnabled then
		Events.Call('core-multicharacter:PlayerReady', player, new_char)
		return
	end

	-- Sets play to control new character
	player:Possess(new_char)
	-- Subscribe to Death event
	new_char:Subscribe("Death", OnPlayerCharacterDeath)

	-- Unsubscribe to Death event if unpossessed (in case we got possessed into another Character)
	new_char:Subscribe("UnPossess", function(self)
		self:Unsubscribe("Death", OnPlayerCharacterDeath)
	end)	

	Events.CallRemote('core:playerSpawned', player, Core.Players[player:GetID()].serialisedVersion)
	Events.Call('core:playerSpawned', player)
	Events.BroadcastRemote('core:playerJoinedServer', player)
end

function CreatePlayer(identifier, name, accounts, stats)
	-- Construct multi-statement INSERT query
	local multiInsertQuery = string.format([[
		BEGIN;
		INSERT INTO users (identifier, name) VALUES ('%s', '%s');
	]], identifier, name)

	-- Add accounts inserts
	for k, v in pairs(accounts) do
		multiInsertQuery = multiInsertQuery .. string.format("INSERT INTO user_accounts (identifier, type, amount) VALUES ('%s', '%s', '%s');", identifier, k, v)
	end

	-- Add stats inserts
	for k, v in pairs(stats) do
		multiInsertQuery = multiInsertQuery .. string.format("INSERT INTO user_stats (identifier, type, amount) VALUES ('%s', '%s', '%s');", identifier, k, v)
	end

	-- End the multi-statement query
	multiInsertQuery = multiInsertQuery .. "COMMIT;"

	-- Execute the multi-statement query using DB:Execute
	print(multiInsertQuery)
	DB:Execute(multiInsertQuery)
end

function OnPlayerCharacterDeath(character, last_damage_taken, last_bone_damaged, damage_reason, hit_from, instigator)
	local player = character:GetPlayer()
	if not player then return end
	
	local xPlayer = Core.GetPlayerFromId(player:GetID())
	if not xPlayer then return end
	
	xPlayer.call("core:onPlayerDeath")
	xPlayer.set("isDead", true)
end

function OnPlayerLeave(player)
	-- Player left
	local plyId = player:GetID()
	local ply = Core.Players[plyId]

	if ply then
		-- Save info to database
		ply.save()
	end

	Events.Call('core:playerLeftServer', ply, player)	

	Timer.SetTimeout(function()	
		if character then
			character:Destroy()
		end
	
		Core.Players[plyId] = nil
	end, 500)
end

function OnPlayerRespawn(player)
	local xPlayer = Core.GetPlayerFromId(player:GetID())

	if not xPlayer then return end

    xPlayer.revive()
	xPlayer.showNotification("You have been revived", 'info', 2000)
end

function OnPlayerPossess(player, character)
	local plyId = player:GetID()
	local xPlayer = Core.Players[plyId]
	
	if not xPlayer then return end;

	xPlayer.setCharacter(character);		
end

function OnPlayerUnpossess(player, character)
	local plyId = player:GetID()
	local xPlayer = Core.Players[plyId]
	
	if not xPlayer then return end;

	xPlayer.character:Destroy()		
	xPlayer.setCharacter(nil);
end

Events.Subscribe("RespawnPlayer", OnPlayerRespawn)

Player.Subscribe("Ready", OnPlayerReady)
Player.Subscribe("Spawn", OnPlayerSpawn)
Player.Subscribe('Destroy', OnPlayerLeave)
Player.Subscribe("Possess", OnPlayerPossess)
Player.Subscribe("Unpossess", OnPlayerUnpossess)

PlayerStatusTimer = Timer.SetInterval(function()
	if Core.Players then
		for k, v in pairs(Core.Players) do
			if HELIXUtils.IsEntityValid(v.player) then
				local hunger = v.getStat('hunger')
				local thirst = v.getStat('thirst')
				
				hunger.RemoveValue(1)
				thirst.RemoveValue(1)
				
				v.call("core:onStatusTick", { hunger.Serialise(), thirst.Serialise() })
			else
				Core.Players[k] = nil
			end
		end
	end
end, 5000)

PlayerSaveTimer = Timer.SetInterval(function()
	-- Save players every 15 minutes
	for k, v in pairs(Core.Players) do
		if HELIXUtils.IsEntityValid(v.player) then
			v.save()
		else
			Core.Players[k] = nil
		end
	end
end, 60000 * 15)

Package.Subscribe("Load", function()
    for _, character in pairs(HELIXCharacter.GetPairs()) do
        local player = character:GetPlayer()
        
		if player then 
            
			character:Destroy()
            OnPlayerSpawn(player)
            OnPlayerReady(player)

            Events.CallRemote("pcrp-core:HideHUD", player)
        end
    end
end)