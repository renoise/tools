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
    thumbnail = "Launchpad.bmp",
    protocol = DEVICE_MIDI_PROTOCOL,
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
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Controls",
          orientation = HORIZONTAL,
        }
      }
    },
    Matrix = {
      mappings = {
        triggers = {
          group_name = "Triggers",
          --orientation = HORIZONTAL,
        },
      },
      options = {
        sequence_mode = 2,
      }
    },
  }
}