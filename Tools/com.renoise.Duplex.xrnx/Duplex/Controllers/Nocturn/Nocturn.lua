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
    device_port_in = "Automap MIDI",
    device_port_out = "Automap MIDI",
    control_map = "Controllers/Nocturn/Nocturn.xml",
    thumbnail = "Nocturn.bmp",
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
    device_port_in = "Automap MIDI",
    device_port_out = "Automap MIDI",
    control_map = "Controllers/Nocturn/Nocturn.xml",
    thumbnail = "Nocturn.bmp",
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
    device_port_in = "Automap MIDI",
    device_port_out = "Automap MIDI",
    control_map = "Controllers/Nocturn/Nocturn.xml",
    thumbnail = "Nocturn.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "Encoders",
        },
        master = {
          group_name = "XFader",
        },
        mode = {
          group_name = "Pots",
          index = 8,
        }

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
      options = {
      }

    },
  }
}


--------------------------------------------------------------------------------

-- setup "Recorder" as the only app for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Recorder BETA",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Nocturn Automap",
    device_port_in = "Automap MIDI",
    device_port_out = "Automap MIDI",
    control_map = "Controllers/Nocturn/Nocturn.xml",
    thumbnail = "Nocturn.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    Recorder = {
      mappings = {
        recorders = {
          group_name = "Pots",
        },
        sliders = {
          group_name = "Encoders",
        },
        --[[
        pattern = {
          group_name = "Triggers",
        }
        ]]
      },
      options = {
        --writeahead = 1,
        --loop_mode = 2,
        --beat_sync = 1,
        --trigger_mode = 1,
      }
    }
  }
}

--------------------------------------------------------------------------------

-- setup Navigator on the buttons, leave sliders/crossfader unassigned

duplex_configurations:insert {

  -- configuration properties
  name = "Navigator",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Nocturn Automap",
    device_port_in = "Automap MIDI",
    device_port_out = "Automap MIDI",
    control_map = "Controllers/Nocturn/Nocturn.xml",
    thumbnail = "Nocturn.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    Navigator = {
      mappings = {
        blockpos = {
          group_name= "Pots",
          orientation = HORIZONTAL,
        },
      },
    }
  }
}

--------------------------------------------------------------------------------

-- setup TrackSelector as the only app for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "TrackSelector",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Nocturn Automap",
    device_port_in = "Automap MIDI",
    device_port_out = "Automap MIDI",
    control_map = "Controllers/Nocturn/Nocturn.xml",
    thumbnail = "Nocturn.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    TrackSelector = {
      mappings = {
      --[[
        prev_next_track = {
          -- mapped to a UISpinner
          group_name= "Pots",
          orientation = HORIZONTAL,
          index = 1,
        },
        ]]
        prev_next_page = {
          -- mapped to a UISpinner
          group_name= "XFader",
          orientation = HORIZONTAL,
          index = 1,
        },
        select_track = {
          -- mapped to a UISlider
          group_name= "Pots",
          --orientation = HORIZONTAL,
          index = 1,
        },
      },
    }
  }
}

