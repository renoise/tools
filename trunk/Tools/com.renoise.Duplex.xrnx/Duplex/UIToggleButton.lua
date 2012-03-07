--[[----------------------------------------------------------------------------
-- Duplex.UIToggleButton
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UIToggleButton
Requires: Globals, Display, MessageStream, CanvasPoint

About 

The UIToggleButton is a button that you can use to control an on/off state.
You can of course use it to represent a button on an external controller, 
but perhaps not so obvious, dial and fader input is also supported,
simply turn the control to it's maximum or minimum to toggle between states.

- Used by multiple core applications (Mixer, Matrix, etc.)
- Minimum unit size: 1x1, otherwise any width/height

Supported input methods

- button
- pushbutton
- togglebutton*
- slider*
- dial*

* hold & release events are not supported for these input methods

Events

- on_change()   - invoked whenever the button change it's active state
- on_press()    - invoked when the button is pressed
- on_release()  - invoked when the button is released
- on_hold()     - invoked when the button is held for a while

Note: the on_change() method will allow you to cancel the event by returning 
false (boolean value) from your custom event handling method. This is useful 
when you want to recieve button presses, but don't want the state to change. 


--]]


--==============================================================================

class 'UIToggleButton' (UIComponent)

function UIToggleButton:__init(display)
  TRACE('UIToggleButton:__init')

  UIComponent.__init(self,display)

  -- initial state is nil (to force drawing)
  self.active = nil

  -- paint inverted (swap fore/background)
  self.inverted = false

  -- specify the default palette 
  self.palette = {
    foreground = table.rcopy(display.palette.color_1),
    background = table.rcopy(display.palette.background)
  }

  -- external event handlers
  self.on_change = nil
  self.on_hold = nil
  self.on_press = nil
  self.on_release = nil

  -- internal stuff
  self._cached_active = nil

  self:add_listeners()

end


--------------------------------------------------------------------------------

-- user input via button
-- @return boolean, true when message was handled

function UIToggleButton:do_press(msg)
  --TRACE("UIToggleButton:do_press")
  
  if not self:test(msg.group_name,msg.column,msg.row) then
    return false
  end

  -- force-update controls that maintain their
  -- internal state (togglebutton, pushbutton)
  if (msg.input_method ~= CONTROLLER_BUTTON) then
    self:force_update()
  end

  local handled = false
  if (self.on_press ~= nil) then
    handled = self:on_press()
  end
  return handled

end

--------------------------------------------------------------------------------

-- user input via button(s)
-- @return boolean, true when message was handled

function UIToggleButton:do_release(msg)
  --TRACE("UIToggleButton:do_release()",msg)

  if not self:test(msg.group_name,msg.column,msg.row) then
    return false
  end

  -- force-update controls that maintain their
  -- internal state (togglebutton, pushbutton)
  if (msg.input_method ~= CONTROLLER_BUTTON) then
    self:force_update()
  end
  local handled = false
  if (self.on_release ~= nil) then
    handled = self:on_release()
  end
  return handled

end

--------------------------------------------------------------------------------

-- user input via fader, dial
-- @return boolean, true when message was handled

function UIToggleButton:do_change(msg)
  --TRACE("UIToggleButton:do_change()")

  if not self:test(msg.group_name,msg.column,msg.row) then
    return false
  end

  if (self.on_change ~= nil) then 
    -- toggle when moved away from min/max values
    if self.active and msg.value < msg.max then
      self:toggle()
    elseif not self.active and msg.value > msg.min then
      self:toggle()
    end
    return true
  end

  return false

end

--------------------------------------------------------------------------------

-- user input via (held) button
-- on_hold() is an optional handler, which is only supported by "button" input
-- @return boolean, true when message was handled

function UIToggleButton:do_hold(msg)
  --TRACE("UIToggleButton:do_hold()",msg)

  if not self:test(msg.group_name,msg.column,msg.row) then
    return 
  end
  local handled = false
  if (self.on_hold ~= nil) then
    handled = self:on_hold()
  end

  return handled

end

--------------------------------------------------------------------------------

-- toggle button state

function UIToggleButton:toggle()
  --TRACE("UIToggleButton:toggle")

  self._cached_active = self.active
  self.active = not self.active
  self:_invoke_handler()

end


--------------------------------------------------------------------------------

-- set button state

function UIToggleButton:set(value,skip_event)
  --TRACE("UIToggleButton:set", value,skip_event)
  if (self.active~=value) then
    if(skip_event)then
      self._cached_active = value
      self.active = value
      self:invalidate()
    else
      self._cached_active = self.active
      self.active = value
      self:_invoke_handler()
    end
  end

end


--------------------------------------------------------------------------------

-- force-update controls that are handling their internal state by themselves,
-- achieved by changing the canvas so that it get's painted the next time...

function UIToggleButton:force_update()

  self.canvas.delta = table.rcopy(self.canvas.buffer)
  self.canvas.has_changed = true
  self:invalidate()

end

--------------------------------------------------------------------------------

-- trigger the external handler method
-- (this can revert changes)

function UIToggleButton:_invoke_handler()

  if (self.on_change == nil) then 
    return 
  end

  local rslt = self:on_change()
  if (rslt==false) then  -- revert
    self.active = self._cached_active
  else
    self:invalidate()
  end
end

--------------------------------------------------------------------------------

-- expand UIComponent test by looking for group name & event handlers
-- (if none are defined, we return false)

function UIToggleButton:test(group_name,column,row)

  if not (self.group_name == group_name) then
    return false
  end

  if (self.on_change == nil) 
    and (self.on_press == nil) 
    and (self.on_release == nil) 
    and (self.on_hold == nil) 
  then  
    return false
  end 

  return UIComponent.test(self,column,row)

end

--------------------------------------------------------------------------------

function UIToggleButton:draw()
  --TRACE("UIToggleButton:draw",self.active)

  local foreground,background,lit

  if(self.inverted)then
    foreground = self.palette.background
    background = self.palette.foreground
    lit = false
  else
    foreground = self.palette.foreground
    background = self.palette.background
    lit = true
  end
  
  local point = CanvasPoint()

  if self.active then
    point:apply(foreground)
    point.val = lit
  else
    point:apply(background)
    point.val = not lit
  end
  self.canvas:fill(point)

  UIComponent.draw(self)

end


--------------------------------------------------------------------------------

function UIToggleButton:add_listeners()

  self._display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_PRESSED,
    function(msg) return self:do_press(msg) end )

  self._display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_RELEASED,
    function(msg) return self:do_release(msg) end )

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_VALUE_CHANGED,
    function(msg) return self:do_change(msg) end )

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_HELD,
    function(msg) return self:do_hold(msg) end )


end


--------------------------------------------------------------------------------

function UIToggleButton:remove_listeners()

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED)

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_VALUE_CHANGED)

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_HELD)


end

