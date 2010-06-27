--[[--------------------------------------------------------------------------

Duplex_browser.lua

--------------------------------------------------------------------------]]--

-- includes

require "Duplex/Duplex"


-------------------------------------------------------------------------------
-- functions
-------------------------------------------------------------------------------

local app = nil
local app = Browser()


function show_dialog(device_name, app_name)
  --if (not app or not app.dialog) then
  if (not app) then
    app = Browser(device_name, app_name)
  else
    if (device_name) then
      app:set_device(device_name)
      
      if (app_name) then
        local start_running = true
        app:set_application(app_name, start_running)
      end
    end
  end
  
  app:show_app()
end


-------------------------------------------------------------------------------
-- Menu entries (the browser will expand this)
-------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Duplex:Browser...",
  invoke = function() 
    show_dialog() 
  end
}

app:build_menu()

--[[
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
  name = "--- Main Menu:Tools:Duplex:Launchpad PatternMatrix...",
  invoke = function() 
    show_dialog("Launchpad", "PatternMatrix") 
  end
}
renoise.tool():add_menu_entry {
  name = "--- Main Menu:Tools:Duplex:LaunchpadTest MixConsole",
  invoke = function() 
    show_dialog("LaunchpadTest", "MixConsole") 
  end
}
renoise.tool():add_menu_entry {
  name = "--- Main Menu:Tools:Duplex:OHM64 PatternMatrix",
  invoke = function() 
    show_dialog("OHM64", "PatternMatrix") 
  end
}
]]
-------------------------------------------------------------------------------
-- Keybindings
-------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:Duplex Browser",
  invoke = function() show_dialog() end
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


