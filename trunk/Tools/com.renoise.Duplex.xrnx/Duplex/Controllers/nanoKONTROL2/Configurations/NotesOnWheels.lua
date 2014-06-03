--[[----------------------------------------------------------------------------
-- Duplex.NanoKontrol2
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Notes On Wheels",
  pinned = true,

  -- device properties
  device = {
    class_name = "NanoKontrol2",          
    display_name = "nanoKONTROL2",
    device_port_in = "nanoKONTROL2",
    device_port_out = "nanoKONTROL2",
    control_map = "Controllers/nanoKONTROL2/Controlmaps/nanoKONTROL2.xml",
    thumbnail = "Controllers/nanoKONTROL2/nanoKONTROL2.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    Transport = {
      mappings = {
        loop_pattern = {
          group_name = "CYCLE",
          index = 1,
        },
        goto_previous = {
          group_name = "Transport",
          index = 1,
        },
        goto_next = {
          group_name = "Transport",
          index = 2,
        },
        stop_playback = {
          group_name = "Transport",
          index = 3,
        },
        start_playback = {
          group_name = "Transport",
          index = 4,
        },
        metronome_toggle = {
          group_name = "MARKER",
          index = 1,
        },
      },
    },
    NotesOnWheels = {
      mappings = {
        multi_sliders = {
          group_name = "Faders",
        },
        pitch_adjust = {
          group_name = "Encoders",
          index = 1,
        },
        velocity_adjust = {
          group_name = "Encoders",
          index = 2,
        },
        offset_adjust = {
          group_name = "Encoders",
          index = 3,
        },
        gate_adjust = {
          group_name = "Encoders",
          index = 4,
        },
        retrig_adjust = {
          group_name = "Encoders",
          index = 5,
        },
        step_spacing = {
          group_name = "Encoders",
          index = 6,
        },
        multi_adjust = {
          group_name = "Encoders",
          index = 8,
        },
        position = {
          group_name = "Buttons1",
        },
        num_steps = {
          group_name = "Buttons2",
          orientation = ORIENTATION.HORIZONTAL,
        },
        write = {
          group_name = "Transport",
          index = 5,
        },
        learn = {
          group_name = "Buttons3",
          index = 1,
        },
        fill = {
          group_name = "Buttons3",
          index = 2,
        },
        global = {
          group_name = "Buttons3",
          index = 3,
        },
        set_mode_pitch = {
          group_name = "Buttons3",
          index = 4,
        },
        set_mode_velocity = {
          group_name = "Buttons3",
          index = 5,
        },
        set_mode_offset = {
          group_name = "Buttons3",
          index = 6,
        },
        set_mode_gate = {
          group_name = "Buttons3",
          index = 7,
        },
        set_mode_retrig = {
          group_name = "Buttons3",
          index = 8,
        },
      },
    },
    TrackSelector = {
      mappings = {
        prev_track = {
          group_name = "TRACK",
          index = 1,
        },
        next_track = {
          group_name = "TRACK",
          index = 2,
        },
      },
    },
    SwitchConfiguration = {
      mappings = {
        goto_previous = {
          group_name = "MARKER",
          index = 2,
        },
        goto_next = {
          group_name = "MARKER",
          index = 3,
        },
      }
    },
  }
}


