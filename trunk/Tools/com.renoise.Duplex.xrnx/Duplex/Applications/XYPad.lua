--[[----------------------------------------------------------------------------
-- Duplex.XYPad
-- Inheritance: Application > RoamingDSP > XYPad
----------------------------------------------------------------------------]]--

--[[

About

  The XYPad application is designed to take over/auto-map any XYPad device in any Renoise DSP Chain. You can control and record movement on the X/Y axis via knobs, a MIDI keyboard's touchpad or an OSC device's accelerometer

  At it's most basic level, the application is targeting any XYPad that has been selected in Renoise, freely roaming the tracks. It supports automation recording as well - hit the edit-button, and it will record automation envelopes (according to the selected mode in options). 

  While the free-roaming mode is useful, you also have the locked mode. This is the complete opposite, as it will always target a single device, no matter the track or device that's currently selected. The locked mode can either be set by being mapped to a button, or via the options dialog. In either case, the locked state of a device can be restored between sessions, as the application will 'tag' the device with a unique name. 
  
  By selecting a different unique name, we can run multiple XYPad applications, and each one will be controlling a different XYPad device. Even when you move devices and tracks around, things should not break.
  
  If you select an unassignable (non-XYPad) device in free-roaming mode, and you have assigned lock_button somewhere on your controller, the button will start to blink slowly, to remind you that the application is currently 'homeless', has no parameter to control. 

  To complement the "lock" button, we also have a "focus" button. This button brings focus back to the locked device, whenever you have (manually) selected an un-locked device.

  Finally, we can navigate between XYPad devices by using the 'next' and 'previous' buttons. Pressing one will search across all tracks in the song, so we can putting our XYPad device in any track we want. In case we have locked to a device, previous/next will "transfer" the lock to that device (use carefully if you have other locked XYPad devices, as this will overwrite their special name).

  How to add XYPad to your control-map (applies only to OSC devices)

  The application include some additions to the Duplex control-map implementation. In order to use the application with something like tilt-sensors, a special "xypad" type has been introduced. It can receive input from such things as tilt sensors or virtual XY pads (which often send their value in pairs). In the virtual control surface, the xypad is displayed as a native XY pad, while MIDI devices continues to be slider/knob-based. 

  <Param name="MyDevicePad" type="xypad" invert_x="false" invert_y="true"
    minimum="-2" maximum="2"/>

  To enter the correct minimum and maximum values, it's important you know a bit 
  about your device as the application will base it's min/max/axis values 
  directly on the information specified here. 

Mappings

  For basic operation, you can either map 

  xy_pad      (UIPad)         This is the OSC-only(?) mapping that accept
                                both X and Y axis simultaneously
  -- or --

  xy_grid     (UIButtons)       This is a multiple-button "emulation" of
                                an XYPad on your grid controller. Minimum
                                required resolution is 2x2
  -- or --

  x_slider      (UISlider)        Map each axis to it's own fader/knob
  y_slider      (UISlider)        --//--

  -- and optionally --

  lock_button   (UIButton)  Lock/unlock currently selected XYPad device
  focus_button  (UIButton)  Bring focus to locked device (if it exists)
  next_device   (UIButton)  Select next XYPad (+locking)
  prev_device   (UIButton)  Select previous XYPad (+locking)


Options

  locked        - Disable locking if you want the controls to
                  follow the currently selected device
  record_method - Determine how to record automation


Idea/planned features

  Support custom/combined display-names 
  

Changes (equal to Duplex version number)

  0.98 - First release 


--]]



--==============================================================================

class 'XYPad' (RoamingDSP)

XYPad.default_options = {

}

XYPad.available_mappings = {
  xy_pad = {
    description = "XYPad: XY Pad",
  },
  xy_grid = {
    description = "XYPad: XY Grid",
  },
  x_slider = {
    description = "XYPad: X-Axis",
    orientation = HORIZONTAL
  },
  y_slider = {
    description = "XYPad: Y-Axis",
    orientation = VERTICAL
  },
}

XYPad.default_palette = {
  grid_on         = { color = {0xFF,0xFF,0x00}, text = "▪", val=true  },  
  grid_off        = { color = {0x40,0x40,0x00}, text = "·", val=false },  
}

--  merge superclass options, mappings & palette --

for k,v in pairs(RoamingDSP.default_options) do
  XYPad.default_options[k] = v
end
for k,v in pairs(RoamingDSP.available_mappings) do
  XYPad.available_mappings[k] = v
end
for k,v in pairs(RoamingDSP.default_palette) do
  XYPad.default_palette[k] = v
end


--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg), see Application to learn more

