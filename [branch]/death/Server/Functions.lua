--- Heals minor injuries of the given player
--- @param xPlayer table
function HealMinorInjuries(xPlayer)
	local currentHealth = xPlayer.character:GetHealth()
	local maxHealth = xPlayer.character:GetMaxHealth()
	local addHealthAmount = maxHealth * Config.MinorHealValue / 100
	local newHealth = currentHealth + addHealthAmount

	if (newHealth > maxHealth) then
		newHealth = maxHealth
	end

	xPlayer.character:SetHealth(newHealth)
end

--- Heals major injuries of the given player
--- @param xPlayer table
function HealMajorInjuries(xPlayer)
	local maxHealth = xPlayer.character:GetMaxHealth()
	xPlayer.character:SetHealth(maxHealth)
end