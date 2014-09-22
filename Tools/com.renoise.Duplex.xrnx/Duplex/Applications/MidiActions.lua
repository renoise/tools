--[[============================================================================
-- Duplex.Application.MidiActions
============================================================================]]--

--[[--
MidiActions will expose most of the standard Renoise mappings to Duplex. 
Inheritance: @{Duplex.Application} > Duplex.Application.MidiActions 

MidiActions will expose standard Renoise mappings as fully bi-directional mappings, with customizable scaling (exponential, logarithmic, linear) and range. 

By parsing the GlobalMidiActions file, it literally provides access to hundreds of features inside Renoise, such as BPM, LPB, and even UI view presets. You will have to map each feature manually, but only once - once mapped, the target will remain accessible. 

See also: @{Duplex.Applications.MidiActions.Bindings}
--]]

--==============================================================================

--- Before we launch the application, import GlobalMidiActions
-- (prefer the user-specified version, then the default)

local actions_loaded = false

if (os.platform() == "WINDOWS") then

  -- Windows: load user-specified or custom file

  local default_location = nil
  local user_provided = "./../../GlobalMidiActions.lua"
  local iterator = string.gmatch(package.path,";([^;]+)")

  for str in iterator do
    if (string.sub(str,-34)=="\\Resources\\Scripts\\Libraries\\?.lua") then
      default_location = string.sub(str,0,49)   
    end
  end

  if (io.exists(user_provided)) then
    local old_package_path = package.path
    package.path = package.path .. ";./../../?.lua"
    require "GlobalMidiActions"
    package.path = old_package_path
    actions_loaded = true
  elseif (io.exists(default_location .."GlobalMidiActions.lua")) then
    local old_package_path = package.path
    package.path = package.path .. ";" .. default_location .. "?.lua"
    require "GlobalMidiActions"
    package.path = old_package_path
    actions_loaded = true
  end

else

  -- Linux, OSX: look for locations by parsing "package.path" 

  local default_location = nil
  local user_provided = nil
  local iterator = string.gmatch(package.path,";([^;]+)")

  for str in iterator do
    if (string.sub(str,-24)=="/Scripts/Libraries/?.lua") then
      -- "resources" for unix/osc, "/usr/" for linux
      if string.find(str,"Resources") or
        string.find(str,"/usr/")
      then
        default_location = str    
      else
        user_provided = str
      end
    end
  end

  if default_location or user_provided then

    local make_path = function(str_path)
      return str_path:gsub("/Libraries","")
    end

    local literal_path = function(str_path)
      return str_path:gsub("?","GlobalMidiActions")
    end

    if default_location then
      default_location = make_path(default_location)
    end
    if user_provided then
      user_provided = make_path(user_provided)
    end

    local path_addendum = nil
    if user_provided and io.exists(literal_path(user_provided)) then
      path_addendum = user_provided
    elseif default_location and io.exists(literal_path(default_location)) then
      path_addendum = default_location
    end
    
    if path_addendum then
      local old_package_path = package.path
      package.path = package.path .. ";" .. path_addendum
      require "GlobalMidiActions"
      package.path = old_package_path
      actions_loaded = true  
    end

  end


end

--==============================================================================

-- constants

local SCALE_LOG_STRONG = 1
local SCALE_LOG = 2
local SCALE_LINEAR = 3
local SCALE_EXP = 4
local SCALE_EXP_STRONG = 5

--==============================================================================

class 'MidiActions' (Application)

