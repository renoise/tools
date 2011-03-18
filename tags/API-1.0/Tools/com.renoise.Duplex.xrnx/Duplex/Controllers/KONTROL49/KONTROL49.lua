--[[----------------------------------------------------------------------------
-- Duplex.KONTROL49
----------------------------------------------------------------------------]]--

-- default configuration of the KONTROL49
-- uses a control map and the Mixer and Effect applications

--==============================================================================

-- setup a Mixer and Effect application

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer",
  pinned = true,

  -- device properties
  device = {
    display_name = "KONTROL49",
    device_port_in = "MIDIIN2 (KONTROL49)",
    device_port_out = "MIDIOUT2 (KONTROL49)",
    control_map = "Controllers/KONTROL49/KONTROL49.xml",
    thumbnail = "KONTROL49.bmp",
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
          group_name = "Switches"
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
    display_name = "KONTROL49",
    device_port_in = "MIDIIN2 (KONTROL49)",
    device_port_out = "MIDIOUT2 (KONTROL49)",
    control_map = "Controllers/KONTROL49/KONTROL49.xml",
    thumbnail = "KONTROL49.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },

  applications = {
    Effect = {
      mappings = {
        parameters = {
          group_name= "Encoders"
        },
        page = {
          group_name = "Switches"
        },
        device = {
          group_name = "Pads B"
        }
      }
    }
  }
}

