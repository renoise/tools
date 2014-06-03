duplex_configurations:insert {
  -- configuration properties
  name = "MuteGrid + Navigator + Matrix",
  pinned = true,
  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Controlmaps/Launchpad_Mixer.xml",
    thumbnail = "Controllers/Launchpad/Launchpad.bmp",
    protocol = DEVICE_PROTOCOL.MIDI,
  },
  applications = {
    Mixer = {
      mappings = {
        mute = {
          group_name = "Grid", -- this is where the grid is assigned
        },
      },
      options = {
        follow_track = 2, -- track follow is disabled
      },
      palette = {
        normal_mute_on = {
          color={0xff,0x00,0x00}
        },
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Controls",
          orientation = ORIENTATION.HORIZONTAL,
        }
      }
    },
    Matrix = {
      mappings = {
        triggers = {
          group_name = "Triggers",
          --orientation = ORIENTATION.HORIZONTAL,
        },
      },
      options = {
        sequence_mode = 2,
      },
    },
  }
}