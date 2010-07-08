--[[----------------------------------------------------------------------------
-- Duplex.BCR-2000
----------------------------------------------------------------------------]]--

-- default configuration of the BCR-2000


--------------------------------------------------------------------------------

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer & Effects",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "BCR-2000",
    device_name = "BCR2000",
    control_map = "Controllers/BCR-2000/BCR-2000.xml",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  -- setup a MixConsole and Effect application
  applications = {
    MixConsole = {
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
