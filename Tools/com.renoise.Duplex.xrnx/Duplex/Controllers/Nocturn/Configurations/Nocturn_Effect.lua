--[[----------------------------------------------------------------------------
-- Duplex.Nocturn
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Effect",
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
    Effect = {
      mappings = {
        parameters = {
          group_name= "Encoders",
        },
        device_select = {
          group_name = "XFader",
        },
        device_prev = {
          group_name = "Pots",
          index = 1,
        },
        device_next = {
          group_name = "Pots",
          index = 2,
        },
        preset_prev = {
          group_name = "Pots",
          index = 3,
        },
        preset_next = {
          group_name = "Pots",
          index = 4,
        },
        param_prev = {
          group_name = "Pots",
          index = 5,
        },
        param_next = {
          group_name = "Pots",
          index = 6,
        },
      },
      options = {
        
      }
    }
  }
}
