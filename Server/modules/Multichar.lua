local showingChar = nil
PlayerCharacters = {}
PlayersSelecting = {}
PlayerSelectingCount = 0
PickingCharacterDimension = 6969


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
    local ret_01, ret_02 = NanosMath.RelativeTo(Vector(120, 0, 0), Rotator(0, 180, 0), old_char)

    PlayersSelecting[player] = { char = old_char, cam_pos = ret_01 }
    PlayerSelectingCount = PlayerSelectingCount + 1


    old_char:SetLocation(Vector(0, 0, -500 + (PlayerSelectingCount * -180)))
    old_char:SetRotation(Rotator(0, 20, 0))
    local platformPos = old_char:GetLocation()

    player:SetCameraLocation(ret_01)
    player:SetCameraRotation(ret_02)

    player:SetDimension(PickingCharacterDimension)
    old_char:SetDimension(PickingCharacterDimension)

    local char = old_char

--[[     char:RemoveAllSkeletalMeshesAttached()

    local mesh = "helix::SK_Male"
    local head = "helix::SK_Male_Head"

    char:SetMesh(mesh)
    char:AddSkeletalMeshAttached("head", head) ]]

    -- SetCharMesh(char, true)

    local xPlayer = Core.GetPlayerFromId(player:GetID())

    local characterIds = DB:Select("SELECT charid FROM users WHERE identifier = :0", xPlayer.identifier)
    local maxCharacters = DB:Select("SELECT maxcharacters FROM users_maxcharacters WHERE identifier = :0",
        xPlayer.identifier)

    if maxCharacters[1] == nil then
        DB:Execute("INSERT INTO users_maxcharacters (identifier, maxcharacters) VALUES (:0, :0)", xPlayer.identifier, 1)
    end
    
    -- print("MAX CHARACTERS => ", maxCharacters[1])
    maxCharacters = (maxCharacters[1] and maxCharacters[1].maxcharacters) or 1
    -- print("MAX CHARACTERS => ", maxCharacters)
    
    local str = ''
    local lenCharacterIds = #characterIds
    for k, v in ipairs(characterIds) do
        if k ~= lenCharacterIds then
            str = str .. 'charid=\'' .. v.charid .. '\'' .. ' or '
        else
            str = str .. 'charid=\'' .. v.charid .. '\''
        end
    end
    
    local characterInfo
    if #str ~= 0 then
        characterInfo = DB:Select("SELECT * FROM user_character_info WHERE " .. str)
    end
    
    local data = {
        slotsAvailable = maxCharacters,
        characters = characterInfo
    }
    print("CHAR DATA => ", NanosUtils.Dump(data))

    xPlayer.call('multichar:SetupRoom', platformPos)
    xPlayer.call('pcrp-core:MulticharacterSetup', data)
end)

Events.SubscribeRemote('multicharacter:AdjustCamera', function(player, offset, faceCamera)
    if not PlayersSelecting[player] then return end

    player:SetCameraSocketOffset(offset + (Vector(0, 0, 1) * (PlayerSelectingCount * -180)))

    local char = PlayersSelecting[player].char
    if faceCamera then
        char:SetRotation(Rotator(0, 20, 0))

        return
    end

    char:SetRotation(Rotator(0, 0, 0))
end)

