--[[----------------------------------------------------------------------------
-- Duplex.Browser
----------------------------------------------------------------------------]]--


local DEVICE_NOT_AVAILABLE_POSTFIX = " (N/A)"
local CONFIGURATION_RUNNING_POSTFIX = " (running)"


--==============================================================================

-- The Browser class shows and instantiates registered device configurations
-- and shows the virtual UI for them. More than one configuration can be 
-- active and running for multiple devices.

class 'Browser'

function Browser:__init(initial_configuration)
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
    local auto_start = true
    self:set_configuration(initial_configuration, auto_start)
  end
end


--------------------------------------------------------------------------------

-- return list of valid devices (plus a "None" option)
-- existing devices (ones that we found MIID ports for) are listed first,
-- all others are listed as (N/A)

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
        not result:find(config.device.display_name .. DEVICE_NOT_AVAILABLE_POSTFIX))
    then
      result:insert(config.device.display_name .. DEVICE_NOT_AVAILABLE_POSTFIX)
    end
  end

  return result
end


--------------------------------------------------------------------------------

-- change the active input device:
-- instantiates a new device, using the first avilable configuration for it,
-- or reusing an already running configuration
-- @param name (string) device display-name, without postfix

function Browser:set_device(device_display_name, start_running)
  TRACE("Browser:set_device("..device_display_name..")")
  
  local start_running = start_running or false


  ---- activate the device with its default or existing config
  
  if (self.__device_name ~= device_display_name) then
    
    self.__device_name = self:__strip_na_postfix(device_display_name)
    self.__configuration_name = "None"
  
    if (device_display_name == "None") then
      TRACE("Browser:releasing all processes")
      
      -- release all devices & applications
      for _,process in ripairs(self.__processes) do
        process:invalidate()
        self.__processes:remove()
      end

    else
      TRACE("Browser:assigning new process")
      
      local configuration = nil
          
      -- use an already running process by default
      for _,process in pairs(self.__processes) do
        local process_device_name = process.configuration.device.display_name
        if (process_device_name == device_display_name) then
          configuration = process.configuration
          break
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
      
      assert( ("Internal Error: found no configuration for " .. 
        "device '%s'"):format(device_display_name))

      -- thee may be no configs for the device
      self:set_configuration(configuration, start_running)
    end
  end
  
  
  ---- update the GUI, in case this function was not fired from the GUI
  
  local suppress_notifiers = self.__suppress_notifiers
  self.__suppress_notifiers = true

  local idx = self:__device_index_by_name(device_display_name)
  self.__vb.views.dpx_browser_input_device.value = idx
    
  self.__vb.views.dpx_browser_configuration_row.visible = 
    (self.__configuration_name ~= "None")
  self.__vb.views.dpx_browser_device_settings.visible = 
    (self.__device_name ~= "None")

  local available_configuration_names = 
    self:__available_configuration_names_for_device(self.__device_name)

  self.__vb.views.dpx_browser_configurations.items = 
    available_configuration_names
  
  self.__vb.views.dpx_browser_rootnode:resize()
  self:__decorate_configuration_list()
   
  self.__suppress_notifiers = suppress_notifiers
end


--------------------------------------------------------------------------------

-- activates and shows the dialog, or brings the active on to front

function Browser:show()
  TRACE("Browser:show()")
  
  if (not self.__dialog or not self.__dialog.visible) then
    assert(self.__content_view, 
      "Internal Error: browser always needs a valid content view")
    
    self.__dialog = renoise.app():show_custom_dialog(
      "Duplex Browser", self.__content_view)
  else
    self.__dialog:show()
  end
end


--------------------------------------------------------------------------------

-- forward idle notification to all active processes

function Browser:on_idle()
  -- TRACE("Browser:on_idle()")
  
  for _,process in pairs(self.__processes) do
    process:on_idle()
  end
end


--------------------------------------------------------------------------------

-- forward new document notification to all active processes

function Browser:on_new_document()
  TRACE("Browser:on_new_document()")

  for _,process in pairs(self.__processes) do
    process:new_document()
  end
end


--------------------------------------------------------------------------------

-- return list of valid configurations for the given device 

function Browser:available_configurations(device_name)
  return self:__available_configurations_for_device(device_name)
end


--------------------------------------------------------------------------------

-- activate a new configuration for the currently active device

