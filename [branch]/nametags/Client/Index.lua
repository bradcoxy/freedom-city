local NameTags = {}
NameTags.activeTags = {}
NameTags.activeTagMaterials = {}


-- Clears any existing tags on the character.
function NameTags.ClearTags(source)
    if not NameTags.activeTags[source] then return end

    NameTags.activeTags[source]:Destroy()
    NameTags.activeTagMaterials[source]:Destroy()
end


-- Gets called from the server, and does checks to make sure it doesn't put the name tag on self by comparing the sources/ids.
-- Creates a TextRender with the other player's name and attaches it above the player's head.
function NameTags.CreateTag(otherPlayer, otherPlayerName)
    if not otherPlayer then return end
    if not otherPlayerName then return end

    local self = NameTags
    local player = Client.GetLocalPlayer()
    local playerSource = player:GetID()
    local otherPlayerSource = otherPlayer:GetID()
    local otherPlayerCharacter = otherPlayer:GetControlledCharacter()

    if playerSource == otherPlayerSource then
        return
    end

    self.ClearTags(otherPlayerSource)

    local tagMaterial = WebUI("nametag"..otherPlayerName , "file://UI/index.html", WidgetVisibility.Hidden, true)
    local tag = Billboard(Vector(0, 0, 100), "helix::M_Default_Translucent_Lit", Vector2D(55, 100))

    tagMaterial:CallEvent('newTag', otherPlayerName)
    tag:AttachTo(otherPlayerCharacter)
    tag:SetRelativeLocation(Vector(0, 0, 110))
    tag:SetMaterialFromWebUI(tagMaterial)
    tag:SetMaterialScalarParameter('Opacity', 0.8)

    self.activeTags[otherPlayerSource] = tag
    self.activeTagMaterials[otherPlayerSource] = tagMaterial
end


--- Updates the mute state of the given player.
function NameTags.UpdateTagState(otherPlayer, bool)
    local player = Client.GetLocalPlayer()
    local playerSource = player:GetID()
    local otherPlayerSource = otherPlayer:GetID()

    if playerSource == otherPlayerSource then
        return
    end

    print(otherPlayerSource, bool)
    local tagMaterial = NameTags.activeTagMaterials[otherPlayerSource]
    tagMaterial:CallEvent('setMuteState', bool)
end


-- Called when need to remove a player's tag.
function NameTags.ClearTag(otherPlayerSource)
    if not otherPlayerSource then return end

    local player = Client.GetLocalPlayer()
    local playerSource = player:GetID()

    if playerSource == otherPlayerSource then
        return
    end

    NameTags.ClearTags(otherPlayerSource)

    NameTags.activeTags[otherPlayerSource] = nil
    NameTags.activeTagMaterials[otherPlayerSource] = nil
end


--[[ function NameTags.PlayerTalking(otherPlayer, isTalking)
    if not otherPlayer then return end

    local player = Client.GetLocalPlayer()
    local playerSource = player:GetID()
    local otherPlayerSource = otherPlayer:GetID()
    local otherPlayerTag = NameTags.activeTags[otherPlayerSource]

    if playerSource == otherPlayerSource then
        return
    end

    if not otherPlayerTag then
        return
    end

    if isTalking then
        otherPlayerTag:SetMaterialColorParameter("Tint", Color(1, 0, 0)) -- Red
    else
        otherPlayerTag:SetMaterialColorParameter("Tint", Color(1, 1, 1)) -- White
    end

    print(player, Client.GetLocalPlayer(), isTalking)
end ]]






-- Gets called when a player starts/stops using VOIP.
-- Calls PlayerTalking function for processing their nametag.
Player.Subscribe("VOIP", NameTags.UpdateTagState)

--- Gets called when a player joins the world.
Events.SubscribeRemote('NameTags:PlayerConnection', NameTags.CreateTag)

--- Gets called when a player leaves the world.
Events.SubscribeRemote('NameTags:PlayerDisconnection', NameTags.ClearTag)

-- Called when the players joins, and receives and adds nametags for the other players.
Events.SubscribeRemote('NameTags:AddExistingPlayer', NameTags.CreateTag)