--[[----------------------------------------------------------------------------
-- Duplex.TouchOSC 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Handset - keys",
  pinned = true,

  -- device properties
  device = {
    class_name = "TouchOSC",
    display_name = "TouchOSC",
    device_prefix = nil,
    device_address = "10.0.0.2",
    device_port_in = "8001",
    device_port_out = "8081",
    control_map = "Controllers/TouchOSC/Controlmaps/TouchOSC_Keys.xml",
    thumbnail = "Controllers/TouchOSC/TouchOSC.bmp",
    protocol = DEVICE_PROTOCOL.OSC,
  },

  applications = {
    Keyboard1 = {
      application = "Keyboard",
      mappings = {
        keys = {
          group_name = "Keyboard1",
        }
      }
    },
    Keyboard2 = {
      application = "Keyboard",
      mappings = {
        keys = {
          group_name = "Keyboard2",
        }
      }
    },
  }
}

