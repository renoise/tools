--[[============================================================================
vButton 
============================================================================]]--
--[[

A basic button

]]

--==============================================================================

require (_vlibroot.."vControl")

class 'vButton' (vControl)

--------------------------------------------------------------------------------

function vButton:__init(...)
  TRACE("vButton:__init()")

  local args = cLib.unpack_args(...)

  -- properties -----------------------

  self.text = property(self.get_text,self.set_text)
  self._text = args.text or ""

  self.bitmap = property(self.get_bitmap,self.set_bitmap)
  self._bitmap = args.bitmap or ""

  self.color = property(self.get_color,self.set_color)
  self._color = args.color or {0x00,0x00,0x00}

  -- specify defaults
  args.width = args.width or 20
  args.height = args.height or vLib.CONTROL_H

  -- methods --------------------------

  self.pressed = args.pressed or nil
  self.released = args.released or nil
  self.notifier = args.notifier or nil

  -- initialize -----------------------

  vControl.__init(self,...)

  self:build()

  -- TODO investigate returning view in constructor
  -- (declare within viewbuilder structures)
  --return self.view

end

--------------------------------------------------------------------------------

function vButton:build()
  TRACE("vButton:build()")

	local vb = self.vb
  if not self.view then
    self.view = vb:button{
      id = self.id,
      pressed = function()
        self:press()
      end,
      released = function()
        self:release()
      end,
    }
  end
  self:request_update()
end

--------------------------------------------------------------------------------

function vButton:press()
  if self.pressed then
    self:pressed()
  end
end

--------------------------------------------------------------------------------

function vButton:release()
  TRACE("vButton:release()")

  if self.released then
    self:released()
  end
  if self.notifier then
    self:notifier()
  end
end

--------------------------------------------------------------------------------

function vButton:update()
  TRACE("vButton:update()")

  if self.text then self.view.text = self.text end
  if self.color then self.view.color = self.color end
  if self.bitmap then self.view.bitmap = self.bitmap end
  if self.midi_mapping then self.view.midi_mapping = self.midi_mapping end
  if self._width then self.view.width = self._width end
  if self._height then self.view.height = self._height end

end

--------------------------------------------------------------------------------

function vButton:set_active(b)
  self.view.active = b
end

--------------------------------------------------------------------------------

function vButton:set_text(val)
  assert(type(val)=="string")
  self._text = val
  self.view.text = val
end

function vButton:get_text()
  return self._text
end

--------------------------------------------------------------------------------

function vButton:set_bitmap(val)
  assert(type(val)=="string")
  self._bitmap = val
  self.view.bitmap = val
end

function vButton:get_bitmap()
  return self._bitmap
end

--------------------------------------------------------------------------------

function vButton:set_color(val)
  assert(type(val)=="table")
  self._color = val
  self.view.color = val
end

function vButton:get_color()
  return self._color
end

--------------------------------------------------------------------------------

function vButton:set_midi_mapping(val)
  assert(type(val)=="string")
  vControl.set_midi_mapping(self,val)
  self.view.midi_mapping = val
end

--------------------------------------------------------------------------------

function vButton:set_width(val)
  TRACE("vButton:set_width(val)")

  assert(type(val)=="number")
  self.view.width = val
  vControl.set_width(self)
end

--------------------------------------------------------------------------------

function vButton:set_height(val)
  TRACE("vButton:set_height(val)")

  assert(type(val)=="number")
  self.view.height = val
  vControl.set_height(self)
end

