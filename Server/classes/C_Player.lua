-- Creates a proxy, this essentially makes the table observed and every index is serialised
local function CreateProxy(t, a, b)
    return setmetatable({}, {
        __index = function(_, key)
            return a[key]
        end,
        __newindex = function(_, k, v)
            a[k] = v
            -- if not initialised then return end
            if not t.serialisedVersion[b] then t.serialisedVersion[b] = {} end
            t.serialisedVersion[b][k] = v
            
            t.updateData();
        end
    })
end

function CreatePlayerData(player, id, identifier, name, accounts, stats, xp, job, skin, variables)
    local t = {} -- player table

    local s = {
        hunger = CreateStatus('hunger', stats.hunger or 100),
        thirst = CreateStatus('thirst', stats.thirst or 100),
        sanity = CreateStatus('sanity', stats.sanity or 100)
    } -- status table

    local a = {
        money = accounts.money or 0,
        bank = accounts.bank or 0
    } -- accounts table

    local x = {
        xp = xp.xp or 0,
        rank = xp.rank or 1,
    } -- xp table

    -- TODO: CREATE A CUSTOM PROXY TABLE FOR THIS TO SYNC TO CLIENT SIDE
    local v = {} -- variables table

    local cm = {} -- currentMarker table

    local e = {
        phone = false
    } -- equipment table

    local sk = skin
    local j = job

    local initialised = false

    -- Auto update any changes made to the player
    local self = setmetatable({}, {
        __index = function(_, key)
            return t[key]
        end,
        __newindex = function(_, k, v)
            t[k] = v

            if type(v) == 'table' then
                t.serialisedVersion[k] = v.serialisedVersion
            elseif (type(v) ~= 'function') then
                t.serialisedVersion[k] = v
            end

            if not initialised then return end

            t.updateData()
        end
    })

    self.serialisedVersion = {}

    self.stats = CreateProxy(self, s, 'stats');
    self.accounts = CreateProxy(self, a, 'accounts');
    self.currentMarker = CreateProxy(self, cm,'currentMarker');
    self.xp = CreateProxy(self, x, 'xp');
    self.variables = variables or {}
    -- self.variables = CreateProxy(self, v, 'variables');
    self.skin = CreateProxy(self, sk, 'skin');
    self.equipment = CreateProxy(self, e, 'equipment');

    self.identifier = identifier
    self.source = id
    self.name = name
    self.player = player
    self.character = nil
 
    self.insideVehicle = nil
    self.inventoryTarget = nil

    self.inventory = Core.CreateInventory(id, 'player', 1, 100)
    self.inventory.UpdateHolder(self)
    
    self.job = CreateProxy(self, j, 'job');

    function self.revive(location)
        if (self.character:GetHealth() ~= 0) then print("Called to revive player but, wasn't dead") return end
        location = location or self.character:GetLocation();

        self.set("isDead", false)
        
        self.character:Respawn(location, Rotator(0, 0, 0))
        self.call('core:onPlayerRevived')
    end
    
    function self.slay()
        self.set("isDead", true)

        self.character:SetHealth(0)
        self.call("core:onPlayerDeath")
    end

    function self.save()
