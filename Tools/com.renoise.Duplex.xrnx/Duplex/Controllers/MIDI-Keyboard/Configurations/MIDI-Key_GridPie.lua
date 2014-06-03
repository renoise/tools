--[[----------------------------------------------------------------------------
-- Duplex.MIDI-Keyboard
----------------------------------------------------------------------------]]--

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
    protocol = DEVICE_PROTOCOL.MIDI
  },

  applications = {

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
  }
}

