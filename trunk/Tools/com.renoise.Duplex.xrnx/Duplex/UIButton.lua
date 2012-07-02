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

--------------------------------------------------------------------------------

--- Initialize the UIButton class
-- @param display (Duplex.Display)

function UIButton:__init(display)
  TRACE('UIButton:__init')

  UIComponent.__init(self,display)

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
-- @param msg (Duplex.Message)
-- @return (Boolean), true when message was handled

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

--- User released button
-- @param msg (Duplex.Message)
-- @return (Boolean), true when message was handled

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

--- User changed value via fader, dial ...
-- @param msg (Duplex.Message)
-- @return (Boolean), true when message was handled

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

--- User held button for a while (exact time is specified in preferences).
--  Note that this event is only supported by controllers that transmit the 
--  "release" event
-- @param msg (Duplex.Message)
-- @return (Boolean), true when message was handled

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

--- Expanded UIComponent test. Look for group name, event handlers, then 
--  proceed with the standard UIComponent test
-- @param group_name (String) control-map group name
-- @param column (Number) 
-- @param row (Number) 
-- @return (Boolean), false when criteria is not met

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

--- Shorthand method for setting the foreground palette 
-- @param fg_val (Table), new color/text values

function UIButton:set(fg_val)
  TRACE("UIButton:set()",fg_val)

  if not fg_val then
    return
  end

  UIComponent.set_palette(self,{foreground=fg_val})

end

--------------------------------------------------------------------------------

--- Easy way to animate the appearance of the button
-- @param delay (Number) number of ms between updates
-- @param ... (Vararg) palette entries

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

--- Update the appearance of the button 

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

--- Add event listeners to the button (press, release, change, hold)

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

--- Remove previously attached event listeners
-- @see UIButton:add_listeners

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

