--[[----------------------------------------------------------------------------
-- Duplex.R-control
----------------------------------------------------------------------------]]--

-- default configuration of the CMD DC-1

--==============================================================================

duplex_configurations:insert {

  -- configuration properties
  name = "Stepsequencer + Effects",
  pinned = true,

  -- device properties
  device = {
    class_name = "CMDDC1",
    display_name = "CMD DC-1",
    device_port_in = "CMD DC1",
    device_port_out = "CMD DC1",
    control_map = "Controllers/CMD_DC-1/Controlmaps/CMD_DC-1_Default.xml",
    thumbnail = "Controllers/CMD_DC-1/CMD_DC-1.bmp",
    protocol = DEVICE_PROTOCOL.MIDI,
  },

  applications = {
    Effect = {
      mappings = {
        parameters = {
          group_name= "Encoders",
          index = 2,
        },
        device_select = {
          group_name= "Encoders",
          index = 1,
        }
      },
    },
    StepSequencer = {
      -- ORIENTATION.VERTICAL layout (default)
      mappings = {
        grid = {
          group_name = "Grid",
          orientation = ORIENTATION.HORIZONTAL,
          button_size = 1.5
        },
        levelslider = {
          group_name = "Level",
          index = 1
        },
        levelsteps = {
          group_name = "Level",
          index = 2
        },
        transpose = {
          group_name = "Transpose",
          orientation = ORIENTATION.HORIZONTAL,
          index = 1
        },
      },
      options = {
        follow_track = 1,
        follow_column = 1,
        grid_mode = 2,
        write_mode = 1,
        play_notes = 2,
        display_notes = 2,
      }

    },
    TrackSelector = {
      mappings = {
        prev_column = {
          group_name = "Navigation",
          index = 2,
        },
        next_column = {
          group_name = "Navigation",
          index = 3,
        },
        prev_track = {
          group_name = "Navigation",
          index = 1,
        },
        next_track = {
          group_name = "Navigation",
          index = 4,
        },
      }
    },
    Transport = {
      mappings = {
        -- goto_previous = {
        --   group_name = "NavigationL",
        --   index = 1,
        -- },
        -- goto_next = {
        --   group_name = "Controls",
        --   index = 2,
        -- },
        stop_playback = {
          group_name= "NavigationL",
          index = 1,
        },
        start_playback = {
          group_name = "NavigationR",
          index = 2,
        },
        -- loop_pattern = {
        --   group_name = "Controls",
        --   index = 5,
        -- },
        edit_mode = {
          group_name = "NavigationR",
          index = 1,
        },
        block_loop = {
          group_name = "NavigationL",
          index = 2,
        },
        -- follow_player = {
        --   group_name = "Controls",
        --   index = 8,
        -- },
      },
      options = {
      }
    },

    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Triggers",
          orientation = ORIENTATION.HORIZONTAL
        }
      }
    },
  }
}

