--[[----------------------------------------------------------------------------
-- Duplex.Browser
----------------------------------------------------------------------------]]--


local NOT_AVAILABLE_POSTFIX = " (N/A)"
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
  self.__available_configurations = device_configurations

  -- processes is a table containing BrowserProcess processes
  self.__processes = table.create()
  
  -- string, selected device display-name 
  self.__device_name = nil 
  -- string, selected configuration for the current device
  self.__configuration_name = nil

  -- dump midi information to console (debug option)
  self.__dump_midi = false

  -- true while updating the GUI from within the internal browser functions, 
  -- to avoid doubling updates when the changes are not fired from the GUI
  self.__suppress_notifiers = false
  
  
  ---- components
  
  -- view builder that we do use for all our views
  self.__vb = renoise.ViewBuilder()
  
  -- referenc eto the main dialog that we create
  self.__dialog = nil
  

  ---- build the GUI

  self:__create_content_view()

  
  ---- activate default config

  -- select none by default
  self:set_device("None")
  
  -- as last step, apply optional arguments (autostart devices)
  if (initial_configuration) then
    self:set_configuration(initial_configuration, start_configuration)
  end
end


--------------------------------------------------------------------------------

-- activates and shows the dialog, or brings the existing one to front

function Browser:show()
  TRACE("Browser:show()")
  
  if (not self.__dialog or not self.__dialog.visible) then
    assert(self.__content_view, "Internal Error. Please report: " .. 
      "browser always needs a valid content view")
    
    self.__dialog = renoise.app():show_custom_dialog(
      "Duplex Browser", self.__content_view)
  else
    self.__dialog:show()
  end
end


--------------------------------------------------------------------------------

-- forwards idle notifications to all active processes

function Browser:on_idle()
  -- TRACE("Browser:on_idle()")
  
  for _,process in pairs(self.__processes) do
    process:on_idle()
  end
end


--------------------------------------------------------------------------------

-- forwards new document notifications to all active processes

function Browser:on_new_document()
  TRACE("Browser:on_new_document()")

  for _,process in pairs(self.__processes) do
    process:on_new_document()
  end
end


--------------------------------------------------------------------------------

-- return a list of valid devices (plus a "None" option)
-- existing devices (ones that we found MIDI ports for) are listed first,
-- all others are listed as (N/A) to indicate that they are not present
-- in the users device setup

