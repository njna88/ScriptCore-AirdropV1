Config = {}

Config.AirdropInterval = {90, 120} -- Minutter
Config.DespawnTime = 15 -- Minutter indtil containeren forsvinder
Config.CaptureTime = 60 -- Sekunder det tager at gennemsøge

Config.CrateModel = "p_secret_weapon_02" 
Config.PlaneModel = "bombushka"

-- Max Vægt
Config.MaxLootWeight = 1500 

-- Politiet
Config.PoliceJobs = {"police", "sheriff"}
Config.PoliceAlarmChance = 100 -- Procent chance for at alarmen går (100 = altid)

-- Loot 
Config.LootPresets = {
    ["illegal_drugs"] = {
        label = "Massar Stoffer",
        items = {
            {name = "meth_pooch", count = 250},
            {name = "coke_pooch", count = 250},
            {name = "weed_pooch", count = 250}
        }
    },
    ["heavy_weapons"] = {
        label = "Massar Våben",
        items = {
            {name = "weapon_pistol50", count = 1, isWeapon = true},
            {name = "weapon_revolver", count = 1, isWeapon = true},
            {name = "weapon_pumpshotgun", count = 1, isWeapon = true}
        }
    },
    ["criminal_package"] = {
        label = "Kriminel Pakke",
        items = {
            {name = "meth_pooch", count = 250},
            {name = "coke_pooch", count = 250},
            {name = "weapon_pistol50", count = 1, isWeapon = true},
            {name = "armor", count = 1}
        }
    },
    ["supplies"] = {
        label = "Forsyninger",
        items = {
            {name = "water", count = 50},
            {name = "bread", count = 50},
            {name = "armor", count = 10}
        }
    }
}

Config.DropLocations = {
    { label = "Sandy Lufthavn", coords = vector3(1081.7413, 3048.2153, 40.8767) },
    { label = "Grapeseed", coords = vector3(1946.1310, 4986.1924, 42.8242) },
    { label = "Havnen", coords = vector3(244.9306, -3327.0786, 5.7999) },
    { label = "Lufthavnen", coords = vector3(-791.4904, -2856.5127, 13.9474) },
    { label = "Kortz", coords = vector3(-2284.2383, 277.4862, 194.6017) },
    { label = "Paleto Bay", coords = vector3(275.9824, 6834.2451, 17.8069) }
}