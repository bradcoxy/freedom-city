--[[-------------------------------------
--   @brief   Helix Admin Menu         --
--                                     --
--                                     --
--   @author  @Kravs                   --
--   @version 0.0.1                    --
--   @date    May 2023                 --
---------------------------------------]]


local AdminMenu = {}

Events.SubscribeRemote("Goto:Teleport", function(player, target)
    local my_char = player:GetControlledCharacter()
    local target_char = target:GetControlledCharacter()
    local target_location = target_char:GetLocation()

    my_char:SetLocation(Vector(target_location.X, target_location.Y, target_location.Z + 300))
end)

Events.SubscribeRemote("Bring:Teleport", function(player, target)
    local targetChar = target:GetControlledCharacter()
    local my_char = player:GetControlledCharacter()
    local my_location = my_char:GetLocation()

    targetChar:SetLocation(Vector(my_location.X, my_location.Y, my_location.Z + 300))
end)

Events.SubscribeRemote("Player:Kill", function(player, target)
    local xTarget = Core.GetPlayerFromId(target:GetID())

    if (xTarget) then
        xTarget.slay()
    end
end)

Events.SubscribeRemote("Player:Revive", function(player, target)
    local xTarget = Core.GetPlayerFromId(target:GetID())

    if (xTarget) then
        xTarget.revive()
    end
end)

