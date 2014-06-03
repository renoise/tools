--[[----------------------------------------------------------------------------
-- Duplex.Nocturn
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Hydra",
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
    Hydra_1 = {
	    application = "Hydra",
      mappings = {
        input_slider = {
          group_name = "Encoders",
          index = 1,
        },
        lock_button = {
          group_name = "Pots",
          index = 1,
        },
      },
    },
    Hydra_2 = {
	    application = "Hydra",
      mappings = {
        input_slider = {
          group_name = "Encoders",
          index = 2,
        },
        lock_button = {
          group_name = "Pots",
          index = 2,
        },
      },
    },
    Hydra_3 = {
	    application = "Hydra",
      mappings = {
        input_slider = {
          group_name = "Encoders",
          index = 3,
        },
        lock_button = {
          group_name = "Pots",
          index = 3,
        },
      },
    },
    Hydra_4 = {
	    application = "Hydra",
      mappings = {
        input_slider = {
          group_name = "Encoders",
          index = 4,
        },
        lock_button = {
          group_name = "Pots",
          index = 4,
        },
      },
    },
  }
}
