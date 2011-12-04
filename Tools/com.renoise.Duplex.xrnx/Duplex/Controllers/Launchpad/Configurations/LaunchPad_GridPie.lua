--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

-- setup GridPie for the Launchpad

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
    protocol = DEVICE_MIDI_PROTOCOL,
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
        follow_pos = 1,
        polyrhythms = 1,
        page_size_v = 5,
        page_size_h = 2,
      },
    },
    Mixer = {
      mappings = {
        mute = {
          group_name = "Mutes"
        }
      },
      options = {
        page_size = 2,
        follow_track = 1
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Triggers",
        },
      },
    },
    --[[
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Triggers",
        },
      },
    },
    ]]
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

  }
}