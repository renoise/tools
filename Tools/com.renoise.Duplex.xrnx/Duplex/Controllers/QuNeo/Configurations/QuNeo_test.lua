--[[----------------------------------------------------------------------------
-- Duplex.QuNeo
----------------------------------------------------------------------------]]--

-- test of the QuNeo control-map 

duplex_configurations:insert {

  -- configuration properties
  name = "QuNeo",
  pinned = true,

  -- device properties
  device = {
    class_name = "QuNeo",
    display_name = "QuNeo",
    device_port_in = "none",
    device_port_out = "none",
    control_map = "Controllers/QuNeo/Controlmaps/QuNeo_default.xml",
    thumbnail = "Controllers/QuNeo/quneo.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    Mixer = {
        mappings = {
          levels = {
            group_name = "VerticalFaders",
          },
      panning = {
            group_name = "HorizontalFaders",
          },
      mute = {
            group_name = "HorizontalArrowsLeft"
          },
          solo = {
            group_name = "HorizontalArrowsRight"
          },
      master = {
            group_name = "CentralFader"
          },
      },
      options = {
      pre_post = 2
        },
    },
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Grid",
        },
        track = {
          group_name = "Encoders",
          index = 2,
        }, 
      },
    },
    Transport = {
      mappings = {
        start_playback = {
              group_name = "Transport",
              index = 3,
            },
        stop_playback = {
              group_name = "Transport",
              index = 2,
        },
        edit_mode = {
          group_name = "Transport",
          index = 1,
        },
        block_loop = {
          group_name = "AnythingButton",
          index = 1,
        },
      }
    },
    PatternSequence = {
      mappings = {
        display_next = {
          group_name = "VerticalArrows1",
          index = 2,
        },
        display_previous = {
          group_name = "VerticalArrows1",
          index = 1,
        },
      }
    }
  }
}