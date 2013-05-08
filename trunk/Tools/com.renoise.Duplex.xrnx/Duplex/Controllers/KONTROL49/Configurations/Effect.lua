--[[----------------------------------------------------------------------------
-- Duplex.KONTROL49
----------------------------------------------------------------------------]]--

-- set up "Effect" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Effect",
  pinned = true,

  -- device properties
  device = {
    display_name = "KONTROL49",
    device_port_in = "MIDIIN2 (KONTROL49)",
    device_port_out = "MIDIOUT2 (KONTROL49)",
    control_map = "Controllers/KONTROL49/Controlmaps/KONTROL49.xml",
    thumbnail = "Controllers/KONTROL49/KONTROL49.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },

  applications = {
    Effect = {
      mappings = {
        parameters = {
          group_name= "Encoders"
        },
        --page = {
        --  group_name = "Switches"
        --},
        device = {
          group_name = "Pads B"
        },
        param_prev = {
          group_name = "Switches",
          index = 1,
        },
        param_next = {
          group_name = "Switches",
          index = 2,
        },

      }
    }
  }
}

