fx_version "adamant"

games { 'rdr3' }

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

-- UI
ui_page "ui/index.html"
files {
	"ui/index.html",
	"ui/script.js",
	"ui/style.css",
	"ui/crock.ttf",
	"ui/ter.png",
}

-- Client Scripts
client_scripts {
	"config.lua",
	"client.lua",
}

server_scripts {
	"config.lua",
	'server.lua',
	'@mysql-async/lib/MySQL.lua',
}