local showingChar = nil
PlayerCharacters = {}
PlayersSelecting = {}
PlayerCharactersSaved = {}
PlayerSelectingCount = 0
PickingCharacterDimension = 6969
local registeredCharIds = {}


function SetCharMesh(char, isMale)
    if not char then return end

--[[     isMale = true -- for now.

    char:RemoveAllSkeletalMeshesAttached()

    local mesh = "helix::SK_Invisible"
	local head = "helix::SK_Male_Head"
	local chest = "helix::SK_Male_Chest"
	local hands = "helix::SK_Male_Hands"
	local legs = "helix::SK_Male_Legs"
	local feet = "helix::SK_Male_Feet"

    if not isMale then
        mesh = "helix::SK_Female_Body"
        head = "helix::SK_Female_Head"
        chest = "helix::SK_Female_Chest"
        hands = "helix::SK_Female_Hands"
        legs = "helix::SK_Female_Legs"
        feet = "helix::SK_Female_Feet"
    end

    char:SetMesh(mesh)
    char:AddSkeletalMeshAttached("head", head)
    char:AddSkeletalMeshAttached("headwear", head)
	char:AddSkeletalMeshAttached("topwear", chest)
	char:AddSkeletalMeshAttached("hands", hands)
	char:AddSkeletalMeshAttached("bottomwear", legs)
	char:AddSkeletalMeshAttached("footwear", feet) ]]
end

Events.Subscribe('core-multicharacter:PlayerReady', function(player, old_char)
    local xPlayer = Core.GetPlayerFromId(player:GetID())
    PlayerSelectingCount = PlayerSelectingCount + 1


    xPlayer.call('multichar:SetupRoom', Vector(0, 0, -5000))
    player:SetDimension(player:GetID())
    old_char:SetDimension(player:GetID())
    Timer.SetTimeout(function ()
        local cameraAttachProp = Prop(Vector(), Rotator(0, 0, 0), 'helix::SM_Pyramid_VR', 1, false, 0, CCDMode.Disabled)
        cameraAttachProp:SetVisibility(false)
        cameraAttachProp:SetDimension(player:GetID())
        cameraAttachProp:AttachTo(old_char, AttachmentRule.SnapToTarget)
        cameraAttachProp:SetRelativeLocation(Vector(120, 0, 0))
        cameraAttachProp:SetRelativeRotation(Rotator(0, -180, 0))

        old_char:SetLocation(Vector(0, 0, -5000))
        old_char:SetRotation(Rotator(0, 0, 0))
        player:SetCameraLocation(cameraAttachProp:GetLocation())
        player:SetCameraRotation(cameraAttachProp:GetRotation())
        player:SetCameraSocketOffset(Vector(0, 0, 50))
        cameraAttachProp:Detach()
        cameraAttachProp:Destroy()
        PlayersSelecting[player] = {char = old_char}
    end, 100)

    PersistentDatabase.GetByKey(xPlayer.identifier, function(success, data)
        local maxCharacters = 0
        local characters = {}
        if success then
            data = JSON.parse(data)
            if data[1] then
                maxCharacters = data[1]['value']['maxCharacters']
                characters = data[1]['value']['characters']

                for charid, character in pairs(characters) do
                    PlayerCharactersSaved[character.charid] = character
                end
            end

            xPlayer.call('pcrp-core:MulticharacterSetup', {
                slotsAvailable = maxCharacters,
                characters = characters
            })
        end
    end)
end)

Events.SubscribeRemote('multicharacter:AdjustCamera', function(player, offset, faceCamera)
    if not PlayersSelecting[player] then return end

--[[     player:SetCameraSocketOffset(offset + (Vector(0, 0, 1) * (PlayerSelectingCount * -180)))

    local char = PlayersSelecting[player].char
    if faceCamera then
        char:SetRotation(Rotator(0, 20, 0))

        return
    end

    char:SetRotation(Rotator(0, 0, 0)) ]]
end)

