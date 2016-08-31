--[[============================================================================
vCellBitmap
============================================================================]]--

class 'vCellBitmap' (vCell)

--------------------------------------------------------------------------------
--- Bitmap button support for vCell. See also renoise.Views.Bitmap

vCellBitmap.DEFAULT_VALUE = nil

function vCellBitmap:__init(...)

  local args = cLib.unpack_args(...)

  -- (string) name and path, specify a relative path that uses  Renoise's
  -- default resource folder as base (like "Icons/ArrowRight.bmp"). Or specify 
  -- a file relative from your XRNX tool bundle
  self._bitmap = args.bitmap or vLib.DEFAULT_BMP
  self.bitmap = property(self.get_bitmap,self.set_bitmap)

  -- (enum) drawing mode, Available modes are:
  -- >  "plain"        -> bitmap is drawn as is, no recoloring is done  
  -- >  "transparent"  -> same as plain, but black pixels will be fully transparent  
  -- >  "button_color" -> recolor the bitmap, using the theme's button color  
  -- >  "body_color"   -> same as 'button_back' but with body text/back color  
  -- >  "main_color"   -> same as 'button_back' but with main text/back colors
  self._mode = args.mode or "transparent"
  self.mode = property(self.get_mode,self.set_mode)

  -- (function) handle mouse clicks on bitmap
  -- @param elm (vCellBitmap)
  self.notifier = property(self.get_notifier,self.set_notifier)
  self._notifier = args.notifier or nil

  -- internal -------------------------

	vCell.__init(self,...)
  self.view = args.vb:bitmap{
    bitmap = self._bitmap,
    mode = self._mode,
    notifier = function()
      if self._notifier then
        self._notifier(self)
      end
    end,
  }

	vCell.update(self)

end

--------------------------------------------------------------------------------
-- @return string

function vCellBitmap:get_value()
  return self.bitmap
end

--------------------------------------------------------------------------------

function vCellBitmap:set_value(str)
  self:set_bitmap(str)
end

--------------------------------------------------------------------------------
-- @param str (vCellBitmap.bitmap)

function vCellBitmap:set_bitmap(str)
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

function vCellBitmap:get_bitmap(str)
  return self._bitmap
end

--------------------------------------------------------------------------------
-- @param str (vCellBitmap.mode)

function vCellBitmap:set_mode(str)
  TRACE("vCellBitmap:set_mode(str)",str)
  self._mode = str
  self.view.mode = str
	vCell.update(self)
end

function vCellBitmap:get_mode(str)
  return self._mode
end

--------------------------------------------------------------------------------

function vCellBitmap:set_notifier(fn)
  self._notifier = fn
end

function vCellBitmap:get_notifier()
  return self._notifier
end


--------------------------------------------------------------------------------

function vCellBitmap:set_active(val)
  TRACE("vCellBitmap:set_active(val)",val)

  self.view.active = val
	vControl.set_active(self,val)

end
