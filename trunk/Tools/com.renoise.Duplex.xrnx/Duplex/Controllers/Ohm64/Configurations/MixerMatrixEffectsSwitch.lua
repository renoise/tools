--[[----------------------------------------------------------------------------
-- Duplex.Ohm64 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix, Mixer, Effects & SwitchConfiguration",
  pinned = true,

  -- device properties
  device = {
    class_name = "Ohm64",          
    display_name = "Ohm64Switch",
    device_port_in = "Ohm64 MIDI 1",
    device_port_out = "Ohm64 MIDI 1",
    control_map = "Controllers/Ohm64/Controlmaps/Ohm64.xml",
    thumbnail = "Controllers/Ohm64/Ohm64.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },

  applications = {
    Mixer = {
      mappings = {
        panning = {
          group_name = "Panning_*",
        },
        levels = {
          group_name = "Volume_*",
        },
        mute = {
          group_name = "Buttons_*",
        },
      },
      options = {
        invert_mute = 1,
        follow_track = 1,
        page_size = 5,
      }
    },
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Grid",
        },
        triggers = {
          group_name = "Grid2",
        },
        prev_seq_page = {
          group_name = "ControlsRight",
          index = 1,
        },
        next_seq_page = {
          group_name = "ControlsRight",
          index = 2,
        },
        track = {
          group_name = "ControlsRight",
          index = 2,
        }
      },
      options = {
        follow_track = 1,
        page_size = 5,
      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name= "EncodersEffect",
        },
        param_prev = {
          group_name = "ControlsRight",
          index = 5,
        },
        param_next = {
          group_name = "ControlsRight",
          index = 6,
        },
      }
    },
    Transport = {
      mappings = {
        start_playback = {
          group_name = "BigButton",
          index = 1,
        },        
      },
      options = {
        pattern_play = 3,
      }
    },
    SwitchConfiguration = {
      mappings = {
        goto_previous = {
            group_name = "CrossFader",
            index = 1,
        },
        goto_next = {
            group_name = "CrossFader",
            index = 3,
        },
      }
    },

  }
}