function Browser:set_configuration(configuration, start_running)
  TRACE("Browser:set_configuration:",configuration.name)
  
  start_running = start_running or false


  ---- first make sure the configs device is selected
  
  self:set_device(configuration.device.display_name, start_running)


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
        self.__vb.views.dpx_browser_rootnode)

    else
      TRACE("Browser:creating new process")
  
      -- remove already running processes for this device
      for _,process in ripairs(self.__processes) do
        local process_device_name = process.configuration.device.display_name
        if (process_device_name == self.__device_name) then
          process:invalidate()
          self.__processes:remove()
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
          self.__vb.views.dpx_browser_rootnode)

        -- and add it to the list of active processes
        self.__processes:insert(new_process)
      
      else
        self.__configuration_name = "None" 
      end

    end
  
    -- instantiation succeeded - auto start?
    if (self.__configuration_name ~= "None" and start_running) then
      self:start_configuration()
    end
  end
  
  
  ---- update the GUI, in case this function was not fired from the GUI

  local suppress_notifiers = self.__suppress_notifiers
  self.__suppress_notifiers = true

  local idx = self:__configuration_index_by_name(configuration.name)
  self.__vb.views.dpx_browser_configurations.value = idx
  
  self.__vb.views.dpx_browser_configuration_row.visible = 
    (self.__configuration_name ~= "None")
  
  local process = self:__current_process()

  self.__vb.views.dpx_browser_configuration_running_checkbox.value = 
    (process and process:running()) or false
  
  self.__vb.views.dpx_browser_rootnode:resize()
  self:__decorate_configuration_list()

  self.__suppress_notifiers = suppress_notifiers
end


--------------------------------------------------------------------------------

-- starts all apps from the current configuration

function Browser:start_configuration()
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

  self.__suppress_notifiers = suppress_notifiers
end
  
  
--------------------------------------------------------------------------------

-- stops all apps that run with in the current configuration

function Browser:stop_configuration()
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

-- removes DEVICE_NOT_AVAILABLE_POSTFIX from the passed name, if present

