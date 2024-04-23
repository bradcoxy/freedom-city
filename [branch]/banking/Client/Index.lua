local Banking = {}
local isBusy = false
Banking.isInATM = false


function Banking.SetupBranches(Branches)
    for k, branch in pairs(Branches) do
        local point = Core.CreateMarker({
            coords = branch.location,
            distance = 150.0,
            marker = {
                type = 'pco-markers::SM_MarkerArrow',
            },
            prompt = {
                text = 'Access Bank',
                key = 'F'
            },
            interactions = 'F'
        })

        function point:nearby()
            if isBusy then return end

            if self.currentDistance <= 150.0 then
                self:showPrompt()

                if self:isKeyJustReleased('F') then
                    isBusy = true
                    Events.CallRemote('Banking:OpenBranch')
                    self:hidePrompt()
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
    end, 250)
end

function Banking.SelectTransferAmount(balance)
    Core.OpenMenu("input", {
        title = "BANKING",
        description = ("Specify the transfer amount. Balance: $%s"):format(balance),
        inputType = 'number',
    }, function(amount, menu)
        if amount <= 0 or type(amount) ~= "number" then Core.ShowNotification('Please provide a valid number.') return end
        if amount > balance then Core.ShowNotification('You do not have that balance.') return end

        menu.close()

        Core.OpenMenu("input", {
            title = "BANKING",
            description = "Specify the IBAN you want to transfer to.",
            inputType = 'string',
        }, function(iban, ibm)
            if string.len(iban) > 10 then Core.ShowNotification('IBAN is not longer than 10 characters.') return end

            Events.CallRemote('Banking:Transfer', {
                amount = amount,
                type = 'iban',
                iban = iban
            })

            isBusy = false
            ibm.close()
        end, function(ibm)
            isBusy = false
            ibm.close()
        end)
    end, function(menu)
        isBusy = false
        menu.close()
    end)
end

function Banking.DepositChecking(cash)
    Core.OpenMenu("input", {
        title = "BANKING",
        description = ("Specify the amount you want to deposit. Cash: $%s"):format(cash),
        inputType = 'number',
    }, function(amount, ibm)
        if amount <= 0 or type(amount) ~= "number" then Core.ShowNotification('Please provide a valid number.') return end
        if amount > cash then Core.ShowNotification('You do not have that cash.') return end

        Events.CallRemote('Banking:Deposit', {
            amount = amount,
            type = 'checking',
        })

        isBusy = false
        ibm.close()
    end, function(ibm)
        isBusy = false
        ibm.close()
    end)
end

function Banking.WithdrawChecking(balance)
    Core.OpenMenu("input", {
        title = "BANKING",
        description = ("Specify the amount you want to withdraw. Balance: $%s"):format(balance),
        inputType = 'number',
    }, function(amount, wbm)
        if amount <= 0 or type(amount) ~= "number" then Core.ShowNotification('Please provide a valid number.') return end
        if amount > balance then Core.ShowNotification('You do not have that balance.') return end

        Events.CallRemote('Banking:Withdraw', {
            amount = amount,
        })

        isBusy = false
        wbm.close()
    end, function(wbm)
        isBusy = false
        wbm.close()
    end)
end

function Banking.SelectLoadAmount(balance)
    if (balance < 0) then
        Core.ShowNotification('You cannot take any loans at the moment.')
        return
    end

    local eligibleAmount = math.floor(balance / 4)
    Core.OpenMenu("input", {
        title = "BANKING",
        description = ("Specify the load amount. Eligible: $%s"):format(eligibleAmount),
        inputType = 'number',
    }, function(amount, menu)
        if amount <= 0 or type(amount) ~= "number" then Core.ShowNotification('Please provide a valid number.') return end
        if amount > balance then Core.ShowNotification('You are not eligible for that.') return end

        Events.CallRemote('Banking:Loan', amount)

        isBusy = false
        menu.close()
    end, function(menu)
        isBusy = false
        menu.close()
    end)
end

function Banking.OpenBranch(account, cash)
    if not account then return end

    Core.OpenMenu('select', {
        title = 'BANKING',
        description = ('Checking Account: $%s'):format(account.balances.checking),
        elements = {
            {
                label = 'Deposit',
                value = 'deposit'
            },
            {
                label = 'Withdraw',
                value = 'withdraw'
            },
            {
                label = 'Transfer',
                value = 'transferBalance'
            },
            {
                label = 'Take Loan',
                value = 'takeLoan'
            }
        },
    }, function(data, menu)
        menu.close()

        if (data.value == 'transferBalance') then
            Banking.SelectTransferAmount(account.balances.checking)
        elseif (data.value == 'withdraw') then
            Banking.WithdrawChecking(account.balances.checking)
        elseif (data.value == 'deposit') then
            Banking.DepositChecking(cash)
        elseif (data.value == 'takeLoan') then
            Banking.SelectLoadAmount(account.balances.checking)
        end

        isBusy = false
    end, function(menu)
        isBusy = false
        menu.close()
    end)
    print('open branch', HELIXTable.Dump(account))
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

    Events.CallRemote('Banking:Deposit', depositData)
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

    if string.len(transferData.iban) > 10 then
        transferData.type = 'card'
    end

    Events.CallRemote('Banking:Transfer', transferData)
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

Events.SubscribeRemote('Banking:OpenBranch', Banking.OpenBranch)
Events.SubscribeRemote('Banking:ReceiveBranches', Banking.SetupBranches)