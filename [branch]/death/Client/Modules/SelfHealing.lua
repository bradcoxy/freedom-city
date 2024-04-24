local currentServiceID = ""
local inactiveServices = {}

Player.Subscribe("Possess", function()
	Events.CallRemote("pcrp-ambulancejob::server::RequestSelfHealingServices")
end)

Events.SubscribeRemote("pcrp-ambulancejob::client::CreateSelfHealingService", function(service, doctorIdentifier)
	local identifier = Core.PlayerData.source

	print('char id player', identifier, 'doctor', doctorIdentifier)

	if identifier == doctorIdentifier then
		Core.ShowNotification(NOTIFICATIONS["started_offering_self_healing_services"])
		return
	end

    local point = Core.CreateMarker({
        coords = service.location,
        distance = 150.0,
        prompt = {
            text = 'Self Heal',
			key = 'F'
        },
        interactions = 'F'
    })

    function point:nearby()
        if isBusy then return end
               
        if self.currentDistance <= 150.0 then
            self:showPrompt()
            
            if self:isKeyJustReleased('F') then
                isBusy = true

				if not inactiveServices[service.id] then
					currentServiceID = service.id
				end

				UseSelfHealingServices(service.id)

                isBusy = false
            end
        else
            self:hidePrompt()
        end
    end

    function point:onExit()
		self:hidePrompt()
    end
end)

Events.SubscribeRemote("pcrp-ambulancejob::client::MakeServiceInactive", function(serviceID)
	inactiveServices[serviceID] = true

	if currentServiceID == serviceID then
		Core.RemoveInteraction("F")
	end
end)

Events.SubscribeRemote("pcrp-ambulancejob::client::ReceiveSelfHealingServices", function(services)
	for _, service in pairs(services) do
		local point = Core.CreateMarker({
			coords = service.location,
			distance = 150.0,
			prompt = {
				text = 'to self heal.',
				key = 'F'
			},
			interactions = 'F'
		})
	
		point:showMarker()
		
		function point:nearby()
			if isBusy then return end
				   
			if self.currentDistance <= 150.0 then
				self:showPrompt()
				
				if self:isKeyJustReleased('F') then
					isBusy = true
	
					if not inactiveServices[service.id] then
						currentServiceID = service.id
					end

					UseSelfHealingServices(service.id)
	
					isBusy = false
				end
			else
				self:hidePrompt()
			end
		end
		
		function point:onExit()
			self:hidePrompt()
		end
	end
end)

function UseSelfHealingServices(serviceID)
	Events.CallRemote("pcrp-ambulancejob::server::UseSelfHealingService", serviceID)
end