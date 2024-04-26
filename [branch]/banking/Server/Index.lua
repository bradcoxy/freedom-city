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
Banking.Branches = {
    ['north_south_1'] = {
        location = Vector(-326.142, -530.596, 10.0),
        rotation = Rotator(0.0, 0.0, 0.0),
        label = "North South Bank",
    }
}

Banking.TaxRate = 10
Banking.InterestRate = 6.50
Banking.MinCardPayment = 15

Package.Subscribe('Load', function()
    -- local savedAccounts = DB:Select('SELECT * FROM user_banking')
    -- for _, account in pairs(savedAccounts) do

    --     Banking.Accounts[account.identifier] = {
    --         iban = account.iban,
    --         number = account.number,
    --         transactions = account.transactions and JSON.parse(account.transactions) or {},
    --         stats = account.stats and JSON.parse(account.stats) or {
    --             income = {title = 'income'},
    --             outcome = {title = 'outcome'},
    --             earnings = {title = 'earnings'},
    --         },
    --         loans = account.loans and JSON.parse(account.loans) or {},
    --         balances = account.balances and JSON.parse(account.balances) or {
    --             saving = 0,
    --             checking = 0,
    --         },
    --         cards = account.cards and JSON.parse(account.cards) or {}
    --     }

    --     for cardNumber in pairs(Banking.Accounts[account.identifier].cards) do
    --         Banking.Cards[cardNumber] = account.identifier
    --     end

    --     Banking.IBANs[account.iban] = account.identifier
    -- end

    Core.CreateItem({
        ['credit_card'] = {
            label = 'Credit Card',
            unique = true,
            description = 'Classic Credit Card to spend.',
            type = 'item',
        }
    })

    for _, ATM in pairs(Banking.ATMs) do
        local prop = Prop(
            ATM.location,
            ATM.rotation,
            'helix::SM_HalfStack_Marshall',
            CollisionType.Normal,
            false,
            GrabMode.Disabled
        )
        prop:SetScale(Vector(1, 1, 1.5))
    end

    for _, branch in pairs(Banking.Branches) do
        local ped = Character(branch.location, branch.rotation, 'helix::SK_Male_Chest')

        ped:SetMesh('helix::SK_Man_Outwear_03')
        ped:AddSkeletalMeshAttached('headwear', 'helix::SK_Male_Head')
        ped:AddSkeletalMeshAttached('hands', 'helix::SK_Male_Hands')
        ped:AddSkeletalMeshAttached('bottomwear', 'helix::SK_Man_Pants_09')
        ped:AddSkeletalMeshAttached('footwear', 'helix::SK_Man_Boots_17')
        ped:SetInvulnerable(true)
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
            return name
        end
    end
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

function Banking.PlayerSpawned(player)
    if not player then return end

    PersistentDatabase.GetByKey(string.format('%s_BankAccount', player.charid), function(success, data)
        data = JSON.parse(data)
        if success and data then
            local account = data[1]['value']
            Banking.Accounts[player.charid] = account or {
                iban = Banking.GenerateIBAN(),
                number = Banking.GenerateAccountNumber(),
                transactions = {},
                loans = {},
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

            Banking.Accounts[player.charid].id = player.source
            Banking.IBANs[Banking.Accounts[player.charid].iban] = player.charid
        end
    end)

    Timer.SetTimeout(function ()
        Banking:CardBillingCycle(player)
    end, 5000)

    player.call('Banking:ReceiveBranches', Banking.Branches)
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

function Banking.OpenBranch(player)
    if not player then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local account = Banking.Accounts[xPlayer.charid]
    print(HELIXTable.Dump(Banking.Accounts))
    print(HELIXTable.Dump(Banking.Accounts[xPlayer.charid]), xPlayer.charid)
    if account then
        xPlayer.call('Banking:OpenBranch', account, xPlayer.getMoney())
    end
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

function Banking.Loan(player, amount)
    if not player then return end
    if not amount then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local account = Banking.Accounts[xPlayer.charid]
    local transactionID = #account.transactions + 1
    local amountToPay = math.floor(amount + ((amount * Banking.InterestRate) / 100))
    local loadID = #account.loans + 1

    if not account then return end

    if (amount > (account.balances.checking / 4)) then
        return
    end

    if (#account.loans >= 2) then
        xPlayer.showNotification('You\'ve already taken out the maximum number of loans.')
        return
    end

    xPlayer.addMoney(amount)

    account.name = xPlayer.name
    account.cash = xPlayer.getMoney()
    account.loans[loadID] = amountToPay
    account.transactions[transactionID] = {
        transactionid = transactionID,
        accountname = 'Debit',
        amount = amount,
        inflow = true,
    }

    xPlayer.showNotification('You\'ve taken a loan of $'.. amount ..'. Amount you need to pay $'.. amountToPay ..'.')
    SendLog({
        ["username"] = "Banking System",
        ['embeds'] = {
            {
                ['title'] = 'Loan Taken',
                ['fields'] = {
                    {
                        ['name'] = 'Bank Account Holder',
                        ['value'] = xPlayer.getName(),
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Account ID',
                        ['value'] = xPlayer.identifier,
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Character ID',
                        ['value'] = xPlayer.get('charId'),
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Amount',
                        ['value'] = amount,
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'New Balance',
                        ['value'] = account.balances.checking,
                        ['inline'] =  true
                    },
                }
            }
        }
    })
end

function Banking.Deposit(player, depositData)
    if not player then return end
    if not depositData.amount then return end


    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local account = Banking.Accounts[xPlayer.charid]
    local amount = depositData.amount
    local card = account.cards[depositData.cardNumber]
    local currentCash = xPlayer.getMoney()
    local transactionID = #account.transactions + 1
    local statsIncome = account.stats.income.amount or 0
    local totalIncome = statsIncome + amount

    if not account then return end

    if currentCash < amount then
        xPlayer.showNotification('You don\'t have enough to deposit.')
        return
    end

    if (depositData.type == 'checking') and not card then
        account.balances.checking = account.balances.checking + amount
        xPlayer.removeMoney(amount)

        account.cash = xPlayer.getMoney()
        account.stats.income.amount = totalIncome
        account.transactions[transactionID] = {
            transactionid = transactionID,
            accountname = 'Deposit into Checking',
            amount = amount,
            inflow = true,
        }

        SendLog({
            ["username"] = "Banking System",
            ['embeds'] = {
                {
                    ['title'] = 'Deposit into Checking Balance',
                    ['fields'] = {
                        {
                            ['name'] = 'Bank Account Holder',
                            ['value'] = xPlayer.getName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Account ID',
                            ['value'] = xPlayer.identifier,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Character ID',
                            ['value'] = xPlayer.get('charId'),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Amount',
                            ['value'] = amount,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'New Balance',
                            ['value'] = account.balances.checking,
                            ['inline'] =  true
                        },
                    }
                }
            }
        })
        xPlayer.showNotification(('You\'ve deposited $%s into your checking balance.'):format(amount))
        return
    end

    if card then
        card.balance = card.balance + amount
        xPlayer.removeMoney(amount)

        account.cash = xPlayer.getMoney()
        account.stats.income.amount = totalIncome
        account.transactions[transactionID] = {
            transactionid = transactionID,
            accountname = 'Deposit into Card '.. card.lastfour,
            amount = amount,
            inflow = true,
        }

        xPlayer.showNotification(('You\'ve deposited $%s into Card %s.'):format(amount, card.lastfour))
        xPlayer.call('Banking:updateData', account, card, depositData.cardNumber)
        SendLog({
            ["username"] = "Banking System",
            ['embeds'] = {
                {
                    ['title'] = 'Deposit into Card',
                    ['fields'] = {
                        {
                            ['name'] = 'Bank Account Holder',
                            ['value'] = xPlayer.getName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Account ID',
                            ['value'] = xPlayer.identifier,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Character ID',
                            ['value'] = xPlayer.get('charId'),
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

    xPlayer.removeMoney(amount)
    account.balances.checking = account.balances.checking + amount

    account.name = xPlayer.name
    account.cash = xPlayer.getMoney()
    account.transactions[transactionID] = {
        transactionid = transactionID,
        accountname = 'Credit',
        amount = amount,
        inflow = true,
    }
    account.stats.income.amount = totalIncome
    xPlayer.call('Banking:ClientEvent', 'updateData', account)
    xPlayer.showNotification('You\'ve deposited $'.. amount ..'.')
    print('total income ', account.stats.income)
end

function Banking.Withdraw(player, withdrawData)
    if not player then return end
    if not withdrawData.amount then return end

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local account = Banking.Accounts[xPlayer.charid]
    local card = account.cards[withdrawData.cardNumber]
    local amount = withdrawData.amount
    local transactionID = #account.transactions + 1
    local statsOutcome = account.stats.outcome.amount or 0
    local totalOutcome = statsOutcome + amount

    if not account then return end

    if card then
        local balance = card.balance
        local limit = card.limit

        if balance >= amount then
            card.balance = card.balance - amount
            xPlayer.addMoney(amount)

            account.cash = xPlayer.getMoney()
            account.stats.outcome.amount = totalOutcome
            account.transactions[transactionID] = {
                transactionid = transactionID,
                accountname = 'Withdraw from Card '.. card.lastfour,
                amount = amount,
                inflow = false,
            }

            xPlayer.showNotification('You\'ve withdrawed $'.. amount ..'.')
            xPlayer.call('Banking:updateData', account, card, withdrawData.cardNumber)
            SendLog({
                ["username"] = "Banking System",
                ['embeds'] = {
                    {
                        ['title'] = 'Withdrawal from Card',
                        ['fields'] = {
                            {
                                ['name'] = 'Bank Account Holder',
                                ['value'] = xPlayer.getName(),
                                ['inline'] =  true
                            },
                            {
                                ['name'] = 'Account ID',
                                ['value'] = xPlayer.identifier,
                                ['inline'] =  true
                            },
                            {
                                ['name'] = 'Character ID',
                                ['value'] = xPlayer.get('charId'),
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
            xPlayer.showNotification('Amount exceeds card\'s limit.')
            return
        end

        card.balance = balance - amount
        xPlayer.addMoney(amount)

        account.cash = xPlayer.getMoney()
        account.stats.outcome.amount = totalOutcome
        account.transactions[transactionID] = {
            transactionid = transactionID,
            accountname = 'Withdraw from Card '.. card.lastfour,
            amount = amount,
            inflow = false,
        }

        xPlayer.showNotification('You\'ve withdrawed $'.. amount ..'.')
        xPlayer.call('Banking:updateData', account, card, withdrawData.cardNumber)
        SendLog({
            ["username"] = "Banking System",
            ['embeds'] = {
                {
                    ['title'] = 'Withdrawal from Card Exceeding Limit',
                    ['fields'] = {
                        {
                            ['name'] = 'Bank Account Holder',
                            ['value'] = xPlayer.getName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Account ID',
                            ['value'] = xPlayer.identifier,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Character ID',
                            ['value'] = xPlayer.get('charId'),
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
        xPlayer.showNotification('You don\'t have enough to withdraw.')
        return
    end

    account.balances.checking = account.balances.checking - amount
    xPlayer.addMoney(amount)

    account.name = xPlayer.name
    account.cash = xPlayer.getMoney()
    account.transactions[transactionID] = {
        transactionid = transactionID,
        accountname = 'Debit',
        amount = amount,
        inflow = false,
    }
    account.stats.outcome.amount = totalOutcome
    xPlayer.showNotification('You\'ve withdrawed $'.. amount ..'.')
    SendLog({
        ["username"] = "Banking System",
        ['embeds'] = {
            {
                ['title'] = 'Withdrawal from Checking',
                ['fields'] = {
                    {
                        ['name'] = 'Bank Account Holder',
                        ['value'] = xPlayer.getName(),
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Account ID',
                        ['value'] = xPlayer.identifier,
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Character ID',
                        ['value'] = xPlayer.get('charId'),
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'Amount',
                        ['value'] = amount,
                        ['inline'] =  true
                    },
                    {
                        ['name'] = 'New Balance',
                        ['value'] = account.balances.checking,
                        ['inline'] =  true
                    },
                }
            }
        }
    })
end

function Banking.Transfer(player, transferData)
    if not player then return end
    if not transferData.amount then return end

    print(HELIXTable.Dump(transferData))

    local xPlayer = Core.GetPlayerFromId(player:GetID())
    local accountSender = Banking.Accounts[xPlayer.charid]
    local card = accountSender.cards[transferData.cardNumber]

    if not accountSender then return end

    if (transferData.type == 'iban') and not card then
        local transferTo = string.upper(transferData.iban)
        local transferAmount = transferData.amount

        if (accountSender.iban == transferTo) then
            xPlayer.showNotification('You cannot transfer to yourself.')
            return
        end

        if not Banking.IBANs[transferTo] then
            xPlayer.showNotification('There is no account with the IBAN : '.. transferTo ..'.')
            return
        end

        local receiverCharID = Banking.IBANs[transferTo]
        local accountReceiver = Banking.Accounts[receiverCharID]
        local receivingPlayer = Core.GetPlayerFromId(accountReceiver.id)

        if not receivingPlayer then
            xPlayer.showNotification('You cannot transfer to this account at the moment.')
            return
        end

        if (transferAmount > accountSender.balances.checking) then
            xPlayer.showNotification('You do not have enough balance.')
            return
        end

        local receiverStatsIncome = accountReceiver.stats.income.amount or 0
        local receiverTotalIncome = receiverStatsIncome + transferAmount

        local senderStatsOutcome = accountSender.stats.outcome.amount or 0
        local senderTotalOutcome = senderStatsOutcome + transferAmount

        accountSender.balances.checking = accountSender.balances.checking  - transferAmount
        accountReceiver.balances.checking = accountReceiver.balances.checking + transferAmount

        accountSender.transactions[#accountSender.transactions + 1] = {
            transactionid = #accountSender.transactions + 1,
            accountname = ('Transferred to Checking %s from Checking %s'):format(accountSender.iban, transferTo),
            amount = transferAmount,
            inflow = false,
        }
        accountSender.stats.outcome.amount = senderTotalOutcome

        accountReceiver.transactions[#accountReceiver.transactions + 1] = {
            transactionid = #accountReceiver.transactions + 1,
            accountname = ('Received to Checking %s from Checking %s'):format(transferTo, accountSender.iban),
            amount = transferAmount,
            inflow = true,
        }
        accountReceiver.stats.income.amount = receiverTotalIncome

        xPlayer.showNotification('You have transfered $'.. transferAmount ..' from your checking balance.')
        receivingPlayer.showNotification('You have received $'.. transferAmount ..' to your checking balance.')

        SendLog({
            ["username"] = "Banking System",
            ['embeds'] = {
                {
                    ['title'] = 'Transfer from Checking to Checking',
                    ['fields'] = {
                        {
                            ['name'] = 'Bank Account Holder',
                            ['value'] = xPlayer.getName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Account ID',
                            ['value'] = xPlayer.identifier,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Character ID',
                            ['value'] = xPlayer.get('charId'),
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
                    ['title'] = 'Received Transfer from Checking to Checking',
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
                            ['value'] = xPlayer.getName(),
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
    end

    if card and (transferData.type == 'card') then
        local transferToCardNumber = transferData.iban
        local transferToCard = Banking.Cards[transferToCardNumber]
        local transferAmount = transferData.amount

        if (transferToCardNumber == transferData.cardNumber) then
            xPlayer.showNotification('You cannot transfer to yourself.')
            return
        end

        if not transferToCard then
            xPlayer.showNotification('There is no card with the number : '.. transferToCard ..'.')
            return
        end

        local accountReceiver = Banking.Accounts[transferToCard]
        local receivingCard = accountReceiver.cards[transferToCardNumber]
        local receivingPlayer = Core.GetPlayerFromId(accountReceiver.id)

        if not receivingPlayer then
            xPlayer.showNotification('You cannot transfer to this card at the moment.')
            return
        end

        print('using card to transfer')
        if card.balance < transferAmount then
            xPlayer.showNotification('Your card doesn\'t have enough balance for this transaction.')
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

        xPlayer.showNotification('You have transfered $'.. transferAmount ..' to the card: '.. receivingCard.lastfour ..'.')
        receivingPlayer.showNotification('You have received $'.. transferAmount ..' to your card: '.. receivingCard.lastfour ..'.')

        xPlayer.call('Banking:updateData', accountSender, card, transferData.cardNumber)
        SendLog({
            ["username"] = "Banking System",
            ['embeds'] = {
                {
                    ['title'] = 'Transfer from Card to Card',
                    ['fields'] = {
                        {
                            ['name'] = 'Bank Account Holder',
                            ['value'] = xPlayer.getName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Account ID',
                            ['value'] = xPlayer.identifier,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Character ID',
                            ['value'] = xPlayer.get('charId'),
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
                            ['value'] = xPlayer.getName(),
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
    end
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

function Banking.PayLoan(charId)
    if not charId then return end

    local account = Banking.Accounts[charId]
    local xPlayer = Core.GetPlayerFromId(account.id)

    if not xPlayer then return end

    for k, loanLeft in pairs(account.loans) do
        local minimumPayment = loanLeft > 250 and math.floor(loanLeft / 4) or loanLeft
        local transactionID = #account.transactions
        local statsOutcome = account.stats.outcome.amount or 0
        local totalOutcome = statsOutcome + minimumPayment

        account.balances.checking = account.balances.checking - minimumPayment
        account.loans[k] = account.loans[k] - minimumPayment
        account.transactions[transactionID] = {
            transactionid = transactionID,
            accountname = 'Debit',
            amount = minimumPayment,
            inflow = false,
        }
        account.stats.outcome.amount = totalOutcome

        xPlayer.showNotification(('$%s deducted from your checking account as loan payment.'):format(minimumPayment))
        SendLog({
            ["username"] = "Banking System",
            ['embeds'] = {
                {
                    ['title'] = 'Money Deducted as Loan Payment',
                    ['fields'] = {
                        {
                            ['name'] = 'Bank Account Holder',
                            ['value'] = xPlayer.getName(),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Account ID',
                            ['value'] = xPlayer.identifier,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Character ID',
                            ['value'] = xPlayer.get('charId'),
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Amount',
                            ['value'] = minimumPayment,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'New Balance',
                            ['value'] = account.balances.checking,
                            ['inline'] =  true
                        },
                        {
                            ['name'] = 'Amount left to pay',
                            ['value'] = account.loans[k],
                            ['inline'] =  true
                        },
                    }
                }
            }
        })

        if account.loans[k] <= 0 then
            account.loans[k] = nil
        end
    end
end

Timer.SetInterval(function ()
    print('pay for loan')
    for charId, account in pairs(Banking.Accounts) do
        if account.id and #account.loans > 0 then
            Banking.PayLoan(charId)
            print('found account with loan.')
        end
    end
end, (60000 * 60)) -- payment for loans

Events.Subscribe('core:playerSpawned', function(player)
    local xPlayer = Core.GetPlayerFromId(player:GetID())

    Banking.PlayerSpawned(xPlayer)

    xPlayer.inventory.AddItem('begel', 1)
    xPlayer.inventory.AddItem('phone', 1)
    xPlayer.inventory.AddItem('water', 1)
end)


Package.Subscribe('Load', function ()
    for k, v in pairs(Player.GetPairs()) do
        local xPlayer = Core.GetPlayerFromId(v:GetID())
        Banking.PlayerSpawned(xPlayer)
    end
end)

Player.Subscribe("Destroy", function(player)
    local xPlayer = Core.GetPlayerFromId(player:GetID())

    if not xPlayer then return end

    local account = Banking.Accounts[xPlayer.charid]
    if account and (account.isNew) then
        account.isNew = false
        --DB:Execute('INSERT INTO user_banking VALUES (:0, :0, :0, :0, :0, :0, :0, :0)', xPlayer.charid, account.iban, account.number, JSON.stringify(account.transactions), JSON.stringify(account.stats), JSON.stringify(account.loans), JSON.stringify(account.balances), JSON.stringify(account.cards))
        PersistentDatabase.Insert(string.format('%s_BankAccount', xPlayer.charid), JSON.stringify(Banking.Accounts[xPlayer.charid]), function () end)
        return
    end

    PersistentDatabase.Update(string.format('%s_BankAccount', xPlayer.charid), JSON.stringify(Banking.Accounts[xPlayer.charid]), function () end)
    --DB:Execute('UPDATE user_banking SET iban = :0, transactions = :0, stats = :0, loans = :0, balances = :0, cards = :0 WHERE identifier = :0', account.iban, JSON.stringify(account.transactions), JSON.stringify(account.stats), JSON.stringify(account.loans), JSON.stringify(account.balances), JSON.stringify(account.cards), xPlayer.charid)
end)

Events.SubscribeRemote('Banking:ServerEvent',function (player, eventType, eventData)
	local xPlayer = Core.GetPlayerFromId(player:GetID())

    if eventType == 'open_atm' then
        Banking:OpenATM(xPlayer)
    end

    if eventType == 'changeIBAN' and eventData then
        Banking:ChangeIBAN(xPlayer, eventData)
    end

    if eventType == 'changePIN' and eventData then
        Banking:ChangePIN(xPlayer, eventData.pin, eventData.cardNumber)
    end
end)

Events.SubscribeRemote('Banking:OpenBranch', Banking.OpenBranch)
Events.SubscribeRemote('Banking:Loan', Banking.Loan)
Events.SubscribeRemote('Banking:Transfer', Banking.Transfer)
Events.SubscribeRemote('Banking:Deposit', Banking.Deposit)
Events.SubscribeRemote('Banking:Withdraw', Banking.Withdraw)

Chat.Subscribe("PlayerSubmit", function(message, player)
    local xPlayer = Core.GetPlayerFromId(player:GetID())

	if message == 'getcard' then
        Banking:GiveCreditCard(xPlayer)
    end
end)

Package.Export("GetAccount", Banking.GetAccount)
Package.Export("GetAccountFromIBAN", Banking.GetAccountFromIBAN)