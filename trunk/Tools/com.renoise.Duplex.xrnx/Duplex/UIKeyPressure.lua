--[[============================================================================
-- Duplex.UIKeyPressure
-- Inheritance: UIComponent > UISlider > UIKeyPressure
============================================================================]]--

--[[--
UIKeyPressure is a UIComponent that respond to MIDI channel-pressure events.


### Changes

  0.98
    - First release


--]]

--==============================================================================

class 'UIKeyPressure' (UISlider)

--------------------------------------------------------------------------------

--- Initialize the UIKeyPressure class
-- @param app (@{Duplex.Application})
-- @param map[opt] (table) mapping properties 

function UIKeyPressure:__init(app,map)
  TRACE("UIKeyPressure:__init()",app,map)

  UISlider.__init(self,app,map)

end


--------------------------------------------------------------------------------

--- Add event listener
--    DEVICE_EVENT.CHANNEL_PRESSURE
-- @see Duplex.UIComponent.add_listeners

function UIKeyPressure:add_listeners()
  TRACE("UIKeyPressure:add_listeners()")

	UISlider.add_listeners(self)


  if self.on_change then
    self.app.display.device.message_stream:add_listener(
      self, DEVICE_EVENT.CHANNEL_PRESSURE,
      function(msg) return self:do_change(msg) end )
  end

end

--------------------------------------------------------------------------------

--- Remove previously attached event listener
-- @see Duplex.UIComponent

function UIKeyPressure:remove_listeners()
  TRACE("UIKeyPressure:remove_listeners()")

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.CHANNEL_PRESSURE)

end

