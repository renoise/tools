--[[----------------------------------------------------------------------------
-- Duplex.LaunchpadMiniMK3
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Step Sequencer",
  pinned = true,

  -- device properties
  device = {
    class_name = "LaunchpadMiniMK3",
    display_name = "Launchpad Mini MK3",
    device_port_in = "Launchpad Mini MK3 MIDI 2",
    device_port_out = "Launchpad Mini MK3 MIDI 2",
    control_map = "Controllers/LaunchpadMiniMK3/Controlmaps/LaunchpadMiniMK3_StepSequencer.xml",
    thumbnail = "Controllers/LaunchpadMiniMK3/LaunchpadMiniMK3.bmp",
    protocol = DEVICE_PROTOCOL.MIDI,
  },

  applications = {
    StepSequencer = {
      mappings = {
        grid = {
          component = {{UIButton}},
          group_name = "Grid",
          orientation = ORIENTATION.HORIZONTAL,
        },
        level = {
          component = UIButtonStrip,
          group_name = "Position",
          orientation = ORIENTATION.HORIZONTAL,
        },
        prev_line = {
          component = UIButton,
          group_name = "Controls",
          index = 3
        },
        next_line = {
          component = UIButton,
          group_name = "Controls",
          index = 4
        },
        track = {
          component = UISpinner,
          group_name = "Controls",
          orientation = ORIENTATION.HORIZONTAL,
          index = 1
        },
        transpose = {
          component = {UIButton,UIButton,UIButton,UIButton},
          group_name = "Treatments",
          orientation = ORIENTATION.HORIZONTAL,
          index = 5
        },
        cycle_layout = {
          component = UIButton,
          group_name = "Treatments",
          index = 1,
        }
      },
      options = {
        --line_increment = 8,
        --follow_track = 1,
        --page_size = 5,
      }
    },
    Rotate = {
      mappings = {
        track_in_pattern_up = {
          group_name = "Treatments",
          index = 3
        },
        track_in_pattern_down = {
          group_name = "Treatments",
          index = 4
        },
      }
    },
    
    Transport = {
      mappings = {
        start_playback = {
          group_name = "Controls",
          index = 6,
        },
        edit_mode = {
          group_name = "Controls",
          index = 5,
        },
        follow_player = {
          group_name= "Controls",
          index = 7,
        },
        loop_pattern = {
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

