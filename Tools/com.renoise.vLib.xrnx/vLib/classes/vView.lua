--[[============================================================================
vView
============================================================================]]--

class 'vView' 

--------------------------------------------------------------------------------
--- vView is the base class for child views in the vLib library

function vView:__init(...)

  local args = cLib.unpack_args(...)

  -- required -------------------------

  if not args.vb then
    error("vView: missing reference to vb (ViewBuilder) in constructor method")
  end
  
  -- constructor only  ----------------

  --- (ViewBuilder) required constructor argument
  self.vb = args.vb

  --- (string) view id, optional constructor argument
  self.id = property(function() return self._id end)
  self._id = args.id

  -- properties -----------------------

  --- (bool, r/w) visible property 
  self.visible = property(self.get_visible, self.set_visible)
  self._visible = args.visible or true 

  --- (int, r/w) width property
  self.width = property(self.get_width, self.set_width)
  self._width = args.width or nil

  --- (int, r/w) height property
  self.height = property(self.get_height, self.set_height)
  self._height = args.height or nil

  --- (string, r/w) tooltip property 
  -- note: when nil is specified, tooltip is removed
  self.tooltip = property(self.get_tooltip, self.set_tooltip)
  self._tooltip = args.tooltip or ""

  -- internal 

  --- (renoise.Views.Rack) implementation will define the view
  self.view = nil


end

--------------------------------------------------------------------------------

function vView:set_tooltip(str)
  if str then
    self._tooltip = tostring(str)
  else
    self._tooltip = ""
  end
  if self.view then
    self.view.tooltip = self._tooltip
  end
end

function vView:get_tooltip(a)
  return self._tooltip
end

--------------------------------------------------------------------------------

function vView:set_visible(val)
  self._visible = (val) and true or false
  if self.view then
    self.view.visible = self._visible
  end
end

function vView:get_visible()
  return self._visible
end

--------------------------------------------------------------------------------

function vView:set_width(val)
  self._width = val
  if val and self.view then
    self.view.width = val
  end
end

function vView:get_width()
  return self._width
end

--------------------------------------------------------------------------------

function vView:set_height(val)
  self._height = val
  if val and self.view then
    self.view.height = val
  end
end

function vView:get_height()
  return self._height
end

