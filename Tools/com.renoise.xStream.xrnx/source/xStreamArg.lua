--[[===============================================================================================
xStreamArg
===============================================================================================]]--
--[[

  This class is representing a single xStream argument
  See also xStreamArgs

]]

--=================================================================================================

class 'xStreamArg'

-- string constants, saved into definitions 
xStreamArg.DISPLAYS = {"float","hex","integer","percent","note","popup","chooser","switch","minislider","rotary","checkbox","textfield","value"}
xStreamArg.DISPLAY_AS = {
  FLOAT = 1,
  HEX = 2,
  INTEGER = 3,
  PERCENT = 4,
  NOTE = 5,
  POPUP = 6,
  CHOOSER = 7,
  SWITCH = 8,
  MINISLIDER = 9,
  ROTARY = 10,
  CHECKBOX = 11,
  TEXTFIELD = 12,
  VALUE = 13,
}

xStreamArg.BASE_TYPES = {"number","boolean","string"}
xStreamArg.BASE_TYPE = {
  NUMBER = 1,
  BOOLEAN = 2,
  STRING = 3
}

xStreamArg.SUPPORTS_MIN_MAX = {
  xStreamArg.DISPLAY_AS.FLOAT,
  xStreamArg.DISPLAY_AS.HEX,
  xStreamArg.DISPLAY_AS.INTEGER,
  xStreamArg.DISPLAY_AS.PERCENT,
  xStreamArg.DISPLAY_AS.NOTE,
  xStreamArg.DISPLAY_AS.MINISLIDER,
  xStreamArg.DISPLAY_AS.ROTARY,
}

xStreamArg.SUPPORTS_ZERO_BASED = {
  xStreamArg.DISPLAY_AS.HEX,
  xStreamArg.DISPLAY_AS.INTEGER,
}

xStreamArg.REQUIRES_ITEMS = {
  xStreamArg.DISPLAY_AS.POPUP,
  xStreamArg.DISPLAY_AS.CHOOSER,
  xStreamArg.DISPLAY_AS.SWITCH,
}

xStreamArg.NUMBER_DISPLAYS = {
  xStreamArg.DISPLAY_AS.FLOAT,
  xStreamArg.DISPLAY_AS.HEX,
  xStreamArg.DISPLAY_AS.INTEGER,
  xStreamArg.DISPLAY_AS.PERCENT,
  xStreamArg.DISPLAY_AS.NOTE,
  xStreamArg.DISPLAY_AS.POPUP,
  xStreamArg.DISPLAY_AS.CHOOSER,
  xStreamArg.DISPLAY_AS.SWITCH,
  xStreamArg.DISPLAY_AS.MINISLIDER,
  xStreamArg.DISPLAY_AS.ROTARY,
  xStreamArg.DISPLAY_AS.VALUE,
}

xStreamArg.BOOLEAN_DISPLAYS = {
  xStreamArg.DISPLAY_AS.CHECKBOX,
}

xStreamArg.STRING_DISPLAYS = {
  xStreamArg.DISPLAY_AS.TEXTFIELD,
}

xStreamArg.SERIALIZABLE = {
  "full_name",
  "value",
  "props",
  "description",
  "bind_str",
  "poll_str",
  "linked",
  "locked",
}

---------------------------------------------------------------------------------------------------
-- constructor
-- @param args (table), 
--  xstream
--  name
--  description
--  properties (table)
--  bind (string)
--  poll (string)
--  value (number/string/boolean)
--  observable (ObservableXXX)

