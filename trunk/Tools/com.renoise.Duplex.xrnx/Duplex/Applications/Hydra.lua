--[[----------------------------------------------------------------------------
-- Duplex.Hydra
-- Inheritance: Application > RoamingDSP > Hydra
----------------------------------------------------------------------------]]--

--[[

  This is our sample Hydra application 

  It demonstrates the following things:

  1. Extending a class (RoamingDSP)
  2. Creating options and mappings for our application
  3. Scaling values between a controller and a device parameter
  4. Time-based interpolation of 

--]]

--==============================================================================

class 'Hydra' (RoamingDSP)

Hydra.default_options = {
  interpolation = {
    label = "Env. interpolation",
    description = "Determine the shape of automation envelopes",
    items = {
      "Point",
      "Linear",
      "Curve",
    },
    value = 1,
  }
}

Hydra.available_mappings = {
  input_slider = {
    description = "Hydra: control value",
  },
}

--  merge with superclass 
for k,v in pairs(RoamingDSP.default_options) do
  Hydra.default_options[k] = v
end
for k,v in pairs(RoamingDSP.available_mappings) do
  Hydra.available_mappings[k] = v
end

--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg), see Application to learn more

function Hydra:__init(...)

  -- the name of the device we are controlling
  -- (the exact name of the device, as it appears in the DSP chain)
  self._instance_name = "*Hydra"

  -- boolean, set to temporarily skip value notifier
  self.suppress_value_observable = false

  -- the UISlider we use for controlling the value
  self._input_slider = nil

  -- initialize the superclass
  RoamingDSP.__init(self,...)

end

--------------------------------------------------------------------------------

-- attach notifier to the device 
-- called when we use previous/next device, set the initial device
-- or are freely roaming the tracks

function Hydra:attach_to_device(track_idx,device_idx,device)

  -- clear observables, attach to track (if needed)
  RoamingDSP.attach_to_device(self,track_idx,device_idx,device)

  -- listen for changes to the mode/divisor parameters
  local param_input = self:get_device_param("Input")
  self._parameter_observables:insert(param_input.value_observable)
  param_input.value_observable:add_notifier(
    self, 
    function()
      if not self.suppress_value_observable then
        self:update_controller()
      end
    end 
  )


end

--------------------------------------------------------------------------------

-- construct the user interface

function Hydra:_build_app()
  
  -- start by adding the roaming controls:
  -- lock_button,next_device,prev_device...
  RoamingDSP._build_app(self)

  local cm = self.display.device.control_map

  local map = self.mappings.input_slider
  if map.group_name then

    -- locate the control-map "maximum" attribute,
    -- and make the slider use this range as "ceiling"
    local args = cm:get_indexed_element(map.index,map.group_name)

    local c = UISlider(self.display)
    c.group_name = map.group_name
    c:set_pos(map.index)
    c.ceiling = args.maximum
    c.tooltip = map.description
    c.on_change = function()

      -- don't respond to user input when 
      -- the application is paused
      if not self.active then 
        return false 
      end

      self:update_device()

    end
    self:_add_component(c)
    self._input_slider = c
  end

  -- attach to song at first run
  self:_attach_to_song()

  return true

end


--------------------------------------------------------------------------------

-- This method is called when the controller is changed

function Hydra:update_device()

  if self.target_device and self._input_slider then

    -- this should scale the value to between 0 and 1
    local new_val = self._input_slider.value/self._input_slider.ceiling

    -- update the device without triggering another event
    local device_param = self:get_device_param("Input")
    self.suppress_value_observable = true
    device_param.value = new_val
    self.suppress_value_observable = false

    -- add to automation (only if recording)
    local playmode = self.options.interpolation.value
    self:update_automation(self.track_index,device_param,new_val,playmode)

  end

end

--------------------------------------------------------------------------------

-- This method is called when the device is changed from Renoise

function Hydra:update_controller()

  if self.target_device and self._input_slider then

    -- scale the value from between 0 and 1 to the controller's range
    local device_param = self:get_device_param("Input")
    local new_val = device_param.value
    local new_val = new_val * self._input_slider.ceiling

    -- update the slider value without triggering an event
    local skip_event = true
    self._input_slider:set_value(new_val,skip_event)

  end

end

