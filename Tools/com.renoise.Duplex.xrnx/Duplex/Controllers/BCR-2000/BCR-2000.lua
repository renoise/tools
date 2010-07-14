--[[----------------------------------------------------------------------------
-- Duplex.BCR-2000
----------------------------------------------------------------------------]]--

-- default configuration of the BCR-2000
-- uses a custom device class, a control map and Mixer and Effect applications


--==============================================================================

class "BCR2000" (MidiDevice)

function BCR2000:__init(display_name, port_name, message_stream)
  TRACE("BCR2000:__init", display_name, port_name, message_stream)

  MidiDevice.__init(self, display_name, port_name, message_stream)

  -- the BFR can not handle looped back messages correctly, so we disable 
  -- sending back messages we got from the BFR, in order to break feedback loops...
  self.loopback_received_messages = false

end


--------------------------------------------------------------------------------

-- setup a Mixer and Effect application

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer & Effects",
  pinned = true,

  -- device properties
  device = {
    class_name = "BCR2000",          
    display_name = "BCR-2000",
    device_name = "BCR2000",
    control_map = "Controllers/BCR-2000/BCR-2000.xml",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "Encoders",
        },
        mute = {
          group_name = "Buttons1",
        },
        page = {
          group_name = "PageControls",
          index = 0
        }
      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name= "EffectEncoders",
        },
        page = {
          group_name = "PageControls",
          index = 2
        }
      }
    }
  }
}
