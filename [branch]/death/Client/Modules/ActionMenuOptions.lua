local ACTION_MENU_OPTIONS <const> = {
	-- Main button
	{
		id = "ems_actions",
		category = "home",
		element = {
			label = "EMS Actions",
			icon = "fa-solid fa-heart",
			value = "ems_actions",
			func = nil,
			event = nil
		}
	},

	-- Actions
	{
		id = "heal_minor_injuries",
		category = "ems_actions",
		element = {
			label = "Heal Minor Injuries",
			icon = "fa-solid fa-stethoscope",
			value = "heal_minor_injuries",
			func = nil,
			event = "pcrp-ambulancejob::client::HealMinorInjuries"
		},
	},

	{
		id = "heal_major_injuries",
		category = "ems_actions",
		element = {
			label = "Heal Major Injuries",
			icon = "fa-solid fa-medkit",
			value = nil,
			func = nil,
			event = "pcrp-ambulancejob::client::HealMajorInjuries"
		},
	},

	{
		id = "resuscitate",
		category = "ems_actions",
		element = {
			label = "Resuscitate",
			icon = "fa-solid fa-heartbeat",
			value = nil,
			func = nil,
			event = "pcrp-ambulancejob::client::Resuscitate"
		},
	},

	-- Return button
	{
		id = "return",
		category = "ems_actions",
		element = {
			label = "Return",
			icon = "fa-solid fa-arrow-right-from-bracket",
			value = "home",
			func = nil,
			event = nil
		}
	},
}

local SELF_HEALING_OPTION <const> = {
	id = "self_healing_services",
	category = "ems_actions",
	element = {
		label = "Self Healing Services",
		icon = "fa-solid fa-hospital",
		value = nil,
		func = nil,
		event = "pcrp-ambulancejob::client::SelfHealingServices"
	},
}

local STOP_SELF_HEALING_OPTION <const> = {
	id = "stop_self_healing_services",
	category = "ems_actions",
	element = {
		label = "Stop Self Healing Services",
		icon = "fa-solid fa-hospital",
		value = nil,
		func = nil,
		event = "pcrp-ambulancejob::client::StopSelfHealingServices"
	},
}


--- Adds EMS options to the action menu
function AddActionMenuOptions()
	for _, v in pairs(ACTION_MENU_OPTIONS) do
		Core.AddAction({v})
	end

	AddSelfHealingOption()
end

--- Removes EMS options from the action menu
function RemoveActionMenuOptions()
	for _, v in pairs(ACTION_MENU_OPTIONS) do
		Core.RemoveAction(v.id)
	end
end

function ToggleActionMenuOptions(toggle)
	if toggle then
		for _, v in pairs(ACTION_MENU_OPTIONS) do
			if (v.category ~= "home") then
				Core.AddAction({v})
			end
		end
	else
		for _, v in pairs(ACTION_MENU_OPTIONS) do
			if (v.category ~= "home") then
				Core.RemoveAction(v.id)
			end
		end
	end
end

--- Adds an option to offer self healing services
function AddSelfHealingOption()
	Core.RemoveAction(STOP_SELF_HEALING_OPTION.id)
	Core.AddAction({SELF_HEALING_OPTION})
end

--- Removes an option to offer self healing services
function RemoveSelfHealingOption()
	Core.RemoveAction(SELF_HEALING_OPTION.id)
	Core.AddAction({STOP_SELF_HEALING_OPTION})
end

Events.SubscribeRemote("pcrp-ambulancejob::client::AddActionMenuOptions", function()
	AddActionMenuOptions()
end)

Events.SubscribeRemote("pcrp-ambulancejob::client::RemoveActionMenuOptions", function()
	RemoveActionMenuOptions()
end)