--[[============================================================================
main.lua
============================================================================]]--

-- includes

require "Duplex"

-- enable tests

require "testing"

--------------------------------------------------------------------------------
-- locals
--------------------------------------------------------------------------------

-- the one and only browser
local browser = nil


--------------------------------------------------------------------------------

-- instantiate the browser, if needed, or load a new controller configuration

local function create_browser(config, start_running)
  start_running = start_running or true
  
  if (not browser) then
    browser = Browser()
    browser:set_dump_midi(duplex_preferences.dump_midi.value)
  end
    
  if (config) then
    browser:set_configuration(config, start_running)
  end
end


--------------------------------------------------------------------------------

-- show the duplex browser dialog and optionally lauch a configuration

local function show_dialog(config, start_running)
  create_browser(config, start_running)
  browser:show()
end


--------------------------------------------------------------------------------

-- instantiate all configs that the user "enabled" to autostart
-- to be invoked from app_new_document_observable 

local applied_autostart_configurations = false

local function apply_autostart_configurations() 

  -- only needs to be done once, when the first song gets activated
  if (not applied_autostart_configurations) then
    applied_autostart_configurations = true
    
    local autostart_configurations = duplex_preferences.autostart_configurations    
    for i=1, #autostart_configurations do     
      local device_config_name = autostart_configurations[i].value      
      if (device_config_name ~= "") then
      
        -- find the config
        local matching_config
        for _,config in pairs(duplex_configurations) do
          local config_autostart_name = 
            config.device.display_name .. " " .. config.name
          
          if (device_config_name == config_autostart_name) then
            matching_config = config
            break
          end
        end
        
        -- and start it
        if (matching_config) then
          local start_running = true
          create_browser(matching_config, start_running)
        end
      end
    end
  end  
end



--------------------------------------------------------------------------------
-- menu entries
--------------------------------------------------------------------------------

-- main browser entry

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Duplex:Browser...",
  invoke = function() 
    show_dialog() 
  end
}


--  entries to quicklaunch all pinned configurations

local device_configuration_map = table.create()

for _,config in pairs(duplex_configurations) do
  if (config.device and config.device.display_name) then
    local device_name = config.device.display_name
    if (not device_configuration_map[device_name]) then
      device_configuration_map[device_name] = table.create{config}
    else
      device_configuration_map[device_name]:insert(config)
    end
  end
end

local avilable_devices = table.create(device_configuration_map:keys())
avilable_devices:sort()

for _,device_name in pairs(avilable_devices) do
  local prefix = "--- "
  for _,config in pairs(device_configuration_map[device_name]) do
    if (config.pinned) then
      local entry_name = ("Main Menu:Tools:Duplex: %s %s..."):format(
        config.device.display_name, config.name)
        
      renoise.tool():add_menu_entry {
        name = ("%s%s"):format(prefix,entry_name),
        selected = function() 
          return (browser ~= nil and browser:configuration_running(config))
        end,
        invoke = function() 
          show_dialog(config) 
        end
      }
      prefix = ""
    end
  end
end

renoise.tool():add_menu_entry {
  name = "--- Main Menu:Tools:Duplex:Dump MIDI",
  selected = function()
    return duplex_preferences.dump_midi.value
  end,
  invoke = function() 
    duplex_preferences.dump_midi.value = not duplex_preferences.dump_midi.value
    if (browser) then
      browser:set_dump_midi(duplex_preferences.dump_midi.value)
    end
  end
}


--------------------------------------------------------------------------------
-- keybindings
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:Duplex Browser...",
  invoke = function() show_dialog() end
}


--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

renoise.tool().app_idle_observable:add_notifier(function()
  if (browser) then
    browser:on_idle()
  end
end)

renoise.tool().app_new_document_observable:add_notifier(function()
  if (browser) then
    browser:on_new_document()
  end

  apply_autostart_configurations()
end)


--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

-- assign the global duplex prefs as tool preferences
renoise.tool().preferences = duplex_preferences


--------------------------------------------------------------------------------
-- debug
--------------------------------------------------------------------------------

_AUTO_RELOAD_DEBUG = function()
  -- autoload device the configs from the prefs when changing duplex sources
  apply_autostart_configurations()
end

