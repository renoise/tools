--[[============================================================================
xValue
============================================================================]]--
--[[

	Abstract 'value' class. Use it to represent a value which fit into a 
  particular range, or is of a particular type (e.g. integer/float)

  PLANNED 
    custom tostring, tonumber converters

]]

-------------------------------------------------------------------------------


class 'xValue' (xValue)

function xValue:__init(...)

	local args = xLib.unpack_args(...)

  self.value = property(self.get_value,self.set_value)
  self._value = args.value

  self.max = property(self.get_max,self.set_max)
  self._max = args.max

  self.min = property(self.get_min,self.set_min)
  self._min = args.min

  -- string, just a helpful reminder (e.g. 'velocity')
  self.name = property(self.get_name,self.set_name)
  self._name = args.name

end

-------------------------------------------------------------------------------

function xValue:get_value()
  return self._value
end
function xValue:set_value(val)
  self._value = val
end

-------------------------------------------------------------------------------

function xValue:get_max()
  return self._max
end
function xValue:set_max(val)
  self._max = val
end

-------------------------------------------------------------------------------

function xValue:get_min()
  return self._min
end
function xValue:set_min(val)
  self._min = val
end

-------------------------------------------------------------------------------

function xValue:get_name()
  return self._name
end
function xValue:set_name(val)
  self._name = val
end

-------------------------------------------------------------------------------

function xValue:__tostring()
  return type(self)..": "
    .."value="..tostring(self.value)
    ..", min="..tostring(self.min)
    ..", max="..tostring(self.max)
    ..", name="..tostring(self.name)

end

