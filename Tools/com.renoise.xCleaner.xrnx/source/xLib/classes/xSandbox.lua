--[[============================================================================
xSandbox
============================================================================]]--

--[[--

xSandbox allows you to execute code in a controlled environment
.
#

## How to use

    -- create instance 
    sandbox = xSandbox()

    -- supply function
    sandbox.callback_str = 
      "print('hello world')"

    -- and call it...
    sandback.callback()


## Arguments and return values

    -- if you need to supply arguments and define return value, 
    -- one approach is to define a 'prefix' and 'suffix' 
    -- (always added to the generated code)

    -- define arguments 
    sandbox.str_prefix = "local some_arg = select(1, ...)"
    
    -- define return value
    sandbox.str_suffix = "return some_arg"
      
    -- supply function
    sandbox.callback_str = 
      "some_arg = some_arg + 'foo'"..
      "print(some_arg)"

    -- now call the function like this:
    local result = sandback.callback('my_arg')


## Custom properties

TODO how to ... 

]]

class 'xSandbox'

-- disallow the following lua methods/properties
xSandbox.UNTRUSTED = {
  "collectgarbage",
  "coroutine",
  "dofile",
  "io",
  "load",
  "loadfile",
  "module",
  "os",
  "setfenv",
  "class",
  "rawset",
  "rawget",
}

function xSandbox:__init()


  --- function, compiled function (when set, always valid)
  self.callback = nil

  --- string, code to insert into all generated functions
  self.str_prefix = ""
  self.str_suffix = "return"

  --- boolean, set to true for instant compilation of callback string
  self.compile_at_once = true

  --- string, text representation of the function 
  self.callback_str = property(self.get_callback_str,self.set_callback_str)
  self.callback_str_observable = renoise.Document.ObservableString("")

  --- properties can contain custom get/set methods
  self.properties = property(self.get_properties,self.set_properties)
  self._properties = {}

  --- invoked when callback has changed
  self.modified_observable = renoise.Document.ObservableBang()

  --- table, sandbox environment
  self.env = nil

  -- initialize --

  local env = {
    assert = _G.assert,
    error = _G.error,
    ipairs = _G.ipairs,
    loadstring = _G.loadstring,
    math = _G.math,
    next = _G.next,
    pairs = _G.pairs,
    print = _G.print,
    select = _G.select,
    string = _G.string,
    table = _G.table,
    tonumber = _G.tonumber,
    tostring = _G.tostring,
    type = _G.type,
    unpack = _G.unpack,
    -- renoise extended
    ripairs = _G.ripairs,
    rprint = _G.rprint,
    oprint = _G.oprint,
  }

  self.env = env
  env = {}

  -- metatable (constants and shorthands)
  setmetatable(self.env,{
    __index = function (t,k)
      --print("*** sandbox access ",k)
      if table.find(xSandbox.UNTRUSTED,k) then
        error("Property or method is not allowed:"..k)
      else
        if self.properties[k] and self.properties[k].access then
          return self.properties[k].access(env)
        else
          return env[k]
        end
      end
    end,
    __newindex = function (t,k,v)
      --print("*** sandbox assign ",k,v)
      if self.properties[k] and self.properties[k].assign then
        self.properties[k].assign(env,v)
      else
        env[k] = v
      end

    end,
    __metatable = false -- prevent tampering
  })


end

--==============================================================================
-- Getter/Setter Methods
--==============================================================================

function xSandbox:get_callback_str()
  --TRACE("xSandbox:get_callback_str - ",self.callback_str_observable.value)
  return self.callback_str_observable.value
end

-- it's recommended to call test_syntax before setting this value,
--  otherwise you get no feedback if it failed

function xSandbox:set_callback_str(str_fn)

  assert(type(str_fn) == "string", "Expected string as parameter")

  local str_combined = self:prepare_callback(str_fn)
  local modified = (str_combined ~= self.callback_str_observable.value)
  local passed,err = self:test_syntax(str_combined)
  
  self.callback_str_observable.value = str_combined

  if not err and self.compile_at_once then
    local passed,err = self:compile(str_combined)
    if not passed then -- should not happen! 
      LOG(err)
    end
  else
    LOG(err)
  end

  if modified then
    self.modified_observable:bang()
  end

end

-------------------------------------------------------------------------------

function xSandbox:get_properties()
  return self._properties
end

function xSandbox:set_properties(val)
  assert(type(val) == "table", "Expected table as parameter")
  self._properties = val
end


--==============================================================================
-- Class Methods
--==============================================================================
-- wrap callback in function with variable run-time arguments 
-- @param str_fn (string) function as string

function xSandbox:prepare_callback(str_fn)
  --TRACE("xSandbox:prepare_callback(str_fn)",#str_fn)

  assert(type(str_fn) == "string", "Expected string as parameter")

  local str_combined = [[return function(...)
  ]]..self.str_prefix..[[
  ]]..str_fn..[[
  ]]..self.str_suffix..[[
  end]]

  return str_combined

end


-------------------------------------------------------------------------------
-- call method to evaluate function (ensure that it's safe to run)
-- @return boolean, true when method passed
-- @return string, error message when failed

function xSandbox:compile()

  if (self.callback_str == "") then
    LOG("xSandbox: no function was provided")
    return true
  end

  local def = loadstring(self.callback_str)
  self.callback = def()
  setfenv(self.callback, self.env)

  return true

end

-------------------------------------------------------------------------------
-- check for syntax errors
--  (assert provides better error messages)
-- @param str_fn (string) function as string
-- @return boolean, true when passed
-- @return string, when failed

function xSandbox:test_syntax(str_fn)
  --TRACE("xSandbox:test_syntax(str_fn)",#str_fn)

  local function untrusted_fn()
    assert(loadstring(str_fn))
  end
  setfenv(untrusted_fn, self.env)
  local pass,err = pcall(untrusted_fn)
  if not pass then
    return false,err
  end

  return true

end

