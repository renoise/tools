--[[----------------------------------------------------------------------------
-- Duplex.Browser
----------------------------------------------------------------------------]]--

--[[

The Browser class provides easy access to running scripts

--]]


--==============================================================================

class 'Browser' (Application)

function Browser:__init(device_name,app_name)
  TRACE("Browser:__init",device_name,app_name)

  -- initialize
  self.name = "Browser"
  self.device = nil
  self.display = nil
  self.stream = MessageStream()

  self.application = nil  --  current application

  Application.__init(self)

  self.vb = renoise.ViewBuilder()

  self:build_app()
  -- hide after building
  self.vb.views.dpx_browser_app_row.visible = false
  self.vb.views.dpx_browser_device_settings.visible = false
  self.vb.views.dpx_browser_fix.visible = false

  -- as last step, apply optional arguments
  if device_name then
    self:set_device_index(device_name)
    if app_name then
      self:set_application(app_name)
    end
  end


end


-- note: changing the active input device list-index will
-- cause another method, "set_device" to become invoked

function Browser:set_device_index(name)
  TRACE("Browser:set_device_index("..name..")")

  local idx = self:get_list_index("dpx_browser_input_device",name)
  self.vb.views.dpx_browser_input_device.value = idx

end


--------------------------------------------------------------------------------

-- set the active input device
-- * instantiate the new device 
-- * load dedicated class if it exists
-- * filter applications
-- @param name (string)  the name of the device (display_name)

function Browser:set_device(name)
  TRACE("Browser:set_device("..name..")")

  local idx = self:get_list_index("dpx_browser_input_device",name)
  self.vb.views.dpx_browser_input_device.value = idx

  if self.device then
    self.device:release()
    self.display:hide_control_surface()
  end

  -- "cascading" effect
  self:set_application("None")

  if (name == "None") then
    self.vb.views.dpx_browser_app_row.visible = false
    self.vb.views.dpx_browser_device_settings.visible = false
    return  
  else
    self.vb.views.dpx_browser_app_row.visible = true
    self.vb.views.dpx_browser_device_settings.visible = true

  end

  local custom_devices = self:get_custom_devices()
  for _,k in ipairs(custom_devices) do
  
    if (name==k.display_name) then
      if k.classname then
        self:instantiate_device(k.class_name,k.device_name,k.control_map)
      elseif k.control_map then

        local generic_class = nil
        if(k.protocol == DEVICE_MIDI_PROTOCOL)then
          generic_class = "MIDIDevice"
        elseif(k.protocol == DEVICE_OSC_PROTOCOL)then
          generic_class = "OSCDevice"
        end

        local class_name = k.class_name or generic_class
        self:instantiate_device(class_name,k.device_name,k.control_map)
      else
        renoise.app():show_warning("Whoops! This device needs a control-map")
      end
    end
    
  end

end


--------------------------------------------------------------------------------

-- instantiate a device from it's basic information

function Browser:instantiate_device(class_name,device_name,control_map)
  TRACE("Browser:instantiate_device:",class_name)

  if class_name == "MIDIDevice" then

    -- standard/generic MIDI device
    -- always provide a device_name and control-map

    self.device = MIDIDevice(device_name)

  elseif class_name == 'Launchpad' then

    -- TODO on-the-fly loading of classes 

    self.device = Launchpad(device_name)
  
  end

  if self.device then
    self.device:set_control_map(control_map)
    self.device.message_stream = self.stream

    self.display = Display(self.device)
    self.display:build_control_surface()
    self.vb.views.dpx_browser_rootnode:add_child(self.display.view)
    self.display:show_control_surface()

  end

end


--------------------------------------------------------------------------------

--  return list of valid devices plus a "none" option
--  include devices that match the device name (dedicated classes)
--  and/or has a control-map (as this enables the control surface)

function Browser:get_devices()

  local tmp = nil
  local rslt = {"None"}

  local input_devices = renoise.Midi.available_input_devices()
  local custom_devices = self:get_custom_devices()

  --table.insert(rslt, "--------  custom devices  ---------")
  for idx,t in ipairs(custom_devices) do
    for _,k in ripairs(input_devices) do
      if (string.sub(k,0,string.len(t.device_name))==t.device_name) then
        table.insert(rslt, t.display_name)
        table.remove(custom_devices,idx) -- remove from list
      end
    end
  end
  --table.insert(rslt, "----  control-mapped devices  -----")
  for _,t in ipairs(custom_devices) do
    if (t.control_map) then
      table.insert(rslt, t.display_name)
    end
  end

  return rslt

