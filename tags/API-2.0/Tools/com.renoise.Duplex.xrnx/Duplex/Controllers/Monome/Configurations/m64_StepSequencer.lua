-- setup StepSequencer for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "StepSequencer",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 64",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Controlmaps/Monome64_StepSequencer.xml",
    thumbnail = "Controllers/Monome/Monome.bmp",
    protocol = DEVICE_OSC_PROTOCOL,
  },
  applications = {
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Column1",
          orientation = VERTICAL,
        }
      }
    },
    StepSequencer = {
      mappings = {
        grid = {
          group_name = "Grid",
        },
        level = {
          group_name = "Column2",
          index = 1,
        },
        line = { 
          group_name = "Column3",
          orientation = VERTICAL,
          index = 1,
        },
        track = {
          group_name = "Column3",
          orientation = VERTICAL,
          index = 3,
        },
        transpose = {
          group_name = "Column3",
          index = 5,
        },
      },
    }
  }
}

