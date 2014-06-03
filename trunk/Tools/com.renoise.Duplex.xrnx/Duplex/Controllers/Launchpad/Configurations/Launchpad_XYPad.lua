--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

-- setup Daxton's Step Sequencer for the Launchpad

duplex_configurations:insert {

  -- configuration properties
  name = "XYPad + Repeater",
  pinned = true,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Controlmaps/Launchpad_XYPad.xml",
    thumbnail = "Controllers/Launchpad/Launchpad.bmp",
    protocol = DEVICE_PROTOCOL.MIDI,
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
        grid_on = {
          color={0x80,0xFF,0x00}, 
        },
        grid_off = {
          color={0x00,0x40,0x00}, 
        }
      },
      options = {
        record_method = 2,
        locked = 1
      }
    },

    Repeater = {
      mappings = {
        grid = {
          group_name = "Pad_5"
        },
        lock_button = {
          group_name = "Pad_6",
          index = 1
        },
        prev_device = {
          group_name = "Pad_6",
          index = 2
        },
        next_device = {
          group_name = "Pad_6",
          index = 3
        },
      }
    }
  }
}

