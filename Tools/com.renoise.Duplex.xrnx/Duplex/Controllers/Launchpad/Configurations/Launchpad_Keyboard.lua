--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

-- setup Daxton's Step Sequencer for the Launchpad

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
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    --[[
    ]]
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
      }
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
      }
    },
    Keyboard = {
      mappings = {
        key_grid = {
          group_name = "LargeGrid",
          orientation = HORIZONTAL,
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
          orientation = VERTICAL,
          index = 1
        }
      } 
    },
    TrackSelector = {
      mappings = {
        prev_next_track = {
          group_name = "Controls",
          index = 3,
        }
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

