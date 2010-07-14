--[[----------------------------------------------------------------------------
-- Duplex.Remote-SL-MKII
----------------------------------------------------------------------------]]--

-- default configurations of the Remote-SL
-- only uses a control map and the Mixer application

--------------------------------------------------------------------------------

-- setup a Mixer + Effect for this configuration

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
