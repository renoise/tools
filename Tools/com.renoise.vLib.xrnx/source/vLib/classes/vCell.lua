--[[============================================================================
vCell 
============================================================================]]--

class 'vCell' (vControl)
--------------------------------------------------------------------------------
---	Base class for cells (vTable, vTree...)

vCell.DEFAULT_VALUE = nil

function vCell:__init(...)

  local args = cLib.unpack_args(...)

  --assert(type(args.item_id)=="number")

  --- (int) the data record id associated with this cell
  -- it is the responsibility of the owner to assign this property 
  self.item_id = args.item_id

  --- (vTable) reference to the table which holds this cell
  self.owner = args.owner

  --- (function) callback, transform the displayed value somehow
  -- @param val (variant)
  self.transform = nil

  -- internal -------------------------

  -- (bool) true while performing programmatic updates
  self._suppress_notifier = false

	vControl.__init(self,...)

end

--------------------------------------------------------------------------------
-- @return variant, depends on class

function vCell:get_value()

  LOG("Unimplemented method: get_value()")

end

--------------------------------------------------------------------------------
-- programmatic updates are performed through this method
-- @param val (variant)
-- @param skip_event (bool) don't fire any events 

function vCell:set_value(val,skip_event)

  LOG("Unimplemented method: set_value()")

end


--------------------------------------------------------------------------------
-- after updating certain properties, the component might change size
-- (for example, text will expand it's size when the "style" property is set)
-- counteract by calling this method after changing the property

function vCell:update()

  if self._width then
    self.view.width = self._width
  end
  if self._height then
    self.view.height = self._height
  end

end



