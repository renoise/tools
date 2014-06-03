--[[----------------------------------------------------------------------------
-- Duplex.MIDI-Keyboard
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "TripleStack",
  pinned = true,

  -- device properties
  device = {
    display_name = "MIDI-Keyboard",
    class_name = "MidiKeyboard",
    device_port_in = "None",
    device_port_out = "None",
    control_map = "Controllers/MIDI-Keyboard/Controlmaps/MIDI-Key_TripleStack.xml",
    thumbnail = "Controllers/MIDI-Keyboard/MIDI-Keyboard.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },


  applications = {
    
    KeyboardUpper = {
      application = "Keyboard",
      mappings = {
        keys = {
          group_name = "Keyboard1",
        },
        pitch_bend = {
          group_name = "PB1",
          index = 1,
        },
        pressure = {
          group_name = "CP1",
          index = 1,
        },
        volume = {
          group_name = "Volume1",
          index = 1,
        },
        volume_sync = {
          group_name = "Volume1",
          index = 2,
        },
        octave_up = {
          group_name = "Octave1",
          index = 1,
        },
        octave_down = {
          group_name = "Octave1",
          index = 2,
        },
        octave_sync = {
          group_name = "Octave1",
          index = 3,
        },
      },
      options = {
        pitch_bend = 2,
        channel_pressure = 2,
      },
      hidden_options = {
        "button_width","button_height"
      }
    },
    KeyboardMiddle = {
      application = "Keyboard",
      mappings = {
        keys = {
          group_name = "Keyboard2",
        },
        volume = {
          group_name = "Volume2",
          index = 1,
        },
        volume_sync = {
          group_name = "Volume2",
          index = 2,
        },
        octave_set = {
          group_name = "Buttons2a",
          orientation = ORIENTATION.VERTICAL,
          index = 1,
        },
        octave_sync = {
          group_name = "Button2a",
          index = 1,
        },
        octave_up = {
          group_name = "Octave2",
          index = 1,
        },
        octave_down = {
          group_name = "Octave2",
          index = 2,
        },
        track_set = {
          group_name = "Buttons2b",
          orientation = ORIENTATION.VERTICAL,
          index = 1,
        },
        track_sync = {
          group_name = "Button2b",
          index = 1,
        },
        instr_set = {
          group_name = "Buttons2c",
          orientation = ORIENTATION.VERTICAL,
          index = 1,
        },
        instr_sync = {
          group_name = "Button2c",
          index = 1,
        },

      },
      options = {
        upper_note = 36,
        lower_note = 6,
      },
      hidden_options = {
        "button_width","button_height","pitch_bend","channel_pressure",
      }
    },
    KeyboardLower = {
      application = "Keyboard",
      mappings = {
        keys = {
          group_name = "Keyboard3",
        },
        volume = {
          group_name = "Volume3",
          index = 1,
        },
        volume_sync = {
          group_name = "Volume3",
          index = 2,
        },
        octave_set = {
          group_name = "Buttons3a",
          orientation = ORIENTATION.VERTICAL,
          index = 1,
        },
        octave_sync = {
          group_name = "Button3a",
          index = 1,
        },
        octave_up = {
          group_name = "Octave3",
          index = 1,
        },
        octave_down = {
          group_name = "Octave3",
          index = 2,
        },
        track_set = {
          group_name = "Buttons3b",
          orientation = ORIENTATION.VERTICAL,
          index = 1,
        },
        track_sync = {
          group_name = "Button3b",
          index = 1,
        },
        instr_set = {
          group_name = "Buttons3c",
          orientation = ORIENTATION.VERTICAL,
          index = 1,
        },
        instr_sync = {
          group_name = "Button3c",
          index = 1,
        },

      },
      options = {
        upper_note = 84,
        lower_note = 37,
      },
      hidden_options = {
        "button_width","button_height","pitch_bend","channel_pressure",
      }
    },


  }
}

