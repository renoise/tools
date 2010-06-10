--[[----------------------------------------------------------------------------
-- Duplex.Browser
----------------------------------------------------------------------------]]--

--[[

The Browser class provides easy access to running scripts
- run apps on multiple devices at the same time 
- run multiple apps on the same device

multitasking todo:

- when an application is selected, and it's not running
- - add to list of applications, along with device information
    (this makes us able to decorate the list of applications with a
    "running" postfix, also when we are switching to other devices)
- when switching device, and there's an application running, prompt user
  whether to keep the app running (keeping the io open)
- when switching to another application on the same device, offer to
  reposition/resize the application (esp. useful with a grid controller)
    

--]]


--==============================================================================

local DEVICE_NOT_AVAILABLE_POSTFIX = " (N/A)"
local APPLICATION_RUNNING_POSTFIX = " (running)"

--==============================================================================

class 'Browser' (Application)

function Browser:__init(device_name, app_name)
  TRACE("Browser:__init",device_name, app_name)

  Application.__init(self)

  -- processes is a table containing processes launched by the browser,
  -- each time a new device is selected, a process is started
  -- {
  --  name = "Launchpad",   -- string, device-display-name
  --  device = [LaunchPad], -- device class instance
  --  display = [Display],  -- display class instance
  --  applications = {[PatternMatrix class],[...]} -- list of active apps
  --  selected_app = 1,     -- restore popup index when switching process
  -- }
  self.__processes = table.create()
  
  -- this is set when choosing the device
  self.__process = nil 

  -- list of duplex device definitions
  self.__devices = table.create(self:__get_custom_devices())

  -- string, selected device display-name 
  self.__device_name = nil 

  -- number, selected device index 
  self.__device_index = nil

  self.stream = MessageStream()
  self.vb = renoise.ViewBuilder()
  self:build_app()
  
  -- the browser is always active
  Application.start_app(self)

  -- hide after building
  self.vb.views.dpx_browser_device_settings.visible = false

  -- as last step, apply optional arguments (autostart apps, devices)
  if (device_name) then
    self:__set_device_index(device_name)
    if (app_name) then
      self:__set_application_index(app_name)
      -- invokes start_app
      self.vb.views.dpx_browser_application_checkbox.value = true
    end
  end

end


--------------------------------------------------------------------------------

-- return list of valid devices (plus a "None" option)
-- - include devices that match the device name (dedicated classes)
--   and/or has a control-map (as this enables the control surface)

