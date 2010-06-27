--[[----------------------------------------------------------------------------
-- Duplex.Ohm64 
----------------------------------------------------------------------------]]--

--[[

Inheritance: Ohm64 > MIDIDevice > Device

A device-specific class 

--]]


--==============================================================================

class "Ohm64" (MIDIDevice)

function Ohm64:__init(name, message_stream)
  TRACE("Ohm64:__init", name, message_stream)

  MIDIDevice.__init(self, name, message_stream)

  -- send back a copy of the incming midi messages
  self.loopback_received_messages = true
end


--------------------------------------------------------------------------------

function Ohm64:point_to_value(pt, maximum, minimum, ceiling)
  TRACE("Ohm64:point_to_value", pt.val, maximum, minimum, ceiling)

  return MIDIDevice.point_to_value(self, pt, maximum, minimum, ceiling)
end

