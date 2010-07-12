--[[----------------------------------------------------------------------------
-- Duplex.BCR-2000
----------------------------------------------------------------------------]]--

-- default configuration of the BCR-2000
-- uses a custom device class, a control map and Mixer and Effect applications


--==============================================================================

class "BFR2000" (MidiDevice)

function BFR2000:__init(name, message_stream)
  TRACE("BFR2000:__init", name, message_stream)

  MidiDevice.__init(self, name, message_stream)

  -- the BFR can not handle looped back messages correctly, so we disable 
  -- sending back messages we got from the BFR, in order to break feedback loops...
  self.loopback_received_messages = false
end


--------------------------------------------------------------------------------

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer & Effects",
  pinned = true,

  -- device properties
  device = {
    class_name = "BFR2000",          
    display_name = "BCR-2000",
    device_name = "BCR2000",
    control_map = "Controllers/BCR-2000/BCR-2000.xml",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  -- setup a Mixer and Effect application
  applications = {
    Mixer = {
      levels = {
        group_name = "Encoders",
      },
      mute = {
        group_name = "Buttons1",
      },
      solo = {
        group_name = "Buttons2",
      },
      page = {
        group_name = "PageControls",
        index = 0
      }
    },
    Effect = {
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
