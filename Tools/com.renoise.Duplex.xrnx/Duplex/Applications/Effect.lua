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
  }

  -- apply control-maps groups 
  self.mappings = {
    parameters = {
      group_name = nil,
      description = "Parameter Value - assign to a dial or fader",
      required = false,
      index = nil,
    },
    page = {
      group_name = nil,
      description = "Page navigator - assign to a fader, dial or two buttons",
      required = false,
      index = nil,
    },
  }

  -- the controls
  self.__parameter_sliders = nil
  self.__page_control = nil

  self.__width = 8

  -- todo: extract this from the options
  self.__parameter_set = self.ALL_PARAMETERS

  -- offset of the whole parameter mapping, controlled by the page navigator
  self.__parameter_offset = 0
  
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
          
      -- update component states from the parameter
      local value = (parameter.value - parameter.value_min) / 
        (parameter.value_max - parameter.value_min)
        
      self:set_parameter(control_index, value)
      
    else
      -- deactivate, reset controls which have no parameter assigned
      self:set_parameter(control_index, 0)
    end
  end
end


--------------------------------------------------------------------------------


-- build_app: create the fader/encoder layout

function Effect:build_app()
  TRACE("Effect:build_app(")

  Application.build_app(self)

  self.__parameter_sliders = {}

  -- use one parameter per control in the group
  local control_map_groups = self.display.device.control_map.groups
  local parameters_group = control_map_groups[self.mappings.parameters.group_name]

  if (parameters_group) then
    self.__width = #parameters_group
  end
  
  for control_index = 1,self.__width do

    -- sliders --------------------------------------------

    local slider = UISlider(self.display)
    slider.group_name = self.mappings.parameters.group_name
    slider.x_pos = control_index
    slider.y_pos = 1
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
        
        -- scale parameter value from [0 - 1] range to the parameter range
        local parameter_value = parameter.value_min + obj.value *
          (parameter.value_max - parameter.value_min)
            
        parameter.value = parameter_value
        return true
      end
    end
    
    self.display:add(slider)
    self.__parameter_sliders[control_index] = slider
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
    navigator.palette.foreground_dec.text = "◄"
    navigator.palette.foreground_inc.text = "►"
    
    navigator.on_change = function(obj) 
      if (not self.active) then
        return false
      end
      
      self.__parameter_offset = obj.index
      self:__attach_to_parameters()
      self:update()
      return true
    end
    
    self.__page_control = navigator
    self.display:add(self.__page_control)
  end

  -- the finishing touch
  self:__attach_to_song(renoise.song())
end


--------------------------------------------------------------------------------

-- start/resume application

function Effect:start_app()
  TRACE("Effect.start_app()")

  if not (self.created) then 
    self:build_app()
  end

  Application.start_app(self)
  self:update()
end


--------------------------------------------------------------------------------

function Effect:destroy_app()
  TRACE("Effect:destroy_app")

  if (self.__parameter_sliders) then
    for _,obj in ipairs(self.__parameter_sliders) do
      obj.remove_listeners(obj)
    end
  end
  
  Application.destroy_app(self)
end


--------------------------------------------------------------------------------

function Effect:on_new_document()
  TRACE("Effect:on_new_document")
  
  self:__attach_to_song(renoise.song())
  
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

function Effect:__attach_to_song(song)
  TRACE("Effect:__attach_to_song()")
  
  -- update on parameter changes in the song
  song.selected_device_observable:add_notifier(
    function()
      TRACE("Effect:selected_device_changed fired...")
      self:__attach_to_parameters()
      
      if (self.active) then
        self:update()
      end
    end
  )

  -- and immediately attach to the current parameter set
  self:__attach_to_parameters()
end


--------------------------------------------------------------------------------

-- add notifiers to parameters
-- invoked when parameters are added/removed/swapped

function Effect:__attach_to_parameters()
  TRACE("Effect:__attach_to_parameters()")

  local parameters = self:__current_parameters()

  -- validate and update the sequence/parameter offset
  if (self.__page_control) then
    self.__page_control:set_range(nil,
      math.max(0, #parameters - self.__width))
  end
    
  -- detach all previously added notifiers first
  for _,parameter in pairs(parameters) do
    parameter.value_observable:remove_notifier(self)
  end 
  
  -- attach to the new ones in the order we want them
  for control_index = 1,math.min(#parameters, self.__width) do
    local parameter_index = self.__parameter_offset + control_index
    local parameter = parameters[parameter_index]

    -- parameter value
    parameter.value_observable:add_notifier(
      self, 
      function()
        if (self.active) then

          -- scale parameter value to a [0 - 1] range
          local parameter_value = (parameter.value - parameter.value_min) /
            (parameter.value_max - parameter.value_min)

          local control_value = self.__parameter_sliders[control_index].value
          
          if not compare(control_value, parameter_value, 1000) then
            self:set_parameter(control_index, parameter_value)
          end
        end
      end 
    )
  end
end

