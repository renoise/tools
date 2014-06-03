--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "GridPie",
  pinned = true,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Controlmaps/Launchpad_GridPie.xml",
    thumbnail = "Controllers/Launchpad/Launchpad.bmp",
    protocol = DEVICE_PROTOCOL.MIDI,
  },

  applications = {
    GridPie = {
	    mappings = {
	      grid = {
          group_name = "Grid",
        },
	      v_prev = {
          group_name = "Controls",
          index = 1,
        },
	      v_next = {
          group_name = "Controls",
          index = 2,
        },
	      h_prev = {
          group_name = "Controls",
          index = 3,
        },
	      h_next = {
          group_name = "Controls",
          index = 4,
        },
    	},
      options = {
        follow_pos = 2
      },
    },
    Mixer = {
      mappings = {
        mute = {
          group_name = "Mutes"
        }
      },
      options = {
        page_size = 1,
        follow_track = 1
      }
    },

    Transport = {
      mappings = {
        edit_mode = {
          group_name = "Controls",
          index = 5,
        },
        start_playback = {
          group_name = "Controls",
          index = 6,
        },
        loop_pattern = {
          group_name = "Controls",
          index = 7,
        },
        follow_player = {
          group_name= "Controls",
          index = 8,
        },
      },
      options = {
        pattern_play = 3, -- toggle start/stop with single button
      },
    },
    PatternSequence = {
      mappings = {
        display_previous = {
          group_name = "SequencerControls",
          index = 1,
        },
        display_next = {
          group_name = "SequencerControls",
          index = 2,
        }
      },
    },
    TrackSelector = {
      mappings = {
        select_track = {
          group_name = "Tracks"
        }
      },
      options = {
        page_size = 1
      }
    },
    StepSequencer = {
      mappings = {
        grid = {
          group_name = "Sequencer"
        },
        transpose = {
          group_name = "SequencerControls",
          index = 5,
          orientation = "vertical"
        },
        level = {
          group_name = "Triggers"
        }
      },
      options = {
        line_increment = 8,
        page_size = 1,
        follow_track = 1,
      }
    }
  }
}