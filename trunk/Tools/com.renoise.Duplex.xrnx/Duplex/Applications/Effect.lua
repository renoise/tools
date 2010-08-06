--[[----------------------------------------------------------------------------
-- Duplex.Effect
----------------------------------------------------------------------------]]--

--[[

  About:

  "Effect" is a generic class for controlling parameters of the selected 
  FX in Renoise.
  
  Control-map assignments:

  - "parameters" - specify this group to control the 
    selected FX parameters

  - "control" - specify this group to navigate the parameter
    group offsets (page control). relevant when more parameters 
    are available than controls in the "parameters" group exist
    
  
  TODO:

  -- apply ALL_PARAMETERS, AUTOMATED_PARAMETERS, MIXER_PARAMETERS options
  -- extend to also control other FX, not just the selected one

--]]


--==============================================================================

-- default precision we're using to compare floating point values in Effect

local FLOAT_COMPARE_QUANTUM = 1000


-- convert a [0-1] value to the given parameter value-range

local function normalized_value_to_parameter_value(parameter, value)
  local parameter_range = parameter.value_max - parameter.value_min

  return parameter.value_min + value * parameter_range
end


-- convert a parameter value to a [0-1] value 

local function parameter_value_to_normalized_value(parameter, value)
  local parameter_range = parameter.value_max - parameter.value_min

  return (value - parameter.value_min) / parameter_range
end


--==============================================================================

class 'Effect' (Application)

function Effect:__init(display, mappings, options)
  TRACE("Effect:__init", display, mappings, options)

  -- constructor 
  Application.__init(self)

  self.display = display


   -- define the options (with defaults)

  self.ALL_PARAMETERS = "Include all parameters"
  self.AUTOMATED_PARAMETERS = "Automated Parameters only"
  self.MIXER_PARAMETERS = "Mixer Parameters only"

  self.options = {
  --[[
    -- TODO
    include_parameters = {
      label = "Parameters",
      description = "Select which parameter set you want to control.",
      items = {
        self.ALL_PARAMETERS,
        self.AUTOMATED_PARAMETERS,
        self.MIXER_PARAMETERS,
      },
      default = 1,
    },
    ]]
  }

  -- apply control-maps groups 
  self.mappings = {
    parameters = {
      group_name = nil,
      description = "Parameter Value - assign to a fader, dial or grid",
      required = false,
      index = nil,
    },
    page = {
      group_name = nil,
      description = "Page navigator - assign to a fader, dial or two buttons",
      required = false,
      index = nil,
    },
    device = {
      group_name = nil,
      description = "Device navigator - assign to a fader, dial or grid",
      required = false,
      index = nil,
    }
  }

  -- the controls
  self.__parameter_sliders = nil
  self.__page_control = nil
  self.__device_navigator = nil
  
  self.__width = 8

  -- todo: extract this from the options
  self.__parameter_set = self.ALL_PARAMETERS

  -- offset of the whole parameter mapping, controlled by the page navigator
  self.__parameter_offset = 0
  
  -- list of parameters we are currently listening to
  self.__attached_observables = table.create()
  
  -- apply arguments
  self:__apply_options(options)
  self:__apply_mappings(mappings)
end


--------------------------------------------------------------------------------

-- parameter value changed from Renoise

function Effect:set_parameter(control_index, value)
  TRACE("Effect:set_parameter", control_index, value)

  if (self.active) then
    self.__parameter_sliders[control_index]:set_value(value)
  end
end


--------------------------------------------------------------------------------

-- update: set all controls to current values from renoise

