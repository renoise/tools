--[[----------------------------------------------------------------------------
-- Duplex.XYPad
-- Inheritance: Application > XYPad
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

  xy_pad      (UIXYPad)         This is the OSC-only(?) mapping that accept
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


class 'XYPad' (Application)

XYPad.default_options = {
  locked = {
    --hidden = true,
    label = "Lock to device",
    description = "Disable locking if you want the controls to"
                .."\nfollow the currently selected device ",
    on_change = function(app)
      if (app.options.locked.value == app.LOCKED_DISABLED) then
        app:clear_device()
        app.current_device_requested = true
      end
      app:tag_device(app.target_device)
    end,
    items = {
      "Lock to device",
      "Roam freely"
    },
    value = 2,
  },
  record_method = {
    label = "Automation rec.",
    description = "Determine how to record automation",
    items = {
      "Disabled, do not record automation",
      "Touch, record only when touched",
      "Latch (experimental)",
    },
    value = 1,
    on_change = function(inst)
      inst.automation.latch_record = 
      (inst.options.record_method.value==inst.RECORD_LATCH) and true or false
    end
  },
  follow_pos = {
    label = "Follow pos",
    description = "Bring focus to selected XYPad device",
    items = {
      "Enabled",
      "Disabled"
    },
    value = 1,
  }

}


function XYPad:__init(process,mappings,options,cfg_name,palette)
  TRACE("XYPad:__init()",process,mappings,options,cfg_name,palette)

  self.mappings = {
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
    next_device = {
      description = "XYPad: Next device",
    },
    prev_device = {
      description = "XYPad: Previous device",
    },
    lock_button = {
      description = "XYPad: Lock/unlock device",
    },
    focus_button = {
      description = "XYPad: Bring focus locked device",
    },
  }

  self.palette = {
    grid_on         = { color = {0xFF,0xFF,0x00}, text = "▪", val=true  },  
    grid_off        = { color = {0x40,0x40,0x00}, text = "·", val=false },  
    prev_device_on  = { color = {0xFF,0xFF,0xFF}, text = "◄", val=true  },
    prev_device_off = { color = {0x00,0x00,0x00}, text = "◄", val=false },
    next_device_on  = { color = {0xFF,0xFF,0xFF}, text = "►", val=true  },
    next_device_off = { color = {0x00,0x00,0x00}, text = "►", val=false },
    focus_on        = { color = {0xFF,0xFF,0xFF}, text = "⌂", val=true  },
    focus_off       = { color = {0x00,0x00,0x00}, text = "⌂", val=false },
    lock_on         = { color = {0xFF,0xFF,0xFF}, text = "♥", val=true  },
    lock_off        = { color = {0x00,0x00,0x00}, text = "♥", val=false },
  }

  -- option constants

  self.LOCKED_ENABLED = 1
  self.LOCKED_DISABLED = 2

  self.RECORD_NONE = 1
  self.RECORD_TOUCH = 2
  self.RECORD_LATCH = 3

  self.FOLLOW_POS_ENABLED = 1
  self.FOLLOW_POS_DISABLED = 2

  -- keep reference to browser process, so we can
  -- maintain the "locked" options at all times
  self.pad_process = process

  -- use Automation class to record movements
  self.automation = Automation()

  -- set while recording automation
  self._record_mode = true

  -- update display
  self.update_controller_requested = false
  self.update_focus_requested = false
  self.current_device_requested = false

  -- observables that get cleared
  self._parameter_observables = table.create()
  self._device_observables = table.create()

  -- temporarily skip value notifier
  -- (when value is set from within the application)
  self.suppress_value_observable = false

  -- current blink-state (lock button)
  self._blink = false

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

  -- TrackDevice, the device we are currently controlling
  self.target_device = nil

  -- the target's track-index/device-index 
  self.track_index = nil
  self.device_index = nil

  -- controls
  self._xy_pad = nil  -- UIXYPad
  self._xy_grid = nil -- UIButtons...
  self._x_slider = nil  -- UISlider
  self._y_slider = nil  -- UISlider
  self._lock_button = nil   -- UIButton
  self._focus_button = nil  -- UIButton
  self._prev_button = nil   -- UIButton
  self._next_button = nil   -- UIButton

  Application.__init(self,process,mappings,options,cfg_name, palette)

  -- determine stuff after options have been applied

  self.automation.latch_record = 
  (self.options.record_method.value==self.RECORD_LATCH)

end

--------------------------------------------------------------------------------

-- check configuration, build & start the application

function XYPad:start_app()
  TRACE("XYPad:start_app()")

  if not Application.start_app(self) then
    return
  end
  self:initial_select()
  self:update_renoise()
  --self:update_controller()

end


--------------------------------------------------------------------------------

-- attempt to select the current device 
-- failing to do so will clear the target device

function XYPad:attach_to_selected_device()
  TRACE("XYPad:attach_to_selected_device()")

  if (self.options.locked.value == self.LOCKED_DISABLED) then
    local song = renoise.song()
    local device = self:get_selected_device()
    if self:device_is_xy_pad(device) then
      local track_idx = song.selected_track_index
      local device_idx = song.selected_device_index
      self:attach_to_device(track_idx,device_idx,device)
      local params = self:get_xy_params()
      local val_x = scale_value(params.x.value,0,1,self.min_value,self.max_value)
      local val_y = scale_value(params.y.value,0,1,self.min_value,self.max_value)
      self.value = {val_x,val_y}
      --print("*** attach_to_selected_device value",self.value[1],self.value[2])

    else
      self:clear_device()
    end
  end
end


--------------------------------------------------------------------------------

-- perform periodic updates

function XYPad:on_idle()
	--TRACE("XYPad:on_idle")

  if (not self.active) then 
    return 
  end

  --local skip_event = true
  local song = renoise.song()

  -- set to the current device
  if self.current_device_requested then
    self.current_device_requested = false
    self.update_controller_requested = true
    self:attach_to_selected_device()
    -- update prev/next
    local track_idx = song.selected_track_index
    local device_idx = song.selected_device_index
    self:update_prev_next(track_idx,device_idx)
    if self.target_device then
      self:update_lock_button()
    end
    self:update_focus_button()

  end

  -- when device is unassignable, blink lock button
  if self._lock_button and not self.target_device then
    local blink = (math.floor(os.clock()%2)==1)
    if blink~=self._blink then
      self._blink = blink
      if blink then
        self._lock_button:set(self.palette.lock_on)
      else
        self._lock_button:set(self.palette.lock_off)
      end
    end
  end

  if self.update_focus_requested then
    self.update_focus_requested = false
    self:update_focus_button()
  end

  --[[
  if self.update_controller_requested then
    self._reset_time = os.clock() + self._reset_delay_ms / 1000
  end
  if self._reset_time then
    if (os.clock() >= self._reset_time) then
      print("os.clock()",os.clock())
      print("_reset_time")
      self._reset_time = nil
      self.value = table.rcopy(self.reset_value)
      self:update_renoise()
      self.update_controller_requested = true
    end 
  end 
  ]]

  if self.update_controller_requested then
    self.update_controller_requested = false
    self:update_controller()
  end


  if self._record_mode then
    self.automation:update()
  end

end


--------------------------------------------------------------------------------

-- update the record mode (when editmode or record_method has changed)

function XYPad:_update_record_mode()
  TRACE("XYPad:_update_record_mode()")
  if (self.options.record_method.value ~= self.RECORD_NONE) then
    self._record_mode = renoise.song().transport.edit_mode 
  else
    self._record_mode = false
  end
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

-- return the currently focused track->device in Renoise
-- @return Device

function XYPad:get_selected_device()
  TRACE("XYPad:get_selected_device()")

  local song = renoise.song()
  local track_idx = song.selected_track_index
  local device_index = song.selected_device_index
  return song.tracks[track_idx].devices[device_index]   

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

  -- 
  local x_slider_idx,x_slider_name
  local y_slider_idx,y_slider_name

  if xy_pad_args then

    self.min_value = xy_pad_args.minimum
    self.max_value = xy_pad_args.maximum

--[[
  elseif xy_grid_args then

    -- when using a grid, min/max will use defaults
]]
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
    --c.ceiling = self.max_value

    c.on_change = function(obj)
      if not self.active then return false end
      self.value = obj.value
      self.suppress_value_observable = true
      self:update_renoise()
      if self._record_mode then
        local params = self:get_xy_params()
        if params then
          --local track_idx = renoise.song().selected_track_index
          --print("about to record",obj.value[1],obj.value[2])
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

  -- lock button
  local map = self.mappings.lock_button
  if map.group_name then
    local c = UIButton(self.display)
    c.group_name = map.group_name
    --c.palette = self.palette.foreground
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      if not self.active then return false end
      local track_idx = renoise.song().selected_track_index
      if (self.options.locked.value ~= self.LOCKED_ENABLED) then
        -- attempt to lock device
        if not self.target_device then
          return 
        end
        -- set preference and update device name 
        self:_set_option("locked",self.LOCKED_ENABLED,self.pad_process)
        self:tag_device(self.target_device)
      else
        -- unlock only when locked
        if (self.options.locked.value == self.LOCKED_ENABLED) then
          -- set preference and update device name 
          self:_set_option("locked",self.LOCKED_DISABLED,self.pad_process)
          self.current_device_requested = true
          self:tag_device(nil)
        end
      end
      self:update_lock_button()
      self:update_focus_button()

    end
    self:_add_component(c)
    self._lock_button = c
  end

  -- focus button
  local map = self.mappings.focus_button
  if map.group_name then
    local c = UIButton(self.display)
    c.group_name = map.group_name
    --c.palette.foreground = self.palette.foreground
    --c.palette.background = self.palette.background
    c:set(self.palette.focus_off)
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      if not self.active then return false end
      self:bring_focus_to_locked_device()
      self:update_focus_button()
    end
    self:_add_component(c)
    self._focus_button = c
  end

  -- previous device button
  local map = self.mappings.prev_device
  if map.group_name then
    local c = UIButton(self.display)
    c.group_name = map.group_name
    --c.palette.foreground = self.palette.foreground
    --c.palette.background = self.palette.background
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      if not self.active then return false end
      self:goto_previous_device()
    end
    self:_add_component(c)
    self._prev_button = c
  end

  -- next device button
  local map = self.mappings.next_device
  if map.group_name then
    local c = UIButton(self.display)
    c.group_name = map.group_name
    --c.palette.foreground = self.palette.foreground
    --c.palette.background = self.palette.background
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      if not self.active then return false end
      self:goto_next_device()
    end
    self:_add_component(c)
    self._next_button = c
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
  self.update_controller_requested = true


end


--------------------------------------------------------------------------------

-- bring focus to the locked device

function XYPad:bring_focus_to_locked_device()
  TRACE("XYPad:bring_focus_to_locked_device()")

  if self.track_index then
    local track = renoise.song().tracks[self.track_index]
    if track then
      for k,device in ipairs(track.devices) do
        local display_name = self:get_unique_name()
        if (device.display_name == display_name) then
          renoise.song().selected_track_index = self.track_index
          renoise.song().selected_device_index = k
          return true
        end
      end
    end
  end

  return false

end

--------------------------------------------------------------------------------

-- goto previous device
-- search from locked device (if available), otherwise use the selected device
-- @return boolean

function XYPad:goto_previous_device()
  TRACE("XYPad:goto_previous_device()")

  local song = renoise.song()
  local track_index,device_index
  if self.target_device then
    track_index = self.track_index
    device_index = self.device_index
  else
    track_index = song.selected_track_index
    device_index = song.selected_device_index
  end

  local search = self:search_previous_device(track_index,device_index)
  if search then
    self:goto_device(search.track_index,search.device_index,search.device)
    self.update_controller_requested = true
  end
  self:follow_device_pos()
  return search and true or false

end

--------------------------------------------------------------------------------

-- goto next device
-- search from locked device (if available), otherwise use the selected device
-- @return boolean

function XYPad:goto_next_device()
  TRACE("XYPad:goto_next_device()")

  local song = renoise.song()
  local track_index,device_index
  if self.target_device then
    track_index = self.track_index
    device_index = self.device_index
  else
    track_index = song.selected_track_index
    device_index = song.selected_device_index
  end
  local search = self:search_next_device(track_index,device_index)
  if search then
    self:goto_device(search.track_index,search.device_index,search.device)
    self.update_controller_requested = true
  end
  self:follow_device_pos()
  return search and true or false

end

--------------------------------------------------------------------------------

-- using a search table to attach to a device
-- this is the final step of a "previous/next device" operation,
-- or called during the initial search

function XYPad:goto_device(track_index,device_index,device,skip_tag)
  TRACE("XYPad:goto_device()",track_index,device_index,device,skip_tag)
  
  self:attach_to_device(track_index,device_index,device)
  local params = self:get_xy_params()
  local val_x = params.x.value
  local val_y = params.y.value

  val_x = scale_value(params.x.value,0,1,self.min_value,self.max_value)
  val_y = scale_value(params.y.value,0,1,self.min_value,self.max_value)

  self.value = {val_x,val_y}

  if not skip_tag and 
    (self.options.locked.value == self.LOCKED_ENABLED) 
  then
    self:tag_device(device)
  end
  self.update_focus_requested = true
  self:update_prev_next(track_index,device_index)

end

--------------------------------------------------------------------------------

-- update the lit state of the previous/next device buttons
-- @track_index,device_index (number) the active track/device
-- @prev_state_next_state (boolean) optional, will set to specific state

function XYPad:update_prev_next(track_index,device_index,prev_state,next_state)
  TRACE("XYPad:update_prev_next()",track_index,device_index,prev_state,next_state)

  -- use locked device if available
  if (self.options.locked.value == self.LOCKED_ENABLED) then
    track_index = self.track_index
    device_index = self.device_index
  end

  if self._prev_button then
    if not prev_state then
      local prev_search = self:search_previous_device(track_index,device_index)
      prev_state = (prev_search) and true or false
    end
    if prev_state then
      self._prev_button:set(self.palette.prev_device_on)
    else
      self._prev_button:set(self.palette.prev_device_off)
    end
  end
  if self._next_button then
    if not next_state then
      local next_search = self:search_next_device(track_index,device_index)
      next_state = (next_search) and true or false
    end
    if next_state then
      self._next_button:set(self.palette.next_device_on)
    else
      self._next_button:set(self.palette.next_device_off)
    end
  end

end

--------------------------------------------------------------------------------

-- select track + device, but only when follow_pos is enabled

function XYPad:follow_device_pos()
  TRACE("XYPad:follow_device_pos()")

  if (self.options.follow_pos.value == self.FOLLOW_POS_ENABLED) then
    if self.track_index then
      renoise.song().selected_track_index = self.track_index
      renoise.song().selected_device_index = self.device_index
    end
  end

end

--------------------------------------------------------------------------------

-- update the state of the lock button

function XYPad:update_lock_button()

  if self._lock_button then
    if (self.options.locked.value == self.LOCKED_ENABLED) then
      self._lock_button:set(self.palette.lock_on)
    else
      self._lock_button:set(self.palette.lock_off)
    end
  end

end

--------------------------------------------------------------------------------

-- update the state of the focus button
-- unlit when not locked, or locked device has focus

function XYPad:update_focus_button()
  TRACE("XYPad:update_focus_button()")

  if self._focus_button then
    local song = renoise.song()
    local lit = true
    if (self.options.locked.value == self.LOCKED_DISABLED) then
      lit = false
    else
      local selected = song.selected_device
      local display_name = self:get_unique_name()
      lit = selected and 
        (song.selected_device.display_name ~= display_name) 
    end
    if lit then
      self._focus_button:set(self.palette.focus_on)
    else
      self._focus_button:set(self.palette.focus_off)
    end
  
  end

end

--------------------------------------------------------------------------------

-- locate the prior device
-- @param track_index/device_index, start search from here
-- @return table or nil

function XYPad:search_previous_device(track_index,device_index)
  TRACE("XYPad:search_previous_device()",track_index,device_index)

  local matched = nil
  local locked = (self.options.locked.value == self.LOCKED_ENABLED)
  local display_name = self:get_unique_name()
  for track_idx,v in ripairs(renoise.song().tracks) do
    local include_track = true
    if track_index and (track_idx>track_index) then
      include_track = false
    end
    if include_track then
      for device_idx,device in ripairs(v.devices) do
        local include_device = true
        if device_index and (device_idx>=device_index) then
          include_device = false
        end
        if include_device then
          local search = {
            track_index=track_idx,
            device_index=device_idx,
            device=device
          }
          if locked and (device.display_name == display_name) then
            return search
          elseif self:device_is_xy_pad(device) then
            return search
          end
        end

      end

    end

    if device_index and include_track then
      device_index = nil
    end

  end

end

--------------------------------------------------------------------------------

-- locate the next device
-- @param track_index/device_index, start search from here
-- @return table or nil

function XYPad:search_next_device(track_index,device_index)
  TRACE("XYPad:search_next_device()",track_index,device_index)

  local matched = nil
  local locked = (self.options.locked.value == self.LOCKED_ENABLED)
  local display_name = self:get_unique_name()
  for track_idx,v in ipairs(renoise.song().tracks) do
    local include_track = true
    if track_index and (track_idx<track_index) then
      include_track = false
    end
    if include_track then
      for device_idx,device in ipairs(v.devices) do
        local include_device = true
        if device_index and (device_idx<=device_index) then
          include_device = false
        end
        if include_device then
          local search = {
            track_index=track_idx,
            device_index=device_idx,
            device=device
          }
          if locked and (device.display_name == display_name) then
            return search
          elseif self:device_is_xy_pad(device) then
            return search
          end
        end
      end

    end

    if device_index and include_track then
      device_index = nil
    end

  end

end

--------------------------------------------------------------------------------

-- tag device (add unique identifier), clearing existing one(s)
-- @device (TrackDevice), leave out to simply clear

function XYPad:tag_device(device)
  TRACE("XYPad:tag_device()",device)

  local display_name = self:get_unique_name()
  for _,track in ipairs(renoise.song().tracks) do
    for k,d in ipairs(track.devices) do
      if (d.display_name==display_name) then
        d.display_name = d.name
      end
    end
  end

  if device then
    device.display_name = display_name
  end

end

--------------------------------------------------------------------------------

-- called when releasing the active document

function XYPad:on_release_document()
  TRACE("XYPad:on_release_document()")
  self:clear_device()

end

--------------------------------------------------------------------------------

-- called whenever a new document becomes available

function XYPad:on_new_document()
  TRACE("XYPad:on_new_document()")

  self:_remove_notifiers(self._device_observables)
  self:_attach_to_song()
  self:initial_select()

end

--------------------------------------------------------------------------------

-- attach notifier to the song, handle changes

function XYPad:_attach_to_song()
  TRACE("XYPad:_attach_to_song()")

  -- update when a device is selected
  renoise.song().selected_device_observable:add_notifier(
    function()
      TRACE("XYPad:selected_device_observable")
      self.current_device_requested = true
    end
  )

  -- track edit_mode, and set record_mode accordingly
  renoise.song().transport.edit_mode_observable:add_notifier(
    function()
      TRACE("XYPad:edit_mode_observable fired...")
      self:_update_record_mode()
    end
  )
  self._record_mode = renoise.song().transport.edit_mode


  -- listen for changes to tracks (remove)
  --[[
  renoise.song().tracks_observable:add_notifier(
    function(notifier)
      TRACE("XYPad:tracks_observable fired...")
      if (notifier.type=="remove") then
        if (self.options.locked.value == self.LOCKED_ENABLED) and
          (self.track_index==notifier.index)
        then
          -- 'soft' unlock
          --self.options.locked.value = self.LOCKED_DISABLED
          self:clear_device()
          if self._lock_button then
            self._lock_button:set(false,true)
          end
        end
      end
    end
  )
  ]]

  -- handle devices insert/remove/swap when we switch track
  --[[
  renoise.song().selected_track_observable:add_notifier(
    function()
      TRACE("XYPad:selected_track_observable fired...")
    end 
  )
  ]]

  -- also call Automation class
  self.automation:attach_to_song()

end

--------------------------------------------------------------------------------

-- keep track of devices (insert,remove,swap...)
-- invoked by attach_to_device()

function XYPad:_attach_to_track_devices(track)
  TRACE("XYPad:_attach_to_track_devices",track)

  self:_remove_notifiers(self._device_observables)
  self._device_observables = table.create()

  self._device_observables:insert(track.devices_observable)
  track.devices_observable:add_notifier(
    function(notifier)
      TRACE("XYPad:devices_observable fired...")
      --rprint(notifier)
      --[[
      if (notifier.type == "insert") then
        -- TODO stop when index is equal to, or higher 
      end
      ]]
      if (notifier.type == "swap") and self.device_index then
        --print("*** device swapped, existing index is ",self.device_index)
        if (notifier.index1 == self.device_index) then
          self.device_index = notifier.index2
          --print("*** device swapped, new index is ",self.device_index)
        elseif (notifier.index2 == self.device_index) then
          self.device_index = notifier.index1
          --print("*** device swapped, new index is ",self.device_index)
        end
      end

      if (notifier.type == "remove") then

        local search = self:do_device_search()
        if not search then
          self:clear_device()
        else
          if (search.track_index ~= self.track_index) then
            self:clear_device()
            self:initial_select()
          end
        end
      end
      self.automation:stop_automation()

    end
  )
end

--------------------------------------------------------------------------------

-- get the unique name of the device, as specified in options

function XYPad:get_unique_name()
  TRACE("XYPad:get_unique_name()")
  
  local dev_name = self.pad_process.browser._device_name
  local cfg_name = self.pad_process.browser._configuration_name
  local app_name = self._app_name

  local unique_name = ("XYPad:%s_%s_%s"):format(dev_name,cfg_name,app_name)
  --print("unique_name",unique_name)
  return unique_name
  
end

--------------------------------------------------------------------------------

-- this search is performed on application start
-- if not in locked mode: use the currently focused track->device
-- if we are in locked mode: recognize any locked devices, but fall back
--  to the focused track->device if no locked device was found

function XYPad:initial_select()
  TRACE("XYPad:initial_select()")

  local song = renoise.song()
  local device,track_idx,device_idx
  --if (self.options.locked.value == self.LOCKED_ENABLED) then
    local search = self:do_device_search()
    if search then
      device = search.device
      track_idx = search.track_index
      device_idx = search.device_index
    else
      -- we failed to match a locked device,
      -- perform a 'soft' unlock
      self.options.locked.value = self.LOCKED_DISABLED
      self:update_lock_button()
      --[[
      if self._lock_button then
        self._lock_button:set(self.palette.lock_off)
      end
      ]]
    end
  --end
  if not device then
    device = song.selected_device
    track_idx = song.selected_track_index
    device_idx = song.selected_device_index
  end

  if self:device_is_xy_pad(device) then
    local skip_tag = true
    self:goto_device(track_idx,device_idx,device,skip_tag)
    self.update_controller_requested = true
  end
  self:update_prev_next(track_idx,device_idx)

end

--------------------------------------------------------------------------------

-- look for any XYPad device that match the provided name
-- it is called right after the target device has been removed,
-- or by initial_select()

function XYPad:do_device_search()
  TRACE("XYPad:do_device_search()")

  local song = renoise.song()
  --local track_idx = song.selected_track_index
  --local device_index = song.selected_device_index
  local display_name = self:get_unique_name()
  local device_count = 0
  for track_idx,track in ipairs(song.tracks) do
    for device_idx,device in ipairs(track.devices) do
      if self:device_is_xy_pad(device) and 
        (device.display_name == display_name) 
      then
        return {
          device=device,
          track_index=track_idx,
          device_index=device_idx
        }
      end
    end
  end

end


--------------------------------------------------------------------------------

-- test if the device is a valid target 

function XYPad:device_is_xy_pad(device)
  --TRACE("XYPad:device_is_xy_pad()",device)

  if device and (device.name == "*XY Pad") then
    return true
  else
    return false
  end
end

--------------------------------------------------------------------------------

-- attach notifier to the device 
-- called when we use previous/next device, set the initial device
-- or are freely roaming the tracks

function XYPad:attach_to_device(track_idx,device_idx,device)
  TRACE("XYPad:attach_to_device()",track_idx,device_idx,device)

  -- clear the previous device references
  self:_remove_notifiers(self._parameter_observables)

  local track_changed = (self.track_index ~= track_idx)

  self.target_device = device
  self.track_index = track_idx
  self.device_index = device_idx

  -- listen for changes to the X/Y parameters
  if self:device_is_xy_pad(device) then
    local params = self:get_xy_params()
    self._parameter_observables:insert(params.x.value_observable)
    params.x.value_observable:add_notifier(
      self, 
      function()
        if not self.suppress_value_observable then
          --print("X value_observable fired...",params.x.value)
          self.value[1] = scale_value(params.x.value,0,1,self.min_value,self.max_value)
          self.update_controller_requested = true
        end
      end 
    )
    self._parameter_observables:insert(params.y.value_observable)
    params.y.value_observable:add_notifier(
      self, 
      function()
        if not self.suppress_value_observable then
          --print("Y value_observable fired...",params.y.value)
          self.value[2] = scale_value(params.y.value,0,1,self.min_value,self.max_value)
          self.update_controller_requested = true
        end
      end 
    )
  end

  -- new track? attach_to_track_devices
  if track_changed then
    local track = renoise.song().tracks[track_idx]
    --print("*** about to attach to track",track_idx,track)
    self:_attach_to_track_devices(track)
  end

  --[[
  -- update the locked status
  if (self.options.locked.value == self.LOCKED_ENABLED) then
    if self._lock_button then
      self._lock_button:set(self.palette.lock_on)
    end
  end
  ]]
  self:update_lock_button()

end


--------------------------------------------------------------------------------

function XYPad:clear_device()
  TRACE("XYPad:clear_device()")

  self:_remove_notifiers(self._parameter_observables)
  self.automation:stop_automation()
  self.target_device = nil
  self.track_index = nil
  self.device_index = nil

end


--------------------------------------------------------------------------------

-- @param observables - list of observables
function XYPad:_remove_notifiers(observables)
  TRACE("XYPad:_remove_notifiers()",observables)

  for _,observable in pairs(observables) do
    -- temp security hack. can also happen when removing FX
    pcall(function() observable:remove_notifier(self) end)
  end
    
  observables:clear()

end
