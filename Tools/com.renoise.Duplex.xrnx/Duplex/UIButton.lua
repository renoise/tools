--[[============================================================================
-- Duplex.UIButton
-- Inheritance: UIComponent > UIButton
============================================================================]]--

--[[--
The UIButton is a generic button. It is very flexible, as you can assign any button type, fader or dial to control it
     __________ __________ _______________
    |   ____   |    __    |               |
    |  / __ \  |   |  |   |   ____        |
    | / /  \ \ |   |  |   |  |    |       |
    | \ \__/ / |   |__|   |  | // |       |
    |  \/___/  |   |__|   |  |____|       |
    |          |          |               |
    |  Dial    |  Fader   |  Button       |
    |          |          |  PushButton   |
    |          |          |  ToggleButton |
    |__________|__________|_______________|

It has no internal "active" or "enabled" state, it merely tells you when an event has occurred. Then, it is up to you to change it's visual state. 

--]]

--==============================================================================

class 'UIButton' (UIComponent)

--------------------------------------------------------------------------------

--- Initialize the UIButton class
-- @param app (@{Duplex.Application})
-- @param map[opt] (table) mapping properties 

function UIButton:__init(app,map)
  TRACE('UIButton:__init')

  UIComponent.__init(self,app,map)

  --- (table) the visual appearance, changed via @{set}
  -- @field foreground (table) 
  --    color (table) - {int,int,int}
  --    text (string)
  --    val (bool)
  -- @table palette
  self.palette = {
    foreground = {
      color = {0x00,0x00,0x80},
      text = "",
      val = false
    }
  }

  --- (func) event handler
  self.on_change = nil

  --- (func) event handler
  self.on_hold = nil

  --- (func) event handler
  self.on_press = nil

  --- (func) event handler
  self.on_release = nil


end


--------------------------------------------------------------------------------

--- User pressed button
-- @param msg (@{Duplex.Message})
-- @return (bool), true when message was handled

function UIButton:do_press(msg)
  TRACE("UIButton:do_press")
  
  if not self:test(msg) then
    return
  end

  if (self.on_press ~= nil) then
    -- force-update controls that maintain their
    -- internal state (togglebutton, pushbutton)
    if (msg.xarg.type ~= "button") then
      self:force_refresh()
    end
    self:on_press(msg)
    return self
  end

end

--------------------------------------------------------------------------------

--- User released button
-- @param msg (@{Duplex.Message})
-- @return (bool), true when message was handled

function UIButton:do_release(msg)
  TRACE("UIButton:do_release()")

  if not self:test(msg) then
    return
  end
  
  -- force-update controls that maintain their
  -- internal state (togglebutton, pushbutton)
  if (msg.xarg.type ~= "button") then
    self:force_refresh()
  end

  if (self.on_release ~= nil) then
    self:on_release(msg)
    return self
  end

end

--------------------------------------------------------------------------------

--- User changed value via fader, dial ...
-- @param msg (@{Duplex.Message})
-- @return (bool), true when message was handled

function UIButton:do_change(msg)
  TRACE("UIButton:do_change()")

  if not self:test(msg) then
    return
  end

  if (self.on_change ~= nil) then
    self:on_change(msg.value)
    return self
  end

end

--------------------------------------------------------------------------------

--- User held button for a while (exact time is specified in preferences).
--  Note that this event is only supported by controllers that transmit the 
--  "release" event
-- @param msg (@{Duplex.Message})

function UIButton:do_hold(msg)
  TRACE("UIButton:do_hold()")

  if not self:test(msg) then
    return
  end

  if (self.on_hold ~= nil) then
    self:on_hold()
  end

end


--------------------------------------------------------------------------------

--- method for setting the palette 
-- @param val (table), new color/text values

function UIButton:set(val)
  TRACE("UIButton:set()",val)

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

--- Easy way to animate the appearance of the button
-- @param delay (number) number of seconds between updates
-- @param ... (vararg) palette entries

function UIButton:flash(delay, ...)
  TRACE("UIButton:flash()",delay,arg)

  self.app.display.scheduler:remove_task(self._task)
  for i,args in ipairs(arg) do
    if (i==1) then
      self:set(arg[i]) -- set first one at once
    else
      self._task = self.app.display.scheduler:add_task(
        self, UIButton.set_palette, delay*(i-1), {foreground=arg[i]})
        --self, UIButton.set, delay*(i-1), arg[i])
    end
  end

end

--------------------------------------------------------------------------------

--- Update the appearance - inherited from UIComponent
-- @see Duplex.UIComponent

function UIButton:draw()
  TRACE("UIButton:draw()")

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

--------------------------------------------------------------------------------

--- Add event listeners to the button
--    DEVICE_EVENT.BUTTON_PRESSED
--    DEVICE_EVENT.BUTTON_RELEASED
--    DEVICE_EVENT.VALUE_CHANGED
--    DEVICE_EVENT.BUTTON_HELD
-- @see Duplex.UIComponent.add_listeners

function UIButton:add_listeners()
  TRACE("UIButton:add_listeners()")

  self:remove_listeners()

  if self.on_press then
    self.app.display.device.message_stream:add_listener(
      self, DEVICE_EVENT.BUTTON_PRESSED,
      function(msg) return self:do_press(msg) end )
  end

  if self.on_release then
    self.app.display.device.message_stream:add_listener(
      self, DEVICE_EVENT.BUTTON_RELEASED,
      function(msg) return self:do_release(msg) end )
  end

  if self.on_hold then
    self.app.display.device.message_stream:add_listener(
      self,DEVICE_EVENT.BUTTON_HELD,
      function(msg) self:do_hold(msg) end )
  end

  if self.on_change then
    self.app.display.device.message_stream:add_listener(
      self,DEVICE_EVENT.VALUE_CHANGED,
      function(msg) return self:do_change(msg) end )  
  end

end


--------------------------------------------------------------------------------

--- Remove previously attached event listeners
-- @see Duplex.UIComponent

function UIButton:remove_listeners()
  TRACE("UIButton:remove_listeners()")

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.BUTTON_PRESSED)

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.BUTTON_RELEASED)

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.VALUE_CHANGED)

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.BUTTON_HELD)


end

