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
require "Duplex/ControlMap"
require "Duplex/Device"
require "Duplex/MIDIDevice"

require "Duplex/Applications/Browser"
require "Duplex/Applications/MixConsole"
require "Duplex/Applications/PatternMatrix"

require "Duplex/Controllers/Launchpad/Launchpad"


-------------------------------------------------------------------------------
-- functions
-------------------------------------------------------------------------------

local app = nil

function show_dialog(device_name,app_name)
  if not app then
    app = Browser(device_name,app_name)
  end
  app:show_app()
end

function handle_app_idle_notification()
  if app then
    app:idle_app()
  end
end

function handle_app_new_document()
print("handle_app_new_document()")
  if app then
    app:on_new_document()
  end
end


-------------------------------------------------------------------------------
-- tool setup
-------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Duplex:Browser...",
  invoke = function() 
    show_dialog() 
  end
}

renoise.tool():add_menu_entry {
  name = "--- Main Menu:Tools:Duplex:MixConsole (Launchpad)...",
  invoke = function() 
    show_dialog("Launchpad","MixConsole") 
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Duplex:MixConsole (Nocturn)...",
  invoke = function() 
    show_dialog("Nocturn","MixConsole") 
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Duplex:PatternMatrix (Launchpad)...",
  invoke = function() 
    show_dialog("Launchpad","PatternMatrix") 
  end
}

renoise.tool().app_idle_observable:add_notifier(
  handle_app_idle_notification)

renoise.tool().app_new_document_observable:add_notifier(
  handle_app_new_document)



