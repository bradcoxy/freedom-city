-- Package.Require("Functions.lua")
-- Package.Require("Modules/Items.lua")
-- Package.Require("Modules/JobActions.lua")
-- Package.Require("Modules/MedicalSuppliesShop.lua")
Package.Require("Modules/Death.lua")

--[[ Core.CreateCommand("ambulance", function(xPlayer)
	xPlayer.setJob({
		name = 'ambulance'
	})
end)

Core.CreateCommand("ambMoney", function(xPlayer)
	xPlayer.addMoney(5000)
end)

Core.CreateCommand("killSelf", function(xPlayer)
	xPlayer.slay()
end)

Core.CreateCommand('getAcc', function (xPlayer)
	print('player account', GetAccount(xPlayer.charid))
end)

Core.CreateCommand('getAcc2', function (xPlayer)
	print('player account', GetAccountFromIBAN('IBN25888'))
end)

Core.CreateCommand("testani", function(xPlayer, args)
	xPlayer.character:StopAnimation()

	if not args.anim or (args.anim and args.anim == 'stop') then
		return
	end

	print(1)
	xPlayer.character:PlayAnimation("nanos-world::"..args.anim)
end, {
	{ name = 'anim', type = 'string' }
})
 ]]

Chat.Subscribe("PlayerSubmit", function(message, player)
	local xPlayer = Core.GetPlayerFromId(player:GetID())

	if (message == 'killSelf') then
		xPlayer.slay()
	end
end)