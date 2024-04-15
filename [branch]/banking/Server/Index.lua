local Banking = {}

Banking.Accounts = {}
Banking.IBANs = {}
Banking.Cards = {}
Banking.ATMs = {
    ["south_east_atm_1"] = {
        location = Vector(206.8, -257.4, 10.0),
        rotation = Rotator(0.0, 0.0, 0.0),
        label = "South East Park ATM",
    },
}

Banking.TaxRate = 10
Banking.InterestRate = 1.18
Banking.MinCardPayment = 15

Package.Subscribe('Load', function()
    local savedAccounts = DB:Select('SELECT * FROM user_banking')
    for _, account in pairs(savedAccounts) do

        Banking.Accounts[account.identifier] = {
            iban = account.iban,
            number = account.number,
            transactions = account.transactions and JSON.parse(account.transactions) or {},
            stats = account.stats and JSON.parse(account.stats) or {
                income = {title = 'income'},
                outcome = {title = 'outcome'},
                earnings = {title = 'earnings'},
            },
            balances = account.balances and JSON.parse(account.balances) or {
                saving = 0,
                checking = 0,
            },
            cards = account.cards and JSON.parse(account.cards) or {}
        }

        for cardNumber in pairs(Banking.Accounts[account.identifier].cards) do
            Banking.Cards[cardNumber] = account.identifier
        end

        Banking.IBANs[account.iban] = account.identifier
    end

    Core.CreateItem({
        ['credit_card'] = {
            label = 'Credit Card',
            unique = true,
            description = 'Classic Credit Card to spend.',
            type = 'item',
        }
    })

    for _, atm in pairs(Banking.ATMs) do
        local prop = Prop(
            atm.location,
            atm.rotation,
            'helix::SM_HalfStack_Marshall',
            CollisionType.Normal,
            false,
            GrabMode.Disabled
        )
        prop:SetScale(Vector(1, 1, 1.5))
    end
end)

--Functions

Core.CreateUseableItem('credit_card', function(player, item, slot, extra)
    local inventory = player.inventory
    local card = inventory[extra][slot]
    print(HELIXTable.Dump(card))
    local cardData = card.metadata

    print('used a card')
    print(cardData, cardData.number)

    Banking:UseCard(player, cardData.number)
end)

function Banking:GiveCreditCard(player)
    if not player then return end
    if not self.Accounts[player.charid] then return end

    local account = self.Accounts[player.charid]
    local cardTempPin = math.random(1111, 9999)
    local cardNumber = self.GenerateCardNumber()
    local cardData = {
        number = cardNumber,
    }

    --- Assign a temporary pin to the card and email it to the account holder.

    account.cards[cardNumber] = {
        owner = player.charid,
        lastfour = string.sub(cardNumber, -4),
        account = account.number,
        pin = cardTempPin,
        limit = 5000,
        nextPayment = (os.time() + (60 * 60 * 24 * 7)) or false,
        balance = 0,
    }
    self.Cards[cardNumber] = player.charid

    print(cardNumber, account.cards[cardNumber], self.Cards[cardNumber])

    player.inventory.AddItem('credit_card', 1, cardData)
    player.showNotification('Your card\'s temporary pin is '.. cardTempPin)
end

function Banking:GetClosestATM(player)
    if not player then return end

    local characterLocation = player.character:GetLocation()
    local ret = nil

    for name, atm in pairs(self.ATMs) do
        if characterLocation:Distance(atm.location) <= 200.0 then
            ret = name
        end
    end

    return ret
end

function Banking:UseCard(player, cardNumber)
    if not player then return end
    if not cardNumber then return end
    if not self.Cards[cardNumber] then return end
    print('used card.')
    local closestATM = self:GetClosestATM(player)
    if closestATM then
        print('card used found an ATM nearby.')
        self:OpenATM(player, cardNumber)
        return
    end
end

function Banking.CalculateCardPayment(player, card)
    if not player then return end

    local balance = math.abs(card.balance)
    local n = (0.025 * balance)
    local minpayment = HELIXMath.Clamp(n, Banking.MinCardPayment, card.limit)
    local n_interest = minpayment * Banking.InterestRate
    local payment =  math.floor(n_interest + balance)

    return minpayment, payment
