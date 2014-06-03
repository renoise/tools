--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

-- setup "Matrix + Effect" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix + Effect",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 128",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Controlmaps/Monome128_MatrixEffect.xml",
    thumbnail = "Controllers/Monome/Monome.bmp",
    protocol = DEVICE_PROTOCOL.OSC,
    options = {
      --cable_orientation = 2 -- up
    }
  },

  applications = {
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Grid1",
        },
        triggers = {
          group_name = "Grid1",
        },
        prev_seq_page = {
          group_name = "Controls",
          index = 1,
        },
        next_seq_page = {
          group_name = "Controls",
          index = 2,
        },
        track = {
          group_name = "Controls",
          index = 3,
        }
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Column",
          orientation = ORIENTATION.VERTICAL,
        }
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
      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name= "Grid2",
        },
        device = {
          group_name = "Controls2",
        },
      },
    },
  }
}