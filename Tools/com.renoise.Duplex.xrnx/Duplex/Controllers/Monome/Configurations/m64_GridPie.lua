--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "GridPie",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 64",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Controlmaps/Monome64_GridPie.xml",
    thumbnail = "Controllers/Monome/Monome.bmp",
    protocol = DEVICE_PROTOCOL.OSC,
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
        v_step = 5,     -- every 4th
        h_step = 3,     -- every 2nd
        follow_pos = 2, -- disable follow
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Navigator",
          orientation = ORIENTATION.VERTICAL,
        }
      }
    },
    Mixer = {
      mappings = {
        mute = {
          group_name = "Mutes",
        }
      }
    },
    Transport = {
      mappings = {
        start_playback = {
          group_name = "Controls",
          index = 5,
        },
      },
      options = {
        pattern_play = 3,
      }
    },

  }
}

