local Cocaine = {}
local plantMarkers = {}

Cocaine.isInUI = false

function Cocaine.RefreshPlants(plants)
    for _, point in pairs(plantMarkers) do
        point:remove()
    end

    plantMarkers = {}
    for k, plant in pairs(plants) do
        local point = Core.CreateMarker({
            coords = plant.location,
            distance = 150.0,
            prompt = {
                text = 'Cocaine Plant',
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
                    Events.CallRemote('Cocaine:RetrivePlant', k)

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

function Cocaine.ShowPlant(plant)
    if Cocaine.isInUI then return end

    Cocaine:CreateUI()
    Cocaine.isInUI = not Cocaine.isInUI

    Timer.SetTimeout(function ()
        Cocaine.plantUI:BringToFront()
        Input.SetMouseEnabled(true)
        Input.SetInputEnabled(false)
        Cocaine.plantUI:CallEvent('ShowPlant', JSON.stringify(plant), 'coca')
    end, 100)
end

function Cocaine.ClosePlant()
    if not Cocaine.isInUI then return end

    Cocaine.isInUI = not Cocaine.isInUI
    Input.SetMouseEnabled(false)
    Input.SetInputEnabled(true)
    Cocaine.plantUI:CallEvent('ClosePlant')

    Timer.SetTimeout(function ()
        Cocaine.plantUI:Destroy()
    end, 500)
end

function Cocaine.UpdateCurrentPlant(plant)
    if not plant then return end
    if not Cocaine.isInUI then return end

    Cocaine.plantUI:CallEvent('UpdateCurrentPlant', JSON.stringify(plant), 'coca')
end

function Cocaine:CreateUI()
    self.plantUI = WebUI('cocainePlant', 'file://PlantDetailsUI/index.html')

    self.plantUI:Subscribe('feedPlant', function(plantID)
        print('called to feed plant')
        Events.CallRemote('Cocaine:FeedPlant', plantID)
    end)

    self.plantUI:Subscribe('waterPlant', function(plantID)
        Events.CallRemote('Cocaine:WaterPlant', plantID)
    end)

    self.plantUI:Subscribe('harvestPlant', function(plantID)
        Events.CallRemote('Cocaine:HarvestPlant', plantID)
    end)

    self.plantUI:Subscribe('destroyPlant', function(plantID)
        self.ClosePlant()
        Core.OpenMenu("confirm", {
            title = "Cocaine Plant",
            description = 'Are you sure you want to destroy this plant?',
        }, function(confirm)
            confirm.close()
            Events.CallRemote('Cocaine:DestroyPlant', plantID)
        end, function(confirm)
            confirm.close()
        end)
    end)

    self.plantUI:Subscribe('CloseUI', function ()
        self.ClosePlant()
    end)
end

Events.SubscribeRemote('Cocaine:UpdateCurrentPlant', Cocaine.UpdateCurrentPlant)
Events.SubscribeRemote('Cocaine:ClosePlant', Cocaine.ClosePlant)
Events.SubscribeRemote('Cocaine:ShowPlant', Cocaine.ShowPlant)
Events.SubscribeRemote('Cocaine:ReceivePlants', Cocaine.RefreshPlants)