function XYPad:__init(...)
  TRACE("XYPad:__init()",...)

  -- the name of the device we are controlling
  self._instance_name = "*XY Pad"

  -- update display
  self.update_requested = true

  -- boolean, set to temporarily skip value notifier
  self.suppress_value_observable = false

  -- current value
  self.value = {nil,nil}

  -- remember any values from the control-map, such
  -- as minimum and maximum values 
  -- xypad 
  self.min_value = 0
  self.max_value = 1
  -- x/y_slider 
  self.x_slider_args = nil
  self.y_slider_args = nil

  -- TODO use the XYPad device's settings
  --self.reset_value = {0.5,0.5}
  --self._reset_delay_ms = 200
  --self._reset_time = nil

  -- the detected grid width/height
  self.grid_width = nil
  self.grid_height = nil

  -- controls
  self._xy_pad = nil  -- UIXYPad
  self._xy_grid = nil -- UIButtons...
  self._x_slider = nil  -- UISlider
  self._y_slider = nil  -- UISlider
  self._prev_button = nil   -- UIButton
  self._next_button = nil   -- UIButton

  RoamingDSP.__init(self,...)


end

--------------------------------------------------------------------------------

-- perform periodic updates

function XYPad:on_idle()
	--TRACE("XYPad:on_idle")

  if (not self.active) then 
    return 
  end

  if self.current_device_requested then
    self.update_requested = true
  end

  if self.update_requested then
    self:update_controller()
  end

  RoamingDSP.on_idle(self)

end


--------------------------------------------------------------------------------

-- apply the value to the targeted DSP device

function XYPad:update_renoise()
  TRACE("XYPad:update_renoise()")

  if self.target_device then

    local val_x = self.value[1]
    local val_y = self.value[2]

    if (self.min_value ~= 0) or 
      (self.max_value ~= 1) then
      val_x = scale_value(val_x,self.min_value,self.max_value,0,1)
      val_y = scale_value(val_y,self.min_value,self.max_value,0,1)
    end

    self.target_device.parameters[1].value = val_x
    self.target_device.parameters[2].value = val_y

  end

end

--------------------------------------------------------------------------------

-- update display state of the various controls

function XYPad:update_controller()
  TRACE("XYPad:update_controller()")

  local skip_event = true

  if self._xy_pad then
    self._xy_pad:set_value(self.value[1],self.value[2],skip_event)
    --print("set UIPad to ",self.value[1],self.value[2])
  end
  if self._x_slider then
    local slider_min = self.x_slider_args.minimum
    local slider_max = self.x_slider_args.maximum
    local val_scaled = round_value(scale_value(self.value[1],self.min_value,self.max_value,slider_min,slider_max))
    self._x_slider:set_value(val_scaled,skip_event)
    --print("set X UISlider to ",self.value[1])
  end
  if self._y_slider then
    --print("setting y slider to",self.value[2])
    local slider_min = self.x_slider_args.minimum
    local slider_max = self.x_slider_args.maximum
    local val_scaled = round_value(scale_value(self.value[2],self.min_value,self.max_value,slider_min,slider_max))
    self._y_slider:set_value(val_scaled,skip_event)
    --print("set Y UISlider to ",self.value[2])
  end
  if self._xy_grid then

    local x_scaled = round_value(scale_value(self.value[1],0,1,1,self.grid_width))
    local y_scaled = round_value(scale_value(self.value[2],0,1,1,self.grid_height))

    for x=1,self.grid_width do
      for y=self.grid_height,1,-1 do
        local matched = false
        if (x == x_scaled) and (y == y_scaled) then
          matched = true
        end
        local flipped_y = math.abs(y-self.grid_height)+1
        if matched then
          self._xy_grid[x][flipped_y]:set(self.palette.grid_on)
        else
          self._xy_grid[x][flipped_y]:set(self.palette.grid_off)
        end
      end
    end

  end

end


--------------------------------------------------------------------------------

-- return the X/Y axis parameter of the target device
-- @return DeviceParameter

function XYPad:get_xy_params()

  if not self.target_device then
    return
  end
  local params = {}
  for _,param in ipairs(self.target_device.parameters) do
    if (param.name == "X-Axis") then
      params.x = param
    end
    if (param.name == "Y-Axis") then
      params.y = param
      break
    end
  end
  return params
end

function XYPad:get_y_param()

  if not self.target_device then
    return
  end
  for _,param in ipairs(self.target_device.parameters) do
    if (param.name == "Y-Axis") then
      return param
    end
  end
end

--------------------------------------------------------------------------------

-- construct the user interface

