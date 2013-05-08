--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

-- setup "StepSequencer" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Performance_1",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 128",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Controlmaps/Monome128_Performance.xml",
    thumbnail = "Controllers/Monome/Monome.bmp",
    protocol = DEVICE_OSC_PROTOCOL,
  },
  applications = {

    Repeater = {
      mappings = {
        grid = {
          group_name = "Repeater",
        },
        --lock_button = {
        --  group_name = "Grid8x1",
        --  index = 1
        --},
        --prev_device = {
        --  group_name = "Grid8x1",
        --  index = 2
        --},
        --next_device = {
        --  group_name = "Grid8x1",
        --  index = 3
        --},
      }
    },
    TiltSensor = {
      application = "XYPad",
      mappings = {
        xy_pad = {
          group_name = "ADC",
          index = 1,
        },
        lock_button = {
          group_name = "Controls",
          index = 7
        },
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Navigator",
          orientation = VERTICAL,
        }
      }
    },
    Transport = {
      mappings = {
        stop_playback = {
          group_name = "Controls",
          index = 1,
        },
        start_playback = {
          group_name = "Controls",
          index = 2,
        },
        loop_pattern = {
          group_name = "Controls",
          index = 3,
        },
        edit_mode = {
          group_name = "Controls",
          index = 4,
        },
        --goto_previous = {
        --  group_name= "Controls",
        --  index = 5,
        --},
        --goto_next = {
        --  group_name= "Controls",
        --  index = 6,
        --},
      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name= "Effects",
          orientation = VERTICAL,
          flipped = false,
        },
        --device = {
        --  group_name = "Controls2",
        --},
        --device_prev = {
        --  group_name = "Grid1x5",
        --  index = 4
        --},
        --device_next = {
        --  group_name = "Grid1x5",
        --  index = 5
        --}
      },
    },
    Mixer = {
      mappings = {
        --levels = {
        --  group_name = "Grid",
        --},
        mute = {
          group_name = "MixerMute",
        },
        --page = {
        --  group_name = "Controls1",
        --  orientation = HORIZONTAL,
        --  index = 1,
        --},
        --mode = {
        --  group_name = "Controls2",
        --  index = 1,
        --},
      },
      options = {
        invert_mute = 2,
      }
    },

    TrackSelector = {
      mappings = {
        select_master = {
          group_name = "Master",
          index = 1
        },
        --prev_next_track = {
        --  group_name = "Grid1x5",
        --  index = 2,
        --  orientation = VERTICAL
        --}
      },
    },
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Matrix",
        },
        triggers = {
          group_name = "Triggers",
        },
        --sequence = {
        --  group_name = "Controls",
        --  index = 5,
        --  orientation = HORIZONTAL
        --},
        prev_seq_page = {
          group_name = "Controls",
          index = 5,
        },
        next_seq_page = {
          group_name = "Controls",
          index = 6,
        },
        --track = {
        --  group_name = "Controls",
        --  index = 3,
        --}
      }
    },


  }
}

