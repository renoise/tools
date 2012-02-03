--[[----------------------------------------------------------------------------
-- Duplex.MIDI-Keyboard
----------------------------------------------------------------------------]]--

-- default configuration of a MIDI-Keyboard

--==============================================================================

duplex_configurations:insert {

  -- configuration properties
  name = "GridPie",
  pinned = true,

  -- device properties
  device = {
    display_name = "MIDI-Keyboard",
    class_name = "MidiKeyboard",
    device_port_in = "None",
    device_port_out = "None",
    control_map = "Controllers/MIDI-Keyboard/Controlmaps/MIDI-Key_GridPie.xml",
    thumbnail = "Controllers/MIDI-Keyboard/MIDI-Keyboard.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },

  applications = {
    --[[
    KeyboardLower = {
      application = "Keyboard",
      mappings = {
        keys = {
          group_name = "Keyboard",
        },
        pitch_bend = {
          group_name = "MOD",
          index = 1,
        }
      },
      options = {
        pitch_bend = 2,  -- ignore, but capture pitch bend
      }
    },
    ]]
    GridPie = {
      mappings = {
        grid = {
          group_name = "White_Keys",
        },
        v_prev = {
          group_name = "Black_Keys_0",
          index = 1
        },
        v_next = {
          group_name = "Black_Keys_0",
          index = 2
        },
        h_prev = {
          group_name = "Black_Keys_0",
          index = 4
        },
        h_next = {
          group_name = "Black_Keys_0",
          index = 5
        },
        v_slider = {
          group_name = "MOD",
          index = 1
        },
        --[[
        ]]
      },
      options = {
        v_step = 2,
        h_step = 2,
        follow_pos = 3,
      }
    },
    --[[
    Transport = {
      mappings = {
        start_playback = {
          group_name = "White_Keys_1",
          index = 1,
        },
        stop_playback = {
          group_name = "White_Keys_1",
          index = 2,
        },
        loop_pattern = {
          group_name = "Black_Keys_1",
          index = 1,
        },
        follow_player = {
          group_name = "Black_Keys_1",
          index = 2,
        },
      },
    },
    ]]
  }
}

