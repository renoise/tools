--[[----------------------------------------------------------------------------
-- Duplex.Browser
----------------------------------------------------------------------------]]--


local NOT_AVAILABLE_POSTFIX = " [N/A]"
local RUNNING_POSTFIX = " (running)"


--==============================================================================

-- The Browser class shows and instantiates registered device configurations
-- and shows the virtual UI for them. More than one configuration can be 
-- active and running for multiple devices.

class 'Browser'

function Browser:__init(initial_configuration, start_configuration)
  TRACE("Browser:__init")

  
  ---- properties

  -- list of duplex device configuration definitions
  self._available_configurations = duplex_configurations

  -- processes is a table containing BrowserProcess processes
  self._processes = table.create()
  
  -- string, selected device display-name 
  self._device_name = nil 
  -- string, selected configuration for the current device
  self._configuration_name = nil

  -- dump midi information to console (debug option)
  self._dump_midi = false

  -- true while updating the GUI from within the internal browser functions, 
  -- to avoid doubling updates when the changes are not fired from the GUI
  self._suppress_notifiers = false
  
  
  ---- components
  
  -- view builder that we do use for all our views
  self._vb = renoise.ViewBuilder()
  
  -- referenc eto the main dialog that we create
  self._dialog = nil
  

  ---- build the GUI

  self:_create_content_view()

  
  ---- activate default config

  -- select none by default
  self:set_device("None")
  
  -- as last step, apply optional arguments (autostart devices)
  if (initial_configuration) then
    self:set_configuration(initial_configuration, start_configuration)
  end


  ---- attach to configuration settings
  
  -- MIDI port setup changed
  renoise.Midi.devices_changed_observable():add_notifier(
    Browser._available_device_ports_changed, self
  )
  
  -- MIDI port configs changed
  for _,config in pairs(duplex_configurations) do
    local settings = configuration_settings(config)
    if (settings.device_port_out) then
      settings.device_port_out:add_notifier(
        Browser._device_ports_changed, self
      )
    end
    if (settings.device_port_in) then
      settings.device_port_in:add_notifier(
        Browser._device_ports_changed, self
      )
    end
  end    
end


--------------------------------------------------------------------------------

-- activates and shows the dialog, or brings the existing one to front

function Browser:show()
  TRACE("Browser:show()")
  
  if (not self._dialog or not self._dialog.visible) then
    assert(self._content_view, "Internal Error. Please report: " .. 
      "browser always needs a valid content view")

    -- switch configuration using the function keys
    local function keyhandler(dialog, key)
      local fkey = (string.match(key.name,"f([%d]+)"))
      if (key.modifiers=="") and (fkey~=nil) then
        fkey = fkey *1
        local config_list = 
          self:_available_configurations_for_device(self._device_name)
        if (config_list[fkey]) then
          self:set_configuration(config_list[fkey], true)
        end
      else
        return key
      end
    end

    self._dialog = renoise.app():show_custom_dialog(
      "Duplex Browser", self._content_view,keyhandler)
  else
    self._dialog:show()
  end
end

--------------------------------------------------------------------------------

-- hide the dialog

function Browser:hide()
  TRACE("Browser:hide()")

  if (self._dialog and self._dialog.visible) then
    self._dialog:close()
  end

  self._dialog = nil

end


--------------------------------------------------------------------------------

-- forwards idle notifications to all active processes

function Browser:on_idle()
  -- TRACE("Browser:on_idle()")
  
  for _,process in pairs(self._processes) do
    process:on_idle()
  end
end


--------------------------------------------------------------------------------

-- forwards new document notifications to all active processes

function Browser:on_new_document()
  TRACE("Browser:on_new_document()")

  for _,process in pairs(self._processes) do
    process:on_new_document()
  end
end


--------------------------------------------------------------------------------

-- return a list of valid devices (plus a "None" option)
-- existing devices (ones that we found MIDI ports for) are listed first,
-- all others are listed as (N/A) to indicate that they are not present
-- in the users device setup

function Browser:available_devices()

  -- devices that are installed on this system 
  local installed_devices = table.create()
  
  local input_devices = table.create(renoise.Midi.available_input_devices())
  local output_devices = table.create(renoise.Midi.available_output_devices())
  
  for _,config in pairs(self._available_configurations) do
    local settings = configuration_settings(config)
    
    local device_port_in = (settings.device_port_in.value ~= "") and 
      settings.device_port_in.value or config.device.device_port_in
      
    local device_port_out = (settings.device_port_out.value ~= "") and 
      settings.device_port_out.value or config.device.device_port_out
  
    local display_name = config.device.display_name
    
    if (input_devices:find(device_port_in) and 
        output_devices:find(device_port_out) and 
        not installed_devices:find(display_name)) 
    then
      installed_devices:insert(display_name)
    end
  end
  
  -- all others that are available in duplex but could not be found
  local remaining_devices = table.create()
  
  for _,config in pairs(self._available_configurations) do
    local display_name = config.device.display_name
    if (not installed_devices:find(display_name) and
        not remaining_devices:find(display_name .. NOT_AVAILABLE_POSTFIX))
    then
      remaining_devices:insert(display_name .. NOT_AVAILABLE_POSTFIX)
    end
  end

  -- build the final list, prepending "none"
  local result = table.create{ "None" }
  
  installed_devices:sort()
  for _,device in pairs(installed_devices) do
    result:insert(device)
  end
  
  remaining_devices:sort()
  for _,device in pairs(remaining_devices) do
    result:insert(device)
  end
  
  return result
