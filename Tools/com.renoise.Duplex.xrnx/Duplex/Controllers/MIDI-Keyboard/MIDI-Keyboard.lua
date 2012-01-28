--[[----------------------------------------------------------------------------
-- Duplex.MIDI-Keyboard
----------------------------------------------------------------------------]]--

--[[

Inheritance: MidiDevice > Device

--]]

--==============================================================================

class "MidiKeyboard" (MidiDevice)

function MidiKeyboard:__init(display_name, message_stream, port_in, port_out)
  TRACE("MidiKeyboard:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- disable sending back messages 
  self.loopback_received_messages = false

end


