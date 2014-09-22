--[[============================================================================
Duplex.Application.Effect
============================================================================]]--

--[[--
The Effect application enables control of DSP chain parameters.
Inheritance: @{Duplex.Application} > Duplex.Application.Effect 

### Features

* Using a paged navigation mechanism 
* Access every parameter of every effect device (including plugins)
* Flip through parameters using paged navigation
* Select between devices using a number of fixed buttons
* Enable grid-controller mode by assigning "parameters" to a grid
* Parameter subsets make it possible to control only certain values
* Supports automation recording (touch or latch mode)

### Changes

  0.98.27
    - New mapping: “device_name” (UILabel)
    - New mappings: “param_names”,”param_values” (UILabels for parameters)
    - New mappings: “param_next”,”param_next” (UIButtons, replaces UISpinner)

  0.98.19
    - Fixed: device-navigator now works after switching song/document

  0.98  
    - Support for automation recording
    - New mapping: select device via knob/slider
    - New mappings: previous/next device
    - New mappings: previous/next preset

  0.97  
    - Better performance, as UI updates now happen in idle loop 
    - Option to include parameters based on criteria 
      ALL/MIXER/AUTOMATED_PARAMETERS
  
  0.95  
    - Grid controller support (with configurations for Launchpad, etc)
    - Seperated device-navigator group size from parameter group size
    - Use standard (customizable) palette instead of hard-coded values
    - Applied feedback fix, additional check for invalid meta-device values

  0.92  
    - Contextual tooltip support: show name of DSP parameter

  0.91  
    - Fixed: check if "no device" is selected (initial state)

  0.90  
    - Check group sizes when building application
    - Various bug fixes

  0.81  
    - First release


--]]


--==============================================================================

-- default precision we're using to compare floating point values in Effect

local FLOAT_COMPARE_QUANTUM = 1000

-- option constants

local ALL_PARAMETERS = 1
local AUTOMATED_PARAMETERS = 2
local MIXER_PARAMETERS = 3
local RECORD_NONE = 1
local RECORD_TOUCH = 2
local RECORD_LATCH = 3


--==============================================================================

class 'Effect' (Application)

Effect.default_options = {
  include_parameters = {
    label = "Param. subset",
    description = "Select which parameter set you want to control.",
    items = {
      "All parameters (device)",
      "Automated parameters (track)",
      "Mixer parameters (track)",
    },
    value = 1,
    on_change = function(inst)
      local mode = (inst.options.include_parameters.value) 
      if (mode == ALL_PARAMETERS) then
        inst._update_requested = true
      else
        inst._track_update_requested = true
      end
    end,
  },
  record_method = {
    label = "Automation rec.",
    description = "Determine how to record automation",
    items = {
      "Disabled, do not record automation",
      "Touch: record only when touched",
      "Latch (experimental) ",
    },
    value = 1,
    on_change = function(inst)
      inst.automation.latch_record = (inst.options.record_method.value == RECORD_LATCH) and true or false
    end
  }
}

-- apply control-maps groups 
Effect.available_mappings = {
  parameters = {
    description = "Parameter value",
    distributable = true,
    greedy = true,
    orientation = ORIENTATION.HORIZONTAL,
    flipped = true,
    toggleable = true,
  },
  param_next = {
    description = "Parameter page",
    distributable = true,
  },
  param_prev = {
    description = "Parameter page",
    distributable = true,
  },
  device = {
    description = "Select device via buttons",
    distributable = true,
    greedy = true,
  },
  device_select = {
    description = "Select device via knob/slider",
    orientation = ORIENTATION.HORIZONTAL,
  },
  device_next = {
    description = "Select next device",
  },
  device_prev = {
    description = "Select previous device",
  },
  preset_next = {
    description = "Select next device preset",
  },
  preset_prev = {
    description = "Select previous device preset",
  },
  device_name = {
    description = "Display device name",
  },
  param_names = {
    description = "Display parameter name",
  },
  param_values = {
    description = "Display parameter value",
  },

}

-- define default palette
Effect.default_palette = {
  -- parameter sliders
  background = {        color={0x00,0x00,0x00},   text="·",   val=false },
  slider_background = { color={0x00,0x40,0x00},   text="·",   val=false },
  slider_tip = {        color={0XFF,0XFF,0XFF},   text="·",   val=true },
  slider_track = {      color={0XFF,0XFF,0XFF},   text="·",   val=true },
  -- device-buttons
  device_nav_on = {     color={0XFF,0XFF,0XFF},   text="■",   val=true },
  device_nav_off = {    color={0x00,0x00,0x00},   text="·",   val=false },
  prev_device_on = {    color = {0xFF,0xFF,0xFF}, text = "◄", val=true },
  prev_device_off = {   color = {0x00,0x00,0x00}, text = "◄", val=false },
  next_device_on = {    color = {0xFF,0xFF,0xFF}, text = "►", val=true },
  next_device_off = {   color = {0x00,0x00,0x00}, text = "►", val=false },
  -- preset buttons
  prev_preset_on = {    color = {0xFF,0xFF,0xFF}, text = "◄", val=true },
  prev_preset_off = {   color = {0x00,0x00,0x00}, text = "◄", val=false },
  next_preset_on = {    color = {0xFF,0xFF,0xFF}, text = "►", val=true },
  next_preset_off = {   color = {0x00,0x00,0x00}, text = "►", val=false },
  -- parameter pages
  prev_param_on = {     color = {0xFF,0xFF,0xFF}, text = "◄", val=true },
  prev_param_off = {    color = {0x00,0x00,0x00}, text = "◄", val=false },
  next_param_on = {     color = {0xFF,0xFF,0xFF}, text = "►", val=true },
  next_param_off = {    color = {0x00,0x00,0x00}, text = "►", val=false },

}


