--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

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
    protocol = DEVICE_PROTOCOL.OSC,
  },
  applications = {

    Repeater = {
      mappings = {
        grid = {
          group_name = "Repeater",
        },
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
          orientation = ORIENTATION.VERTICAL,
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

      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name= "Effects",
          orientation = ORIENTATION.VERTICAL,
          flipped = false,
        },
      },
    },
    Mixer = {
      mappings = {
        mute = {
          group_name = "MixerMute",
        },

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
        prev_seq_page = {
          group_name = "Controls",
          index = 5,
        },
        next_seq_page = {
          group_name = "Controls",
          index = 6,
        },
      }
    },


  }
}