Events.SubscribeRemote('multicharacter:UpdateCharacter', function(player, charid)
    if not PlayersSelecting[player] then return end

    local char = PlayersSelecting[player].char

    -- TODO: Store the characters on the player class or globally to reduce amount of db calls
    -- local characterIds = DB:Select("SELECT charid FROM users WHERE identifier = :0 AND charid = :0", player:GetAccountID(), charid)
    -- local result = DB:Select("SELECT gender FROM user_character_info WHERE charid = :0", charid)

--[[     if result[1] == nil then
        return -- Character not available
    end ]]

    --local isMale = result[1].gender == 'm'
--[[     char:RemoveAllSkeletalMeshesAttached()

    local mesh = "helix::SK_Female_Body"
    local head = "helix::SK_Female_Head"
    if isMale then
        mesh = "helix::SK_Male"
        head = "helix::SK_Male_Head"
    end

    char:SetMesh(mesh)
    char:AddSkeletalMeshAttached("head", head) ]]

    -- SetCharMesh(char, isMale)
end)


Events.SubscribeRemote('multicharacter:SelectCharacter', function(player, cid)
    if not PlayersSelecting[player] then return end

    local char = PlayersSelecting[player].char
    local id = player:GetID()
    local xPlayer = Core.GetPlayerFromId(id)


    -- Verify character

    -- TODO: Store the characters on the player class or globally to reduce amount of db calls
    local characterSaved
    characterSaved = PlayerCharactersSaved[cid]

    if not characterSaved then
        return -- Character not available
    end

    PlayersSelecting[player] = nil
    PlayerSelectingCount = PlayerSelectingCount - 1

    xPlayer.setCharId(characterSaved.charid)
    UpdatePlayer(xPlayer, characterSaved, characterSaved.charid)
    PersistentDatabase.GetByKey(('%s_Saved'):format(characterSaved.charid), function(success, saved)
        if success then
            saved = JSON.parse(saved)

            if saved[1] then
                local charSaved = saved[1]['value']
                for k, save in pairs(charSaved) do
                    if xPlayer[k] then
                        if (k == 'accounts') then
                            xPlayer.addMoney(save['money'])
                        elseif (k == 'job') then
                            xPlayer.setJob(save)
                        end
                    else
                        print('tried to set saved character data on key, not found.', k)
                    end
                end
            end
        end
    end)

    -- Timer.SetTimeout(function()
    --     Events.CallRemote("pcrp-core:SpawnMenu", player, true)
    -- end, 500)
    player:Possess(char)

    -- Subscribe to Death event
    char:Subscribe("Death", OnPlayerCharacterDeath)

    -- Unsubscribe to Death event if unpossessed (in case we got possessed into another Character)
    char:Subscribe("UnPossess", function(self)
        self:Unsubscribe("Death", OnPlayerCharacterDeath)
    end)

    player:SetCameraSocketOffset(Vector())
    player:SetCameraRotation(Rotator(0, 180, 0))

    player:SetDimension(1)
    char:SetDimension(1)

    char:SetGravityEnabled(true)
    --char:SetFlyingMode(false)
    --char:SetInputEnabled(true)

    char:SetLocation(Vector(35606,65780,120)) -- THIS CHANGES SPAWN POSITION?
    char:SetRotation(Rotator(0, 180, 0))
    --char:SetLocation(Vector(0, 0, 1000))
    char:SetCapsuleSize(20, 92)

--[[         local nametag = TextRender(Vector(0,0,100),Rotator(),xPlayer.firstname or player:GetAccountName(),Vector(0.2,0.2,0.2),Color(1,1,1),FontType.Roboto,TextRenderAlignCamera.AlignCameraRotation) 
    nametag:AttachTo(char)
    nametag:SetRelativeLocation(Vector(0,0,100))
    nametag:SetTextSettings(0,0,0,TextRenderHorizontalAlignment.Center) ]]

    Events.CallRemote('core:playerSpawned', player, Core.Players[player:GetID()].serialisedVersion)
    Events.Call('core:playerSpawned', player)
    Events.BroadcastRemote('core:playerJoinedServer', player)

    Events.CallRemote("multicharacter:RemoveRoom", player)
    Events.CallRemote("pcrp-core:ShowHUD", player)
    --Events.CallRemote("pcrp-core:SpawnMenu", player, true)
--[[                     break
                end
            end
        end
    end)
 ]]
