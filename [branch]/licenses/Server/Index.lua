local Licenses = {}

local hardcoded_licenseData = {
    firstName = 'Myer',
    lastName = 'HELIX',
    address = '456 Parallel Drive',
    state = 'Parallel City, PC 5517',
    licenseNumber = 'PC45782OO45',
    dob = '01/09/1920',
    issueDate = '05/08/2019',
    expireDate = '17/05/2023',
    class = 'A',
    gender = 'M',
}


Package.Subscribe("Load", function()
	Core.CreateItem({
		['drivinglicense'] = {
			label = 'Driver License',
			unique = true,
			description = 'needed for driving.',
			type = 'item',
		},
	})
end)

--- @brief returns the closest player within given range/distance
function Licenses:GetClosestPlayer(player, distance)
    if not player or not distance then return nil end
    local char = player:GetControlledCharacter()
    local location = char:GetLocation()
    local closest_player = nil

    for k, ply in pairs(Player.GetAll()) do
        if player ~= ply then
            if ply and ply:GetControlledCharacter() then
                local chr = ply:GetControlledCharacter()
                local loc =  chr:GetLocation()
                local dis = HELIXMath.Round(location:Distance(loc) / 4)
                if dis <= distance then
                    closest_player = ply
                    break
                end
            end
        end
    end

    return closest_player
end

function Licenses:ShowDrivingLicense(player, licenseData)
    if not player then return end
    if not licenseData then return end

    local other_player = self:GetClosestPlayer(player.player, 15.0)

    Events.CallRemote('Licenses:ShowLicense', player.player, 'driving_license', licenseData)
    if other_player then
        Events.CallRemote('Licenses:ShowLicense', other_player, 'driving_license', licenseData)
    end
end


Core.CreateUseableItem('drivinglicense', function(player, item, slot, extra)
    local inventory = player.inventory
    local license = inventory[extra][slot]
    local licenseData = license.metadata

    Licenses:ShowDrivingLicense(player, licenseData)
end)


Chat.Subscribe("PlayerSubmit", function(message, player)
    local xPlayer = Core.GetPlayerFromId(player:GetID())

--[[ 	if message == 'showLicense' then
        Licenses:ShowDrivingLicense(xPlayer)
    end

    if message == 'getLicense' then
        local timeToAdd = (86400 * 14) -- 14 days
        local issueTime = os.time()
        local expiryTime = issueTime + timeToAdd
        local issueDate = os.date('%x', issueTime)
        local expiryDate = os.date('%x', expiryTime)
    
        local metadata = {
            characterImage = xPlayer.characterImage,
            firstName = xPlayer.get('firstName'),
            lastName = xPlayer.get('lastName'),
            address = '456 Parallel Drive',
            state = 'Parallel City, PC 5517',
            licenseNumber = 'PC45782OO45',
            dob = xPlayer.get('dateofbirth'),
            issueDate = issueDate,
            expireDate = expiryDate,
            issueTime = issueTime,
            expiryTime = expiryTime,
            class = 'A',
            gender = string.upper(xPlayer.get('gender')),
        }
    
        print('issue', issueDate, 'expiry', expiryDate, 'issueTime', issueTime, 'expiryTime', expiryTime)
        xPlayer.inventory.AddItem('drivinglicense', 1, metadata)
    end ]]
end)


Events.SubscribeRemote('CharacterSnapShot:SaveIMG', function (player, img)
--[[     local xPlayer = Core.GetPlayerFromId(player:GetID())
    local characterPicturesPath = "Packages/"..Package.GetName().."/Server/CharacterPictures.json"
    local characterPictures = File(characterPicturesPath, false)
    local characterPicturesSize = characterPictures:Size()
    local characterPicturesTable = characterPicturesSize > 0 and JSON.parse(characterPictures:Read(characterPicturesSize)) or nil
 ]]
    --xPlayer.characterImage = img

--[[     if characterPicturesSize <= 0 or not characterPicturesTable then
        local newCharacterPictures = {}
        newCharacterPictures[xPlayer.charid] = img

        local header = {
            Authorization =  'aPQEfZkJ3DtKH5Vs^B6c42S6PaJsjK^MP$v6VrxYXsDG9hEJ'
        }

        HTTP.RequestAsync("https://api.helix-cdn.com", "/pco-cache/", "PUT", img, "text/plain", false, header, function(status, data)
            Console.Log(status) -- 200
            Console.Log(data) -- 200

            print(HELIXTable.Dump(data))
        end)


        characterPictures:Write(JSON.stringify(newCharacterPictures))
        characterPictures:Close()
        return
    end

    characterPictures:Close()
    characterPicturesTable[xPlayer.charid] = img

    local header = {
        Authorization =  'aPQEfZkJ3DtKH5Vs^B6c42S6PaJsjK^MP$v6VrxYXsDG9hEJ'
    }

    HTTP.RequestAsync("https://api.helix-cdn.com", "/pco-cache/", "PUT", img, "text/plain", false, header, function(status, data)
        Console.Log(status) -- 200
        Console.Log(data) -- 200
    
        -- TIP: You can parse it if it's a json return as well
        print(HELIXTable.Dump(data))
    end)

    local emptyJSON = File(characterPicturesPath, true)
    emptyJSON:Write(JSON.stringify(characterPicturesTable))
    emptyJSON:Close() ]]
end)