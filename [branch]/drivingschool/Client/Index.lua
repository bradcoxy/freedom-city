local DrivingSchool = {}

DrivingSchool.questionsAttempted = 0
DrivingSchool.correctAnswersTheoritical = 0

DrivingSchool.theoriticalPassed = true
DrivingSchool.practicalPassed = false
DrivingSchool.recentSpeedViolation = false
DrivingSchool.practicalStarted = false

DrivingSchool.lastQuestion = nil
DrivingSchool.practicalMarker = nil
DrivingSchool.maxSpeedTimer = nil


--- @briefs registering markers.
Events.SubscribeRemote('core:playerSpawned', function ()
    for k, school in pairs(Config.Schools) do
        local point = Core.CreateMarker({
            coords = school.coords,
            distance = 150.0,
            marker = {
                type = 'pco-markers::SM_MarkerCylinder',
            },
            prompt = {
                text = school.label,
                key = 'F'
            },
            interactions = 'F'
        })
        point:showMarker()

        function point:nearby()
            if isBusy then return end

            if self.currentDistance <= 150.0 then
                self:showPrompt()

                if self:isKeyJustReleased('F') then
                    if Client.GetLocalPlayer():GetControlledCharacter():GetVehicle() then
                        Core.ShowNotification('Exit vehicle.')
                        return
                    end

                    isBusy = true
                    self:hidePrompt()
                    DrivingSchool:StartTest(k)
                    isBusy = false
                end
            else
                self:hidePrompt()
            end
        end

        function point:onExit()
            self:hidePrompt()
        end
    end
end)

Package.Subscribe("Load", function ()
    Timer.SetTimeout(function ()
        for k, school in pairs(Config.Schools) do
            local point = Core.CreateMarker({
                coords = school.coords,
                distance = 150.0,
                marker = {
                    type = 'pco-markers::SM_MarkerCylinder',
                },
                prompt = {
                    text = school.label,
                    key = 'F'
                },
                interactions = 'F'
            })
            point:showMarker()
    
            function point:nearby()
                if isBusy then return end
    
                if self.currentDistance <= 150.0 then
                    self:showPrompt()
    
                    if self:isKeyJustReleased('F') then
                        if Client.GetLocalPlayer():GetControlledCharacter():GetVehicle() then
                            Core.ShowNotification('Exit vehicle.')
                            return
                        end
    
                        isBusy = true
                        self:hidePrompt()
                        DrivingSchool:StartTest(k)
                        isBusy = false
                    end
                else
                    self:hidePrompt()
                end
            end
    
            function point:onExit()
                self:hidePrompt()
            end
        end
    end, 2000)
end)

