local Banking = {}

Banking.isInATM = false

function Banking:SetupATMs(ATMs)
    for k, atm in pairs(ATMs) do
        local point = Core.CreateMarker({
            coords = atm.location,
            distance = 150.0,
            marker = {
                type = 'pco-markers::SM_MarkerArrow',
            },
            prompt = {
                text = 'Access ATM',
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
                    isBusy = true

                    Core.RemoveInteraction("F")
                    Events.CallRemote('Banking:ServerEvent', 'open_atm')

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


function Banking:OpenATM(account, card, cardNumber)
    if not account then return end
    if not card then return end

    Timer.SetTimeout(function ()
        Core.CloseInventory()
        self.isInATM = not self.isInATM
        self.uiATM:BringToFront()
        Input.SetMouseEnabled(true)
        Input.SetInputEnabled(false)
        self.uiATM:CallEvent("OpenATM", JSON.stringify(account), JSON.stringify(card), cardNumber)
    end, 500)
end

function Banking:ClostATM()
    Timer.SetTimeout(function ()
        self.isInATM = not self.isInATM
        Input.SetMouseEnabled(false)
        Input.SetInputEnabled(true)
        self.uiATM:CallEvent("CloseATM")
    end, 100)
end

function Banking:Update(account, card, cardNumber)
    if not account then return end

    if card then
        self.uiATM:CallEvent("updateData", JSON.stringify(account), JSON.stringify(card), cardNumber)
        return
    end
end


function Banking:Deposit(depositData)
    if depositData.amount <= 0 then
        Core.ShowNotification('Please enter a valid amount.')
        return
    end

    Events.CallRemote('Banking:ServerEvent', 'deposit', depositData)
end

function Banking:Withdraw(withdrawData)
    if withdrawData.amount <= 0 then
        Core.ShowNotification('Please enter a valid amount.')
        return
    end

    Events.CallRemote('Banking:ServerEvent', 'withdraw', {amount = withdrawData.amount, cardNumber = withdrawData.cardNumber})
end

function Banking:Transfer(transferData)
    if transferData.iban == '' or type(transferData.iban) ~= 'string' then
        Core.ShowNotification('Please enter a valid IBAN to transfer.')
        return
    end

    if transferData.amount <= 0 then
        Core.ShowNotification('Please enter a valid amount.')
        return
    end


    Events.CallRemote('Banking:ServerEvent', 'transfer', transferData)
end

function Banking:ChangeIBAN(iban)
    if iban == '' or type(iban) ~= 'string' then
        Core.ShowNotification('Please enter a valid IBAN to change.')
        return
    end

    if string.len(iban) > 10 then
        Core.ShowNotification('IBAN cannot contain more than 10 characters.')
        return
    end


    Events.CallRemote('Banking:ServerEvent', 'changeIBAN', iban)
    print('change IBAN to', iban)
end

function Banking:ChangePIN(pin, cardNumber)
    if type(pin) ~= 'number' or string.len(tostring(pin)) > 4 or string.len(tostring(pin)) < 4 then
        Core.ShowNotification('Please enter a valid 4 digit PIN to change.')
        return
    end
    
    Events.CallRemote('Banking:ServerEvent', 'changePIN', {pin = pin, cardNumber = cardNumber})
    print('change PIN to', pin)
end


Events.SubscribeRemote('core:playerSpawned', function()
    Banking.uiATM = WebUI("Bank UI", "file://ui/index.html")
    Banking.uiATM:Subscribe("uiATM", function(eventType, eventData)
        if eventType == 'closeUI' then
            Banking:ClostATM()
        end

        if eventType == 'pinNotMatch' then
            Core.ShowNotification('You couldn\'t enter the correct pin.')
        end

        if eventType == 'deposit' and eventData then
            Banking:Deposit(eventData)
        end

        if eventType == 'withdraw' and eventData then
            Banking:Withdraw(eventData)
        end

        if eventType == 'transfer' and eventData then
            Banking:Transfer(eventData)
        end

        if eventType == 'changeIBAN' and eventData then
            Banking:ChangeIBAN(eventData)
        end

        if eventType == 'changePIN' and eventData then
            Banking:ChangePIN(eventData.pin, eventData.cardNumber)
        end
    end)
end)



-- Events
Events.SubscribeRemote('Banking:OpenATM', function(...)
    Banking:OpenATM(...)
end)

Events.SubscribeRemote('Banking:updateData', function(...)
    Banking:Update(...)
end)

Events.SubscribeRemote('Banking:ClientEvent', function(eventType, eventData)
    if eventType == 'receive_atms' and eventData then
        Banking:SetupATMs(eventData)
    end
end)