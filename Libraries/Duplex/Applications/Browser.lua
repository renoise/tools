--[[----------------------------------------------------------------------------
-- Duplex.Browser
----------------------------------------------------------------------------]]--

--[[

The Browser class provides easy access to running scripts

--]]


--==============================================================================

local DEVICE_NOT_AVAILABLE_POSTFIX = " (N/A)"


--==============================================================================

class 'Browser' (Application)

function Browser:__init(device_name, app_name)
  TRACE("Browser:__init",device_name, app_name)

  Application.__init(self)

  -- initialize
  self.name = "Browser"
  self.device = nil
  self.display = nil

  self.stream = MessageStream()
  self.application = nil  --  current application

  self.vb = renoise.ViewBuilder()

  self:build_app()
  
  -- hide after building
  self.vb.views.dpx_browser_app_row.visible = false
  self.vb.views.dpx_browser_device_settings.visible = false
  self.vb.views.dpx_browser_fix.visible = false

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

--  return list of valid devices plus a "none" option
--  include devices that match the device name (dedicated classes)
--  and/or has a control-map (as this enables the control surface)

function Browser:available_devices()

  local result = table.create{"None"}
  
  local input_devices = table.create(renoise.Midi.available_input_devices())
  local custom_devices = table.create(self:__get_custom_devices())

  -- insert devices that are installed on this system (the user's devices) first
  for idx,t in ipairs(custom_devices) do
    for _,k in ripairs(input_devices) do
      if (k:sub(0, #t.device_name) == t.device_name) then
        result:insert(t.display_name)
        custom_devices:remove(idx) -- remove from list
      end
    end
  end

  -- then all others that are avilable in duplex but are not installed
  for _,t in ipairs(custom_devices) do
    if (t.control_map) then
      result:insert(t.display_name .. DEVICE_NOT_AVAILABLE_POSTFIX)
    end
  end

  return result
end


--------------------------------------------------------------------------------

-- set the active input device
-- * instantiate the new device 
-- * load dedicated class if it exists
-- * filter applications
-- @param name (string)  the name of the device (display_name)

function Browser:set_device(name)
  TRACE("Browser:set_device("..name..")")
  
  -- release already running devices first
  if (self.device) then
    self.device:release()
    self.display:hide_control_surface()
  end

  -- adjust device index, in case it was not fired from the GUI
  local idx = self:__get_device_index(name)
  self.vb.views.dpx_browser_input_device.value = idx

  -- "cascading" effect
  self:__set_application_index("None")

  if (name == "None") then
    self.vb.views.dpx_browser_app_row.visible = false
    self.vb.views.dpx_browser_device_settings.visible = false
  
  else
    self.vb.views.dpx_browser_app_row.visible = true
    self.vb.views.dpx_browser_device_settings.visible = true

    local custom_devices = self:__get_custom_devices()
    
    for _,k in ipairs(custom_devices) do 
      if (name == k.display_name) then
        if (k.class_name) then
          -- device has its own class
          self:__instantiate_device(k.class_name, k.device_name, k.control_map)
          break
  
        elseif (k.control_map) then
          -- device has a control map but no class. use a default one
          local generic_class = nil
  
          if (k.protocol == DEVICE_MIDI_PROTOCOL)then
            generic_class = "MIDIDevice"
          
          elseif (k.protocol == DEVICE_OSC_PROTOCOL)then
            generic_class = "OscDevice"
          
          else
            error(("device uses unexpected protocol: %d"):format(k.protoco))
          end
  
          self:__instantiate_device(generic_class, k.device_name, k.control_map)
          break
        
        else
          renoise.app():show_warning("Whoops! This device needs a control-map")
        end      
      end
    end
  end
end


--------------------------------------------------------------------------------

-- return list of supported applications
-- TODO filter applications by device
-- @param (string)  device_name: show only scripts that are  
--          guaranteed to work with this device

function Browser:available_applications(device_name)

  return {
    "None",
    "MixConsole",
    "PatternMatrix",
  }
  
end


--------------------------------------------------------------------------------

-- set application as active item 
-- currently, we display only a single app at a time
-- but it should be possible to run several apps!

function Browser:set_application(application_name)
  TRACE("Browser:set_application:",application_name)

  if (self.application) then
    -- rebuilt the app
    self.application:destroy_app()
    self.application = nil
    self.vb.views.dpx_browser_application_checkbox.value = false
  end

  -- hide run option if no application is selected
  self.vb.views.dpx_browser_application_active.visible = 
    (self.vb.views.dpx_browser_application.value ~= 1)

  -- get current device name
  local device_display_name = self:__strip_na_postfix(
    self.vb.views.dpx_browser_input_device.items[
      self.vb.views.dpx_browser_input_device.value]
  )


  -- map control groups to the app 
  -- todo: make group-names configurable
  
  if (application_name == "MixConsole") then  
    local sliders_group_name = nil
    local encoders_group_name = nil
    local buttons_group_name = nil
    local master_group_name = nil
    local page_scroll_group_name = nil

    if (device_display_name == "Launchpad") then
      sliders_group_name="Grid"
      buttons_group_name="Controls"
      master_group_name="Triggers"
    
    elseif (device_display_name == "Nocturn") then
      sliders_group_name = "Encoders"
      buttons_group_name = "Pots"
      master_group_name = "XFader"
    
    elseif (device_display_name == "BCF-2000") then
      buttons_group_name = "Buttons1"
      encoders_group_name= "Encoders"
      sliders_group_name = "Faders"
      page_scroll_group_name = "PageControls"
    end

    self.application = MixConsole(self.display, 
      sliders_group_name, encoders_group_name, buttons_group_name, 
      master_group_name, page_scroll_group_name)

  elseif (application_name == "PatternMatrix") then
  
    -- pattern matrix currently only for the launchpad...
    if (device_display_name == "Launchpad") then
      self.application = PatternMatrix(self.display, "Grid", "Triggers")
    end
  end
end


--------------------------------------------------------------------------------

-- construct the browser "view" 

function Browser:build_app()
  Application.build_app(self)

  local devices = self:available_devices()
  local applications = self:available_applications()
  --local presets = self:get_presets()

  local vb = self.vb
  
  self.view = vb:column{
    --margin = DEFAULT_MARGIN,
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
          items=devices,
          --value=4,
          width=200,
          notifier=function(e)
            self:set_device(self:__strip_na_postfix(devices[e]))
          end
      },
      vb:button{
          id='dpx_browser_device_settings',
          text="Settings",
          --visible=false,
      },
    },
    vb:row{
      margin = DEFAULT_MARGIN,
      id= 'dpx_browser_app_row',
      --visible=false,
      vb:text{
          text="Application",
          width=60,
      },
      vb:popup{
          id='dpx_browser_application',
          items=applications,
          value=1,
          width=200,
          notifier=function(e)
            self:set_application(applications[e])
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

    -- the following is used to control initial size of dialog
    vb:button{
      id='dpx_browser_fix',
      width=400,
      height=400,
      text="BOOM",
    },
  }
end


--------------------------------------------------------------------------------
-------  Application class methods
--------------------------------------------------------------------------------

function Browser:start_app()
  TRACE("Browser:start_app()")

  Application.start_app(self)

  if (self.application) then
    if (not self.vb.views.dpx_browser_application_checkbox.value) then
      -- invokes start_app again
      self.vb.views.dpx_browser_application_checkbox.value = true
    else
      self.application:start_app()
    end
  end
end
  

--------------------------------------------------------------------------------

function Browser:stop_app()
  TRACE("Browser:stop_app()")

  Application.stop_app(self)

  if (self.application) then
    if (self.vb.views.dpx_browser_application_checkbox.value) then
      -- invokes stop_app again
      self.vb.views.dpx_browser_application_checkbox.value = false
    else
      self.application:stop_app()
    end
  end
end


--------------------------------------------------------------------------------

function Browser:idle_app()
  
  if not (self.active) then
    return
  end
  
  -- idle process for stream
  self.stream:on_idle()

  -- modify ui components
  if (self.display) then
    self.display:update()
  end
  -- then update the display 
  if (self.application) then
    self.application:idle_app()
  end
end


--------------------------------------------------------------------------------

function Browser:on_new_document()
  TRACE("Browser:on_new_document()")
  
  -- refresh notifiers 
  if (self.application) then
    self.application:on_new_document()
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

-- get the currently selected application popup index index for a app name

function Browser:__get_application_index(app_name)

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

  self.vb.views.dpx_browser_application.value = self:__get_application_index(name)
  self.vb.views.dpx_browser_application_checkbox.value = false
end


--------------------------------------------------------------------------------

-- get the currently selected application popup index index for a device  name

function Browser:__get_device_index(device_name)
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
  
  local idx = self:__get_device_index(device_name)
  self.vb.views.dpx_browser_input_device.value = idx
end


--------------------------------------------------------------------------------

--  todo: check for "real" device config-files
--  @class_name : (optional) indicates that device has a custom implementation
--  @display_name : the name we list in the popup, can contain additional 
--   information, such as number and status (e.g. "Launchpad [2] (active)"
--  @device_name : the device name, as reported by the os 
--   (we should allow different names for different platforms)
--  @control_map : name of the default control-map
--  @protocol : if we instantiate a "generic" class, this is needed

function Browser:__get_custom_devices()

  return {
    --  this is a fullblown implementation (class + control-map)
    --  the class tell us of the hardware capabilities
    {
      class_name="Launchpad",      
      display_name="Launchpad",
      device_name="Launchpad",
      control_map="Controllers/Launchpad/launchpad.xml",
      protocol=DEVICE_MIDI_PROTOCOL,
    },
    --  different controlmap
    {
      class_name="Launchpad",      
      display_name="Launchpad (with encoders)",
      device_name="Launchpad",
      control_map="Controllers/Launchpad/launchpad_encoders.xml",
      protocol=DEVICE_MIDI_PROTOCOL,
    },
    --  here, device_name is different from display_name 
    --  it should load as a generic MIDI device
    {
      class_name=nil,
      display_name="Nocturn",      
      device_name="Automap MIDI",    
      control_map="Controllers/Nocturn/nocturn.xml",
      protocol=DEVICE_MIDI_PROTOCOL,
    },
    --  this is a defunkt implementation (no control-map)
    --  will cause a warning once it's opened
    {
      class_name=nil,          
      display_name="Remote SL",
      device_name="Automap MIDI",  
      control_map=nil,
      protocol=DEVICE_MIDI_PROTOCOL,
    },
    --  TODO: implement class
    {
      class_name=nil,          
      display_name="BCF-2000",
      device_name="BCF2000",
      control_map="Controllers/BCF-2000/bcf-2000.xml",
      protocol=DEVICE_MIDI_PROTOCOL,
    },
    --  TODO: implement class
    {
      class_name=nil,          
      display_name="BCR-2000",
      device_name="BCR2000",
      control_map="Controllers/BCR-2000/bcr-2000.xml",
      protocol=DEVICE_MIDI_PROTOCOL,
    },

    --  and here I don't really know how to list osc clients?
    {
      class_name=nil,          
      display_name="mrmr",
      device_name="mrmr",
      control_map="mrmr.xml",
      protocol=DEVICE_OSC_PROTOCOL,
    },
  }

end

--------------------------------------------------------------------------------

-- instantiate a device from it's basic information

function Browser:__instantiate_device(class_name, device_name, control_map)
  TRACE("Browser:__instantiate_device:",class_name)

  -- instantiate the device from the class name
  if (rawget(_G, class_name)) then
    self.device = _G[class_name](device_name, self.stream)
    self.device:set_control_map(control_map)

    self.display = Display(self.device)
    self.vb.views.dpx_browser_rootnode:add_child(
      self.display:build_control_surface())
    self.display:show_control_surface()
    
    self.device.display = self.display

  else
    renoise.app():show_warning(("Whoops! This device uses " ..
      "unknown device class: '%s'"):format(class_name))
  end 
end