Events.SubscribeRemote('multicharacter:UpdateCharacter', function(player, charid)
    if not PlayersSelecting[player] then return end

    local char = PlayersSelecting[player].char

    -- TODO: Store the characters on the player class or globally to reduce amount of db calls
    local characterIds = DB:Select("SELECT charid FROM users WHERE identifier = :0 AND charid = :0",
        player:GetAccountID(), charid)
    local result = DB:Select("SELECT gender FROM user_character_info WHERE charid = :0", charid)

    if result[1] == nil then
        return -- Character not available
    end

    local isMale = result[1].gender == 'm'
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
    local characterIds = DB:Select("SELECT charid FROM users WHERE identifier = :0", xPlayer.identifier)

    local str = ''
    local lenCharacterIds = #characterIds
    for k, v in ipairs(characterIds) do
        if k ~= lenCharacterIds then
            str = str .. 'charid=\'' .. v.charid .. '\'' .. ' or '
        else
            str = str .. 'charid=\'' .. v.charid .. '\''
        end
    end

    local result = DB:Select("SELECT * FROM user_character_info WHERE " .. str .. " AND cid = :0", cid)

    if result[1] == nil then
        return -- Character not available
    end

    PlayersSelecting[player] = nil
    PlayerSelectingCount = PlayerSelectingCount - 1

    xPlayer.setCharId(result[1].charid)
    UpdatePlayer(xPlayer, result[1], result[1].charid)

    
    -- Timer.SetTimeout(function()
    --     Events.CallRemote("pcrp-core:SpawnMenu", player, true)
    -- end, 500)
    
    Timer.SetTimeout(function()
        player:Possess(char)

        -- Subscribe to Death event
        char:Subscribe("Death", OnPlayerCharacterDeath)

        -- Unsubscribe to Death event if unpossessed (in case we got possessed into another Character)
        char:Subscribe("UnPossess", function(self)
            self:Unsubscribe("Death", OnPlayerCharacterDeath)
        end)

        player:SetCameraSocketOffset(Vector())

        player:SetDimension(1)
        char:SetDimension(1)

        char:SetGravityEnabled(true)
        --char:SetFlyingMode(false)
        --char:SetInputEnabled(true)

        char:SetLocation(Vector(40619,63438,1000) or Vector(0, 0, 1000)) -- THIS CHANGES SPAWN POSITION?
        char:SetCapsuleSize(20, 92)

        --give nametag feck it
        print(HELIXTable.Dump(xPlayer))
        print(xPlayer.firstname)
        local nametag = TextRender(Vector(0,0,100),Rotator(),xPlayer.firstname or player:GetAccountName(),Vector(0.2,0.2,0.2),Color(1,1,1),FontType.Roboto,TextRenderAlignCamera.AlignCameraRotation) 
        nametag:AttachTo(char)
        nametag:SetRelativeLocation(Vector(0,0,100))
        nametag:SetTextSettings(0,0,0,TextRenderHorizontalAlignment.Center)

        Events.CallRemote('core:playerSpawned', player, Core.Players[player:GetID()].serialisedVersion)
        Events.Call('core:playerSpawned', player)
        Events.BroadcastRemote('core:playerJoinedServer', player)
        
        Events.CallRemote("multicharacter:RemoveRoom", player)
        Events.CallRemote("pcrp-core:SpawnMenu", player, true)
    end, 0)
end)

Events.SubscribeRemote('multicharacter:SaveCharacter', function(player, character_data)
    if not PlayersSelecting[player] then return end

    local char = PlayersSelecting[player].char

    -- Save character to db
    local charid = CreateCharID()
    local identifier = player:GetAccountID()

    DB:Execute("INSERT INTO users (charid, identifier, name) VALUES (:0, :0, :0)", function()
    end, charid, identifier, player:GetName())
    DB:Execute(
        "INSERT INTO user_character_info (charid, cid, birthdate, firstname, lastname, nationality, gender) VALUES (:0, :0, :0, :0, :0, :0, :0)",
        function()
        end,
        charid, character_data.cid, character_data.date_of_birth, character_data.first_name,
        character_data.last_name, character_data.nationality, character_data.gender and 'm' or 'f')

    DB:SelectAsync('SELECT * FROM users_maxcharacters WHERE identifier = "' .. identifier .. '"', function(result)
        if next(result) == nil then
            DB:Execute("INSERT INTO users_maxcharacters (identifier, maxcharacters) VALUES (:0, :0)", function()
            end, identifier, 1)
        end
    end)

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
        
        char:SetGravityEnabled(true)
        
        --char:SetFlyingMode(false)
        --char:SetInputEnabled(true)
        
        
        Events.CallRemote("multicharacter:RemoveRoom", player)
        Events.CallRemote("pcrp-core:SpawnMenu", player, true)

        char:SetLocation(Vector())
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
    local UniqueFound = false
    local charId = nil
    while not UniqueFound do
        charId = tostring(Core.GetRandomStr(3) .. Core.GetRandomInt(5)):upper()
        local result = DB:Select('SELECT COUNT(*) as count FROM users WHERE charid = "' .. charId .. '"')
        if result[1].count == 0 then
            UniqueFound = true
            print('[helix] Char ID: ' .. charId .. ' has been created!')
        end
    end
    return charId
end

--- [[Commands]] ---

-- Core.CreateCommand("plyinfo", function(xPlayer, args)
--     local name = xPlayer.get('firstName')
--     local lastname = xPlayer.get('lastName')
--     local dob = xPlayer.get('dateofbirth')
--     local gen = xPlayer.get('gender')
--     local nationality = xPlayer.get('nationality')

--     Chat.BroadcastMessage(name .. " " .. lastname .. " " .. dob .. " " .. gen .. " " .. nationality)
-- end, {})
