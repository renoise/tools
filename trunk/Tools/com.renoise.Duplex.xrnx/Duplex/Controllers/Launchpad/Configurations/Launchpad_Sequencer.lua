--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Step Sequencer",
  pinned = true,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Controlmaps/Launchpad_StepSequencer.xml",
    thumbnail = "Controllers/Launchpad/Launchpad.bmp",
    protocol = DEVICE_PROTOCOL.MIDI,
  },

  applications = {
    StepSequencer = {
      -- ORIENTATION.VERTICAL layout (default)
      mappings = {
        grid = {
          group_name = "Grid",
          orientation = ORIENTATION.HORIZONTAL,
        },
        level = {
          group_name = "Position",
          orientation = ORIENTATION.HORIZONTAL,
        },
        prev_line = {
          group_name = "Controls",
          orientation = ORIENTATION.HORIZONTAL,
          index = 3
        },
        next_line = {
          group_name = "Controls",
          orientation = ORIENTATION.HORIZONTAL,
          index = 4
        },
        track = {
          group_name = "Controls",
          orientation = ORIENTATION.HORIZONTAL,
          index = 1
        },
        transpose = {
          group_name = "Treatments",
          orientation = ORIENTATION.HORIZONTAL,
          index = 5
        },
      },
      options = {
        --line_increment = 8,
        --follow_track = 1,
        --page_size = 5,
      }

      --[[

      -- enable this instead for ORIENTATION.HORIZONTAL layout

      mappings = {
        grid = {
          group_name = "Grid",
          orientation = ORIENTATION.HORIZONTAL,
        },
        level = {
          group_name = "Controls",
          orientation = ORIENTATION.HORIZONTAL,
        },
        line = {
          group_name = "Triggers",
          orientation = ORIENTATION.VERTICAL,
          index = 1
        },
        track = {
          group_name = "Triggers",
          orientation = ORIENTATION.VERTICAL,
          index = 3
        },
        transpose = {
          group_name = "Triggers",
          orientation = ORIENTATION.VERTICAL,
          index = 5
        },
      },
      ]]
    },
    Rotate = {
      mappings = {
        track_in_pattern_up = {
          group_name = "Treatments",
          index = 1
        },
        track_in_pattern_down = {
          group_name = "Treatments",
          index = 2
        },
        whole_pattern_up = {
          group_name = "Treatments",
          index = 3
        },
        whole_pattern_down = {
          group_name = "Treatments",
          index = 4
        }
      }
    },
    
    Transport = {
      mappings = {
        start_playback = {
          group_name = "Controls",
          index = 6,
        },
        metronome_toggle = {
          group_name = "Controls",
          index = 5,
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

    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Triggers",
        }
      }
    },

  }
}

