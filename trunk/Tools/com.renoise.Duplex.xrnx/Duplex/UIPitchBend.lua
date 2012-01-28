--[[----------------------------------------------------------------------------
-- Duplex.UIPitchBend
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UISlider > UIPitchBend


About

UIPitchBend expands the standard UISlider with the "on_bend" event



--]]


--==============================================================================

class 'UIPitchBend' (UISlider)

function UIPitchBend:__init(display)

	UISlider.__init(self,display)

end

--------------------------------------------------------------------------------

--[[
function UIPitchBend:do_bend()
  TRACE("UIPitchBend:do_bend()")

  if (self.on_bend ~= nil) then

    local msg = self:get_msg()

    print("msg.value",msg.value)

    -- scale from the message range to the sliders range
    local val = (msg.value / msg.max) * self.ceiling
    self:set_value(val)

  end

end
]]

--------------------------------------------------------------------------------

function UIPitchBend:add_listeners()

  self._display.device.message_stream:add_listener(
    self,DEVICE_EVENT_PITCH_CHANGED,
    function(msg) self:do_change(msg) end )

	UISlider.add_listeners(self)


end

--------------------------------------------------------------------------------

function UIPitchBend:remove_listeners()

  self._display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_PITCH_CHANGED)

	UISlider.remove_listeners(self)

end

--------------------------------------------------------------------------------

-- trigger the external handler method
--[[
function UISlider:_invoke_handler()

  if (self.on_bend == nil) then 
    return 
  end

  local rslt = self:on_bend()  
  if (rslt==false) then  -- revert
    self.index = self._cached_index    
    self.value = self._cached_value  

  else
    self:invalidate()
  end
end

]]
