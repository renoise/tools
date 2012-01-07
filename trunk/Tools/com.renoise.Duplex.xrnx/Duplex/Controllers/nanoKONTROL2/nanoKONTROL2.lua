--[[----------------------------------------------------------------------------
-- Duplex.NanoKontrol2
----------------------------------------------------------------------------]]--

--[[

Inheritance: NanoKontrol > MidiDevice > Device

A device-specific class 

--]]

--==============================================================================

class "NanoKontrol2" (MidiDevice)

function NanoKontrol2:__init(display_name, message_stream, port_in, port_out)
  TRACE("NanoKontrol2:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)


end


