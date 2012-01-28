--[[----------------------------------------------------------------------------
-- Duplex.UIKey
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UIKey


About

  UIKey is a UIComponent designed to work with a standard keyboard. It 
  responds to any control-map containing a "keyboard" or "key" parameter

  Instead of a single numeric value, the UIKey can represent both pitch and 
  velocity. UIKey does not produce sound or trigger notes by itself, you need to 
  tie it together with you own application logic in order to achieve this. 

  The component can be used in two different ways:

  1. Hidden, matching any note (match_any_note=true)
     In this mode, the UIKey receive any incoming notes, which you
     can use as the basis for building your own keyboard implementation.

  2. Interactive, mapping to individual inputs (match_any_note=false)
     In this mode, the UIKey will respond when the right area has
     been triggered by the user (the UIKey, like any UIComponent, isn't 
     limited to a single button, but can have any rectangular size). 
     Use this to visualize the input from the keyboard.

  The events are designed to be similar to the events employed by the 
  other UI component: press, release and hold events are standard. 



Supported input methods

- keyboard
- key

Events

- on_press()
- on_release()
- on_hold()


--]]


--==============================================================================

class 'UIKey' (UIComponent)

function UIKey:__init(display)
  TRACE('UIKey:__init')

  UIComponent.__init(self,display)

  -- true while the key is pressed 
  self.pressed = false

  -- the current pitch
  self.pitch = nil

  -- the current transpose (semitones)
  self.transpose = 0

  -- the current velocity
  self.velocity = nil

  -- when true, we match any incoming note
  self.match_any_note = false

  -- specify the default palette 
  self.palette = {
    pressed = table.rcopy(display.palette.color_1),
    released = table.rcopy(display.palette.background)
  }

  -- external event handlers
  self.on_press = nil
  self.on_release = nil
  self.on_hold = nil

  -- internal stuff
  self:add_listeners()

end


--------------------------------------------------------------------------------

-- perform a test of the incoming value:
-- if we pass any note (keyboard mode), the incoming pitch is remembered
-- else, match pitch by row/column (grid mode)

function UIKey:test(msg)

  if not (self.group_name == msg.group_name) then
    return 
  end

  if self.match_any_note then 
    self.pitch = msg.value[1]
  elseif not UIComponent.test(self,msg.column,msg.row) then
    return false
  end

  return true

end

--------------------------------------------------------------------------------

-- user input 

function UIKey:do_press(msg)
  --TRACE("UIKey:do_press",msg)
  
  if (self.on_press ~= nil) then

    if not self:test(msg) then
      return 
    end

    self.velocity = msg.value[2]
    self.pressed = true
    self:_invoke_handler()

  end

end

function UIKey:do_release(msg)
  --TRACE("UIKey:do_release",msg)
  
  if (self.on_release ~= nil) then

    if not self:test(msg) then
      return 
    end

    self.pressed = false
    self:on_release()
    self:invalidate()

  end

end

function UIKey:do_hold(msg)
  --TRACE("UIKey:do_hold",msg)
  
  if (self.on_hold ~= nil) then

    if not self:test(msg) then
      return 
    end

    self.on_hold()

  end

end

--------------------------------------------------------------------------------
-- Overridden from UIComponent
--------------------------------------------------------------------------------

function UIKey:draw()
  --TRACE("UIKey:draw")

  local point = CanvasPoint()

  if self.pressed then
    point.text = self.pitch
    point.color = self.palette.pressed.color  --{0xFF,0xFF,0xFF}
    point.val = true        
  else
    point.text = self.pitch
    point.color = self.palette.released.color -- {0x00,0x00,0x00}
    point.val = false        
  end

  self.canvas:fill(point)
  UIComponent.draw(self)

end

--------------------------------------------------------------------------------

function UIKey:add_listeners()

  self._display.device.message_stream:add_listener(
    self, DEVICE_EVENT_KEY_PRESSED,
    function(msg) self:do_press(msg) end )

  self._display.device.message_stream:add_listener(
    self, DEVICE_EVENT_KEY_RELEASED,
    function(msg) self:do_release(msg) end )

  self._display.device.message_stream:add_listener(
    self, DEVICE_EVENT_KEY_HELD,
    function(msg) self:do_hold(msg) end )


end


--------------------------------------------------------------------------------

function UIKey:remove_listeners()

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_KEY_PRESSED)

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_KEY_RELEASED)

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_KEY_HELD)


end


--------------------------------------------------------------------------------
-- Private
--------------------------------------------------------------------------------

-- trigger the external handler method

function UIKey:_invoke_handler()
  TRACE("UIKey:_invoke_handler()")

  if (self.on_press == nil) then 
    return 
  end

  local rslt = self:on_press()
  if (rslt~=false) then
    self:invalidate()
  end
end



