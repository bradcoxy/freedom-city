local ServerPoints = {}

Markers = {
    Arrow = 'pco-markers::SM_MarkerArrow',
    Circle = 'pco-markers::SM_MarkerCircle',
    Cylinder = 'pco-markers::SM_MarkerCylinder'
}

NPCOutfits = {
    ['default'] = {
        mesh = 'helix::SK_Man_Outwear_03',
        headwear = 'helix::SK_Male_Head',
        hands = 'helix::SK_Male_Hands',
        bottomwear = 'helix::SK_Man_Pants_09',
        footwear = 'helix::SK_Male_Feet'
    }
}

Package.Export('Markers', Markers)

local time = os.time
local random = math.random
local rs = math.randomseed

local pointCount = 0
local keysPressed = {}
local keysReleased = {}

local nearbyPoints = {}
local nearbyCount = 0

local closestPoint = nil
local tick = nil

function CreatePoint(data)
    local self = {}

    self.coords = data.coords
    self.distance = data.distance
    self.markerSettings = data.marker
    self.text = data.text
    self.prompt = data.prompt
    self.npc = data.npc
    
    self.marker = nil
    self.npcSpawned = false

    self.currentDistance = 0.0
    self.markerVisible = true
    self.textVisible = true
    self.promptVisible = true    

    if type(data.interactions) == 'string' then
        data.interactions = { data.interactions }
    end

    local obj = {}
    for k, v in ipairs(data.interactions) do
        obj[v] = true
    end

    data.interactions = obj

    self.interactions = data.interactions
    
    rs(time())

    self.id = time() + pointCount

    function self:showPrompt()
        if self.prompt == nil then return end
        if self.promptVisible == true then return end
        
        self.promptVisible = true
        Core.AddInteraction(self.prompt.key, self.prompt.text, self.prompt.holdTime ~= nil, self.prompt.holdTime)
    end

    function self:spawnNPC()
        if self.npcSpawned then return end

        self.npcSpawned = not self.npcSpawned

        if not self.npc then
            self.npc = {}
        end

        if not self.npc.coords then
            self.npc.coords = self.coords
            self.npc.rotation = Rotator()
        end

        self.npc.outfit = self.npc.outfit and NPCOutfits[self.npc.outfit] or NPCOutfits['default']

        Events.CallRemote('core:spawnNPC', self.npc)
    end

    function self:hidePrompt()
        if self.prompt == nil then return end
        if self.promptVisible == false then return end

        self.promptVisible = false
        Core.RemoveInteraction(self.prompt.key)
    end

    function self:showText()
        if self.text == nil then return end
        if self.textVisible then return end
        self.textVisible = true

        self.text:SetVisibility(self.textVisible)
    end

    function self:updateText(data)
        if data == nil then return end
        if self.text == nil then return end

        if data.text then
            self.text:SetText(data.text)
        end

        if data.color then
            self.text:SetColor(data.color)
        end

        if data.scale then
            self.text:SetScale(data.scale)
        end
    end

    function self:updateMarker(data)
        if data == nil then return end

        if data.color then
            self.markerSettings.color = data.color
            self.marker:SetMaterialColorParameter("Color", data.color)
        end

        if data.scale then
            self.markerSettings.scale = data.scale
            self.marker:SetScale(data.scale)
        end
    end

    function self:hideText()
        if self.text == nil then return end
        if self.textVisible == false then return end
        self.textVisible = false
        
        self.text:SetVisibility(self.textVisible)
    end

    function self:showMarker()
        if self.marker == nil then return end
        if self.markerVisible then return end
        self.markerVisible = true
        
        self.marker:SetVisibility(self.markerVisible)
    end
    
    function self:hideMarker()
        if self.marker == nil then return end
        if self.markerVisible == false then return end
        self.markerVisible = false
        
        self.marker:SetVisibility(self.markerVisible)
    end

    function self:remove()
        if self.marker then
            self.marker:Destroy()
        end
        if self.text then
            self.text:Destroy()
        end

        pointCount = pointCount - 1
        ServerPoints[self.id] = nil
    end

    function self:onEnter()
    end

    function self:onExit()
    end

    function self:isKeyPressed(key)
        return keysPressed[key]
    end

    function self:isKeyJustPressed(key)
        if not keysPressed[key] then return end
        if keysPressed[key].justPressed then return end

        if keysPressed[key].count == 1 then
            keysPressed[key].justPressed = true

            return true
        end

        return false
    end

    function self:isKeyJustReleased(key)
        if keysReleased[key] == nil then return end
        
        if time() - keysReleased[key] == 0 then
            keysReleased[key] = nil
            return true
        end
        
    end

    if self.markerSettings ~= nil then
        local prop = Prop(self.coords, Rotator(0, 0, 0), self.markerSettings.type, CollisionType.NoCollision, false, GrabMode.Disabled, CCDMode.Auto)        
        prop:SetMaterialColorParameter("Color", self.markerSettings.color or Color(1, 1, 1))

        self.markerSettings.scale = self.markerSettings.scale or Vector(1, 1, 1)
        prop:SetScale(self.markerSettings.scale)

        self.marker = prop
        self:hideMarker()
    end

    if self.text ~= nil then
        local text = TextRender(self.coords + Vector(0, 0, 100), Rotator(0, 0, 0), self.text.text, self.text.scale or Vector(0.15, 0.15, 0.15), self.text.color, FontType.Roboto, TextRenderAlignCamera.FaceCamera)
        text:SetTextSettings(nil, nil, nil, TextRenderHorizontalAlignment.Center, TextRenderVerticalAlignment.Center)
        -- text:SetFreeze(true)

        self.text = text
        self:hideText()
    end

    ServerPoints[self.id] = self
    pointCount = pointCount + 1

    return self
end

Timer.SetInterval(function()
    if nearbyCount > 0 then
        table.wipe(nearbyPoints)
        nearbyCount = 0
    end

    local player = Client.GetLocalPlayer()
    if player == nil then return end

    local character = player:GetControlledCharacter()
    
    if character == nil then return end
    
    local pCoords = character:GetLocation()

    if closestPoint and pCoords:Distance(closestPoint.coords) > closestPoint.distance then
        closestPoint = nil
    end

    for k, v in pairs(ServerPoints) do
        local dist = v.coords:Distance(pCoords)
        
        if dist <= v.distance then
            v.currentDistance = dist
            
            if closestPoint then
                closestPoint.isClosest = nil
                v.isClosest = true
                closestPoint = v
            elseif dist < v.distance then
                v.isClosest = true
                closestPoint = v
            end

            if v.nearby then
                nearbyCount = nearbyCount + 1
                nearbyPoints[nearbyCount] = v
            end

            if v.onEnter and not v.inside then
                v.inside = true
                v:onEnter()
            end
        elseif v.currentDistance then
            if v.onExit then v:onExit() end
            v.inside = nil
            v.currentDistance = nil 
        end
    end
end, 500)

Timer.SetInterval(function()
    
    if nearbyCount == 0 then
        return
    end

    for i = 1, nearbyCount do
        local point = nearbyPoints[i]

        if point then
            point:nearby()
        end
    end
end, 100)

Input.Subscribe("KeyDown", function(key_name, delta)
    if keysPressed[key_name] == nil then keysPressed[key_name] = { count = 0, justPressed = false } end
    keysPressed[key_name].count = keysPressed[key_name].count + 1
end)

Input.Subscribe("KeyUp", function(key_name, delta)
    keysPressed[key_name] = nil
    keysReleased[key_name] = time()
end)