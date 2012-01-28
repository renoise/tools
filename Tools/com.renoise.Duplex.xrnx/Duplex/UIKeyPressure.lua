--[[----------------------------------------------------------------------------
-- Duplex.UIKeyPressure
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UIKeyPressure


About

  UIKeyPressure is a UIComponent that respond to channel-pressure events.
  Although the UIKeyPressure class is based on UIComponent, it does not
  come with a graphical representation. It merely receives channel-
  pressure and let your application act on that information.

Supported input methods

- keyboard

Events

- on_change()


--]]


--==============================================================================

class 'UIKeyPressure' (UIComponent)

function UIKeyPressure:__init(display)
  TRACE('UIKeyPressure:__init')

  UIComponent.__init(self,display)

  self.value = nil
  self.on_change = nil

  -- internal stuff
  self:add_listeners()

end


--------------------------------------------------------------------------------

-- user input 

function UIKeyPressure:do_change(msg)
  TRACE("UIKeyPressure:do_change",msg)
  
  if (self.on_change ~= nil) then

    if not (self.group_name == msg.group_name) then
      return 
    end

    self.value = msg.value
    self:on_change()

  end

end


--------------------------------------------------------------------------------

function UIKeyPressure:add_listeners()

  self._display.device.message_stream:add_listener(
    self, DEVICE_EVENT_CHANNEL_PRESSURE,
    function(msg) self:do_change(msg) end )

end

--------------------------------------------------------------------------------

function UIKeyPressure:remove_listeners()

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_CHANNEL_PRESSURE)

end

