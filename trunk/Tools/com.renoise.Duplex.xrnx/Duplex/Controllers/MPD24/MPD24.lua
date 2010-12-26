--[[----------------------------------------------------------------------------
-- Duplex.MPD24
----------------------------------------------------------------------------]]--

-- "Generic" preset


-- setup a Mixer, Matrix and Effect application

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Matrix + Effects",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,
    display_name = "MPD24",
    device_port_in = "Akai MPD24 (Port 1)",
    device_port_out = "Akai MPD24 (Port 1)",
    control_map = "Controllers/MPD24/MPD24.xml",
    thumbnail = "MPD24.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "Faders",
        }
      }
    },
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Pads",
        }
      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name= "Knobs",
        }
      }
    }
  }
}
