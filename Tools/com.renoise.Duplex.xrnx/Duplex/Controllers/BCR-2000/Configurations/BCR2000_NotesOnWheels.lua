--[[----------------------------------------------------------------------------
-- Duplex.BCR2000
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Notes On Wheels",
  pinned = true,

  -- device properties
  device = {
    class_name = "BCR2000",          
    display_name = "BCR-2000",
    device_port_in = "BCR2000",
    device_port_out = "BCR2000",
    control_map = "Controllers/BCR-2000/Controlmaps/BCR-2000_NOW.xml",
    thumbnail = "Controllers/BCR-2000/BCR-2000.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    NotesOnWheels = {
      mappings = {
        pitch_sliders = {
          group_name = "EffectEncoders1",
        },
        pitch_adjust = {
          group_name = "Encoders1",
          index = 1,
        },
        velocity_sliders = {
          group_name = "EffectEncoders2",
        },
        velocity_adjust = {
          group_name = "Encoders1",
          index = 2,
        },
        retrig_sliders = {
          group_name = "EffectEncoders3",
        },
        retrig_adjust = {
          group_name = "Encoders1",
          index = 3,
        },
        gate_sliders = {
          group_name = "Encoders2",
        },
        gate_adjust = {
          group_name = "Encoders1",
          index = 4,
        },
        offset_sliders = {
          group_name = "Encoders3",
        },
        offset_adjust = {
          group_name = "Encoders1",
          index = 5,
        },
        num_steps = {
          group_name = "Buttons1",
          --orientation = ORIENTATION.HORIZONTAL,
        },
        step_spacing = {
          group_name = "Encoders1",
          index = 8,
        },
        write = {
          group_name = "Buttons2",
          index = 1,
        },
        learn = {
          group_name = "Buttons2",
          index = 2,
        },
        global = {
          group_name = "Buttons2",
          index = 3,
        },
        shrink = {
          group_name = "ControlButtonRow1",
          index = 1,
        },
        extend = {
          group_name = "ControlButtonRow1",
          index = 2,
        },
        set_mode_pitch = {
          group_name = "Buttons2",
          index = 4,
        },
        set_mode_velocity = {
          group_name = "Buttons2",
          index = 5,
        },
        set_mode_retrig = {
          group_name = "Buttons2",
          index = 6,
        },
        set_mode_gate = {
          group_name = "Buttons2",
          index = 7,
        },
        set_mode_offset = {
          group_name = "Buttons2",
          index = 8,
        },
      }
    },
    Transport = {
      mappings = {
        start_playback = {
          group_name = "DialPush1",
          index = 1,
        },
        stop_playback = {
          group_name = "DialPush1",
          index = 2,
        },
        loop_pattern = {
          group_name = "DialPush1",
          index = 3,
        },
        goto_previous = {
          group_name = "DialPush1",
          index = 4,
        },
        goto_next = {
          group_name = "DialPush1",
          index = 5,
        },
        edit_mode = {
          group_name = "DialPush1",
          index = 6,
        },
        follow_player = {
          group_name = "DialPush1",
          index = 7,
        },
        metronome_toggle = {
          group_name = "DialPush1",
          index = 8,
        },

      },
      options = {
      }
    },
    SwitchConfiguration = {
      mappings = {
        goto_previous = {
          group_name = "DialPush4",
          index = 7,
        },
        goto_next = {
          group_name = "DialPush4",
          index = 8,
        },
      }
    },
    TrackSelector = {
      mappings = {
        prev_track = {
          group_name = "ControlButtonRow2",
          index = 1,
        },
        next_track = {
          group_name = "ControlButtonRow2",
          index = 2,
        },
      },
    },
  }
}
