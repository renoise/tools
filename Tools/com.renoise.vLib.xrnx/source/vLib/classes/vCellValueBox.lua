--[[============================================================================
vCellValueBox 
============================================================================]]--

class 'vCellValueBox' (vCell)

--------------------------------------------------------------------------------
---	ValueBox support for vCell. See also renoise.Views.ValueBox

vCellValueBox.DEFAULT_VALUE = 0

function vCellValueBox:__init(...)

  local args = cLib.unpack_args(...)

  -- (number)
  self._value = args.value or 0
  self.value = property(self.get_value,self.set_value)

  -- (int)
  self._min = args.min or 0
  self.min = property(self.get_min,self.set_min)

  -- (int)
  self._max = args.max or 100
  self.max = property(self.get_max,self.set_max)

  self.tonumber = vCellValueBox._default_tonumber
  self.tostring = vCellValueBox._default_tostring

  -- (function) callback when value has changed
  -- @param elm (vCellValueBox)
  self.notifier = nil

  -- internal -------------------------

	vCell.__init(self,...)

  self.view = args.vb:valuebox{
    notifier = function()
      if self.notifier and not self._suppress_notifier then
        self.notifier(self,self.view.value)
      end
    end,
    tostring = function(val)
      return self:tostring(val)
    end,
    tonumber = function(val)
      return self:tonumber(val)
    end
  }

	vCell.update(self)

end

--------------------------------------------------------------------------------
-- @param val (number)

function vCellValueBox:get_value()
  return self._value
end

function vCellValueBox:set_value(val,skip_event)

  if (type(val) == "nil") then
   val = vCellValueBox.DEFAULT_VALUE
  end

  if (type(val) ~= "number") then
    error("vCellValueBox accepts only number values")
  end

  self._value = val

  if not skip_event then
    self._suppress_notifier = true
    self.view.value = val
    self._suppress_notifier = false
  end

	vCell.update(self)

end

--------------------------------------------------------------------------------

function vCellValueBox:get_min()
  return self._min 
end

function vCellValueBox:set_min(val)
  TRACE("vCellValueBox:set_active(val)",val)
  self._min = val
  self.view.min = val
	vCell.update(self)
end

--------------------------------------------------------------------------------

function vCellValueBox:get_max()
  return self._max 
end

function vCellValueBox:set_max(val)
  TRACE("vCellValueBox:set_active(val)",val)
  self._max = val
  self.view.max = val
	vCell.update(self)
end

--------------------------------------------------------------------------------

function vCellValueBox:set_active(val)

  self.view.active = val
	vControl.set_active(self,val)

end

--------------------------------------------------------------------------------
-- Static methods
--------------------------------------------------------------------------------

function vCellValueBox._default_tonumber(self,val)
  local num = tonumber(val)
  if num then
    return ("¤%d"):format(num)
  end
end

--------------------------------------------------------------------------------

function vCellValueBox._default_tostring(self,val)
  return ("%d"):format(val)
end

