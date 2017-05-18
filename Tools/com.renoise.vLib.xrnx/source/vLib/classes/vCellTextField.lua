--[[============================================================================
vCellTextField 
============================================================================]]--

class 'vCellTextField' (vCell)

--------------------------------------------------------------------------------
---	Textfield support for vCell. See also renoise.Views.Textfield

vCellTextField.DEFAULT_VALUE = 0

function vCellTextField:__init(...)

  local args = cLib.unpack_args(...)

  -- (number)
  self._text = args.value or ""
  self.text = property(self.get_text,self.set_text)

  -- (function) callback when value has changed
  -- @param elm (vCellTextField)
  self.notifier = nil

  -- internal -------------------------

	vCell.__init(self,...)

  self.view = args.vb:textfield{
    text = self._text, 
    notifier = function()
      if self.notifier and not self._suppress_notifier then
        self.notifier(self,self.view.text)
      end
    end
  }

	vCell.update(self)

end

--------------------------------------------------------------------------------

function vCellTextField:set_value(str)
  self:set_text(str)
end

function vCellTextField:get_value()
  return self._text
end


--------------------------------------------------------------------------------
-- @param val (number)

function vCellTextField:get_text()
  return self._text
end

function vCellTextField:set_text(val,skip_event)

  self._text = val
  
  if not skip_event then
    self._suppress_notifier = true
    self.view.text = val or ""
    self._suppress_notifier = false
  end
  
	vCell.update(self)

end

--------------------------------------------------------------------------------

function vCellTextField:set_active(val)

  self.view.active = val
	vControl.set_active(self,val)

end
