--[[----------------------------------------------------------------------------
-- Duplex.AkaiLPD8
----------------------------------------------------------------------------]]--

-- setup "Effect" for this configuration

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