end

function Banking:CardBillingCycle(player)
    if not player then return end

    local account = self.Accounts[player.charid]
    local cards = account.cards

    if not account.cards then return end

    for number, card in pairs(cards) do
        if card.balance < 0 and card.nextPayment then
            if os.time() >= card.nextPayment then
                local minPayment, payment = Banking.CalculateCardPayment(player, card) --* days_difference

                if account.balances.checking > payment then
                    local transactionID = #account.transactions + 1

                    account.balances.checking = account.balances.checking - minPayment
                    account.transactions[transactionID] = {
                        transactionid = transactionID,
                        accountname = 'Card Payment of '..card.lastfour,
                        amount = minPayment,
                        inflow = false,
                    }
                    card.balance = card.balance + minPayment

                    player.showNotification("Your Credit Card bill is: $"..payment, "Credit Card", "info")
                    SendLog({
                        ["username"] = "Banking System",
                        ['embeds'] = {
                            {
                                ['title'] = 'Card Payment Deducted',
                                ['fields'] = {
                                    {
                                        ['name'] = 'Bank Account Holder',
                                        ['value'] = player.getName(),
                                        ['inline'] =  true
                                    },
                                    {
                                        ['name'] = 'Account ID',
                                        ['value'] = player.identifier,
                                        ['inline'] =  true
                                    },
                                    {
                                        ['name'] = 'Character ID',
                                        ['value'] = player.get('charId'),
                                        ['inline'] =  true
                                    },
                                    {
                                        ['name'] = 'Deducted for Card',
                                        ['value'] = number,
                                        ['inline'] =  true
                                    },
                                    {
                                        ['name'] = 'Deducted from Checking Minimum Payment Of',
                                        ['value'] = '$'.. minPayment,
                                        ['inline'] =  true
                                    },
                                }
                            }
                        }
                    })
                    print("PAYMENT INFO:", minPayment, payment, self.Cards[number].balance, card.balance)
                end
            end
        end
    end
end


function Banking:PlayerSpawned(player)
    if not player then return end
    if not self.Accounts[player.charid] then
        print('account not found')
        self.Accounts[player.charid] = {
            iban = self.GenerateIBAN(),
            number = self.GenerateAccountNumber(),
            transactions = {},
            stats = {
                income = {title = 'income'},
                outcome = {title = 'outcome'},
                earnings = {title = 'earnings'},
            },
            balances = {
                checking = 0,
            },
            cards = {},
            isNew = true,
        }
    end

    Timer.SetTimeout(function ()
        self:CardBillingCycle(player)
    end, 5000)

    self.Accounts[player.charid].id = player.source
    self.IBANs[self.Accounts[player.charid].iban] = player.charid
    player.call('Banking:ClientEvent', 'receive_atms', self.ATMs)
end

function Banking.GenerateIBAN()
    local ranINT = math.random(11111, 99999)
    local prefix = 'IBN'

    return prefix .. ranINT
end

function Banking.GenerateAccountNumber()
    local ranINT = math.random(11111111, 99999999)
    local prefix = 'PC00'

    return prefix .. ranINT
end

function Banking.GenerateCardNumber()
    return string.format('%s %s %s %s', math.random(1111, 9999), math.random(3452, 9999), math.random(2181, 9999), math.random(2716, 9999))
end

function Banking:OpenATM(player, cardNumber)
    if not player then return end
    if not cardNumber then return end
    if not self.Accounts[player.charid] then return end

    local account = self.Accounts[player.charid]
    local card = account.cards[cardNumber]

    account.name = player.name
    account.cash = player.getMoney()
    account.id = player.getID()

    player.call('Banking:OpenATM', account, card, cardNumber)
    SendLog({
        ["username"] = "Banking System",
        ['embeds'] = {
            {
                ['title'] = 'ATM Accessed',
                ['fields'] = {
                    {
                        ['name'] = 'Bank Account Holder',
                        ['value'] = player.getName(),
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Account ID',
                        ['value'] = player.identifier,
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Character ID',
                        ['value'] = player.get('charId'),
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Accessed with Card',
                        ['value'] = cardNumber,
                        ['inline'] =  true
                    },
                }
            }
        }
    })