--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg) 
-- @see Application

function Effect:__init(...)
  TRACE("Effect:__init", ...)

  -- the controls
  self._parameter_sliders = nil
  self._device_navigators = nil
  self._device_select = nil
  self._device_next = nil
  self._device_prev = nil
  self._preset_next = nil
  self._preset_prev = nil
  self._device_name = nil
  self._param_names = nil
  self._param_next = nil
  self._param_prev = nil

  --- (int) the number of controls assigned as sliders
  self._slider_group_size = nil

  --- (int or nil) the maximum size of a slider
  self._slider_max_size = nil

  --- (bool) true if sliders are in grid mode
  self._slider_grid_mode = false

  --- (table) indexed table, each entry contains:
  --    device_index (int)
  --    ref (renoise.DeviceParameter)
  self._parameter_set = table.create()

  --- (int) how many devices are included in our parameter set?
  self._num_devices = 1

  --- (int) offset of the whole parameter mapping, controlled by the page navigator
  self._parameter_offset = 0
  
  --- list of parameters we are currently listening to
  self._parameter_observables = table.create()
  self._device_observables = table.create()
  self._preset_observables = table.create()
  self._mixer_observables = table.create()

  --- (@{Duplex.Automation}) used for recording movements
  self.automation = Automation()

  --- (bool) set while recording automation
  self._record_mode = false

  Application.__init(self,...)

  -- do stuff after options have been set

  self.automation.latch_record = (self.options.record_method.value == RECORD_LATCH)


end

--------------------------------------------------------------------------------

--- parameter value changed from Renoise
-- @param control_index (int) 
-- @param value (number) _mostly_ between 0 and 1
-- @param skip_event (bool) do not trigger event

function Effect:set_parameter(control_index, value, skip_event)
  TRACE("Effect:set_parameter", control_index, value, skip_event)

  if not self.active then
    return
  end

  --- value needs to be positive (this is not true with the multitap-
  -- delay, in which the "panic" button will output a negative value)
  if (value<0) then
    value = 0
  end

  self._parameter_sliders[control_index]:set_value(value, skip_event)

end


--------------------------------------------------------------------------------

--- update: set all controls to current values from renoise

