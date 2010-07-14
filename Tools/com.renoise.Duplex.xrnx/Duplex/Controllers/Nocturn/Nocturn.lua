--[[----------------------------------------------------------------------------
-- Duplex.Nocturn
----------------------------------------------------------------------------]]--

-- default configurations of the Nocturn

--------------------------------------------------------------------------------

-- setup a Mixer as the only app for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Nocturn Automap",
    device_name = "Automap MIDI",
    control_map = "Controllers/Nocturn/Nocturn.xml",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "Encoders",
        },
        mute = {
          group_name = "Pots",
        },
        master = {
          group_name = "XFader",
        },
      }
    }
  }
}

--------------------------------------------------------------------------------

-- setup an Effect as the only app for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Effect",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Nocturn Automap 2",
    device_name = "Automap MIDI",
    control_map = "Controllers/Nocturn/Nocturn.xml",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    Effect = {
      mappings = {
        parameters = {
          group_name= "Encoders",
        },
        page = {
          group_name = "XFader",
        },
        device = {
          group_name = "Pots",
        },
      },
      options = {
        
      }
    }
  }
}
