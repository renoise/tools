--[[----------------------------------------------------------------------------
-- Duplex.microKONTROL
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Effect",
  pinned = true,

  -- device properties
  device = {
    display_name = "microKONTROL",
    device_port_in = "MIDIIN2 (microKONTROL)",
    device_port_out = "MIDIOUT2 (microKONTROL)",
    control_map = "Controllers/microKONTROL/Controlmaps/microKONTROL.xml",
    thumbnail = "Controllers/microKONTROL/microKONTROL.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },

  applications = {
    Effect = {
      mappings = {
        parameters = {
          group_name= "Encoders"
        },
        device = {
          group_name = "Pads B"
        },
        param_prev = {
          group_name = "Joystick",
          index = 1,
        },
        param_next = {
          group_name = "Joystick",
          index = 2,
        },
      }
    }
  }
}
