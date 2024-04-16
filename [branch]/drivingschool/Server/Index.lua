local DrivingSchool = {}
local currentPracticalTests = {}
local activeVehicles = {}

--- @briefs registering markers.
Package.Subscribe('Load', function()
    Prop(Vector(1926.8, 940.7, 94.1), Rotator(), 'helix::SM_Cube', 3, false, false, CCDMode.Auto)
end)


function SpawnVehicle(location)
    local vehicle = Vehicle(location, Rotator(), "helix::SK_Pickup", CollisionType.Normal, true, false, true, "helix::A_Vehicle_Engine_10")

    -- Configure it's Engine power and Aerodynamics
    vehicle:SetEngineSetup(700, 5000)
    vehicle:SetAerodynamicsSetup(2500)

    -- Configure it's Steering Wheel and Headlights location
    vehicle:SetSteeringWheelSetup(Vector(0, 27, 120), 24)
    vehicle:SetHeadlightsSetup(Vector(270, 0, 70))

    -- Configures each Wheel
    vehicle:SetWheel(0, "Wheel_Front_Left", 27, 18, 45, Vector(), true, true, false, false, false, 1500, 3000, 1000,
        1, 3, 20, 20, 250, 50, 10, 10, 0, 0.5, 0.5)
    vehicle:SetWheel(1, "Wheel_Front_Right", 27, 18, 45, Vector(), true, true, false, false, false, 1500, 3000, 1000,
        1, 3, 20, 20, 250, 50, 10, 10, 0, 0.5, 0.5)
    vehicle:SetWheel(2, "Wheel_Rear_Left", 27, 18, 0, Vector(), false, true, true, false, false, 1500, 3000, 1000, 1,
        4, 20, 20, 250, 50, 10, 10, 0, 0.5, 0.5)
    vehicle:SetWheel(3, "Wheel_Rear_Right", 27, 18, 0, Vector(), false, true, true, false, false, 1500, 3000, 1000, 1,
        4, 20, 20, 250, 50, 10, 10, 0, 0.5, 0.5)

    -- Adds 6 Doors/Seats
    vehicle:SetDoor(0, Vector(50, -75, 105), Vector(8, -32.5, 95), Rotator(0, 0, 10), 70, -150)
    vehicle:SetDoor(1, Vector(50, 75, 105), Vector(25, 50, 90), Rotator(0, 0, 0), 70, 150)
    vehicle:SetDoor(2, Vector(-90, -75, 130), Vector(-90, -115, 155), Rotator(0, 90, 20), 60, -150)
    vehicle:SetDoor(3, Vector(-90, 75, 130), Vector(-90, 115, 155), Rotator(0, -90, 20), 60, 150)
    vehicle:SetDoor(4, Vector(-195, -75, 130), Vector(-195, -115, 155), Rotator(0, 90, 20), 60, -150)
    vehicle:SetDoor(5, Vector(-195, 75, 130), Vector(-195, 115, 155), Rotator(0, -90, 20), 60, 150)

    -- Make it ready (so clients only create Physics once and not for each function call above)
    vehicle:RecreatePhysics()
    return vehicle
end

--- @briefs spawns the car for practical test
function DrivingSchool.StartPractical(player, currentSchool)
    if not player then return end
    if not Config.Schools[currentSchool] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local school = Config.Schools[currentSchool]
    local schoolVehicle = school.testVehicle
    local testVehicle = SpawnVehicle(schoolVehicle.coords)

    currentPracticalTests[testVehicle] = {
        testee = xPlayer.charid,
        id = xPlayer.source,
        errors = 0,
        active = false,
        vehicle = testVehicle,
        startTime = os.time()
    }

    -- Deletes the vehicle if the testee hasn't started driving even after the time limit.
    Timer.SetTimeout(function ()
--[[         local vehData = Core.GetVehicleData(testVehicle)

        vehData.RemoveVehicle() ]]
        if (currentPracticalTests[testVehicle]) and (not currentPracticalTests[testVehicle].active) then
            testVehicle:Destroy()
            currentPracticalTests[testVehicle] = nil
            xPlayer.showNotification('The test vehicle has been removed for not being used.')
        end
    end, 20000)
end

--- @briefs verifies and processes violation.
function DrivingSchool.ExceededMaxSpeed(player, speed)
    if not player then return end
    if not speed then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local practicalTest = currentPracticalTests[xPlayer.insideVehicle]

    if not practicalTest then
        return
    end

    practicalTest.errors = practicalTest.errors + 1
    xPlayer.showNotification('Slow down, you are going faster than the maximum speed.')
