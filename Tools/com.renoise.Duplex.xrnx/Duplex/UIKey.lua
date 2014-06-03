--[[============================================================================
-- Duplex.UIKey
-- Inheritance: UIComponent > UIKey
============================================================================]]--

--[[--

A UIComponent designed to work with a standard keyboard, it responds to a `keyboard` or `key` type parameter

Instead of a single numeric value, the UIKey can represent both pitch and velocity. UIKey does not produce sound or trigger notes by itself, you need to tie it together with you own application logic in order to achieve this. 

The component can be used in two different ways:

1. Hidden, matching any note (`match_any_note=true`) In this mode, the UIKey receive any incoming notes, which you can use as the basis for building your own keyboard implementation.

2. Interactive, mapping to individual inputs (`match_any_note=false`) In this mode, the UIKey will respond when the right area has been triggered by the user (the UIKey, like any UIComponent, isn't limited to a single button, but can have any rectangular size). Use this to visualize the input from the keyboard. The events are designed to be similar to the events employed by the other UI component: press, release and hold events are standard. 

Supported input methods

* keyboard
* key

--]]

--==============================================================================


class 'UIKey' (UIComponent)

--------------------------------------------------------------------------------

--- Initialize the UIKey class
-- @param app (@{Duplex.Application})

function UIKey:__init(app)
  TRACE('UIKey:__init')

  UIComponent.__init(self,app)

  --- true while the key is pressed 
  self.pressed = false

  --- if key is disabled, draw "dimmed" version
  self.disabled = false

  --- the current pitch
  self.pitch = nil

  --- the current transpose (semitones)
  self.transpose = 0

  --- default ceiling is for standard MIDI (override if needed)
  --self.ceiling = 127

  --- the current velocity
  self.velocity = nil

  --- when true, we match any incoming note
  self.match_any_note = false

  --- specify the default palette 
  -- @field pressed The pressed state
  -- @field released The released state
  -- @field disabled The disabled state
  -- @table palette
  self.palette = {
    pressed  = {  color={0xFF,0xFF,0xFF}, text="▪"},
    released  = { color={0x40,0x40,0x40}, text="▫" },
    disabled  = { color={0x00,0x00,0x00}, text="·" },
  }

  --- external event handlers
  self.on_press = nil
  self.on_release = nil
  self.on_hold = nil

  --- when acting as keyboard, maintain the display state:
  -- decide which keys should be disabled (upper/lower range)
  self.disabled_keys = {}

  --- decide which keys are currently pressed 
  self.pressed_keys = {}

  --- when acting as keyboard, raise this flag to tell the 
  -- display to refresh the entire keyboard (a bit of a hack but 
  -- the keyboard is entirely virtual, so it's a special case)
  self._key_update_requested = false

  --- internal stuff
  self:add_listeners()

end


--------------------------------------------------------------------------------

--- Perform a test of the incoming value:
-- if we pass any note (keyboard mode), the incoming pitch is remembered
-- else, pitch is assigned when the UIKey is first created (and the
-- containing application will then apply it's own transpose)
-- @param msg (@{Duplex.Message})
-- @return (bool), true when message was considered valid
-- @see Duplex.UIComponent.test

function UIKey:test(msg)
  TRACE("UIKey:test()",msg)

  if self.disabled then
    return true
  end

  if not self.app.active then
    return false
  end
  
  if not (self.group_name == msg.group_name) then
    return false
  end

  if self.match_any_note then 
    self.pitch = self:translate_pitch(msg)
    if not self.pitch then
      return false
    end
  elseif not UIComponent.test(self,msg.column,msg.row) then
    return false
  end

  return true

end

--------------------------------------------------------------------------------

--- A key was pressed
-- @param msg (@{Duplex.Message})
-- @return self or nil

function UIKey:do_press(msg)
  TRACE("UIKey:do_press()",msg)

  if not self:test(msg) then  
    return
  end

  if (self.on_press ~= nil) then
    self.velocity = msg.value[2]
    self.pressed = true
    local handled = self:on_press()
    if (handled==true) then
      self:invalidate()
    end
  end

  return self

end

--------------------------------------------------------------------------------

--- A key was released
-- @param msg (@{Duplex.Message})
-- @return self or nil

function UIKey:do_release(msg)
  TRACE("UIKey:do_release",msg)

  if not self:test(msg) then  
    return
  end

  if (self.on_release ~= nil) then
    self.pressed = false
    local handled = self:on_release()
    if (handled==true) then
      self:invalidate()
    end
  end

  return self

end

--------------------------------------------------------------------------------

--- A key was held
-- @param msg (@{Duplex.Message})

function UIKey:do_hold(msg)
  TRACE("UIKey:do_hold",msg)

  if not self:test(msg) then  
    return
  end

  if (self.on_hold ~= nil) then
    self.on_hold()
  end

end

--------------------------------------------------------------------------------

--- Translate_pitch, used for determining the correct pitch 
-- @param msg (@{Duplex.Message})
-- @return pitch (int)

function UIKey:translate_pitch(msg)
  TRACE("UIKey:translate_pitch()",msg)
  
  if not msg.value[1] then
    return false
  end

  local pitch = msg.value[1]
  if msg.is_virtual then
    pitch = pitch + self.transpose - 12 -- virtual control surface
  elseif (msg.is_osc_msg) then
    pitch = pitch + self.transpose - 13 -- OSC message
  else
    pitch = pitch + self.transpose -- actual MIDI keyboard
  end

  return pitch

end


--------------------------------------------------------------------------------
-- Overridden from UIComponent
--------------------------------------------------------------------------------

--- Update the appearance - inherited from UIComponent
-- @see Duplex.UIComponent

function UIKey:draw()
  TRACE("UIKey:draw")

  -- the pitch value may not be defined initially
  if not self.pitch then
    return
  end

  local point = CanvasPoint()

  if self.disabled then
    point.text = self.palette.disabled.text
    point.color = self.palette.disabled.color
    point.val = (self.match_any_note) and self.pitch or false
  elseif self.pressed then
    point.text = self.palette.pressed.text
    point.color = self.palette.pressed.color
    point.val = (self.match_any_note) and self.pitch or true
  else
    point.text = self.palette.released.text
    point.color = self.palette.released.color
    point.val = (self.match_any_note) and self.pitch or false
  end

  self.canvas:fill(point)
  UIComponent.draw(self)

end

--------------------------------------------------------------------------------

--- Force complete refresh when used as keyboard - a bit of a hack  
-- (the display will reset the "refresh_requested" property)

function UIKey:update_keys()
  TRACE("UIKey:update_keys")

  self._key_update_requested = true
  local point = CanvasPoint()
  point.val = not self.pressed
  self.canvas:fill(point)
  self:invalidate()

end

--------------------------------------------------------------------------------

--- Add event listeners
--    DEVICE_EVENT.BUTTON_PRESSED
--    DEVICE_EVENT.BUTTON_RELEASED
--    DEVICE_EVENT.BUTTON_HELD
-- @see Duplex.UIComponent

function UIKey:add_listeners()

  self.app.display.device.message_stream:add_listener(
    self, DEVICE_EVENT.KEY_PRESSED,
    function(msg) return self:do_press(msg) end )

  self.app.display.device.message_stream:add_listener(
    self, DEVICE_EVENT.KEY_RELEASED,
    function(msg) return self:do_release(msg) end )

  self.app.display.device.message_stream:add_listener(
    self, DEVICE_EVENT.KEY_HELD,
    function(msg) return self:do_hold(msg) end )

end


--------------------------------------------------------------------------------

--- Remove previously attached event listeners
-- @see Duplex.UIComponent

function UIKey:remove_listeners()

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.KEY_PRESSED)

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.KEY_RELEASED)

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.KEY_HELD)

end