end

function Banking:SetAccountPIN(player, account)
    if not player then return end
    if not account.pin then return end

    self.Accounts[player.charid].pin = tostring(account.pin)
    player.showNotification('Your account\'s pin is now ' .. account.pin)
end

function Banking:Deposit(player, depositData)
    if not player then return end
    if not depositData.amount then return end
    if not self.Accounts[player.charid] then return end

    local account = self.Accounts[player.charid]
    local amount = depositData.amount
    local card = account.cards[depositData.cardNumber]
    local currentCash = player.getMoney()
    local transactionID = #account.transactions + 1
    local statsIncome = account.stats.income.amount or 0
    local totalIncome = statsIncome + amount

    if currentCash < amount then
        player.showNotification('You don\'t have enough to deposit.')
        return
    end

    if card then
        card.balance = card.balance + amount
        player.removeMoney(amount)

        account.cash = player.getMoney()
        account.stats.income.amount = totalIncome
        account.transactions[transactionID] = {
            transactionid = transactionID,
            accountname = 'Deposit into Card '.. card.lastfour,
            amount = amount,
            inflow = true,
        }

        player.showNotification(('You\'ve deposited $%s into Card %s.'):format(amount, card.lastfour))
        player.call('Banking:updateData', account, card, depositData.cardNumber)
        SendLog({
            ["username"] = "Banking System",
            ['embeds'] = {
                {
                    ['title'] = 'Deposit into Card',
                    ['fields'] = {
                        {
                            ['name'] = 'Bank Account Holder',
                            ['value'] = player.getName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Account ID',
                            ['value'] = player.identifier,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Character ID',
                            ['value'] = player.get('charId'),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Card',
                            ['value'] = depositData.cardNumber,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Amount',
                            ['value'] = amount,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'New Balance',
                            ['value'] = card.balance,
                            ['inline'] =  true
                        },
                    }
                }
            }
        })
        return
    end

    player.removeMoney(amount)
    account.balances.checking = account.balances.checking + amount

    account.name = player.name
    account.cash = player.getMoney()
    account.transactions[transactionID] = {
        transactionid = transactionID,
        accountname = 'Credit',
        amount = amount,
        inflow = true,
    }
    account.stats.income.amount = totalIncome
    player.call('Banking:ClientEvent', 'updateData', account)
    player.showNotification('You\'ve deposited $'.. amount ..'.')
    print('total income ', account.stats.income)
end

