--[[----------------------------------------------------------------------------
-- Duplex.microKONTROL
----------------------------------------------------------------------------]]--

-- set up "Effect" for this configuration

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
    protocol = DEVICE_MIDI_PROTOCOL
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
        page = {
          group_name = "Joystick"
        }
      }
    }
  }
}
