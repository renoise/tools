--[[============================================================================
-- Duplex.Application.XYPad 
============================================================================]]--

--[[--
Control any XYPad device in any Renoise DSP Chain. 
Inheritance: @{Duplex.Application} > @{Duplex.RoamingDSP} > Duplex.Application.XYPad 

### Features
* Built-in automation recording 
* Supports knobs, a MIDI keyboard's touchpad or an OSC device's accelerometer
* Free roaming - jump between different XYPad devices in the song
* Device Lock - remember focused device between sessions

### Usage

  For basic operation, you can map _either_ `xy_pad` or `xy_grid` to your controller. Without any of these mappings, the application will refuse to start.

  To map an OSC device, add a `Param` node to the control-map which look like this:

    <Param name="MyDevicePad" type="xypad"  minimum="0" maximum="127"/>

  To map a MIDI device, add a `Param` node to the control-map which look like this:

    <Param name="XYPad_X" type="xypad" size="4" skip_echo="true">
      <SubParam value="CC#56" orientation="vertical" minimum="0" maximum="127" />
      <SubParam value="CC#57" orientation="horizontal" minimum="0" maximum="127" />
    </Param>

  Note: to enter the correct minimum and maximum values, it's important you know a bit about your device as the application will base it's min/max/axis values 
  directly on the information specified here. 


### Discuss

Tool discussion is located on the [Renoise forum][1]
[1]: http://forum.renoise.com/index.php?/topic/33154-new-tool-duplex-xypad/

### Changes

  0.99.12
    - Supports <SubParam> nodes (proper support for MIDI devices)
    - Broadcasting of MIDI values

  0.98.19
    - Simplified setup: use unique, automatically-generated names to identify 
      “managed” XYPads (no more need for manually specified id’s)

  0.98.15
    - Fixed: No longer looses focus when navigating to a new track

  0.98 
    - First release 


--]]



--==============================================================================

-- constants

local BROADCAST_X_DISABLED = 1
local BROADCAST_X_ENABLED = 2

local BROADCAST_Y_DISABLED = 1
local BROADCAST_Y_ENABLED = 2



class 'XYPad' (RoamingDSP)

--- The XYPad application has no default options 
-- @see Duplex.RoamingDSP

XYPad.default_options = {
  broadcast_x = {
    label = "Broadcast X",
    description = "Broadcast changes to X axis as MIDI-CC messages",
    items = {
      "Ignore",
    },
    value = 1,
  },
  broadcast_y = {
    label = "Broadcast Y",
    description = "Broadcast changes to Y axis as MIDI-CC messages",
    items = {
      "Ignore",
    },
    value = 1,
  },
}
-- populate some options dynamically
for i = 0,127 do
  local str_val = ("Route to CC#%i"):format(i)
  XYPad.default_options.broadcast_x.items[i+2] = str_val
  XYPad.default_options.broadcast_y.items[i+2] = str_val
end

