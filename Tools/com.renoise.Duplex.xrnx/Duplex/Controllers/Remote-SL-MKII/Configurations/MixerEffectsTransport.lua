
duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Effects + Drums + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Remote SL MKII Automap",
    device_port_in = "Automap MIDI",
    device_port_out = "Automap MIDI",
    control_map = "Controllers/Remote-SL-MKII/Controlmaps/Remote-SL-MKII.xml",
    thumbnail = "Controllers/Remote-SL-MKII/Remote-SL-MKII.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "Sliders",
        },
        param_prev = {
          group_name = "EncoderButtons",
          index = 3,
        },
        param_next = {
          group_name = "EncoderButtons",
          index = 4,
        },
      },
      options = {
        page_size = 2,     -- "1",
        follow_track = 1,  -- "Follow track enabled"
      }
    },
    TrackSelector = {
      mappings = {
        select_track = {
          group_name = "SliderButtons",
        },
        prev_track = {
          group_name = "EncoderButtons",
          index = 7,
        },
        next_track = {
          group_name = "EncoderButtons",
          index = 8,
        },
        prev_page = {
          group_name = "EncoderButtons",
          index = 5,
        },
        next_page = {
          group_name = "EncoderButtons",
          index = 6,
        },
      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name= "Encoders",
        },
        device = {
          group_name = "PotButtons",
        }
      }
    },
    Drumpads = {
      application = "Keyboard",
      mappings = {
        key_grid = {
          group_name = "Drumpads",
          --index = 1,
        },
      },
      options = {
        release_type = 2  -- the Remote sends multiple note-on, but only a single note-off
      },
      hidden_options = {  -- display minimal set of options
        "channel_pressure","pitch_bend","release_type","button_width","button_height"
      },
    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name = "Controls",
          index = 1,
        },
        goto_next = {
          group_name = "Controls",
          index = 2,
        },
        stop_playback = {
          group_name= "Controls",
          index = 3,
        },
        start_playback = {
          group_name = "Controls",
          index = 4,
        },
        loop_pattern = {
          group_name = "Controls",
          index = 5,
        },
        edit_mode = {
          group_name = "Controls",
          index = 6,
        },
        block_loop = {
          group_name = "Controls",
          index = 7,
        },
        follow_player = {
          group_name = "Controls",
          index = 8,
        },
      },
      options = {
      }
    },

  }
}
