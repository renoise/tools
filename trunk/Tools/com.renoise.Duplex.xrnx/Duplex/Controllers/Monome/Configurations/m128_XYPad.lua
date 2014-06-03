--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "XYPad + Repeater",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 128",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Controlmaps/Monome128_XYPad.xml",
    thumbnail = "Controllers/Monome/Monome.bmp",
    protocol = DEVICE_PROTOCOL.OSC,
  },
  applications = {
    Repeater = {
      mappings = {
        grid = {
          group_name = "Grid8x3"
        },
        lock_button = {
          group_name = "Grid8x1",
          index = 1
        },
        prev_device = {
          group_name = "Grid8x1",
          index = 2
        },
        next_device = {
          group_name = "Grid8x1",
          index = 3
        },
      }
    },
    Grid7x7 = {
      application = "XYPad",
      mappings = {
        xy_grid = {
          group_name = "Grid7x7",
        },
        lock_button = {
          group_name = "Controls",
          index = 6
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
    Transport = {
      mappings = {
        start_playback = {
          group_name = "Controls",
          index = 1,
        },
        edit_mode = {
          group_name = "Controls",
          index = 2,
        },
        goto_previous = {
          group_name= "Grid1x5",
          index = 4,
        },
        goto_next = {
          group_name= "Grid1x5",
          index = 5,
        },
      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name= "Grid8x5",
        },
      },
    },
    TrackSelector = {
      mappings = {
        select_master = {
          group_name = "Grid1x5",
          index = 1
        },
        prev_track = {
          group_name = "Grid1x5",
          index = 2,
        },
        next_track = {
          group_name = "Grid1x5",
          index = 3,
        },

      },
      palette = {
        track_prev_on       = { text = "?"},
        track_prev_off      = { text = "?"},
        track_next_on       = { text = "?"},
        track_next_off      = { text = "?"},
      }
    }

  }
}

