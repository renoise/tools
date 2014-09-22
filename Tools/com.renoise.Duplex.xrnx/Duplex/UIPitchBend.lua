--[[============================================================================
-- Duplex.UIPitchBend
-- Inheritance: UIComponent > UISlider > UIPitchBend
============================================================================]]--

--[[--
UIPitchBend is able to receive pitch bend messages from MIDI devices


### Changes

  0.98
    - First release


--]]

--==============================================================================

class 'UIPitchBend' (UISlider)

--------------------------------------------------------------------------------

--- Initialize the UIPitchBend class
-- @param app (@{Duplex.Application})
-- @param map[opt] (table) mapping properties 

function UIPitchBend:__init(app,map)
  TRACE("UIPitchBend:__init()",app,map)

	UISlider.__init(self,app,map)

end

--------------------------------------------------------------------------------

--- Add event listener
--    DEVICE_EVENT.PITCH_CHANGED
-- @see Duplex.UIComponent.add_listeners

function UIPitchBend:add_listeners()
  TRACE("UIPitchBend:add_listeners()")

	UISlider.add_listeners(self)

  if self.on_change then
    self.app.display.device.message_stream:add_listener(
      self,DEVICE_EVENT.PITCH_CHANGED,
      function(msg) return self:do_change(msg) end )
  end

end

--------------------------------------------------------------------------------

--- Remove previously attached event listener
-- @see Duplex.UIComponent.remove_listeners

function UIPitchBend:remove_listeners()
  TRACE("UIPitchBend:remove_listeners()")

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT.PITCH_CHANGED)
	UISlider.remove_listeners(self)

end

