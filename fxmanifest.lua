fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Aimeri'
description 'Vivify Ammunation Shop'
version '1.0.0'

shared_script {
	'@oxmysql/lib/MySQL.lua',
	'config.lua',
}

client_scripts {
    'client.lua',
}

server_script {
	'server.lua'
}