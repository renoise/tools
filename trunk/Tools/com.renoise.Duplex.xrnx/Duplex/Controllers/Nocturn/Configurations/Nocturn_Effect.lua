--[[----------------------------------------------------------------------------
-- Duplex.Nocturn
----------------------------------------------------------------------------]]--

-- setup Effect as the only app for this configuration

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
    protocol = DEVICE_MIDI_PROTOCOL
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
        page = {
          group_name = "Pots",
          index = 5,
        },
        --[[
        device = {
          group_name = "Pots",
        },
        ]]
      },
      options = {
        
      }
    }
  }
}
