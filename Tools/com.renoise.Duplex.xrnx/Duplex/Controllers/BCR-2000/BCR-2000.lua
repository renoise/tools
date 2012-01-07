--[[----------------------------------------------------------------------------
-- Duplex.BCR2000
----------------------------------------------------------------------------]]--

-- default configuration of the BCR-2000

--==============================================================================

class "BCR2000" (MidiDevice)

function BCR2000:__init(display_name, message_stream, port_in, port_out)
  TRACE("BCR2000:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- the BCR can not handle looped back messages correctly, so we disable 
  -- sending back messages we got from the BCR, in order to break feedback loops...
  self.loopback_received_messages = false

end


