--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Keyboard",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 128",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Controlmaps/Monome128_Keyboard.xml",
    thumbnail = "Controllers/Monome/Monome.bmp",
    protocol = DEVICE_PROTOCOL.OSC,
  },
  applications = {
    KeyBoard = {
      application = "Keyboard",
      mappings = {
        key_grid = {
          group_name = "Grid"
        }
      }, 
      palette = {

      }
    },
    KeyPads = {
      application = "Keyboard",
      mappings = {
        key_grid = {
          group_name = "KeyPads"
        }
      },
      options = {
        button_width = 2,
        button_height = 2,
      }
    },

  }
}

