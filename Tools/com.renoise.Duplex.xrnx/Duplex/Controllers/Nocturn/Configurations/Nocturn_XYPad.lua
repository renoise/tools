--[[----------------------------------------------------------------------------
-- Duplex.Nocturn
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "XYPad",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Nocturn Automap",
    device_port_in = "Automap MIDI",
    device_port_out = "Automap MIDI",
    control_map = "Controllers/Nocturn/Controlmaps/Nocturn.xml",
    thumbnail = "Controllers/Nocturn/Nocturn.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    XYPad = {
      mappings = {
        x_slider = {
          group_name = "Encoders",
          index = 1,
        },
        y_slider = {
          group_name = "Encoders",
          index = 2,
        },
      },
      options = {
      }
    }
  }
}
