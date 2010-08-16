--[[----------------------------------------------------------------------------
-- Duplex.microKONTROL
----------------------------------------------------------------------------]]--

-- default configuration of the microKONTROL
-- uses a custom device class, a control map and the Mixer and Effect
-- applications

--==============================================================================

class "microKONTROL" (MidiDevice)

function microKONTROL:__init(display_name, message_stream, port_in, port_out)
  TRACE("microKONTROL:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

end

--------------------------------------------------------------------------------

-- setup a Mixer and Effect application

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer",
  pinned = true,

  -- device properties
  device = {
    class_name = "microKONTROL",
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
          group_name = "Button 1"
        },
        solo = {
          group_name = "Button 2"
        },
        panning = {
          group_name = "Dials"
        },
        levels = {
          group_name = "Faders"
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
    class_name = "microKONTROL",
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
          group_name= "Dials"
        },
        page = {
          group_name = "Joystick"
        }
      }
    }
  }
}
