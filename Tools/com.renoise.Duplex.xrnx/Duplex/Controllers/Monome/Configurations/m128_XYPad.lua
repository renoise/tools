--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

-- setup "StepSequencer" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "XYPad",
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
    protocol = DEVICE_OSC_PROTOCOL,
  },
  applications = {
    Grid8x3 = {
      application = "XYPad",
      mappings = {
        xy_grid = {
          group_name = "Grid8x3",
        },
      },
      palette = {
        foreground = {
          color={0x00,0x00,0x00}, 
        },  
        background = {
          color={0xFF,0xFF,0x00}, 
        },  
      }
    },
    Grid8x3_Extra = {
      application = "XYPad",
      mappings = {
        xy_grid = {
          group_name = "Grid8x3_Extra",
        },
      }
    },
    Grid7x7 = {
      application = "XYPad",
      mappings = {
        xy_grid = {
          group_name = "Grid7x7",
        },
        --prev_device = {
        --  group_name = "Controls",
        --  index = 4
        --},
        --next_device = {
        --  group_name = "Controls",
        --  index = 5
        --},
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
    TrackSelector = {
      mappings = {
        select_master = {
          group_name = "Grid1x5",
          index = 1
        },
        prev_next_track = {
          group_name = "Grid1x5",
          index = 2,
          orientation = VERTICAL
        }
      },
    }

  }
}

