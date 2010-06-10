--[[--------------------------------------------------------------------------

Duplex_browser.lua

--------------------------------------------------------------------------]]--

-- includes

require "Duplex/Application"
require "Duplex/Globals"
require "Duplex/MessageStream"
require "Duplex/Display"
require "Duplex/Canvas"
require "Duplex/UIComponent"
require "Duplex/UIToggleButton"
require "Duplex/UISlider"
require "Duplex/UISpinner"
require "Duplex/ControlMap"
require "Duplex/Device"
require "Duplex/MIDIDevice"
require "Duplex/OscDevice"
--require "Duplex/Scheduler"

require "Duplex/Applications/Browser"
require "Duplex/Applications/MixConsole"
require "Duplex/Applications/PatternMatrix"
require "Duplex/Applications/MatrixTest"

require "Duplex/Controllers/Launchpad/Launchpad"


-------------------------------------------------------------------------------
-- functions
-------------------------------------------------------------------------------

local app = nil

function show_dialog(device_name, app_name)
  if (not app or not app.dialog or not app.dialog.visible) then
    app = Browser(device_name, app_name)
  end
  app:show_app()
end


-------------------------------------------------------------------------------
-- Menu entries
-------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Duplex:Browser...",
  invoke = function() 
    show_dialog() 
  end
}

renoise.tool():add_menu_entry {
  name = "--- Main Menu:Tools:Duplex:Launchpad MixConsole...",
  invoke = function() 
    show_dialog("Launchpad", "MixConsole") 
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Duplex:Nocturn MixConsole...",
  invoke = function() 
    show_dialog("Nocturn", "MixConsole") 
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Duplex:BCF 2000 MixConsole...",
  invoke = function() 
    show_dialog("BCF-2000", "MixConsole") 
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Duplex:Launchpad PatternMatrix...",
  invoke = function() 
    show_dialog("Launchpad", "PatternMatrix") 
  end
}
--[[
renoise.tool():add_menu_entry {
  name = "--- Main Menu:Tools:Duplex:Launchpad MatrixTest...",
  invoke = function() 
    show_dialog("LaunchpadTest", "MatrixTest") 
  end
}
]]
renoise.tool():add_menu_entry {
  name = "--- Main Menu:Tools:Duplex:OHM64 MatrixTest...",
  invoke = function() 
    show_dialog("OHM64", "MatrixTest") 
  end
}


-------------------------------------------------------------------------------
-- Notifications
-------------------------------------------------------------------------------

renoise.tool().app_idle_observable:add_notifier(function()
  if app then
    app:idle_app()
  end
end)

renoise.tool().app_new_document_observable:add_notifier(function()
  if app then
    app:on_new_document()
  end
end)


