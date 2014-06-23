--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Recorder + Matrix",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 128",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Controlmaps/Monome128_RecorderMatrix.xml",
    thumbnail = "Controllers/Monome/Monome.bmp",
    protocol = DEVICE_PROTOCOL.OSC,

  },

  applications = {
    Recorder = {
      mappings = {
        recorders = {
          group_name = "Controls",
        },
        sliders = {
          group_name = "Grid1",
        },
      },
      options = {
        follow_track = 1,
        page_size = 3,
        --autostart
        --trigger_mode
        --beat_sync
        --auto_seek
        --loop_mode
      
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Column",
          orientation = ORIENTATION.VERTICAL,
        }
      }
    },
    TrackSelector = {
      mappings = {
        prev_page = {
          group_name = "Controls2",
          index = 1,
        },
        next_page = {
          group_name = "Controls2",
          index = 2,
        },
      },
      options = {
        --page_size
      }

    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name= "Controls2",
          index = 3,
        },
        goto_next = {
          group_name= "Controls2",
          index = 4,
        },
        edit_mode = {
          group_name = "Controls2",
          index = 5,
        },
        start_playback = {
          group_name = "Controls2",
          index = 6,
        },
        loop_pattern = {
          group_name = "Controls2",
          index = 7,
        },
        --follow_player = {
        --  group_name= "Controls2",
        --  index = 8,
        --},
      },
      options = {
        pattern_play = 3,
      }
    },
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Grid2",
        },
        triggers = {
          group_name = "Grid2",
        },
      }
    }
  }
}