end


--------------------------------------------------------------------------------

-- helper : get the currently selected index of a list

function Browser:get_list_index(view_elm,name)

  local elm = self.vb.views[view_elm]
  for idx,val in ipairs(elm.items)do
    if name == val then
      return idx
    end
  end
  print("Notice: could not locate the item "..name)
  return 1

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

function Browser:get_custom_devices()

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
      display_name="Behringer BCF-2000",
      device_name="BCF-2000",  -- ???
      control_map="Controllers/BCF-2000/bcf-2000.xml",
      protocol=DEVICE_MIDI_PROTOCOL,
    },
    --  TODO: implement class
    {
      class_name=nil,          
      display_name="Behringer BCR-2000",
      device_name="BCR-2000", -- ??? 
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

-- return list of supported applications
-- TODO filter applications by device
-- @param (string)  device_name: show only scripts that are  
--          guaranteed to work with this device

function Browser:get_applications(device_name)

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

function Browser:set_application(name)
  TRACE("Browser:set_application:",name)
  --renoise.app():show_warning("not yet implemented")

  self.vb.views.dpx_browser_application.value = self.get_list_index(
    self, "dpx_browser_application", name)
    
  self.vb.views.dpx_browser_application_checkbox.value = false

  if self.application then
    self.application:destroy_app()
  end

  -- hide/show the "run" option
  if self.vb.views.dpx_browser_application.value == 1 then
    self.vb.views.dpx_browser_application_active.visible = false
    --self.display:clear()
  else
    self.vb.views.dpx_browser_application_active.visible = true
  end

  -- TODO: load classes dynamically
  local elm = self.vb.views["dpx_browser_input_device"]
  local device_display_name = elm.items[elm.value]

  if name == "MixConsole" then
    
    local sliders_group_name=nil
    local buttons_group_name=nil
    local master_group_name=nil

    -- TODO: control-map groups should be user-configurable
    -- make some sort of application preferences to solve this
    if device_display_name == "Launchpad" then
      sliders_group_name="Grid"
      buttons_group_name="Controls"
      master_group_name="Triggers"
    elseif device_display_name == "Nocturn" then
      sliders_group_name="Encoders"
      buttons_group_name="Pots"
      master_group_name="XFader"
    end

    self.application = MixConsole(self.display, sliders_group_name,
      buttons_group_name, master_group_name)
  end

  if name == "PatternMatrix" then
    -- currently only for use with launchpad...
    if device_display_name == "Launchpad" then
      self.application = PatternMatrix(self.display,"Grid","Triggers")
    end
  end
end


--------------------------------------------------------------------------------

-- TODO apply preset to application
-- application needs to expose parameters somehow...

function Browser:set_preset()
  renoise.app():show_warning("not yet implemented")
end


--------------------------------------------------------------------------------

-- construct the browser "view" 

function Browser:build_app()
  Application.build_app(self)

  local input_devices = self:get_devices()
  local applications = self:get_applications()
  --local presets = self:get_presets()

  --local vb = renoise.ViewBuilder()
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
          items=input_devices,
          --value=4,
          width=200,
          notifier=function(e)
            self:set_device(input_devices[e])
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
-------  class methods ----------
--------------------------------------------------------------------------------

function Browser:start_app()
  Application.start_app(self)

  if self.application then
    self.application:start_app()
  end
end
  

--------------------------------------------------------------------------------

function Browser:stop_app()
  Application.stop_app(self)

  if self.application then
    self.application:stop_app()
  end
end


--------------------------------------------------------------------------------

function Browser:idle_app()
  if not self.active then
    return
  end
  -- idle process for stream
  self.stream:on_idle()

  -- modify ui components
  if self.display then
    self.display:update()
  end
  -- then update the display 
  if self.application then
    self.application:idle_app()
  end


end


--------------------------------------------------------------------------------

function Browser:on_new_document()
  TRACE("Browser:on_new_document()")
  -- refresh notifiers 
  if self.application then
    self.application:on_new_document()
  end
end
