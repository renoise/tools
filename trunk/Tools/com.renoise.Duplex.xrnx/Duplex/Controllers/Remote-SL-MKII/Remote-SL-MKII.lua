--[[----------------------------------------------------------------------------
-- Duplex.Remote-SL-MKII
----------------------------------------------------------------------------]]--

-- default configurations of the Remote-SL
-- only uses a control map and the Mixer application

--------------------------------------------------------------------------------

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer & Effects",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Remote SL MKII Automap",
    device_name = "Automap MIDI",
    control_map = "Controllers/Remote-SL-MKII/Remote-SL-MKII.xml",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  -- setup a Mixer as the only app for this configuration
  applications = {
    Mixer = {
      levels = {
        group_name = "Sliders",
      },
      mute = {
        group_name = "SliderButtons",
      }
    },
    Effect = {
      parameters = {
        group_name= "Encoders",
      },
      page = {
        group_name = "EncoderButtons",
        index = 0
      }
    },
  }
}
