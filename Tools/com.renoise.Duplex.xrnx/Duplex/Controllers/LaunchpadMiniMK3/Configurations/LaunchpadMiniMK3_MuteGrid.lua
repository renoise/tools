duplex_configurations:insert {
  -- configuration properties
  name = "MuteGrid + Navigator + Matrix",
  pinned = true,
  -- device properties
  device = {
    class_name = "LaunchpadMiniMK3",
    display_name = "Launchpad Mini MK3",
    device_port_in = "Launchpad Mini MK3 MIDI 2",
    device_port_out = "Launchpad Mini MK3 MIDI 2",
    control_map = "Controllers/LaunchpadMiniMK3/Controlmaps/LaunchpadMiniMK3_Mixer.xml",
    thumbnail = "Controllers/LaunchpadMiniMK3/LaunchpadMiniMK3.bmp",
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
      -- palette = {
      --   normal_mute_on = {
      --     color={0xff,0x00,0x00}
      --   },
      -- }
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