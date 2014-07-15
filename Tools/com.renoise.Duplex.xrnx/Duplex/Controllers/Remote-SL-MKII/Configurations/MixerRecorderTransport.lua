
duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Recorder + Transport",
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
        page = {
          group_name = "EncoderButtons",
          index = 7,
        },
        mute = {
          group_name = "SliderButtons",
        },
      }
    },
    Recorder = {
      mappings = {
        recorders = {
          group_name = "PotButtons",
        },
        sliders = {
          group_name = "Encoders",
        },
      },
      options = {
      }
    },
    XYPad = {
      mappings = {
        --[[
        y_slider = {
          group_name = "XYPad",
          index = 1,
        },
        x_slider = {
          group_name = "XYPad",
          index = 2,
        },
        ]]
        xy_pad = {
          group_name = "XYPad",
          index = 1
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


