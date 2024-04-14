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
            text = {
                text = 'Press [F] to start fishing.'
            },
            interactions = 'F'
        })
        point:showMarker()

        function point:nearby()
            if isBusy then return end

            if self.currentDistance <= 150.0 then
                self:showText()

                if self:isKeyJustReleased('F') then
                    if Client.GetLocalPlayer():GetControlledCharacter():GetVehicle() then
                        Core.ShowNotification('Cannot fish from inside any vehicle.')
                        return
                    end

                    isBusy = true
                    Events.CallRemote('Fishing:Start', zoneName)

                    self:hideText()
                    Timer.SetTimeout(function()
                        self:showText()
                        isBusy = false
                    end, 3000)
                end
            else
                self:hideText()
            end
        end

        function point:onExit()
            self:hideText()
        end
    end

    for _, monger in pairs(mongers) do
        local point = Core.CreateMarker({
            coords = monger.coords,
            distance = 150.0,
            marker = {
                type = 'pco-markers::SM_MarkerCylinder',
            },
            text = {
                text = 'Press [F] to sell fish.'
            },
            interactions = 'F'
        })

        function point:nearby()
            if isBusy then return end

            if self.currentDistance <= 150.0 then
                self:showText()

                if self:isKeyJustReleased('F') then
                    if Client.GetLocalPlayer():GetControlledCharacter():GetVehicle() then
                        Core.ShowNotification('Cannot sell fish from inside any vehicle.')
                        return
                    end

                    isBusy = false
                    Fishing:CreateMenuPrices()
                    isBusy = true
                end
            else
                self:hideText()
            end
        end

        function point:onExit()
            self:hideText()
        end
    end
end

function Fishing:CreateMenuPrices()
    local availableFish = {}

    for fishId, fish in pairs(self.Fish) do
        local price = fish.price

        if fish.current_price_inc > 0 then
            price = HELIXMath.Round(fish.price + fish.price / 100 * fish.current_price_inc)
        end
        availableFish[#availableFish+1] = {label = fish.label.." $"..price.." +"..fish.current_price_inc.."%", value = fishId}
    end

    Core.OpenMenu("select", {
        title = "Fish Selling",
        description = "",
        elements = availableFish
    }, function(selection, selectionMenu)
        selectionMenu.close()
        local fishToSell = Fishing.Fish[selection.value]
        local hasFish = 10 -- hardcoded
        local price = fishToSell.price

        if fishToSell.current_price_inc > 0 then
            price = HELIXMath.Round(fishToSell.price + fishToSell.price / 100 * fishToSell.current_price_inc)
        end

        Core.OpenMenu('input', {
            title = "Fish Selling",
            description = ("Enter the amount of %s you want to sell (each $%s). You have %s pieces."):format(fishToSell.label, price, hasFish),
            inputType = 'number' -- optional
        }, function(amount, amountMenu)
            if not amount then Core.ShowNotification("Please enter a valid number") return end
            if amount> hasFish then Core.ShowNotification("Please enter a valid number within the limit") return end

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