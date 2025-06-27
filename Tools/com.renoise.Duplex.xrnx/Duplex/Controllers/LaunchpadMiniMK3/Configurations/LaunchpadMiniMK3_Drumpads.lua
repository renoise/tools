--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--
 
duplex_configurations:insert {
 
  -- configuration properties
  name = "Drumpads",
  pinned = true,
 
  -- device properties
  device = {
    class_name = "LaunchpadMiniMK3",
    display_name = "Launchpad Mini MK3",
    device_port_in = "Launchpad Mini MK3 MIDI 2",
    device_port_out = "Launchpad Mini MK3 MIDI 2",
    control_map = "Controllers/LaunchpadMiniMK3/Controlmaps/LaunchpadMiniMK3_Drumpads.xml",
    thumbnail = "Controllers/LaunchpadMiniMK3/LaunchpadMiniMK3.bmp",
    protocol = DEVICE_PROTOCOL.MIDI,
  },
 
  applications = {
    Bank1 = {
      application = "Keyboard",
      mappings = {
        key_grid = {
          group_name = "Bank 1",
        },
      },
      options = {},
      hidden_options = {  -- display minimal set of options
        "channel_pressure","pitch_bend","release_type","button_width","button_height","mod_wheel","velocity_mode","keyboard_mode"
      },
    },
    Bank2 = {
      application = "Keyboard",
      mappings = {
        key_grid = {
          group_name = "Bank 2",
        },
      },
      options = {},
      hidden_options = {  -- display minimal set of options
        "channel_pressure","pitch_bend","release_type","button_width","button_height","mod_wheel","velocity_mode","keyboard_mode"
      },
    },

    Bank3 = {
      application = "Keyboard",
      mappings = {
        key_grid = {
          group_name = "Bank 3",
        },
      },
      options = {},
      hidden_options = {  -- display minimal set of options
        "channel_pressure","pitch_bend","release_type","button_width","button_height","mod_wheel","velocity_mode","keyboard_mode"
      },
    },

    Bank4 = {
      application = "Keyboard",
      mappings = {
        key_grid = {
          group_name = "Bank 4",
        },
      },
      options = {},
      hidden_options = {  -- display minimal set of options
        "channel_pressure","pitch_bend","release_type","button_width","button_height","mod_wheel","velocity_mode","keyboard_mode"
      },
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
