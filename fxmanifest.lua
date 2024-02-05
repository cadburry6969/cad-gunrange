fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'complexza & Cadburry (ByteCode Studios)'
description 'Weapons Firing Range'
version '1.0'

client_scripts {
    'config/cfg_client.lua',
    'client.lua',
}

server_scripts {
    'config/cfg_server.lua',
    'server.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
}

dependencies {
    'ox_lib'
}