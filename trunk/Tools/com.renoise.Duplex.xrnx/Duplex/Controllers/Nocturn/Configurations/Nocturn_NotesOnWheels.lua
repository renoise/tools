--[[----------------------------------------------------------------------------
-- Duplex.Nocturn
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "NotesOnWheels",
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
    NotesOnWheels = {
      mappings = {
        multi_sliders = {
          group_name = "Encoders",
        },
        multi_adjust = {
          group_name = "XFader",
        },
        write = {
          group_name = "Pots",
          index = 1,
        },
        learn = {
          group_name = "Pots",
          index = 2,
        },
        global = {
          group_name = "Pots",
          index = 3,
        },
        set_mode_pitch = {
          group_name = "Pots",
          index = 4,
        },
        set_mode_velocity = {
          group_name = "Pots",
          index = 5,
        },
        set_mode_offset = {
          group_name = "Pots",
          index = 6,
        },
        set_mode_gate = {
          group_name = "Pots",
          index = 7,
        },
        set_mode_retrig = {
          group_name = "Pots",
          index = 8,
        },

      },
      options = {
      }
    }
  }
}
