local RoleplayCommands = {}

RoleplayCommands.AllowedCommands = {
    'ooc',
    'looc',
    'me',
    'whisper',
    'wd',
    'yell',
    'rules'
}

RoleplayCommands.Alternatives = {
    ['o'] = 'ooc',
    ['lo'] = 'looc',
    ['w'] = 'whisper',
    ['y'] = 'yell',
    ['m'] = 'me'
}

RoleplayCommands.EmergencyServices = {
    ['911'] = {
        ['police'] = true,
        ['ambulance'] = true
    }
}

RoleplayCommands.OffensiveWords = {
    ['NIGGER'] = true,
    ['NEGRO'] = true,
    ['NIGGA'] = true,
    ['GAY'] = true,
    ['GAYROPE'] = true,
    ['LESBO'] = true,
    ['BATTY'] = true,
    ['BATTY BOY'] = true,
    ['CUNTBOY'] = true,
    ['GROOMER'] = true,
    ['SHEMALE'] = true,
    ['RAPE'] = true,
    ['CHINK'] = true,
    ['WHORE'] = true,
    ['SLUT'] = true,
    ['GIP'] = true,
    ['SLAVE'] = true,
    ['GYPSY'] = true,
    ['HITLER'] = true,
    ['ANAL'] = true,
    ['ANUS'] = true,
    ['ASS'] = true,
    ['ASSHOLE'] = true,
    ['BADASS'] = true,
    ['BALLSACK'] = true,
    ['BASTARD'] = true,
    ['BITCH'] = true,
    ['BLOWJOB'] = true,
    ['BONER'] = true,
    ['BONG'] = true,
    ['BULLSHIT'] = true,
    ['BUTTSECS'] = true,
    ['BUTTSEX'] = true,
    ['CHOAD'] = true,
    ['CHODE'] = true,
    ['CIRCLEJERK'] = true,
    ['CLIT'] = true,
    ['COCK'] = true,
    ['COCKBLOCK'] = true,
    ['COCKSUCK'] = true,
    ['COCKSUCKER'] = true,
    ['COOTCH'] = true,
    ['CORNHOLE'] = true,
    ['CRACKWHORE'] = true,
    ['CUM'] = true,
    ['CUMMING'] = true,
    ['CUNT'] = true,
    ['CK'] = true,
    ['D!IC'] = true,
    ['DICK'] = true,
    ['DICKBRICK'] = true,
    ['DILDO'] = true,
    ['DOUCHEBAG'] = true,
    ['DUMBASS'] = true,
    ['ERECTION'] = true,
    ['FAEG'] = true,
    ['FAG'] = true,
    ['FAGGOT'] = true,
    ['FAHGOT'] = true,
    ['FCUK'] = true,
    ['FGT'] = true,
    ['FUC'] = true,
    ['FUCK'] = true,
    ['FUHK'] = true,
    ['FUK'] = true,
    ['FUQ'] = true,
    ['GANGBANG'] = true,
    ['GOD'] = true,
    ['JIZZ'] = true,
    ['NEGGA00'] = true,
    ['NIGS21'] = true,
    ['NIPPLE'] = true,
    ['NIPPLES'] = true,
    ['PENIS'] = true,
    ['PHCK'] = true,
    ['PHUC'] = true,
    ['PHUCK'] = true,
    ['PHUK'] = true,
    ['PISSING'] = true,
    ['PORN'] = true,
    ['PORNHUB'] = true,
    ['PORNO'] = true,
    ['POTHEAD'] = true,
    ['PUSSAY'] = true,
    ['PUSSY'] = true,
}

function RoleplayCommands.FilteredMessage(letters)
    local ret = ''

    for _, letter in pairs(letters) do
        ret = ret .. letter
    end

    return ret
end

