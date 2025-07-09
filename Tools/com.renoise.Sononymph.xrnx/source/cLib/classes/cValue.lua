--[[============================================================================
cValue
============================================================================]]--

--[[--

Abstract value class 
.
#

]]

-------------------------------------------------------------------------------

class 'cValue'

-------------------------------------------------------------------------------

function cValue:__init(...)

  local args = cLib.unpack_args(...)

  if (type(args.value_default)=="nil") 
    and (type(args.value)=="nil") 
  then
    error("cValue needs value_default and/or value to be defined")
  end

  --- (boolean/string/number)
  self.value_default = args.value_default 
    or (type(args.value) == "boolean") and false
    or (type(args.value) == "string") and ""
    or (type(args.value) == "number") and 0

  --- (boolean/string/number)
  self.value = property(self.get_value,self.set_value)

  if (type(args.value)=="boolean") then
    self._value = args.value 
  else
    self._value = args.value or self.value_default 
  end


end

-------------------------------------------------------------------------------

function cValue:get_value()
  return self._value
end

function cValue:set_value(val)
  self._value = val
end

-------------------------------------------------------------------------------
-- Meta-methods
-------------------------------------------------------------------------------
-- not available

--function cValue:__index()
--end

--function cValue:__newindex()
--end

-------------------------------------------------------------------------------
-- when accessing via paranthesis ()

function cValue:__call(key)
  --TRACE("cValue:__call",key)
  
  if not key then
    return self._value
  else
    assert(type(key)=="string")
    return self[key]
  end

end

-------------------------------------------------------------------------------
-- get length (implement for strings, tables)

function cValue:__len()
  --print("cValue:__len")
end

