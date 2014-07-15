--[[============================================================================
main.lua
============================================================================]]--

-- includes

require "Duplex"


--------------------------------------------------------------------------------
-- locals
--------------------------------------------------------------------------------

-- the one and only browser
local browser = nil

-- workaround for http://goo.gl/UnSDnw
local waiting_to_show_browser = nil


--------------------------------------------------------------------------------

-- instantiate the browser, if needed, or load a new controller configuration

local function create_browser(config, start_running)
  TRACE("main:create_browser()",config, start_running)

  start_running = start_running or true
  
  if (not browser) then
    browser = Browser()
    browser:set_dump_midi(duplex_preferences.dump_midi.value)
    browser:set_dump_osc(duplex_preferences.dump_osc.value)
    waiting_to_show_browser = duplex_preferences.display_browser_on_start.value

  end
    
  if config then
    browser:set_configuration(config, start_running)
  end


end


--------------------------------------------------------------------------------

-- show the duplex browser dialog and optionally lauch a configuration

local function show_dialog(config, start_running)
  --LOG("main:show_dialog()",config, start_running)

  create_browser(config, start_running)
  browser:show()
end

--------------------------------------------------------------------------------

--- returns a hopefully unique, xml node friendly key, that is used in the 
-- preferences tree for the given configuration

function configuration_settings_key(config)

  -- use device_name + config_name as base
  local key = (config.device.display_name .. " " .. config.name):lower()
  
  -- convert spaces to _'s
  key = key:gsub("%s", "_")
  -- remove all non alnums
  key = key:gsub("[^%w_]", "")
  -- and removed doubled _'s
  key = key:gsub("[_]+", "_")
  
  return key
end


--------------------------------------------------------------------------------

--- returns the preferences user settings node for the given configuration.
-- always valid, but properties in the settings will be empty by default

function configuration_settings(config)

  local key = configuration_settings_key(config)
  return duplex_preferences.configurations[key]
end



--------------------------------------------------------------------------------

-- instantiate all configs that the user "enabled" to autostart.
-- to be invoked from 'app_new_document_observable'

local applied_autostart_configurations = false

local function apply_autostart_configurations() 
  --LOG("main:apply_autostart_configurations()")

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
  name = "Main Menu:Tools:Duplex:Show Duplex Browser...",
  invoke = function() 
    show_dialog() 
  end,
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
  for _,config in pairs(device_configuration_map[device_name]) do
    if (config.pinned) then
      local entry_name = ("Main Menu:Tools:Duplex:%s:%s %s..."):format(
        config.device.display_name, config.device.display_name, config.name)
        
      -- duplicate config entries are validated below by the prefs registration
      if (not added_menu_entries:find(entry_name)) then
        added_menu_entries:insert(entry_name)
        
        renoise.tool():add_menu_entry {
          --name = ("%s%s"):format(entry_name),
          name = entry_name,
          selected = function() 
            return (browser ~= nil and browser:configuration_running(config))
          end,
          invoke = function() 
            show_dialog(config) 
          end
        }

      end
    end
  end
end

renoise.tool():add_menu_entry {
  name = "--- Main Menu:Tools:Duplex:Release all open devices",
  invoke = function() 
    if (browser) then
      browser:set_configuration()
    end
  end
}

