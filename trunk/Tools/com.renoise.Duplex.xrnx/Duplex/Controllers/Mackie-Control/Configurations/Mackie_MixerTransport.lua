--[[----------------------------------------------------------------------------
-- Duplex.Mackie-Control
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = "MackieControl",          
    display_name = "Mackie-Control",
    device_port_in = "",
    device_port_out = "",
    control_map = "Controllers/Mackie-Control/Controlmaps/Mackie-Control.xml",
    thumbnail = "Controllers/Mackie-Control/Mackie-Control.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    Mixer = {
      mappings = {
        solo = {
          group_name = "Solo",
        },
        mute = {
          group_name = "Mute",
        },
        levels = {
          group_name = "Faders",
        },
        master = {
          group_name = "Master_Fader",
        },
        mode = {
          group_name = "Function",
          index = 1,
        },
      },
      options = {
        invert_mute = 1,
        follow_track = 1,
        take_over_volumes = 2,
      }
    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name = "Transport",
          index = 1,
        },
        goto_next = {
          group_name = "Transport",
          index = 2,
        },
        stop_playback = {
          group_name = "Transport",
          index = 3,
        },
        start_playback = {
          group_name = "Transport",
          index = 4,
        },
        edit_mode = {
          group_name = "Transport",
          index = 5,
        },
        loop_pattern = {
          group_name = "Function",
          index = 6,
        },
        block_loop = {
          group_name = "Function",
          index = 7,
        },
        follow_player = {
          group_name = "Function",
          index = 4,
        },
        metronome_toggle = {
          group_name = "Function",
          index = 5,
        },
      },
      options = {
      }
    },
    TrackSelector = {
      mappings = {
        prev_page = {
          group_name = "Fader_Bank",
          index = 1,
        },
        next_page = {
          group_name = "Fader_Bank",
          index = 2,
        },
        prev_track = {
          group_name = "Cursor",
          index = 1,
        },
        next_track = {
          group_name = "Cursor",
          index = 2,
        },
        select_track = {
          group_name = "Select",
          index = 1,
        },
        select_first = {
          group_name = "Function",
          index = 2,
        },
        select_sends = {
          group_name = "Function",
          index = 3,
        },
      },
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Rec",
          orientation = ORIENTATION.HORIZONTAL,
        },
      }
    },
    SwitchConfiguration = {
      mappings = {
        goto_previous = {
          group_name = "Cursor",
          index = 3,
        },
        goto_next = {
          group_name = "Cursor",
          index = 4,
        },
      }
    },
  }
}



