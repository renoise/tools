--[[----------------------------------------------------------------------------
-- Duplex.microKONTROL
----------------------------------------------------------------------------]]--

-- default configuration of the microKONTROL
-- uses a control map and the Mixer and Effect applications
-- applications

--==============================================================================

-- setup a Mixer and Effect application

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer",
  pinned = true,

  -- device properties
  device = {
    display_name = "microKONTROL",
    device_port_in = "MIDIIN2 (microKONTROL)",
    device_port_out = "MIDIOUT2 (microKONTROL)",
    control_map = "Controllers/microKONTROL/microKONTROL.xml",
    thumbnail = "microKONTROL.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
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

duplex_configurations:insert {

  -- configuration properties
  name = "Effect",
  pinned = true,

  -- device properties
  device = {
    display_name = "microKONTROL",
    device_port_in = "MIDIIN2 (microKONTROL)",
    device_port_out = "MIDIOUT2 (microKONTROL)",
    control_map = "Controllers/microKONTROL/microKONTROL.xml",
    thumbnail = "microKONTROL.bmp",
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
