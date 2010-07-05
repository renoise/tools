--[[--------------------------------------------------------------------------
main.lua
--------------------------------------------------------------------------]]--

-- includes

require "Duplex"


-------------------------------------------------------------------------------
-- locals
-------------------------------------------------------------------------------

-- the one and only browser
local browser = nil

-- dump MIDI debug option
local dump_midi = false

-- instantiate a new browser, or load a new controller configuration
local function show_dialog(config)
  if (not browser) then
    browser = Browser()
    browser:set_dump_midi(dump_midi)
  end
    
  if (config) then
    local start_running = true
    browser:set_configuration(config, start_running)
  end
  
  browser:show()
end


-------------------------------------------------------------------------------
-- menu entries
-------------------------------------------------------------------------------

-- main browser entry

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Duplex:Browser...",
  invoke = function() 
    show_dialog() 
  end
}


--  entries to quicklaunch all pinned configurations

local device_configuration_map = table.create()

for _,config in pairs(device_configurations) do
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
    return (browser ~= nil and browser:dump_midi() or dump_midi)
  end,
  invoke = function() 
    dump_midi = not dump_midi
    if (browser) then
      browser:set_dump_midi(dump_midi)
    end
  end
}


-------------------------------------------------------------------------------
-- keybindings
-------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Tools:Duplex Browser...",
  invoke = function() show_dialog() end
}


-------------------------------------------------------------------------------
-- notifications
-------------------------------------------------------------------------------

renoise.tool().app_idle_observable:add_notifier(function()
  if (browser) then
    browser:on_idle()
  end
end)

renoise.tool().app_new_document_observable:add_notifier(function()
  if (browser) then
    browser:on_new_document()
  end
end)


