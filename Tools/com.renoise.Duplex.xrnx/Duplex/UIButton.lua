--[[----------------------------------------------------------------------------
-- Duplex.UIButton
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UIButton

About 

  The UIButton is a generic button that accept a wide range of input methods,
  as you can assign any button type, fader or dial to control it.


Events

- on_change()   - invoked when a slider/dial is changed
- on_press()    - invoked when the button is pressed
- on_release()  - invoked when the button is released
- on_hold()     - invoked when the button is held for a while*

* The amount of time is specified in the preferences (Globals.lua)

  Each input method may or may not support specific events. See this table:

                  | on_change | on_press |  on_release | on_hold
  ----------------+-----------+----------+-------------+----------
  - button        |           |     X    |       X     |    X
  - pushbutton    |           |     X    |             |
  - togglebutton  |           |     X    |             |
  - fader         |    X      |          |             |
  - dial          |    X      |          |             |



--]]


--==============================================================================

class 'UIButton' (UIComponent)

function UIButton:__init(display)
  TRACE('UIButton:__init')

  UIComponent.__init(self,display)

  self.palette = {
    foreground = {
      color = {0x00,0x00,0x80},
      text = "bt",
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

-- user input via button
-- @return boolean, true when message was handled

function UIButton:do_press(msg)
  TRACE("UIButton:do_press")
  
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

function UIButton:do_release(msg)
  TRACE("UIButton:do_release()")

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

function UIButton:do_change(msg)
  TRACE("UIButton:do_change()")

  if not self:test(msg.group_name,msg.column,msg.row) then
    return false
  end
  local handled = false
  if (self.on_change ~= nil) then 
    handled = self:on_release()
  end
  return handled

end

--------------------------------------------------------------------------------

-- user input via (held) button
-- on_hold() is an optional handler, which is only supported by "button" input
-- @return boolean, true when message was handled

function UIButton:do_hold(msg)
  TRACE("UIButton:do_hold()")

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

-- expanded UIComponent test
-- @return boolean, false when criteria is not met

function UIButton:test(group_name,column,row)

  -- look for group name
  if not (self.group_name == group_name) then
    return false
  end

  -- look for event handlers
  if (self.on_change == nil) 
    and (self.on_press == nil) 
    and (self.on_release == nil) 
    and (self.on_hold == nil) 
  then  
    return false
  end 

  -- test the X/Y position
  return UIComponent.test(self,column,row)

end

--------------------------------------------------------------------------------

-- shorthand method for setting the @foreground palette 
-- @param foreground (table), new color/text values

function UIButton:set(fg_val)
  TRACE("UIButton:set()",fg_val)

  if not fg_val then
    return
  end

  UIComponent.set_palette(self,{foreground=fg_val})

end

--------------------------------------------------------------------------------

-- easy way to animate the appearance of the button
-- @param delay, number of ms between updates
-- @param ..., palette entries

function UIButton:flash(delay, ...)
  TRACE("UIButton:flash()",delay,arg)

  self._display.scheduler:remove_task(self._task)
  for i,args in ipairs(arg) do
    if (i==1) then
      self:set(arg[i]) -- set first one at once
    else
      self._task = self._display.scheduler:add_task(
        self, UIButton.set, delay*(i-1), arg[i])
    end
  end

end

--------------------------------------------------------------------------------

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

-- force-update controls that are handling their internal state by themselves,
-- achieved by changing the canvas so that it get's painted the next time...

function UIButton:force_update()
  TRACE("UIButton:force_update()")

  self.canvas.delta = table.rcopy(self.canvas.buffer)
  self.canvas.has_changed = true
  self:invalidate()

end

--------------------------------------------------------------------------------

function UIButton:add_listeners()

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

function UIButton:remove_listeners()

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED)

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_VALUE_CHANGED)

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_HELD)


end

