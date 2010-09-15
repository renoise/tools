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
      description = "Parameter value",
      ui_component = UI_COMPONENT_SLIDER,
      greedy = true,
    },
    page = {
      description = "Effect parameter navigator",
      ui_component = UI_COMPONENT_SPINNER,
    },
    device = {
      description = "Effect device navigator",
      ui_component = UI_COMPONENT_SPINNER,
    }
  }

  -- the controls
  self.__parameter_sliders = nil
  self.__page_control = nil
  self.__device_navigators = nil
  
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

  local cm = self.display.device.control_map
  local group_size = cm:get_group_size(self.mappings.parameters.group_name)
  local track_idx = renoise.song().selected_track_index

  for control_index = 1,group_size do
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

    -- set the device navigator to the current fx

    if (self.__device_navigators) then
      local device_idx = renoise.song().selected_device_index
      self.__device_navigators[control_index]:set((device_idx==control_index),true)
        
      -- update tooltip
      local device = renoise.song().tracks[track_idx].devices[control_index]   
      self.__device_navigators[control_index].tooltip = (device) and 
        string.format("Set focus to %s",device.name) or
        "Effect device N/A"

    end

  end
  
  if (self.__device_navigators) then
    self.display:apply_tooltips(self.mappings.device.group_name)
  end

end


--------------------------------------------------------------------------------


-- build_app: create the fader/encoder layout

function Effect:__build_app()
  TRACE("Effect:__build_app(")

  Application.__build_app(self)

  self.__parameter_sliders = {}
  self.__device_navigators = (self.mappings.device.group_name) and {} or nil

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

  local cm = self.display.device.control_map
  local group_cols,group_size = nil,nil

  group_cols = cm:count_columns(self.mappings.parameters.group_name)
  group_size = cm:get_group_size(self.mappings.parameters.group_name)

  for control_index = 1,group_size do

    -- sliders for parameters ------------------------------

    local c = UISlider(self.display)
    c.group_name = self.mappings.parameters.group_name
    c.tooltip = self.mappings.parameters.description
    c:set_pos(control_index)
    c.toggleable = false
    c.ceiling = 1
    c:set_size(1)

    c.on_change = function(obj) 

      if (not self.active) then return false end
      
      local parameter_index = self.__parameter_offset + control_index
      local parameters = self:__current_parameters()    
  
      if (parameter_index > #parameters) then
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
    
    --self.display:add(c)
    self:__add_component(c)
    self.__parameter_sliders[control_index] = c

    -- device navigator (optional) ---------------------------
    if (self.mappings.device.group_name) then

      group_cols = cm:count_columns(self.mappings.device.group_name)

      local c = UIToggleButton(self.display)
      c.group_name = self.mappings.device.group_name
      c.tooltip = self.mappings.device.description
      c.flipped = true
      c.orientation = HORIZONTAL
      c.ceiling = group_cols
      c.palette.background = self.display.palette.background
      c.palette.tip = self.display.palette.color_1
      c.palette.track = self.display.palette.background
      c:set_pos(control_index)
      --c:set_size(group_cols)
      c.on_change = function(obj) 

        if (not self.active) then return false end

        local track_idx = renoise.song().selected_track_index
        local device = renoise.song().tracks[track_idx].devices[control_index]
        local device_idx = renoise.song().selected_device_index
        if (renoise.song().tracks[track_idx].devices[control_index]) then
          if(device_idx > 0) and (device_idx ~= control_index) then
              self.__device_navigators[device_idx]:set(false,true)
          end
          renoise.song().selected_device_index = control_index
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
      --self.display:add(c)
      self:__add_component(c)
      self.__device_navigators[control_index] = c
    end

  end

  -- parameter scrolling (optional) ---------------------------

  if (self.mappings.page.group_name) then

    group_size = cm:get_group_size(self.mappings.parameters.group_name)
    group_cols = cm:count_columns(self.mappings.page.group_name)

    local c = UISpinner(self.display)
    c.group_name = self.mappings.page.group_name
    c.tooltip = self.mappings.page.description
    c.index = 0
    c.step_size = group_size
    c.minimum = 0
    c.maximum = math.max(0, #self:__current_parameters() - group_cols)
    c:set_pos(self.mappings.page.index or 1)
    c.text_orientation = HORIZONTAL
    
    c.on_change = function(obj) 

      if (not self.active) then return false end
      
      self.__parameter_offset = obj.index
      local new_song = false
      self:__attach_to_parameters(new_song)

      self:update()
      return true
    end
    
    --self.display:add(self.__page_control)
    self:__add_component(c)
    self.__page_control = c

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

-- returns the current device name
--[[
function Effect:__current_device_name()
  TRACE("Effect:__current_device_name()")

  local selected_device = renoise.song().selected_device   
  return selected_device and selected_device.name or nil
end
]]
    
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
  --local device_name = self:__current_device_name()

  local cm = self.display.device.control_map
  local group_cols = cm:count_columns(self.mappings.parameters.group_name)
  local group_count = cm:get_group_size(self.mappings.parameters.group_name)

  -- validate and update the sequence/parameter offset
  if (self.__page_control) then
    self.__page_control:set_range(nil,
      --math.max(0, #parameters - group_cols))
      math.max(0, #parameters - group_count))
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
  --for control_index = 1,math.min(#parameters, group_count) do
  for control_index = 1, group_count do
    local parameter_index = self.__parameter_offset + control_index
    local parameter = parameters[parameter_index]

    -- different tooltip for unassigned controls
    local tooltip = (control_index>#parameters) and "Effect: param N/A" or 
      string.format("Effect param : %s",parameter.name)
    self.__parameter_sliders[control_index].tooltip = tooltip

    if(parameter) then
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

  self.display:apply_tooltips(self.mappings.parameters.group_name)

end