function XYPad:_build_app()
  TRACE("XYPad:_build_app()")

  -- start by adding the roaming controls:
  -- lock_button,next_device,prev_device...
  RoamingDSP._build_app(self)

  local cm = self.display.device.control_map

  -- create the xypad?
  local xy_pad_idx = self.mappings.xy_pad.index or 1
  local xy_pad_name = self.mappings.xy_pad.group_name
  local xy_pad_args = cm:get_indexed_element(xy_pad_idx,xy_pad_name)

  -- create a grid?
  local xy_grid_idx = self.mappings.xy_grid.index or 1
  local xy_grid_name = self.mappings.xy_grid.group_name
  local xy_grid_args = cm:get_indexed_element(xy_grid_idx,xy_grid_name)

  -- create sliders?
  self.x_slider_args = nil
  self.y_slider_args = nil

  local x_slider_idx,x_slider_name
  local y_slider_idx,y_slider_name

  if xy_pad_args then

    self.min_value = xy_pad_args.minimum
    self.max_value = xy_pad_args.maximum

  else
    
    x_slider_idx = self.mappings.x_slider.index or 1
    x_slider_name = self.mappings.x_slider.group_name
    self.x_slider_args = cm:get_indexed_element(x_slider_idx,x_slider_name)

    y_slider_idx = self.mappings.y_slider.index or 1
    y_slider_name = self.mappings.y_slider.group_name
    self.y_slider_args = cm:get_indexed_element(y_slider_idx,y_slider_name)

    if not xy_grid_args and not self.x_slider_args and not self.y_slider_args then
      local msg = "Could not start instance of Duplex XYPad:"
                .."\nneither 'xy_pad', 'x_slider/y_slider' or 'xy_grid'"
                .."\nmapping has been specified"
      renoise.app():show_warning(msg)
      return false
    else
      if self.x_slider_args then
        self.min_value = self.x_slider_args.minimum
        self.max_value = self.x_slider_args.maximum
      end
    end
  end

  if not self.min_value and not self.max_value then
    local msg = "Could not start instance of Duplex XYPad:"
              .."\nthe parameters need to have minimum/maximum values"
    renoise.app():show_warning(msg)
    return false
  end

  -- default value is between min and max
  local center_val = self.min_value + ((self.max_value-self.min_value)/2)
  self.value = {center_val,center_val}
  --print("*** initial value",self.value[1],self.value[2])

  -- XY pad
  if xy_pad_args then

    local c = UIPad(self.display)
    c.group_name = xy_pad_name
    c.secondary_index = y_slider_idx
    c:set_pos(xy_pad_idx)
    c.tooltip = self.mappings.xy_pad.description
    c.value = self.value
    --c.floor = self.min_value
    c.ceiling = self.max_value

    c.on_change = function(obj)
      if not self.active then return false end
      self.value = obj.value
      self.suppress_value_observable = true
      self:update_renoise()
      if self._record_mode then
        local params = self:get_xy_params()
        if params then
          local val_x = scale_value(obj.value[1],self.min_value,self.max_value,0,1)
          local val_y = scale_value(obj.value[2],self.min_value,self.max_value,0,1)
          self.automation:add_automation(self.track_index,params.x,val_x)
          self.automation:add_automation(self.track_index,params.y,val_y)
        end
      end
      self.suppress_value_observable = false

    end
    self:_add_component(c)
    self._xy_pad = c
  end

  -- X Axis
  if self.x_slider_args then

    -- check for pad/grid style mapping
    local x_slider_size = 1
    local grid_mode = cm:is_grid_group(x_slider_name,self.mappings.x_slider.index)
    local x_slider_orientation = self.mappings.x_slider.orientation
    if grid_mode then
      if (x_slider_orientation == HORIZONTAL) then
        x_slider_size = cm:count_columns(x_slider_name)
      else
        x_slider_size = cm:count_rows(x_slider_name)
      end
    end

    local c = UISlider(self.display)
    c.group_name = x_slider_name
    c.secondary_index = y_slider_idx -- for detecting paired values
    c:set_pos(x_slider_idx)
    c.flipped = true
    c.toggleable = true
    c.palette.track = table.rcopy(c.palette.background)
    c:set_orientation(x_slider_orientation)
    c:set_size(x_slider_size)
    c.ceiling = self.x_slider_args.maximum
    c.tooltip = self.mappings.x_slider.description
    c.value = self.value[1]
    c.on_change = function(obj)
      if not self.active then return false end
      self.value[1] = obj.value
      self.suppress_value_observable = true
      self:update_renoise()
      self.suppress_value_observable = false
    end
    self:_add_component(c)
    self._x_slider = c
  end

  -- Y Axis
  if self.y_slider_args then

    -- check for pad/grid style mapping
    local y_slider_size = 1
    local grid_mode = cm:is_grid_group(y_slider_name,self.mappings.y_slider.index)
    local y_slider_orientation = self.mappings.y_slider.orientation
    if grid_mode then
      if (y_slider_orientation == HORIZONTAL) then
        y_slider_size = cm:count_columns(y_slider_name)
      else
        y_slider_size = cm:count_rows(y_slider_name)
      end
    end

    local c = UISlider(self.display)
    c.group_name = y_slider_name
    c:set_pos(y_slider_idx or 1)
    c.flipped = true
    c.toggleable = true
    c.palette.track = table.rcopy(c.palette.background)
    c:set_orientation(y_slider_orientation)
    c:set_size(y_slider_size)
    c.ceiling = self.y_slider_args.maximum
    c.tooltip = self.mappings.y_slider.description
    c.value = self.value[2]
    c.on_change = function(obj)
      if not self.active then return false end
      self.value[2] = obj.value
      self.suppress_value_observable = true
      self:update_renoise()
      self.suppress_value_observable = false
    end
    self:_add_component(c)
    self._y_slider = c

  end


  -- XY button grid 
  local map = self.mappings.xy_grid
  if map.group_name then
    -- determine width and height of grid
    self.grid_width = cm:count_columns(map.group_name)
    self.grid_height = cm:count_rows(map.group_name)

    self._xy_grid = table.create()

    for x=1,self.grid_width do
      self._xy_grid[x] = table.create()
      --for y=self.grid_height,1,-1 do
      for y=1,self.grid_height do
        local c = UIButton(self.display)
        c.group_name = map.group_name
        c.tooltip = map.description
        c:set(self.palette.grid_off)
        c:set_pos(x,y)
        c.on_press = function(obj)
          if not self.active then return false end
          -- flip Y index, so the top may represent the highest value
          local flipped_y = math.abs(y-self.grid_height)+1
          self:select_grid_cell(x,flipped_y)
        end
        self:_add_component(c)
        self._xy_grid[x][y] = c
      end
    end

  end

  -- attach to song at first run
  self:_attach_to_song()
  return true

