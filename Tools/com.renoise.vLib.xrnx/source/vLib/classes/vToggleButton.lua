--[[============================================================================
vToggleButton 
============================================================================]]--
--[[

A basic toggle button

]]

--==============================================================================

require (_vlibroot.."vButton")

class 'vToggleButton' (vButton)

function vToggleButton:__init(...)

  local args = cLib.unpack_args(...)

  self.enabled = property(self.get_enabled,self.set_enabled)
  self.enabled_observable = renoise.Document.ObservableBoolean(args.enabled or false)

  self.text_enabled = property(self.get_text_enabled,self.set_text_enabled)
  self._text_enabled = args.text_enabled or "Enabled"
  self.text_disabled = property(self.get_text_disabled,self.set_text_disabled)
  self._text_disabled = args.text_disabled or "Disabled"

  self.color_enabled = property(self.get_color_enabled,self.set_color_enabled)
  self._color_enabled = args.color_enabled or {0x80,0x80,0x80}
  self.color_disabled = property(self.get_color_disabled,self.set_color_disabled)
  self._color_disabled = args.color_disabled or {0x00,0x00,0x00}

  self.bitmap_enabled = property(self.get_bitmap_enabled,self.set_bitmap_enabled)
  self._bitmap_enabled = args.bitmap_enabled or ""
  self.bitmap_disabled = property(self.get_bitmap_disabled,self.set_bitmap_disabled)
  self._bitmap_disabled = args.bitmap_disabled or ""

  -- internal -------------------------

  vButton.__init(self,...)

end

--------------------------------------------------------------------------------

function vToggleButton:toggle()
  self.enabled = not self.enabled
  vButton.release(self)
end

--------------------------------------------------------------------------------

function vToggleButton:release()
  self:toggle()
end

--------------------------------------------------------------------------------

function vToggleButton:update()
  TRACE("vToggleButton:update()")

  self.color = self.enabled and self.color_enabled or self.color_disabled
  self.text = self.enabled and self.text_enabled or self.text_disabled
  self.bitmap = self.enabled and self.bitmap_enabled or self.bitmap_disabled
  vButton.update(self)

end

--------------------------------------------------------------------------------

function vToggleButton:set_enabled(val)
  assert(type(val)=="boolean")
  self.enabled_observable.value = val
  self:request_update()
end

function vToggleButton:get_enabled()
  return self.enabled_observable.value
end

--------------------------------------------------------------------------------

function vToggleButton:set_text_enabled(val)
  assert(type(val)=="string")
  self._text_enabled = val
  self:request_update()
end

function vToggleButton:get_text_enabled()
  return self._text_enabled
end

--------------------------------------------------------------------------------

function vToggleButton:set_text_disabled(val)
  assert(type(val)=="string")
  self._text_disabled = val
  self:request_update()
end

function vToggleButton:get_text_disabled()
  return self._text_disabled
end

--------------------------------------------------------------------------------

function vToggleButton:set_color_enabled(val)
  assert(type(val)=="table")
  self._color_enabled = val
  self:request_update()
end

function vToggleButton:get_color_enabled()
  return self._color_enabled
end

--------------------------------------------------------------------------------

function vToggleButton:set_color_disabled(val)
  assert(type(val)=="table")
  self._color_disabled = val
  self:request_update()
end

function vToggleButton:get_color_disabled()
  return self._color_disabled
end

--------------------------------------------------------------------------------

function vToggleButton:set_bitmap_enabled(val)
  assert(type(val)=="string")
  self._bitmap_enabled = val
  self:request_update()
end

function vToggleButton:get_bitmap_enabled()
  return self._bitmap_enabled
end

--------------------------------------------------------------------------------

function vToggleButton:set_bitmap_disabled(val)
  assert(type(val)=="string")
  self._bitmap_disabled = val
  self:request_update()
end

function vToggleButton:get_bitmap_disabled()
  return self._bitmap_disabled
end

