local Licenses = {}
Licenses.drivingLicenseUI = WebUI('drivingLicenseUI', 'file://UI/index.html')

function Licenses:ShowLicense(licenseType, LicenseData)
    licenseType = 'driving_license' and 'Driving License' or 'Unknown License'

    Timer.SetTimeout(function ()
        self.drivingLicenseUI:CallEvent('showdrvLicense', JSON.stringify(LicenseData))
    end, 250)
end


Events.SubscribeRemote('Licenses:ShowLicense', function (licenseType, licenseData)
    if not licenseData then return end
    if not licenseType then return end

    Licenses:ShowLicense(licenseType, licenseData)
end)


Events.SubscribeRemote('core:playerSpawned', function()
    Timer.SetTimeout(function ()
        local scene_capture = SceneCapture(Vector(38.0, 0.0, 160.0), Rotator(0, -180, 0), 1024, 1024, 0.033, 1000, 90)
        local prop = Prop(Vector(38.0, 0.0, 160.0), Rotator(0, -180, 0), "helix::SM_Cube", 2, false)
        local light = Light(Vector(100.0, 0.0, 170.0), Rotator(0, -180, 0), Color(1, 1, 1), LightType.Point, 2, 250, 44, 0, 5000, true, false, true)
        local background = Prop(Vector(-95.0, 0.0, 150.0), Rotator(0, 0, 0), "helix::SM_Cube", 5, false)
        local character = Client.GetLocalPlayer():GetControlledCharacter()

        --local helixcharacter = HELIXCharacter(Vector(200.0, 0.0, 10.0), Rotator(0, 180, 0), Client.GetLocalPlayer())
        --character:PlayAnimation("misc-animations::SK_Idle", true, "FullBody")

        background:SetScale(Vector(1.5, 1.5, 1.5))
        background:SetMaterialTextureParameter("Texture", "package://licenses/Client/background.jpg")

        scene_capture:AddRenderActor(character)
        scene_capture:AddRenderActor(background)
        scene_capture:SetShowFlag("Atmosphere", false)
        scene_capture:SetShowFlag("SkyLighting", false)
        scene_capture:SetShowFlag("AntiAliasing", true)

        prop:SetScale(Vector(0.5, 0.5, 0.5))
        prop:SetMaterialFromSceneCapture(scene_capture)

        Timer.SetTimeout(function()
            scene_capture:SetFreeze(true)
            local screeny = scene_capture:EncodeToBase64(0)

            Events.CallRemote('CharacterSnapShot:SaveIMG', screeny)

            --character:StopAnimation("misc-animations::SK_Idle")
            scene_capture:Destroy()
            prop:Destroy()
            light:Destroy()
            background:Destroy()
        end, 500)
    end, 5000) ---- PERFECT SETTINGS
end)


Events.SubscribeRemote('TakeCharacterPicture', function()
    Timer.SetTimeout(function ()
        local scene_capture = SceneCapture(Vector(30.0, 0.0, 158.0), Rotator(0, -180, 0), 1024, 1024, 0.033, 1000, 90)
        local prop = Prop(Vector(30.0, 0.0, 158.0), Rotator(0, -180, 0), "helix::SM_Cube", 2, false)
        local light = Light(Vector(100.0, 0.0, 170.0), Rotator(0, -180, 0), Color(1, 1, 1), LightType.Point, 2, 250, 44, 0, 5000, true, false, true)
        local background = Prop(Vector(-95.0, 0.0, 150.0), Rotator(0, 0, 0), "helix::SM_Cube", 5, false)


        --local helixcharacter = HELIXCharacter(Vector(200.0, 0.0, 10.0), Rotator(0, 180, 0), Client.GetLocalPlayer())

        background:SetScale(Vector(1.5, 1.5, 1.5))
        background:SetMaterialTextureParameter("Texture", "package://pcrp-licenses/Client/background.jpg")

        scene_capture:AddRenderActor(Client.GetLocalPlayer():GetControlledCharacter())
        scene_capture:AddRenderActor(background)
        scene_capture:SetShowFlag("Atmosphere", false)
        scene_capture:SetShowFlag("SkyLighting", false)
        scene_capture:SetShowFlag("AntiAliasing", true)

        prop:SetScale(Vector(0.5, 0.5, 0.5))
        prop:SetMaterialFromSceneCapture(scene_capture)

        Timer.SetTimeout(function()
            scene_capture:SetFreeze(true)
            local screeny = scene_capture:EncodeToBase64(0)
        
            Events.CallRemote('CharacterSnapShot:SaveIMG', screeny)

            scene_capture:Destroy()
            prop:Destroy()
            light:Destroy()
            background:Destroy()
        end, 500)
    end, 500) ---- PERFECT SETTINGS
end)