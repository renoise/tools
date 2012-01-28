--[[----------------------------------------------------------------------------
-- Duplex.MIDI-Keyboard
----------------------------------------------------------------------------]]--

-- default configuration of a MIDI-Keyboard

--==============================================================================

duplex_configurations:insert {

  -- configuration properties
  name = "TripleStack",
  pinned = true,

  -- device properties
  device = {
    display_name = "MIDI-Keyboard",
    device_port_in = "USB MIDI Keyboard",
    device_port_out = "USB MIDI Keyboard",
    control_map = "Controllers/MIDI-Keyboard/Controlmaps/MIDI-Key_TripleStack.xml",
    thumbnail = "Controllers/MIDI-Keyboard/MIDI-Keyboard.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },


  applications = {
    
    KeyboardUpper = {
      application = "Keyboard",
      mappings = {
        keys = {
          group_name = "Keyboard1",
        },
        pitch_bend = {
          group_name = "MOD1",
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
      },
      options = {
        pitch_bend = 2,
        channel_pressure = 2,
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
          group_name = "Buttons2",
          orientation = VERTICAL,
          index = 1,
        },
        octave_sync = {
          group_name = "Button2",
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

      },

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
          group_name = "Buttons3",
          orientation = VERTICAL,
          index = 1,
        },
        octave_sync = {
          group_name = "Button3",
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
      }
    },


  }
}