XYPad.available_mappings = {
  xy_pad = {
    description = "XYPad: XY Pad",
  },
  xy_grid = {
    description = "XYPad: XY Grid",
  },
  x_slider = {
    description = "XYPad: Slider X axis",
  },
  y_slider = {
    description = "XYPad: Slider Y axis",
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

  --- the name of the device we are controlling
  self._instance_name = "*XY Pad"

  --- update display
  self.update_requested = true

  --- (bool) set to temporarily skip value notifier
  self.suppress_value_observable = false

  --- current value
  self.value = {nil,nil}

  --- minimum/maximum value
  self.min_value = 0
  self.max_value = 127

  --- the detected grid width/height
  self.grid_width = nil
  self.grid_height = nil

  --- controls
  -- Note: RoamingDSP has some controls too
  self._controls = {}


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

--- apply the value to the targeted DSP device

function XYPad:update_renoise()
  TRACE("XYPad:update_renoise()")

  if self.target_device then

    local val_x = self.value[1]
    local val_y = self.value[2]

    if (self.min_value ~= 0) or 
      (self.max_value ~= 1) 
    then
      val_x = scale_value(val_x,self.min_value,self.max_value,0,1)
      val_y = scale_value(val_y,self.min_value,self.max_value,0,1)
    end

    self.target_device.parameters[1].value = val_x
    self.target_device.parameters[2].value = val_y

  end

end

--------------------------------------------------------------------------------

--- update display state of the various controls

function XYPad:update_controller()
  TRACE("XYPad:update_controller()")

  local skip_event = true

  if self._controls.xy_pad then
    self._controls.xy_pad:set_value(self.value[1],self.value[2],skip_event)
    --print("set UIPad to ",self.value[1],self.value[2])
  end

  if self._controls.x_slider then
    self._controls.x_slider:set_value(self.value[1],skip_event)
    --print("set UIPad to ",self.value[1],self.value[2])
  end

  if self._controls.y_slider then
    self._controls.y_slider:set_value(self.value[2],skip_event)
    --print("set UIPad to ",self.value[1],self.value[2])
  end

  if self._controls.xy_grid then

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
          self._controls.xy_grid[x][flipped_y]:set(self.palette.grid_on)
        else
          self._controls.xy_grid[x][flipped_y]:set(self.palette.grid_off)
        end
      end
    end

  end

end


--------------------------------------------------------------------------------

--- return the X/Y axis parameter of the target device
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

  -- default value is between min and max
  local center_val = self.min_value + ((self.max_value-self.min_value)/2)
  self.value = {center_val,center_val}
  --print("*** initial value",self.value[1],self.value[2])


  -- XY pad
  local map = self.mappings.xy_pad
  if map.group_name then

    local c = UIPad(self,map)
    c.value = self.value
    c.floor = self.min_value
    c.ceiling = self.max_value

    c.on_change = function(obj)

      self.value = obj.value

      self:do_broadcast_x()
      self:do_broadcast_y()

      self:update_renoise()

      self.suppress_value_observable = true
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
    self._controls.xy_pad = c

  end


  -- XY button grid 
  local map = self.mappings.xy_grid
  if map.group_name then
    -- determine width and height of grid
    self.grid_width = cm:count_columns(map.group_name)
    self.grid_height = cm:count_rows(map.group_name)

    self._controls.xy_grid = {}

    for x=1,self.grid_width do
      self._controls.xy_grid[x] = table.create()
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
        self._controls.xy_grid[x][y] = c
      end
    end

  end

  -- Slider X
  local map = self.mappings.x_slider
  if map.group_name then
    local c = UISlider(self,map)
    c.floor = self.min_value
    c.ceiling = self.max_value
    c.on_change = function(obj)
      --print("Slider X",obj.value)
      self.value[1] = obj.value
      self:do_broadcast_x()
    end
    self._controls.x_slider = c
  end


  -- Slider Y
  local map = self.mappings.y_slider
  if map.group_name then
    local c = UISlider(self,map)
    c.floor = self.min_value
    c.ceiling = self.max_value
    c.on_change = function(obj)
      --print("Slider Y",obj.value)
      self.value[2] = obj.value
      self:do_broadcast_y()
    end
    self._controls.y_slider = c
  end


  -- attach to song at first run
  self:_attach_to_song()
  return true

end

--------------------------------------------------------------------------------

--- set the quantized value based on input from xy_grid, but add a tiny 
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

  self:do_broadcast_x()
  self:do_broadcast_y()

  self:update_renoise()
  self.update_requested = true


end


--------------------------------------------------------------------------------

--- attach notifier to the device 
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
          --print("params.x.value_observable - self.value[1]",self.value[1])
          self.update_requested = true
          self:do_broadcast_x()
        end
      end 
    )
    self._parameter_observables:insert(params.y.value_observable)
    params.y.value_observable:add_notifier(
      self, 
      function()
        if not self.suppress_value_observable then
          self.value[2] = scale_value(params.y.value,0,1,self.min_value,self.max_value)
          --print("params.x.value_observable - self.value[2]",self.value[2])
          self.update_requested = true
          self:do_broadcast_y()
        end
      end 
    )
  end

end


--------------------------------------------------------------------------------

function XYPad:do_broadcast_x()

  if (self.options.broadcast_x.value >= BROADCAST_X_ENABLED) then
    local cc_num = self.options.broadcast_x.value-2
    local msg = {176,cc_num,math.floor(self.value[1])}
    self:send_midi(msg)
  end

end

--------------------------------------------------------------------------------

function XYPad:do_broadcast_y()

  if (self.options.broadcast_y.value >= BROADCAST_Y_ENABLED) then
    local cc_num = self.options.broadcast_y.value-2
    local msg = {176,cc_num,math.floor(self.value[2])}
    self:send_midi(msg)
  end

end


--------------------------------------------------------------------------------

--- send MIDI message using the internal OSC server
-- @param msg (table) MIDI message with three bytes

function XYPad:send_midi(msg)
  TRACE("XYPad:send_midi(msg)",msg)

  local osc_client = self._process.browser._osc_client
  if not osc_client:trigger_midi(msg) then
    LOG("Cannot send MIDI, the internal OSC server was not started")
  end

end

