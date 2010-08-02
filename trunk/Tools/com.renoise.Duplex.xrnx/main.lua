--[[============================================================================
main.lua
============================================================================]]--

-- includes

require "Duplex"

-- tests configurations (enable for debugging only)
-- require "testing"


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

-- instantiate all configs that the user "enabled" to autostart.
-- to be invoked from 'app_new_document_observable'

local applied_autostart_configurations = false

local function apply_autostart_configurations() 

  -- only needs to be done once, when the first song gets activated
  if (not applied_autostart_configurations) then
    applied_autostart_configurations = true
    
    for _,config in pairs(duplex_configurations) do
      local settings = configuration_settings(config)
      if (settings.autostart.value) then
        local start_running = true
        create_browser(config, start_running)
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

local available_devices = table.create(device_configuration_map:keys())
available_devices:sort()

local added_menu_entries = table.create()

for _,device_name in pairs(available_devices) do
  local prefix = "--- "
  for _,config in pairs(device_configuration_map[device_name]) do
    if (config.pinned) then
      local entry_name = ("Main Menu:Tools:Duplex: %s %s..."):format(
        config.device.display_name, config.name)
        
      -- doubled config entreis are validated below by the prefs registration
      if (not added_menu_entries:find(entry_name)) then
        added_menu_entries:insert(entry_name)
        
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

-- dynamicall register configuration settings for each config

local configuration_root_node = 
  duplex_preferences:add("configurations", renoise.Document.create())

for _,device_name in pairs(available_devices) do
  for _,config in pairs(device_configuration_map[device_name]) do

    if (config.device.display_name and config.name) then
      if (configuration_root_node[configuration_settings_key(config)]) then
      
        renoise.app():show_warning(
          ("Whoops! Device configuration '%s %s' seems to be present more "..
           "than once. Please use a unique device & config name combination "..
           "for each config."):format(config.device.display_name, config.name))
      else
      
        if (config.device.protocol == DEVICE_MIDI_PROTOCOL) then
          configuration_root_node:add(
            configuration_settings_key(config), 
            renoise.Document.create {
              autostart = false,
              device_port_in = "",
              device_port_out = ""
            }
          )
        else -- protocol == DEVICE_OSC_PROTOCOL
          configuration_root_node:add(
            configuration_settings_key(config), 
            renoise.Document.create {
              autostart = false,
              prefix = "",
              address = "",
              port = ""
            }
          )
        end        
      end
    end
  end
end

-- and assign the global duplex prefs as tool preferences to activate them
renoise.tool().preferences = duplex_preferences


--------------------------------------------------------------------------------
-- debug
--------------------------------------------------------------------------------

-- controller map authors and others to get their changes applied automatically
_AUTO_RELOAD_DEBUG = true