function Banking:Withdraw(player, withdrawData)
    if not player then return end
    if not withdrawData.amount then return end
    if not self.Accounts[player.charid] then return end

    local account = self.Accounts[player.charid]
    local card = account.cards[withdrawData.cardNumber]
    local amount = withdrawData.amount
    local transactionID = #account.transactions + 1
    local statsOutcome = account.stats.outcome.amount or 0
    local totalOutcome = statsOutcome + amount

    if card then
        local balance = card.balance
        local limit = card.limit

        if balance >= amount then
            card.balance = card.balance - amount
            player.addMoney(amount)

            account.cash = player.getMoney()
            account.stats.outcome.amount = totalOutcome
            account.transactions[transactionID] = {
                transactionid = transactionID,
                accountname = 'Withdraw from Card '.. card.lastfour,
                amount = amount,
                inflow = false,
            }

            player.showNotification('You\'ve withdrawed $'.. amount ..'.')
            player.call('Banking:updateData', account, card, withdrawData.cardNumber)
            SendLog({
                ["username"] = "Banking System",
                ['embeds'] = {
                    {
                        ['title'] = 'Withdrawal from Card',
                        ['fields'] = {
                            {
                                ['name'] = 'Bank Account Holder',
                                ['value'] = player.getName(),
                                ['inline'] =  true
                            },
                            {
                                ['name'] = 'Account ID',
                                ['value'] = player.identifier,
                                ['inline'] =  true
                            },
                            {
                                ['name'] = 'Character ID',
                                ['value'] = player.get('charId'),
                                ['inline'] =  true
                            },
                            {
                                ['name'] = 'Card',
                                ['value'] = withdrawData.cardNumber,
                                ['inline'] =  true
                            },
                            {
                                ['name'] = 'Amount',
                                ['value'] = amount,
                                ['inline'] =  true
                            },
                            {
                                ['name'] = 'New Balance',
                                ['value'] = card.balance,
                                ['inline'] =  true
                            },
                        }
                    }
                }
            })
            return
        end

        if not ((math.abs(balance - amount)) <= limit) then
            player.showNotification('Amount exceeds card\'s limit.')
            return
        end

        card.balance = balance - amount
        player.addMoney(amount)

        account.cash = player.getMoney()
        account.stats.outcome.amount = totalOutcome
        account.transactions[transactionID] = {
            transactionid = transactionID,
            accountname = 'Withdraw from Card '.. card.lastfour,
            amount = amount,
            inflow = false,
        }

        player.showNotification('You\'ve withdrawed $'.. amount ..'.')
        player.call('Banking:updateData', account, card, withdrawData.cardNumber)
        SendLog({
            ["username"] = "Banking System",
            ['embeds'] = {
                {
                    ['title'] = 'Withdrawal from Card Exceeding Limit',
                    ['fields'] = {
                        {
                            ['name'] = 'Bank Account Holder',
                            ['value'] = player.getName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Account ID',
                            ['value'] = player.identifier,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Character ID',
                            ['value'] = player.get('charId'),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Card',
                            ['value'] = withdrawData.cardNumber,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Amount',
                            ['value'] = amount,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'New Balance',
                            ['value'] = card.balance,
                            ['inline'] =  true
                        },
                    }
                }
            }
        })
        return
    end

    if account.balances.checking < amount then
        player.showNotification('You don\'t have enough to withdraw.')
        return
    end

    account.balances.checking = account.balances.checking - amount
    player.addMoney(amount)

    account.name = player.name
    account.cash = player.getMoney()
    account.transactions[transactionID] = {
        transactionid = transactionID,
        accountname = 'Debit',
        amount = amount,
        inflow = false,
    }
    account.stats.outcome.amount = totalOutcome
    player.call('Banking:ClientEvent', 'updateData', account)
    player.showNotification('You\'ve withdrawed $'.. amount ..'.')
end

function Banking:Transfer(player, transferData)
    if not player then return end
    if not transferData.amount then return end
    if not self.Accounts[player.charid] then return end

    local accountSender = self.Accounts[player.charid]
    local card = accountSender.cards[transferData.cardNumber]

    if card and (transferData.type == 'card') then
        local transferToCardNumber = transferData.iban
        local transferToCard = self.Cards[transferToCardNumber]
        local transferAmount = transferData.amount

        if (transferToCardNumber == transferData.cardNumber) then
            player.showNotification('You cannot transfer to yourself.')
            return
        end

        if not transferToCard then
            player.showNotification('There is no card with the number : '.. transferToCard ..'.')
            return
        end

        local accountReceiver = self.Accounts[transferToCard]
        local receivingCard = accountReceiver.cards[transferToCardNumber]
        local receivingPlayer = Core.GetPlayerFromId(accountReceiver.id)

        if not receivingPlayer then
            player.showNotification('You cannot transfer to this card at the moment.')
            return
        end

        print('using card to transfer')
        if card.balance < transferAmount then
            player.showNotification('Your card doesn\'t have enough balance for this transaction.')
            return
        end

        local receiverStatsIncome = accountReceiver.stats.income.amount or 0
        local receiverTotalIncome = receiverStatsIncome + transferAmount

        local senderStatsOutcome = accountSender.stats.outcome.amount or 0
        local senderTotalOutcome = senderStatsOutcome + transferAmount

        card.balance = card.balance - transferAmount
        receivingCard.balance = receivingCard.balance + transferAmount

        accountSender.transactions[#accountSender.transactions + 1] = {
            transactionid = #accountSender.transactions + 1,
            accountname = ('Transferred to Card %s from Card %s'):format(receivingCard.lastfour, card.lastfour),
            amount = transferAmount,
            inflow = false,
        }
        accountSender.stats.outcome.amount = senderTotalOutcome

        accountReceiver.transactions[#accountReceiver.transactions + 1] = {
            transactionid = #accountReceiver.transactions + 1,
            accountname = ('Received to Card %s from Card %s'):format(receivingCard.lastfour, card.lastfour),
            amount = transferAmount,
            inflow = true,
        }
        accountReceiver.stats.income.amount = receiverTotalIncome

        player.showNotification('You have transfered $'.. transferAmount ..' to the card: '.. receivingCard.lastfour ..'.')
        receivingPlayer.showNotification('You have received $'.. transferAmount ..' to your card: '.. receivingCard.lastfour ..'.')

        player.call('Banking:updateData', accountSender, card, transferData.cardNumber)
        SendLog({
            ["username"] = "Banking System",
            ['embeds'] = {
                {
                    ['title'] = 'Transfer from Card to Card',
                    ['fields'] = {
                        {
                            ['name'] = 'Bank Account Holder',
                            ['value'] = player.getName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Account ID',
                            ['value'] = player.identifier,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Character ID',
                            ['value'] = player.get('charId'),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Card',
                            ['value'] = transferData.cardNumber,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Transferred to Account Holder',
                            ['value'] = receivingPlayer.getName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Transferred to Card',
                            ['value'] = transferToCardNumber,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Amount',
                            ['value'] = transferAmount,
                            ['inline'] =  true
                        },
                    }
                }
            }
        })
        SendLog({
            ["username"] = "Banking System",
            ['embeds'] = {
                {
                    ['title'] = 'Received Transfer from Card to Card',
                    ['fields'] = {
                        {
                            ['name'] = 'Bank Account Holder',
                            ['value'] = receivingPlayer.getName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Account ID',
                            ['value'] = receivingPlayer.identifier,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Character ID',
                            ['value'] = receivingPlayer.get('charId'),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Received from Card',
                            ['value'] = transferData.cardNumber,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Received from Account Holder',
                            ['value'] = player.getName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Receiving Card',
                            ['value'] = transferToCardNumber,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Amount',
                            ['value'] = transferAmount,
                            ['inline'] =  true
                        },
                    }
                }
            }
        })
        return
    end