function Effect:update()  
  TRACE("Effect:update()")

  local skip_event = true

  local parameters = self._parameter_set

  local cm = self.display.device.control_map
  local track_idx = renoise.song().selected_track_index
  local device_idx = renoise.song().selected_device_index

  -- update prev/next device buttons
  self:_update_prev_next_device_buttons(device_idx)

  -- update prev/next device buttons
  self:_update_prev_next_preset_buttons(device_idx)

  -- update device-select control
  local new_index = self:_get_ctrl_index_by_device(renoise.song().selected_device_index)
  if new_index then
    if self._device_select then
      self._device_select:set_value(new_index/self._num_devices,skip_event)
    end
  end

  -- update device label
  if self._device_name and renoise.song().selected_device then
    self._device_name:set_text(renoise.song().selected_device.name)
  end

  for control_index = 1,self._slider_group_size do

    local param_value = nil
    local parameter_index = self._parameter_offset + control_index
    local parameter = self:_get_parameter_by_index(parameter_index)
    -- set default values  
    if (parameter_index <= #parameters) then
          
      -- update component states from the parameter, 
      -- hackily check for valid ranges, in order to suppress updates of
      -- temporarily wrong values that we get from Renoise (-1 for the meta 
      -- device effect/device choosers)    
      if (parameter.value >= parameter.value_min and 
          parameter.value <= parameter.value_max) 
      then
        -- normalize to the controls [0-1] range
        local normalized_value = self:_parameter_value_to_normalized_value(
          parameter, parameter.value) 
        self:set_parameter(control_index, normalized_value, skip_event)
      else
        self:set_parameter(control_index, 0, skip_event)
      end

      param_value = parameter.value_string

    else
      -- deactivate, reset controls which have no parameter assigned
      self:set_parameter(control_index, 0, skip_event)
      param_value = ""

    end

    --print("*** param_value",param_value)
    
    if self._param_values and self._param_values[control_index] then
      self._param_values[control_index]:set_text(param_value)
    end

  end
  
  -- update button-based device selectors
  if (self._device_navigators) then

    if (self.options.include_parameters.value == ALL_PARAMETERS) then
      -- set the device navigator to the current fx
      for control_index = 1,#self._device_navigators do
        if (device_idx==control_index) then
          self._device_navigators[control_index]:set(self.palette.device_nav_on)
        else
          self._device_navigators[control_index]:set(self.palette.device_nav_off)
        end

        -- update tooltip
        local device = renoise.song().tracks[track_idx].devices[control_index]   
        self._device_navigators[control_index].tooltip = (device) and 
          string.format("Set focus to %s",device.name) or
          "Effect device N/A"
      end
    else
      -- parameter subsets require a different approach
      local count = 0
      for control_idx = 1,#self._device_navigators do
        local is_current = false
        local device = nil
        -- go through the parameter set, each entry with
        -- a higher device_index will be added 
        for _,prm in ipairs(self._parameter_set) do
          if (prm.device_index>count) then
            is_current = (prm.device_index==renoise.song().selected_device_index) 
            device = renoise.song().tracks[track_idx].devices[prm.device_index]   
            count = prm.device_index
            break
          end
        end
        if is_current then
          self._device_navigators[control_idx]:set(self.palette.device_nav_on)
        else
          self._device_navigators[control_idx]:set(self.palette.device_nav_off)
        end
        -- update tooltip
        self._device_navigators[control_idx].tooltip = (device) and 
          string.format("Set focus to %s",device.name) or
          "Effect device N/A"
      end
    end

    self.display:apply_tooltips(self.mappings.device.group_name)

  end

end


--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function Effect:_build_app()
  TRACE("Effect:_build_app(")

  self._parameter_sliders = {}
  self._device_navigators = (self.mappings.device.group_name) and {} or nil

  local cm = self.display.device.control_map

  -- TODO check for required mappings
  if not (self.mappings.parameters.group_name) then
    local msg = "Effect cannot initialize, the required mapping 'parameters' is missing"
    renoise.app():show_warning(msg)
    return false
  end

  -- check if the control-map describe
  -- (1) a distributed group or (2) a grid controller
  local map = self.mappings.parameters
  --print("*** map",map.group_name)
  --print("*** map.group_name",map.group_name)
  local distributed_group = string.find(map.group_name,"*")
  local params = nil
  self._slider_grid_mode = cm:is_grid_group(map.group_name)

  if self._slider_grid_mode then
    local w,h = cm:get_group_dimensions(map.group_name)
    if (map.orientation == ORIENTATION.HORIZONTAL) then
      self._slider_group_size = h
      self._slider_max_size = w
    else
      self._slider_group_size = w
      self._slider_max_size = h
    end
  else
    self._slider_max_size = 1
    if distributed_group then
      params = cm:get_params(map.group_name,map.index)
      self._slider_group_size = #params
    else
      self._slider_group_size = cm:get_group_size(map.group_name)
    end
  end

  for control_index = 1,self._slider_group_size do

    -- sliders for parameters --

    local c = UISlider(self)
    c.tooltip = map.description
    if self._slider_grid_mode then
      c.group_name = map.group_name
      if (map.orientation == ORIENTATION.HORIZONTAL) then
        c:set_pos(1,control_index)
      else
        c:set_pos(control_index,1)
      end
      c:set_orientation(map.orientation)
      if (map.orientation == ORIENTATION.HORIZONTAL) then
        c:set_pos(1,control_index)
      else
        c:set_pos(control_index,1)
      end
      c.flipped = map.flipped
      c.toggleable = map.toggleable
      c.palette.background = table.rcopy(self.palette.slider_background)
      c.palette.tip = table.rcopy(self.palette.slider_tip)
      c.palette.track = table.rcopy(self.palette.slider_track)
    elseif distributed_group then
      c.group_name = params[control_index].group_name
      c:set_pos(map.index)
      c:set_size(1)
      c.toggleable = false
    else
      c.group_name = map.group_name
      c:set_pos(control_index)
      c:set_size(1)
      c.toggleable = false
    end
    c.ceiling = 1

    c.on_change = function(obj) 

      local parameter_index = self._parameter_offset + control_index
      local parameters = self._parameter_set
  
      if (parameter_index > #parameters) then
        -- parameter is outside bounds
        return 

      else
        local parameter = self:_get_parameter_by_index(parameter_index)

        self:_modify_ceiling(obj,parameter)
        
        -- scale parameter value to a [0-1] range before comparing
        local normalized_value = self:_parameter_value_to_normalized_value(
          parameter, parameter.value)
        -- ignore floating point fuziness    
        if (not compare(normalized_value, obj.value, FLOAT_COMPARE_QUANTUM) or 
            obj.value == 0.0 or obj.value == 1.0) -- be exact at the min/max 
        then
          -- scale the [0-1] ranged value to the parameters value
          local parameter_value = self:_normalized_value_to_parameter_value(
            parameter, obj.value)
          
          -- hackily check for valid ranges, in order to suppress updates of
          -- temporarily wrong values that we get from Renoise (-1 for the meta 
          -- device effect/device choosers)    
          if (parameter_value >= parameter.value_min and 
              parameter_value <= parameter.value_max) 
          then
            parameter.value = parameter_value

            if self._record_mode then
              -- todo: proper detection of track
              local track_idx = renoise.song().selected_track_index
              self.automation:add_automation(track_idx,parameter,obj.value)
            end

            if self._param_values and self._param_values[control_index] then
              self._param_values[control_index]:set_text(parameter.value_string)
            end

          end
        end

      end
    end
    self._parameter_sliders[control_index] = c

  end


  -- device navigator (optional)

  local map = self.mappings.device
  if (map.group_name) then

    local distributed_group = string.find(map.group_name,"*")
    local params = nil
    local group_size = nil
    
    if distributed_group then
      params = cm:get_params(map.group_name,map.index)
      group_size = #params
    else
      group_size = cm:get_group_size(map.group_name)
    end

    for control_index = 1,group_size do

      local group_cols = cm:count_columns(map.group_name)
      local c = UIButton(self)
      if distributed_group then
        c.group_name = params[control_index].group_name
        c:set_pos(map.index)
      else
        c.group_name = map.group_name
        c:set_pos(control_index)
      end
      c.tooltip = map.description
      c.on_press = function() 

        local song = renoise.song()
        local track_idx = song.selected_track_index
        local new_index = self:_get_device_index_by_ctrl(control_index)
        local device = song.tracks[track_idx].devices[new_index]   

        if device then

          -- select the device
          --song.selected_device_index = new_index
          self:_set_selected_device_index(new_index)

          -- turn off previously selected device
          if (self.options.include_parameters.value == ALL_PARAMETERS) then
            local sel_index = song.selected_device_index
            if (sel_index ~= control_index) and
                self._device_navigators[sel_index] then
              self._device_navigators[sel_index]:set(self.palette.device_nav_off)

            end
          else
            for control_index2 = 1,#self._device_navigators do
              local prm_table = self._parameter_set[control_index2]
              if prm_table and
                  (prm_table.device_index ~= new_index) then
                self._device_navigators[control_index2]:set(self.palette.device_nav_off)
              end
            end
          end
        end

      end
      self._device_navigators[control_index] = c
    end
  end

  -- device_select (optional) --
  -- select devices via knob/slider 

  local map = self.mappings.device_select
  if (map.group_name) then

    local c = UISlider(self)
    c.group_name = self.mappings.device_select.group_name
    c.tooltip = map.description
    c:set_pos(map.index or 1)
    c.palette.track = self.palette.background
    c.toggleable = false
    c.flipped = true
    c.value = 0
    c:set_orientation(map.orientation)
    c.on_change = function(obj) 

      local song = renoise.song()
      local track_idx = song.selected_track_index
      local new_index = self:_get_device_index_by_ctrl(math.ceil(obj.value*self._num_devices))
      self:_set_selected_device_index(new_index)

    end

    self._device_select = c

  end


  -- next parameter page

  local map = self.mappings.param_next
  if (map.group_name) then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function()
      local max_offset = self._slider_group_size * 
        math.floor(#self._parameter_set/self._slider_group_size)
      self._parameter_offset = math.min(max_offset,
        self._parameter_offset + self._slider_group_size)
      self:_attach_to_parameters(false)
      self:update()
    end
    self._param_next = c
  end


  -- previous parameter page

  local map = self.mappings.param_prev
  if (map.group_name) then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function()
      self._parameter_offset = math.max(0,
        self._parameter_offset - self._slider_group_size)
      self:_attach_to_parameters(false)
      self:update()
    end
    self._param_prev = c
  end


  -- next device (optional) --

  if (self.mappings.device_next.group_name) then

    local c = UIButton(self)
    c.group_name = self.mappings.device_next.group_name
    c.tooltip = self.mappings.device_next.description
    c:set_pos(self.mappings.device_next.index)
    c.on_press = function()

      local device_idx = renoise.song().selected_device_index
      local new_index = self:_get_next_device_index(device_idx)
      self:_set_selected_device_index(new_index)

    end
    self._device_next = c

  end

  -- previous device (optional) --

  if (self.mappings.device_prev.group_name) then

    local c = UIButton(self)
    c.group_name = self.mappings.device_prev.group_name
    c.tooltip = self.mappings.device_prev.description
    c:set_pos(self.mappings.device_prev.index)
    c.on_press = function()

      local device_idx = renoise.song().selected_device_index
      local new_index = self:_get_previous_device_index(device_idx)
      self:_set_selected_device_index(new_index)

    end
    self._device_prev = c

  end


  -- next device preset (optional) --

  if (self.mappings.preset_next.group_name) then

    local c = UIButton(self)
    c.group_name = self.mappings.preset_next.group_name
    c.tooltip = self.mappings.preset_next.description
    c:set_pos(self.mappings.preset_next.index)
    c.on_press = function()

      local device = self:_get_selected_device()
      device.active_preset = math.min(#device.presets,device.active_preset+1)

    end
    self._preset_next = c

  end

  -- previous device preset (optional) --

  if (self.mappings.preset_prev.group_name) then

    local c = UIButton(self)
    c.group_name = self.mappings.preset_prev.group_name
    c.tooltip = self.mappings.preset_prev.description
    c:set_pos(self.mappings.preset_prev.index)
    c.on_press = function()

      local device = self:_get_selected_device()
      device.active_preset = math.max(1,device.active_preset-1)

    end
    self._preset_prev = c

  end

  local map = self.mappings.device_name
  if (map) then
    local c = UILabel(self)
    c.group_name = map.group_name
    --c.tooltip = map.description
    c:set_pos(map.index)
    self._device_name = c

  end

  local map = self.mappings.param_names
  if (map.group_name) then
    self._param_names = {}
    local params = cm:get_params(map.group_name,map.index)
    for control_index = 1,#params do
      local c = UILabel(self)
      --c.group_name = map.group_name
      c.group_name = params[control_index].xarg.group_name
      --c.tooltip = map.description
      c:set_pos(map.index)
      self._param_names[control_index] = c
    end
  end

  local map = self.mappings.param_values
  if (map.group_name) then
    self._param_values = {}
    local params = cm:get_params(map.group_name,map.index)
    for control_index = 1,#params do
      local c = UILabel(self)
      --c.group_name = map.group_name
      c.group_name = params[control_index].xarg.group_name
      --c.tooltip = map.description
      c:set_pos(map.index)
      self._param_values[control_index] = c
    end
  end

  -- the finishing touches --
  self:_attach_to_song()
  Application._build_app(self)
  return true

end

--------------------------------------------------------------------------------

--- set device index, will only succeed when device exist
-- @param idx (int)

function Effect:_set_selected_device_index(idx)
  TRACE("Effect:_set_selected_device_index()",idx)

  local song = renoise.song()
  local track_idx = song.selected_track_index
  local device = song.tracks[song.selected_track_index].devices[idx]   
  if device then
    song.selected_device_index = idx
    self._parameter_offset = 0

    -- update the label
    if self._device_name then
      self._device_name:set_text(device.name)
    end
  end

end

--------------------------------------------------------------------------------

--- return the currently selected device (can be nil)
-- @return renoise.AudioDevice

function Effect:_get_selected_device()

  local song = renoise.song()
  local track_idx = song.selected_track_index
  local device_index = song.selected_device_index
  return song.tracks[track_idx].devices[device_index]   

end

--------------------------------------------------------------------------------

--- update display for prev/next device-navigation buttons
-- @param device_idx (int)

function Effect:_update_prev_next_device_buttons(device_idx)
  TRACE("Effect:_update_prev_next_device_buttons()",device_idx)

  local song = renoise.song()
  local track_idx = song.selected_track_index

  local skip_event = true
  if self._device_prev then
    local prev_idx = self:_get_previous_device_index(device_idx)
    local previous_device = song.tracks[track_idx].devices[prev_idx]
    if previous_device then
      self._device_prev:set(self.palette.prev_device_on)
    else
      self._device_prev:set(self.palette.prev_device_off)
    end
  end
  if self._device_next then
    local next_idx = self:_get_next_device_index(device_idx)
    local next_device = song.tracks[track_idx].devices[next_idx]
    if next_device then
      self._device_next:set(self.palette.next_device_on)
    else
      self._device_next:set(self.palette.next_device_off)
    end
  end

end

--------------------------------------------------------------------------------

--- update display for prev/next device-preset buttons
-- @param device_idx (int)

function Effect:_update_prev_next_preset_buttons(device_idx)
  TRACE("Effect:_update_prev_next_preset_buttons()",device_idx)

  local song = renoise.song()
  local track_idx = song.selected_track_index
  local device = song.tracks[track_idx].devices[device_idx]

  if not device then
    -- unexpected, no device present...
    return
  end

  local preset_idx = device.active_preset
  local skip_event = true
  if self._preset_prev then
    if device.presets[preset_idx-1] then
      self._preset_prev:set(self.palette.prev_preset_on)
    else
      self._preset_prev:set(self.palette.prev_preset_off)
    end
  end
  if self._preset_next then
    if device.presets[preset_idx+1] then
      self._preset_next:set(self.palette.next_preset_on)
    else
      self._preset_next:set(self.palette.next_preset_off)
    end
  end

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function Effect:start_app()
  TRACE("Effect.start_app()")

  if not Application.start_app(self) then
    return
  end

  local new_song = false
  self:_attach_to_parameters(new_song)

  self:update()

end

--------------------------------------------------------------------------------

--- get specific effect parameter from current parameter-set
-- @param idx (int)
-- @return renoise.DeviceParameter

function Effect:_get_parameter_by_index(idx)
  --TRACE("Effect._get_parameter_by_index()",idx)

  if (self._parameter_set[idx]) then
    return self._parameter_set[idx].ref
  end

end

--------------------------------------------------------------------------------

--- obtain next device index (supports parameter subsets)
-- @param idx (int)
-- @return int

function Effect:_get_next_device_index(idx)
  --TRACE("Effect._get_next_device_index()",idx)

  if (self.options.include_parameters.value == ALL_PARAMETERS) then
    return idx+1
  else
    for _,prm in ipairs(self._parameter_set) do
      if (idx<prm.device_index) then
        return prm.device_index
      end
    end
  end

end


--------------------------------------------------------------------------------

--- obtain previous device index (supports parameter subsets)
-- @param idx (int)
-- @return int

function Effect:_get_previous_device_index(idx)
  TRACE("Effect._get_previous_device_index()",idx)

  if (self.options.include_parameters.value == ALL_PARAMETERS) then
    return idx-1
  else
    for _,prm in ripairs(self._parameter_set) do
      if (idx>prm.device_index) then
        return prm.device_index
      end
    end
  end

end



--------------------------------------------------------------------------------

--- obtain actual device index by specifying the control index
-- (useful when dealing with parameter subsets)
-- @param idx (int)
-- @return int

function Effect:_get_device_index_by_ctrl(idx)
  --TRACE("Effect._get_device_index_by_ctrl()",idx)

  if (self.options.include_parameters.value == ALL_PARAMETERS) then
    return idx
  else
    local count,matched = 0,0
    for _,prm in ipairs(self._parameter_set) do
      if (prm.device_index>matched) then
        matched = prm.device_index
        count = count+1
        if (count==idx) then
          return prm.device_index
        end
      end
    end
  end

end


--------------------------------------------------------------------------------

--- obtain control index by specifying the actual device index
-- (useful when dealing with parameter subsets)
-- @param idx (int)
-- @return int

function Effect:_get_ctrl_index_by_device(idx)
  --TRACE("Effect._get_ctrl_index_by_device()",idx)

  if (self.options.include_parameters.value == ALL_PARAMETERS) then
    return idx
  else
    local count,matched = 0,0
    for _,prm in ipairs(self._parameter_set) do
      if (prm.device_index>matched) then
        matched = prm.device_index
        count = count+1
        if (prm.device_index==idx) then
          return count
        end
      end
    end
  end

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_new_document

function Effect:on_new_document()
  TRACE("Effect:on_new_document")
  
  self:_attach_to_song()
  
  if (self.active) then
    self:update()
  end

end


--------------------------------------------------------------------------------

--- in grid mode, when encountering a quantized parameter that
-- has a larger range than the number of buttons we lower the ceiling
-- for the slider, so only the 'settable' range is displayed
-- (called when modifying and attaching parameter) 
-- @param obj (@{Duplex.UISlider})
-- @param prm (renoise.DeviceParameter)

function Effect:_modify_ceiling(obj,prm)
  if self._slider_grid_mode and 
    (prm.value_quantum == 1) and 
    (prm.value_max>self._slider_max_size) then
    obj.ceiling = (1/prm.value_max)*self._slider_max_size
  else
    obj.ceiling = 1
  end
end

--------------------------------------------------------------------------------

--- in non-grid mode, if the parameters is quantized and has a range of 255, 
-- we provide the 7-bit value as maximum - otherwise, we'd only be able to 
-- access every second value
-- @param prm (renoise.DeviceParameter)

function Effect:_get_quant_max(prm)

  if (not self._slider_grid_mode) and
    (prm.value_quantum == 1) and
    (prm.value_max == 255) then
    return 127
  end
  return prm.value_max
end

--------------------------------------------------------------------------------

--- convert a [0-1] value to the given parameter value-range
-- @param parameter (renoise.DeviceParameter)
-- @param value (number)

function Effect:_normalized_value_to_parameter_value(parameter, value)

  local value_max = self:_get_quant_max(parameter)
  local parameter_range = value_max - parameter.value_min
  return parameter.value_min + value * parameter_range
end

--------------------------------------------------------------------------------

--- convert a parameter value to a [0-1] value 
-- @param parameter (renoise.DeviceParameter)
-- @param value (number)

function Effect:_parameter_value_to_normalized_value(parameter, value)

  local value_max = self:_get_quant_max(parameter)
  local parameter_range = value_max - parameter.value_min
  return (value - parameter.value_min) / parameter_range

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_idle

function Effect:on_idle()

  if (not self.active) then 
    return 
  end

  if self._track_update_requested then
    self._track_update_requested = false
    self._parameter_offset = 0
    self:_attach_to_track_devices(renoise.song().selected_track)
    self._update_requested = true
  end

  if self._update_requested then
    self:_attach_to_parameters()
    self._update_requested = false
    self:update()
  end

  if self._record_mode then
    self.automation:update()
  end

end


--------------------------------------------------------------------------------

--- update the current parameter set 
-- (updates Effect._num_devices)

function Effect:_define_parameters()
  TRACE("Effect:_define_parameters()")

  self._parameter_set = table.create()

  if (self.options.include_parameters.value == ALL_PARAMETERS) then
    local device = renoise.song().selected_device   
    if device then
      for _,parameter in ipairs(device.parameters) do
        self._parameter_set:insert({
          device_index=renoise.song().selected_device_index,
          ref=parameter
        })
      end
    end
    local track_idx = renoise.song().selected_track_index
    self._num_devices = #renoise.song().tracks[track_idx].devices
  else
    local track = renoise.song().selected_track
    for device_idx,device in ipairs(track.devices) do
      for _,parameter in ipairs(device.parameters) do
        if(parameter.show_in_mixer) and
            (self.options.include_parameters.value == MIXER_PARAMETERS) then
          self._parameter_set:insert({
            device_index=device_idx,
            ref=parameter
          })
        elseif (parameter.is_automated) and
            (self.options.include_parameters.value == AUTOMATED_PARAMETERS) then
          self._parameter_set:insert({
            device_index=device_idx,
            ref=parameter
          })
        end
      end
    end
  end

end

--------------------------------------------------------------------------------

--- update the number of devices in the current parameter set 
-- (updates Effect._num_devices)

function Effect:_get_num_devices()
  TRACE("Effect:_get_num_devices()")

  if (self.options.include_parameters.value == ALL_PARAMETERS) then
    local track_idx = renoise.song().selected_track_index
    self._num_devices = #renoise.song().tracks[track_idx].devices
  else
    local devices = {}
    local device_count = 0
    local track = renoise.song().selected_track
    for device_idx,device in ipairs(track.devices) do
      for _,parameter in ipairs(device.parameters) do
        local matched = false
        if(parameter.show_in_mixer) and
            (self.options.include_parameters.value == MIXER_PARAMETERS) then
          matched = true
        elseif (parameter.is_automated) and
            (self.options.include_parameters.value == AUTOMATED_PARAMETERS) then
          matched = true
        end
        if matched and not devices[device_idx] then
          devices[device_idx] = true -- "something"
          device_count = device_count +1           
        end
      end
    end

    self._num_devices = device_count

  end

end

--------------------------------------------------------------------------------

--- update display of the parameter navigation buttons

function Effect:update_param_page()
  TRACE("Effect:update_param_page()")

  if self._param_next then
    if ((self._parameter_offset + self._slider_group_size) 
      < #self._parameter_set)
    then
      self._param_next:set(self.palette.next_param_on)
    else
      self._param_next:set(self.palette.next_param_off)
    end
  end
  if self._param_prev then
    if (self._parameter_offset > 0) then
      self._param_prev:set(self.palette.prev_param_on)
    else
      self._param_prev:set(self.palette.prev_param_off)
    end
  end

end

--------------------------------------------------------------------------------

--- update display of the record mode 

function Effect:_update_record_mode()
  TRACE("Effect:_update_record_mode()")
  if (self.options.record_method.value ~= RECORD_NONE) then
    self._record_mode = renoise.song().transport.edit_mode 
  else
    self._record_mode = false
  end
end

--------------------------------------------------------------------------------

--- adds notifiers to song
-- invoked when a new document becomes available

function Effect:_attach_to_song()
  TRACE("Effect:_attach_to_song()")

  
  -- update on parameter changes in the song
  renoise.song().selected_device_observable:add_notifier(
    function()
      TRACE("Effect:selected_device_observable fired...")
      -- always update when display all parameters 
      if (self.options.include_parameters.value == ALL_PARAMETERS) then
        self._update_requested = true
      end
      -- update the device selector
      if self._device_select then
        self._update_requested = true
      end

    end
  )

  -- follow active track in Renoise
  -- (for AUTOMATED_PARAMETERS and MIXER_PARAMETERS)
  renoise.song().selected_track_index_observable:add_notifier(
    function()
      TRACE("Effect:selected_track_index_observable fired...")
      TRACE("Effect:self.options.include_parameters.value",self.options.include_parameters.value)
      if (self.options.include_parameters.value == MIXER_PARAMETERS) or
          (self.options.include_parameters.value == AUTOMATED_PARAMETERS) then
        self._track_update_requested = true
      end
      self:_get_num_devices()
    end
  )

  -- track edit_mode, and set record_mode accordingly
  renoise.song().transport.edit_mode_observable:add_notifier(
    function()
      TRACE("Effect:edit_mode_observable fired...")
        self:_update_record_mode()
    end
  )
  self._record_mode = renoise.song().transport.edit_mode

  -- immediately attach to the current parameter set
  local new_song = true
  self:_attach_to_parameters(new_song)
  self:_attach_to_track_devices(renoise.song().selected_track,new_song)

  -- also call Automation class
  self.automation:attach_to_song(new_song)

end

--------------------------------------------------------------------------------

--- attach notifier methods to devices & parameters...
-- @param track (renoise.Track)
-- @param new_song (bool)

function Effect:_attach_to_track_devices(track,new_song)
  TRACE("Effect:_attach_to_track_devices",track,new_song)


  -- remove notifier first 
  self:_remove_notifiers(new_song,self._device_observables)
  self:_remove_notifiers(new_song,self._mixer_observables)
  self:_remove_notifiers(new_song,self._preset_observables)

  self._device_observables = table.create()

  -- handle changes to devices in track
  -- todo: only perform update when in current track
  self._device_observables:insert(track.devices_observable)
  track.devices_observable:add_notifier(
    function()
      TRACE("Effect:devices_observable fired...")
      self._track_update_requested = true

      -- tracks may have been inserted or removed
      self:_get_num_devices()

    end
  )

  for idx2,device in ipairs(track.devices) do

    -- listen for preset changes 
    self._preset_observables:insert(device.active_preset_observable)
    device.active_preset_observable:add_notifier(
        function()
            TRACE("Effect:active_preset_observable fired...")
            -- update prev/next device buttons
            --self:_update_prev_next_preset_buttons(device_idx)
            self._update_requested = true
        end
      )

    for idx3,parameter in ipairs(device.parameters) do
      
      -- handle when visible or automated state has changed 
      -- (for AUTOMATED_PARAMETERS and MIXER_PARAMETERS)

      self._mixer_observables:insert(parameter.show_in_mixer_observable)
      parameter.show_in_mixer_observable:add_notifier(
        function()
          if (self.options.include_parameters.value == MIXER_PARAMETERS) then
            TRACE("Effect:show_in_mixer_observable fired...")
            -- todo: only perform update when in current track
            self._update_requested = true
          end

        end
      )

      self._mixer_observables:insert(parameter.is_automated_observable)
      parameter.is_automated_observable:add_notifier(
        function()
          if (self.options.include_parameters.value == AUTOMATED_PARAMETERS) then
            TRACE("Effect:is_automated_observable fired...")
            -- todo: only perform update when in current track
            self._update_requested = true
          end

        end
      )

    end
  end

end

--------------------------------------------------------------------------------

--- detect when a parameter set has changed
-- @param new_song (bool) true to leave existing notifiers alone

function Effect:_attach_to_parameters(new_song)
  TRACE("Effect:_attach_to_parameters", new_song)

  if not self.active then
    return
  end

    -- if no device is selected, select the TrackVolPan device
  if (renoise.song().selected_device_index==0) then
    --renoise.song().selected_device_index = 1
    self:_set_selected_device_index(1)
  end


  self:_define_parameters()
  self:_get_num_devices()

  local cm = self.display.device.control_map

  -- validate and update the sequence/parameter offset
  self:update_param_page()

  self:_remove_notifiers(new_song,self._parameter_observables)
  
  -- then attach to the new ones in the order we want them
  for control_index = 1, self._slider_group_size do
    local parameter_index = self._parameter_offset + control_index
    local parameter = self:_get_parameter_by_index(parameter_index)
    local control = self._parameter_sliders[control_index]
    local outside_bounds = (parameter_index>#self._parameter_set)

    --print("*** control_index, parameter_index,#self._parameter_set",control_index,parameter_index,#self._parameter_set)

    -- different tooltip for unassigned controls
    local tooltip = outside_bounds and "Effect: param N/A" or 
      string.format("Effect param : %s",parameter.name)
    control.tooltip = tooltip

    -- assign background color
    if self._slider_grid_mode then
      if (outside_bounds or not parameter) then
        control:set_palette({background=self.palette.background})
      else
        control:set_palette({background=self.palette.slider_background})
      end
    end

    if(parameter) then
      -- if value is quantized, and we are dealing with a grid 
      -- controller, resize the slider to fit the quantized values
      if self._slider_grid_mode then
        if (parameter.value_quantum==1) then
          control:set_size(math.min(parameter.value_max,self._slider_max_size))
        else
          control:set_size(self._slider_max_size)
        end
      end

      self:_modify_ceiling(control,parameter)

      self._parameter_observables:insert(parameter.value_observable)
      parameter.value_observable:add_notifier(
        self, 
        function()
          if (self.active) then

            -- TODO skip value-tracking when we are recording automation

            -- scale parameter value to a [0-1] range
            local normalized_value = self:_parameter_value_to_normalized_value(
              parameter, parameter.value) 
            -- ignore floating point fuzziness    
            if (not compare(normalized_value, control.value, FLOAT_COMPARE_QUANTUM) or
                normalized_value == 0.0 or normalized_value == 1.0) -- be exact at the min/max 
            then
              local skip_event = true -- only update the Duplex UI
	            self:set_parameter(control_index, normalized_value, skip_event)

              if self._param_values and self._param_values[control_index] then
                self._param_values[control_index]:set_text(parameter.value_string)
              end

            end
          end
        end 
      )
    end
    
    if self._param_names and self._param_names[control_index] then
      local param_name = parameter and parameter.name or "-"
      self._param_names[control_index]:set_text(param_name)
    end
    --if self._param_values and self._param_values[control_index] then
    --  local param_value = parameter and parameter.value_string or ""
    --  self._param_values[control_index]:set_text(param_value)
    --end
  end

  self.display:apply_tooltips(self.mappings.parameters.group_name)

end

--------------------------------------------------------------------------------

--- detach all previously attached notifiers first
-- but don't even try to detach when a new song arrived. old observables
-- will no longer be alive then...
-- @param new_song (bool), true to leave existing notifiers alone
-- @param observables (table), list of observables

function Effect:_remove_notifiers(new_song,observables)

  if (not new_song) then
    for _,observable in pairs(observables) do
      -- temp security hack. can also happen when removing FX
      pcall(function() observable:remove_notifier(self) end)
    end
  end
    
  observables:clear()

end

