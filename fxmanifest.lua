fx_version "adamant"
game 'rdr3' 
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author '@Tura'
description 'A Playtime System for vorp core framework'
repository 'https://github.com/fpslaze/vorp_tura_playtime'
name 'vorp_tura_playtime'

shared_scripts {
	'config.lua',
}
client_scripts {
	'client/client.lua',
}
server_scripts {
	'@mysql-async/lib/MySQL.lua',
    '@oxmysql/lib/utils.lua',
	'server/server.lua'
} 

version '1.0'
vorp_checker 'yes'
vorp_name '^4Resource version Check^3'
vorp_github 'https://github.com/fpslaze/vorp_tura_playtime'
