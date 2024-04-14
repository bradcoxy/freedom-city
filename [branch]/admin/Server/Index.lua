local AdminMenu = {}
AdminMenu.activeBans = {}

Events.SubscribeRemote("Goto:Teleport", function(player, target)
    local my_char = player:GetControlledCharacter()
    local target_char = target:GetControlledCharacter()
    local target_location = target_char:GetLocation()

    my_char:SetLocation(Vector(target_location.X, target_location.Y, target_location.Z + 300))
    SendLog({
        ["username"] = "Admin System",
        ['embeds'] = {
            {
                ['title'] = 'Admin Teleported to Player',
                ['fields'] = {
                    {
                        ['name'] = 'Admin',
                        ['value'] = player:GetAccountName(),
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Target Player',
                        ['value'] = target:GetAccountName() .. ' '.. target:GetAccountID(),
                        ['inline'] =  true
                    }
                }
            }
        }
    })
end)

Events.SubscribeRemote("Bring:Teleport", function(player, target)
    local targetChar = target:GetControlledCharacter()
    local my_char = player:GetControlledCharacter()
    local my_location = my_char:GetLocation()

    targetChar:SetLocation(Vector(my_location.X, my_location.Y, my_location.Z + 300))
    SendLog({
        ["username"] = "Admin System",
        ['embeds'] = {
            {
                ['title'] = 'Player Brought To Admin',
                ['fields'] = {
                    {
                        ['name'] = 'Admin',
                        ['value'] = player:GetAccountName(),
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Target Player',
                        ['value'] = target:GetAccountName() .. ' '.. target:GetAccountID(),
                        ['inline'] =  true
                    }
                }
            }
        }
    })
end)

Events.SubscribeRemote("Player:Kill", function(player, target)
    local xTarget = Core.GetPlayerFromId(target:GetID())

    if (xTarget) then
        xTarget.slay()
        SendLog({
            ["username"] = "Admin System",
            ['embeds'] = {
                {
                    ['title'] = 'Player Killed by Admin',
                    ['fields'] = {
                        {
                            ['name'] = 'Admin',
                            ['value'] = player:GetAccountName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Player Killed',
                            ['value'] = target:GetAccountName() .. ' '.. target:GetAccountID(),
                            ['inline'] =  true
                        }
                    }
                }
            }
        })
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

Events.SubscribeRemote('Player:Ban', function(player, target, reason)
    if not target then return end

    reason = reason or 'No reason was given.'

    local targetAccount = target:GetAccountID()
    local targetIP = target:GetIP()
    local targetName = player:GetAccountName()
    local bansFilePath = 'Packages/'.. Package.GetName() ..'/bans.json'
    local bansFile = File(bansFilePath, false)
    local currentBans = bansFile:Size() > 0 and JSON.parse(bansFile:Read()) or {}

    if not currentBans[targetAccount].active then
        local emptyJSON = File(bansFilePath, true)

        currentBans[targetAccount] = currentBans[targetAccount] or {}
        currentBans[targetAccount].active = true
        currentBans[targetIP] = true
        currentBans[targetAccount]['pastBans'] = currentBans[targetAccount]['pastBans'] or {}
        table.insert(currentBans[targetAccount]['pastBans'], {
            reason = reason,
            time = os.date()
        })

        emptyJSON:Write(JSON.stringify(currentBans))
        emptyJSON:Close()
        bansFile:Close()

        local previousBansLog = {}
        for k, ban in pairs(currentBans[targetAccount]['pastBans']) do
            previousBansLog[#previousBansLog + 1] = {
                ['name'] = ('#%s Reason: %s'):format(k, ban.reason),
                ['value'] = ('Time: %s'):format(ban.time),
                ['inline'] =  true
            }
        end
        SendLog({
            ["username"] = "Admin System",
            ['embeds'] = {
                {
                    ['title'] = 'Player Banned',
                    ['fields'] = {
                        {
                            ['name'] = 'Admin',
                            ['value'] = targetName,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Player Banned',
                            ['value'] = ('%s %s'):format(targetName, targetAccount),
                            ['inline'] =  true
                        }
                    }
                },
                {
                    ['title'] = ('%s\'s Previous Bans'):format(targetName),
                    ['fields'] = previousBansLog
                }
            }
        })

        target:Kick('You have been banned. '.. reason)
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
        SendLog({
            ["username"] = "Admin System",
            ['embeds'] = {
                {
                    ['title'] = 'Admin Toggled NoClip',
                    ['fields'] = {
                        {
                            ['name'] = 'Admin',
                            ['value'] = player:GetAccountName(),
                            ['inline'] =  true
                        }
                    }
                }
            }
        })
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
        SendLog({
            ["username"] = "Admin System",
            ['embeds'] = {
                {
                    ['title'] = 'Admin Toggled God Mode',
                    ['fields'] = {
                        {
                            ['name'] = 'Admin',
                            ['value'] = player:GetAccountName(),
                            ['inline'] =  true
                        }
                    }
                }
            }
        })
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
                PhoneNumber = "23123"
            }
        end
    end

    Events.CallRemote("Client:PlayerInfo", player, playerInfo)
end)


function SendLog(data)
	HTTP.RequestAsync('https://discord.com', '/api/webhooks/1226893748827455549/CH7TO4toQuJxRBXikoC6vwLZx74ftFdaDw1tL-ymcDzwwFnI5fIWo7t6y68wqXA_zbUC', 'POST', JSON.stringify(data), 'application/json')
end

-- ban checking
Server.Subscribe("PlayerConnect", function(IP, player_account_ID)
    local bansFile = File('Packages/'.. Package.GetName() ..'/bans.json')
    local bannedPlayers = bansFile:Size() > 0 and JSON.parse(bansFile:Read()) or {}

    if (bannedPlayers[player_account_ID]) and (bannedPlayers[player_account_ID].active) or (bannedPlayers[IP]) then
        SendLog({
            ["username"] = "Admin System",
            ['embeds'] = {
                {
                    ['title'] = 'Banned Player Tried To Join',
                    ['fields'] = {
                        {
                            ['name'] = 'Account ID',
                            ['value'] = player_account_ID,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'IP Address',
                            ['value'] = IP,
                            ['inline'] =  true
                        },
                    }
                }
            }
        })
        return false
    end
end)

Player.Subscribe("Ready", function(self)
    local playerIdentifier = self:GetAccountID()
    local adminsFile = File('Packages/'.. Package.GetName() ..'/admin.json')
    local allowedAdmins = adminsFile:Size() > 0 and JSON.parse(adminsFile:Read()) or {}

    if allowedAdmins[playerIdentifier] then
        Events.CallRemote('Client:AdminAllowed', self,  true)
        SendLog({
            ["username"] = "Admin System",
            ['embeds'] = {
                {
                    ['title'] = 'Admin Joined',
                    ['fields'] = {
                        {
                            ['name'] = 'Name',
                            ['value'] = self:GetAccountName(),
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