--[[     for charid in pairs(characterIds) do
        PersistentDatabase.GetByKey(charid, function (success, data)
            data = JSON.parse(data)

            if success and data[1] then
                local charCID = data[1]['value']['cid']

                if (charCID == cid) then
                    characterSaved = data[1]['value']
                end
            end
        end)
    end ]]

--[[     local str = ''
    local lenCharacterIds = #characterIds
    for k, v in ipairs(characterIds) do
        if k ~= lenCharacterIds then
            str = str .. 'charid=\'' .. v .. '\'' .. ' or '
        else
            str = str .. 'charid=\'' .. v .. '\''
        end
    end ]]

    local result = {} --DB:Select("SELECT * FROM user_character_info WHERE " .. str .. " AND cid = :0", cid)

end)

Events.SubscribeRemote('multicharacter:SaveCharacter', function(player, character_data)
    if not PlayersSelecting[player] then return end

    local char = PlayersSelecting[player].char

    -- Save character to db
    local charid = CreateCharID()
    local identifier = player:GetAccountID()
    local characterData = {
        charid = charid,
        cid = character_data.cid,
        birthdate = character_data.date_of_birth,
        firstname = character_data.first_name,
        lastname = character_data.last_name,
        nationality = character_data.nationality,
        gender = character_data.gender and 'm' or 'f'
    }
    local userDefault = {
        characters = {
            characterData
        },
        maxCharacters = 1
    }

    -- DB:Execute("INSERT INTO users (charid, identifier, name) VALUES (:0, :0, :0)", function()
    -- end, charid, identifier, player:GetName())
    -- DB:Execute(
    --     "INSERT INTO user_character_info (charid, cid, birthdate, firstname, lastname, nationality, gender) VALUES (:0, :0, :0, :0, :0, :0, :0)",
    --     function()
    --     end,
    --     charid, character_data.cid, character_data.date_of_birth, character_data.first_name,
    --     character_data.last_name, character_data.nationality, character_data.gender and 'm' or 'f')

    -- DB:SelectAsync('SELECT * FROM users_maxcharacters WHERE identifier = "' .. identifier .. '"', function(result)
    --     if next(result) == nil then
    --         DB:Execute("INSERT INTO users_maxcharacters (identifier, maxcharacters) VALUES (:0, :0)", function()
    --         end, identifier, 1)
    --     end
    -- end)

    Timer.SetTimeout(function ()
        PersistentDatabase.GetByKey(identifier, function(success, data)
            data = JSON.parse(data)

            if success and data[1] then
                local xPlayer = Core.GetPlayerFromId(player:GetID())
                local characters = data[1]['value']['characters'] or {}
                local maxCharacters = data[1]['value']['maxCharacters'] or 0

                characters[charid] = characterData
                maxCharacters = maxCharacters + 1

                data[1]['value']['characters'] = characters
                data[1]['value']['maxCharacters'] = maxCharacters

                xPlayer.setCharId(charid)
                UpdatePlayer(xPlayer, characterData, charid)

                xPlayer.inventory.AddItem('begel', 1)
                xPlayer.inventory.AddItem('phone', 1)
                xPlayer.inventory.AddItem('water', 1)

                PersistentDatabase.Update(identifier, JSON.stringify(data[1]['value']), function () end)
            else
                PersistentDatabase.Insert(identifier, JSON.stringify(userDefault), function () end)
            end
        end)
        registeredCharIds[charid] = true
        PersistentDatabase.Insert('registeredCharIds', JSON.stringify(registeredCharIds), function () end)
    end, 250)

    local isMale = character_data.gender

--[[     char:RemoveAllSkeletalMeshesAttached()

    local mesh = "helix::SK_Female_Body"
    local head = "helix::SK_Female_Head"
    if isMale then
        mesh = "helix::SK_Male"
        head = "helix::SK_Male_Head"
    end

    char:SetMesh(mesh)
    char:AddSkeletalMeshAttached("head", head) ]]

    -- SetCharMesh(char, isMale)

    player:SetDimension(1) -- quick fix
    char:SetDimension(1)

    PlayersSelecting[player] = nil
    PlayerSelectingCount = PlayerSelectingCount - 1

    Timer.SetTimeout(function()
        player:Possess(char)

        -- Subscribe to Death event
        char:Subscribe("Death", OnPlayerCharacterDeath)
        
        -- Unsubscribe to Death event if unpossessed (in case we got possessed into another Character)
        char:Subscribe("UnPossess", function(self)
            self:Unsubscribe("Death", OnPlayerCharacterDeath)
        end)
        
        player:SetCameraSocketOffset(Vector())
        player:SetCameraRotation(Rotator(0, 180, 0))
        
        char:SetGravityEnabled(true)
        
        --char:SetFlyingMode(false)
        --char:SetInputEnabled(true)
        
        Events.CallRemote('core:playerSpawned', player, Core.Players[player:GetID()].serialisedVersion)
        Events.Call('core:playerSpawned', player)
        Events.BroadcastRemote('core:playerJoinedServer', player)
        Events.CallRemote("multicharacter:RemoveRoom", player)
        Events.CallRemote("pcrp-core:ShowHUD", player)

        --Events.CallRemote("pcrp-core:SpawnMenu", player, true)

        char:SetLocation(Vector(8444.7, 62169.1, 120) or Vector(35606,65780,120))
        char:SetRotation(Rotator(0, 180, 0))
    end, 0)
end)

