--[[----------------------------------------------------------------------------
-- Duplex.BCF2000
----------------------------------------------------------------------------]]--

-- default configuration of the BCF-2000

--==============================================================================

class "BCF2000" (MidiDevice)

function BCF2000:__init(display_name, message_stream, port_in, port_out)
  TRACE("BCF2000:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- the BCF can not handle looped back messages correctly, so we disable 
  -- sending back messages we got from the BCF, in order to break feedback loops...
  self.loopback_received_messages = false
end


--==============================================================================

-- Include these configurations 

local CTRL_PATH = "Duplex/Controllers/BCF-2000/Configurations/"
require (CTRL_PATH.."BCF2000_Effect")
require (CTRL_PATH.."BCF2000_Mixer")
require (CTRL_PATH.."BCF2000_NotesOnWheels")
require (CTRL_PATH.."BCF2000_Recorder")

