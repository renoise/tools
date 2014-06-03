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

function UIButton:__init(app)
  TRACE('UIButton:__init')

  UIComponent.__init(self,app)

  self.palette = {
    foreground = {
      color = {0x00,0x00,0x80},
      text = "",
      val = false
    }
  }

  -- external event handlers
  self.on_change = nil
  self.on_hold = nil
  self.on_press = nil
  self.on_release = nil

  self:add_listeners()

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
    if (msg.input_method ~= INPUT_TYPE.BUTTON) then
      self:force_update()
    end
    self:on_press()
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
  if (msg.input_method ~= INPUT_TYPE.BUTTON) then
    self:force_update()
  end

  if (self.on_release ~= nil) then
    self:on_release()
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

--- Expanded UIComponent test. Look for group name + standard test
-- @param msg (@{Duplex.Message})
-- @return (bool), false when criteria is not met
-- @see Duplex.UIComponent.test

function UIButton:test(msg)

  if not (self.group_name == msg.group_name) then
    return false
  end

  if not self.app.active then
    return
  end

  return UIComponent.test(self,msg.column,msg.row)

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
  --TRACE("UIButton:draw()")

  local point = CanvasPoint()
  point.color = self.palette.foreground.color
  point.text = self.palette.foreground.text
  point.val = self.palette.foreground.val

  -- if value has not been explicitly set, use the
  -- avarage color (0x80+) to determine lit state 
  if not type(point.val)=="boolean" then
    if(get_color_average(self.palette.foreground.color)>0x7F)then
      point.val = true        
    else
      point.val = false        
    end
  end

  self.canvas:fill(point)
  UIComponent.draw(self)

end

--------------------------------------------------------------------------------

--- Force the button to update: some controllers handle their internal state 
-- by themselves, and as a result, we never know their actual state. For those
-- controls, we "force-update" them by changing the canvas so that it always 
-- get output the next time the display is updated

function UIButton:force_update()
  TRACE("UIButton:force_update()")

  self.canvas.delta = table.rcopy(self.canvas.buffer)
  self.canvas.has_changed = true
  self:invalidate()

end

--------------------------------------------------------------------------------

--- Add event listeners to the button
--    DEVICE_EVENT.BUTTON_PRESSED
--    DEVICE_EVENT.BUTTON_RELEASED
--    DEVICE_EVENT.VALUE_CHANGED
--    DEVICE_EVENT.BUTTON_HELD
-- @see Duplex.UIComponent.add_listeners

function UIButton:add_listeners()

  self.app.display.device.message_stream:add_listener(
    self, DEVICE_EVENT.BUTTON_PRESSED,
    function(msg) return self:do_press(msg) end )

  self.app.display.device.message_stream:add_listener(
    self, DEVICE_EVENT.BUTTON_RELEASED,
    function(msg) return self:do_release(msg) end )

  self.app.display.device.message_stream:add_listener(
    self,DEVICE_EVENT.VALUE_CHANGED,
    function(msg) return self:do_change(msg) end )

  self.app.display.device.message_stream:add_listener(
    self,DEVICE_EVENT.BUTTON_HELD,
    function(msg) self:do_hold(msg) end )


end


--------------------------------------------------------------------------------

--- Remove previously attached event listeners
-- @see Duplex.UIComponent

function UIButton:remove_listeners()

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.BUTTON_PRESSED)

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.BUTTON_RELEASED)

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.VALUE_CHANGED)

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.BUTTON_HELD)


end

