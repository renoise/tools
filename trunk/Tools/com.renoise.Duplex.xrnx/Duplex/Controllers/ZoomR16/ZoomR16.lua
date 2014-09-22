--[[----------------------------------------------------------------------------
-- Duplex.ZoomR16
----------------------------------------------------------------------------]]--

--[[

Inheritance: ZoomR16 > MidiDevice > Device

A device-specific class 

--]]


--==============================================================================

class "ZoomR16" (MidiDevice)

function ZoomR16:__init(display_name, message_stream, port_in, port_out)
  TRACE("ZoomR16:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

end


