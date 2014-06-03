--[[----------------------------------------------------------------------------
-- Duplex.APC20
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "XYPad + Navigator + Transport + Mixer",
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
    XYPad1 = {
      application = "XYPad",
      mappings = {
        xy_grid = {
          group_name = "Slot",
        },
        lock_button = {
          group_name = "Trigger",
          index = 1
        },
        focus_button = {
          group_name = "Trigger",
          index = 2
        },
        prev_device = {
          group_name = "Trigger",
          index = 3
        },
        next_device = {
          group_name = "Trigger",
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
        }
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
    }
  }
}

