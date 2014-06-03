--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "StepSequencer",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 128",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Controlmaps/Monome128_StepSequencer.xml",
    thumbnail = "Controllers/Monome/Monome.bmp",
    protocol = DEVICE_PROTOCOL.OSC,
  },
  applications = {
    StepSequencer = {
      mappings = {
        grid = {
          group_name = "Grid",
          orientation = ORIENTATION.HORIZONTAL,
        },
        level = {
          group_name = "Row2",
          orientation = ORIENTATION.HORIZONTAL,
          index = 1,
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
          index = 5,
        },
        transpose = {
          group_name = "Column1",
          index = 1,
        },
      },
      options = {
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Row1",
          orientation = ORIENTATION.HORIZONTAL,
        }
      }
    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name= "Controls",
          index = 1,
        },
        goto_next = {
          group_name= "Controls",
          index = 2,
        },
        start_playback = {
          group_name = "Column2",
          index = 2,
        },
        loop_pattern = {
          group_name = "Column2",
          index = 4,
        },
        follow_player = {
          group_name= "Column2",
          index = 3,
        },
      },
      options = {
        pattern_play = 3,
      }
    },

  }
}

