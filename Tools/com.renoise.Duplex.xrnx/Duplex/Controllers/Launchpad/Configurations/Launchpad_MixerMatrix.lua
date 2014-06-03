--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix + Mixer + Transport",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Controlmaps/Launchpad_MatrixMixer.xml",
    thumbnail = "Controllers/Launchpad/Launchpad.bmp",
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
        master = {
          group_name = "Triggers2",
        }
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


