local multichar_ui = Core.RegisterHUD('multicharacter', 'file://ui/modules/multicharacter/index.html')

local active_camera = false
local multichar_small_room
local multichar_platform

Events.SubscribeRemote('pcrp-core:MulticharacterSetup', function(characterData)
    active_camera = true
    Sky.DestroyAllSky()
    
    Sky.Spawn()
    Sky.SetTimeOfDay(7, 30)
    
    multichar_ui.Focus(true, false)
    
    if characterData.characters ~= nil and next(characterData.characters) then
        local newData = {}
        for k, v in ipairs(characterData.characters) do
            if not newData[k] then
                newData[k] = {}
            end
            newData[k].identifier = v.charid
            newData[k].first_name = v.firstname
            newData[k].last_name = v.lastname
            newData[k].cash = v.cash or 0
            newData[k].bank = v.bank or 0
            newData[k].phone_number = v.phone_number or 0
            newData[k].gender = v.gender == 'm' and 'Male' or 'Female'
            newData[k].job = v.job or 'Unemployed'
            newData[k].nationality = v.nationality
            newData[k].date_of_birth = v.birthdate
        end
        characterData.characters = newData
    else
        characterData.characters = {}
    end
    
    Client.SetValue('isBusy', true)
    Core.HideHUD()

    multichar_ui.Call('Initialise', { nationalities = CoreCFG.Nationalities, characterData = characterData })
end)

Events.SubscribeRemote('multichar:SetupRoom', function(platformPos)
    local vp = Viewport.GetViewportSize()
    local x = vp.X * 0.115
    local y = vp.Y * 0.115

    multichar_small_room = Billboard(
        Vector(0, 0, 500), -- location
        "helix::M_NanosMasked", -- material
        Vector2D(y, x), -- size
        false
    )
    
    multichar_small_room:SetMaterialTextureParameter("Texture", "package://pcrp-core/Client/image.png")
    
    multichar_platform = Prop(platformPos - Vector(0, 0, 100.0), Rotator(), "helix::SM_Plane", CollisionType.Normal, false)
    multichar_platform:SetScale(Vector(10, 10, 1))

    Sky.SetAnimateTimeOfDay(false)
    Sky.SetTimeOfDay(7, 30)

    local my_light = Light(
        platformPos + Vector(120, 0, 80),
        Rotator(0, 90, 0), -- Relevant only for Rect and Spot light types
        Color(1, 1, 1), -- Red Tint
        LightType.Point, -- Point Light type
        0.2, -- Intensity
        250, -- Attenuation Radius
        44, -- Cone Angle (Relevant only for Spot light type)
        0, -- Inner Cone Angle Percent (Relevant only for Spot light type)
        5000, -- Max Draw Distance (Good for performance - 0 for infinite)
        true, -- Whether to use physically based inverse squared distance falloff, where Attenuation Radius is only clamping the light's contribution. (Spot and Point types only)
        false, -- Cast Shadows?
        true -- Enabled?
    )
end)

Events.SubscribeRemote('multicharacter:RemoveRoom', function()
    print("TRYING TO REMOVE ROOM")
    multichar_small_room:Destroy()
    multichar_small_room = nil
    multichar_platform:Destroy()
    multichar_platform = nil

	active_camera = false

    multichar_ui.RemoveHUD()    
    
    Sky.SetAnimateTimeOfDay(true)
end)

function RemoveRoom()
    multichar_small_room:Destroy()
    multichar_small_room = nil
	active_camera = false

    multichar_ui.RemoveHUD()
    
    
    Sky.SetAnimateTimeOfDay(true)
end

function ValidateInformation(character_data)
    local first_name = character_data.first_name
    local last_name = character_data.last_name
    local date_of_birth = character_data.date_of_birth
    local nationality = character_data.nationality
    local gender = character_data.gender

    if first_name == nil or #first_name == 0 then
        return 'error_first_name'
    end
    
    if last_name == nil or #last_name == 0 then
        return 'error_last_name'
    end

    if date_of_birth == nil or #date_of_birth == 0 or date_of_birth == 'MM/DD/YYYY' then
        return 'error_dob'
    end

    if nationality == nil then
        return 'error_nationality'
    end

    if gender == nil then
        return 'error_gender'
    end
end

multichar_ui.Subscribe('CHANGE_GENDER', function(isMale)
    Events.CallRemote('multicharacter:ChangeGender', isMale)
end)

-- This event will send a request to readjust the character for the new menu
multichar_ui.Subscribe('CREATE_CHARACTER_CAMERA', function()
    Events.CallRemote('multicharacter:AdjustCamera', Vector(20, -30, 50), true)
end)

-- This event will send a request to readjust the character for the new menu
multichar_ui.Subscribe('CHOOSE_CHARACTER_CAMERA', function()
    Events.CallRemote('multicharacter:AdjustCamera', Vector(0, 0, 30), false)
end)

multichar_ui.Subscribe('CREATE_CHARACTER', function(character_data)
    local validateInformation = ValidateInformation(character_data)

    if (validateInformation ~= nil) then
        Core.ShowNotification(_U(validateInformation))
        return
    end

    Events.CallRemote('multicharacter:SaveCharacter', character_data)
    Client.SetValue('isBusy', false)
end)

multichar_ui.Subscribe('CHOOSE_CHARACTER', function(cid)
    Client.SetValue('isBusy', false)
    Events.CallRemote('multicharacter:SelectCharacter', cid)
end)

multichar_ui.Subscribe('multicharacter:UpdateCharacter', function(charid)
    Events.CallRemote('multicharacter:UpdateCharacter', charid)
end)

Client.Subscribe("Tick", function(delta_time)
    if not multichar_small_room then return end
    -- if not active_camera then return end

    local viewport_2D_center = Viewport.GetViewportSize() / 2
    local viewport_3D = Viewport.DeprojectScreenToWorld(viewport_2D_center)
    local start_location = viewport_3D.Position

    local end_location = (viewport_3D.Position + viewport_3D.Direction * 200.0)

    multichar_small_room:SetLocation(end_location)
end)