--[[============================================================================
vCellPopup
============================================================================]]--

class 'vCellPopup' (vCell)

--------------------------------------------------------------------------------
---	Popup support for vCell. See also renoise.Views.Popup

vCellPopup.DEFAULT_VALUE = 1

function vCellPopup:__init(...)

  local args = cLib.unpack_args(...)

  -- (table>string)
  self.items = property(self.get_items,self.set_items)

  -- (int)
  self._value = args.value or nil
  self.value = property(self.get_value,self.set_value)

  -- (function) handle when popup value has changed
  -- @param elm (vCellPopup)
  self._notifier = args.notifier or nil
  self.notifier = property(self.get_notifier,self.set_notifier)

  -- initialize

	vCell.__init(self,...)
  self.view = args.vb:popup{
    items = args.items or {},
    value = self._value,
    notifier = function()
      self._value = self.view.value
      if self._notifier and not self._suppress_notifier then
        self._notifier(self,self.view.value)
      end
    end,
  }

	vCell.update(self)

end

--------------------------------------------------------------------------------

function vCellPopup:set_value(val,skip_event)
  TRACE("vCellPopup:set_value(val)",val)

  if (type(val) == "nil") then
   val = vCellPopup.DEFAULT_VALUE
  end

  self._value = val

  if not skip_event then
    self._suppress_notifier = true
    self.view.value = val
    self._suppress_notifier = false
  end

	vCell.update(self)

end

function vCellPopup:get_value()
  return self._value
end

--------------------------------------------------------------------------------

function vCellPopup:set_items(tbl)
  self.view.items = tbl
end

function vCellPopup:get_items()
  return self.view.items
end

--------------------------------------------------------------------------------

function vCellPopup:set_notifier(fn)
  self._notifier = fn
end

function vCellPopup:get_notifier()
  return self._notifier
end

--------------------------------------------------------------------------------

function vCellPopup:set_active(val)

  self.view.active = val
	vControl.set_active(self,val)

end

