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
    class_name = "LaunchpadMiniMK3",
    display_name = "Launchpad Mini MK3",
    device_port_in = "Launchpad Mini MK3 MIDI 2",
    device_port_out = "Launchpad Mini MK3 MIDI 2",
    control_map = "Controllers/LaunchpadMiniMK3/Controlmaps/LaunchpadMiniMK3_XYPad.xml",
    thumbnail = "Controllers/LaunchpadMiniMK3/LaunchpadMiniMK3.bmp",
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

