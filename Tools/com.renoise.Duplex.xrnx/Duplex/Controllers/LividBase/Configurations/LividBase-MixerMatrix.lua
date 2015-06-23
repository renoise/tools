--[[----------------------------------------------------------------------------
-- Duplex.LividBase
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Matrix",
  pinned = true,

  -- device properties
  device = {
    class_name = "LividBase",          
    display_name = "LividBase",
    device_port_in = "",
    device_port_out = "",
    control_map = "Controllers/LividBase/Controlmaps/LividBase.xml",
    --thumbnail = "Controllers/LividBase/LividBase.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "TouchStrips",
        },
        mute = {
          group_name = "TouchButtons",
        },
        master = {
          group_name = "TouchStrip",
        }
      },

    },
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Pads",
        },
        prev_seq_page = {
          group_name = "Buttons",
          index = 1,
        },
        next_seq_page = {
          group_name = "Buttons",
          index = 2,
        },
        prev_track_page = {
          group_name = "Buttons",
          index = 3,
        },
        next_track_page = {
          group_name = "Buttons",
          index = 4,
        },
      },  
      palette = {
        out_of_bounds       = { color=LividBase.COLOR_GREEN,  text="·"},
        slot_empty          = { color=LividBase.COLOR_OFF,    text=""},
        slot_empty_muted    = { color=LividBase.COLOR_RED,    text="·"},
        slot_filled         = { color=LividBase.COLOR_YELLOW, text="▪"},
        slot_filled_muted   = { color=LividBase.COLOR_MAGENTA,text="▫"},
        slot_master_filled  = { color=LividBase.COLOR_CYAN,   text="▪"},
        slot_master_empty   = { color=LividBase.COLOR_BLUE,   text="·"},      
      }
    },

    TrackSelector = {
      mappings = {
        select_track = {
          group_name = "LEDs",
        }
      },
    }


  }
}



