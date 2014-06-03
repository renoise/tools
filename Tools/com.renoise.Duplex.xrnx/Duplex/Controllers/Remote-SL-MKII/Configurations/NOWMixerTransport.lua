
duplex_configurations:insert {

  -- configuration properties
  name = "N.O.W. + Mixer + Transport",
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
      },
      options = {
        page_size = 2,     -- "1",
        follow_track = 1,  -- "Follow track enabled"
      }
    },
    NotesOnWheels = {
      mappings = {
        multi_sliders = {
          group_name = "Encoders",
        },
        set_mode_pitch = {
          group_name = "EncoderButtons",
          index = 1,
        },
        set_mode_velocity = {
          group_name = "EncoderButtons",
          index = 2,
        },
        set_mode_offset = {
          group_name = "EncoderButtons",
          index = 3,
        },
        set_mode_gate = {
          group_name = "EncoderButtons",
          index = 4,
        },
        set_mode_retrig = {
          group_name = "EncoderButtons",
          index = 5,
        },
        num_steps = {
          group_name = "Pots",
          index = 7,
        },
        step_spacing = {
          group_name = "Pots",
          index = 8,
        },
        write = {
          group_name = "PotButtons",
          index = 1,
        },
        learn = {
          group_name = "PotButtons",
          index = 2,
        },
        fill = {
          group_name = "PotButtons",
          index = 3,
        },
        global = {
          group_name = "PotButtons",
          index = 4,
        },
        shrink = {
          group_name = "PotButtons",
          index = 5,
        },
        extend = {
          group_name = "PotButtons",
          index = 6,
        },
        shift_up = {
          group_name = "PotButtons",
          index = 7,
        },
        shift_down = {
          group_name = "PotButtons",
          index = 8,
        },
        pitch_adjust = {
          group_name = "Pots",
          index = 1,
        },
        velocity_adjust = {
          group_name = "Pots",
          index = 2,
        },
        offset_adjust = {
          group_name = "Pots",
          index = 3,
        },
        gate_adjust = {
          group_name = "Pots",
          index = 4,
        },
        retrig_adjust = {
          group_name = "Pots",
          index = 5,
        },

      },
      options = {
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
