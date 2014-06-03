--[[----------------------------------------------------------------------------
-- Duplex.APC20
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix + Navigator + Transport + Mixer",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "APC20",
    display_name = "APC20",
    device_port_in = "Akai APC20",
    device_port_out = "Akai APC20",
    control_map = "Controllers/APC20/Controlmaps/APC20.xml",
    thumbnail = "Controllers/APC20/APC20.bmp",
    protocol = DEVICE_PROTOCOL.MIDI,
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
        track = {
          group_name = "Transport",
          index = 5,
        },
        prev_seq_page = {
          group_name = "Transport",
          index = 7,
        },
        next_seq_page = {
          group_name = "Transport",
          index = 8,
        },
      },
      options = {
        follow_track = 1,
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
          group_name = "Activator",
          index = 1,
        },
        follow_player = {
          group_name = "Transport",
          index = 4,
        },
        metronome_toggle = {
          group_name = "Activator",
          index = 3,
        },
        block_loop = {
          group_name = "Activator",
          index = 2,
        },
        goto_previous = {
          group_name = "Activator",
          index = 5,
        },
        goto_next = {
          group_name = "Activator",
          index = 6,
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
          group_name = "Transport",
          index = 5,
        },
      },
      options = {
        invert_mute = 1,
        follow_track = 1,
        take_over_volumes = 2,
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Navigator",
          orientation = ORIENTATION.HORIZONTAL,
        },
      }
    },
    BPM_Set = {
      application = "MidiActions",
      mappings = {control = {group_name = "Cue Level"}},
      options = {
        action = "Transport:Song:BPM [Set]",
        min_scaling = "64",
        max_scaling = "200",
        scaling = "Exp+"
      }
    },
    SwitchConfiguration = {
      mappings = {
        goto_previous = {
          group_name = "Activator",
          index = 7,
        },
        goto_next = {
          group_name = "Activator",
          index = 8,
        },
      }
    },
  }
}