MidiActions.default_options = {
  action = {
    label = "Action",
    description = "List of supported MIDI actions (GlobalMidiActions.lua)",
    on_change = function(app)
      app:_establish_routing()
    end,
    items = {
      "None", 
    },
    value = 1,
  },
  min_scaling = {
    label = "From value",
    description = "Determine the minimum value to output",
    on_change = function(app)
      --print("min_scaling.on_change")
      if not app._revert_requested then
        app:_validate_range()
      end
    end,
    items = {"0"},
    value = 1,
  },
  max_scaling = {
    label = "To value",
    description = "Determine the maximum value to output",
    on_change = function(app)
      --print("max_scaling.on_change")
      if not app._revert_requested then
        app:_validate_range()
      end
    end,
    items = {"0"},
    value = 2,
  },
  scaling = {
    label = "Value scaling",
    description = "Determine the output scaling",
    --on_change = function(app)
    --end,
    items = {
      "Log+",
      "Log",
      "Linear",
      "Exp",
      "Exp+"
    },
    value = 3,
  },
}

-- Populate min/max options dynamically

for i = 0,1000 do
  local str_val = string.format("%d",i)
  MidiActions.default_options.min_scaling.items[i+1] = str_val
  MidiActions.default_options.max_scaling.items[i+1] = str_val
end


-- Retrieve mappings from GlobalMidiActions.lua
-- we filter out the mappings that cause the list to grow
-- to an unmanageble size (> 34000 items!)

