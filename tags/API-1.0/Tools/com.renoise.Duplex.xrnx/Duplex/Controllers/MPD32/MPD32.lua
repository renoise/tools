--[[----------------------------------------------------------------------------
-- Duplex.MPD32
----------------------------------------------------------------------------]]--

-- "Generic" preset


-- setup a Mixer, Matrix and Effect application

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Matrix + Effects + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,
    display_name = "MPD32",
    device_port_in = "Akai MPD32 (Port 1)",
    device_port_out = "Akai MPD32 (Port 1)",
    control_map = "Controllers/MPD32/MPD32.xml",
    thumbnail = "MPD32.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "Faders",
        },
        page = {
          group_name = "Switches",
          index = 5,
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
        },
        page = {
          group_name = "Switches",
          index = 7,
        }
      }
    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name = "Switches",
          index = 1,
        },
        goto_next = {
          group_name= "Switches",
          index = 2,
        },
        start_playback = {
          group_name = "Switches",
          index = 3,
        },
        loop_pattern = {
          group_name = "Switches",
          index = 4,
        },
      },
      options = {
        pattern_play = 3,
      }
    },
  }
}