function Browser:available_devices()

  local result = table.create{ "None" }

  -- insert devices that are installed on this system first
  local input_devices = table.create(renoise.Midi.available_input_devices())

  for _,config in pairs(self.__available_configurations) do
    if (input_devices:find(config.device.device_name) and 
        not result:find(config.device.display_name)) 
    then
      result:insert(config.device.display_name)
    end
  end
  
  -- then all others that are available in duplex but not installed
  for _,config in pairs(self.__available_configurations) do
    if (not result:find(config.device.display_name) and
        not result:find(config.device.display_name .. NOT_AVAILABLE_POSTFIX))
    then
      result:insert(config.device.display_name .. NOT_AVAILABLE_POSTFIX)
    end
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
  
  if (self.__device_name ~= device_display_name) then
    
    self.__device_name = self:__strip_postfixes(device_display_name)
    self.__configuration_name = "None"
  
    if (device_display_name == "None") then
      TRACE("Browser:releasing all processes")
      
      -- release all devices & applications
      while (not self.__processes:is_empty()) do
        self.__processes[#self.__processes]:invalidate()
        self.__processes:remove(#self.__processes)
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
        for _,process in pairs(self.__processes) do
          local process_device_name = process.configuration.device.display_name
          if (process_device_name == device_display_name) then
            configuration = process.configuration
            break
          end
        end
      end
      
      -- else the first listed one for the device
      if (not configuration) then
        for _,config in pairs(self.__available_configurations) do 
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

  local suppress_notifiers = self.__suppress_notifiers
  self.__suppress_notifiers = true

  local available_configuration_names = 
    self:__available_configuration_names_for_device(self.__device_name)

  self.__vb.views.dpx_browser_configurations.items = 
    available_configuration_names

  local index = self:__device_index_by_name(self.__device_name)
  self.__vb.views.dpx_browser_input_device.value = index
  
  self:__decorate_device_list()

  self.__suppress_notifiers = suppress_notifiers
end


--------------------------------------------------------------------------------

-- return list of valid configurations for the given device 

function Browser:available_configurations(device_name)
  TRACE("Browser:available_configurations:",device_name)
  
  return self:__available_configurations_for_device(device_name)
end


--------------------------------------------------------------------------------

-- returns true if the given config is instantiated and running

function Browser:configuration_running(configuration)
  TRACE("Browser:configuration_running:",configuration.name)
  
  for _,process in pairs(self.__processes) do
    if (process:matches_configuration(configuration)) then
      return process:running()
    end
  end
  
  return false
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
    
    if (self.__configuration_name ~= configuration.name) then
      self.__configuration_name = configuration.name
      
      -- switching to an existing running process?
      local existing_process = nil
      for _,process in pairs(self.__processes) do
        if (process:matches_configuration(configuration)) then
          existing_process = process
          break
        end
      end
      
      if (existing_process) then
        TRACE("Browser:switching to existing process")
            
        -- hide previous instantiated control-maps
        for _,process in pairs(self.__processes) do
          if (process ~= existing_process) then
            if (process:control_surface_visible()) then
              process:hide_control_surface()
            end
          end
        end
        
        -- and show the new one
        existing_process:show_control_surface(
          self.__vb.views.dpx_browser_device_ui_row)
  
      else
        TRACE("Browser:creating new process")
    
        -- remove already running processes for this device
        for process_index,process in ripairs(self.__processes) do
          local process_device_name = process.configuration.device.display_name
          if (process_device_name == self.__device_name) then
            process:invalidate()
            self.__processes:remove(process_index)
            break
          end
        end
      
        -- hide previous instantiated control-maps from other devices
        for _,process in pairs(self.__processes) do
          if (process:control_surface_visible()) then
            process:hide_control_surface()
          end
        end
        
        -- create a new process 
        local new_process = BrowserProcess()
        
        if (new_process:instantiate(configuration)) then
          
          -- apply debug options
          new_process:set_dump_midi(self.__dump_midi)
          
          -- show it (add the control map GUI to the browser)
          new_process:show_control_surface(
            self.__vb.views.dpx_browser_device_ui_row)
  
          -- and add it to the list of active processes
          self.__processes:insert(new_process)
        
        else
          self.__configuration_name = "None" 
        end
      end
    end
  
  else
  
    self:set_device("None")
    self.__configuration_name = "None" 
  end
  

  ---- validate the process list
  
  for _,process in pairs(self.__processes) do
    assert(process:instantiated(), "Internal Error. Please report: " ..
      "should only have instantiated processes listed")
  end


  ---- apply start options
  
  if (self:__current_process() and start_running) then
    self:start_current_configuration()
  end
  
    
  ---- update the GUI, in case this function was not fired from the GUI

  local suppress_notifiers = self.__suppress_notifiers
  self.__suppress_notifiers = true

  local index = self:__configuration_index_by_name(self.__configuration_name)
  self.__vb.views.dpx_browser_configurations.value = index
  
  local has_device = (self:__current_process() ~= nil)
    
  self.__vb.views.dpx_browser_configuration_row.visible = has_device
  self.__vb.views.dpx_browser_device_settings.visible = has_device
  self.__vb.views.dpx_browser_device_ui_row.visible = has_device
  self.__vb.views.dpx_browser_device_info_text.visible = has_device
    
  local process = self:__current_process()

  self.__vb.views.dpx_browser_configuration_running_checkbox.value = 
    (process and process:running()) or false

  self.__vb.views.dpx_browser_device_ui_row:resize()
  self.__vb.views.dpx_browser_rootnode:resize()

  self:__update_device_description()
    
  self:__decorate_device_list()
  self:__decorate_configuration_list()

  self.__suppress_notifiers = suppress_notifiers
end


--------------------------------------------------------------------------------

-- starts all apps for the current configuration

function Browser:start_current_configuration()
  TRACE("Browser:start_configuration()")
  
  local process = self:__current_process()
  if (process and not process:running()) then
    process:start()
  end

  -- adjust the GUI, in case this was not fired from the GUI
  local suppress_notifiers = self.__suppress_notifiers
  self.__suppress_notifiers = true
  
  self.__vb.views.dpx_browser_configuration_running_checkbox.value = 
   (process and process:running()) or false

  self:__decorate_device_list()
  self:__decorate_configuration_list()
  
  self.__suppress_notifiers = suppress_notifiers
end
  
  
--------------------------------------------------------------------------------

-- stops all apps that run with in the current configuration

function Browser:stop_current_configuration()
  TRACE("Browser:stop_configuration()")

  local process = self:__current_process()
  if (process and process:running()) then
    process:stop()
  end

   -- adjust the GUI, in case this was not fired from the GUI
  local suppress_notifiers = self.__suppress_notifiers
  self.__suppress_notifiers = true
  
  self.__vb.views.dpx_browser_configuration_running_checkbox.value = 
   (process and process:running()) or false

  self:__decorate_device_list()
  self:__decorate_configuration_list()
  
  self.__suppress_notifiers = suppress_notifiers
end


--------------------------------------------------------------------------------

-- true when devices dump received midi to the std out

function Browser:dump_midi()
  return self.__dump_midi
end


--------------------------------------------------------------------------------

-- start/stop device midi dump

function Browser:set_dump_midi(dump)
  self.__dump_midi = dump
  for _,process in pairs(self.__processes) do
    process:set_dump_midi(dump)
  end
end


--------------------------------------------------------------------------------
-------  private helper functions
--------------------------------------------------------------------------------

-- removes NOT_AVAILABLE_POSTFIX and RUNNING_POSTFIX from the passed name

function Browser:__strip_postfixes(name)
  TRACE("Browser:__strip_postfixes", name)

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

function Browser:__process_running()
  --TRACE("Browser:__process_running()")

  for _,process in pairs(self.__processes) do
    if (process:running()) then
      return true
    end
  end

  return false
end


--------------------------------------------------------------------------------

-- returns the currently selected process, a BrowserProcess object or nil

function Browser:__current_process()
  TRACE("Browser:__current_process")

  for _,process in pairs(self.__processes) do
    if (process:matches(self.__device_name, self.__configuration_name)) then
      return process
    end
  end
  
  return nil
end


--------------------------------------------------------------------------------

-- return index of the given device display name, as it's displayed in the 
-- device popup

function Browser:__device_index_by_name(device_display_name)
  TRACE("Browser:__device_index_by_name", device_display_name)
  
  if (device_display_name == "None") then
    return 1
  
  else
    device_display_name = self:__strip_postfixes(device_display_name)
  
    local popup = self.__vb.views.dpx_browser_input_device
    for index, name in pairs(popup.items)do
      if (device_display_name == self:__strip_postfixes(name)) then
        return index
      end
    end
  
    return nil
  end
end


--------------------------------------------------------------------------------

-- return index of the given configuration name, as it's displayed in the 
-- configuration popup

function Browser:__configuration_index_by_name(config_name)
  TRACE("Browser:__configuration_index_by_name", config_name)
  
  if (config_name == "None") then
    return 1

  else
    config_name = self:__strip_postfixes(config_name)
    
    local popup = self.__vb.views.dpx_browser_configurations
    for index, name in pairs(popup.items)do
      if (config_name == self:__strip_postfixes(name)) then
        return index
      end
    end
  
    return nil
  end
end


--------------------------------------------------------------------------------

-- return list of configurations that are present for the given device
-- @param (string) device name, as it's displayed in the device popup  

function Browser:__available_configurations_for_device(device_display_name)
  TRACE("Browser:__available_configurations_for_device:", device_display_name)

  local configurations = table.create()
  
  for _,config in pairs(self.__available_configurations) do 
    if (config.device.display_name == device_display_name) then
      configurations:insert(config)
    end
  end
  
  return configurations
end


--------------------------------------------------------------------------------

-- return list of configurations names that are present for the given device
-- @param (string) device name, as it's displayed in the device popup  

function Browser:__available_configuration_names_for_device(device_display_name)
  TRACE("Browser:__available_configuration_names_for_device:", device_display_name)

  local config_names = table.create()
  
  local available_configurations = 
    self:__available_configurations_for_device(device_display_name)

  for _,config in pairs(available_configurations) do 
    config_names:insert(config.name)
  end
  
  return config_names
end


--------------------------------------------------------------------------------

-- add/remove the "running" postfix for relevant devices.
-- called when we start/stop apps, and choose a device/config

function Browser:__decorate_device_list()
  TRACE("Browser:__decorate_device_list:")

  local device_list = self:available_devices()
  
  for index,device_name in pairs(device_list) do
    device_name = self:__strip_postfixes(device_name) 
    
    local running = false
    for _,process in pairs(self.__processes) do
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

  self.__vb.views.dpx_browser_input_device.items = device_list
end


--------------------------------------------------------------------------------

-- add/remove the "running" postfix for relevant configurations.
-- called when we start/stop apps, and choose a device/config

function Browser:__decorate_configuration_list()
  TRACE("Browser:__decorate_configuration_list:")

  local configuration_names = 
    self:__available_configuration_names_for_device(self.__device_name)
  
  local config_list = table.create()

  for _,configuration_name in pairs(configuration_names) do
    local running = false
    for _,process in pairs(self.__processes) do
      if (process:matches(self.__device_name, configuration_name)) then
        running = process:running()
        break
      end
    end
  
    config_list:insert(running and 
      (configuration_name .. RUNNING_POSTFIX) or
      (configuration_name)
    )
  end

  self.__vb.views.dpx_browser_configurations.items = config_list
end


--------------------------------------------------------------------------------

-- show info about the current device, gathered by the control maps info field

function Browser:__update_device_description() 

  local active_process = self:__current_process()      

  if (active_process == nil) then
    self.__vb.views.dpx_browser_device_info_text.text = ""

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

    self.__vb.views.dpx_browser_device_info_text.paragraphs = paragraphs
  end
  
  -- fill up the entire dialog width
  self.__vb.views.dpx_browser_device_info_text.width = math.max(
    self.__vb.views.dpx_browser_input_device_row.width, 
    self.__vb.views.dpx_browser_device_ui_row.width)
end


--------------------------------------------------------------------------------

-- build and assign the application dialog

function Browser:__create_content_view()
  
  local device_list = self:available_devices()

  local vb = self.__vb
  
  self.__content_view = vb:column{
    id = 'dpx_browser_rootnode',
    width = 400,
    
    -- device chooser
    vb:row {
      id = 'dpx_browser_input_device_row',
      margin = DEFAULT_MARGIN,
      vb:text {
        text = "Device",
        width = 50,
      },
      vb:popup {
        id = 'dpx_browser_input_device',
        items = device_list,
        width = 200,
        notifier = function(e)
          if (not self.__suppress_notifiers) then
            if (e == 1 and self:__process_running()) then -- "None"
              local choice = renoise.app():show_prompt("", 
                "This will close all open devices. Are you sure?", 
                {"OK","Cancel"})
                    
              if (choice == "Cancel") then
                -- revert to the last used device
                self:set_device(self.__device_name)
              else
                self:set_device(self:__strip_postfixes(device_list[e]))
              end
            else
              self:set_device(self:__strip_postfixes(device_list[e]))
            end
          end
        end
      },
      vb:button {
        id = 'dpx_browser_device_settings',
        text = "Settings",
        width = 60,
        notifier = function(e)
          renoise.app():show_warning("Device settings not yet implemented")
        end
      },
    },

    -- configuration chooser
    vb:row {
      id = 'dpx_browser_configuration_row',
      margin = DEFAULT_MARGIN,
      visible = false,
      vb:text {
          text = "Config.",
          width = 50,
      },
      vb:popup {
        id = 'dpx_browser_configurations',
        items = table.create{"None"},
        value = 1,
        width = 200,
        notifier = function(e)
          if (not self.__suppress_notifiers) then
            
            local config_list = 
              self:__available_configurations_for_device(self.__device_name)
            
            -- when the old config was running, run the new one as well
            local auto_start = (self:__current_process() and
              self:__current_process():running())
            
            self:set_configuration(config_list[e], auto_start)
          end
        end
      },
      --[[ taktik: temporarily removed
      vb:button{
        id = "dpx_browser_configurations_options",
        text = "Options",
        width = 60,
        notifier = function(e)
          renoise.app():show_warning("Device settings not yet implemented")
          -- self:show_configuration_options()
        end
      },]]
      vb:row {
        vb:checkbox {
          value = false,
          id = 'dpx_browser_configuration_running_checkbox',
          notifier = function(v)
            if (not self.__suppress_notifiers) then
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
        }
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
       height = 3*18
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
  
  -- device class instance
  self.device = nil 
  
  -- Display class instance
  self.__display = nil 

  -- MessageStream class instance
  self.__message_stream = nil

  -- View that got build by the display for the device
  self.__control_surface_view = nil
  self.__control_surface_parent_view = nil
  
  -- list of instantiated apps for current configuration
  self.__applications = table.create() 
  
  -- true when this process was running at least once after instantiated
  self.__was_running = false
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

  -- applications class node specified?
  if (configuration.applications == nil) then 
    renoise.app():show_warning(("Whoops! Device configuration "..
       "contains no applications"))

    return false
  end
  
   -- applications classes valid?
 for app_class_name in pairs(configuration.applications) do
    if (not rawget(_G, app_class_name)) then
      renoise.app():show_warning(
        ("Whoops! Device configuration "..
         "contains unknown application class: '%s'"):format(
         app_class_name or "nil"))

      return false
    end
  end
  
  
  ---- instantiate the device

  self.configuration = configuration

  self.__message_stream = MessageStream()
  
  self.device = _G[device_class_name](
    configuration.device.device_name, self.__message_stream)
    
  self.device:set_control_map(
    configuration.device.control_map)

  self.__display = Display(self.device)
  self.device.display = self.__display


  ---- instantiate all applications

  self.__applications = table.create()

  for app_class_name,_ in pairs(configuration.applications) do

    local mappings = configuration.applications[app_class_name] or {}
    local options = {} -- TODO
    
    local app_instance = _G[app_class_name](
      self.__display, mappings, options)
    
    self.__applications:insert(app_instance)
  end

  self.__was_running = false
  
  return true
end


--------------------------------------------------------------------------------

-- deinitializes a process actively. can always be called, even when 
-- initialization never happened

function BrowserProcess:invalidate()
  TRACE("BrowserProcess:invalidate")

  while (not self.__applications:is_empty()) do
    local last_app = self.__applications[#self.__applications]
    if (last_app.running) then 
      last_app:stop_app() 
    end
    last_app:destroy_app()
    
    self.__applications:remove(#self.__applications)
  end
  
  self.__was_running = false
  
  if (self.__control_surface_view) then
    self.__control_surface_parent_view:remove_child(
      self.__control_surface_view)
    
    self.__control_surface_parent_view = nil
    self.__control_surface_view = nil
  end

  self.__message_stream = nil
  self.__display = nil

  if (self.device) then
    self.device:release()
    self.device = nil
  end
  
  self.configuration = nil
end


--------------------------------------------------------------------------------

-- returns true if this process is running (its apps are running)

function BrowserProcess:running()

  if (#self.__applications == 0) then
    return false -- can't run without apps
  end
  
  for _,app in pairs(self.__applications) do
    if (not app.active) then
      return false
    end
  end
    
  return true
end


--------------------------------------------------------------------------------

-- start running a fully configured process. returns true when successfully 
-- started, else false (may happen if one of the apps neglect to start)

function BrowserProcess:start()
  TRACE("BrowserProcess:start")

  assert(self:instantiated(), "Internal Error. Please report: " .. 
    "trying to start a process which was not instantiated")

  assert(not self:running(), "Internal Error. Please report: " ..
    "trying to start a browser process which is already running")
  
  local succeeded = true
  
  -- start every single app we have
  for _,app in pairs(self.__applications) do
    if (app:start_app() == false) then
      succeeded = false
      break
    end
  end
  
  -- stop already started apps on failures
  if (not succeeded) then
    for _,app in pairs(self.__applications) do
      if (app.running) then
        app:stop_app()
      end
    end
  end
  
  -- refresh the display when reactivating an old process
  if (succeeded and self.__was_running) then
    self.__display:clear()
  end

  self.__was_running = succeeded
    
  return succeeded
end


--------------------------------------------------------------------------------

-- stop a runing process. will not invalidate it, just stop all apps

function BrowserProcess:stop()
  TRACE("BrowserProcess:stop")

  assert(self:instantiated(), "Internal Error. Please report: " ..
    "trying to stop a process which was not instantiated")

  assert(self:running(), "Internal Error. Please report: " ..
    "trying to stop a browser process which is not running")
  
  for _,app in pairs(self.__applications) do
    app:stop_app()
  end
end


--------------------------------------------------------------------------------

-- returtns true when the processes control surface is currently visible

function BrowserProcess:control_surface_visible()
  return (self.__control_surface_view ~= nil)
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
  self.__control_surface_parent_view = parent_view

  self.__control_surface_view = 
    self.__display:build_control_surface()

  parent_view:add_child(self.__control_surface_view)

  -- refresh the display when reactivating an old process
  if (self:running()) then
    self.__display:clear()
  end
end


--------------------------------------------------------------------------------

-- hide the device control surfaces, when showing it...

function BrowserProcess:hide_control_surface()
  TRACE("BrowserProcess:hide_control_surface")

  assert(self:instantiated() and self:control_surface_visible(), 
    "Internal Error. Please report: " .. 
    "trying to hide a control map GUI which was not shown")
    
  -- remove the device GUI from the browser GUI
  self.__control_surface_parent_view:remove_child(
    self.__control_surface_view)

  self.__control_surface_view = nil
  self.__control_surface_parent_view = nil
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
    self.__message_stream:on_idle()
    
    -- first, modify ui components
    self.__display:update()
  
    -- then refresh the display 
    for _,app in pairs(self.__applications) do
      app:on_idle()
    end
  end
end


--------------------------------------------------------------------------------

-- provide new document notification for all active apps

function BrowserProcess:on_new_document()
  TRACE("BrowserProcess:on_new_document")

  if (self:instantiated()) then
    for _,app in pairs(self.__applications) do
      app:on_new_document()
    end
  end
end


--------------------------------------------------------------------------------

-- comparison operator (check configs only)

function BrowserProcess:__eq(other)
  return self:matches_configuration(other.configuration)
end

