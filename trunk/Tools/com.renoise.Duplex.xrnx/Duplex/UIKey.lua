--[[============================================================================
-- Duplex.UIKey
-- Inheritance: UIComponent > UIKey
============================================================================]]--

--[[--

UIKey receives messages from a MIDI keyboard.

You can create one of these components when you have a control-map which 
specify a parameter with a type of "keyboard" 

This type of UIComponent is a bit different since it does not have the ability
to be displayed externally - instead, it is visualized by a WidgetKeyboard 
(a custom viewbuilder widget) in the virtual control surface

### Supported events

    on_press
    on_release 
    on_hold 

### Supported parameter types

    <Param type="keyboard">


### Changes

  0.98
    - First release

--]]

--==============================================================================


class 'UIKey' (UIComponent)

--------------------------------------------------------------------------------

--- Initialize the UIKey class
-- @param app (@{Duplex.Application})
-- @param map[opt] (table) mapping properties 

function UIKey:__init(app,map)
  TRACE('UIKey:__init',app,map)

  UIComponent.__init(self,app,map)

  -- the most recent midi message
  self.recent_msg = nil

  -- (WidgetKeyboard) reference to custom widget class
  self.widget = nil

  -- specify the default palette 
  self.palette = {
    white_pressed   = {0xFF,0xFF,0xFF},
    white_released  = {0x40,0x40,0x40},
    white_disabled  = {0x00,0x00,0x00},
    black_pressed   = {0xFF,0xFF,0xFF},
    black_released  = {0x40,0x40,0x40},
    black_disabled  = {0x00,0x00,0x00},
  }

  --- external event handlers
  self.on_press = nil
  self.on_release = nil
  self.on_hold = nil


end


--------------------------------------------------------------------------------

--- Perform a test of the incoming value
-- @param msg (@{Duplex.Message})
-- @return (bool), true when message was considered valid
-- @see Duplex.UIComponent.test

function UIKey:test(msg)
  TRACE("UIKey:test()",msg)

  if not self.app.active then
    return false
  end
  
  if not (self.group_name == msg.xarg.group_name) then
    return false
  end

  -- establish reference to custom widget
  self.widget = widget_hooks._custom_widgets[msg.xarg.id]

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
    self.recent_msg = msg
    local handled = self:on_press(msg.midi_msg[2],msg.midi_msg[3])
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
    self.recent_msg = msg
    local handled = self:on_release(msg.midi_msg[2],msg.midi_msg[3])
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

function UIKey:set_key_disabled(pitch,state)

  if self.widget then
    self.widget.disabled_keys[pitch] = state
    self:invalidate()
  end

end

--------------------------------------------------------------------------------

function UIKey:set_key_pressed(pitch,state)
  
  -- TODO check if key is already pressed - if not, generate a message
  -- that can be used for updating the device display 

  -- TODO in the widget, keep track of keys that need to update

  if self.widget then
    self.widget.pressed_keys[pitch] = state
    self:invalidate()
    --rprint("self.widget.pressed_keys",rprint(self.widget.pressed_keys))
  end


end

--------------------------------------------------------------------------------

function UIKey:set_octave(oct)

  if self.widget then
    if self.widget:set_octave(oct) then
      self:invalidate()
    end
  end

end

--------------------------------------------------------------------------------
-- Overridden from UIComponent
--------------------------------------------------------------------------------

--- Set the position - 
-- @see Duplex.UIComponent

function UIKey:set_pos(x,y)
  TRACE("UIKey:set_pos(x,y)",x,y)

  UIComponent.draw(self)

end


--------------------------------------------------------------------------------

--- Update the appearance - inherited from UIComponent
-- @see Duplex.UIComponent

function UIKey:draw()
  TRACE("UIKey:draw")

  --print("self.widget",self.widget)
  if self.widget then
    self.widget:update_all_keys()
  end

  UIComponent.draw(self)

end


--------------------------------------------------------------------------------

--- Add event listeners
--    DEVICE_EVENT.BUTTON_PRESSED
--    DEVICE_EVENT.BUTTON_RELEASED
--    DEVICE_EVENT.BUTTON_HELD
-- @see Duplex.UIComponent

function UIKey:add_listeners()
  TRACE("UIKey:add_listeners()")

  self:remove_listeners()

  if self.on_press then
    self.app.display.device.message_stream:add_listener(
      self, DEVICE_EVENT.KEY_PRESSED,
      function(msg) return self:do_press(msg) end )
  end

  if self.on_release then
    self.app.display.device.message_stream:add_listener(
      self, DEVICE_EVENT.KEY_RELEASED,
      function(msg) return self:do_release(msg) end )
  end

  if self.on_hold then
    self.app.display.device.message_stream:add_listener(
      self, DEVICE_EVENT.KEY_HELD,
      function(msg) return self:do_hold(msg) end )
  end

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