--[[     local transferTo = string.upper(transferData.iban)
    local transferAmount = transferData.amount

    if accountSender.iban == transferTo then
        player.showNotification('You cannot transfer to yourself.')
        return
    end

    if not self.IBANs[transferTo] then
        player.showNotification('There is no account with the IBAN : '.. transferTo ..'.')
        return
    end

    local receiverCharID = self.IBANs[transferTo]
    local accountReceiver = self.Accounts[receiverCharID]
    local receivingPlayer = Core.GetPlayerFromId(accountReceiver.id)

    if not receivingPlayer then
        player.showNotification('You cannot transfer to this account at the moment.')
        return
    end

    local receiverStatsIncome = accountReceiver.stats.income.amount or 0
    local receiverTotalIncome = receiverStatsIncome + transferAmount

    local senderStatsOutcome = accountSender.stats.outcome.amount or 0
    local senderTotalOutcome = senderStatsOutcome + transferAmount

    if card then
        print('using card to transfer')
        if card.balance < transferAmount then
            player.showNotification('Your card doesn\'t have enough balance for this transaction.')
            return
        end

        card.balance = card.balance - transferAmount
        accountReceiver.balances.checking = accountReceiver.balances.checking + transferAmount

        accountSender.transactions[#accountSender.transactions + 1] = {
            transactionid = #accountSender.transactions + 1,
            accountname = ('Transferred to %s from Card %s'):format(transferTo, card.lastfour),
            amount = transferAmount,
            inflow = false,
        }
        accountSender.stats.outcome.amount = senderTotalOutcome

        accountReceiver.transactions[#accountReceiver.transactions + 1] = {
            transactionid = #accountReceiver.transactions + 1,
            accountname = ('Received from %s'):format(accountSender.iban),
            amount = transferAmount,
            inflow = true,
        }
        accountReceiver.stats.income.amount = receiverTotalIncome

        player.showNotification('You have transfered $'.. transferAmount ..' to the IBAN : '.. transferTo ..'.')
        receivingPlayer.showNotification('You have received $'.. transferAmount ..' from the IBAN : '.. accountSender.iban ..'.')

        player.call('Banking:updateData', accountSender, card, transferData.cardNumber)
        SendLog({
            ["username"] = "Banking System",
            ['embeds'] = {
                {
                    ['title'] = 'Transfer from Card',
                    ['fields'] = {
                        {
                            ['name'] = 'Bank Account Holder',
                            ['value'] = player.getName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Account ID',
                            ['value'] = player.identifier,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Character ID',
                            ['value'] = player.get('charId'),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Card',
                            ['value'] = transferData.cardNumber,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Transferred to account',
                            ['value'] = transferTo,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Amount',
                            ['value'] = transferAmount,
                            ['inline'] =  true
                        },
                    }
                }
            }
        })
        SendLog({
            ["username"] = "Banking System",
            ['embeds'] = {
                {
                    ['title'] = 'Received Transfer',
                    ['fields'] = {
                        {
                            ['name'] = 'Bank Account Holder',
                            ['value'] = receivingPlayer.getName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Account ID',
                            ['value'] = receivingPlayer.identifier,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Character ID',
                            ['value'] = receivingPlayer.get('charId'),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Received from account',
                            ['value'] = transferData.cardNumber,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Received to account',
                            ['value'] = transferTo,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Amount',
                            ['value'] = transferAmount,
                            ['inline'] =  true
                        },
                    }
                }
            }
        })
        return
    end

    local senderCurrentBank = accountSender.balances.checking
    if senderCurrentBank < transferAmount then
        player.showNotification('Transfer amount exceeds your current balance.')
        return
    end

    accountSender.balances.checking = accountSender.balances.checking - accountReceiver
    accountReceiver.balances.checking = accountReceiver.balances.checking + accountReceiver

    player.showNotification('You have transfered $'.. transferAmount ..' to the IBAN : '.. transferTo ..'.')
    receivingPlayer.showNotification('You have received $'.. transferAmount ..' from the IBAN : '.. accountSender.iban ..'.')

    accountSender.transactions[#accountSender.transactions + 1] = {
        transactionid = #accountSender.transactions + 1,
        accountname = 'Sent to '.. transferTo,
        amount = transferAmount,
        inflow = false,
    }
    accountSender.stats.outcome.amount = senderTotalOutcome

    accountReceiver.transactions[#accountReceiver.transactions + 1] = {
        transactionid = #accountReceiver.transactions + 1,
        accountname = 'Received from '.. accountSender.iban,
        amount = transferAmount,
        inflow = true,
    }
    accountReceiver.stats.income.amount = receiverTotalIncome

    player.call('Banking:ClientEvent', 'updateData', accountSender)
    receivingPlayer.call('Banking:ClientEvent', 'updateData', accountReceiver) ]]
