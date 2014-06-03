--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 128",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Controlmaps/Monome128_Mixer.xml",
    thumbnail = "Controllers/Monome/Monome.bmp",
    protocol = DEVICE_PROTOCOL.OSC,
  },

  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "Grid",
        },
        mute = {
          group_name = "Grid",
        },
        page = {
          group_name = "Controls1",
          orientation = ORIENTATION.HORIZONTAL,
          index = 1,
        },
        mode = {
          group_name = "Controls2",
          index = 1,
        },
      },
      options = {
        invert_mute = 2,
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Navigator",
          orientation = ORIENTATION.HORIZONTAL,
        }
      }
    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name= "Controls1",
          index = 3,
        },
        goto_next = {
          group_name= "Controls1",
          index = 4,
        },
        start_playback = {
          group_name = "Controls2",
          index = 2,
        },
        loop_pattern = {
          group_name = "Controls2",
          index = 3,
        },
        follow_player = {
          group_name= "Controls2",
          index = 4,
        },
      },
      options = {
        pattern_play = 3,
      }
    },
  }
}