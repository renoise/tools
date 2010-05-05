--[[--------------------------------------------------------------------------

Duplex_browser.lua

--------------------------------------------------------------------------]]--

-- manifest

manifest = {}
manifest.api_version = 0.1
manifest.author = "danoise [bjorn.nesby@gmail.com]"
manifest.description = "Duplex application browser"

manifest.actions = {}
manifest.actions[#manifest.actions + 1] = {
	name = "MainMenu:Tools:Duplex:Browser",
	description = "Duplex",
	invoke = function() 
		show_dialog() 
	end
}
manifest.actions[#manifest.actions + 1] = {
	name = "MainMenu:Tools:Duplex:MixConsole (Launchpad)",
	description = "Duplex",
	invoke = function() 
		show_dialog("Launchpad","MixConsole") 
	end
}
manifest.actions[#manifest.actions + 1] = {
	name = "MainMenu:Tools:Duplex:PatternMatrix (Launchpad)",
	description = "Duplex",
	invoke = function() 
		show_dialog("Launchpad","PatternMatrix") 
	end
}



manifest.notifications = {}
--manifest.notifications.auto_reload_debug = function() test_my_tool() end
manifest.notifications.app_idle = function() handle_app_idle_notification() end

--print(os.currentdir())

-- included files

require "Duplex/Application"
require "Duplex/MixConsole"
require "Duplex/Browser"
require "Duplex/Point"
require "Duplex/Globals"
require "Duplex/Message"
require "Duplex/MessageStream"
require "Duplex/Display"
require "Duplex/Canvas"
require "Duplex/DisplayObject"
require "Duplex/ToggleButton"
require "Duplex/Slider"
require "Duplex/ControlMap"
require "Duplex/Device"
require "Duplex/MIDIDevice"
require "Duplex/Launchpad"
require "Duplex/PatternMatrix"

local app = nil

function show_dialog(device_name,app_name)
	if not app then
		app = Browser(device_name,app_name)
	end
	app.show_app(app)
end

function handle_app_idle_notification()
	if app then
		app.idle_app(app)
	end
end


