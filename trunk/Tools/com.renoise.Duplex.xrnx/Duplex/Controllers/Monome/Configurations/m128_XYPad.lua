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
    --[[
    ]]
    Grid8x5 = {
      application = "XYPad",
      mappings = {
        xy_grid = {
          group_name = "Grid8x5",
        },
        focus_button = {
          group_name = "Grid8x5",
          index = 5
        },
      },
      options = {
        unique_id = 1,
      }
    },
    Grid8x3 = {
      application = "XYPad",
      mappings = {
        xy_grid = {
          group_name = "Grid8x3",
        },
        focus_button = {
          group_name = "Controls",
          index = 6
        },
      },
      palette = {
        foreground = {
          color={0x00,0x00,0x00}, 
        },  
        background = {
          color={0xFF,0xFF,0x00}, 
        },  
      },
      options = {
        unique_id = 2,
      }
    },
    Grid8x3_Extra = {
      application = "XYPad",
      mappings = {
        xy_grid = {
          group_name = "Grid8x3_Extra",
        },
      },
      options = {
        unique_id = 3,
      }
    },
    Grid1x5 = {
      application = "XYPad",
      mappings = {
        xy_grid = {
          group_name = "Grid1x5",
        },
      },
      palette = {
        foreground = {
          color={0x00,0x00,0x00}, 
        },  
        background = {
          color={0xFF,0xFF,0x00}, 
        },  
      },
      options = {
        unique_id = 4,
      }
    },
    Grid7x7 = {
      application = "XYPad",
      mappings = {
        xy_grid = {
          group_name = "Grid7x7",
        },
      },
      options = {
        unique_id = 5,
      }
    },
    TiltSensor = {
      application = "XYPad",
      mappings = {
        xy_pad = {
          group_name = "ADC",
          index = 1,
        },
        focus_button = {
          group_name = "Controls",
          index = 7
        },
      },
      options = {
        unique_id = 6,
      }
    },
    --[[
    ]]
  }
}

