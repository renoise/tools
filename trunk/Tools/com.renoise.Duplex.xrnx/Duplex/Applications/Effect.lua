--[[----------------------------------------------------------------------------
-- Duplex.Effect
-- Inheritance: Application > Effect
----------------------------------------------------------------------------]]--

--[[

About:

  The Effect application will enable control of every parameter in the 
  DSP chain. The application will follow the currently selected device,  
  and display all of it's parameters using a paged navigation mechanism. 


Features

  - Access every parameter of every effect device (including plugins)
  - Flip through parameters using paged navigation
  - Select between devices using a number of fixed buttons
  - Enable grid-controller mode by assigning "parameters" to a grid


Mappings
  
  parameters  (UISlider)  parameter value, assignable to grid-controller
  page        (UISpinner) effect parameter navigator
  device      (UIToggleButton) effect device navigator


Options

  This application has no options


Changes (equal to Duplex version number)

  0.97  - Better performance, as idle loop takes care of UI updates 
        - Option to include parameters based on criteria:
          ALL/MIXER/AUTOMATED_PARAMETERS
  
  0.95  - Grid controller support (with configurations for Launchpad, etc)
        - Seperated device-navigator group size from parameter group size
        - Use standard (customizable) palette instead of hard-coded values
        - Applied feedback fix, additional check for invalid meta-device values

  0.92  - Contextual tooltip support: show name of DSP parameter

  0.91  - Fixed: check if "no device" is selected (initial state)

  0.90  - Check group sizes when building application
        - Various bug fixes

  0.81  - First release

--]]


--==============================================================================

-- default precision we're using to compare floating point values in Effect

local FLOAT_COMPARE_QUANTUM = 1000


--==============================================================================

class 'Effect' (Application)

Effect.default_options = {
    include_parameters = {
      label = "Parameters",
      description = "Select which parameter set you want to control.",
      items = {
        "All parameters (device)",
        "Automated parameters (track)",
        "Mixer parameters (track)",
      },
      value = 1,
      on_change = function(inst)
        local mode = (inst.options.include_parameters.value) 
        if (mode == inst.ALL_PARAMETERS) then
          inst._update_requested = true
        else
          inst._track_update_requested = true
        end
      end,

    },
}

function Effect:__init(display,mappings,options,config_name)
  TRACE("Effect:__init", display,mappings,options,config_name)

   -- define option constants

  self.ALL_PARAMETERS = 1
  self.AUTOMATED_PARAMETERS = 2
  self.MIXER_PARAMETERS = 3

  -- apply control-maps groups 
  self.mappings = {
    parameters = {
      description = "Parameter value",
      greedy = true,
    },
    page = {
      description = "Effect parameter navigator",
      orientation = HORIZONTAL,
    },
    device = {
      description = "Effect device navigator",
      greedy = true,
    },
--[[
    -- todo
    set_device = {
      description = "Flip through devices",
      ui_component = UI_COMPONENT_SPINNER,
    },
    toggle_active = {
      description = "Turn device on/off",
      ui_component = UI_COMPONENT_TOGGLEBUTTON,
    }
    device_preset = {
      description = "Select device preset",
      ui_component = UI_COMPONENT_SPINNER,
    }
]]
  }

  -- define default palette

  self.palette = {
  
    background = {
      color={0x00,0x00,0x00}, 
      text="",
    },
    slider_background = {
      color={0x00,0x40,0x00},
      text="·",    
    },
    slider_tip = {
      color={0xff,0xff,0xff},
      text="■",
    },
    slider_track = {
      color={0xff,0xff,0xff},
      text="■",
    }
  }


  -- the controls
  self._parameter_sliders = nil
  self._page_control = nil
  self._device_navigators = nil
  
  -- the number of controls assigned as sliders
  self._slider_group_size = nil

  -- the maximum size of a slider
  self._slider_max_size = nil

  -- true if sliders are in grid mode
  self._slider_grid_mode = nil

  -- the current parameter set 
  self._parameter_set = table.create()

  -- offset of the whole parameter mapping, controlled by the page navigator
  self._parameter_offset = 0
  
  -- list of parameters we are currently listening to
  self._parameter_observables = table.create()
  self._device_observables = table.create()
  self._mixer_observables = table.create()

  Application.__init(self,display,mappings,options,config_name)

