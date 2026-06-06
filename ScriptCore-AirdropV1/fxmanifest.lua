fx_version "cerulean"
game "gta5"

author "ScriptCore.dk"
description "ScriptCore.dk | Airdrop System"
version "1.0.0"


dependency "ox_lib"
shared_script "@ox_lib/init.lua"

shared_scripts {
    "config.lua"
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/main.lua"
}

client_scripts {
    "client/main.lua"
}

escrow_ignore{
    "config.lua",
}