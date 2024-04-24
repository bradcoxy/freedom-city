NOTIFICATIONS = {
	-- Called when checking for closest player
	["no_one_near"] = "There's no one near you",

	-- Called when checking if player has the required items in their inventory
	["need_bandage"] = "You must have a bandage to heal minor injuries",
	["need_medical_kit"] = "You must have a medical kit to heal major injuries",
	["need_defibrillator"] = "You must have a defibrillator to resuscitate",

	-- Called for treated player
	["minor_injuries_treated_self"] = "You have used a bandage to treat your minor injuries",
	["minor_injuries_treated_doctor"] = "You have treated the minor injuries of this person",
	["minor_injuries_treated_target"] = "Your minor injuries have been treated",
	
	["major_injuries_treated_self"] = "You have used a medical kit to treat your major injuries",
	["major_injuries_treated_doctor"] = "You have treated the major injuries of this person",
	["major_injuries_treated_target"] = "Your major injuries have been treated",

	["resuscitated_doctor"] = "You have resuscitated this person",
	["resuscitated_target"] = "You have been resuscitated",

	["started_offering_self_healing_services"] = "You've started offering self healing services",
	["self_healing_doctor"] = "You've received $%s for offered self healing",
	["self_healing_target"] = "Your injuries have been treated",

	-- Called when player buys a medical supply
	["bought_item"] = "You've bought x%s %s for $%s",

	-- Called when trying to revive a player
	["target_not_dead"] = "This person isn't unconscious",

	-- Called when zone restriction is enabled and player isn't in one of the zones
	["not_in_zone"] = "You can't offer self healing services here!",

	-- Called when player's already offering self heal
	["already_offering_self_healing"] = "You're already offering self healing",

	-- Called when you don't have enough money while buying medical supplies
	["not_enough_money"] = "You don't have enough money",

	-- Called when using item shop
	["invalid_input_value"] = "Invalid input value",

	-- Called when medical supply item somehow isn't in the shop's items table
	["something_went_wrong_client"] = "Something went wrong. Please contact with administration",

	-- Called when something goes wrong server-side
	["something_went_wrong_console"] = "[AMBULANCE JOB | %s] Something went wrong!",
}