duplex_configurations:insert {
  -- configuration properties
  name = "Mixer",
  pinned = true,
  -- device properties
  device = {
    display_name = "AkaiLPD8",
    device_port_in = "MIDIIN2 (AkaiLPD8)",
    device_port_out = "MIDIOUT2 (AkaiLPD8)",
    control_map = "Controllers/AkaiLPD8/AkaiLPD8.xml",
    thumbnail = "AkaiLPD8.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  applications = {
    Mixer = {
      mappings = {
        mute = {
          group_name = "Pads",
        },
        levels = {
          group_name = "Knobs",
        },
      },
      options = {
        pre_post = 2,
        simsalabim = 42,
      }
    }
  }
}
duplex_configurations:insert {
  -- configuration properties
  name = "Effects",
  pinned = true,
  -- device properties
  device = {
    display_name = "AkaiLPD8",
    device_port_in = "MIDIIN2 (AkaiLPD8)",
    device_port_out = "MIDIOUT2 (AkaiLPD8)",
    control_map = "Controllers/AkaiLPD8/AkaiLPD8.xml",
    thumbnail = "AkaiLPD8.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  applications = {
    Effect = {
      mappings = {
        parameters = {
          group_name= "Knobs",
        },
        page = {
          group_name = "Pads"
        }
      }
    }
  }
}