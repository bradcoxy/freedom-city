SELF_HEALING_SERVICES = {
	nextID = -1,
	services = {},
	servicesDoctorIDs = {},
	cost = Config.SelfHealingCost,
}

function SELF_HEALING_SERVICES:RegisterService(xPlayer)
	self.nextID = self.nextID + 1

	local serviceID = "SHS-" .. self.nextID
	local service = {
		id = serviceID,
		playerID = xPlayer.source,
		playerIdentifier = xPlayer.charid,
		location = xPlayer.character:GetLocation(),
		marker = nil,
	}

	self.servicesDoctorIDs[serviceID] = xPlayer.charid
	self.services[xPlayer.charid] = service

	self:MakeServiceActive(service)
end

function SELF_HEALING_SERVICES:DeleteService(xPlayer)
	local service = self.services[xPlayer.charid]

	if not service then
		return
	end

	self:MakeServiceInactive(service)
	self.servicesDoctorIDs[service.id] = nil
	self.services[xPlayer.charid] = nil
end

function SELF_HEALING_SERVICES:UseService(player, serviceID)
	local doctorID = self.servicesDoctorIDs[serviceID]
	local service = self.services[doctorID]

	if not service then
		return
	end

	local xPlayer = Core.GetPlayerFromId(player:GetID())
	local doctorxPlayer = Core.GetPlayerFromId(service.playerID)

	print(("%s is using %s services"):format(xPlayer.name, doctorxPlayer.name))

	if xPlayer.getMoney() >= self.cost then
		xPlayer.character:PlayAnimation('ambulancejob-animations::SK_BandageSelf', false, 'UpperBody')
		xPlayer.character:SetInputEnabled(false)
		Timer.SetTimeout(function ()
			xPlayer.character:SetInputEnabled(true)

			HealMajorInjuries(xPlayer)

			xPlayer.removeMoney(self.cost)
			doctorxPlayer.addMoney(self.cost)

			xPlayer.showNotification(NOTIFICATIONS["self_healing_target"])
			doctorxPlayer.showNotification(string.format(NOTIFICATIONS["self_healing_doctor"], self.cost))
		end, 3000)
	else
		xPlayer.showNotification(NOTIFICATIONS["not_enough_money"])
	end
end

function SELF_HEALING_SERVICES:MakeServiceActive(service)
	Events.BroadcastRemote("pcrp-ambulancejob::client::CreateSelfHealingService", service, service.playerIdentifier)
end

function SELF_HEALING_SERVICES:MakeServiceInactive(service)
	Events.BroadcastRemote("pcrp-ambulancejob::client::MakeServiceInactive", service.id)
end

function SELF_HEALING_SERVICES:SendServices(player)
	Events.CallRemote("pcrp-ambulancejob::client::ReceiveSelfHealingServices", player, self.services)
end


Player.Subscribe("Destroy", function(player)
	SELF_HEALING_SERVICES:DeleteService({
		identifier = player:GetAccountID()
	})
end)

Events.Subscribe("OnJobUpdate", function(player, newJob)
	local id = player:GetID()
	local xPlayer = Core.GetPlayerFromId(id)

	if (newJob.name == "ambulance") then
		return
	end

	SELF_HEALING_SERVICES:DeleteService(xPlayer)
end)

Events.SubscribeRemote("pcrp-ambulancejob::server::OfferSelfHealingServices", function(player)
	local xPlayer = Core.GetPlayerFromId(player:GetID())

	if xPlayer == nil then
		print((NOTIFICATIONS["something_went_wrong_console"]):format("SHS - PLAYER NOT VALID"))
		return
	end

	xPlayer.character:SetInputEnabled(false)
	SELF_HEALING_SERVICES:RegisterService(xPlayer)
end)

Events.SubscribeRemote("pcrp-ambulancejob::server::StopSelfHealingServices", function(player)
	local xPlayer = Core.GetPlayerFromId(player:GetID())

	xPlayer.character:SetInputEnabled(true)
	SELF_HEALING_SERVICES:DeleteService(xPlayer)
end)

Events.SubscribeRemote("pcrp-ambulancejob::server::UseSelfHealingService", function(player, serviceID)
	SELF_HEALING_SERVICES:UseService(player, serviceID)
end)

Events.SubscribeRemote("pcrp-ambulancejob::server::RequestSelfHealingServices", function(player)
	SELF_HEALING_SERVICES:SendServices(player)
end)

