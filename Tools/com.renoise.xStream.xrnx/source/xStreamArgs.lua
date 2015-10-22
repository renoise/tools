--[[============================================================================
xStreamArgs
============================================================================]]--
--[[

	This class manages real-time observable values for xStream

  The observable values are exposed as properties of the class itself,
  which means that arguments are restricted from using any of the names
  that are already in use ("model", "args", etc.). 

  While xStreamArg instances are accessed through the .args property, 
  the callback will access the arguments directly as class properties. 

  ## Value transformations

  Accessing values directly as class properties will include a just-in-time
  transformation of the value. For example, if we are listening to the
  index of an instrument, we are likely to use that value for output in
  the pattern. And since the Renoise API uses a one-based counting system,
  it's of great convenience to be able to specify "this is zero-based". 
  
  Possible value-transformations include: 
  + zero_based : count from 0 instead of 1
  + quant = 1  : force integer  


]]

class 'xStreamArgs'

xStreamArgs.RESERVED_NAMES = {"Arguments","Presets"}

-------------------------------------------------------------------------------
-- constructor
-- @param xstream (xStream)

function xStreamArgs:__init(model)
  TRACE("xStreamArgs:__init(model)",model)
  
  -- xStreamModel, reference to owner
	self.model = model

  -- table<xStreamArg>
  self.args = {}

  -- int, read-only - number of registered arguments
  self.length = property(self.get_length)

  -- int, selected argument in UI (0 = none) 
  self.selected_index = property(self.get_selected_index,self.set_selected_index)
  self.selected_index_observable = renoise.Document.ObservableNumber(1)


end

-------------------------------------------------------------------------------
-- Get/set methods 
-------------------------------------------------------------------------------

function xStreamArgs:get_length()
  return #self.args
end

-------------------------------------------------------------------------------

function xStreamArgs:get_selected_index()
  return self.selected_index_observable.value
end

function xStreamArgs:set_selected_index(val)
  self.selected_index_observable.value = val
end

--------------------------------------------------------------------------------
-- Class methods
-------------------------------------------------------------------------------
-- Add property to our document, register notifier
-- @param arg (table), see xStreamArg.constructor
-- @return bool, true when accepted
-- @return string, error message