Events.SubscribeRemote('multicharacter:ChangeGender', function(player, isMale)
    print("CHANIGN GENDER", isMale)
    print('test 1')
    if not PlayersSelecting[player] then return end
    
    print('test 2')
    local char = PlayersSelecting[player].char

--[[     char:RemoveAllSkeletalMeshesAttached()

    local mesh = "helix::SK_Female_Body"
    local head = "helix::SK_Female_Head"
    if isMale then
        mesh = "helix::SK_Male"
        head = "helix::SK_Male_Head"
    end

    char:SetMesh(mesh)
    char:AddSkeletalMeshAttached("head", head) ]]

    -- SetCharMesh(char, isMale)
end)

Events.Subscribe('core:playerLeftServer', function(xPlayer, player)
    if PlayersSelecting[player] then
        local char = PlayersSelecting[player].char
    
        PlayersSelecting[player] = nil
        PlayerSelectingCount = PlayerSelectingCount - 1
        char:Destroy()
    end
end)

--- [[Functions]] ---

--- @brief Function to update the player data
function UpdatePlayer(xPlayer, data, charid)
    if not data then return end

    if xPlayer then
        if data[1] then data = data[1] end
        local name = data.firstname .. " " .. data.lastname

        xPlayer.setName(name)

        xPlayer.set('firstName', data.firstname)
        xPlayer.set('charId', data.charid or charid or 1)
        xPlayer.set('lastName', data.lastname)
        xPlayer.set('dateofbirth', data.birthdate)
        xPlayer.set('gender', data.gender)
        xPlayer.set('nationality', data.nationality)
    end


end

--- @brief Function to create a random string for the char id
function CreateCharID()
    local charId = nil
    local checkDB = function(checkDB)
        charId = tostring(Core.GetRandomStr(3) .. Core.GetRandomInt(5)):upper()
--[[         PersistentDatabase.GetByKey('registeredCharIds', function(success, data)
            data = JSON.parse(data)

            if success then
                local charIdsSaved = data[1]['value'] ]]

                if not registeredCharIds[charId] then
                    print('[helix] Char ID: ' .. charId .. ' has been created!')
                else
                    checkDB()
                end
--[[             end
        end) ]]
    end
    checkDB()

    return charId
end

Package.Subscribe('Load', function ()
    PersistentDatabase.GetByKey('registeredCharIds', function(success, data)
        data = JSON.parse(data)

        if success and data[1]then
            registeredCharIds = data[1]['value'] or {}
        end
    end)
end)

--- [[Commands]] ---

-- Core.CreateCommand("plyinfo", function(xPlayer, args)
--     local name = xPlayer.get('firstName')
--     local lastname = xPlayer.get('lastName')
--     local dob = xPlayer.get('dateofbirth')
--     local gen = xPlayer.get('gender')
--     local nationality = xPlayer.get('nationality')

--     Chat.BroadcastMessage(name .. " " .. lastname .. " " .. dob .. " " .. gen .. " " .. nationality)
-- end, {})
