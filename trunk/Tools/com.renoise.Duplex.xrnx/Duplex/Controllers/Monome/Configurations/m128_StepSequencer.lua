--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

-- setup "StepSequencer" for this configuration

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
    protocol = DEVICE_OSC_PROTOCOL,
  },
  applications = {
    StepSequencer = {
      mappings = {
        grid = {
          group_name = "Grid",
          orientation = HORIZONTAL,
        },
        level = {
          group_name = "Row2",
          orientation = HORIZONTAL,
          index = 1,
        },
        line = { 
          group_name = "Controls",
          orientation = HORIZONTAL,
          index = 3,
        },
        track = {
          group_name = "Controls",
          orientation = HORIZONTAL,
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
          orientation = HORIZONTAL,
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