end

--------------------------------------------------------------------------------

-- set the quantized value based on input from xy_grid, but add a tiny 
-- amount of noise afterwards, forcing the xypad device to send a signal

function XYPad:select_grid_cell(x,y)
  TRACE("XYPad:select_grid_cell()",x,y)

  if not self.target_device then
    return
  end

  local x_val = (x==1) and 0 or scale_value(x,1,self.grid_width,0,1)
  local y_val = (y==1) and 0 or scale_value(y,1,self.grid_height,0,1)
  
  -- record clean value 
  if self._record_mode then
    local params = self:get_xy_params()
    if params then
      self.automation:add_automation(self.track_index,params.x,x_val)
      self.automation:add_automation(self.track_index,params.y,y_val)
    end
  end

  -- add miniscule amount of noise to destination
  local noise = 0
  if (self.target_device.parameters[1].value==x_val) or
    (self.target_device.parameters[2].value==y_val)
  then
    noise = .0001
  end
  local new_x = x_val + noise
  local new_y = y_val + noise
  -- don't exceed the upper range
  if (new_x > 1) then
    new_x = x_val - noise
  end
  if (new_y > 1) then
    new_y = y_val - noise
  end

  -- scale to the min/max range
  new_x = scale_value(new_x,0,1,self.min_value,self.max_value)
  new_y = scale_value(new_y,0,1,self.min_value,self.max_value)
  self.value = {new_x,new_y}

  self:update_renoise()
  self.update_requested = true


end


--------------------------------------------------------------------------------

-- attach notifier to the device 
-- called when we use previous/next device, set the initial device
-- or are freely roaming the tracks

function XYPad:attach_to_device(track_idx,device_idx,device)
  TRACE("XYPad:attach_to_device()",track_idx,device_idx,device)

  -- clear observables, attach to track (if needed)
  RoamingDSP.attach_to_device(self,track_idx,device_idx,device)

  -- listen for changes to the X/Y parameters
  if self:device_is_valid(device) then
    local params = self:get_xy_params()
    self._parameter_observables:insert(params.x.value_observable)
    params.x.value_observable:add_notifier(
      self, 
      function()
        if not self.suppress_value_observable then
          self.value[1] = scale_value(params.x.value,0,1,self.min_value,self.max_value)
          self.update_requested = true
        end
      end 
    )
    self._parameter_observables:insert(params.y.value_observable)
    params.y.value_observable:add_notifier(
      self, 
      function()
        if not self.suppress_value_observable then
          self.value[2] = scale_value(params.y.value,0,1,self.min_value,self.max_value)
          self.update_requested = true
        end
      end 
    )
  end

end


