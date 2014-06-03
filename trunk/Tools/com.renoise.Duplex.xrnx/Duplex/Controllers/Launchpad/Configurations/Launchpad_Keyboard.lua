--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Keyboard",
  pinned = true,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Controlmaps/Launchpad_Keyboard.xml",
    thumbnail = "Controllers/Launchpad/Launchpad.bmp",
    protocol = DEVICE_PROTOCOL.MIDI,
  },

  applications = {
    KeypadsLeft = {
      application = "Keyboard",
      mappings = {
        key_grid = {
          group_name = "KeypadsLeft"
        },
      },
      palette = {
        key_pressed = {
          color = {0xFF,0xFF,0x80}
        },
        key_released = {
          color = {0x40,0x00,0x40}
        },
        key_released_content = {
          color = {0xFF,0x40,0x40}
        },
        key_released_selected = {
          color = {0xFF,0x80,0x40}
        },
      },
      options = {
        base_octave = 4
      },
      hidden_options = {  -- display minimal set of options
        "channel_pressure","pitch_bend","release_type","button_width","button_height"
      },
    },
    KeypadsRight = {
      application = "Keyboard",
      mappings = {
        key_grid = {
          group_name = "KeypadsRight"
        },
      },
      palette = {
        key_pressed = {
          color = {0xFF,0xFF,0xFF}
        },
        key_released = {
          color = {0x00,0x40,0x40}
        },
        key_released_content = {
          color = {0x40,0xFF,0x40}
        },
        key_released_selected = {
          color = {0x80,0xFF,0x40}
        },
      },
      options = {
        base_octave = 5
      },
      hidden_options = {  -- display minimal set of options
        "channel_pressure","pitch_bend","release_type","button_width","button_height"
      },
    },
    KeyboardSplit1 = {
      application = "Keyboard",
      mappings = {
        key_grid = {
          group_name = "LargeGrid",
          orientation = ORIENTATION.HORIZONTAL,
        },
        octave_down = {
          group_name = "Controls",
          index = 2
        },
        octave_up = {
          group_name = "Controls",
          index = 1
        },
        volume = {
          group_name = "Triggers",
          orientation = ORIENTATION.VERTICAL,
          index = 1
        }
      },
      palette = {
        key_pressed = {
          color = {0xFF,0x00,0xFF}
        },
        key_released = {
          color = {0x40,0x00,0x00}
        },
        key_released_content = {
          color = {0x80,0x00,0x00}
        },
        key_released_selected = {
          color = {0xC0,0x00,0x00}
        },
      },
      options = {
      },
      hidden_options = {  -- display minimal set of options
        "channel_pressure","pitch_bend","release_type","button_width","button_height"
      },
    },

    TrackSelector = {
      mappings = {
        prev_track = {
          group_name = "Controls",
          index = 3,
        },
        next_track = {
          group_name = "Controls",
          index = 4,
        },

      }
    },
    Transport = {
      mappings = {
        start_playback = {
          group_name = "Controls",
          index = 5,
        },
        loop_pattern = {
          group_name = "Controls",
          index = 6,
        },
        follow_player = {
          group_name= "Controls",
          index = 7,
        },
        block_loop = {
          group_name = "Controls",
          index = 8,
        },
      },
      options = {
        pattern_play = 3, -- toggle start/stop with single button
      },
    },
  }
}

