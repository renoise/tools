--[[----------------------------------------------------------------------------
-- Duplex.APC20
----------------------------------------------------------------------------]]--

-- setup "Matrix + Navigator + Transport + Mixer",

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix + Navigator + Transport + Mixer",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "APC20",
    display_name = "APC20",
    device_port_in = "APC20",
    device_port_out = "APC20",
    control_map = "Controllers/APC20/Controlmaps/APC20.xml",
    thumbnail = "Controllers/APC20/APC20.bmp",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Slot",
        },
        triggers = {
          group_name = "Trigger",
        },
        sequence = {
          group_name = "Activator",
          index = 7,
        },
        track = {
          group_name = "Activator",
          index = 5,
        }
      }
    },
    Transport = {
      mappings = {
        start_playback = {
          group_name = "Transport",
          index = 1,
        },
        stop_playback = {
          group_name = "Transport",
          index = 2,
        },
        edit_mode = {
          group_name = "Transport",
          index = 3,
        },
        loop_pattern = {
          group_name = "Transport",
          index = 4,
        },
        follow_player = {
          group_name = "Transport",
          index = 5,
        },
        block_loop = {
          group_name = "Transport",
          index = 6,
        },
        goto_previous = {
          group_name = "Transport",
          index = 7,
        },
        goto_next = {
          group_name = "Transport",
          index = 8,
        },
      }
    },
    Mixer = {
      mappings = {
        levels = {
          group_name = "Track Fader",
        },
        mode = {
          group_name = "Note Mode",
          index = 1,
        },
        mute = {
          group_name = "Mute",
        },
        solo = {
          group_name = "Solo",
        },
        master = {
          group_name = "Master Fader",
        },
        page = {
          group_name = "Activator",
          index = 5,
        },
      },
      options = {
        invert_mute = 1,
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Navigator",
          orientation = HORIZONTAL,
        },
      }
    },
  }
}