if actions_loaded then

  local retrieve_midi_mappings = function()
    local entire_list = available_actions()
    local result_list = {}
    for k,v in ipairs(entire_list) do
      local skip = false
      if (v:sub(-8) == "[Toggle]") or
        (v:sub(1,19) == "Seq. Muting:Seq. XX") or
        (v:sub(1,37)  == "Seq. Triggering:Schedule:Sequence XX:") or
        (v:sub(1,36)  == "Seq. Triggering:Trigger:Sequence XX:")
      then
        skip = true
      end
      if not skip then
        result_list[#result_list+1] = v
      end
    end
    return result_list
  end

  MidiActions.midi_mappings = retrieve_midi_mappings()

  for k,v in ipairs(MidiActions.midi_mappings) do
    --local str_name = string.format("%.50s",v)
    local str_name = string.format("%s",v)
    MidiActions.default_options.action.items[k+1] = str_name
  end

end



MidiActions.available_mappings = {
  -- flipped: when acting as slider, determine which end is high/low
  -- orientation: when acting as grid-mode slider, determine orientation
  control = {
    description = "MidiActions: designated control",
    flipped = true,
    orientation = ORIENTATION.HORIZONTAL,
  }
}

MidiActions.default_palette = {
  active   = { color = {0xFF,0xFF,0xFF}, text = "■", val=true },
  inactive = { color = {0x00,0x00,0x00}, text = "·", val=false },
}


-- include the file with extra bindings info 
-- (such as which observable values to look for, etc.)

local old_package_path = package.path
package.path = renoise.tool().bundle_path .. "Duplex/Applications/MidiActions/?.lua"
require "Bindings"
package.path = old_package_path


--==============================================================================

--- Constructor method
-- @param (VarArg)
-- @see Duplex.Application

function MidiActions:__init(...)
  TRACE("MidiActions:__init()")

  --- List of UIComponents
  self._controls = {}

  --- (int), between 1 - #_midi_mappings, or nil if no action
  self._active_map_index = nil

  --- (bool), interpreted from the MIDI action 
  self._is_switch = nil

  --- (bool), interpreted from the MIDI action 
  self._is_trigger = nil

  --- (bool), control the visual state of a button
  self._is_toggle = nil

  --- (table), contains extra information about mapping
  -- (see MidiActions.assist_table)
  self._assist = {}

  --- (number/bool/nil), represents the current value 
  -- (literal value, "64" for 64 BPM, "1.2" for 1.2 db, etc.)
  self._value = nil

  --- (bool), set when updating a parameter which is being observed
  self._skip_notifier = nil

  --- (bool), set when options should be reset
  self._revert_requested = false

  --- (number), last "good" user-specified value
  self._user_min = nil
  self._user_max = nil

  Application.__init(self,...)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function MidiActions:start_app()
  TRACE("MidiActions:start_app()")

  if not actions_loaded then
    -- show warning in console + status bar
    local msg = "Duplex MidiActions: could not locate the required file"
              .."'GlobalMidiActions.lua' (this file should be located"
              .."'in the Renoise program, or user folder)"
    renoise.app():show_status(msg)
    LOG(msg)
    return
  end

  if not Application.start_app(self) then
    return
  end

  -- use custom min/max values if available
  local user_min = self.options.min_scaling.value
  local user_max = self.options.max_scaling.value
  local default_min = MidiActions.default_options.min_scaling.value
  local default_max = MidiActions.default_options.max_scaling.value
  if (user_min ~= default_min) then
    self._user_min = user_min-1
  end
  if (user_max ~= default_max) then
    self._user_max = user_max-1
  end
  --print("*** start_app - self._user_min,self._user_max",self._user_min,self._user_max)


  self:_establish_routing(true)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.stop_app

function MidiActions:stop_app()
  TRACE("MidiActions:stop_app()")

  self:_remove_notifier()
  self:_clear_routing()

  Application.stop_app(self)

end

--------------------------------------------------------------------------------

--- Reset all properties that deal with the current mapping

function MidiActions:_clear_routing()
  TRACE("MidiActions:_clear_routing()")

  self._assist = {}
  self._is_switch = nil
  self._is_trigger = nil
  self._is_toggle = nil
  self._value = nil
  self._user_min = nil
  self._user_max = nil
  self._revert_requested = false
  self._skip_notifier = nil
  self._active_map_index = nil

  -- reset text, tooltip
  self.palette.active.text = MidiActions.default_palette.active.text
  self.palette.inactive.text = MidiActions.default_palette.inactive.text
  if self._controls.slider then
    self._controls.slider.tooltip = "MidiActions (unassigned)"
  elseif self._controls.button then
    self._controls.button.tooltip = "MidiActions (unassigned)"
    self._controls.button:set(self.palette.inactive)
  end

end

--------------------------------------------------------------------------------

--- Detach an existing notifier, if it exists

function MidiActions:_remove_notifier()
  TRACE("MidiActions:_remove_notifier()")

  local observable = self:_get_observable()
  if observable then
    observable:remove_notifier(self)
    --print("MidiActions:_establish_routing - observable was removed...")
  end

end

--------------------------------------------------------------------------------

--- Bi-directional update (controller/Renoise)
-- @param skip_transmit (bool) 

function MidiActions:_update_control(skip_transmit)
  TRACE("MidiActions:_update_control(skip_transmit)",skip_transmit)

  if not self.active then
    return
  end

  if not self._active_map_index then
    return
  end

  local min_val,max_val = self:_get_min_max(self._assist)

  local interpret_as_trigger = self._is_trigger and 
    not self._is_toggle and 
    not self._is_switch

  -- transmit only when resulting value is different
  local old_value = self._value

  if self._controls.button then

    local obj = self._controls.button
    local val = nil
    local is_active = nil
    if not interpret_as_trigger then
      self._value = self:_get_value()
      if (self._value~=nil) then
        if (type(self._value)=="boolean") then
          -- toggle state if pressed
          if not skip_transmit then
            self._value = not self._value
          end
          is_active = self._value
        elseif (type(self._value)=="number") then
          if self._assist.param then
            is_active = (self._value == max_val)
          else
            is_active = (self._value == self._user_max)
          end
          -- toggle state if pressed
          if not skip_transmit then
            if self._assist.param then
              self._value = (is_active) and min_val or max_val
            else
              self._value = (is_active) and self._user_min or self._user_max
              -- special case: if min and max is the same value, 
              -- always specify the control as being active
              if (self._user_min == self._user_max) then
                is_active = false
              end
            end
            is_active = not is_active
         end
        end

      else
        -- this mapping has no value 
        -- instead, use the visual state
        self._value = obj.palette.foreground.val and max_val or min_val
        if not skip_transmit then
          self._value = (self._value == min_val) and max_val or min_val
        end
        is_active = (self._value == max_val)
      end
      if is_active then
        obj:set(self.palette.active)
      else
        obj:set(self.palette.inactive)
      end
    else -- is trigger
      obj:flash(0.1,self.palette.active,self.palette.inactive)
    end

  elseif self._controls.slider then

    local obj = self._controls.slider

    if skip_transmit then

      -- event was triggered by Renoise, or the application:
      -- attempt to obtain the current value and update control
      if self:_has_value() then
        local value = self:_get_value()
        self._value = value
        if (value~=nil) then
          if self._assist.param then
            value = scale_value(value,min_val,max_val,0,1)
          elseif (type(value)=="number") then
            value = clamp_value(value,self._user_min,self._user_max)
            value = scale_value(value,self._user_min,self._user_max,0,1)
          elseif (type(value)=="boolean") then
            value = value and 1 or 0
          end
          -- apply inverted parameter scaling
          local method = SCALE_LINEAR
          if (self.options.scaling.value == SCALE_LOG_STRONG) then
            method = SCALE_EXP_STRONG
          elseif (self.options.scaling.value == SCALE_LOG) then
            method = SCALE_EXP
          elseif (self.options.scaling.value == SCALE_EXP) then
            method = SCALE_LOG
          elseif (self.options.scaling.value == SCALE_EXP_STRONG) then
            method = SCALE_LOG_STRONG
          end
          value = self:_scale_value(value,method)

          obj:set_value(value,true)

        end
      end

    else

      -- user-generated event (moved slider, pressed button...)
      if self._assist.is_boolean then
        self._value = (obj.value >= 0.5) and true or false
      else
        -- apply the scaling set in options
        local tmp_value = self:_scale_value(obj.value)

        -- scale from control to user/parameter range
        if self._assist.param then
          self._value = scale_value(tmp_value,0,1,min_val,max_val)
        else
          self._value = scale_value(tmp_value,0,1,self._user_min,self._user_max)
        end
        if self._assist.is_integer then
          self._value = round_value(self._value)
        end 

      end
    end
  end

  local value_has_changed = (self._value ~= old_value)

  if not skip_transmit and (interpret_as_trigger or value_has_changed) then
    self:_transmit()
  end

end

--------------------------------------------------------------------------------

--- Scale value log/exponentially
-- @return bool

function MidiActions:_scale_value(val,method)
  TRACE("MidiActions:_scale_value(val,method)",val,method)

  local method = method or self.options.scaling.value
  local scaled_val = val
  local strong_factor = 50
  local normal_factor = 10

  if (method == SCALE_LOG_STRONG) then
    scaled_val = scale_value(val,0,1,1,strong_factor)
    scaled_val = log_scale(strong_factor,scaled_val)
    scaled_val = scale_value(scaled_val,0,strong_factor,0,1)
  elseif (method == SCALE_LOG) then
    scaled_val = scale_value(val,0,1,1,normal_factor)
    scaled_val = log_scale(normal_factor,scaled_val)
    scaled_val = scale_value(scaled_val,0,normal_factor,0,1)
  elseif (method == SCALE_EXP) then
    scaled_val = scale_value(val,0,1,1,normal_factor)
    scaled_val = inv_log_scale(normal_factor,scaled_val)
    scaled_val = scale_value(scaled_val,0,normal_factor,0,1)
  elseif (method == SCALE_EXP_STRONG) then
    scaled_val = scale_value(val,0,1,1,strong_factor)
    scaled_val = inv_log_scale(strong_factor,scaled_val)
    scaled_val = scale_value(scaled_val,0,strong_factor,0,1)
  end

  return scaled_val

end

--------------------------------------------------------------------------------

--- Determine if we are able to retrieve value for the current assignment
-- @return bool

function MidiActions:_has_value()
  --TRACE("MidiActions:_has_value()")

  if self._assist.value_func then
    return true
  elseif self._assist.param then
    return true
  end
  return false

end

--------------------------------------------------------------------------------

--- Determine ability to retrieve an Observable for the current assignment
-- @return bool

function MidiActions:_has_observable()
  --TRACE("MidiActions:_has_observable()")

  if self._assist.observable then
    return true
  end
  return false

end

--------------------------------------------------------------------------------

--- Retrieve value for the current assignment
-- @return bool, number or nil

function MidiActions:_get_value()
  --TRACE("MidiActions:_get_value()")

  if self._assist.value_func then
    return self._assist:value_func()
  elseif self._assist.param then
    local prm = self._assist.param()
    return prm and prm.value or nil
  end
  return nil

end

--------------------------------------------------------------------------------

--- Retrieve Observable for the current assignment
-- @return bool, number or nil

function MidiActions:_get_observable()
  TRACE("MidiActions:_get_observable()")

  if self._assist.observable then
    return self._assist:observable()
  end
  return nil

end

--------------------------------------------------------------------------------

--- Transmit message
-- when routed to MIDI, we generate an emulated 'TriggerMessage'
-- @param val (number, bool or nil)

function MidiActions:_transmit()
  TRACE("MidiActions:_transmit()")

  assert(self._active_map_index,
    "MidiActions error: no mapping was defined")

  self._skip_notifier = (self:_has_observable()) and true or false

  local name = MidiActions.midi_mappings[self._active_map_index]
  assert(name,"MidiActions error: invalid mapping")

  local msg = TriggerMessage()

  -- supply a default value for this
  msg.boolean_value = self._is_switch and true or nil

  if (type(self._value)=="number") then

    -- always scale parameters to 0-127 range
    local value = self._value
    if self._assist.param then
      local min_val,max_val = self:_get_min_max(self._assist)
      value = scale_value(value,min_val,max_val,0,127)
    end

    msg.value_min_scaling = 0
    msg.value_max_scaling = 1

    local offset_val = value + (self._assist.offset or 0)
    msg.int_value = offset_val
    --print("MidiActions:_transmit - msg.int_value",msg.int_value)

  elseif (type(self._value)=="boolean") then
    
    msg.boolean_value = self._value

  end

  msg._is_trigger = self._is_trigger
  msg._is_switch = self._is_switch

  -- todo: support relative values
  msg._is_abs_value = true
  msg._is_rel_value = false

  --print("MidiActions:_transmit - invoke_action(name,msg)",name,msg)
  invoke_action(name,msg)

  if self:_has_observable() then
    self._skip_notifier = false
  end

end

--------------------------------------------------------------------------------

--- Get the min/max values for a parameter
-- @param assist (Table) an entry from the assist table

function MidiActions:_get_min_max(assist)
  --TRACE("MidiActions:_get_min_max(assist)",assist)

  local min_val,max_val = nil,nil --0,127 

  local param = assist.param and assist.param() or nil

  if param then
    min_val = param.value_min
  elseif (type(assist.minimum) == "function") then
    min_val = assist.minimum()
  elseif (type(assist.minimum) == "number") then
    min_val = assist.minimum
  end
  if param then
    max_val = param.value_max
  elseif (type(assist.maximum) == "function") then
    max_val = assist.maximum()
  elseif (type(assist.maximum) == "number") then
    max_val = assist.maximum
  end

  return min_val,max_val

end

--------------------------------------------------------------------------------

--- Locate a specific item in our "assist" table from it's name,
-- with built-in wildcard support (entries that contain an asterisk)

function MidiActions:_retrieve_assist_by_name(str_name)
  TRACE("MidiActions:_retrieve_assist_by_name(str_name)",str_name)

  -- first, try a literal string match
  for k,v in pairs(MidiActions.assist_table) do
    if (v.name == str_name) then
      --print("*** got here - literal match")
      return v
    end
  end

  -- next, try with regular expression matching
  local patt = "([^#]+#)(%d+)(.+)"
  local matches = string.gmatch(str_name,patt)
  local str_start,str_index,str_end = nil,nil,nil
  for v1,v2,v3 in matches do
    str_start,str_index,str_end = v1,v2,v3
  end 
  for k,v in pairs(MidiActions.assist_table) do
    patt = "([^#]+#)*(.+)"
    local matches = string.gmatch(v.name,patt)
    for v1,v2 in matches do
      if (v1==str_start) and (v2==str_end) then

        -- assign functions, using the extracted index as argument 
        -- (the presence of a "param" will cause value_func/observable
        -- to be skipped, as it can replace both)
        local func = nil
        local obs = nil
        local prm = nil
        if not v.param then
          if v.value_func then
            func = function()
              return v.value_func(tonumber(str_index))
            end
          elseif self._is_toggle or self._is_switch then
            -- does not apply to [Trigger]
            func = function()
              return tonumber(str_index)
            end
          end
          if v.observable then
            obs = function()
              return v.observable(tonumber(str_index))
            end
          end
        else
          local param = v.param(tonumber(str_index))
          if param then
            prm = function() 
              return param 
            end
            obs = function() 
              return param.value_observable
            end
          else
            -- could not locate DeviceParameter
            -- (probably due to an invalid index)
          end

        end

        local recreated = table.rcopy(v)
        recreated.name = string.format("%s%s%s",v1,str_index,v2)
        recreated.label = string.format("%s%s",v.label,str_index)
        recreated.value_func = func
        recreated.observable = obs
        recreated.param = prm
        --print("recreated...")
        --rprint(recreated)
        return recreated
      end
    end
  end

  return {}

end

--------------------------------------------------------------------------------

--- Update min/max options, called after routing has been established

function MidiActions:_update_option_panel()
  TRACE("MidiActions:_update_option_panel()")

  for k,v in pairs(self.options) do
    if (k=="min_scaling") or 
      (k=="max_scaling") 
    then
      local min_val,max_val = self:_get_min_max(self._assist)
      if (k=="min_scaling") then
        self._user_min = self._user_min or min_val or 0
      end
      if (k=="max_scaling") then
        self._user_max = self._user_max or max_val or 1
      end
      local elm_id = ("dpx_app_options_%s"):format(k)
      local elm = self._vb.views[elm_id]
      if elm then
        if not table.is_empty(self._assist) then
          if self._assist.minimum and
            self._assist.maximum
          then
            elm.active = true 
          else
            elm.active = false 
          end
          --print("elm.active",elm.active)
          if not self._assist.param then
            self._revert_requested = true
            if (k=="min_scaling") then
              elm.value = self._user_min+1
            end
            if (k=="max_scaling") then
              elm.value =  self._user_max+1
            end
            self._revert_requested = false
          end
        elseif self._active_map_index then
          -- without assist, assume that "[Trigger]" is disabled
          local name = MidiActions.midi_mappings[self._active_map_index]
          local str_trigger = string.sub(name,#name-8)
          elm.active = (str_trigger~="[Trigger]") and true or false
        else
          elm.active = false
        end
      end
    end

  end

end

--------------------------------------------------------------------------------

--- Disable min/max options

function MidiActions:_reset_min_max_options()
  TRACE("MidiActions:_reset_min_max_options()")

  self._revert_requested = true
  for k,v in pairs(self.options) do
    if (k=="min_scaling") or (k=="max_scaling") then
      local elm_id = ("dpx_app_options_%s"):format(k)
      local elm = self._vb.views[elm_id]
      if elm then
        elm.value = 1
        elm.active = false 
      end
    end
  end
  self._revert_requested = false

end


--------------------------------------------------------------------------------

--- Validate & set the current option/user-specified min/max 
-- note that we allow inverted min/max, but not values outside this range

function MidiActions:_validate_range()
  TRACE("MidiActions:_validate_range()")

  local min_val,max_val = self:_get_min_max(self._assist)

  if not min_val and not max_val then
    return
  end

  -- swap min/max if max is smaller
  if (min_val > max_val) then
    min_val,max_val = max_val,min_val
  end

  local function within_min_max(val)
    if (val > max_val) then
      return false
    elseif (val < min_val) then
      return false
    end
    return true
  end

  if min_val then
    local user_min = self.options.min_scaling.value-1
    if not within_min_max(user_min) then
      self._revert_requested = true
    end
  end
  if max_val then
    local user_max = self.options.max_scaling.value-1
    if not within_min_max(user_max) then
      self._revert_requested = true
    end
  end

  if not self._revert_requested then
    -- remember values, so we can revert 
    self._user_min = self.options.min_scaling.value-1
    self._user_max = self.options.max_scaling.value-1
  end
end

--------------------------------------------------------------------------------

--- Look up the mapping and gather as much information as possible
-- @param first_run (bool) true when app is first instantiated

function MidiActions:_establish_routing(first_run)
  TRACE("MidiActions:_establish_routing(first_run)",first_run)

  if not first_run then
    self:_remove_notifier()
    self:_clear_routing()
    self:_reset_min_max_options()
  end
  local map_index = self.options.action.value - 1
  if (map_index == 0) then
    return
  else
    self._active_map_index = map_index
  end
  local mapping = MidiActions.midi_mappings[self._active_map_index]
  assert(mapping,"MidiActions error: the target mapping wes not found!")

  self._assist = self:_retrieve_assist_by_name(mapping)

  local initial_value = self:_get_value()

  self._is_trigger = false
  self._is_switch = false
  self._is_toggle = false

  local str_trigger = string.sub(mapping,#mapping-8)
  local str_toggle = string.sub(mapping,#mapping-7)
  local str_set = string.sub(mapping,#mapping-4)

  if (str_trigger=="[Trigger]") then
    self._is_trigger = true
  elseif(str_toggle=="[Toggle]") then
    self._is_trigger = true
    self._is_toggle = true
  end

  if (str_set=="[Set]") then
    -- some actions check for "is_trigger", so we add this
    -- property as well as the "is_switch" (which is otherwise
    -- the most common/important property for [Set] actions)
    self._is_trigger = true
    self._is_switch = true 
  end

  -- if no type was matched, use the trigger method
  -- (as this is the least "demanding" method)
  if not self._is_trigger and
    not self._is_switch and
    not self._is_toggle 
  then
    self._is_trigger = true
  end

  -- bidirectional support from assist-table
  local observable = self:_get_observable()
  if observable then
    --print("MidiActions:_establish_routing - add self._observable",observable)
    observable:add_notifier(
      self, 
      function(_,args)
        if not self.active then
          return
        end

        if not self._skip_notifier then
          self:_update_control(true)
        end
        self._skip_notifier = false
      end 
    )
  end

  -- apply the icon / label / tooltip
  if self._assist.label then
    self.palette.active.text = self._assist.label
    self.palette.inactive.text = self._assist.label
  else
    self.palette.active.text = MidiActions.default_palette.active.text
    self.palette.inactive.text = MidiActions.default_palette.inactive.text
  end
  if self._assist.name then
    if self._controls.slider then
      self._controls.slider.tooltip = self._assist.name
    elseif self._controls.button then
      self._controls.button.tooltip = self._assist.name
    end
  end

  self:_update_option_panel()
  self:_update_control(true)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_idle

function MidiActions:on_idle()

  if not self.active then
    return
  end

  if not self._active_map_index then
    return
  end

  local min_val,max_val = nil,nil

  if self._revert_requested then
    min_val,max_val = self:_get_min_max(self._assist)
    self._user_min = math.max(self._user_min,min_val)+1
    self._user_max = math.min(self._user_max,max_val)+1
    self:_set_option("min_scaling",self._user_min,self._process)
    self:_set_option("max_scaling",self._user_max,self._process)
    local msg = "The chosen value is outside the allowed range,"
              .."\nplease select a value between %d and %d"
    msg = string.format(msg,min_val,max_val)
    renoise.app():show_message(msg)
    self._revert_requested = false

  end


  -- detect changes to non-observable parameters
  if not self:_has_observable() then
    if self:_has_value() and (self._value~=nil) then
      local new_val = self:_get_value()
      if (new_val~=nil) then
        if self._assist.is_boolean then
          if (new_val~=self._value) then
            --print("*** on_idle - update_control",new_val,self._value)
            self:_update_control(true)
          end
        else
          if not compare(new_val,self._value,1000) then
            --print("*** on_idle - update_control",new_val,self._value)
            self:_update_control(true)
          end
        end
      end
    end

  end

end

--------------------------------------------------------------------------------

--- Override the application method (update the options once ready)

function MidiActions:_build_options()
  TRACE("MidiActions:_build_options()")

  Application._build_options(self,self._process)
  self:_update_option_panel()

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function MidiActions:_build_app()

  -- auto-detect the input method
  local input_method = nil
  local cm = self.display.device.control_map
  local map = self.mappings.control
  local grid_size,grid_size_x,grid_size_y = nil
  if map.group_name then
    local param = cm:get_param_by_index(map.index,map.group_name)
    if param then
      if (param.xarg.type == "dial") or
        (param.xarg.type == "fader") 
      then
        input_method = "slider"
      else
        input_method = "button"
      end
    else
      -- check if we are dealing with a slider 
      -- made from individual buttons ("grid mode")
      if map.orientation == ORIENTATION.HORIZONTAL then
        grid_size = cm:count_columns(map.group_name)
      elseif map.orientation == ORIENTATION.VERTICAL then
        grid_size = cm:count_rows(map.group_name)
      elseif map.orientation == ORIENTATION.NONE then
        grid_size_x = cm:count_columns(map.group_name)
        grid_size_y = cm:count_rows(map.group_name)
      end
      input_method = "slider"
    end
  end

  if not input_method then
    local msg = "Could not start Duplex MidiActions, the required "
              .."\nmapping 'control' has not been defined"
    renoise.app():show_warning(msg)
    return false
  end

  if (input_method == "button") then

    if map.group_name then
      local c = UIButton(self)
      c.group_name = map.group_name
      c:set_pos(map.index)
      c.tooltip = map.description
      c.on_press = function(obj)
        self:_update_control()
      end
      self._controls.button = c
    end

  else

    if map.group_name then
      local c = UISlider(self)
      c.group_name = map.group_name
      c:set_pos(map.index or 1)
      c.flipped = map.flipped
      c.toggleable = true
      c:set_orientation(map.orientation)
      if map.orientation == ORIENTATION.NONE then
        c:set_size(grid_size_x,grid_size_y)
      else
        c:set_size(grid_size or 1)
      end
      c.palette.background = table.rcopy(self.palette.inactive)
      c.palette.tip = table.rcopy(self.palette.active)
      c.palette.track = table.rcopy(self.palette.inactive)
      c.ceiling = 1
      c.tooltip = map.description
      c.on_change = function(obj)
        self:_update_control()
      end
      self._controls.slider = c

    end

  end

  return true

end


--==============================================================================

--- Emulate the MIDI message class used by Renoise (see GlobalMidiActions.lua)

class 'TriggerMessage'

function TriggerMessage:__init()

  -- [0 - 127] for abs values, [-63 - 63] for relative values
  -- valid when is_rel_value() or is_abs_value() returns true, else nil
  self.int_value = nil

  -- valid [true OR false] when :is_switch() returns true, else nil
  self.boolean_value = nil

  -- [0.0 - 1.0] min/max range scaling for parameter values 
  self.value_min_scaling = nil
  self.value_max_scaling = nil

  -- bools, for internal use
  self._is_trigger = nil
  self._is_switch = nil
  self._is_rel_value = nil
  self._is_abs_value = nil

end

function TriggerMessage:is_trigger() 
  return self._is_trigger
end

function TriggerMessage:is_switch() 
  return self._is_switch
end

function TriggerMessage:is_rel_value() 
  return self._is_rel_value
end

function TriggerMessage:is_abs_value() 
  return self._is_abs_value
end