end


--------------------------------------------------------------------------------

-- parameter value changed from Renoise

function Effect:set_parameter(control_index, value, skip_event)
  TRACE("Effect:set_parameter", control_index, value, skip_event)

  if (self.active) then
    self._parameter_sliders[control_index]:set_value(value, skip_event)
  end
end


--------------------------------------------------------------------------------

-- update: set all controls to current values from renoise
-- todo: make the device navigator follow the "device page"
--  when using MIXER_PARAMETERS or AUTOMATED_PARAMETERS

function Effect:update()  
  TRACE("Effect:update()")

  local skip_event = true

  local parameters = self._parameter_set

  local cm = self.display.device.control_map
  local track_idx = renoise.song().selected_track_index

  for control_index = 1,self._slider_group_size do
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
      
    else
      -- deactivate, reset controls which have no parameter assigned
      self:set_parameter(control_index, 0, skip_event)
    end
  end
  
  if (self._device_navigators) then

    if (self.options.include_parameters.value == self.ALL_PARAMETERS) then

      -- set the device navigator to the current fx
      local device_idx = renoise.song().selected_device_index
      for control_index = 1,#self._device_navigators do
        self._device_navigators[control_index]:set((device_idx==control_index),true)  

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
        
        self._device_navigators[control_idx]:set(is_current,skip_event)  

        -- update tooltip
        self._device_navigators[control_idx].tooltip = (device) and 
          string.format("Set focus to %s",device.name) or
          "Effect device N/A"


      end



--[[
      for control_idx = 1,#self._device_navigators do

        local device = nil
        local parameter = nil
        local device_idx = nil

        if self._parameter_set[control_idx] then
          device_idx = self._parameter_set[control_idx].device_index
          parameter = self:_get_parameter_by_index(control_idx)
        end

        if parameter then
          -- is current? 
          local is_current = (device_idx==renoise.song().selected_device_index) 
          self._device_navigators[control_idx]:set(is_current,skip_event)  
          device = renoise.song().tracks[track_idx].devices[device_idx]   
        end

        if not device then
          self._device_navigators[control_idx]:set(false,skip_event)  
        end

        -- update tooltip
        self._device_navigators[control_idx].tooltip = (device) and 
          string.format("Set focus to %s",device.name) or
          "Effect device N/A"

      end
]]
    end

    self.display:apply_tooltips(self.mappings.device.group_name)

  end

end


--------------------------------------------------------------------------------


-- build_app: create the fader/dial layout

