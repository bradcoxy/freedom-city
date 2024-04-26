local Weed = {}
local plantMarkers = {}

Weed.isInUI = false

function Weed.RefreshPlants(plants)
    for _, point in pairs(plantMarkers) do
        point:remove()
    end

    plantMarkers = {}
    for k, plant in pairs(plants) do
        local point = Core.CreateMarker({
            coords = plant.location,
            distance = 150.0,
            prompt = {
                text = 'Weed Plant',
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
                    Events.CallRemote('Weed:RetrivePlant', k)

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

function Weed.ShowPlant(plant)
    if Weed.isInUI then return end

    Weed:CreateUI()
    Weed.isInUI = not Weed.isInUI

    Timer.SetTimeout(function ()
        Weed.plantUI:BringToFront()
        Input.SetMouseEnabled(true)
        Input.SetInputEnabled(false)
        Weed.plantUI:CallEvent('ShowPlant', JSON.stringify(plant), 'cannabis')
    end, 100)
end

function Weed.ClosePlant()
    if not Weed.isInUI then return end

    Weed.isInUI = not Weed.isInUI
    Input.SetMouseEnabled(false)
    Input.SetInputEnabled(true)
    Weed.plantUI:CallEvent('ClosePlant')

    Timer.SetTimeout(function ()
        Weed.plantUI:Destroy()
    end, 500)
end

function Weed.UpdateCurrentPlant(plant)
    if not plant then return end
    if not Weed.isInUI then return end

    Weed.plantUI:CallEvent('UpdateCurrentPlant', JSON.stringify(plant), 'cannabis')
end

function Weed:CreateUI()
    self.plantUI = WebUI('weedPlant', 'file://PlantDetailsUI/index.html')

    self.plantUI:Subscribe('feedPlant', function(plantID)
        print('called to feed plant')
        Events.CallRemote('Weed:FeedPlant', plantID)
    end)

    self.plantUI:Subscribe('waterPlant', function(plantID)
        Events.CallRemote('Weed:WaterPlant', plantID)
    end)

    self.plantUI:Subscribe('harvestPlant', function(plantID)
        Events.CallRemote('Weed:HarvestPlant', plantID)
    end)

    self.plantUI:Subscribe('destroyPlant', function(plantID)
        self.ClosePlant()
        Core.OpenMenu("confirm", {
            title = "Weed Plant",
            description = 'Are you sure you want to destroy this plant?',
        }, function(confirm)
            confirm.close()
            Events.CallRemote('Weed:DestroyPlant', plantID)
        end, function(confirm)
            confirm.close()
        end)
    end)

    self.plantUI:Subscribe('CloseUI', function ()
        self.ClosePlant()
    end)
end

Events.SubscribeRemote('Weed:UpdateCurrentPlant', Weed.UpdateCurrentPlant)
Events.SubscribeRemote('Weed:ClosePlant', Weed.ClosePlant)
Events.SubscribeRemote('Weed:ShowPlant', Weed.ShowPlant)
Events.SubscribeRemote('Weed:ReceivePlants', Weed.RefreshPlants)