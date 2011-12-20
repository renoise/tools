--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

-- setup Daxton's Step Sequencer for the Launchpad

duplex_configurations:insert {

  -- configuration properties
  name = "XYPad",
  pinned = true,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Controlmaps/Launchpad_XYPad.xml",
    thumbnail = "Controllers/Launchpad/Launchpad.bmp",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    Pad1_Green = {
      application = "XYPad",
      mappings = {
        xy_grid = {
          group_name = "Pad_1"
        },
        lock_button = {
          group_name = "Pad_1_Controls",
          index = 1
        },
        focus_button = {
          group_name = "Pad_1_Controls",
          index = 2
        },
        prev_device = {
          group_name = "Pad_1_Controls",
          index = 3
        },
        next_device = {
          group_name = "Pad_1_Controls",
          index = 4
        }
      },
      palette = {
        foreground = {
          color={0x80,0xFF,0x00}, 
        },
        background = {
          color={0x00,0x40,0x00}, 
        }
      },
      options = {
        unique_id = 1,
        record_method = 2,
        locked = 1
      }
    },
    --[[
    XYPadControl = {
      application = "XYPad",
      mappings = {
        xy_grid = {
          group_name = "Pad_1_Controls",
          index = 5
        }
      },
      palette = {
        foreground = {
          color={0x80,0xFF,0x00}, 
        },
        background = {
          color={0x00,0x40,0x00}, 
        }
      },
      options = {
        unique_id = 2
      }
    },
    ]]
    Pad5_Red = {
      application = "XYPad",
      mappings = {
        xy_grid = {
          group_name = "Pad_5"
        }
      },
      palette = {
        foreground = {
          color={0xFF,0x80,0x00}, 
        },
        background = {
          color={0x40,0x00,0x00}, 
        }
      },
      options = {
        unique_id = 5,
        locked = 1
      }
    },
    Pad5_Red_Extra = {
      application = "XYPad",
      mappings = {
        xy_grid = {
          group_name = "Pad_6"
        }
      },
      palette = {
        foreground = {
          color={0xFF,0x80,0x00}, 
        },
        background = {
          color={0x40,0x00,0x00}, 
        }
      },
      options = {
        unique_id = 6,
        locked = 1
      }
    }
  }
}

