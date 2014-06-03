--[[----------------------------------------------------------------------------
-- Duplex.MIDI-Keyboard
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Keyboard",
  pinned = true,

  -- device properties
  device = {
    display_name = "MIDI-Keyboard",
    class_name = "MidiKeyboard",
    device_port_in = "None",
    device_port_out = "None",
    control_map = "Controllers/MIDI-Keyboard/Controlmaps/MIDI-Key_Keyboard.xml",
    thumbnail = "Controllers/MIDI-Keyboard/MIDI-Keyboard.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  applications = {
    Keyboard = {
      mappings = {
        keys = {
          group_name = "Keyboard",
        },
        pitch_bend = {
          group_name = "MOD",
          index = 1,
        },
        pressure = {
          group_name = "CP",
          index = 1,
        },
      },
      options = {
        pitch_bend = 2, -- broadcast as MIDI
        channel_pressure = 2, -- broadcast as MIDI
      },
      hidden_options = {
        "button_width","button_height","release_type",
      }
    },
  }
}

