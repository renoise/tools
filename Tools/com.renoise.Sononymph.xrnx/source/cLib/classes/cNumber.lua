--[[============================================================================
cNumber
============================================================================]]--

--[[--

Extend standard number with min/max and polarity.

## 
A good base class for e.g. device parameters, which it is modelled over

]]

-------------------------------------------------------------------------------


require (_clibroot.."cValue")

class 'cNumber' (cValue)

cNumber.POLARITY = {
  UNIPOLAR = 1,
  BIPOLAR = 2,
}

-------------------------------------------------------------------------------

function cNumber:__init(...)
  TRACE("cNumber:__init(...)")

  local args = cLib.unpack_args(...)

  --- cNumber.POLARITY
  self.polarity = args.polarity or cNumber.POLARITY.UNIPOLAR

  --- number
  self.value_min = args.value_min or 0

  --- number
  self.value_max = args.value_max or 1

  --- number, value of 1 means integer
  self.value_quantum = args.value_quantum or nil

  --- table, strings representing enum states
  -- (only relevant when integer)
  self.value_enums = args.value_enums or nil

  --- number, how to scale value - '1' with factor of 100 becomes '100'
  -- this is relevant for some values that are represented differently
  -- than their actual value (e.g. 'phrase.shuffle')
  self.value_factor = args.value_factor or 1

  --- function, when defined also define value_tonumber 
  self.value_tostring = args.value_tostring or nil

  --- function, when defined also define value_tostring 
  self.value_tonumber = args.value_tonumber or nil

  --- bool, when value starts from zero
  -- (it should be used for display purposes only)
  self.zero_based = (type(args.zero_based)=="boolean") and args.zero_based or false

  -- initialize --

  cValue.__init(self,...)

end

-------------------------------------------------------------------------------

function cNumber:add(val)
  self:set_value(self._value+val)
end

function cNumber:subtract(val)
  self:set_value(self._value-val)
end

function cNumber:multiply(val)
  self:set_value(self._value*val)
end

function cNumber:divide(val)
  self:set_value(self._value/val)
end

-------------------------------------------------------------------------------

function cNumber:set_value(val)
  self._value = cLib.clamp_value(val,self.value_min,self.value_max)
end

-------------------------------------------------------------------------------
-- Meta-methods
-------------------------------------------------------------------------------

function cNumber:__add(val)
  self:add(val)
  return self
end

function cNumber:__sub(val)
  self:subtract(val)
  return self
end

function cNumber:__mul(val)
  self:multiply(val)
  return self
end

function cNumber:__div(val)
  self:divide(val)
  return self
end




