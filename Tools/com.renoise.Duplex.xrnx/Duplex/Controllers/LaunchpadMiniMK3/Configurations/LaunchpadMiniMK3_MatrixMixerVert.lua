--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix + Mixer + Transport (vert)",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "LaunchpadMiniMK3",
    display_name = "Launchpad Mini MK3",
    device_port_in = "Launchpad Mini MK3 MIDI 2",
    device_port_out = "Launchpad Mini MK3 MIDI 2",
    control_map = "Controllers/LaunchpadMiniMK3/Controlmaps/LaunchpadMiniMK3_MatrixMixerVert.xml",
    thumbnail = "Controllers/LaunchpadMiniMK3/LaunchpadMiniMK3.bmp",
    protocol = DEVICE_PROTOCOL.MIDI,
  },

  applications = {
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Grid",
        },
        triggers = {
          group_name = "Triggers",
        },
        prev_seq_page = {
          group_name = "Controls",
          index = 1,
        },
        next_seq_page = {
          group_name = "Controls",
          index = 2,
        },
        track = {
          group_name = "Controls",
          index = 3,
        }
      },
      options = {      
      }
    },
    Mixer = {
      mappings = {
        levels = {
          group_name = "Grid2",
        },
        mute = {
          group_name = "Grid2",
        },
      },
      options = {
        invert_mute = 1
      }
    },
    Transport = {
      mappings = {
        stop_playback = {
          group_name= "Controls",
          index = 5,
        },
        start_playback = {
          group_name = "Controls",
          index = 6,
        },
        loop_pattern = {
          group_name = "Controls",
          index = 7,
        },
        edit_mode = {
          group_name = "Controls",
          index = 8,
        },
      },
      options = {
      }
    },
  }
}


