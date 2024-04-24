Package.Require("SelfHealing.lua")

Events.SubscribeRemote("pcrp-ambulancejob::server::HealMinorInjuries", function(player, closestPlayer)
	local xPlayer = Core.GetPlayerFromId(player:GetID())

	if xPlayer == nil then
		print((NOTIFICATIONS["something_went_wrong_console"]):format("EMS-MIN - PLAYER NOT VALID"))
		return
	end

	local itemData = xPlayer.inventory.GetItem(Config.MinorHealItem)

	if (itemData == nil or (itemData ~= nil and itemData.count <= 0)) then
		xPlayer.showNotification(NOTIFICATIONS["need_bandage"])
		return
	end

	local xPlayerTarget = Core.GetPlayerFromId(closestPlayer:GetID())

	-- TODO: ADD ACTION AND PROGRESS BAR HERE
	xPlayer.character:PlayAnimation('ambulancejob-animations::SK_Bandage', false, 'UpperBody')
	xPlayer.character:SetInputEnabled(false)
	xPlayerTarget.character:PlayAnimation('ambulancejob-animations::SK_BeingBandaged', false, 'UpperBody')
	xPlayerTarget.character:SetInputEnabled(false)
	Timer.SetTimeout(function ()
		xPlayer.character:SetInputEnabled(true)
		xPlayerTarget.character:SetInputEnabled(true)

		xPlayer.inventory.RemoveItem(Config.MinorHealItem, 1)
		xPlayer.showNotification(NOTIFICATIONS["minor_injuries_treated_doctor"])
		
		HealMinorInjuries(xPlayerTarget)
		xPlayerTarget.showNotification(NOTIFICATIONS["minor_injuries_treated_target"])
	end, 3000)
end)

Events.SubscribeRemote("pcrp-ambulancejob::server::HealMajorInjuries", function(player, closestPlayer)
	local xPlayer = Core.GetPlayerFromId(player:GetID())

	if xPlayer == nil then
		print((NOTIFICATIONS["something_went_wrong_console"]):format("EMS-MAJ - PLAYER NOT VALID"))
		return
	end

	local itemData = xPlayer.inventory.GetItem(Config.MajorHealItem)

	if (itemData == nil or (itemData ~= nil and itemData.count <= 0)) then
		xPlayer.showNotification(NOTIFICATIONS["need_medical_kit"])
		return
	end


	local xPlayerTarget = Core.GetPlayerFromId(closestPlayer:GetID())
	
	-- TODO: ADD ACTION AND PROGRESS BAR HERE
	xPlayer.character:PlayAnimation('ambulancejob-animations::SK_Bandage', false, 'UpperBody')
	xPlayer.character:SetInputEnabled(false)
	xPlayerTarget.character:PlayAnimation('ambulancejob-animations::SK_BeingBandaged', false, 'UpperBody')
	xPlayerTarget.character:SetInputEnabled(false)
	Timer.SetTimeout(function ()
		xPlayer.character:SetInputEnabled(true)
		xPlayerTarget.character:SetInputEnabled(true)

		xPlayer.inventory.RemoveItem(Config.MajorHealItem, 1)
		xPlayer.showNotification(NOTIFICATIONS["major_injuries_treated_doctor"])
		
		HealMajorInjuries(xPlayerTarget)
		xPlayerTarget.showNotification(NOTIFICATIONS["major_injuries_treated_target"])
	end, 3000)
end)

Events.SubscribeRemote("pcrp-ambulancejob::server::Resuscitate", function(player, closestPlayer)
	local xPlayer = Core.GetPlayerFromId(player:GetID())

	if xPlayer == nil then
		print((NOTIFICATIONS["something_went_wrong_console"]):format("EMS-R - PLAYER NOT VALID"))
		return
	end

	local itemData = xPlayer.inventory.GetItem(Config.ReviveItem)

	if (itemData == nil or (itemData ~= nil and itemData.count <= 0)) then
		xPlayer.showNotification(NOTIFICATIONS["need_defibrillator"])
		return
	end

	local xPlayerTarget = Core.GetPlayerFromId(closestPlayer:GetID())
	local isTargetDead = xPlayerTarget.get("isDead")

	if not isTargetDead then
		xPlayer.showNotification(NOTIFICATIONS["target_not_dead"])
		return
	end

	-- TODO: ADD ACTION AND PROGRESS BAR HERE
	xPlayer.character:PlayAnimation('ambulancejob-animations::SK_Rescusitate', false, 'FullBody')
	xPlayer.character:SetInputEnabled(false)
	Timer.SetTimeout(function ()
		xPlayer.character:SetInputEnabled(true)

		xPlayer.inventory.RemoveItem(Config.ReviveItem, 1)
		xPlayer.showNotification(NOTIFICATIONS["resuscitated_doctor"])

		xPlayerTarget.revive()
		xPlayerTarget.showNotification(NOTIFICATIONS["resuscitated_target"])
	end, 2500)
end)

Events.Subscribe("OnJobUpdate", function(player, newJob)
	local id = player:GetID()
	local xPlayer = Core.GetPlayerFromId(id)

	if (xPlayer.job.name == "ambulance") then
		Events.CallRemote("pcrp-ambulancejob::client::AddActionMenuOptions", player)
	else
		Events.CallRemote("pcrp-ambulancejob::client::RemoveActionMenuOptions", player)
	end
end)