function xStreamArgs:add(arg)
  TRACE("xStreamArgs:add(arg)",arg)
  --rprint(arg)
  --print(type(arg.value))
  
  if (type(arg.name)~='string') then
    return false,"Argument name '"..arg.name.."' needs to be a string"
  end
  -- TODO validate as proper lua variable name
  --[[
    *** std::logic_error: 'observable and node names must not contain special characters. only alphanumerical characters and '_' are allowed (like XML keys).'
  ]]
  if not xReflection.is_valid_identifier(arg.name) then
    --print("got here")
    return false,"Argument name '"..arg.name.."' needs to be a proper lua variable name - no special characters or number as the first character"
  end

  -- avoid using existing or RESERVED_NAMES
  if (type(self[arg.name]) ~= 'nil') or 
    (table.find(xStreamArgs.RESERVED_NAMES,arg.name)) 
  then
    return false,"The argument "..arg.name.." is already defined. Please choose another name"
  end

  if (type(arg.value)=='nil') then
    return false,"Please provide a default value (makes the type unambigous)"
  end

  if arg.poll and arg.bind then
    return false,"Please specify either bind or poll for an argument, but not both"
  end   

  -- Observable needs a value in order to determine it's type.
  -- Try to evaluate the bind/poll string in order to get the 
  -- current value. If that fails, provide the default value
  local bind_val,err
  if arg.bind then
    --print("default value for arg.bind",arg.bind)
    local bind_val_no_obs = string.sub(arg.bind,1,#arg.bind-11)
    bind_val,err = xLib.parse_str(bind_val_no_obs)
  elseif arg.poll then
    --print("default value for arg.poll",arg.poll)
    bind_val,err = xLib.parse_str(arg.poll)
  end
  if not err then
    arg.value = bind_val or arg.value
  else
    LOG(err)
  end

  -- seems ok, add to our document and create xStreamArg 
  if (type(arg.value) == "string") then
    arg.observable = renoise.Document.ObservableString(arg.value)
  elseif (type(arg.value) == "number") then
    arg.observable = renoise.Document.ObservableNumber(arg.value)
  elseif (type(arg.value) == "boolean") then
    arg.observable = renoise.Document.ObservableBoolean(arg.value)
  end
  arg.xstream = self.model.xstream

  local xarg = xStreamArg(arg)
  table.insert(self.args,xarg)

  local arg_index = #self.args

  -- read-only access, used by the callback method
  -- can apply transformation to the result
  self[arg.name] = property(function()  
    local val = self.args[arg_index].value
    if arg.properties then
      if arg.properties.zero_based then
        val = val - 1
      end
      if (arg.properties.quant == 1) then
        val = math.floor(val)
      end
    end
    return val
  end)

  --print("adding arg",arg.name)
  return true

end

-------------------------------------------------------------------------------
-- return copy of all current values (requested by e.g. callback)
-- TODO optimize by keeping this up to date when values change

function xStreamArgs:get_values()
  TRACE("xStreamArgs:get_values()")
  local rslt = {}
  for _,arg in ipairs(self.args) do
    rslt[arg.name] = arg.value
  end
  --print("xStreamArgs:get_values - rslt",rprint(rslt))
  return rslt
end

-------------------------------------------------------------------------------
-- return table<string>

function xStreamArgs:get_names()
  TRACE("xStreamArgs:get_names()")

  local t = {}
  for _,v in ipairs(self.args) do
    table.insert(t,v.name)
  end
  return t

end

-------------------------------------------------------------------------------
-- apply a random value to boolean, numeric values

function xStreamArgs:randomize()

  for _,arg in ipairs(self.args) do

    if not arg.locked then

      local val

      if (type(arg.value) == "boolean") then
        val = (math.random(0,1) == 1) and true or false
        --print("*** boolean random",val)
      elseif (type(arg.value) == "number") then
        if arg.properties then
          if (arg.properties.items) then
            -- popup or switch
            val = math.random(0,#arg.properties.items)
          elseif arg.properties.min and arg.properties.max then
            if (arg.properties.quant == 1) then
              -- integer
              val = math.random(arg.properties.min,arg.properties.max)
            else
              -- float
              val = xLib.scale_value(math.random(),0,1,arg.properties.min,arg.properties.max)
            end
          end
        end
      end

      if (type(val) ~= "nil") then
        arg.observable.value = val
      end

    end

  end

end

-------------------------------------------------------------------------------
-- (re-)bind arguments when model or song has changed

function xStreamArgs:attach_to_song()
  TRACE("xStreamArgs:attach_to_song()")

  self:detach_from_song()

  for _,arg in ipairs(self.args) do
    if (arg.bind) then
      arg.bind = xStreamArg.resolve_binding(arg.bind_str)
      arg.bind:add_notifier(arg,arg.bind_notifier)
      -- call it once, to initialize value
      arg:bind_notifier()
    end
  end

end

-------------------------------------------------------------------------------
-- when we switch away from the model using these argument

function xStreamArgs:detach_from_song()
  TRACE("xStreamArgs:detach_from_song()")

  for _,arg in ipairs(self.args) do
    if (arg.bind_notifier) then
      --print("*** detach_from_song - arg.bind_str",arg.bind_str)
      pcall(function()
        if arg.bind:has_notifier(arg,arg.bind_notifier) then
          arg.bind:remove_notifier(arg,arg.bind_notifier)
        end
      end) 
    end
  end

end

-------------------------------------------------------------------------------
-- execute running tasks for all registered arguments

function xStreamArgs:on_idle()
  --TRACE("xStreamArgs:on_idle()")

  for _,arg in ipairs(self.args) do
    if (type(arg.poll)=="function") then
      -- 'poll' - get current value 
      local rslt = arg.poll()
      if rslt then
        arg.observable.value = rslt
      end
    elseif (type(arg.value_update_requested) ~= "nil") then
      -- 'bind' requested an update
      arg.observable.value = arg.value_update_requested
      arg.value_update_requested = nil
    end
  end



end

-------------------------------------------------------------------------------
-- return arguments as a valid lua string, ready be to included
-- in a model definition - see also xStreamModel:serialize()
-- @return string (arguments)
-- @return string (default presets)

function xStreamArgs:serialize()
  TRACE("xStreamArgs:serialize()")

  local args = {}
  for _,arg in ipairs(self.args) do

    local props = {}
    if arg.properties then
      -- remove default values from properties
      props = table.rcopy(arg.properties_initial)
      if (props.impacts_buffer == true) then
        props.impacts_buffer = nil
      end
    end

    table.insert(args,{
      name = arg.name,
      value = arg.value,
      properties = props,
      description = arg.description,
      bind = arg.bind_str,
      poll = arg.poll_str
    })

  end

  local presets = {}
  if self.model.selected_preset_bank then
    presets = self.model.selected_preset_bank.presets
  end

  local str_args = xLib.serialize_table(args)
  local str_presets = xLib.serialize_table(presets)

  return str_args,str_presets

end