function Effect:_build_app()
  TRACE("Effect:_build_app(")

  self._parameter_sliders = {}
  self._device_navigators = (self.mappings.device.group_name) and {} or nil

  local cm = self.display.device.control_map

  -- check if the control-map describes a grid controller
  local cm = self.display.device.control_map
  self._slider_grid_mode = cm:is_grid_group(self.mappings.parameters.group_name)

  if self._slider_grid_mode then
    local w,h = cm:get_group_dimensions(self.mappings.parameters.group_name)
    self._slider_group_size = h
    self._slider_max_size = w
  else
    self._slider_group_size = cm:get_group_size(self.mappings.parameters.group_name)
    self._slider_max_size = 1
  end

  for control_index = 1,self._slider_group_size do

    -- sliders for parameters ------------------------------

    local c = UISlider(self.display)
    c.group_name = self.mappings.parameters.group_name
    c.tooltip = self.mappings.parameters.description
    if self._slider_grid_mode then
      c:set_pos(1,control_index)
      c:set_orientation(HORIZONTAL)
      c.flipped = true
      c.toggleable = true
      c.palette.background = table.rcopy(self.palette.slider_background)
      c.palette.tip = table.rcopy(self.palette.slider_tip)
      c.palette.track = table.rcopy(self.palette.slider_track)

    else
      c:set_pos(control_index)
      c:set_size(1)
      c.toggleable = false
    end
    c.ceiling = 1

    c.on_change = function(obj) 

      if (not self.active) then 
        return false 
      end
      
      local parameter_index = self._parameter_offset + control_index
      local parameters = self._parameter_set
  
      if (parameter_index > #parameters) then
        -- parameter is outside bounds
        return false

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
          end
        end
        
        return true
      end
    end
    self:_add_component(c)
    self._parameter_sliders[control_index] = c

  end


  -- device navigator (optional) ---------------------------
  if (self.mappings.device.group_name) then

    local group_size = cm:get_group_size(self.mappings.device.group_name)
    for control_index = 1,group_size do

      local group_cols = cm:count_columns(self.mappings.device.group_name)

      local c = UIToggleButton(self.display)
      c.group_name = self.mappings.device.group_name
      c.tooltip = self.mappings.device.description
      c:set_pos(control_index)
      c.on_change = function(obj) 

        if (not self.active) then 
          return false 
        end

        local track_idx = renoise.song().selected_track_index
        local new_index = nil

        -- obtain the device index
        if (self.options.include_parameters.value == self.ALL_PARAMETERS) then
          new_index = control_index
        else
          new_index = self:_get_device_index_by_ctrl_index(control_index)
        end

        local device = renoise.song().tracks[track_idx].devices[new_index]   

        if device then

          -- select the device
          renoise.song().selected_device_index = new_index

          -- turn off previously selected device
          if (self.options.include_parameters.value == self.ALL_PARAMETERS) then
            local sel_index = renoise.song().selected_device_index
            if (sel_index ~= control_index) and
                self._device_navigators[sel_index] then
              self._device_navigators[sel_index]:set(false,true)
            end
          else
            for control_index2 = 1,#self._device_navigators do
              local prm_table = self._parameter_set[control_index2]
              if prm_table and
                  (prm_table.device_index ~= new_index) then
                self._device_navigators[control_index2]:set(false,true)
              end
            end
          end

        else
          return false      
        end


        -- make togglebuttons behave like radio buttons
        -- (refuse to toggle off when already active)
        if (not obj.active) then 
          obj:set(true,true)
          return false      
        end

        return true      

      end
      self:_add_component(c)
      self._device_navigators[control_index] = c
    end
  end



  -- parameter scrolling (optional) ---------------------------

  if (self.mappings.page.group_name) then

    local group_cols = cm:count_columns(self.mappings.page.group_name)

    local c = UISpinner(self.display)
    c.group_name = self.mappings.page.group_name
    c.tooltip = self.mappings.page.description
    c.index = 0
    c.step_size = self._slider_group_size
    c.minimum = 0
    c.maximum = math.max(0, #self._parameter_set - group_cols)
    c:set_pos(self.mappings.page.index or 1)
    c:set_orientation(self.mappings.page.orientation)
    c:set_orientation(self.mappings.page.orientation)
    c.text_orientation = HORIZONTAL
    c.on_change = function(obj) 

      if (not self.active) then 
        return false 
      end
      
      self._parameter_offset = obj.index
      local new_song = false
      self:_attach_to_parameters(new_song)
      self:update()
      return true
    end
    self:_add_component(c)
    self._page_control = c

  end


  -- the finishing touch
  self:_attach_to_song()

  Application._build_app(self)
  return true

end


--------------------------------------------------------------------------------

-- start/resume application

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

function Effect:_get_parameter_by_index(idx)
  --TRACE("Effect._get_parameter_by_index()",idx)

  if (self._parameter_set[idx]) then
    return self._parameter_set[idx].ref
  end

end

--------------------------------------------------------------------------------

-- obtain device index by specifying the control index
-- this is used when working with parameter subsets 

function Effect:_get_device_index_by_ctrl_index(idx)
  --TRACE("Effect._get_device_index_by_ctrl_index()",idx)

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


--------------------------------------------------------------------------------

function Effect:on_new_document()
  TRACE("Effect:on_new_document")
  
  self:_attach_to_song()
  
  if (self.active) then
    self:update()
  end
end


--------------------------------------------------------------------------------

-- in grid mode, when encountering a quantized parameter that
-- has a larger range than the number of buttons we lower the ceiling
-- for the slider, so only the 'settable' range is displayed
-- (called when modifying and attaching parameter) 

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

-- in non-grid mode, if the parameters is quantized and has a range of 255, 
-- we provide the 7-bit value as maximum - otherwise, we'd only be able to 
-- access every second value

function Effect:_get_quant_max(prm)

  if (not self._slider_grid_mode) and
    (prm.value_quantum == 1) and
    (prm.value_max == 255) then
    return 127
  end
  return prm.value_max
end

--------------------------------------------------------------------------------

-- convert a [0-1] value to the given parameter value-range

function Effect:_normalized_value_to_parameter_value(parameter, value)

  local value_max = self:_get_quant_max(parameter)
  local parameter_range = value_max - parameter.value_min
  return parameter.value_min + value * parameter_range
end

--------------------------------------------------------------------------------

-- convert a parameter value to a [0-1] value 

function Effect:_parameter_value_to_normalized_value(parameter, value)

  local value_max = self:_get_quant_max(parameter)
  local parameter_range = value_max - parameter.value_min
  return (value - parameter.value_min) / parameter_range

end

--------------------------------------------------------------------------------

-- perform periodic updates

function Effect:on_idle()

  if (not self.active) then 
    return 
  end

  if self._track_update_requested then
    self._track_update_requested = false
    self:_attach_to_track_devices(renoise.song().selected_track)
    self._update_requested = true
  end

  if(self._update_requested) then
    self:_attach_to_parameters()
    self._update_requested = false
    self:update()
  end

end


--------------------------------------------------------------------------------

-- returns the current parameter set that we control

function Effect:_define_parameters()
  TRACE("Effect:_define_parameters()")

  self._parameter_set = table.create()

  if (self.options.include_parameters.value == self.ALL_PARAMETERS) then

    local device = renoise.song().selected_device   
    --self._parameter_set = selected_device and selected_device.parameters or {}
    if device then
      for _,parameter in ipairs(device.parameters) do
        self._parameter_set:insert({
          device_index=renoise.song().selected_device_index,
          ref=parameter
        })

      end
    end

  else

    local track = renoise.song().selected_track
    for device_idx,device in ipairs(track.devices) do
      for _,parameter in ipairs(device.parameters) do
        if(parameter.show_in_mixer) and
            (self.options.include_parameters.value == self.MIXER_PARAMETERS) then
          self._parameter_set:insert({
            device_index=device_idx,
            ref=parameter
          })
        elseif (parameter.is_automated) and
            (self.options.include_parameters.value == self.AUTOMATED_PARAMETERS) then
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

-- adds notifiers to song
-- invoked when a new document becomes available

function Effect:_attach_to_song()
  TRACE("Effect:_attach_to_song()")
  
  -- update on parameter changes in the song
  renoise.song().selected_device_observable:add_notifier(
    function()
      
      if (self.options.include_parameters.value == self.ALL_PARAMETERS) then
        TRACE("Effect:selected_device_changed fired...")
        self._update_requested = true
      else
        -- todo: update the device selector
        self._update_requested = true
      end

    end
  )

  -- follow active track in Renoise
  -- (for AUTOMATED_PARAMETERS and MIXER_PARAMETERS)
  renoise.song().selected_track_index_observable:add_notifier(
    function()
        TRACE("Effect:self.options.include_parameters.value",self.options.include_parameters.value)
      if (self.options.include_parameters.value == self.MIXER_PARAMETERS) or
          (self.options.include_parameters.value == self.AUTOMATED_PARAMETERS) then
        TRACE("Effect:selected_track_index_observable fired...")

        local track = renoise.song().selected_track
        self._track_update_requested = true

      end

    end
  )

  --[[
  renoise.song().tracks_observable:add_notifier(
    function()
      TRACE("Effect:tracks_observable fired...")
      
      local track = renoise.song().selected_track

      self:_attach_to_track_devices(track)
      
      if (self.active) then
        self:update()
      end
    end
  )
  ]]



  -- and immediately attach to the current parameter set
  local new_song = true
  self:_attach_to_parameters(new_song)
  self:_attach_to_track_devices(renoise.song().selected_track,new_song)

end

--------------------------------------------------------------------------------

-- handle when visible or automated state has changed 
-- (for AUTOMATED_PARAMETERS and MIXER_PARAMETERS)

function Effect:_attach_to_track_devices(track,new_song)
  TRACE("Effect:_attach_to_track_devices",track,new_song)

  self._device_observables = table.create()

  -- remove notifier first 
  self:_remove_notifiers(new_song,self._device_observables)
  self:_remove_notifiers(new_song,self._mixer_observables)

  -- handle changes to devices in track
  self._device_observables:insert(track.devices_observable)
  track.devices_observable:add_notifier(
    function()
      -- todo: only perform update when in current track
      self._track_update_requested = true
    end
  )

  for idx2,device in ipairs(track.devices) do

    for idx3,parameter in ipairs(device.parameters) do
      
      self._mixer_observables:insert(parameter.show_in_mixer_observable)
      parameter.show_in_mixer_observable:add_notifier(
        function(obj)
          if (self.options.include_parameters.value == self.MIXER_PARAMETERS) then
            TRACE("Effect:show_in_mixer_observable fired...")
            -- todo: only perform update when in current track
            self._update_requested = true
          end

        end
      )

      self._mixer_observables:insert(parameter.is_automated_observable)
      parameter.is_automated_observable:add_notifier(
        function(obj)
          if (self.options.include_parameters.value == self.AUTOMATED_PARAMETERS) then
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

-- detect when a parameter set has changed
-- @param new_song - boolean, true to leave existing notifiers alone
function Effect:_attach_to_parameters(new_song)
  TRACE("Effect:_attach_to_parameters", new_song)

  if not self.active then
    return
  end

    -- if no device is selected, select the TrackVolPan device
  if (renoise.song().selected_device_index==0) then
    renoise.song().selected_device_index = 1
  end


  self:_define_parameters()

  local cm = self.display.device.control_map

  -- validate and update the sequence/parameter offset
  if (self._page_control) then
    self._page_control:set_range(nil,
      math.max(0, #self._parameter_set - self._slider_group_size))
  end
    
  self:_remove_notifiers(new_song,self._parameter_observables)
  
  -- then attach to the new ones in the order we want them
  for control_index = 1, self._slider_group_size do
    local parameter_index = self._parameter_offset + control_index
    local parameter = self:_get_parameter_by_index(parameter_index)
    local control = self._parameter_sliders[control_index]
    local outside_bounds = (control_index>#self._parameter_set)

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

            -- scale parameter value to a [0-1] range
            local normalized_value = self:_parameter_value_to_normalized_value(
              parameter, parameter.value) 
            -- ignore floating point fuzziness    
            if (not compare(normalized_value, control.value, FLOAT_COMPARE_QUANTUM) or
                normalized_value == 0.0 or normalized_value == 1.0) -- be exact at the min/max 
            then
              local skip_event = true -- only update the Duplex UI
	            self:set_parameter(control_index, normalized_value, skip_event)
            end
          end
        end 
      )
    end

  end

--[[
    -- if no device is selected, select the TrackVolPan device
  if (renoise.song().selected_device_index==0) then
    renoise.song().selected_device_index = 1
  end
]]

  self.display:apply_tooltips(self.mappings.parameters.group_name)

end

--------------------------------------------------------------------------------

-- detach all previously attached notifiers first
-- but don't even try to detach when a new song arrived. old observables
-- will no longer be alive then...
-- @param new_song - boolean, true to leave existing notifiers alone
-- @param observables - list of observables
function Effect:_remove_notifiers(new_song,observables)

  if (not new_song) then
    for _,observable in pairs(observables) do
      -- temp security hack. can also happen when removing FX
      pcall(function() observable:remove_notifier(self) end)
    end
  end
    
  observables:clear()

end

