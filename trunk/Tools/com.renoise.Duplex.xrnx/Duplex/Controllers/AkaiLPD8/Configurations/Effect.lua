--[[----------------------------------------------------------------------------
-- Duplex.AkaiLPD8
----------------------------------------------------------------------------]]--

duplex_configurations:insert {
  -- configuration properties
  name = "Effects",
  pinned = true,
  -- device properties
  device = {
    display_name = "AkaiLPD8",
    device_port_in = "MIDIIN2 (AkaiLPD8)",
    device_port_out = "MIDIOUT2 (AkaiLPD8)",
    control_map = "Controllers/AkaiLPD8/Controlmaps/AkaiLPD8.xml",
    thumbnail = "Controllers/AkaiLPD8/AkaiLPD8.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  applications = {
    Effect = {
      mappings = {
        parameters = {
          group_name= "Knobs",
        },
        device_prev = {
          group_name = "Pads",
          index = 1
        },
        device_next = {
          group_name = "Pads",
          index = 2
        },
        preset_prev = {
          group_name = "Pads",
          index = 3
        },
        preset_next = {
          group_name = "Pads",
          index = 4
        },
        page = {
          group_name = "Pads",
          index = 5
        },
      }
    }
  }
}