renoise.tool():add_menu_entry {
  name = "--- Main Menu:Tools:Duplex:Display on startup",
  selected = function()
    return duplex_preferences.display_browser_on_start.value
  end,
  invoke = function() 
    duplex_preferences.display_browser_on_start.value = 
      not duplex_preferences.display_browser_on_start.value
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Duplex:Enable NRPN support",
  selected = function()
    return duplex_preferences.nrpn_support.value
  end,
  invoke = function() 
    duplex_preferences.nrpn_support.value = 
      not duplex_preferences.nrpn_support.value
      if duplex_preferences.nrpn_support.value then
        local msg = "You have selected to enable NRPN support. Please note that the"
                  .."\nfeature is currently experimental and might have undesired."
                  .."\nside-effects (please see http://goo.gl/BiIW6)"
        renoise.app():show_message(msg)
      end
  end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Duplex:Dump MIDI to console",
  selected = function()
    return duplex_preferences.dump_midi.value
  end,
  invoke = function() 
    duplex_preferences.dump_midi.value = not duplex_preferences.dump_midi.value
    if (browser) then
      browser:set_dump_midi(duplex_preferences.dump_midi.value)
    end
    if duplex_preferences.dump_midi.value then
      local msg = "You have selected to dump MIDI data into the Renoise scripting console"
                .."\nThis is useful when you want to identify some problem, or figure out"
                .."\nwhich messages your device is transmitting."
                .."\n"
                .."\nNote that you have to enable scripting in Renoise before you can see"
                .."\nthe scripting console (howto: http://code.google.com/p/xrnx/)"
      renoise.app():show_message(msg)
    end
  end
}
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Duplex:Dump OSC to console",
  selected = function()
    return duplex_preferences.dump_osc.value
  end,
  invoke = function() 
    duplex_preferences.dump_osc.value = not duplex_preferences.dump_osc.value
    if (browser) then
      browser:set_dump_osc(duplex_preferences.dump_osc.value)
    end
    if duplex_preferences.dump_osc.value then
      local msg = "You have selected to dump OSC messages into the Renoise scripting console"
                .."\nThis is useful when you want to identify some problem, or figure out"
                .."\nwhich messages your device is transmitting."
                .."\n"
                .."\nNote that you have to enable scripting in Renoise before you can see"
                .."\nthe scripting console (howto: http://code.google.com/p/xrnx/)"
      renoise.app():show_message(msg)
    end
  end
}

--------------------------------------------------------------------------------
-- keybindings
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Duplex:Show Browser...",
  invoke = function(repeated) 
    if (not repeated) then 
      show_dialog() 
    end
  end
}

renoise.tool():add_keybinding {
  name = "Global:Duplex:Hide Browser...",
  invoke = function(repeated) 
    if (not repeated) then 
      if (browser) then
        browser:show() 
      end
    end
  end
}

renoise.tool():add_keybinding({
  name = "Global:Duplex:Next configuration",
  invoke = function(repeated)
    if (not repeated) then 
      if (browser) then
        renoise.app():show_status("Next Duplex Configuration")
        browser:set_next_configuration()
      end
    end
  end
})

renoise.tool():add_keybinding({
  name = "Global:Duplex:Previous configuration",
  invoke = function(repeated)
    if (not repeated) then 
      if (browser) then
        renoise.app():show_status("Previous Duplex Configuration")
        browser:set_previous_configuration()
      end
    end
  end
})

for config_idx = 1,8 do
  renoise.tool():add_keybinding({
    name = string.format("Global:Duplex:Set Configuration #%02d",config_idx ),
    invoke = function(repeated)
      if (browser) then
        local config_list = 
          browser:_available_configurations_for_device(browser._device_name)
        if (config_list[config_idx]) then
          browser:set_configuration(config_list[config_idx], true)
        end
      end
    end
  })
end

--------------------------------------------------------------------------------
-- MIDI mappings
--------------------------------------------------------------------------------

renoise.tool():add_midi_mapping({
  name = "Global:Tools:Duplex:Display Browser [Set]",
  invoke = function(msg) 
    if not browser then
      create_browser()
    end
    if (browser) then
      if msg.boolean_value then 
        browser:show() 
      else
        browser:hide() 
      end
    end
  end
})

renoise.tool():add_midi_mapping({
  name = "Global:Tools:Duplex:Select configuration [Set]",
  invoke = function(msg)
    if(browser)then
      local idx = msg.int_value
      local config_list = 
        browser:_available_configurations_for_device(browser._device_name)
      if (config_list[idx]) then
        browser:set_configuration(config_list[idx], true)
      end
    end
  end
})

renoise.tool():add_midi_mapping({
  name = "Global:Tools:Duplex:Next configuration [Trigger]",
  invoke = function(msg)
    if(browser)then
      if msg:is_trigger() then 
        renoise.app():show_status("Next Duplex Configuration")
        browser:set_next_configuration()
      end
    end
  end
})

renoise.tool():add_midi_mapping({
  name = "Global:Tools:Duplex:Previous configuration [Trigger]",
  invoke = function(msg)
    if(browser)then
      if msg:is_trigger() then 
        renoise.app():show_status("Previous Duplex Configuration")
        browser:set_previous_configuration()
      end
    end
  end
})

