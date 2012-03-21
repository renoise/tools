--[[----------------------------------------------------------------------------
-- Duplex.APC40
----------------------------------------------------------------------------]]--

-- setup "Matrix + Effect + Navigator + Transport + Mixer",

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix + Effect + Navigator + Transport + Mixer",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "APC40",
    display_name = "APC40",
    device_port_in = "APC40",
    device_port_out = "APC40",
    control_map = "Controllers/APC40/Controlmaps/APC40.xml",
    thumbnail = "Controllers/APC40/APC40.bmp",
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
          group_name = "Move",
          index = 3,
        },
        track = {
          group_name = "Move",
          index = 1,
        }
      }
    },
    TrackSelector = {
      mappings = {
        prev_next_page = {
          group_name = "Move",
          index = 1,
        },
        select_track = {
          group_name = "Track Selector",
          index = 1,
        },
      },
    },
    Transport = {
      mappings = {
        stop_playback = {
          group_name = "Transport",
          index = 2,
        },
        start_playback = {
          group_name = "Transport",
          index = 1,
        },
        edit_mode = {
          group_name = "Transport",
          index = 3,
        },
        goto_previous = {
          group_name = "Control",
          index = 5,
        },
        goto_next = {
          group_name = "Control",
          index = 6,
        },
        follow_player = {
          group_name = "Control",
          index = 7,
        },
        block_loop = {
          group_name = "Block Loop",
          index = 1,
        },
      }
    },
    Mixer = {
      mappings = {
        levels = {
          group_name = "Track Fader",
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
          group_name = "Move",
          index = 1,
        },
        panning = {
          group_name = "Panning Knob",
        },
        mode = {
          group_name = "Note Mode",
        },
      },
      options = {
        invert_mute = 1,
        take_over_volumes = 2
      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name = "Device Knob",
        },
        page = {
          group_name = "Control",
          index = 3,
        },
        device = {
          group_name = "Device Selector",
        },
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