end

function Banking:ChangeIBAN(player, iban)
    if not player then return end
    if not iban then return end
    if not self.Accounts[player.charid] then return end

    local account = self.Accounts[player.charid]
    local newIBAN = string.upper(iban)

    if account.recentIBANChange then
        player.showNotification('You\'ve recently changed your IBAN, try again later.')
        return
    end

    if self.IBANs[newIBAN] then
        player.showNotification('There\'s is already an account with the IBAN : '.. newIBAN ..'.')
        return
    end

    self.IBANs[account.iban] = nil
    self.IBANs[newIBAN] = player.charid
    account.iban = newIBAN
    account.recentIBANChange = true

    Timer.SetTimeout(function ()
        account.recentIBANChange = false
    end, 60000 * 5)
    
    player.showNotification('You\'ve changed your IBAN to : '.. newIBAN ..'.')
    player.call('Banking:ClientEvent', 'updateData', account)
    SendLog({
        ["username"] = "Banking System",
        ['embeds'] = {
            {
                ['title'] = 'Account IBAN Change',
                ['fields'] = {
                    {
                        ['name'] = 'Bank Account Holder',
                        ['value'] = player.getName(),
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Account ID',
                        ['value'] = player.identifier,
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Character ID',
                        ['value'] = player.get('charId'),
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'New IBAN',
                        ['value'] = account.iban,
                        ['inline'] =  true
                    }
                }
            }
        }
    })
end

