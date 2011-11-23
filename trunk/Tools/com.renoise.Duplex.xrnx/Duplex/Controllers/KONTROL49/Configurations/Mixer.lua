--[[----------------------------------------------------------------------------
-- Duplex.KONTROL49
----------------------------------------------------------------------------]]--

-- set up "Mixer" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer",
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

