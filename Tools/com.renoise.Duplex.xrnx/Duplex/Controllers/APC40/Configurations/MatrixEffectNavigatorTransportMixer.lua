--[[----------------------------------------------------------------------------
-- Duplex.APC40
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix + Effect + Navigator + Transport + Mixer",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "APC40",
    display_name = "APC40",
    device_port_in = "Akai APC40",
    device_port_out = "Akai APC40",
    control_map = "Controllers/APC40/Controlmaps/APC40.xml",
    thumbnail = "Controllers/APC40/APC40.bmp",
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
        prev_seq_page = {
          group_name = "Move",
          index = 3,
        },
        next_seq_page = {
          group_name = "Move",
          index = 4,
        },
        track = {
          group_name = "Move",
          index = 1,
        }
      },
      options = {
        follow_track = 1,
      }
    },
    TrackSelector = {
      mappings = {
        prev_page = {
          group_name = "Move",
          index = 1,
        },
        next_page = {
          group_name = "Move",
          index = 2,
        },
        prev_track = {
          group_name = "Activator",
          index = 3,
        },
        next_track = {
          group_name = "Activator",
          index = 4,
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
          group_name = "Activator",
          index = 5,
        },
        goto_next = {
          group_name = "Activator",
          index = 6,
        },
        follow_player = {
          group_name = "Control",
          index = 7,
        },
        metronome_toggle = {
          group_name = "Control",
          index = 8,
        },
        loop_pattern = {
          group_name = "Activator",
          index = 1,
        },
        block_loop = {
          group_name = "Activator",
          index = 2,
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
          group_name = "Upper Knob1",
        },
        mode = {
          group_name = "Note Mode",
        },
      },
      options = {
        invert_mute = 1,
        follow_track = 1,
        take_over_volumes = 2
      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name = "Lower Knob1",
        },
        param_prev = {
          group_name = "Control",
          index = 1,
        },
        param_next = {
          group_name = "Control",
          index = 2,
        },
        device_prev = {
          group_name = "Control",
          index = 3,
        },
        device_next = {
          group_name = "Control",
          index = 4,
        },
        preset_prev = {
          group_name = "Control",
          index = 5,
        },
        preset_next = {
          group_name = "Control",
          index = 6,
        },
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

