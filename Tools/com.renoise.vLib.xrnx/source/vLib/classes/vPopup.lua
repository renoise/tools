--[[============================================================================
main.lua
============================================================================]]--

--[[--

TODO 
  * items/value
  * midi mapping
  * default message

--]]

--==============================================================================

require (_vlibroot.."vControl")

class 'vPopup' (vControl)

function vPopup:__init(...)
  TRACE("vPopup:__init()")

  local args = cLib.unpack_args(...)

  --- (table), 
  self.items = property(self.get_items,self.set_items)
  self._items = args.items or {"Foo","Bar"}

  self.value = property(self.get_value,self.set_value)
  self._value = args.value or 1

  vControl.__init(self,...)
  self:build()

end

--------------------------------------------------------------------------------

function vPopup:build()
  TRACE("vPopup:build()")

  local vb = self.vb

  self.view = vb:popup{
    id = self.id,
    items = self._items,
  }
  
  vControl.build(self)

  self:request_update()

end

--------------------------------------------------------------------------------

function vPopup:update()
  TRACE("vPopup:update()")


end

--------------------------------------------------------------------------------

function vPopup:set_active(val)
  assert(type(val)=="boolean")
  self.view.active = val
  vControl.set_active(self,val)
end


--------------------------------------------------------------------------------

function vPopup:set_items(val)
  assert(type(val)=="table")
  self._items = val
  self.view.items = val
end

function vPopup:get_items()
  return self._items
end

--------------------------------------------------------------------------------

function vPopup:set_value(val)
  assert(type(val)=="number")
  self._value = val
  self.view.value = val
end

function vPopup:get_value()
  return self._value
end