for config_idx = 1,8 do
  renoise.tool():add_midi_mapping({
    
    name = string.format("Global:Tools:Duplex:Select configuration #%02d [Trigger]",config_idx ),
    invoke = function(msg)
      if(browser)then
        if msg:is_trigger() then 
          local config_list = 
            browser:_available_configurations_for_device(browser._device_name)
          if (config_list[config_idx]) then
            browser:set_configuration(config_list[config_idx], true)
          end
        end
      end
    end
  })
end


--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

renoise.tool().app_idle_observable:add_notifier(function()
  if (browser) then
    browser:on_idle()
  end
  if (waiting_to_show_browser) then
    waiting_to_show_browser = false
    browser:show()
  end
end)
renoise.tool().app_release_document_observable:add_notifier(function()
  --TRACE("main:app_release_document_observable fired...")
  if (browser) then
    browser:on_release_document()
  end
end)
renoise.tool().app_new_document_observable:add_notifier(function()
  --TRACE("main:app_new_document_observable fired...")
  if (browser) then
    browser:on_new_document()
  end
  apply_autostart_configurations()
end)
renoise.tool().app_became_active_observable:add_notifier(function()
  --TRACE("main:app_new_document_observable fired...")
  if (browser) then
    browser:on_window_became_active()
  end
end)
renoise.tool().app_resigned_active_observable:add_notifier(function()
  --TRACE("main:app_new_document_observable fired...")
  if (browser) then
    browser:on_window_resigned_active()
  end
end)


--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

-- dynamically register configuration settings for each config

local configuration_root_node = duplex_preferences:add_property(
  "configurations", renoise.Document.create("Configurations"){ })

for _,device_name in pairs(available_devices) do

  --LOG("main:register configurations for this device:" .. device_name)

  for _,config in pairs(device_configuration_map[device_name]) do

    if (config.device.display_name and config.name) then
      if (configuration_root_node[configuration_settings_key(config)]) then
      
        renoise.app():show_warning(
          ("Whoops! Device configuration '%s %s' seems to be present more "..
           "than once. Please use a unique device & config name combination "..
           "for each config."):format(config.device.display_name, config.name))
      else

        -- create application options
        local applications_root_node = renoise.Document.create("Applications") {}
        for app_name,app in pairs(config.applications) do
            local application_root_node = applications_root_node:add_property(
              app_name, renoise.Document.create("Application") {}
            )
            local options_node = renoise.Document.create("Options"){} 
            local option_key, option_value

            -- figure out the actual application name
            if (app.application) then
              app_name = app.application
            end

            -- only include existing applications
            if (rawget(_G, app_name)) then

              -- create default application options
              local default_options = _G[app_name]["default_options"]
              if default_options then
                for option_name,option in pairs(default_options) do
                  option_key = option_name
                  option_value = option.value
                  -- use the key from the device config if present
                  if app.options and
                    app.options[option_key] 
                  then
                    option_value = app.options[option_key] 
                  end
                  -- resolve literal keys into their index
                  if (type(option_value)=="string") then
                    for k,v in pairs(option.items) do
                      if (v == option_value) then
                        option_value = k
                      end
                    end 
                  end
                  if (type(option_value)=="string") then
                    -- could not resolve literal string
                  else
                    options_node:add_property(option_key,option_value)
                  end
                end
              end

            end

            application_root_node:add_property("options",options_node)
        end

        -- add devices...
        local device_root_node
        if (config.device.protocol == DEVICE_PROTOCOL.MIDI) then
          device_root_node = configuration_root_node:add_property(
            configuration_settings_key(config), 
            renoise.Document.create("MidiDevice") {
              autostart = false,
              pass_unhandled = false,
              device_port_in = "",
              device_port_out = "",
            }
          )
        else -- protocol == DEVICE_PROTOCOL.OSC
          device_root_node = configuration_root_node:add_property(
            configuration_settings_key(config), 
            renoise.Document.create("OscDevice") {
              autostart = false,
              pass_unhandled = false,
              device_prefix = "",
              device_address = "",
              device_port_in = "",
              device_port_out = ""
            }
          )
        end    
        -- attach application options to device
        device_root_node:add_property("applications",applications_root_node)
      end
    end
  end
end

-- and assign the global duplex prefs as tool preferences to activate them
renoise.tool().preferences = duplex_preferences

--------------------------------------------------------------------------------
-- debug
--------------------------------------------------------------------------------

-- makes things easier for controller map authors...
--_AUTO_RELOAD_DEBUG = true


--LOG("main:done initializing...")


