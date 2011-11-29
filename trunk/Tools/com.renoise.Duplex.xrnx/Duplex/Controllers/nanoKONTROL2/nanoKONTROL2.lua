--[[----------------------------------------------------------------------------
-- Duplex.NanoKontrol2
----------------------------------------------------------------------------]]--

-- default configuration of the NanoKontrol2
-- uses a custom device class, a control map and the Mixer application


--==============================================================================

class "NanoKontrol2" (MidiDevice)

function NanoKontrol2:__init(display_name, message_stream, port_in, port_out)
  TRACE("NanoKontrol2:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)


end


--==============================================================================

-- Include these configurations 

local CTRL_PATH = "Duplex/Controllers/nanoKONTROL2/Configurations/"
require (CTRL_PATH.."MixerTransport")
require (CTRL_PATH.."RecorderTransport")
require (CTRL_PATH.."StepSequencerTransport")
require (CTRL_PATH.."NotesOnWheels")