--- @briefs goes through available questions and processes answers.
function DrivingSchool:AskQuestion()
    local random = self.lastQuestion and self.lastQuestion + 1 or 1
    local question = Config.Questions[random]
    local answers = {}

    self.lastQuestion = random
    for _, option in pairs(question.options) do
        answers[#answers + 1] = {label = option.answer, value = option.isAns or false}
    end

    Timer.SetTimeout(function ()
        Core.OpenMenu("select", {
            title = "Driving License Test",
            description = question.query,
            elements = answers,
        }, function(data, menu)
            menu.close()
            self.questionsAttempted = self.questionsAttempted + 1
            self.correctAnswersTheoritical = data.value and self.correctAnswersTheoritical + 1 or self.correctAnswersTheoritical

            if self.questionsAttempted >= #Config.Questions then
                self:QuestionsFinished()
                return
            end
            self:AskQuestion()
        end, function(menu)
            self.lastQuestion = nil
            self:QuestionsFinished()
            menu.close()
        end)
    end, 1000)
end

--- @briefs process max speed violation.
function DrivingSchool:ExceededMaxSpeed(speed)
    if self.recentSpeedViolation then return end

    Events.CallRemote('DrivingSchool:SpeedViolation', speed)
    self.recentSpeedViolation = true
    Timer.SetTimeout(function ()
        self.recentSpeedViolation = false
    end, 15000)
end

--- @briefs the maximum speed timer logic.
function DrivingSchool:MaximumSpeedTimer()
    local last_pos = nil
    local maxSpeed = Config.maxSpeedDuringTest or 30.0

    self.maxSpeedTimer = Timer.SetInterval(function ()
        local char = Client.GetLocalPlayer():GetControlledCharacter()
        local car = char:GetVehicle()

        if (char) and (car) then
            local current_pos = char:GetLocation()

            if last_pos and car:GetVelocity() then
                local distance = current_pos:Distance(last_pos)
                local speed = (distance / 250) * 10
                local mph = HELIXMath.Round((speed * 2.23694))

                if mph >= maxSpeed then
                    self:ExceededMaxSpeed(mph)
                end
            end

            last_pos = current_pos
        end
    end, 250)
end


--- @briefs gets the next point for the practical test.
function DrivingSchool:GetNextPoint(pointsTable)
    local maxPoints = #pointsTable
    local currentPoint = self.currentPoint or 1
    local nextPoint = self.currentPoint and self.currentPoint + 1 or currentPoint

    print('max point', maxPoints)
    print('current point is', currentPoint)
    print('next point selected is', nextPoint)

    if nextPoint >= maxPoints then
        nextPoint = maxPoints
    end

    self.currentPoint = nextPoint

    return self.currentPoint
end

--- @briefs processes practical driving test point.
function DrivingSchool:ReachedPoint(point, lastPoint, currentSchool)
    if not point then return end
    if not lastPoint then return end
    if not currentSchool then return end

    -- if it is the last point then completes the test.
    if point >= lastPoint then
        self.currentPoint = nil
        self.practicalMarker = nil
        Events.CallRemote('DrivingSchool:CompleteTest', currentSchool)
        return
    end

    -- otherwise proceed to the next point.
    Timer.SetTimeout(function ()
        self:RegisterPracticalMarker(currentSchool)
        Core.ShowNotification('Proceed to the next point.')
    end, 1500)
end

--- @briefs uses the core to create the finish marker.
function DrivingSchool:RegisterPracticalMarker(currentSchool)
    if not Config.Schools[currentSchool] then return end
    if not Config.Schools[currentSchool].testPoints then return end

    local testPoints = Config.Schools[currentSchool].testPoints
    local nextPoint = self:GetNextPoint(testPoints)
    local pointLocation = testPoints[nextPoint]
    local char = Client.GetLocalPlayer():GetControlledCharacter()

    print(nextPoint, pointLocation)

    local point = Core.CreateMarker({
        coords = pointLocation,
        distance = 150.0,
        marker = {
            type = 'pco-markers::SM_MarkerCylinder',
        },
        prompt = {
            text = 'Reached Point',
            key = 'F'
        },
        interactions = 'F'
    })

    self.practicalMarker = point
    self.practicalMarker:showMarker()
    

    function point:nearby()
        if isBusy then return end

        if self.currentDistance <= 150.0 then
            self:showPrompt()

            if self:isKeyJustReleased('F') then
                if not char:GetVehicle() then
                    Core.ShowNotification('Complete from inside the vehicle.')
                    return
                end
                isBusy = true

                self:hidePrompt()
                self:hideMarker()
                self:remove()

                DrivingSchool.practicalMarker = nil
                DrivingSchool:ReachedPoint(nextPoint, #testPoints, currentSchool)

                Timer.SetTimeout(function ()
                    isBusy = false
                end, 1000)
            end
        else
            self:hidePrompt()
        end
    end
    
    function point:onExit()
        self:hidePrompt()
    end
end


--- @briefs starts the practical driving test.
function DrivingSchool:StartPractical(currentSchool)
    if not Config.Schools[currentSchool] then return end
    if not Config.Schools[currentSchool].testPoints then return end
    if not self.theoriticalPassed then return end

    self.practicalStarted = true
    Events.CallRemote('DrivingSchool:StartTest', currentSchool)

    if self.practicalMarker then
        self.practicalMarker:remove()
    end

    self:RegisterPracticalMarker(currentSchool)
    self:MaximumSpeedTimer()

    Core.ShowNotification('The practical test has started, get into the vehicle.')
end

--- @briefs called when the practical test has been finished, processes the points.
function DrivingSchool.CompletedPractical(practicalResults)
    if not practicalResults then return end
    if not Config.Schools[practicalResults.currentSchool] then return end
    if not DrivingSchool.theoriticalPassed then return end

    local currentSchool = Config.Schools[practicalResults.currentSchool]
    local totalErrors = practicalResults.errors
    local allowedLicenses = {}

    for _, license in pairs(currentSchool.licenses) do
        if totalErrors <= license.maxErrors then
            allowedLicenses[#allowedLicenses + 1] = {label = license.label, value = _}
        end

        if not license.item then
            license.item = _
        end
    end

    DrivingSchool.practicalStarted = false
    DrivingSchool.theoriticalPassed = false

    Timer.ClearInterval(DrivingSchool.maxSpeedTimer)
    DrivingSchool.maxSpeedTimer = nil

    Core.OpenMenu("select", {
        title = "Driving License Test",
        description = ('You qualify for these licenses, total errors %s.'):format(totalErrors),
        elements = allowedLicenses,
    }, function(data, menu)
        menu.close()

        Events.CallRemote('DrivingSchool:GrantLicense', currentSchool.licenses[data.value])
    end, function(menu)
        menu.close()
    end)
end

--- @briefs test finished, processes results.
function DrivingSchool:QuestionsFinished()
    local passingPoints = Config.minimumPointsForTheoritical or 3

    self.lastQuestion = nil
    self.questionsAttempted = 0

    if self.correctAnswersTheoritical < passingPoints then
        Core.ShowNotification('You have failed the theoritical exam.')
        return
    end

    self.theoriticalPassed = true
    Core.ShowNotification('You have passed the theoritical exam.')
end

--- @briefs starts the test.
function DrivingSchool:StartTest(currentSchool)
    if not Config.Questions then return end

    local desc = self.theoriticalPassed and 'Start the practical test?' or 'Start the theoritical test?'

    Core.OpenMenu("confirm", {
        title = "Driving School",
        description = desc,
    }, function(confirm)
        confirm.close()

        if not self.theoriticalPassed then
            self:AskQuestion()
        else
            self.theoriticalPassed = true
            self:StartPractical(currentSchool)
        end
    end, function(confirm)
        confirm.close()
    end)
end

------ Listening event, server to client -------
Events.SubscribeRemote('DrivingSchool:TestComplete', DrivingSchool.CompletedPractical)