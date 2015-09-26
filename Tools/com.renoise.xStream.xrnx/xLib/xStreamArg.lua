--[[============================================================================
xEffectColumn
============================================================================]]--
--[[

  This class is representing a single xStream argument
  See also xStreamArgs

]]

class 'xStreamArg'

-------------------------------------------------------------------------------
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

  -- serializable properties  -----------------------------

  -- string, name of argument (required)
  self.name = arg.name 

  -- number/boolean/string
  self.value = arg.value

  -- string, description of argument (optional)
  self.description = arg.description 

  -- table, extra properties (all optional)
  --  impacts_buffer (bool), refresh buffer when changed
  --  quant (int), value quantization - e.g. "1" for integer 
  --  min, max (number) 
  --  display_as_hex (bool) when valuefield
  --  display_as_note (bool) when slider
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
  self.bind_notifier = nil

  -- everything below is runtime only ---------------------

  -- boolean, when true only user can set value
  -- (preset recalls and observed properties are ignored)
  self.locked = property(self.get_locked,self.set_locked)
  self.locked_observable = renoise.Document.ObservableBoolean(false)

  -- xStream, reference to owner
  self.xstream = arg.xstream

  -- ObservableXXX
  self.observable = arg.observable

  -- function, fires when observable has changed
  self.notifier = nil

  -- add default properties
  if (type(self.properties.impacts_buffer) == "nil") then
    self.properties.impacts_buffer = true
  end

  -- evaluate string-based properties
  if (type(self.properties.items) == "string") then
    local items,err = xLib.parse_str(self.properties.items)
    if err then
      LOG(err)
    else
      self.properties.items = items
    end
  end

  -- notifier for argument (== user events) 
  self.notifier = function()
    --print("notifier_fn fired...",self.name,self.observable.value)
    self.value = self.observable.value
    if self.bind_notifier then
      -- update renoise
      self.bind_notifier(self.observable.value)
    end
    if self.properties.impacts_buffer then
      self.xstream:wipe_futures()
    end

  end

  -- notifier for bound target (== renoise events)
  if arg.bind then
    local bind_str_val = string.sub(arg.bind,1,#arg.bind-11)
    self.bind_notifier = function(val)

      -- @param val (string,number or boolean) set when user event
      --print("bind_notifier fired...self.name,val",self.name,val,type(val),bind_str_val)
      if (type(val) ~= "nil") then
        
        local success,err = xLib.set_obj_str_value(bind_str_val,val)
        --print("*** self.bind_notifier - success,err",success,err)
        if not success then
          LOG("ERROR: xStreamArg.bind_notifier - "..err)
        end
      else
        -- nil, retrieve from Renoise? 
        if self.locked then
          return
        end
        local new_value,err = xLib.parse_str(bind_str_val)
        if not err then
          print("*** self.bind_notifier - parsed bind_str_val",bind_str_val,", new_value = ",new_value,"self.value",self.value)
          self.value = new_value
          -- hackaround: avoid notifier feedback by scheduling the update
          -- note: feedback will occur if we are not able to set the target 
          -- this can occur e.g. with keyboard_velocity, when velocity is not
          -- enabled (it will remain at maximum velocity in such cases)
          self.value_update_requested = new_value
        else
          LOG(err)
        end
      end
    end
  end

end

-------------------------------------------------------------------------------

function xStreamArg:get_locked()
  return self.locked_observable.value
end

function xStreamArg:set_locked(val)
  self.locked_observable.value = val
end

-------------------------------------------------------------------------------
-- resolve the 'bind string' into an ObservableXXX object
-- @param str (string), e.g. "rns.transport.keyboard_velocity_observable"
-- @return ObservableXXX or nil

function xStreamArg.resolve_binding(bind_str)
  TRACE("xStreamArg.resolve_binding(bind_str)",bind_str)

  if not bind_str then
    return
  end

  local binding,err = xLib.parse_str(bind_str)
  if binding then
    return binding
  else
    LOG(err)
  end

end

-------------------------------------------------------------------------------
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
    local new_value,err = xLib.parse_str(str)
    if not err and (new_value ~= old_value) then
      --print("create_bind_fn - old_value,new_value",old_value,new_value)    
      old_value = new_value
      return new_value
    end
  end

  return fn

end

