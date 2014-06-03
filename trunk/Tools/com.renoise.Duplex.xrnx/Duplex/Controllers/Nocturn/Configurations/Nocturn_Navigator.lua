--[[----------------------------------------------------------------------------
-- Duplex.Nocturn
----------------------------------------------------------------------------]]--

-- setup Navigator on the buttons, leave sliders/crossfader unassigned

duplex_configurations:insert {

  -- configuration properties
  name = "Navigator",
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
    Navigator = {
      mappings = {
        blockpos = {
          group_name= "Pots",
          orientation = ORIENTATION.HORIZONTAL,
        },
      },
    }
  }
}
