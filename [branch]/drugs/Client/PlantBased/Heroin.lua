local Heroin = {}
local plantMarkers = {}

Heroin.isInUI = false

function Heroin.RefreshPlants(plants)
    for _, point in pairs(plantMarkers) do
        point:remove()
    end

    plantMarkers = {}
    for k, plant in pairs(plants) do
        local point = Core.CreateMarker({
            coords = plant.location,
            distance = 150.0,
            prompt = {
                text = 'Heroin Plant',
                key = 'F'
            },
            interactions = 'F'
        })

        plantMarkers[k] = point

        function point:nearby()
            if not plantMarkers[k] then return end
            if isBusy then return end

            if self.currentDistance <= 150.0 then
                self:showPrompt()

                if self:isKeyJustReleased('F') then
                    isBusy = true

                    Core.RemoveInteraction('F')
                    Events.CallRemote('Heroin:RetrivePlant', k)

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
end

function Heroin.ShowPlant(plant)
    if Heroin.isInUI then return end

    Heroin:CreateUI()
    Heroin.isInUI = not Heroin.isInUI

    Timer.SetTimeout(function ()
        Heroin.plantUI:BringToFront()
        Input.SetMouseEnabled(true)
        Input.SetInputEnabled(false)
        Heroin.plantUI:CallEvent('ShowPlant', JSON.stringify(plant), 'poppy')
    end, 100)
end

function Heroin.ClosePlant()
    if not Heroin.isInUI then return end

    Heroin.isInUI = not Heroin.isInUI
    Input.SetMouseEnabled(false)
    Input.SetInputEnabled(true)
    Heroin.plantUI:CallEvent('ClosePlant')

    Timer.SetTimeout(function ()
        Heroin.plantUI:Destroy()
    end, 500)
end

function Heroin.UpdateCurrentPlant(plant)
    if not plant then return end
    if not Heroin.isInUI then return end

    Heroin.plantUI:CallEvent('UpdateCurrentPlant', JSON.stringify(plant), 'poppy')
end

function Heroin:CreateUI()
    self.plantUI = WebUI('heroinPlant', 'file://PlantDetailsUI/index.html')

    self.plantUI:Subscribe('feedPlant', function(plantID)
        print('called to feed plant')
        Events.CallRemote('Heroin:FeedPlant', plantID)
    end)

    self.plantUI:Subscribe('waterPlant', function(plantID)
        Events.CallRemote('Heroin:WaterPlant', plantID)
    end)

    self.plantUI:Subscribe('harvestPlant', function(plantID)
        Events.CallRemote('Heroin:HarvestPlant', plantID)
    end)

    self.plantUI:Subscribe('destroyPlant', function(plantID)
        self.ClosePlant()
        Core.OpenMenu("confirm", {
            title = "Heroin Plant",
            description = 'Are you sure you want to destroy this plant?',
        }, function(confirm)
            confirm.close()
            Events.CallRemote('Heroin:DestroyPlant', plantID)
        end, function(confirm)
            confirm.close()
        end)
    end)

    self.plantUI:Subscribe('CloseUI', function ()
        self.ClosePlant()
    end)
end

Events.SubscribeRemote('Heroin:UpdateCurrentPlant', Heroin.UpdateCurrentPlant)
Events.SubscribeRemote('Heroin:ClosePlant', Heroin.ClosePlant)
Events.SubscribeRemote('Heroin:ShowPlant', Heroin.ShowPlant)
Events.SubscribeRemote('Heroin:ReceivePlants', Heroin.RefreshPlants)