function Browser:__strip_na_postfix(name)
  TRACE("Browser:__strip_na_postfix", name)

  local plain_find = true
  if (name:find(DEVICE_NOT_AVAILABLE_POSTFIX, 1, plain_find)) then
    return name:sub(1, #name - #DEVICE_NOT_AVAILABLE_POSTFIX)
  else
    return name
  end
end


--------------------------------------------------------------------------------

-- removes CONFIGURATION_RUNNING_POSTFIX from the passed name, if present

function Browser:__strip_running_postfix(name)
  TRACE("Browser:__strip_running_postfix", name)

  local plain_find = true
  if (name:find(CONFIGURATION_RUNNING_POSTFIX, 1, plain_find)) then
    return name:sub(1, #name - #CONFIGURATION_RUNNING_POSTFIX)
  else
    return name
  end
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
  
  device_display_name = self:__strip_na_postfix(device_display_name)
  
  local popup = self.__vb.views.dpx_browser_input_device
  for index, name in pairs(popup.items)do
    if (device_display_name == self:__strip_na_postfix(name)) then
      return index
    end
  end

  return nil
end


--------------------------------------------------------------------------------

-- return index of the given configuration name, as it's displayed in the 
-- configuration popup

function Browser:__configuration_index_by_name(config_name)
  TRACE("Browser:__configuration_index_by_name", config_name)
  
  config_name = self:__strip_running_postfix(config_name)
  
  local popup = self.__vb.views.dpx_browser_configurations
  for index, name in pairs(popup.items)do
    if (config_name == self:__strip_running_postfix(name)) then
      return index
    end
  end

  return nil
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
      (configuration_name .. CONFIGURATION_RUNNING_POSTFIX) or
      (configuration_name)
    )
  end

  self.__vb.views.dpx_browser_configurations.items = config_list
end


--------------------------------------------------------------------------------

-- build and assign the application dialog

function Browser:__create_content_view()
  
  local device_list = self:available_devices()

  local vb = self.__vb
  
  self.__content_view = vb:column{
    id = 'dpx_browser_rootnode',
    style = "body",
    width = 400,
    
    -- device chooser
    vb:row {
      margin = DEFAULT_MARGIN,
      vb:text {
        text = "Device",
        width = 60,
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
                self:set_device(self:__strip_na_postfix(device_list[e]))
              end
            else
              self:set_device(self:__strip_na_postfix(device_list[e]))
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
      margin = DEFAULT_MARGIN,
      id = 'dpx_browser_configuration_row',
      visible = false,
      vb:text {
          text = "Config",
          width = 60,
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
        id="dpx_browser_configurations_options",
        text = "Options",
        width=60,
        notifier=function(e)
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
                self:start_configuration()
              else
                self:stop_configuration()
              end
            end
          end
        },
        vb:text {
          text = "Run",
        }
      }
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
  self.__device = nil 
  
  -- Display class instance
  self.__display = nil 

  -- MessageStream class instance
  self.__message_stream = nil

  -- View that got build by the display for the device
  self.__control_surface_view = nil
  self.__control_surface_parent_view = nil
  
  -- list of instantiated apps for current configuration
  self.__applications = table.create() 
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
  return (self.configuration ~= nil and self.__device ~= nil)
end


--------------------------------------------------------------------------------

-- initialize a process from the passed configuration. this will only 
-- create the device, display and app, but not start it. to start a process,
-- "start" must be called. returns success

function BrowserProcess:instantiate(configuration)
  TRACE("BrowserProcess:instantiate:", 
    configuration.device.display_name, configuration.name)

  assert(not self:instantiated(), 
    "Internal Error: browser process already instantiated")


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
  
  self.__device = _G[device_class_name](
    configuration.device.device_name, self.__message_stream)
    
  self.__device:set_control_map(
    configuration.device.control_map)

  self.__display = Display(self.__device)
  self.__device.display = self.__display


  ---- instantiate all applications

  self.__applications = table.create()

  for app_class_name,_ in pairs(configuration.applications) do

    local mappings = configuration.applications[app_class_name] or {}
    local options = {} -- TODO
    
    local app_instance = _G[app_class_name](
      self.__display, mappings, options)
    
    self.__applications:insert(app_instance)
  end

  return true
end


--------------------------------------------------------------------------------

-- deinitializes a process actively. can always be called, even when 
-- initialization never happened

function BrowserProcess:invalidate()
  TRACE("BrowserProcess:invalidate")

  for _,app in ripairs(self.__applications) do
    if (app.running) then
      app:stop_app()
    end

    app:destroy_app()
    self.__applications:remove()
  end
  
  if (self.__device) then
    self.__device:release()
    self.__device = nil
  end
  
  if (self.__control_surface_view) then
    self.__control_surface_parent_view:remove_child(
      self.__control_surface_view)
    
    self.__control_surface_parent_view = nil
    self.__control_surface_view = nil
  end

  self.__message_stream = nil
  self.__display = nil

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

  assert(self:instantiated(), 
    "Internal Error: trying to start a process " ..
    "which was not instantiated")

  assert(not self:running(), 
    "Internal Error: trying to start a browser " ..
    "process which is already running")
  
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
  
  return succeeded
end


--------------------------------------------------------------------------------

-- stop a runing process. will not invalidate it, just stop all apps

function BrowserProcess:stop()
  TRACE("BrowserProcess:stop")

  assert(self:instantiated(), 
    "Internal Error: trying to stop a process " ..
    "which was not instantiated")

  assert(self:running(), 
    "Internal Error: trying to stop a browser " ..
    "process which is not running")
  
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

  assert(self:instantiated(), 
    "Internal Error: trying to show a control map" ..
    "GUi which was not instantiated")
  
  assert(not self:control_surface_visible(), 
    "Internal Error: trying to show a control map " ..
    "GUI which is already shown")
    
  -- add the device GUI to the browser GUI
  self.__control_surface_parent_view = parent_view

  self.__control_surface_view = 
    self.__display:build_control_surface()

  parent_view:add_child(self.__control_surface_view)

  -- completely update the display when reactivating an old process
  if (self:running()) then
    self.__display:clear()
  end
end


--------------------------------------------------------------------------------

-- hide the device control surfaces, when showing it...

function BrowserProcess:hide_control_surface()
  TRACE("BrowserProcess:hide_control_surface")

  assert(self:instantiated() and self:control_surface_visible(), 
    "Internal Error: trying to hide a control map " ..
    "GUI which was not shown")
    
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
    if (self.__device.protocol == DEVICE_MIDI_PROTOCOL) then
      self.__device.dump_midi = dump
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

function BrowserProcess:new_document()
  TRACE("BrowserProcess:new_document")

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

