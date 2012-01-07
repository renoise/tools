--[[----------------------------------------------------------------------------
-- Duplex.NanoKontrol
----------------------------------------------------------------------------]]--

--[[

Inheritance: NanoKontrol > MidiDevice > Device

A device-specific class 

--]]


--==============================================================================

class "NanoKontrol" (MidiDevice)

function NanoKontrol:__init(display_name, message_stream, port_in, port_out)
  TRACE("NanoKontrol:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  self.loopback_received_messages = false
end


