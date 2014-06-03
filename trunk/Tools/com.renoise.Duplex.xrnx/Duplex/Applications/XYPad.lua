--[[============================================================================
-- Duplex.XYPad
-- Inheritance: Application > RoamingDSP > XYPad
============================================================================]]--

--[[--
Control any XYPad device in any Renoise DSP Chain. The XYPad application can control and record movement via knobs, a MIDI keyboard's touchpad or an OSC device's accelerometer

### Features

* Flexible mappings - many supported input methods 
* Free roaming - jump between different XYPad devices in the song
* Device Lock - remember focused device between sessions
* Built-in automation recording 

### Usage

  For basic operation, you can map _either_ `xy_pad`, `xy_grid` or `x_slider`/`y_slider` to your controller. Without any of these mappings, the application will refuse to start.

  To map an OSC device, add a `Param` node to the control-map which look like this:

    <Param name="MyDevicePad" type="xypad" invert_x="false" invert_y="true" minimum="-2" maximum="2"/>

  Note: to enter the correct minimum and maximum values, it's important you know a bit about your device as the application will base it's min/max/axis values 
  directly on the information specified here. 


### Discuss

Tool discussion is located on the [Renoise forum][1]
[1]: http://forum.renoise.com/index.php?/topic/33154-new-tool-duplex-xypad/

### Changes

  0.98 
    - First release 


--]]



--==============================================================================

class 'XYPad' (RoamingDSP)

--- The XYPad application has no default options 
-- @see Duplex.RoamingDSP

XYPad.default_options = {

}

--- These are the available mappings for the application
-- @see Duplex.RoamingDSP
--
-- @field xy_pad (UIPad) OSC-only mapping that accept both X and Y axis simultaneously
-- @field xy_grid (UIButton,...) This is a multiple-button "emulation" of an XYPad on your grid controller. Minimum required resolution is 2x2
-- @field x_slider (UISlider) Map x axis to it's own fader/knob
-- @field y_slider (UISlider) Map y axis to it's own fader/knob
-- @table available_mappings
XYPad.available_mappings = {
  xy_pad = {
    description = "XYPad: XY Pad",
  },
  xy_grid = {
    description = "XYPad: XY Grid",
  },
  x_slider = {
    description = "XYPad: X-Axis",
    orientation = ORIENTATION.HORIZONTAL
  },
  y_slider = {
    description = "XYPad: Y-Axis",
    orientation = ORIENTATION.VERTICAL
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
-- @param (VarArg)
-- @see Duplex.Application

function XYPad:__init(...)
  TRACE("XYPad:__init()",...)

  -- the name of the device we are controlling
  self._instance_name = "*XY Pad"

  -- update display
  self.update_requested = true

  -- (bool) set to temporarily skip value notifier
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

--- inherited from Application
-- @see Duplex.Application.on_idle

function XYPad:on_idle()
	--TRACE("XYPad:on_idle")

  if (not self.active) then 
    return 
  end

  if self.current_device_requested then
    self.update_requested = true
  end

  if self.update_requested then
    self.update_requested = false
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
  TRACE("XYPad:get_xy_params()")

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

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

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

    local c = UIPad(self)
    c.group_name = xy_pad_name
    c.secondary_index = y_slider_idx
    c:set_pos(xy_pad_idx)
    c.tooltip = self.mappings.xy_pad.description
    c.value = self.value
    --c.floor = self.min_value
    c.ceiling = self.max_value

    c.on_change = function(obj)
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
      if (x_slider_orientation == ORIENTATION.HORIZONTAL) then
        x_slider_size = cm:count_columns(x_slider_name)
      else
        x_slider_size = cm:count_rows(x_slider_name)
      end
    end

    local c = UISlider(self)
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
      if (y_slider_orientation == ORIENTATION.HORIZONTAL) then
        y_slider_size = cm:count_columns(y_slider_name)
      else
        y_slider_size = cm:count_rows(y_slider_name)
      end
    end

    local c = UISlider(self)
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
        local c = UIButton(self)
        c.group_name = map.group_name
        c.tooltip = map.description
        c:set(self.palette.grid_off)
        c:set_pos(x,y)
        c.on_press = function(obj)
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