function Effect:update()  
  TRACE("Effect:update()")

  local parameters = self:__current_parameters()

  for control_index = 1,self.__width do
    local parameter_index = self.__parameter_offset + control_index
    local parameter = parameters[parameter_index]
          
    -- set default values  
    if (parameter_index <= #parameters) then
          
      -- update component states from the parameter, 
      -- normalize to the controls [0-1] range
      local normalized_value = parameter_value_to_normalized_value(
        parameter, parameter.value) 
        
      self:set_parameter(control_index, normalized_value)
      
    else
      -- deactivate, reset controls which have no parameter assigned
      self:set_parameter(control_index, 0)
    end
  end
  
  if (self.__device_navigator) then
    local device_idx = renoise.song().selected_device_index
    
    if (device_idx) then
      self.__device_navigator:set_index(device_idx)
    end
  end
end


--------------------------------------------------------------------------------


-- build_app: create the fader/encoder layout

function Effect:__build_app()
  TRACE("Effect:__build_app(")

  Application.__build_app(self)

  self.__parameter_sliders = {}

  -- use one parameter per control in the group
  local control_map_groups = self.display.device.control_map.groups
  local parameters_group = control_map_groups[self.mappings.parameters.group_name]
  local row, column, columns = 1, 1, nil
  
  if (parameters_group) then
    self.__width = #parameters_group
    if (parameters_group["columns"]) then
      columns = parameters_group["columns"]
    else
      columns = self.__width
    end
  end

  if (not columns) then
    columns = self.__width
  end
  
  for control_index = 1,self.__width do

    -- sliders --------------------------------------------

    local slider = UISlider(self.display)
    slider.group_name = self.mappings.parameters.group_name
    slider.x_pos = column
    slider.y_pos = row
    slider.toggleable = false
    slider.ceiling = 1
    slider:set_size(1)

    -- slider changed from controller
    slider.on_change = function(obj) 
      local parameter_index = self.__parameter_offset + control_index
      local parameters = self:__current_parameters()    
  
      if (not self.active) then
        return false
      
      elseif (parameter_index > #parameters) then
        -- parameter is outside bounds
        return false

      else
        local parameter = parameters[parameter_index]
        
        -- scale parameter value to a [0-1] range before comparing
        local normalized_value = parameter_value_to_normalized_value(
          parameter, parameter.value)
    
        -- ignore floating point fuziness    
        if (not compare(normalized_value, obj.value, FLOAT_COMPARE_QUANTUM) or 
            obj.value == 0.0 or obj.value == 1.0) -- be exact at the min/max 
        then
          -- scale the [0-1] ranged value to the parameters value
          local parameter_value = normalized_value_to_parameter_value(
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
    
    self.display:add(slider)
    self.__parameter_sliders[control_index] = slider

    -- update row/column counters
    column = column + 1
    if (column > columns) then
      column = 1
      row = row + 1
    end
  end
  

  -- parameter scrolling (optional) ---------------------------

  if (self.mappings.page.group_name) then
    local navigator = UISpinner(self.display)
    
    navigator.group_name = self.mappings.page.group_name
    navigator.index = 0
    navigator.step_size = self.__width
    navigator.minimum = 0
    navigator.maximum = math.max(0, #self:__current_parameters() - self.__width)
    navigator.x_pos = 1 + (self.mappings.page.index or 0)
    navigator.text_orientation = HORIZONTAL
    
    navigator.on_change = function(obj) 
      if (not self.active) then
        return false
      end
      
      self.__parameter_offset = obj.index

      local new_song = false
      self:__attach_to_parameters(new_song)

      self:update()
      return true
    end
    
    self.__page_control = navigator
    self.display:add(self.__page_control)
  end


  -- device navigator (optional) ---------------------------

  if (self.mappings.device.group_name) then
    local navigator = UISlider(self.display)
    navigator.group_name = self.mappings.device.group_name
    navigator.x_pos = 1
    navigator.y_pos = 1
    navigator.flipped = true
    navigator.orientation = HORIZONTAL
    navigator.ceiling = columns
    navigator.palette.background = self.display.palette.background
    navigator.palette.tip = self.display.palette.color_1
    navigator.palette.track = self.display.palette.background
  
    navigator:set_size(columns)
    navigator.on_change = function(obj) 
  
      local track_idx = renoise.song().selected_track_index
      local device = renoise.song().tracks[track_idx].devices[obj.index]

      if (device) then
        renoise.song().selected_device_index = obj.index
      else
        if (obj.index ~= 0) then
          -- we have attempted to select a non-existing device
          return false      
        end
      end
  
    end

    self.__device_navigator = navigator
    self.display:add(navigator)
  end

  -- the finishing touch
  self:__attach_to_song()
end


--------------------------------------------------------------------------------

-- start/resume application

function Effect:start_app()
  TRACE("Effect.start_app()")

  if not (self.__created) then 
    self:__build_app()
  end

  Application.start_app(self)
  self:update()
end


--------------------------------------------------------------------------------

function Effect:destroy_app()
  TRACE("Effect:destroy_app")

  if (self.__parameter_sliders) then
    for _,obj in ipairs(self.__parameter_sliders) do
      obj:remove_listeners()
    end
  end
  
  if (self.__page_control) then
    self.__page_control:remove_listeners()
  end
  
  if (self.__device_navigator) then
    self.__device_navigator:remove_listeners()
  end

  Application.destroy_app(self)
end


--------------------------------------------------------------------------------

function Effect:on_new_document()
  TRACE("Effect:on_new_document")
  
  self:__attach_to_song()
  
  if (self.active) then
    self:update()
  end
end


--------------------------------------------------------------------------------

-- returns the current parameter set that we control

function Effect:__current_parameters()
  TRACE("Effect:__current_parameters()")

  -- TODO: could use other parameter sets and not "everything" here...
  local selected_device = renoise.song().selected_device   
  return selected_device and selected_device.parameters or {}
end

    
--------------------------------------------------------------------------------

-- adds notifiers to song
-- invoked when a new document becomes available

function Effect:__attach_to_song()
  TRACE("Effect:__attach_to_song()")
  
  -- update on parameter changes in the song
  renoise.song().selected_device_observable:add_notifier(
    function()
      TRACE("Effect:selected_device_changed fired...")
      
      local new_song = false
      self:__attach_to_parameters(new_song)
      
      if (self.active) then
        self:update()
      end
    end
  )

  -- and immediately attach to the current parameter set
  local new_song = true
  self:__attach_to_parameters(new_song)
end


--------------------------------------------------------------------------------

-- add notifiers to parameters
-- invoked when parameters are added/removed/swapped

function Effect:__attach_to_parameters(new_song)
  TRACE("Effect:__attach_to_parameters", new_song)

  local parameters = self:__current_parameters()

  -- validate and update the sequence/parameter offset
  if (self.__page_control) then
    self.__page_control:set_range(nil,
      math.max(0, #parameters - self.__width))
  end
    
  -- detach all previously attached notifiers first
  -- but don't even try to detach when a new song arrived. old observables
  -- will no longer be alive then...
  if (not new_song) then
    for _,observable in pairs(self.__attached_observables) do
      -- temp security hack. can also happen when removing FX
      pcall(function() observable:remove_notifier(self) end)
    end
  end
    
  self.__attached_observables:clear()
  
  -- then attach to the new ones in the order we want them
  for control_index = 1,math.min(#parameters, self.__width) do
    local parameter_index = self.__parameter_offset + control_index
    local parameter = parameters[parameter_index]

    self.__attached_observables:insert(parameter.value_observable)
    
    parameter.value_observable:add_notifier(
      self, 
      function()
        if (self.active) then

          -- scale parameter value to a [0-1] range
          local normalized_value = parameter_value_to_normalized_value(
            parameter, parameter.value) 
      
          local control_value = self.__parameter_sliders[control_index].value
      
          -- ignore floating point fuzziness    
          if (not compare(normalized_value, control_value, FLOAT_COMPARE_QUANTUM) or
              normalized_value == 0.0 or normalized_value == 1.0) -- be exact at the min/max 
          then
            self:set_parameter(control_index, normalized_value)
          end
        end
      end 
    )
  end
end