function RoleplayCommands.Filter(message)
    local messageCopy = (message):lower()
    local letters = {}

    for i = 1, string.len(message), 1 do
        letters[#letters + 1] = string.upper(message, i, i)
    end

    for word in pairs(RoleplayCommands.OffensiveWords) do
        for ins in string.gmatch(messageCopy, word) do
            local x, y = string.find(messageCopy, ins)
            if x and y then
                for i = x, y, 1 do
                    letters[i] = '*'
                end
                messageCopy = (RoleplayCommands.FilteredMessage(letters)):lower()
            end
        end
    end

    return RoleplayCommands.FilteredMessage(letters)
end

function RoleplayCommands.OOC(player, message, alternative)
    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local name = xPlayer.getName()
    local pattern = alternative and '^/'.. alternative ..'%s(.+)' or '^/ooc%s(.+)'
	local ooc = (message):match(pattern)

    if ooc then
        Timer.SetTimeout(function ()
            Chat.BroadcastMessage(('<red>[OOC]</> <blue>%s</> %s'):format(name, RoleplayCommands.Filter(ooc)))
        end, 150)
    end
end

function RoleplayCommands.LOOC(player, message, alternative)
    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local playerLocation = xPlayer.character:GetLocation()
    local name = xPlayer.getName()
    local pattern = alternative and '^/'.. alternative ..'%s(.+)' or '^/looc%s(.+)'
	local looc = (message):match(pattern)

    if looc then
        Timer.SetTimeout(function ()
            for _, otherPlayer in pairs(Player.GetPairs()) do
                if otherPlayer:GetControlledCharacter() and not (otherPlayer:GetID() == player:GetID()) then
                    local otherPlayerLocation = otherPlayer:GetControlledCharacter():GetLocation()
                    local distanceBetween = otherPlayerLocation:Distance(playerLocation)
    
                    if distanceBetween <= 10000 then
                        Chat.SendMessage(otherPlayer, ('<red>[LOOC]</> <blue>%s</> %s'):format(name, RoleplayCommands.Filter(looc)))
                    end
                end
            end
            Chat.SendMessage(player, ('<red>[LOOC]</> <blue>%s</> %s'):format(name, RoleplayCommands.Filter(looc)))
        end, 150)
    end
end

function RoleplayCommands.YELL(player, message, alternative)
    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local playerLocation = xPlayer.character:GetLocation()
    local name = xPlayer.getName()
    local pattern = alternative and '^/'.. alternative ..'%s(.+)' or '^/yell%s(.+)'
	local yell = (message):match(pattern)

    if yell then
        Timer.SetTimeout(function ()
            for _, otherPlayer in pairs(Player.GetPairs()) do
                if otherPlayer:GetControlledCharacter() and not (otherPlayer:GetID() == player:GetID()) then
                    local otherPlayerLocation = otherPlayer:GetControlledCharacter():GetLocation()
                    local distanceBetween = otherPlayerLocation:Distance(playerLocation)
    
                    if distanceBetween <= 5000 then
                        Chat.SendMessage(otherPlayer, ('<red>%s</> <yellow>yells</> "%s"'):format(name, RoleplayCommands.Filter(yell)))
                    end
                end
            end
            Chat.SendMessage(player, ('<red>%s</> <yellow>yells</> "%s"'):format(name, RoleplayCommands.Filter(yell)))
        end, 150)
    end
end

function RoleplayCommands.ME(player, message, alternative)
    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local playerLocation = xPlayer.character:GetLocation()
    local name = xPlayer.getName()
    local pattern = alternative and '^/'.. alternative ..'%s(.+)' or '^/me%s(.+)'
	local me = (message):match(pattern)

    if me then
        Timer.SetTimeout(function ()
            for _, otherPlayer in pairs(Player.GetPairs()) do
                if otherPlayer:GetControlledCharacter() and not (otherPlayer:GetID() == player:GetID()) then
                    local otherPlayerLocation = otherPlayer:GetControlledCharacter():GetLocation()
                    local distanceBetween = otherPlayerLocation:Distance(playerLocation)
    
                    if distanceBetween <= 1500 then
                        Chat.SendMessage(otherPlayer, ('<red>%s</> says "%s"'):format(name, RoleplayCommands.Filter(me)))
                    end
                end
            end
            Chat.SendMessage(player, ('<red>%s</> says "%s"'):format(name, RoleplayCommands.Filter(me)))
        end, 150)
    end
end

function RoleplayCommands.WHISPER(player, message, alternative)
    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local playerLocation = xPlayer.character:GetLocation()
    local name = xPlayer.getName()
    local pattern = alternative and '^/'.. alternative ..'%s(.+)' or '^/me%s(.+)'
	local whisper = (message):match(pattern)

    if whisper then
        Timer.SetTimeout(function ()
            for _, otherPlayer in pairs(Player.GetPairs()) do
                if otherPlayer:GetControlledCharacter() and not (otherPlayer:GetID() == player:GetID()) then
                    local otherPlayerLocation = otherPlayer:GetControlledCharacter():GetLocation()
                    local distanceBetween = otherPlayerLocation:Distance(playerLocation)

                    if distanceBetween <= 500 then
                        Chat.SendMessage(otherPlayer, ('<red>%s</> <yellow>whispers</> "%s"'):format(name, RoleplayCommands.Filter(whisper)))
                    end
                end
            end
            Chat.SendMessage(player, ('<red>%s</> <yellow>whispers</> "%s"'):format(name, RoleplayCommands.Filter(whisper)))
        end, 150)
    end
end


function RoleplayCommands.WD(player, message)
    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local playerLocation = xPlayer.character:GetLocation()
    local name = xPlayer.getName()
    local pattern = '^/wd%s(%d+)%s(.+)'
	local target, whisper = (message):match(pattern)
    local targetPlayer = Core.GetPlayerFromId(target)

    if not target then
        Chat.SendMessage(player, ('<yellow>[Direct Whisper]</> <red>(id) (message).</>'):format(target))
        return
    end

    if not targetPlayer then
        Chat.SendMessage(player, ('<yellow>[Direct Whisper]</> no player with the id <red>%s</>.'):format(target))
        return
    end

    local targetLocation = targetPlayer.character:GetLocation()
    if targetLocation:Distance(playerLocation) > 1000 then
        Chat.SendMessage(player, '<yellow>[Direct Whisper]</> player is too far away.')
        return
    end

    if whisper then
        Timer.SetTimeout(function ()
            for _, otherPlayer in pairs(Player.GetPairs()) do
                if otherPlayer:GetControlledCharacter() and not (otherPlayer:GetID() == player:GetID()) then
                    local otherPlayerLocation = otherPlayer:GetControlledCharacter():GetLocation()
                    local distanceBetween = otherPlayerLocation:Distance(playerLocation)
    
                    if distanceBetween <= 3000 then
                        Chat.SendMessage(otherPlayer, ('<red>%s</> is whispering to <blue>%s</>'):format(name, targetPlayer.getName()))
                    end
                end
            end
            Chat.SendMessage(player, ('<red>%s</> whispers "%s"'):format(name, RoleplayCommands.Filter(whisper)))
            Chat.SendMessage(targetPlayer, ('<red>%s</> whispers "%s"'):format(name, RoleplayCommands.Filter(whisper)))
        end, 150)
    end
end

function RoleplayCommands.Emergency(player, message, service)
    if not player then return end
    if not message then return end
    if not RoleplayCommands.EmergencyServices[service] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local services = RoleplayCommands.EmergencyServices[service]
    local pattern = '^/'.. service ..'%s(.+)'

	message = (message):match(pattern)

    local call = {
        location = xPlayer.character:GetLocation(),
        message = message
    }

    for _, yPlayer in pairs(Player.GetPairs()) do
        local zPlayer = Core.GetPlayerFromId(yPlayer:GetID())
        if (services[zPlayer.job.name]) then
            print('found service personel')
            Events.Call("freedom-city:Police:ReportCrime", call)
        end
    end
    print(HELIXTable.Dump(call))
end

---- rp commands logic
Chat.Subscribe("PlayerSubmit", function(message, player)
    for _, command in pairs(RoleplayCommands.AllowedCommands) do
        if (message):find('^/'.. command) then
            RoleplayCommands[(command):upper()](player, message)
            return false
        end
    end

    for alternative, command in pairs(RoleplayCommands.Alternatives) do
        if (message):find('^/'.. alternative) then
            RoleplayCommands[(command):upper()](player, message, alternative)
            return false
        end
    end

    for command in pairs(RoleplayCommands.EmergencyServices) do
        if (message):find('^/'.. command) then
            RoleplayCommands.Emergency(player, message, command)
            return false
        end
    end

    return false
end)