function Browser:available_devices()

  local result = table.create{"None"}
  
  local input_devices = table.create(renoise.Midi.available_input_devices())
  local custom_devices = table.create(self:__get_custom_devices())

  -- insert devices that are installed on this system first
  for idx,t in ripairs(custom_devices) do
    for _,k in ipairs(input_devices) do
      if (k:sub(0, #t.device_name) == t.device_name) then
        result:insert(t.display_name)
        custom_devices:remove(idx) 
      end
    end
  end

  -- then all others that are available in duplex but not installed
  for _,t in ipairs(custom_devices) do
    if (t.control_map) then
      result:insert(t.display_name .. DEVICE_NOT_AVAILABLE_POSTFIX)
    end
  end

  return result
end


--------------------------------------------------------------------------------

-- change the active input device:
-- - instantiate new device, or re-use existing process
-- - load dedicated class if it exists, otherwise load a generic class
-- - update the applications list (show only compatible apps)
-- @param name (string)  device display-name, without postfix

function Browser:set_device(name)
  TRACE("Browser:set_device("..name..")")
  
  -- hide all control-maps
  for _,k in ipairs(self.__processes) do
    if (k.display) then
      k.display:hide_control_surface()
    end
  end

  -- adjust device index, in case it was not fired from the GUI
  local idx = self:__get_device_index_by_name(name)
  self.vb.views.dpx_browser_input_device.value = idx

  if (name == "None") then
    
    -- release all devices & applications
    -- (in reverse, since we are removing entries)
    for o,k in ripairs(self.__processes) do
      if (k.applications) then
        for idx,v in ripairs(k.applications) do
          v:destroy_app()
          k.applications:remove(idx)
        end
      end
      k.display = nil
      k.device:release()
      k.device = nil
      self.__processes:remove(o)
    end

    self.__process = nil

    -- adjust dialog 
    self.vb.views.dpx_browser_rootnode:resize()
    self.vb.views.dpx_browser_app_row.visible = false
    self.vb.views.dpx_browser_device_settings.visible = false

  else

    -- instantiate the new device

    self.__device_name = self:__strip_na_postfix(name)

    self.vb.views.dpx_browser_app_row.visible = true
    self.vb.views.dpx_browser_device_settings.visible = true

    -- find our device among the supported ones
    for _,k in ipairs(self.__devices) do 
      if (name == k.display_name) then

        -- update the applications list 
        local app_list = self:__get_available_apps()
        self.vb.views.dpx_browser_application.items = app_list

        self.__process = self:__get_selected_process()

        if(self.__process)then
          -- eisting device/process
          self.__process.display:show_control_surface()
          self.vb.views.dpx_browser_application.value = self.__process.selected_app
        else
          -- initialize new device/process 
          if (k.class_name) then
            -- device has its own class
            self:__instantiate_device(k.display_name,k.class_name, k.device_name, k.control_map)
          elseif (k.control_map) then
            -- device has a control map but no class. use a default one
            local generic_class = nil
            if (k.protocol == DEVICE_MIDI_PROTOCOL)then
              generic_class = "MIDIDevice"
            elseif (k.protocol == DEVICE_OSC_PROTOCOL)then
              generic_class = "OscDevice"
            else
              error(("device uses unexpected protocol: %d"):format(k.protocol))
            end
            self:__instantiate_device(k.display_name,generic_class, k.device_name, k.control_map)
          else
            renoise.app():show_warning("Whoops! This device needs a control-map")
          end      

          self.__process = self:__get_selected_process()
          self:__set_application_index("None")

        end

        -- adjust dialog 
        self.vb.views.dpx_browser_rootnode:resize()
        self:__decorate_app_list()

      end
    end
  end

  self.__device_index = self.vb.views.dpx_browser_input_device.value

end


--------------------------------------------------------------------------------

-- return list of supported applications: display names are class names
-- @param (string)  device name, as it's displayed in the device popup  

function Browser:__get_available_apps()
  TRACE("Browser:__get_available_apps:")

  -- full list of available applications 
  local app_list = table.create{    
    "None",
    "MixConsole",
    "PatternMatrix",
    "MatrixTest",
  }

  -- locate the device definition
  local custom_device = nil
  for _,k in ipairs(self.__devices) do 
    if (self.__device_name == k.display_name) then
      custom_device = k
    end
  end

  -- remove apps that doesn't run on this device
  if custom_device and custom_device.incompatible then
    local matched_index = nil
    for k,v in ipairs(custom_device.incompatible) do
      matched_index = app_list:find(v)
      if(matched_index)then
        app_list:remove(matched_index)
      end
    end
  end
  return app_list

end

--------------------------------------------------------------------------------

-- add/remove the "running" postfix for relevant applications
-- - called when we start/stop apps, and choose a device
-- @app_list: list of strings (popup.items)

function Browser:__decorate_app_list()
  TRACE("Browser:__decorate_app_list:")

  local app_list = self.vb.views.dpx_browser_application.items
  for _,process in ipairs(self.__processes) do
    if (process.name == self.__device_name) then
      for __,app in ipairs(process.applications) do
        for v,k in ipairs(app_list) do
          k = self:__strip_running_postfix(k)
          if(k==type(app))then
            app_list[v] = app.active and 
              (k .. APPLICATION_RUNNING_POSTFIX) or k
          end
        end
      end
    end
  end

  self.vb.views.dpx_browser_application.items=app_list

end

--------------------------------------------------------------------------------

-- set application as active item 
-- if the application hasn't been run before, it is instantiated
-- if already running, switch focus to it (starting/stopping becomes possible)
-- set to "None" to destroy all applications on the selected device

function Browser:set_application(app_name)
  TRACE("Browser:set_application:",app_name)

  if (app_name=="None") then

    if self.__process and self.__process.applications then
      for idx,v in ripairs(self.__process.applications) do
        v:destroy_app()
        self.__process.applications:remove(idx)
      end
    end
    local app_list = self:__get_available_apps()
    self.vb.views.dpx_browser_application.items = app_list
    self.__process.selected_app = 1

  else

    local app = nil
    if self.__process.applications then
      for _,k in ipairs(self.__process.applications) do
          if (type(k) == app_name) then
            app = k
          end
      end
    end

    if (app) then

      -- switch to existing application
      -- todo: if switching to an application that use identical group-names
      -- on the same device, we want to avoid that both apps produce output 
      -- at the same time, or they would "fight for the same space"
      -- (this is actually a sign of a bad application configuration)

      self.vb.views.dpx_browser_application_checkbox.value = app.active

    else
      -- instantiate application
      -- todo: make group-names user-configurable via special dialog
      
      if (rawget(_G, app_name)) then

        -- collect arguments
        local device_config = nil
        for _,k in ipairs(self.__devices) do 
          if (self.__device_name == k.display_name) then
            device_config = k
            break
          end
        end
        local options = nil
        if device_config then
          if device_config.options then
            options = device_config.options[app_name] or nil
          end
        end
        app = _G[app_name](self.__process.display,options)
      end

      if(app)then
        self.__process.applications:insert(app)
      end

      self.vb.views.dpx_browser_application_checkbox.value = false

    end

    self.__process.selected_app = self.vb.views.dpx_browser_application.value

  end

  -- hide run option if no application is selected
  self.vb.views.dpx_browser_application_active.visible = 
    (self.vb.views.dpx_browser_application.value ~= 1)

end


--------------------------------------------------------------------------------

function Browser:build_app()
  Application.build_app(self)

  local device_list = self:available_devices()

  local vb = self.vb
  
  self.view = vb:column{
    id = 'dpx_browser_rootnode',
    style = "body",
    width = 400,
    vb:row{
      margin = DEFAULT_MARGIN,
      vb:text{
          text="Device",
          width=60,
      },
      vb:popup{
          id='dpx_browser_input_device',
          items=device_list,
          width=200,
          notifier=function(e)
            if(e==1)then -- "None"
              -- todo: present warning only if there's active & running applications
              local message = "This will close all open devices. Are you sure?"
              local pressed = renoise.app():show_prompt("", message, {"OK","Cancel"})
              if(pressed=="OK")then
                self:set_device(self:__strip_na_postfix(device_list[e]))
                return
              else
                self.vb.views.dpx_browser_input_device.value = self.__device_index
              end
            else
              self:set_device(self:__strip_na_postfix(device_list[e]))
            end
          end
      },
      vb:button{
          id='dpx_browser_device_settings',
          text="Settings",
          --visible=false,
          notifier=function(e)
            renoise.app():show_warning("Device settings not yet implemented")
          end

      },
    },
    vb:row{
      margin = DEFAULT_MARGIN,
      id= 'dpx_browser_app_row',
      visible=false,
      vb:text{
          text="Application",
          width=60,
      },
      vb:popup{
          id='dpx_browser_application',
          items=table.create{"None"},
          value=1,
          width=200,
          notifier=function(e)
            local app_list = self:__get_available_apps()
            self:set_application(app_list[e])
          end
      },
      vb:row{
        id='dpx_browser_application_active',
        visible=false,
        vb:checkbox{
            value=false,
            id='dpx_browser_application_checkbox',
            notifier=function(e)
              if e then
                self:start_app()
              else
                self:stop_app()
              end
            end
        },
        vb:text{
            text="Run",
        },
      },
    },
  }
end


--------------------------------------------------------------------------------
-------  Application class methods
--------------------------------------------------------------------------------

-- start the currently selected app

function Browser:start_app()
  TRACE("Browser:start_app()")

  --Application.start_app(self)

  local app = self:__get_selected_app()
  if (app) then
    if (not self.vb.views.dpx_browser_application_checkbox.value) then
      -- invokes start_app again
      self.vb.views.dpx_browser_application_checkbox.value = true
    else
      app:start_app()
      self:__decorate_app_list()
    end
  end
end
  
--------------------------------------------------------------------------------

-- stop the currently selected app

function Browser:stop_app()
  TRACE("Browser:stop_app()")

  --Application.stop_app(self)

  local app = self:__get_selected_app()
  if (app) then
    if (self.vb.views.dpx_browser_application_checkbox.value) then
      -- invokes stop_app again
      self.vb.views.dpx_browser_application_checkbox.value = false
    else
      app:stop_app()
      self:__decorate_app_list()
    end
  end
end


--------------------------------------------------------------------------------

-- provide idle support for all active apps

function Browser:idle_app()
  
  if not (self.active) then
    return
  end
  -- idle process for stream
  self.stream:on_idle()
  for _,process in ipairs(self.__processes) do
    -- first, modify ui components
    if (process.display) then
      process.display:update()
    end
    -- ...then refresh the display 
    if (process.applications) then
      for _,app in ipairs(process.applications) do
        app:idle_app()
      end
    end
  end
end


--------------------------------------------------------------------------------

-- provide new document notification for all active apps

function Browser:on_new_document()
  TRACE("Browser:on_new_document()")

  for _,process in ipairs(self.__processes) do
    if (process.applications) then
      for _,app in ipairs(process.applications) do
        app:on_new_document()
      end
    end
  end
end


--------------------------------------------------------------------------------
-------  private helper functions
--------------------------------------------------------------------------------

function Browser:__strip_na_postfix(name)

  local plain_find = true
  if (name:find(DEVICE_NOT_AVAILABLE_POSTFIX, 1, plain_find)) then
    return name:sub(1, #name - #DEVICE_NOT_AVAILABLE_POSTFIX)
  else
    return name
  end
end

--------------------------------------------------------------------------------

function Browser:__strip_running_postfix(name)

  local plain_find = true
  if (name:find(APPLICATION_RUNNING_POSTFIX, 1, plain_find)) then
    return name:sub(1, #name - #APPLICATION_RUNNING_POSTFIX)
  else
    return name
  end
end


--------------------------------------------------------------------------------

function Browser:__get_app_index_by_name(app_name)
  app_name = self:__strip_running_postfix(app_name)

  local popup = self.vb.views.dpx_browser_application
  for idx,val in ipairs(popup.items)do
    if (app_name == val) then
      return idx
    end
  end

  error("Could not locate the app " .. app_name)
end


--------------------------------------------------------------------------------

-- note: changing the active application list-index will
-- cause another method, "set_application" to become invoked

function Browser:__set_application_index(name)

  self.vb.views.dpx_browser_application.value = self:__get_app_index_by_name(name)
  self.vb.views.dpx_browser_application_checkbox.value = false
end


--------------------------------------------------------------------------------

function Browser:__get_device_index_by_name(device_name)
  device_name = self:__strip_na_postfix(device_name)
  
  local popup = self.vb.views.dpx_browser_input_device
  for idx,val in ipairs(popup.items)do
    if (device_name == self:__strip_na_postfix(val)) then
      return idx
    end
  end

  error("Could not locate the device item " .. device_name)
end


--------------------------------------------------------------------------------

-- note: changing the active input device list-index will
-- cause another method, "set_device" to become invoked

function Browser:__set_device_index(device_name)
  TRACE("Browser:__set_device_index("..device_name..")")
  
  local idx = self:__get_device_index_by_name(device_name)
  self.vb.views.dpx_browser_input_device.value = idx
end


--------------------------------------------------------------------------------

-- duplex device definitions: 
-- class_name : (optional) indicates a custom device implementation
-- display_name : the "friendly" name that we assign to the device
-- device_name : the device name, as reported by the os (platform dependant?)
-- control_map : name of the default control-map
-- protocol : this is needed to instantiate a "generic" class
-- incompatible: list the applications that won't work with this device
-- options : the optional application arguments (groups-names)
-- @return table

function Browser:__get_custom_devices()

  return {
    --  this is a fullblown implementation (class + control-map)
    {
      class_name="Launchpad",      
      display_name="Launchpad",
      device_name="Launchpad",
      --control_map="Controllers/Launchpad/launchpad.xml",
      control_map="Controllers/Launchpad/launchpad_vertical_split.xml",
      protocol=DEVICE_MIDI_PROTOCOL,
      options=table.create{
        MixConsole = table.create{
          levels_group_name="Grid2",
          master_group_name="Triggers2",
        },
        PatternMatrix = table.create{
          matrix_group_name = "Grid",
          trigger_group_name = "Triggers",
          controls_group_name = "Controls",
        },
        MatrixTest = table.create{
          matrix_group_name = "Grid",
        },
      },
    },
    -- alternate implementation for testing purposes
    {
      class_name="Launchpad",      
      display_name="LaunchpadTest",
      device_name="Launchpad",
      control_map="Controllers/Launchpad/launchpad.xml",
      protocol=DEVICE_MIDI_PROTOCOL,
      options=table.create{
        MixConsole = table.create{
          levels_group_name="Grid",
          master_group_name="Triggers",
        },
        PatternMatrix = table.create{
          matrix_group_name = "Grid",
          trigger_group_name = "Triggers",
          controls_group_name = "Controls",
        },
      },
    },
    --  the Nocturn should load as a generic MIDI device
    --  note: device_name is different from display_name!
    {
      class_name=nil,
      display_name="Nocturn",      
      device_name="Automap MIDI",    
      control_map="Controllers/Nocturn/nocturn.xml",
      protocol=DEVICE_MIDI_PROTOCOL,
      incompatible = table.create{"PatternMatrix","MatrixTest"},
      options = table.create{
        MixConsole = table.create{
          levels_group_name = "Encoders",
          mute_group_name = "Pots",
          master_group_name = "XFader",
        },
      },
    },
    --  TODO: implement class
    {
      class_name=nil,          
      display_name="BCF-2000",
      device_name="BCF2000",
      control_map="Controllers/BCF-2000/bcf-2000.xml",
      protocol=DEVICE_MIDI_PROTOCOL,
      incompatible = table.create{"PatternMatrix","MatrixTest"},
      options = table.create{
        MixConsole = table.create{
          mute_group_name = "Buttons1",
          panning_group_name= "Encoders",
          levels_group_name = "Faders",
          page_controls_group_name = "PageControls",
        },
      },
    },
    --  TODO: implement class
    {
      class_name=nil,          
      display_name="BCR-2000",
      device_name="BCR2000",
      control_map="Controllers/BCR-2000/bcr-2000.xml",
      protocol=DEVICE_MIDI_PROTOCOL,
      incompatible = table.create{"PatternMatrix","MatrixTest"},
      options = table.create()
    },
    --  TODO: implement class
    {
      class_name=nil,          
      display_name="OHM64",
      device_name="Ohm64 MIDI 1",
      control_map="Controllers/OHM64/ohm64.xml",
      protocol=DEVICE_MIDI_PROTOCOL,
      options = table.create{
        MixConsole = table.create{
          levels_group_name="VolumeLeft",
          master_group_name="VolumeRight",
        },
        PatternMatrix = table.create{
          matrix_group_name = "Grid",
          trigger_group_name = "MuteLeft",
          controls_group_name = "ControlsRight",
        },
        MatrixTest = table.create{
          matrix_group_name = "Grid",
        },      
      }
    },
    --  this is a defunkt implementation (no control-map)
    --  will cause a warning once it's opened
    {
      class_name=nil,          
      display_name="mrmr",
      device_name="mrmr",
      control_map="mrmr.xml",
      protocol=DEVICE_OSC_PROTOCOL,
      options = table.create()
    },
  }

end

--------------------------------------------------------------------------------

-- return the currently selected process 
-- @return table or nil

function Browser:__get_selected_process()
  TRACE("Browser:__get_selected_process()")

  for _,k in ipairs(self.__processes) do
    if(k.name == self.__device_name) then
      return k
    end
  end
end

--------------------------------------------------------------------------------

-- return the currently selected app 
-- @return Application or nil

function Browser:__get_selected_app()
  TRACE("Browser:__get_selected_app()")

  local app_name = self.vb.views.dpx_browser_application.items[
    self.vb.views.dpx_browser_application.value]
  app_name = self:__strip_running_postfix(app_name)
  for _,k in ipairs(self.__processes) do
    if(k.name == self.__device_name) then
      for _,app in ipairs(k.applications) do
        if(type(app) == app_name)then
          return app
        end
      end
    end
  end
end

--------------------------------------------------------------------------------

-- instantiate a device from it's basic information,
-- save this information into the "__processes" list

function Browser:__instantiate_device(display_name,class_name, device_name, control_map)
  TRACE("Browser:__instantiate_device:",display_name,class_name, device_name, control_map)

  -- instantiate the device from the class name
  if (rawget(_G, class_name)) then
  
    local process = table.create()
    process.name = display_name
    process.device = _G[class_name](device_name, self.stream)
    process.device:set_control_map(control_map)
    process.display = Display(process.device)
    process.applications = table.create()
    process.selected_app = 1  -- "None"

    self.vb.views.dpx_browser_rootnode:add_child(
      process.display:build_control_surface())
    process.display:show_control_surface()
    
    process.device.display = process.display
    self.__processes:insert(process)

  else
    renoise.app():show_warning(("Whoops! This device uses " ..
      "unknown device class: '%s'"):format(class_name))
  end 

end


