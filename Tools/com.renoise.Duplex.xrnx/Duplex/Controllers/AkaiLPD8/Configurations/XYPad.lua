--[[----------------------------------------------------------------------------
-- Duplex.AkaiLPD8
----------------------------------------------------------------------------]]--

duplex_configurations:insert {
  -- configuration properties
  name = "XYPad",
  pinned = true,
  -- device properties
  device = {
    display_name = "AkaiLPD8",
    device_port_in = "MIDIIN2 (AkaiLPD8)",
    device_port_out = "MIDIOUT2 (AkaiLPD8)",
    control_map = "Controllers/AkaiLPD8/Controlmaps/AkaiLPD8_XYPad.xml",
    thumbnail = "Controllers/AkaiLPD8/AkaiLPD8.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  applications = {
    XYPad = {
      mappings = {
        x_slider = {
          group_name = "Pads_X",
          index = 1,
          orientation = ORIENTATION.HORIZONTAL
        },
        y_slider = {
          group_name = "Pads_Y",
          index = 1,
          orientation = ORIENTATION.HORIZONTAL
        }
      },
    }
  }
}