end

--- @briefs verifies and processes violation.
function DrivingSchool.VehicleDamage(vehicle)
    if not vehicle then return end
    if not currentPracticalTests[vehicle] then return end

    local practicalVeh = currentPracticalTests[vehicle]
    local xPlayer = Core.GetPlayerFromId(practicalVeh.id)

    practicalVeh.errors = practicalVeh.errors + 2
    xPlayer.showNotification('Try not to hit anything.')
end

--- @briefs completes the practical test.
function DrivingSchool.CompletePractical(player, currentSchool)
    if not player then return end
    if not Config.Schools[currentSchool] then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())

    if not xPlayer.insideVehicle then return end
    if not currentPracticalTests[xPlayer.insideVehicle] then return end

    local veh = xPlayer.insideVehicle
    local totalErrors = currentPracticalTests[veh].errors
    --local vehData = Core.GetVehicleData(veh)

    --xPlayer.character:LeaveVehicle()
    --Timer.SetTimeout(function ()
        currentPracticalTests[veh].vehicle:Destroy()
        currentPracticalTests[veh] = nil
    --end, 5000)

    Events.CallRemote('DrivingSchool:TestComplete', player, {errors = totalErrors, currentSchool = currentSchool})
end

--- @briefs generates unique ID for licenses.
function DrivingSchool.GenerateLicenseNumber()
    local number = ''
    local prefix = 'PC'
    local randigit = Core.GetRandomInt(111111111, 999999999)

    number =  prefix.. randigit
    return number
end

--- @briefs processes and grants a license to a player.
function DrivingSchool.GrantLicense(player, licenseData)
    print('called to give 1')
    if not player then return end
    if not licenseData then return end
--[[     if player.getMoney() < licenseData.cost or 50 then
        player.showNotification('You don\'t have enough money for this license.')
        return
    end ]]
    print('called to give 2')

    local xPlayer = Core.GetPlayerFromId(player:GetID())

    --player.call('TakeCharacterPicture')
    Timer.SetTimeout(function ()
        local timeToAdd = (86400 * 14) -- 14 days
        local issueTime = os.time()
        local expiryTime = issueTime + timeToAdd
        local issueDate = os.date('%x', issueTime)
        local expiryDate = os.date('%x', expiryTime)

        local metadata = {
            characterImage = 'https://pco-cache.helix-cdn.com/b89d1189-7b79-4f1a-998a-bee96571ea07.jpg', --xPlayer.characterImage,
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
    end, 500)
end



Vehicle.Subscribe("CharacterEnter", function(vehicle, character, seat)
    if seat ~= 0 then return end
    if not currentPracticalTests[vehicle] then return end

    local player = Core.GetPlayerFromCharacter(character)

    if (currentPracticalTests[vehicle].testee == player.charid) then
        currentPracticalTests[vehicle].active = true
        player.showNotification('Drive to the marker.')
    end

    print('character got into vehicle', vehicle, character, seat)
end)

Vehicle.Subscribe("CharacterLeave", function(vehicle, character)
    if not currentPracticalTests[vehicle] then return end

    local player = Core.GetPlayerFromCharacter(character)

    if (currentPracticalTests[vehicle].testee == player.charid) and (currentPracticalTests[vehicle].active) then
        currentPracticalTests[vehicle].active = false
        player.showNotification('The vehicle will get removed in 60 seconds.')
        Timer.SetTimeout(function ()
            if (currentPracticalTests[vehicle]) and (not currentPracticalTests[vehicle].active) then
--[[                 local vehData = Core.GetVehicleData(vehicle)

                vehData.RemoveVehicle() ]]
                vehicle:Destroy()
                currentPracticalTests[vehicle] = nil
                player.showNotification('The test vehicle has been removed for not being used.')
            end
        end, 60000)
    end
end)

Vehicle.Subscribe("Hit", function(vehicle)
    if currentPracticalTests[vehicle] then
        DrivingSchool.VehicleDamage(vehicle)
    end
end)


--- @briefs listening event client > server.
Events.SubscribeRemote('DrivingSchool:StartTest', DrivingSchool.StartPractical)
Events.SubscribeRemote('DrivingSchool:GrantLicense', DrivingSchool.GrantLicense)
Events.SubscribeRemote('DrivingSchool:SpeedViolation', DrivingSchool.ExceededMaxSpeed)
Events.SubscribeRemote('DrivingSchool:CompleteTest', DrivingSchool.CompletePractical)