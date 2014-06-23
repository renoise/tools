--[[============================================================================
-- Duplex.UILabel
-- Inheritance: UIComponent > UILabel
============================================================================]]--

--[[--
UILabel is a component designed for basic text display

--]]

--==============================================================================


class 'UILabel' (UIComponent)

--------------------------------------------------------------------------------

--- Initialize the UILabel class
-- @param app (@{Duplex.Application})
-- @param map[opt] (table) mapping properties 

function UILabel:__init(app,map)
  TRACE("UILabel:__init()",app,map)

  self._text = ""

	UIComponent.__init(self,app,map)

end

--------------------------------------------------------------------------------

function UILabel:set_text(str_text)
  TRACE("UILabel:_set_text()",str_text)

  str_text = tostring(str_text)

  if (str_text ~= self._text) then
    self._text = str_text
    local point = CanvasPoint()
    point.val = str_text
    self.canvas:write(point,1,1)
    self:invalidate()
  end

end

--------------------------------------------------------------------------------
