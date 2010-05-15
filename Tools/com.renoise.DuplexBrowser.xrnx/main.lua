--[[--------------------------------------------------------------------------

Duplex_browser.lua

--------------------------------------------------------------------------]]--

-- includes

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
require "Duplex/PatternMatrix"
require "Duplex/Controllers/Launchpad/Launchpad"


-------------------------------------------------------------------------------
-- functions
-------------------------------------------------------------------------------

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


-------------------------------------------------------------------------------
-- tool setup
-------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Duplex:Browser",
  invoke = function() 
    show_dialog() 
  end
}

renoise.tool():add_menu_entry {
  name = "--- Main Menu:Tools:Duplex:MixConsole (Launchpad)",
  invoke = function() 
    show_dialog("Launchpad","MixConsole") 
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Duplex:PatternMatrix (Launchpad)",
  invoke = function() 
    show_dialog("Launchpad","PatternMatrix") 
  end
}

renoise.tool().app_idle_observable:add_notifier(
  handle_app_idle_notification)



