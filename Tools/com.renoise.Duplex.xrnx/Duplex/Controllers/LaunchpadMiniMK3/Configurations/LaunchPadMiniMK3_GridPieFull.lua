--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "GridPieFull",
  pinned = true,

  -- device properties
  device = {
    class_name = "LaunchpadMiniMK3",
    display_name = "Launchpad Mini MK3",
    device_port_in = "Launchpad Mini MK3 MIDI 2",
    device_port_out = "Launchpad Mini MK3 MIDI 2",
    control_map = "Controllers/LaunchpadMiniMK3/Controlmaps/LaunchpadMiniMK3_GridPieFull.xml",
    thumbnail = "Controllers/LaunchpadMiniMK3/LaunchpadMiniMK3.bmp",
    protocol = DEVICE_PROTOCOL.MIDI,
  },

  applications = {
    GridPie = {
      palette = {
        empty = {color=LaunchpadMiniMK3.COLOR_OFF},
        empty_current = {color=LaunchpadMiniMK3.COLOR_YELLOW},
        empty_active = {color=LaunchpadMiniMK3.COLOR_MAGENTA},
        empty_active_current = {color=LaunchpadMiniMK3.COLOR_MAGENTA},
        content_active = {color=LaunchpadMiniMK3.COLOR_CYAN},
        content_active_current = {color=LaunchpadMiniMK3.COLOR_CYAN},
        content_selected = {color=LaunchpadMiniMK3.COLOR_GREEN},
        inactive_content = {color=LaunchpadMiniMK3.COLOR_BLUE}
      },
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
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Triggers",
        },
      },
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
        pattern_play = 3,
      },
    },



  }
}