function Banking:ChangePIN(player, pin, cardNumber)
    if not player then return end
    if not pin then return end
    if not cardNumber then return end
    if not self.Accounts[player.charid] then return end

    local account = self.Accounts[player.charid]
    local card =  account.cards[cardNumber]
    local newPIN = tostring(pin)
    local previousPIN = card.pin 

    if not card then return end

    if card.recentPINChange then
        player.showNotification('You\'ve recently changed your PIN, try again later.')
        return
    end

    card.pin = newPIN
    card.recentPINChange = true

    Timer.SetTimeout(function ()
        card.recentPINChange = false
    end, 60000 * 5)

    player.showNotification('You\'ve changed your PIN to : '.. newPIN ..'.')
    SendLog({
        ["username"] = "Banking System",
        ['embeds'] = {
            {
                ['title'] = 'Card PIN Change',
                ['fields'] = {
                    {
                        ['name'] = 'Bank Account Holder',
                        ['value'] = player.getName(),
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Account ID',
                        ['value'] = player.identifier,
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Character ID',
                        ['value'] = player.get('charId'),
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Card Number',
                        ['value'] = cardNumber,
                        ['inline'] =  true
                    }
                }
            }
        }
    })
end

function Banking.GetAccount(charid)
    return Banking.Accounts[charid]
end

function Banking.GetAccountFromIBAN(iban)
    return Banking.IBANs[iban] and Banking.Accounts[Banking.IBANs[iban]]
end

function SendLog(data)
	HTTP.RequestAsync('https://discord.com', '/api/webhooks/1226893748827455549/CH7TO4toQuJxRBXikoC6vwLZx74ftFdaDw1tL-ymcDzwwFnI5fIWo7t6y68wqXA_zbUC', 'POST', JSON.stringify(data), 'application/json')
end


Events.Subscribe('core:playerSpawned', function(player)
    local xPlayer = Core.GetPlayerFromId(player:GetID())

    Banking:PlayerSpawned(xPlayer)

    xPlayer.inventory.AddItem('begel', 1)
    xPlayer.inventory.AddItem('phone', 1)
    xPlayer.inventory.AddItem('water', 1)
end)

Player.Subscribe("Destroy", function(player)
    local xPlayer = Core.GetPlayerFromId(player:GetID())

    if not xPlayer then return end

    local account = Banking.Accounts[xPlayer.charid]
    if account and (account.isNew) then
        account.isNew = false
        DB:Execute('INSERT INTO user_banking VALUES (:0, :0, :0, :0, :0, :0, :0)', xPlayer.charid, account.iban, account.number, JSON.stringify(account.transactions), JSON.stringify(account.stats), JSON.stringify(account.balances), JSON.stringify(account.cards))
        return
    end

    DB:Execute('UPDATE user_banking SET iban = :0, transactions = :0, stats = :0, balances = :0, cards = :0 WHERE identifier = :0', account.iban, JSON.stringify(account.transactions), JSON.stringify(account.stats), JSON.stringify(account.balances), JSON.stringify(account.cards), xPlayer.charid)
end)

Events.SubscribeRemote('Banking:ServerEvent',function (player, eventType, eventData)
	local xPlayer = Core.GetPlayerFromId(player:GetID())

    if eventType == 'open_atm' then
        Banking:OpenATM(xPlayer)
    end

    if eventType == 'set_pin' and eventData then
        Banking:SetAccountPIN(xPlayer, eventData)
    end

    if eventType == 'deposit' and eventData then
        Banking:Deposit(xPlayer, eventData)
    end

    if eventType == 'withdraw' and eventData then
        Banking:Withdraw(xPlayer, eventData)
    end

    if eventType == 'transfer' and eventData then
        Banking:Transfer(xPlayer, eventData)
    end

    if eventType == 'changeIBAN' and eventData then
        Banking:ChangeIBAN(xPlayer, eventData)
    end

    if eventType == 'changePIN' and eventData then
        Banking:ChangePIN(xPlayer, eventData.pin, eventData.cardNumber)
    end
end)



Chat.Subscribe("PlayerSubmit", function(message, player)
    local xPlayer = Core.GetPlayerFromId(player:GetID())

	if message == 'getcard' then
        Banking:GiveCreditCard(xPlayer)
    end
end)

Package.Export("GetAccount", Banking.GetAccount)
Package.Export("GetAccountFromIBAN", Banking.GetAccountFromIBAN)