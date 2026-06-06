local currentCrateObj = nil
local currentBlip = nil
local extraBlip = nil
local activeZone = nil
local RESOURCE_NAME <const> = "ScriptCore-AirdropV1"

--- Sikkerhedscheck ved opstart
CreateThread(function()
    if GetCurrentResourceName() ~= RESOURCE_NAME then
        while true do
            print("^1[FEJL] ScriptCore-AirdropV1 systemet er deaktiveret pga. forkert mappenavn!^7")
            Wait(10000)
        end
    end
end)

--- Admin Menu Logic
RegisterNetEvent("airdrop:client:openAdminMenu", function()
    if GetCurrentResourceName() ~= RESOURCE_NAME then return end

    local isActive = lib.callback.await("airdrop:server:isActive", false)
    
    local menuOptions = {
        {
            title = "Start Nyt Airdrop",
            description = "Start Et Airdrop",
            icon = "parachute-box",
            onSelect = function()
                OpenStartDialog()
            end
        }
    }

    if isActive then
        table.insert(menuOptions, {
            title = "STOP AKTIVT AIRDROP",
            description = "Sletter Airdroppet og Blips for Alle spillere",
            icon = "circle-xmark",
            iconColor = "#ff4d4d",
            onSelect = function()
                local alert = lib.alertDialog({
                    header = "Stop Airdrop",
                    content = "Er du sikker på, at du vil stoppe det aktive airdrop?",
                    centered = true,
                    cancel = true
                })
                if alert == "confirm" then
                    TriggerServerEvent("airdrop:server:stopAirdrop")
                end
            end
        })
    end

    lib.registerContext({
        id = "airdrop_main_menu",
        title = "ScriptCore.dk | Kontrolpanel",
        options = menuOptions
    })

    lib.showContext("airdrop_main_menu")
end)

function OpenStartDialog()
    local locations = {}
    for i, loc in ipairs(Config.DropLocations) do
        table.insert(locations, { value = i, label = loc.label })
    end

    local loots = {}
    for key, data in pairs(Config.LootPresets) do
        table.insert(loots, { value = key, label = data.label })
    end

    local input = lib.inputDialog("Konfigurer Airdrop", {
        { type = "select", label = "Vælg Lokation", options = locations, required = true },
        { type = "select", label = "Vælg Loot Indhold", options = loots, required = true }
    })

    if not input then return end

    TriggerServerEvent("airdrop:server:requestAirdrop", {
        location = input[1],
        loot = input[2]
    })
end

--- Police Alert Client Side
RegisterNetEvent("airdrop:client:policeAlert", function(coords, locationLabel)
    if GetCurrentResourceName() ~= RESOURCE_NAME then return end

    local myJob = nil
    
    if GetResourceState("qb-core") == "started" then
        myJob = exports["qb-core"]:GetCoreObject().Functions.GetPlayerData().job.name
    elseif GetResourceState("es_extended") == "started" then
        myJob = exports.es_extended:getSharedObject().GetPlayerData().job.name
    end

    local isPolice = false
    for _, job in ipairs(Config.PoliceJobs) do
        if myJob == job then isPolice = true break end
    end

    if not isPolice then return end

    lib.notify({
        title = "POLITI ALARM",
        description = "Tyveri af Airdrop i gang ved " .. locationLabel .. "!",
        type = "error",
        duration = 10000
    })

    PlaySoundFrontend(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0)

    local alertBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(alertBlip, 161)
    SetBlipScale(alertBlip, 1.5)
    SetBlipColour(alertBlip, 1)
    PulseBlip(alertBlip)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("ALARM: Airdrop Tyveri")
    EndTextCommandSetBlipName(alertBlip)

    Wait(60000)
    RemoveBlip(alertBlip)
end)

--- Finder den præcise jordhøjde
local function GetSafeGroundZ(x, y, z)
    local foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z, 0)
    if foundGround then return groundZ end
    return z
end

local function CreateAirdropBlip(coords)
    if currentBlip then RemoveBlip(currentBlip) end
    if extraBlip then RemoveBlip(extraBlip) end
    
    currentBlip = AddBlipForRadius(coords.x, coords.y, coords.z, 200.0)
    SetBlipHighDetail(currentBlip, true)
    SetBlipColour(currentBlip, 1) 
    SetBlipAlpha(currentBlip, 128) 
    
    extraBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(extraBlip, 478) 
    SetBlipDisplay(extraBlip, 4)
    SetBlipScale(extraBlip, 0.8)
    SetBlipColour(extraBlip, 1)
    SetBlipAsShortRange(extraBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("ScriptCore.dk | Airdrop")
    EndTextCommandSetBlipName(extraBlip)
end

RegisterNetEvent("airdrop:client:spawnPlane", function(coords)
    if GetCurrentResourceName() ~= RESOURCE_NAME then return end
    CreateAirdropBlip(coords)
    
    local modelName = Config.CrateModel
    local modelHash = type(modelName) == "string" and GetHashKey(modelName) or modelName
    
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(10) end

    local groundZ = GetSafeGroundZ(coords.x, coords.y, coords.z)
    
    currentCrateObj = CreateObject(modelHash, coords.x, coords.y, groundZ, true, false, false)
    SetEntityLodDist(currentCrateObj, 1500) 
    PlaceObjectOnGroundProperly(currentCrateObj)
    FreezeEntityPosition(currentCrateObj, true)
    
    local asset = "core"
    if not HasNamedPtfxAssetLoaded(asset) then
        RequestNamedPtfxAsset(asset)
        while not HasNamedPtfxAssetLoaded(asset) do Wait(10) end
    end
    
    UseParticleFxAssetNextCall(asset)
    StartNetworkedParticleFxLoopedOnEntity("exp_grd_flare", currentCrateObj, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 3.0, false, false, false)

    activeZone = lib.points.new({
        coords = coords,
        distance = 5, 
        nearby = function(self)
            if currentCrateObj then
                lib.showTextUI("[E] Gennemsøg Airdroppet")
                if IsControlJustReleased(0, 38) then
                    StartOpening()
                end
            end
        end,
        onExit = function()
            lib.hideTextUI()
        end
    })
end)

function StartOpening()
    lib.hideTextUI()
    TriggerServerEvent("airdrop:server:notifyPolice")

    if lib.progressBar({
        duration = Config.CaptureTime * 1000,
        label = "Tømmer Kassen fra Airdroppet...",
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { 
            dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", 
            clip = "machinic_loop_mechandplayer",
            flag = 1
        }
    }) then
        TriggerServerEvent("airdrop:server:claimLoot")
        ClearPedTasks(cache.ped)
    else
        lib.notify({description = "Du afbrød gennemsøgningen!", type = "error"})
        ClearPedTasks(cache.ped)
    end
end

RegisterNetEvent("airdrop:client:despawn", function()
    if currentCrateObj then DeleteEntity(currentCrateObj) end
    if currentBlip then RemoveBlip(currentBlip) end
    if extraBlip then RemoveBlip(extraBlip) end
    if activeZone then activeZone:remove() end
    currentCrateObj = nil
    activeZone = nil
    currentBlip = nil
    extraBlip = nil
    lib.hideTextUI()
end)