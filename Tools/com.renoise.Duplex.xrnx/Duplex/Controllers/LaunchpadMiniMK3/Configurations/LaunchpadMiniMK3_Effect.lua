--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Effect + Transport",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "LaunchpadMiniMK3",
    display_name = "Launchpad Mini MK3",
    device_port_in = "Launchpad Mini MK3 MIDI 2",
    device_port_out = "Launchpad Mini MK3 MIDI 2",
    control_map = "Controllers/LaunchpadMiniMK3/Controlmaps/LaunchpadMiniMK3_Effect.xml",
    thumbnail = "Controllers/LaunchpadMiniMK3/LaunchpadMiniMK3.bmp",
    protocol = DEVICE_PROTOCOL.MIDI,
  },

  applications = {

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
      }
    },
    TrackSelector = {
      mappings = {
        prev_page = {
          group_name = "Controls",
          index = 3,
        },
        next_page = {
          group_name = "Controls",
          index = 4,
        },
        select_track = {
          group_name = "Row",
          index = 1,
        },
      },
    },
    Effect = {
      mappings = {
        parameters = {
          group_name= "Grid",
        },
        param_prev = {
          group_name = "Controls",
          index = 1,
        },
        param_next = {
          group_name = "Controls",
          index = 2,
        },
        device = {
          group_name = "Triggers",
        },
      },
    },


  }
}

