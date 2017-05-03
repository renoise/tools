--[[============================================================================
-- Duplex.UILed
-- Inheritance: UIComponent > UILed
============================================================================]]--

--[[--
The UILed is a simple control with no internal state, and no events.
It's entirely up to you to control its visual state via set()

--]]

--==============================================================================

class 'UILed' (UIComponent)


--------------------------------------------------------------------------------
-- Initialize the UILed class
-- @param app (@{Duplex.Application})
-- @param map[opt] (table) mapping properties 

function UILed:__init(app,map)
  TRACE('UILed:__init')

  UIComponent.__init(self,app,map)

  -- @table palette
  self.palette = {
    foreground = {
      color = {0x00,0x00,0x80},
      text = nil,--"",
      val = false
    }
  }

  UIComponent.disable(self)

end


--------------------------------------------------------------------------------
-- method for setting the palette 
-- @param val (table), new color/text values

function UILed:set(val)
  TRACE("UILed:set()",val)

  if not val then
    return
  end

  -- if an animated sequence was previously defined, 
  -- this task is removed before we proceed
  if self._task then
    self.app.display.scheduler:remove_task(self._task)
  end

  UIComponent.set_palette(self,{foreground=val})

end

--------------------------------------------------------------------------------
-- Update the appearance - inherited from UIComponent
-- @see Duplex.UIComponent

function UILed:draw()
  TRACE("UILed:draw()")

  local point = CanvasPoint()
  point.color = self.palette.foreground.color
  point.text = self.palette.foreground.text
  point.val = self.palette.foreground.val

  -- if value has not been explicitly set, use the
  -- avarage color (0x80+) to determine lit state 
  if not type(point.val)=="boolean" then
    if(cColor.get_average(self.palette.foreground.color)>0x7F)then
      point.val = true        
    else
      point.val = false        
    end
  end

  self.canvas:fill(point)

  UIComponent.draw(self)

end

