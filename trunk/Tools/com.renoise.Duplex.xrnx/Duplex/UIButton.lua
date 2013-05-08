--[[----------------------------------------------------------------------------
-- Duplex.UIButton
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UIButton

-- About the UIButton component --

  The UIButton is a generic button component that accept a wide range of input 
  methods - you can assign any button type, fader or dial to control it.
  The button has no internal "active" or "enabled" state, it merely tells you 
  when an event has occurred. Then, it is up to you to change it's visual state. 


-- Working with events --

  To listen for an event, you add one of these to your code: 

  on_change()   - invoked when a slider/dial is changed
  on_press()    - invoked when the button is pressed
  on_release()  - invoked when the button is released
  on_hold()     - invoked when the button is held for a while*
                  (the standard amount of time is 0.5 seconds)

  -- Here is an example
  my_button.on_change = function()
    -- do something
  end


  Each input method may or may not support specific events. See this table:

                  | on_change | on_press |  on_release | on_hold
  ----------------+-----------+----------+-------------+----------
  @button         |           |     X    |       X     |    X
  @pushbutton     |           |     X    |             |
  @togglebutton   |           |     X    |             |
  @fader          |    X      |          |             |
  @dial           |    X      |          |             |


-- Controlling the visual representation --

  In Duplex, the UIButton stores it's visual representation in something known
  as a Canvas. The Canvas is made from indivual points, each of which can
  contain the following values: 

  Value   This is a simple boolean value which will tell if the button is lit 
          or not - relevant for most hardware with LEDs that can turn on/off

  Color   Depending on the capabilities of your hardware, color might be an
          interesting feature to make use of. Most hardware doesn't support
          the use of color (this is determined by the device colorspace). 

  Text    this is merely for display purposes on the computer screen, but still,
          it's nice to be able to e.g. label a play button with a "►" symbol.

  In order to actually change these values, you have a couple of methods 
  at your disposal: 

  Method #1 : set
  
  The set() method is the most simple, and will allow you to instantly set 
  any (or all) of the following properties: color, text, value 

  -- Here is an example, setting the button color to full white:
  my_button:set({color={0xFF,0xFF,0xFF}})

  -- Here is another example, setting the button color along with text:
  my_button:set({
    color = {0xFF,0x40,0x00}, 
    text = "HELLO"
  })

  Method #2 : flash

  If you are using a button to produce a "one-shot" type of event, you would
  want it to briefly flash and then go back to it's default state. Of course,
  you could use the set() method twice (schedule the second one shortly after
  the first), but it is a much simpler option to use the built-in method 
  "flash". This method will allow you to assign a list of palette entries 
  that the button should cycle through, even controlling the speed of updates. 
  Just as with the set() method, you can choose to update any or all of the 
  properties, this is entirely up to you.

  -- Here is an example of a brief flash, going to lit state and back
  my_button:flash(0.1,{value=true},{value=false})

  -- Here is an example of an extended flash, slowly fading to black
  my_button:flash(0.5,
    {color=0xFF,0xFF,0xFF},
    {color=0xBF,0xBF,0xBF},
    {color=0x7F,0x7F,0x7F},
    {color=0x3F,0x3F,0x3F},
    {color=0x1F,0x1F,0x1F},
    {color=0x00,0x00,0x00})


--]]


--==============================================================================

class 'UIButton' (UIComponent)

--------------------------------------------------------------------------------

--- Initialize the UIButton class
-- @param app (Duplex.Application)

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
-- @param msg (Duplex.Message)
-- @return (Boolean), true when message was handled

function UIButton:do_press(msg)
  TRACE("UIButton:do_press")
  
  if not self:test(msg) then
    return
  end

  if (self.on_press ~= nil) then
    -- force-update controls that maintain their
    -- internal state (togglebutton, pushbutton)
    if (msg.input_method ~= CONTROLLER_BUTTON) then
      self:force_update()
    end
    self:on_press()
    return self
  end

end

--------------------------------------------------------------------------------

--- User released button
-- @param msg (Duplex.Message)
-- @return (Boolean), true when message was handled

function UIButton:do_release(msg)
  TRACE("UIButton:do_release()")

  if not self:test(msg) then
    return
  end
  
  -- force-update controls that maintain their
  -- internal state (togglebutton, pushbutton)
  if (msg.input_method ~= CONTROLLER_BUTTON) then
    self:force_update()
  end

  if (self.on_release ~= nil) then
    self:on_release()
    return self
  end

end

--------------------------------------------------------------------------------

--- User changed value via fader, dial ...
-- @param msg (Duplex.Message)
-- @return (Boolean), true when message was handled

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
-- @param msg (Duplex.Message)

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
-- @param group_name (String) control-map group name
-- @param column (Number) 
-- @param row (Number) 
-- @return (Boolean), false when criteria is not met

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
-- @param delay (Number) number of seconds between updates
-- @param ... (Vararg) palette entries

function UIButton:flash(delay, ...)
  TRACE("UIButton:flash()",delay,arg)

  self.app.display.scheduler:remove_task(self._task)
  for i,args in ipairs(arg) do
    if (i==1) then
      self:set(arg[i]) -- set first one at once
    else
      self._task = self.app.display.scheduler:add_task(
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

  self.app.display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_PRESSED,
    function(msg) return self:do_press(msg) end )

  self.app.display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_RELEASED,
    function(msg) return self:do_release(msg) end )

  self.app.display.device.message_stream:add_listener(
    self,DEVICE_EVENT_VALUE_CHANGED,
    function(msg) return self:do_change(msg) end )

  self.app.display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_HELD,
    function(msg) self:do_hold(msg) end )


end


--------------------------------------------------------------------------------

--- Remove previously attached event listeners
-- @see UIButton:add_listeners

function UIButton:remove_listeners()

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED)

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_VALUE_CHANGED)

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_HELD)


end

