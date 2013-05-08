--[[----------------------------------------------------------------------------
-- Duplex.UIPitchBend
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UISlider > UIPitchBend


--]]


--==============================================================================

class 'UIPitchBend' (UISlider)

--------------------------------------------------------------------------------

--- Initialize the UIPitchBend class
-- @param app (Duplex.Application)

function UIPitchBend:__init(app)
  TRACE("UIPitchBend:__init()",app)

	UISlider.__init(self,app)

end

--------------------------------------------------------------------------------

--- Add event listener (pitchbend)

function UIPitchBend:add_listeners()
  TRACE("UIPitchBend:add_listeners()")

  self.app.display.device.message_stream:add_listener(
    self,DEVICE_EVENT_PITCH_CHANGED,
    function(msg) return self:do_change(msg) end )
	UISlider.add_listeners(self)

end

--------------------------------------------------------------------------------

--- Remove previously attached event listener
-- @see UIPitchBend:add_listeners

function UIPitchBend:remove_listeners()
  TRACE("UIPitchBend:remove_listeners()")

  self.app.display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_PITCH_CHANGED)
	UISlider.remove_listeners(self)

end

