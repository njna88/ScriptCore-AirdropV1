local activeCrate = nil
local RESOURCE_NAME <const> = "ScriptCore-AirdropV1"

--- Sikkerhedscheck: Stopper scriptet hvis mappenavnet er forkert
if GetCurrentResourceName() ~= RESOURCE_NAME then
    print("^1[FEJL] Resource navnet er forkert!^7")
    print(("^1[FEJL] Dette script SKAL hedde '%s' for at Starte.^7"):format(RESOURCE_NAME))
    return
end

--- Log helper
local function LogAction(message)
    print(("[ScriptCore.dk | Airdrop] %s"):format(message))
end

--- Function to stop an active Airdrop
local function StopAirdrop()
    if not activeCrate then 
        return false, "Der er intet aktivt Airdrop at stoppe."
    end
    
    TriggerClientEvent("airdrop:client:despawn", -1)
    activeCrate = nil
    LogAction("Airdrop blev stoppet manuelt af en Administrator.")
    return true
end

local function StartAirdrop(locationIndex, lootType)
    if activeCrate then 
        return false, "Et Airdrop er Allerede aktivt."
    end
    
    local location = Config.DropLocations[locationIndex]
    local lootData = Config.LootPresets[lootType]

    if not location or not lootData then
        return false, "Ugyldig lokation eller loot type."
    end
    
    activeCrate = {
        coords = location.coords,
        loot = lootData.items,
        spawnTime = os.time(),
        locationLabel = location.label
    }

    TriggerClientEvent("airdrop:client:spawnPlane", -1, location.coords)
    
    -- Global notification
    TriggerClientEvent("ox_lib:notify", -1, {
        title = "ScriptCore.dk | Airdrop",
        description = "Et Airdrop er på vej mod " .. location.label .. "!",
        type = "inform"
    })

    -- Despawn timer
    SetTimeout(Config.DespawnTime * 60000, function()
        if activeCrate then
            TriggerClientEvent("airdrop:client:despawn", -1)
            activeCrate = nil
            LogAction("Airdrop despawned pga. timeout.")
        end
    end)
    
    return true
end

--- Callback to check if airdrop is active
lib.callback.register("airdrop:server:isActive", function(source)
    return activeCrate ~= nil
end)

--- Admin Command with Menu Trigger
lib.addCommand("AirdropV1", {
    help = "Åben Airdrop Kontrolpanel",
    restricted = "group.admin"
}, function(source, args, raw)
    TriggerClientEvent("airdrop:client:openAdminMenu", source)
end)

--- Server Event for triggering from Menu
RegisterNetEvent("airdrop:server:requestAirdrop", function(data)
    local src = source
    local success, message = StartAirdrop(data.location, data.loot)
    
    if success then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "ScriptCore.dk",
            description = "Airdrop succesfuldt sat i gang!",
            type = "success"
        })
    else
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Fejl",
            description = message,
            type = "error"
        })
    end
end)

--- Server Event to stop airdrop
RegisterNetEvent("airdrop:server:stopAirdrop", function()
    local src = source
    local success, message = StopAirdrop()
    
    if success then
        TriggerClientEvent("ox_lib:notify", src, {
            title = "ScriptCore.dk",
            description = "Airdrop er blevet stoppet og fjernet!",
            type = "success"
        })
    else
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Fejl",
            description = message,
            type = "error"
        })
    end
end)

--- Police Alert Logic
RegisterNetEvent("airdrop:server:notifyPolice", function()
    local src = source
    if not activeCrate then return end

    if math.random(1, 100) <= Config.PoliceAlarmChance then
        local coords = activeCrate.coords
        local players = GetPlayers()
        
        for i = 1, #players do
            local targetSrc = tonumber(players[i])
            TriggerClientEvent("airdrop:client:policeAlert", targetSrc, coords, activeCrate.locationLabel)
        end
        LogAction("Politiet er blevet underrettet om tyveri ved " .. activeCrate.locationLabel)
    end
end)

--- Looting Logic with Weight Correction
RegisterNetEvent("airdrop:server:claimLoot", function()
    local src = source
    if not activeCrate then return end
    
    local inventory = exports.ox_inventory
    local lootTable = activeCrate.loot
    local finalLoot = {}
    local totalWeight = 0
    local maxWeight = Config.MaxLootWeight or 15000

    -- Beregn og begræns loot baseret på vægt (Max 15kg)
    for _, item in pairs(lootTable) do
        local itemData = inventory:Items(item.name)
        if itemData then
            local itemWeight = itemData.weight or 0
            local possibleCount = item.count

            if (totalWeight + (itemWeight * possibleCount)) > maxWeight then
                local remainingWeight = maxWeight - totalWeight
                if remainingWeight > 0 then
                    possibleCount = math.floor(remainingWeight / itemWeight)
                else
                    possibleCount = 0
                end
            end

            if possibleCount > 0 then
                table.insert(finalLoot, {name = item.name, count = possibleCount})
                totalWeight = totalWeight + (itemWeight * possibleCount)
            end
        end
    end

    -- Check if player can carry the corrected loot
    local canCarryAll = true
    for _, item in pairs(finalLoot) do
        if not inventory:CanCarryItem(src, item.name, item.count) then
            canCarryAll = false
            break
        end
    end

    if canCarryAll and #finalLoot > 0 then
        for _, item in pairs(finalLoot) do
            inventory:AddItem(src, item.name, item.count)
        end
        LogAction(GetPlayerName(src) .. " lootede airdroppet. Total vægt: " .. (totalWeight/1000) .. "kg")
        activeCrate = nil
        TriggerClientEvent("airdrop:client:despawn", -1)
    else
        TriggerClientEvent("ox_lib:notify", src, {
            title = "Fejl",
            description = "Du har ikke plads i din taske til Airdroppet´s indhold!",
            type = "error"
        })
    end
end)