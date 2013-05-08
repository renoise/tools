--[[----------------------------------------------------------------------------
-- Duplex.APC40
----------------------------------------------------------------------------]]--

-- setup "XYPad + Effect + Navigator + Transport + Mixer",

duplex_configurations:insert {

  -- configuration properties
  name = "XYPad + Repeater",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "APC40",
    display_name = "APC40",
    device_port_in = "Akai APC40",
    device_port_out = "Akai APC40",
    control_map = "Controllers/APC40/Controlmaps/APC40_XYPad_Repeater.xml",
    thumbnail = "Controllers/APC40/APC40.bmp",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    XYPad_1 = {
      application = "XYPad",
      mappings = {
        x_slider = {
          group_name = "Track Fader",
          index = 1
        },
        y_slider = {
          group_name = "Track Fader",
          index = 2
        },
        xy_grid = {
          group_name = "Slot_1",
        },
        lock_button = {
          group_name = "Trigger",
          index = 1
        },
        prev_device = {
          group_name = "Slot_2",
          index = 1
        },
        next_device = {
          group_name = "Slot_2",
          index = 2
        }
               
      },        
      palette = {
        foreground = {
          color={0xFF,0x00,0x00}, 
        },
        background = {
          color={0xFF,0xFF,0x00}, 
        }
      },
      options = {
        unique_id = 1,
        record_method = 2,
        locked = 1
      }
    },
    XYPad_2 = {
      application = "XYPad",
      mappings = {
        x_slider = {
          group_name = "Track Fader",
          index = 3
        },
        y_slider = {
          group_name = "Track Fader",
          index = 4
        },
        xy_grid = {
          group_name = "Slot_3",
        },
        lock_button = {
          group_name = "Trigger",
          index = 2
        },
        prev_device = {
          group_name = "Slot_2",
          index = 3
        },
        next_device = {
          group_name = "Slot_2",
          index = 4
        }
               
      },        
      palette = {
        foreground = {
          color={0xFF,0x00,0x00}, 
        },
        background = {
          color={0xFF,0xFF,0x00}, 
        }
      },
      options = {
        unique_id = 1,
        record_method = 2,
        locked = 1
      }
    },
    Repeater = {
      mappings = {
        grid = {
          group_name = "Slot_4",
        },
        prev_device = {
          group_name = "Slot_5",
          index = 7
        },
        next_device = {
          group_name = "Slot_5",
          index = 8
        },
        mode_free = {
          group_name = "Slot_5",
          index = 1
        },
        mode_even = {
          group_name = "Slot_5",
          index = 2
        },
        mode_triplet = {
          group_name = "Slot_5",
          index = 3
        },
        mode_dotted = {
          group_name = "Slot_5",
          index = 4
        },
        lock_button = {
          group_name = "Trigger",
          index = 4
        },
        mode_slider = {
          group_name = "Track Fader",
          index = 5
        },
        divisor_slider = {
          group_name = "Track Fader",
          index = 6
        }
      }
    },
    TrackSelector = {
      mappings = {
        prev_next_page = {
          group_name = "Move",
          index = 1,
        },
        prev_next_track = {
          group_name = "Activator",
          index = 3,
        },
        select_track = {
          group_name = "Track Selector",
          index = 1,
        }
      }
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
        mute = {
          group_name = "Mute",
        },
        solo = {
          group_name = "Solo",
        },
        master = {
          group_name = "Master Fader",
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
        page = {
          group_name = "Control",
          index = 1,
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
          orientation = HORIZONTAL,
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

