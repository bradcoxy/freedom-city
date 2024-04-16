local Fishing = {}


function Fishing.InitZones(zones, mongers, fish)
    Fishing.Fish = fish

    for zoneName, zone in pairs(zones) do
        local point = Core.CreateMarker({
            coords = zone.coords,
            distance = 150.0,
            marker = {
                type = 'pco-markers::SM_MarkerCylinder',
            },
            prompt = {
                text = 'Start Fishing',
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
                        Core.ShowNotification('Cannot fish from inside any vehicle.')
                        return
                    end

                    local reelSound = Sound(Vector(), "package://fishing/Client/spinningreel.ogg", true)
                    reelSound:FadeIn(1, 0.8)

                    Timer.SetTimeout(function ()
                        if math.random(1, 100) <= 80 then
                            Core.ShowNotification('Caught a fish in the line.')
                            Events.CallRemote('Fishing:Start', zoneName)
                        else
                            Core.ShowNotification('No fish caught the line.')
                        end
                    end, 2000)

                    isBusy = true
                    Core.ShowNotification('Casted a line.')
                    self:hidePrompt()
                    Timer.SetTimeout(function()
                        self:showPrompt()
                        isBusy = false
                    end, 3500)
                end
            else
                self:hidePrompt()
            end
        end

        function point:onExit()
            self:hidePrompt()
        end
    end

    for _, monger in pairs(mongers) do
        local point = Core.CreateMarker({
            coords = monger.coords,
            distance = 150.0,
            marker = {
                type = 'pco-markers::SM_MarkerCylinder',
            },
            prompt = {
                text = 'Sell Fish',
                key = 'F'
            },
            interactions = 'F'
        })

        function point:nearby()
            if isBusy then return end

            if self.currentDistance <= 150.0 then
                self:showPrompt()

                if self:isKeyJustReleased('F') then
                    if Client.GetLocalPlayer():GetControlledCharacter():GetVehicle() then
                        Core.ShowNotification('Cannot sell fish from inside any vehicle.')
                        return
                    end

                    self:hidePrompt()
                    isBusy = true
                    --Fishing:CreateMenuPrices()
                    Events.CallRemote('Fishing:GetFish')
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

function Fishing.CreateMenuPrices(hasFish)
    local self = Fishing
    local availableFish = {}

    for fishId, fish in pairs(self.Fish) do
        local price = fish.price

        if fish.current_price_inc > 0 then
            price = HELIXMath.Round(fish.price + fish.price / 100 * fish.current_price_inc)
        end
        availableFish[#availableFish+1] = {label = fish.label.." $"..price.." +"..fish.current_price_inc.."%", value = fishId}
    end

    print('on sell fish', HELIXTable.Dump(Core.PlayerData))

    Core.OpenMenu("select", {
        title = "Fish Selling",
        description = "",
        elements = availableFish
    }, function(selection, selectionMenu)
        selectionMenu.close()
        local fishToSell = Fishing.Fish[selection.value]
        local limitOfFish = hasFish[selection.value] or 0
        local price = fishToSell.price

        if fishToSell.current_price_inc > 0 then
            price = HELIXMath.Round(fishToSell.price + fishToSell.price / 100 * fishToSell.current_price_inc)
        end

        Core.OpenMenu('input', {
            title = "Fish Selling",
            description = ("Enter the amount of %s you want to sell (each $%s). You have %s pieces."):format(fishToSell.label, price, limitOfFish),
            inputType = 'number' -- optional
        }, function(amount, amountMenu)
            if not amount then Core.ShowNotification("Please enter a valid number") return end
            if amount > limitOfFish then Core.ShowNotification("Please enter a valid number within the limit") return end

            Events.CallRemote('Fishing:Sell', {fish = selection.value, amount = amount})
            amountMenu.close()
        end, function(amountMenu)
            amountMenu.close()
        end)

    end, function(selectionMenu)
        selectionMenu.close()
    end)

end

Events.SubscribeRemote('Fishing:ZonesMongersFish', Fishing.InitZones)
Events.SubscribeRemote('Fishing:SellC', Fishing.CreateMenuPrices)