--[[         for k, v in pairs(self.variables) do
            local db_data = Core.SavedVariables[k]
            if db_data then
                local x

                if type(v) == 'number' then
                    x = v
                end

                if type(v) == 'boolean' then
                    x = v and 1 or 0
                end
                
                local res = DB:Execute(("UPDATE %s SET %s = %s WHERE charid = '%s'"):format(db_data.table, db_data.column, x, self.charid))
                print("DB UPDATE =>", db_data.table, db_data.column, x)
            end
        end

        print("SAVING PLAYER")
        for k, v in pairs(self.accounts) do
            print(("UPDATE `user_accounts` SET value = %s WHERE charid = '%s' AND account = '%s'"):format(v, self.charid, k))
            local res = DB:Execute(("UPDATE `user_accounts` SET value = %s WHERE charid = '%s' AND account = '%s'"):format(v, self.charid, k))
            print(res)
        end ]]

        local toSave = {
            ['accounts'] = true,
            ['job'] = true,
        }
        local save = false
        local saving = {}
        for k, data in pairs(t.serialisedVersion) do
            if toSave[k] then
                saving[k] = data
                save = true
            end
        end

        if save then
            PersistentDatabase.Insert(('%s_Saved'):format(self.charid), JSON.stringify(saving), function () end)
        end

        self.inventory.Save()
    end

    function self.setEquipment(equipment, val)
        self.equipment[equipment] = val
    end

    function self.getXP()
        return self.xp.xp
    end

    function self.setInventoryTarget(target)
        self.inventoryTarget = target
    end
    function self.getInventoryTarget()
        return self.inventoryTarget
    end

    function self.setMarker(marker)
        if not marker then
            self.currentMarker.marker = nil
            self.currentMarker.location = nil
            self.currentMarker.name = nil    
            return
        end
        self.currentMarker.marker = marker.marker
        self.currentMarker.location = marker.location
        self.currentMarker.name = marker.name
    end

    function self.setVehicle(vehicle)
        self.insideVehicle = vehicle
    end
    function self.getVehicle()
        return self.insideVehicle
    end

    function self.setJob(newJob)
        self.job.name = newJob.name
        self.job.grade = newJob.grade
        Events.Call("OnJobUpdate", self.player, newJob)
    end

    function self.setCharacter(character)
        if self.character and Core.Characters[self.character] then
            Core.Characters[self.character] = nil
        end

        self.gender = Core.Genders[character:GetMesh()]
        self.character = character;
        
        Core.Characters[self.character] = self;
    end

    function self.getCharacter()
        return self.character;
    end

    function self.getMarker()
        return self.currentMarker
    end

    function self.set(key, value, sync)
        self.variables[key] = value
    end

    function self.get(key)
        return self.variables[key]
    end

    function self.addXP(value)
        if not value or value <= 0 then return end

        local curXP = self.getXP()
        local curRank = self.getRank()

        local newXP = curXP + value

        if newXP < 0 then return end
        
        local newRank = CalculateChange(newXP, curRank)

        if curRank ~= newRank then
            self.setRank(newRank)
        end

        self.setXP(newXP)
    end

    function self.removeXP(value)
        if not value or value <= 0 then return end

        local curXP = self.getXP()
        local curRank = self.getRank()

        local newXP = curXP - value

        if newXP < 0 then return end
        local newRank = CalculateChange(newXP, curRank)

        if curRank ~= newRank then
            self.setRank(newRank)
        end

        self.setXP(newXP)
    end

    function self.setXP(value)
        self.xp.xp = value
        return self.xp.xp
    end

    function self.setRank(value)
        self.xp.rank = value
        return self.xp.rank
    end

    function self.getRank()
        return self.xp.rank
    end

    function self.getID()
        return self.source
    end

    function self.getName()
        return self.name
    end

    function self.setName(name)
        self.name = name
    end

    function self.getIdentifier()
        return self.identifier
    end

    function self.getMoney()
        return self.accounts["money"]
    end

    function self.getBank()
        return self.accounts["bank"]
    end

    function self.addMoney(value, skipItem)
        self.accounts['money'] = self.accounts['money'] + value
        
        self.call('core:UpdateAccountMoney', 'money', self.accounts['money'])
        
        if skipItem then
            return
        end
        
        self.inventory.AddItem('money', value)
    end
    
    function self.removeMoney(value, skipItem)
        local newVal = self.accounts['money'] - value

        if newVal < 0 then
            newVal = 0
        end

        self.accounts['money'] = newVal

        self.call('core:UpdateAccountMoney', 'money', self.accounts['money'])
        
        if skipItem then
            return
        end

        self.inventory.RemoveItem('money', value)
    end
    
    function self.addBankMoney(value)
        self.accounts['bank'] = self.accounts['bank'] + value 
        self.call('core:UpdateAccountMoney', 'bank', self.accounts['bank'])
    end
    
    function self.removeBankMoney(value)
        self.accounts['bank'] = self.accounts['bank'] - value 
        self.call('core:UpdateAccountMoney', 'bank', self.accounts['bank'])
    end
    
    function self.addAccountMoney(account, value)
        if not self.accounts[account] then return end
        
        if (account == 'money') then
            self.addMoney(value)
            return
        end
        
        self.accounts[account] = self.accounts[account] + value
        self.call('core:UpdateAccountMoney', account, self.accounts[account])
    end

    function self.removeAccountMoney(account, value)
        if not self.accounts[account] then return end

        if (account == 'money') then
            self.removeMoney(value)
            return
        end

        self.accounts[account] = self.accounts[account] - value
    end

    function self.getAccount(account)
        return self.accounts[account]
    end

    function self.setAccount(account, value)
        self.accounts[account] = value
    end

    function self.getStat(stat)
        return self.stats[stat]
    end

    function self.setStat(stat, value)
        self.stats[stat] = value
        return self.stats[stat]
    end

    function self.call(event, ...)
        Events.CallRemote(event, self.player, ...)
    end

    function self.setCharId(charid)
        self.charid = charid
    end
    
    function self.getCharId()
        return self.charid
    end

    function self.setSkin(target, name)
        local clothing = Core.Clothing[name]
        local mesh = clothing.sharedMesh

        if not mesh then
            mesh = (self.gender == 1 and clothing.maleMesh) or clothing.femaleMesh
        end
        
        if not mesh then return end -- clothing not available for char
        
        self.skin[target] = name
        if clothing.sockets and clothing.sockets[self.gender] then
            return self.character:AddStaticMeshAttached(target, mesh, clothing.sockets and clothing.sockets[self.gender])
        end
        self.character:AddSkeletalMeshAttached(target, mesh)
    end

    function self.getSkin()
        return self.skin
    end

    function self.serialiseData()
        for k, v in pairs(self) do
            if (type(v) == 'table' and v.serialisedVersion) then
                self.serialisedVersion[k] = v.serialisedVersion
            elseif (type(v) ~= 'function') then
                self.serialisedVersion[k] = v
            end
        end
    end

    function self.showNotification(msg, type, title, duration)
        if not msg then return end
        self.call("ShowNotification", msg, type or "info", title or '', duration or 3000)
    end

    function self.kick(reason)
        self.player:Kick(reason)
    end

    function self.updateData()
        if HELIXUtils.IsEntityValid(self.player) then
            self.player:SetValue('playerData', self.serialisedVersion, true)
        end
    end
    
    function self.addItem(item, count, metadata, slot, extra)
        self.inventory.AddItem(item, count, metadata, slot, extra)
    end
    
    function self.removeItem(item, count, metadata, slot, extra)
        self.inventory.RemoveItem(item, count, metadata, slot, extra)
    end

    initialised = true

    return self
end

function CalculateChange(xp, rank)
    for k, v in pairs(Core.Ranks) do
        if (v.max and xp >= v.xp and xp <= v.max) or (not v.max and xp >= v.xp) then
            return k
        end
    end
end


Core.CreateCallback('core:getPlayerData', function(player, cb)
    local xPlayer = Core.GetPlayerFromId(player:GetID())

    cb(xPlayer.serialisedVersion)
end)
