--[[----------------------------------------------------------------------------
-- Duplex.OscDevice
----------------------------------------------------------------------------]]--

--[[

Inheritance: OscDevice -> Device

Requires: Globals

--]]


--==============================================================================

class 'OscDevice' (Device)

function OscDevice:__init(name, message_stream)
  TRACE("OscDevice:__init("..name..")")
  
  Device.__init(self, name, message_stream, DEVICE_OSC_PROTOCOL)
end


--------------------------------------------------------------------------------

function OscDevice:release()
  TRACE("OscDevice:release()")
end


