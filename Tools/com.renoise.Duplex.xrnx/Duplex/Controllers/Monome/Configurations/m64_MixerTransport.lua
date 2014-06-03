--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 64",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Controlmaps/Monome64_Mixer.xml",
    thumbnail = "Controllers/Monome/Monome.bmp",
    protocol = DEVICE_PROTOCOL.OSC,
  },

  applications = {
    Transport = {
      mappings = {
        goto_previous = {
          group_name= "Controls",
          index = 3,
        },
        goto_next = {
          group_name= "Controls",
          index = 4,
        },
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
        --[[
        follow_player = {
          group_name= "Controls",
          index = 8,
        },
        ]]
      },
      options = {
        pattern_play = 3,
      }
    },
    Mixer = {
      mappings = {
        levels = {
          group_name = "Grid",
        },
        mute = {
          group_name = "Grid",
        },
        page = {
          group_name = "Controls",
          index = 1
        },
        mode = {
          group_name = "Controls",
          index = 8
        }
      },
      options = {
        invert_mute = 2,
        follow_track = 1,
        --page_size
        --mute_mode
        --pre_post
      }
    }
  }
}

