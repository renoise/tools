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

-- setup Effect as the only app for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Effect",
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

--------------------------------------------------------------------------------

-- setup Mixer + Transport for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Transport",
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
      },
    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name = "Pots",
          index = 1,
        },
        goto_next = {
          group_name = "Pots",
          index = 2,
        },
        stop_playback = {
          group_name = "Pots",
          index = 3,
        },
        start_playback = {
          group_name = "Pots",
          index = 4,
        },
        loop_pattern = {
          group_name = "Pots",
          index = 5,
        },
        edit_mode = {
          group_name = "Pots",
          index = 6,
        },
        block_loop = {
          group_name = "Pots",
          index = 7,
        },
      },
    },
  }
}
