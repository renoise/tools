--[[----------------------------------------------------------------------------
-- Duplex.BCF2000
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Notes On Wheels",
  pinned = true,

  -- device properties
  device = {
    class_name = "BCF2000",          
    display_name = "BCF-2000",
    device_port_in = "BCF2000",
    device_port_out = "BCF2000",
    control_map = "Controllers/BCF-2000/Controlmaps/BCF-2000.xml",
    thumbnail = "Controllers/BCF-2000/BCF-2000.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    NotesOnWheels = {
      mappings = {
        multi_sliders = {
          group_name = "Faders",
        },
        pitch_adjust = {
          group_name = "Encoders1",
          index = 1,
        },
        velocity_adjust = {
          group_name = "Encoders1",
          index = 2,
        },
        offset_adjust = {
          group_name = "Encoders1",
          index = 3,
        },
        gate_adjust = {
          group_name = "Encoders1",
          index = 4,
        },
        retrig_adjust = {
          group_name = "Encoders1",
          index = 5,
        },
        num_steps = {
          group_name = "Buttons1",
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
        set_mode_pitch = {
          group_name = "Buttons2",
          index = 4,
        },
        set_mode_velocity = {
          group_name = "Buttons2",
          index = 5,
        },
        set_mode_offset = {
          group_name = "Buttons2",
          index = 6,
        },
        set_mode_gate = {
          group_name = "Buttons2",
          index = 7,
        },
        set_mode_retrig = {
          group_name = "Buttons2",
          index = 8,
        },
        shift_up = {
          group_name = "ControlButtonRow2",
          index = 1,
        },
        shift_down = {
          group_name = "ControlButtonRow2",
          index = 2,
        },
        shrink = {
          group_name = "ControlButtonRow1",
          index = 1,
        },
        extend = {
          group_name = "ControlButtonRow1",
          index = 2,
        },
      }
    },
    TrackSelector = {
      mappings = {
        select_track = {
          group_name = "DialPush2",
        },
      },
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
  }
}

