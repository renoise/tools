--[[----------------------------------------------------------------------------
-- Duplex.Mackie-Control
----------------------------------------------------------------------------]]--

--[[

Inheritance: Mackie-Control > MidiDevice > Device

A generic class for devices that support the Mackie-control protocol

--]]

--==============================================================================

class "MackieControl" (MidiDevice)

function MackieControl:__init(display_name, message_stream, port_in, port_out)
  TRACE("MackieControl:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  self.allow_zero_velocity_note_on = true


end


