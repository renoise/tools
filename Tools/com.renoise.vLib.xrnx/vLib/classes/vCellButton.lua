--[[============================================================================
vCellButton
============================================================================]]--

class 'vCellButton' (vCell)

--------------------------------------------------------------------------------
---	Button support for vCell. See also renoise.Views.Button

function vCellButton:__init(...)

  local args = cLib.unpack_args(...)

  -- (string)
  self._text = args.text or ""
  self.text = property(self.get_text,self.set_text)

  -- (string) name and path, specify a relative path that uses  Renoise's
  -- default resource folder as base (like "Icons/ArrowRight.bmp"). Or specify 
  -- a file relative from your XRNX tool bundle
  self._bitmap = args.bitmap or nil
  self.bitmap = property(self.get_bitmap,self.set_bitmap)

  -- (function) Handle mouse-press + release
  -- @param elm (vCellValueBox)
  self._notifier = args.notifier or nil
  self.notifier = property(self.get_notifier,self.set_notifier)

  -- (function) Handle mouse-pressed events
  -- @param elm (vCellButton)
  self._pressed = args.pressed or nil
  self.pressed = property(self.get_pressed,self.set_pressed)

  -- (function) Handle mouse-released events
  -- @param elm (vCellButton)
  self._released = args.released or nil
  self.released = property(self.get_released,self.set_released)

  -- (table) Table of R,G,B colors 
  self._color = args.color or {0,0,0}
  self.color = property(self.get_color,self.set_color)

  -- internal -------------------------

  self._display_text = nil

	vCell.__init(self,...)
  self.view = args.vb:button{
    text = self._text,
    bitmap = self.bitmap,
    pressed = function() 
      if self._pressed then
        self._pressed(self,self.view.text)
      end
    end,
    released = function() 
      if self._released then
        self._released(self,self.view.text)
      end
    end,
    notifier = function() 
      if self._notifier then
        self._notifier(self,self.view.text)
      end
    end,
    color = self._color,
  }


	vCell.update(self)


end

--------------------------------------------------------------------------------

function vCellButton:set_value(str)
  self:set_text(str)
end

function vCellButton:get_value()
  return self:get_text()
end

--------------------------------------------------------------------------------

function vCellButton:set_text(str)
  TRACE("vCellButton:set_text(str)",str)

  if not self._display_text or (str ~= self._text) then
    self._text = str
    str = tostring(str)
    if self.transform then
      str = self.transform(str,self)
    end
    self.view.text = str
    self._display_text = str
  else
    -- "lazy" update
    self.view.text = self._display_text
  end

  vCell.update(self)

end

function vCellButton:get_text()
  return self._text 
end

--------------------------------------------------------------------------------
-- @param str (vCellButton.bitmap)

function vCellButton:set_bitmap(str)
  self._bitmap = str
  if not str then
    return
  end
  if self.transform then
    str = self.transform(str)
  end
  self.view.bitmap = str
	vCell.update(self)
end

function vCellButton:get_bitmap(str)
  return self._bitmap
end

--------------------------------------------------------------------------------

function vCellButton:set_color(t)
  self._color = t
  self.view.color = t
	vCell.update(self)
end

function vCellButton:get_color()
  return self._color
end

--------------------------------------------------------------------------------

function vCellButton:set_released(fn)
  self._released = fn
end

function vCellButton:get_released()
  return self._released
end

--------------------------------------------------------------------------------

function vCellButton:set_notifier(fn)
  self._notifier = fn
end

function vCellButton:get_notifier()
  return self._notifier
end

--------------------------------------------------------------------------------

function vCellButton:set_pressed(fn)
  self._pressed = fn
end

function vCellButton:get_pressed()
  return self._pressed
end

--------------------------------------------------------------------------------

function vCellButton:set_active(val)
  self.view.active = val
	vControl.set_active(self,val)
end
