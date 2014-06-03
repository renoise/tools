--[[----------------------------------------------------------------------------
-- Duplex.APC40
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Empty",
  pinned = true,
  
  -- device properties
  device = {
    class_name = nil,
    display_name = "BCD-3000",
    device_port_in = "",
    device_port_out = "",
    control_map = "Controllers/BCD-3000/Controlmaps/BCD-3000.xml",
    thumbnail = "",
    protocol = DEVICE_PROTOCOL.MIDI,
  },

  applications = {
  }
}
