--[[============================================================================
vCellCheckBox
============================================================================]]--

class 'vCellCheckBox' (vCell)

--------------------------------------------------------------------------------
--- CheckBox support for vCell. See also renoise.Views.CheckBox

vCellCheckBox.DEFAULT_VALUE = false

function vCellCheckBox:__init(...)

  local args = cLib.unpack_args(...)

  -- (bool) checked state
  self._value = args.value or vCellCheckBox.DEFAULT_VALUE
  self.value = property(self.get_value,self.set_value)

  -- (function) callback when state has changed
  -- @param elm (vCellCheckBox)
  self._notifier = args.notifier or nil
  self.notifier = property(self.get_notifier,self.set_notifier)

  -- internal -------------------------

	vCell.__init(self,...)
  self.view = args.vb:checkbox{
    value = self._value,
    notifier = function()
      
      if self._notifier and not self._suppress_notifier then
        self._notifier(self,self.view.value)
      end
    end
  }

	vCell.update(self)

end

--------------------------------------------------------------------------------

function vCellCheckBox:set_value(val,skip_event)
  
  if (type(val) == "nil") then
   val = vCellCheckBox.DEFAULT_VALUE
  end

  self._value = val

  if not skip_event then
    self._suppress_notifier = true
    self.view.value = self.value
    self._suppress_notifier = false
  end

end

function vCellCheckBox:get_value()
  return self._value
end

--------------------------------------------------------------------------------

function vCellCheckBox:set_notifier(fn)
  self._notifier = fn
end

function vCellCheckBox:get_notifier()
  return self._notifier
end


--------------------------------------------------------------------------------

function vCellCheckBox:set_active(val)
  TRACE("vCellCheckBox:set_active(val)",val)

  self.view.active = val
	vControl.set_active(self,val)

end

