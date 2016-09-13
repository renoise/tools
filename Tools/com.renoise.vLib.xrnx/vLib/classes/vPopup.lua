--[[============================================================================
main.lua
============================================================================]]--

--[[--

TODO 
  * midi mapping
  * default message

--]]

--==============================================================================

class 'vPopup' (vControl)

function vPopup:__init(...)
  TRACE("vPopup:__init()")

  local args = cLib.unpack_args(...)

  --- (table), 
  self.items = property(self.get_items,self.set_items)
  self._items = args.items or {"Foo","Bar"}

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