function xStreamArg:__init(arg)

	assert(type(arg.name == "string"),"Expected name argument as string")
	assert(type(arg.name ~= "nil"),"Expected value argument (number,string or boolean")

  -- TODO more validation

  -- serializable properties  -----------------------------

  -- string, name of argument (required)
  self.name = arg.name 

  -- string, name of argument tab (optional)
  self.tab_name = arg.tab_name

  -- string, full name is [tab_name +] name
  self.full_name = property(self.get_full_name)

  -- number/boolean/string
  self.value = property(self.get_value,self.set_value)

  -- ObservableXXX (number/boolean/string)
  self.observable = arg.observable

  -- string, description of argument (optional)
  self.description = arg.description 

  -- table, extra properties (all optional)
  --  impacts_buffer (bool), refresh buffer when changed
  --  fire_on_start (bool), fire value when first loaded
  --  min, max (number) 
  --  display_as (xStreamArg.DISPLAY_AS) 
  --  zero_based (bool) also used in callback
  --  items (table<string>) display as popup/chooser
  --    note: you can also specify a string for this value, 
  --    which will then be evaluated during activation
  --    (case in point: a list of effect commands might differ
  --    from one version of Renoise to another)
  --  display (string) "popup", "chooser" (default is popup)
  self.properties = arg.properties or {}

  -- copy of properties (some values might be evaluated 
  -- during runtime - revert to these when serializing)
  self.properties_initial = table.rcopy(self.properties)

  -- function, polling functions (optional)
  self.poll = xStreamArg.create_fn(arg.poll)
  self.poll_str = arg.poll

  -- observableXXX, external bindings (optional)
  -- (re-bound on app_new_document_observable)
  self.bind = xStreamArg.resolve_binding(arg.bind)
  self.bind_str = arg.bind 
  self.bind_str_val = arg.bind and string.sub(arg.bind,1,#arg.bind-11) 

  -- function, update renoise (when bound to API)
  self.bind_notifier = nil

  -- boolean, when true only user can set value
  -- (preset recalls and observed properties are ignored)
  self.locked = property(self.get_locked,self.set_locked)
  self.locked_observable = renoise.Document.ObservableBoolean(arg.locked or false)

  -- boolean, when true only user can set value
  -- (preset recalls and observed properties are ignored)
  self.linked = property(self.get_linked,self.set_linked)
  self.linked_observable = renoise.Document.ObservableBoolean(arg.linked or false)

  -- xStream, reference to the owning model 
  self.model = arg.model

  -- function, fires when observable has changed
  self.notifier = nil

  -- function, fires when argument definition has changed
  self.modified_observable = renoise.Document.ObservableBang()

  -- add default properties
  if (type(self.properties.impacts_buffer) == "nil") then
    self.properties.impacts_buffer = true
  end
  if (type(self.properties.fire_on_start) == "nil") then
    self.properties.fire_on_start = true
  end

  -- evaluate string-based properties
  if (type(self.properties.items) == "string") then
    local items,err = cLib.parse_str(self.properties.items)
    if err then
      LOG(err)
    else
      self.properties.items = items
    end
  end

  -- hook into our own observable
  self.observable:add_notifier(self,self.notifier)


end

---------------------------------------------------------------------------------------------------
-- notifier for argument (== user events) 

function xStreamArg:notifier()
  TRACE("xStreamArg:notifier()")

  if self.linked then
    --print(">>> update linked arguments")
    self.model.args:set_linked(self)
  end

  if self.bind then 
    --print(">>> update renoise")
    self:bind_notifier(self.observable.value)
  end

  -- invoke event callbacks (if any)
  -- doing this before recomputing the buffer
  -- will allow the model to respond to a changed 
  -- state before recomputing 
  local arg_name = "args."..self.full_name
  self.model:handle_event(arg_name,self.value)

  if self.properties.impacts_buffer then
    self.model.buffer:immediate_output()
    -- do the same for other (stacked) models   
    self.model.on_rebuffer:bang()
  end

end

---------------------------------------------------------------------------------------------------
-- update renoise (when bound to API)
-- @param val (string,number or boolean) set when user event

function xStreamArg:bind_notifier(val)
  TRACE("xStreamArg:bind_notifier",val)

  if (type(val) ~= "nil") then
    local success,err = cReflection.set_property(self.bind_str_val,val)
    --print("*** self.bind_notifier - success,err",success,err)
    if not success then
      LOG("ERROR: xStreamArg.bind_notifier - "..err)
    end
  else 
    if self.locked then
      return
    end
    -- retrieve from Renoise
    local new_value,err = cLib.parse_str(self.bind_str_val)
    if not err then
      -- hackaround: avoid notifier feedback by scheduling the update
      -- note: feedback will occur if we are not able to set the target -
      -- this can occur e.g. with keyboard_velocity, when velocity is not
      -- enabled (it will remain at maximum velocity in such cases)
      self.value_update_requested = new_value
    else
      LOG(err)
    end
  end
end

---------------------------------------------------------------------------------------------------
-- get name, including tab (if present)

function xStreamArg:get_full_name()
  if self.tab_name then
    return self.tab_name.."."..self.name
  else
    return self.name
  end
end

---------------------------------------------------------------------------------------------------

function xStreamArg:get_locked()
  return self.locked_observable.value
end

function xStreamArg:set_locked(val)
  --print("xStreamArg:set_locked(val)",val)
  local modified = (val ~= self.locked_observable.value) and true or false
  self.locked_observable.value = val
  if modified then
    self.modified_observable:bang()
  end
end

---------------------------------------------------------------------------------------------------

function xStreamArg:get_linked()
  return self.linked_observable.value
end

function xStreamArg:set_linked(val)
  local modified = (val ~= self.linked_observable.value) and true or false
  self.linked_observable.value = val
  if modified then
    self.modified_observable:bang()
  end
end

---------------------------------------------------------------------------------------------------
-- resolve the 'bind string' into an ObservableXXX object
-- @param bind_str (string), e.g. "rns.transport.keyboard_velocity_observable"
-- @return ObservableXXX or nil

function xStreamArg.resolve_binding(bind_str)
  TRACE("xStreamArg.resolve_binding(bind_str)",bind_str)

  if not bind_str then
    return
  end

  local binding,err = cLib.parse_str(bind_str)
  if binding then
    return binding
  else
    LOG(err)
  end

end

---------------------------------------------------------------------------------------------------
-- quickly decide if argument is bound or polling 

function xStreamArg:get_bop()
  if type(self.poll_str)=="string" then
    return self.poll_str 
  elseif type(self.bind_str)=="string" then
    return self.bind_str 
  end
end

---------------------------------------------------------------------------------------------------
-- create a function which return a value when the bound target has changed
-- @param str (string), e.g. "rns.transport.keyboard_velocity_observable"
-- @return function or nil

function xStreamArg.create_fn(str)
  TRACE("xStreamArg.create_fn(str)",str)

  if not str then
    return
  end

  local old_value = nil 
  local fn = function()
    local new_value,err = cLib.parse_str(str)
    if not err and (new_value ~= old_value) then
      old_value = new_value
      return new_value
    end
  end

  return fn

end


---------------------------------------------------------------------------------------------------

function xStreamArg:get_value()
  return self.observable.value
end

function xStreamArg:set_value(val)
  TRACE("xStreamArg:set_value(val)",val)
  self.observable.value = self:clamp_value(val)
end

---------------------------------------------------------------------------------------------------
-- Get current value, restricted to min/max if set 
-- @return number/boolean/string

function xStreamArg:get_clamped_value()
  return self:clamp_value(self.value)
end

---------------------------------------------------------------------------------------------------
-- Restrict provided value (number only) to min/max 
-- @param val (number/boolean/string)
-- @return number/boolean/string

function xStreamArg:clamp_value(val)
  TRACE("xStreamArg:clamp_value(val)",val)
  if (type(val)=="number") and 
    not table.is_empty(self.properties) 
  then 
    local min,max = self.properties.min,self.properties.max
    if min and max then 
      return cLib.clamp_value(val,min,max)
    end
  end
  return val
end

---------------------------------------------------------------------------------------------------

function xStreamArg:get_definition()
  TRACE("xStreamArg:get_definition()")

  local def = {}

  local props = {}
  if self.properties then
    -- remove default values from properties
    props = table.rcopy(self.properties_initial)
    if (props.impacts_buffer == true) then
      props.impacts_buffer = nil
    end
    if (props.fire_on_start == true) then
      props.fire_on_start = nil
    end
  end

  --[[
  table.insert(args,{
    name = self.full_name,
    value = self.value,
    properties = props,
    description = self.description,
    bind = self.bind_str,
    poll = self.poll_str,
    linked = self.linked,
    locked = self.locked,
  })
  ]]

  local ignored = {
    "props", 
  }

  for k,v in ipairs(xStreamArg.SERIALIZABLE) do
    if not table.find(ignored,k) then
      def[v] = self[v]
    end
  end

  def.props = props

  return def

end


---------------------------------------------------------------------------------------------------

function xStreamArg:__tostring()

  return type(self)
    ..",name="..tostring(self.name)
    ..",tab_name="..tostring(self.tab_name)
    ..",value="..tostring(self.value)

end
