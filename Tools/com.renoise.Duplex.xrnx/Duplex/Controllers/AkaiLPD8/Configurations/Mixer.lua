--[[----------------------------------------------------------------------------
-- Duplex.AkaiLPD8
----------------------------------------------------------------------------]]--

duplex_configurations:insert {
  -- configuration properties
  name = "Mixer",
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
      }
    }
  }
}