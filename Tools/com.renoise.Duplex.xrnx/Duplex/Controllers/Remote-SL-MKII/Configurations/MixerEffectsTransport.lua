-- setup Mixer + Effect + Transport for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Effects + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Remote SL MKII Automap",
    device_port_in = "Automap MIDI",
    device_port_out = "Automap MIDI",
    control_map = "Controllers/Remote-SL-MKII/Controlmaps/Remote-SL-MKII.xml",
    thumbnail = "Controllers/Remote-SL-MKII/Remote-SL-MKII.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "Sliders",
        },
        --[[
        master = {
          group_name = "Modulators",
          index = 2,
        },
        ]]
        page = {
          group_name = "EncoderButtons",
          index = 7,
        },
        mute = {
          group_name = "SliderButtons",
        },
      }
    },
    --[[
    TrackSelector = {
      mappings = {
        prev_next_track = {
          group_name = "SliderButtons",
          index = 1,
        },
        prev_next_page = {
          group_name = "SliderButtons",
          index = 3,
        },
      }
    },
    ]]
    Effect = {
      mappings = {
        parameters = {
          group_name= "Encoders",
        },
        page = {
          group_name = "EncoderButtons",
          index = 1
        },
        device = {
          group_name = "PotButtons",
        }
      }
    },
    XYPad = {
      mappings = {
        y_slider = {
          group_name = "XYPad",
          index = 1,
        },
        x_slider = {
          group_name = "XYPad",
          index = 2,
        },
      }
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
