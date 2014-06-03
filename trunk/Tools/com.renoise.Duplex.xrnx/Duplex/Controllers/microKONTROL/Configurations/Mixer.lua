--[[----------------------------------------------------------------------------
-- Duplex.microKONTROL
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer",
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
    Mixer = {
      mappings = {
        mute = {
          group_name = "Pads A"
        },
        solo = {
          group_name = "Pads B"
        },
        panning = {
          group_name = "Encoders"
        },
        levels = {
          group_name = "Sliders"
        },
        page = {
          group_name = "Joystick"
        }
      },
      options = {
        pre_post = 2
      }
    }
  }
}