Events.SubscribeRemote("Player:Kick", function(player, target, reason)
    if target then
        SendLog({
            ["username"] = "Admin System",
            ['embeds'] = {
                {
                    ['title'] = 'Player Kicked',
                    ['fields'] = {
                        {
                            ['name'] = 'Admin',
                            ['value'] = player:GetAccountName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Player Kicked',
                            ['value'] = target:GetAccountName() .. ' '.. target:GetAccountID(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Reason',
                            ['value'] = reason or 'No reason given.',
                            ['inline'] =  true
                        },
                    }
                }
            }
        })
        if reason then
            target:Kick(reason)
            return
        end
        target:Kick("You have been kicked from the server.")
    end
end)

Events.SubscribeRemote("Player:SetJob", function(player, target, job)
    if target then
        local xTarget = Core.GetPlayerFromId(target:GetID())
        if job then
            xTarget.setJob(job)
            return
        end
        target:Kick("You have been kicked from the server.")
    end
end)

Events.SubscribeRemote("Player:ToggleNoclip", function(player, target)
    if target then
        local character = target:GetControlledCharacter()
        if (not character) then
            return
        end
        print('tatu')
        local is_noclipping = character:GetValue('NoClip')

        if (is_noclipping) then
            -- character:SetCameraMode(2)
            character:SetFlyingMode(false)
            character:SetVisibility(true)
            character:SetCollision(CollisionType.Normal)
        else
            -- character:SetCollision(CollisionType.NoCollision)
            -- character:SetCameraMode(1)
            character:SetFlyingMode(true)
            character:SetVisibility(false)
        end

        character:SetValue('NoClip', not is_noclipping)
    end
end)


Events.SubscribeRemote("Player:ToggleGodMode", function (player, target)
    if target then
        local character = target:GetControlledCharacter()
        if (not character) then
            return
        end

        local is_godmode = character:GetValue('GodMode')

        if (is_godmode) then
            character:SetMaxHealth(100)
            character:SetHealth(100)
            print("Godmode disabled", target:GetName(), character:GetHealth())
        else
            character:SetMaxHealth(999999)
            character:SetHealth(999999)
            print("Godmode enabled", target:GetName(), character:GetHealth())
        end

        character:SetValue('GodMode', not is_godmode)
    end
end)

Events.SubscribeRemote("Player:ToggleVisibility", function (player, target)
    if target then
        local character = target:GetControlledCharacter()
        if (not character) then
            return
        end

        local is_visible = character:GetValue('Visible')

        if (is_visible) then
            character:SetVisibility(false)
        else
            character:SetVisibility(true)
        end

        character:SetValue('Visible', not is_visible)
    end
end)

Events.SubscribeRemote("Player:FixVehicle", function (player, target)
    if target then
        local xTarget = Core.GetPlayerFromId(target:GetID())
        local vehicle = xTarget.getVehicle()

        --- WIP
    end
end)

Events.SubscribeRemote("Player:GiveVehicle", function (player, target, carName)
    local xTarget = Core.GetPlayerFromId(target:GetID())
    if target then
        local coords = xTarget.character:GetLocation()
        local rotation = xTarget.character:GetControlRotation()
    
        coords = coords + Vector(0, 0, 10)
        local veh = Core.CreateVehicle(carName, coords, rotation)
        print(veh)
        xTarget.character:EnterVehicle(veh, 0)
    end
end)

Events.SubscribeRemote("Player:DeleteVehicle", function (player, target)
    if target then
        local xTarget = Core.GetPlayerFromId(target:GetID())
        local vehicle = xTarget:getVehicle()

        if (vehicle) then
            vehicle:Destroy()
        end
    end
end)

Events.SubscribeRemote("Player:HandleAccountMoney", function (player, target, type, operation, amount)
    local xTarget = Core.GetPlayerFromId(target:GetID())
    if target then
        if type == "_cash" then 
            xTarget.addMoney(amount)
        elseif type == "_bank" then
            xTarget.addBankMoney(amount)
        end
    end
end)


Events.SubscribeRemote("Server:GetPlayerInfo", function(player, selectedPlayer)
    local allPlayers = Player.GetAll()
    local playerInfo = {}

    for i, player in pairs(allPlayers) do
        if (player:GetAccountID() == selectedPlayer.identifier) then
            local xPlayer = Core.GetPlayerFromId(player:GetID())
            local identifier = selectedPlayer.identifier
            local name = player:GetName()
            local charID = xPlayer.charid
            local result = DB:Select("SELECT * FROM user_character_info WHERE charid = :0", charID)
            local rpname = result[1].firstname .. " " .. result[1].lastname
            local dob = result[1].birthdate
            local gen = result[1].gender
            local nationality = result[1].nationality
            local job = xPlayer.job.job or xPlayer.job or "Unemployed"

            local source = xPlayer.source
            local cash = xPlayer.accounts["money"]
            local bank = xPlayer.accounts["bank"]
            local xp = xPlayer.getXP()
            local rank = xPlayer.getRank()

            playerInfo = {
                Source = source,
                HelixName = name,
                RolePlayName = rpname,
                HelixIdentifier = identifier,
                Bank = bank,
                Cash = cash,
                Job = job,
                DateOfBirth = dob,
                Gender = gen,
                Nationality = nationality,
                XP = xp,
                Rank = rank,
                PhoneNumber = "23123",
            }
        end
    end

    Events.CallRemote("Client:PlayerInfo", player, playerInfo)
end)


function SendLog(data)
	HTTP.RequestAsync('https://discord.com', '/api/webhooks/1228086796429295717/aQzKic2kWNXuxeSANzp40ASHrpuwG0_Lm7VYJvwuwzhxV_CG8h7OYM18NHVKVojCUAjj', 'POST', JSON.stringify(data), 'application/json')
end

Events.Subscribe('core:playerSpawned', function(player)
    print('called')
    local playerIdentifier = player:GetAccountID()
    local adminsFile = File('Packages/'.. Package.GetName() ..'/admin.json')
    local allowedAdmins = JSON.parse(adminsFile:Read())

    if allowedAdmins[playerIdentifier] then
        Events.CallRemote('Client:AdminAllowed', player,  true)
        SendLog({
            ["username"] = "Admin System",
            ['embeds'] = {
                {
                    ['title'] = 'Admin Joined',
                    ['fields'] = {
                        {
                            ['name'] = 'Name',
                            ['value'] = player:GetAccountName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Account Identifier',
                            ['value'] = playerIdentifier,
                            ['inline'] =  true
                        },
                    }
                }
            }
        })
        print('admin found', allowedAdmins[playerIdentifier])
    end
end)

Chat.Subscribe("PlayerSubmit", function(message, player)
    if message == "s" then
        print('called')
        local playerIdentifier = player:GetAccountID()
        local adminsFile = File('Packages/'.. Package.GetName() ..'/admin.json')
        local allowedAdmins = JSON.parse(adminsFile:Read())

        if allowedAdmins[playerIdentifier] then
            Events.CallRemote('Client:AdminAllowed', player, true)
            SendLog({
                ["username"] = "Admin System",
                ['embeds'] = {
                    {
                        ['title'] = 'Admin Joined',
                        ['fields'] = {
                            {
                                ['name'] = 'Name',
                                ['value'] = player:GetAccountName(),
                                ['inline'] =  true
                            },
                            {
                                ['name'] = 'Account Identifier',
                                ['value'] = playerIdentifier,
                                ['inline'] =  true
                            },
                        }
                    }
                }
            })
            print('admin found', allowedAdmins[playerIdentifier])
        end
    end
end)

function CreateNewChar(player)
    local new_char = Character(Vector(0, 0, 200), Rotator(0, 0, 0), "helix::SK_Invisible")
    player:Possess(new_char)
    new_char:SetCapsuleSize(20, 92)
    new_char:AddSkeletalMeshAttached("head", "helix::SK_Male_Head")
    new_char:AddSkeletalMeshAttached("hat", "helix::SK_Police_Hat")
    new_char:AddSkeletalMeshAttached("top", "helix::SK_Police_Top")
    new_char:AddSkeletalMeshAttached("hands", "helix::SK_Male_Hands")
    new_char:AddSkeletalMeshAttached("legs", "helix::SK_Police_Lower")
    new_char:AddSkeletalMeshAttached("feet", "helix::SK_Police_Shoes")
end