end


--------------------------------------------------------------------------------

-- change the active input device:
-- instantiates a new device, using the first avilable configuration for it,
-- or reusing an already running configuration
-- @param name (string) device display-name, without postfix
-- @param configuration_hint (optional table) configuration that should be 
-- used to instantiate the device. when nil, a default one is selected from the 
-- available device configs

function Browser:set_device(device_display_name, configuration_hint)
  TRACE("Browser:set_device("..device_display_name..")")
  
    
  ---- activate the device with its default or existing config
  
  if (self._device_name ~= device_display_name) then
    
    self._device_name = self:_strip_postfixes(device_display_name)
    self._configuration_name = "None"
  
    if (device_display_name == "None") then
      TRACE("Browser:releasing all processes")
      
      -- release all devices & applications
      while (not self._processes:is_empty()) do
        self._processes[#self._processes]:invalidate()
        self._processes:remove(#self._processes)
      end

      -- make sure all configuration settings are also cleared
      self:set_configuration(nil)
    
    else
      TRACE("Browser:assigning new process")
      
      assert(configuration_hint == nil or 
        configuration_hint.device.display_name == device_display_name, 
        "Internal Error. Please report: invalid device configuration hint")
        
      local configuration = configuration_hint or nil
          
      -- use an already running process by default
      if (not configuration) then
        for _,process in pairs(self._processes) do
          local process_device_name = process.configuration.device.display_name
          if (process_device_name == device_display_name) then
            configuration = process.configuration
            break
          end
        end
      end
      
      -- else the first listed one for the device
      if (not configuration) then
        for _,config in pairs(self._available_configurations) do 
          if (device_display_name == config.device.display_name) then
            configuration = config
            break
          end
        end
      end
      
      assert(configuration, ("Internal Error. Please report: " ..
        "found no configuration for device '%s'"):format(
        device_display_name))

      -- there may be no configs for the device
      self:set_configuration(configuration)
    end
  end
  

  ---- update the GUI, in case this function was not fired from the GUI

  local suppress_notifiers = self._suppress_notifiers
  self._suppress_notifiers = true

  local available_configuration_names = 
    self:_available_configuration_names_for_device(self._device_name)

  self._vb.views.dpx_browser_configurations.items = 
    available_configuration_names

  local index = self:_device_index_by_name(self._device_name)
  self._vb.views.dpx_browser_input_device.value = index
  
  self:_decorate_device_list()

  self._suppress_notifiers = suppress_notifiers
end


--------------------------------------------------------------------------------

-- return list of valid configurations for the given device 

function Browser:available_configurations(device_name)
  TRACE("Browser:available_configurations:",device_name)
  
  return self:_available_configurations_for_device(device_name)
end


--------------------------------------------------------------------------------

-- returns true if the given config is instantiated and running

function Browser:configuration_running(configuration)
  TRACE("Browser:configuration_running:",configuration.name)
  
  for _,process in pairs(self._processes) do
    if (process:matches_configuration(configuration)) then
      return process:running()
    end
  end
  
  return false
end

--------------------------------------------------------------------------------

-- activate the previous configuration (if active, has previous)

function Browser:set_previous_configuration()
  TRACE("Browser:set_previous_configuration()")
  if not self._configuration_name or not self._device_name then
    return
  end
  local available_configuration_names = 
    self:_available_configuration_names_for_device(self._device_name)
  local config_idx = 0
  for _,config_name in pairs(available_configuration_names) do
    if (config_name == self._configuration_name) then
      if (config_idx>0) then
        local config_list = 
          self:_available_configurations_for_device(self._device_name)
        local start_running = true
        self:set_configuration(config_list[config_idx], start_running)
        return
      end
    end
    config_idx = config_idx+1 
  end
end

--------------------------------------------------------------------------------

-- activate the next configuration (if active, has next)

function Browser:set_next_configuration()
  TRACE("Browser:set_next_configuration()")
  if not self._configuration_name or not self._device_name then
    return
  end
  local available_configuration_names = 
    self:_available_configuration_names_for_device(self._device_name)
  local config_idx = 2
  for _,config_name in pairs(available_configuration_names) do
    if (config_name == self._configuration_name) then
      if (config_idx<#available_configuration_names) then
        local config_list = 
          self:_available_configurations_for_device(self._device_name)
        local start_running = true
        self:set_configuration(config_list[config_idx], start_running)
        return
      end
    end
    config_idx = config_idx+1 
  end
end

--------------------------------------------------------------------------------

-- activate a new configuration for the currently active device

function Browser:set_configuration(configuration, start_running)
  TRACE("Browser:set_configuration:", configuration and 
    configuration.name or "None")
  
  start_running = start_running or false

  -- passing no configuration should deinitialize and update the GUI only
  if (configuration ~= nil) then
  
    ---- first make sure the configs device is selected
    
    self:set_device(configuration.device.display_name, configuration)
    
  
    ---- then apply the config, if necessary  
    
    if (self._configuration_name ~= configuration.name) then
      self._configuration_name = configuration.name
      
      -- switching to an existing running process?
      local existing_process = nil
      for _,process in pairs(self._processes) do
        if (process:matches_configuration(configuration)) then
          existing_process = process
          break
        end
      end
      
      if (existing_process) then
        TRACE("Browser:switching to existing process")
            
        -- hide previous instantiated control-maps
        for _,process in pairs(self._processes) do
          if (process ~= existing_process) then
            if (process:control_surface_visible()) then
              process:hide_control_surface()
            end
          end
        end
        
        -- and show the new one
        existing_process:show_control_surface(
          self._vb.views.dpx_browser_device_ui_row)
  
      else
        TRACE("Browser:creating new process")
    
        -- remove already running processes for this device
        for process_index,process in ripairs(self._processes) do
          local process_device_name = process.configuration.device.display_name
          if (process_device_name == self._device_name) then
            process:invalidate()
            self._processes:remove(process_index)
            break
          end
        end
      
        -- hide previous instantiated control-maps from other devices
        for _,process in pairs(self._processes) do
          if (process:control_surface_visible()) then
            process:hide_control_surface()
          end
        end
        
        -- create a new process 
        local new_process = BrowserProcess()
        
        if (new_process:instantiate(configuration)) then
          
          -- apply debug options
          new_process:set_dump_midi(self._dump_midi)
          
          -- show it (add the control map GUI to the browser)
          new_process:show_control_surface(
            self._vb.views.dpx_browser_device_ui_row)
  
          -- and add it to the list of active processes
          self._processes:insert(new_process)
        
        else
          self._configuration_name = "None" 
        end
      end
    end
  
  else
  
    self:set_device("None")
    self._configuration_name = "None" 
  end
  

  ---- validate the process list
  
  for _,process in pairs(self._processes) do
    assert(process:instantiated(), "Internal Error. Please report: " ..
      "should only have instantiated processes listed")
  end


  ---- apply start options
  
  if (self:_current_process() and start_running) then
    self:start_current_configuration()
  end
  
    
  ---- update the GUI, in case this function was not fired from the GUI

  local suppress_notifiers = self._suppress_notifiers
  self._suppress_notifiers = true

  local index = self:_configuration_index_by_name(self._configuration_name)
  self._vb.views.dpx_browser_configurations.value = index
  
  local has_device = (self:_current_process() ~= nil)
    
  self._vb.views.dpx_browser_configuration_row.visible = has_device
  self._vb.views.dpx_browser_device_settings.visible = has_device
  self._vb.views.dpx_browser_device_ui_row.visible = has_device
  self._vb.views.dpx_browser_autostart_row.visible = has_device
  self._vb.views.dpx_browser_device_info_text.visible = has_device

  self._vb.views.dpx_browser_autostart_checkbox.value = 
    self:_configuration_autostart_enabled()
      
  local process = self:_current_process()

  self._vb.views.dpx_browser_configuration_running_checkbox.value = 
    (process and process:running()) or false

  --self._vb.views.dpx_browser_device_ui_row:resize()
  --self._vb.views.dpx_browser_rootnode:resize()

  self:_update_device_description()
    
  self:_decorate_device_list()
  self:_decorate_configuration_list()

  self._suppress_notifiers = suppress_notifiers
end


--------------------------------------------------------------------------------

-- starts all apps for the current configuration

function Browser:start_current_configuration()
  TRACE("Browser:start_configuration()")
  
  local process = self:_current_process()
  if (process and not process:running()) then
    process:start()
  end

  -- adjust the GUI, in case this was not fired from the GUI
  local suppress_notifiers = self._suppress_notifiers
  self._suppress_notifiers = true
  
  self._vb.views.dpx_browser_configuration_running_checkbox.value = 
   (process and process:running()) or false

  self:_decorate_device_list()
  self:_decorate_configuration_list()
  
  self._suppress_notifiers = suppress_notifiers
end
  
  
--------------------------------------------------------------------------------

-- stops all apps that run with in the current configuration

function Browser:stop_current_configuration()
  TRACE("Browser:stop_configuration()")

  local process = self:_current_process()
  if (process and process:running()) then
    process:stop()
  end

   -- adjust the GUI, in case this was not fired from the GUI
  local suppress_notifiers = self._suppress_notifiers
  self._suppress_notifiers = true
  
  self._vb.views.dpx_browser_configuration_running_checkbox.value = 
   (process and process:running()) or false

  self:_decorate_device_list()
  self:_decorate_configuration_list()
  
  self._suppress_notifiers = suppress_notifiers
end


--------------------------------------------------------------------------------

-- true when devices dump received midi to the std out

function Browser:dump_midi()
  return self._dump_midi
end


--------------------------------------------------------------------------------

-- start/stop device midi dump

function Browser:set_dump_midi(dump)
  self._dump_midi = dump
  for _,process in pairs(self._processes) do
    process:set_dump_midi(dump)
  end
end


--------------------------------------------------------------------------------
-------  private helper functions
--------------------------------------------------------------------------------

-- removes NOT_AVAILABLE_POSTFIX and RUNNING_POSTFIX from the passed name

function Browser:_strip_postfixes(name)
  --TRACE("Browser:_strip_postfixes", name)

  local plain_find = true
  
  if (name:find(RUNNING_POSTFIX, 1, plain_find)) then
    name = name:sub(1, #name - #RUNNING_POSTFIX)
  end
  
  if (name:find(NOT_AVAILABLE_POSTFIX, 1, plain_find)) then
    name = name:sub(1, #name - #NOT_AVAILABLE_POSTFIX)
  end
  
  return name
end


--------------------------------------------------------------------------------

-- retuns true when at least one process is instantiated and running

function Browser:_process_running()
  --TRACE("Browser:_process_running()")

  for _,process in pairs(self._processes) do
    if (process:running()) then
      return true
    end
  end

  return false
end


--------------------------------------------------------------------------------

-- returns the currently selected process, a BrowserProcess object or nil

function Browser:_current_process()
  TRACE("Browser:_current_process")

  for _,process in pairs(self._processes) do
    if (process:matches(self._device_name, self._configuration_name)) then
      return process
    end
  end
  
  return nil
end


--------------------------------------------------------------------------------

-- return index of the given device display name, as it's displayed in the 
-- device popup

function Browser:_device_index_by_name(device_display_name)
  TRACE("Browser:_device_index_by_name", device_display_name)
  
  if (device_display_name == "None") then
    return 1
  
  else
    device_display_name = self:_strip_postfixes(device_display_name)
  
    local popup = self._vb.views.dpx_browser_input_device
    for index, name in pairs(popup.items)do
      if (device_display_name == self:_strip_postfixes(name)) then
        return index
      end
    end
  
    return nil
  end
end


--------------------------------------------------------------------------------

-- return index of the given configuration name, as it's displayed in the 
-- configuration popup

function Browser:_configuration_index_by_name(config_name)
  TRACE("Browser:_configuration_index_by_name", config_name)
  
  if (config_name == "None") then
    return 1

  else
    config_name = self:_strip_postfixes(config_name)
    
    local popup = self._vb.views.dpx_browser_configurations
    for index, name in pairs(popup.items)do
      if (config_name == self:_strip_postfixes(name)) then
        return index
      end
    end
  
    return nil
  end
end


--------------------------------------------------------------------------------

-- return list of configurations that are present for the given device
-- @param (string) device name, as it's displayed in the device popup  

function Browser:_available_configurations_for_device(device_display_name)
  TRACE("Browser:_available_configurations_for_device:", device_display_name)

  local configurations = table.create()
  
  for _,config in pairs(self._available_configurations) do 
    if (config.device.display_name == device_display_name) then
      configurations:insert(config)
    end
  end
  
  return configurations
end


--------------------------------------------------------------------------------

-- return list of configurations names that are present for the given device
-- @param (string) device name, as it's displayed in the device popup  

function Browser:_available_configuration_names_for_device(device_display_name)
  TRACE("Browser:_available_configuration_names_for_device:", device_display_name)

  local config_names = table.create()
  
  local available_configurations = 
    self:_available_configurations_for_device(device_display_name)

  for _,config in pairs(available_configurations) do 
    config_names:insert(config.name)
  end
  
  return config_names
end


--------------------------------------------------------------------------------

-- add/remove the "running" postfix for relevant devices.
-- called when we start/stop apps, and choose a device/config

function Browser:_decorate_device_list()
  TRACE("Browser:_decorate_device_list:")

  local device_list = self:available_devices()
  
  for index,device_name in pairs(device_list) do
    device_name = self:_strip_postfixes(device_name) 
    
    local running = false
    for _,process in pairs(self._processes) do
      if (process.configuration.device.display_name == device_name) then
        if (process:running()) then
          running = true
          break
        end
      end
    end
  
    if (running) then
      device_list[index] = device_list[index] .. RUNNING_POSTFIX
    end
  end

  self._vb.views.dpx_browser_input_device.items = device_list
end


--------------------------------------------------------------------------------

-- add/remove the "running" postfix for relevant configurations.
-- called when we start/stop apps, and choose a device/config

function Browser:_decorate_configuration_list()
  TRACE("Browser:_decorate_configuration_list:")

  local configuration_names = 
    self:_available_configuration_names_for_device(self._device_name)
  
  local config_list = table.create()

  for _,configuration_name in pairs(configuration_names) do
    local running = false
    for _,process in pairs(self._processes) do
      if (process:matches(self._device_name, configuration_name)) then
        running = process:running()
        break
      end
    end
  
    config_list:insert(running and 
      (configuration_name .. RUNNING_POSTFIX) or
      (configuration_name)
    )
  end

  self._vb.views.dpx_browser_configurations.items = config_list
end


--------------------------------------------------------------------------------

-- show info about the current device, gathered by the control maps info field

function Browser:_update_device_description() 

  local active_process = self:_current_process()      
  local info_text_view = self._vb.views.dpx_browser_device_info_text
  
  if (active_process == nil) then
    info_text_view.text = ""

  else
    local author, description
    
    -- get the author and description fields from the controlmap
    if (active_process.device.control_map) then

      local definition = active_process.device.control_map.definition
      if (definition and #definition > 0) then

        for _,tag in pairs(definition[1]) do
          if (tag.label and tag.label == "Author") then
            author = tag[1]
          elseif (tag.label and tag.label == "Description") then
            description = tag[1]
          end
        end
      end
    end

    local paragraphs = table.create()

    if (author) then
      paragraphs:insert("Author: " .. author)
    end

    if (description) then
      paragraphs:insert("Description: " .. description)
    end

    info_text_view.paragraphs = paragraphs
  end
  
  -- fill up the entire dialog width
  info_text_view.width = math.max(
    self._vb.views.dpx_browser_input_device_row.width, 
    self._vb.views.dpx_browser_device_ui_row.width)

  local text_rows = math.min(5, math.max(1, #info_text_view.paragraphs))
  if (text_rows ~= math.floor(info_text_view.height / 16)) then
    self._vb.views.dpx_browser_device_info_text.height = text_rows*16
    
    --self._vb.views.dpx_browser_device_ui_row:resize()
    --self._vb.views.dpx_browser_rootnode:resize()
  end
end


--------------------------------------------------------------------------------

-- returns true when the current configuration should be autostarted, else false

function Browser:_configuration_autostart_enabled()

  local process = self:_current_process()  

  if (process) then
    return process.settings.autostart.value

  else
    return false
  end
    
end


--------------------------------------------------------------------------------

-- add the current configuration to the autostart prefs, so that it automatically 
-- starts when renoise starts

function Browser:_enable_configuration_autostart()
  TRACE("Browser:_enable_configuration_autostart()")

  local process = self:_current_process()

  if (process) then
    -- disable autostart for all other configs this device has first
    local device_configs = 
      self:_available_configurations_for_device(self._device_name)

    for _,config in pairs(device_configs) do
      local settings = configuration_settings(config)
      settings.autostart.value = false
    end
        
    -- then enable autostart for the current config
    process.settings.autostart.value = true
  end
end
  

--------------------------------------------------------------------------------

-- remove the current configuration from the autostart prefs

function Browser:_disable_configuration_autostart()
  TRACE("Browser:_disable_configuration_autostart()")
  
  local process = self:_current_process() 

  if (process) then
    process.settings.autostart.value = false
  end
end


--------------------------------------------------------------------------------

-- notifier, fired when device input or output port setting changed

function Browser:_available_device_ports_changed()
  TRACE("Browser:_available_device_ports_changed()")

  -- reactivate all devices that are now available but were not available before  
  local input_devices = table.create(renoise.Midi.available_input_devices())
  local output_devices = table.create(renoise.Midi.available_output_devices())
  
  for _,process in pairs(self._processes) do
    if (process:running()) then
      local device = process.device
      
      if (device.protocol == DEVICE_MIDI_PROTOCOL) then
        local now_available = (input_devices:find(device.port_in) ~= nil) and 
          (output_devices:find(device.port_out) ~= nil)
        
        local ports_active = (device.midi_in ~= nil) and
          (device.midi_out ~= nil)
            
        if (now_available and not ports_active) then
          -- ports are now available. reactivate the device
          
          device:release()
          device:open()

          process:clear_display()
        
        elseif (not now_available and ports_active) then

          -- ports no longer available. release the MIDI device ports
          device:release()
        end
        
      end
    end
  end

  -- and update the device list GUI
  self:_device_ports_changed()
end


--------------------------------------------------------------------------------

-- notifier, fired when device input or output port setting changed

function Browser:_device_ports_changed()

  local suppress_notifiers = self._suppress_notifiers
  self._suppress_notifiers = true

  -- update (NA) postfixes, which depend on the device port settings
  self:_decorate_device_list()

  local index = self:_device_index_by_name(self._device_name)
  self._vb.views.dpx_browser_input_device.value = index

  self._suppress_notifiers = suppress_notifiers
end


--------------------------------------------------------------------------------

-- build and assign the application dialog

function Browser:_create_content_view()
  
  local vb = self._vb
  
  local txt_device    = "This list contains the supported devices."
                      .."\nSelect 'none' to release all active devices,"

  local txt_config    = "This list contains the device configurations."
                      .."\nClick on 'Settings' to display options"

  local txt_settings  = "Click to open device/application settings"

  local txt_autostart = "When enabled, this configuration will be launched"
                      .."\nautomatically, every time Renoise starts."

  local txt_running   = "Toggle the running status of this configuration."

  self._content_view = vb:column{
    id = 'dpx_browser_rootnode',
    margin = DEFAULT_MARGIN,
    spacing = DEFAULT_SPACING,
    width = 400,
    
    -- device chooser
    vb:row {
      id = 'dpx_browser_input_device_row',
      vb:text {
        text = "Device",
        width = 50,
      },
      vb:popup {
        id = 'dpx_browser_input_device',
        tooltip = txt_device,
        items = self:available_devices(),
        width = 200,
        notifier = function(e)
          if (not self._suppress_notifiers) then
            local device_list = self:available_devices()
            
            if (e == 1 and self:_process_running()) then -- "None"
              local choice = renoise.app():show_prompt("", 
                "This will close all open devices. Are you sure?", 
                {"OK","Cancel"})
                    
              if (choice == "Cancel") then
                -- revert to the last used device
                self:set_device(self._device_name)
              else
                self:set_device(self:_strip_postfixes(device_list[e]))
              end
            else
              self:set_device(self:_strip_postfixes(device_list[e]))
            end
          end
        end
      },
      vb:button {
        id = 'dpx_browser_device_settings',
        tooltip = txt_settings,
        text = "Settings",
        width = 60,
        notifier = function()
          local process = self:_current_process()
          if (process) then
            --process.device:show_settings_dialog(process)
            process:show_settings_dialog()
            return
          end

        end
      },
    },

    -- configuration chooser
    vb:row {
      id = 'dpx_browser_configuration_row',
      visible = false,
      vb:text {
          text = "Config.",
          width = 50,
      },
      vb:popup {
        id = 'dpx_browser_configurations',
        tooltip = txt_config,
        items = table.create{"None"},
        value = 1,
        width = 200,
        notifier = function(e)
          if (not self._suppress_notifiers) then
            
            local config_list = 
              self:_available_configurations_for_device(self._device_name)
            
            -- when the old config was running, run the new one as well
            local auto_start = (self:_current_process() and
              self:_current_process():running())
            
            self:set_configuration(config_list[e], auto_start)
          end
        end
      },
      vb:row {
        vb:checkbox {
          value = false,
          id = 'dpx_browser_configuration_running_checkbox',
          tooltip = txt_running,
          notifier = function(v)
            if (not self._suppress_notifiers) then
              if (v == true) then
                self:start_current_configuration()
              else
                self:stop_current_configuration()
              end
            end
          end
        },
        vb:text {
          text = "Run",
          tooltip = txt_running,
        }
      }    
    },

    -- autostart checkbox
    vb:row {
      id = 'dpx_browser_autostart_row',
  
      vb:space { width = 50 },
      vb:checkbox {
        value = false,
        id = 'dpx_browser_autostart_checkbox',
        tooltip = txt_autostart,
        notifier = function(v)
          if (not self._suppress_notifiers) then
            if (v == true) then
              self:_enable_configuration_autostart()
            else
              self:_disable_configuration_autostart()
            end
          end
        end
      },     
      vb:text {
        tooltip = txt_autostart,
        text = "Autostart configuration",
      }
    },
    
    -- virtual device ui
    vb:column {
      id = 'dpx_browser_device_ui_row'
    },
    
    -- device info
    vb:multiline_text {
       id = 'dpx_browser_device_info_text',
       width = 300,
       height = 4*16
    }      
  }
end


--==============================================================================

-- BrowserProcess describes a processes that is launched by the browser - a 
-- device with one or more applications, set up by a device configuration

class 'BrowserProcess'

function BrowserProcess:__init()
  TRACE("BrowserProcess:__init")

  -- the full configuration we got instantiated with (if any)
  self.configuration = nil
  -- shortcut for the configurations user settings
  self.settings = nil
  -- Device class instance
  self.device = nil 

  
  -- Display class instance
  self._display = nil 

  -- MessageStream class instance
  self._message_stream = nil

  -- View that got build by the display for the device
  self._control_surface_view = nil
  self._control_surface_parent_view = nil

  -- view for displaying/editing device settings
  self._settings_dialog = nil
  self._settings_view = nil

  -- list of instantiated apps for the current configuration
  self._applications = table.create() 
  
  -- true when this process was running at least once after instantiated
  self._was_running = false

  self._vb = renoise.ViewBuilder()

end


--------------------------------------------------------------------------------

-- returns true if this process matches the given device configurations

function BrowserProcess:matches(device_display_name, config_name)

  return (self.configuration ~= nil) and
    (self.configuration.device.display_name == device_display_name) and  
    (self.configuration.name == config_name)
end

function BrowserProcess:matches_configuration(config)
  return self:matches(config.device.display_name, config.name)
end


--------------------------------------------------------------------------------

-- returns true when the process instantiated correctly

function BrowserProcess:instantiated()
  return (self.configuration ~= nil and self.device ~= nil)
end


--------------------------------------------------------------------------------

-- initialize a process from the passed configuration. this will only 
-- create the device, display and app, but not start it. to start a process,
-- "start" must be called. returns success

function BrowserProcess:instantiate(configuration)
  TRACE("BrowserProcess:instantiate:", 
    configuration.device.display_name, configuration.name)

  assert(not self:instantiated(), "Internal Error. Please report: " .. 
    "browser process already instantiated")


  ---- validate the configuration (help controller developers to spot bugs)
  
  -- device node specified?
  if (not configuration.device) then
    renoise.app():show_warning(
      "Whoops! This configuration has no device definition")
      
    return false
  end

  -- control map specified?
  if (not configuration.device.control_map) then
    renoise.app():show_warning(
      "Whoops! This configuration has no control-map")
      
    return false
  end

  -- device class specified?
  local device_class_name = configuration.device.class_name

  if (not device_class_name) then
    local protocol = configuration.device.protocol
    
    -- use a generic class if the config does not specify one  
    if (protocol == DEVICE_MIDI_PROTOCOL)then
      device_class_name = "MidiDevice"
    
    elseif (protocol == DEVICE_OSC_PROTOCOL)then
      device_class_name = "OscDevice"
    
    else
      renoise.app():show_warning(
        ("Whoops! This configuration uses an " .. 
         "unexpected protocol (%s)"):format(protocol or "nil"))
        
      return false
    end
  end

  -- device class valid?
  if (not rawget(_G, device_class_name)) then
    renoise.app():show_warning(
      ("Whoops! Cannot instantiate device with " ..
       "unknown class: '%s'"):format(device_class_name))

    return false      
  end

  -- application class node specified?
  if (configuration.applications == nil) then 
    renoise.app():show_warning(("Whoops! Device configuration "..
       "contains no applications"))

    return false
  end
  
  -- application classes valid?
  for app_class_name in pairs(configuration.applications) do

    if configuration.applications[app_class_name].application then
      app_class_name = configuration.applications[app_class_name].application
    end
    if (not rawget(_G, app_class_name)) then
      renoise.app():show_warning(
        ("Whoops! Device configuration "..
         "contains unknown application class: '%s'"):format(
         app_class_name or "nil"))

      return false
    end
  end
  

  ---- assign the config and settings

  self.configuration = configuration
  self.settings = configuration_settings(configuration)

  ---- instantiate the device

  self._message_stream = MessageStream()

  if (configuration.device.protocol == DEVICE_MIDI_PROTOCOL) then

    local device_port_in = (self.settings.device_port_in.value ~= "") and 
      self.settings.device_port_in.value or configuration.device.device_port_in
      
    local device_port_out = (self.settings.device_port_out.value ~= "") and 
      self.settings.device_port_out.value or configuration.device.device_port_out
    
    self.device = _G[device_class_name](
      configuration.device.display_name, 
      self._message_stream,
      device_port_in,
      device_port_out
    )

    -- MIDI port setup changed
    -- 0.95
    renoise.Midi.devices_changed_observable():add_notifier(
      BrowserProcess._available_device_ports_changed, self.device
    )

  
  else  -- protocol == DEVICE_OSC_PROTOCOL

    local prefix = (self.settings.device_prefix.value ~= "") and 
      self.settings.device_prefix.value or configuration.device.device_prefix
    
    local address = (self.settings.device_address.value ~= "") and 
      self.settings.device_address.value or configuration.device.device_address
    
    local port_in = (self.settings.device_port_in.value ~= "") and 
      self.settings.device_port_in.value or configuration.device.device_port_in

    local port_out = (self.settings.device_port_out.value ~= "") and 
      self.settings.device_port_out.value or configuration.device.device_port_out

    self.device = _G[device_class_name](
      configuration.device.display_name,
      self._message_stream,
      prefix,
      address,
      tonumber(port_in),
      tonumber(port_out)
    )
  end
    
  self.device:set_control_map(
    configuration.device.control_map)

  self._display = Display(self.device)
  self.device.display = self._display


  ---- instantiate all applications

  self._applications = table.create()

  for app_class_name,_ in pairs(configuration.applications) do

    local actual_class_name = app_class_name
    if configuration.applications[app_class_name].application then
      actual_class_name = configuration.applications[app_class_name].application
    end

    local mappings = configuration.applications[app_class_name].mappings or {}
    local options = table.rcopy(_G[actual_class_name]["default_options"]) or {}
    local config_name = app_class_name

    -- import device-config/user-specified options
    for k,v in pairs(options) do
      local app_node = self.settings.applications:property(app_class_name)
      if app_node then
        if app_node.options and app_node.options:property(k) then
          options[k].value = app_node.options:property(k).value
        end
      end
    end

    local app_instance = _G[actual_class_name](
      self._display,mappings,options,config_name)
    
    self._applications:insert(app_instance)
  end

  self._was_running = false
  
  return true
end

--------------------------------------------------------------------------------

-- handle device hot-plugging (ports changing while Renoise is running)
function BrowserProcess:_available_device_ports_changed()
  TRACE("BrowserProcess:_available_device_ports_changed()")

  -- close the device setting dialogs on MIDI port changes 
  -- so we don't have to bother updating them
  
  if (self:settings_dialog_visible()) then
      self:close_settings_dialog()
  end
end

--------------------------------------------------------------------------------

-- returns true when the device settings dialog is visible 

function BrowserProcess:settings_dialog_visible()
  TRACE("BrowserProcess:settings_dialog_visible()")

  return (self._settings_dialog and self._settings_dialog.visible)
end

--------------------------------------------------------------------------------

-- deinitializes a process actively. can always be called, even when 
-- initialization never happened

function BrowserProcess:invalidate()
  TRACE("BrowserProcess:invalidate")

  while (not self._applications:is_empty()) do
    local last_app = self._applications[#self._applications]
    if (last_app.running) then 
      last_app:stop_app() 
    end
    last_app:destroy_app()
    
    self._applications:remove(#self._applications)
  end
  
  self._was_running = false
  
  self._message_stream = nil
  self._display = nil

  if (self.device) then
    if (self:settings_dialog_visible()) then
      self:close_settings_dialog()
    end
    
    if (self:control_surface_visible()) then
      self:hide_control_surface()
    end
    
    self.device:release()
    self.device = nil
  end
  
  self.configuration = nil
end


--------------------------------------------------------------------------------

-- returns true if this process is running (its apps are running)

function BrowserProcess:running()

  if (#self._applications == 0) then
    return false -- can't run without apps
  end
  
  for _,app in pairs(self._applications) do
    if (not app.active) then
      return false
    end
  end
    
  return true
end


--------------------------------------------------------------------------------

-- start running a fully configured process. returns true when successfully 
-- started, else false (may happen if one of the apps failed to start)

function BrowserProcess:start()
  TRACE("BrowserProcess:start")

  assert(self:instantiated(), "Internal Error. Please report: " .. 
    "trying to start a process which was not instantiated")

  assert(not self:running(), "Internal Error. Please report: " ..
    "trying to start a browser process which is already running")
  
  local succeeded = true
  
  -- start every single app we have
  for _,app in pairs(self._applications) do
    if (app:start_app() == false) then
      succeeded = false
      break
    end
  end
  
  -- stop already started apps on failures
  if (not succeeded) then
    for _,app in pairs(self._applications) do
      if (app.running) then
        app:stop_app()
      end
    end
  end
  
  -- refresh the display when reactivating an old process
  if (succeeded and self._was_running) then
    self._display:clear()
  end

  self._was_running = succeeded
    
  return succeeded
end


--------------------------------------------------------------------------------

-- stop a running process. will not invalidate it, just stop all apps

function BrowserProcess:stop()
  TRACE("BrowserProcess:stop")

  assert(self:instantiated(), "Internal Error. Please report: " ..
    "trying to stop a process which was not instantiated")

  assert(self:running(), "Internal Error. Please report: " ..
    "trying to stop a browser process which is not running")
  
  for _,app in pairs(self._applications) do
    app:stop_app()
  end
end


--------------------------------------------------------------------------------

-- returns true when the processes control surface is currently visible
-- (this is also an indication of whether this is the selected device)

function BrowserProcess:control_surface_visible()
  return (self._control_surface_view ~= nil)
end


--------------------------------------------------------------------------------

-- show a device control surfaces in the browser gui

function BrowserProcess:show_control_surface(parent_view)
  TRACE("BrowserProcess:show_control_surface")

  assert(self:instantiated(), "Internal Error. Please report: " ..
    "trying to show a control map GUI which was not instantiated")
  
  assert(not self:control_surface_visible(), 
    "Internal Error. Please report: " ..
    "trying to show a control map GUI which is already shown")
    
  -- add the device GUI to the browser GUI
  self._control_surface_parent_view = parent_view

  self._control_surface_view = 
    self._display:build_control_surface()

  parent_view:add_child(self._control_surface_view)

  -- refresh the display when reactivating an old process
  if (self:running()) then
    self._display:clear()
  end
end


--------------------------------------------------------------------------------

function BrowserProcess:show_settings_dialog()

  -- already visible? bring to front...
  if (self._settings_dialog and self._settings_dialog.visible) then
    self._settings_dialog:show()
    return    
  end

  local vb = self._vb

  -- define the basic settings view
  if not self._settings_view then
    self._settings_view = vb:column{
      spacing = DEFAULT_SPACING,
      margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
      vb:row{
        id="dpx_device_settings_root",
      },
      vb:space{
        height = 4,
      },
      vb:column{
        id="dpx_app_settings_root",
        spacing = DEFAULT_SPACING,
        --width = "100%",
        --width = 200,
      },
    }

    -- attach the device settings
    self.device:show_settings_dialog(self)
    vb.views.dpx_device_settings_root:add_child(self.device._settings_view)

    -- attach the configuration settings
    -- (one view for each application)
    for _,app in pairs(self._applications) do
      app:_build_options(self)
      vb.views.dpx_app_settings_root:add_child(app._settings_view)
    end
  end

  self._settings_dialog = renoise.app():show_custom_dialog(
    "Duplex: Device Settings", self._settings_view)


end

--------------------------------------------------------------------------------

-- close the device settings, when open

function BrowserProcess:close_settings_dialog()
  TRACE("BrowserProcess:close_settings_dialog()")

  if (self._settings_dialog and self._settings_dialog.visible) then
    self._settings_dialog:close()
  end

  self._settings_dialog = nil
end
  

--------------------------------------------------------------------------------

-- hide the device control surfaces, when showing it...

function BrowserProcess:hide_control_surface()
  TRACE("BrowserProcess:hide_control_surface")

  assert(self:instantiated() and self:control_surface_visible(), 
    "Internal Error. Please report: " .. 
    "trying to hide a control map GUI which was not shown")
    
  -- remove the device GUI from the browser GUI
  self._control_surface_parent_view:remove_child(
    self._control_surface_view)

  self._control_surface_view = nil
  self._control_surface_parent_view = nil
end


--------------------------------------------------------------------------------

-- clears/repaints the display, device, virtual UI

function BrowserProcess:clear_display()
  TRACE("BrowserProcess:clear_display")
  
  assert(self:instantiated(), "Internal Error. Please report: " ..
    "trying to clear a control map GUI which was not instantiated")
  
  if (self:running()) then
    self._display:clear() 
  end
end


--------------------------------------------------------------------------------

-- start/stop device midi dump

function BrowserProcess:set_dump_midi(dump)
  TRACE("BrowserProcess:set_dump_midi", dump)

  if (self:instantiated()) then
    if (self.device.protocol == DEVICE_MIDI_PROTOCOL) then
      self.device.dump_midi = dump
    end
  end
end


--------------------------------------------------------------------------------

-- provide idle support for all active apps

function BrowserProcess:on_idle()
  -- TRACE("BrowserProcess:idle")
  
  if (self:instantiated()) then
    
    -- idle process for stream
    self._message_stream:on_idle()
    
    -- modify ui components
    self._display:update()
  
    -- then refresh the display 
    for _,app in pairs(self._applications) do
      app:on_idle()
    end
  end
end


--------------------------------------------------------------------------------

-- provide new document notification for all active apps

function BrowserProcess:on_new_document()
  TRACE("BrowserProcess:on_new_document")

  if (self:instantiated()) then
    for _,app in pairs(self._applications) do
      app:on_new_document()
    end
  end
end


--------------------------------------------------------------------------------

-- comparison operator (check configs only)

function BrowserProcess:__eq(other)
  return self:matches_configuration(other.configuration)
end

