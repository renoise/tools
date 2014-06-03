---[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Recorder",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 64",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Controlmaps/Monome64_Recorder.xml",
    thumbnail = "Controllers/Monome/Monome.bmp",
    protocol = DEVICE_PROTOCOL.OSC,
  },

  applications = {
    TrackSelector = {
      mappings = {
        prev_page = {
          group_name = "Controls",
          index = 1,
        },
        next_page = {
          group_name = "Controls",
          index = 2,
        },
      },
      options = {
        page_size = 8,
      }
    },
    Recorder = {
      mappings = {
        recorders = {
          group_name = "Row",
        },
        sliders = {
          group_name = "Grid",
        },
      },
      options = {
        follow_track = 1,
        --page_size
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
    Transport = {
      mappings = {
        goto_previous = {
          group_name= "Controls",
          index = 3,
        },
        goto_next = {
          group_name= "Controls",
          index = 4,
        },
        edit_mode = {
          group_name = "Controls",
          index = 5,
        },
        start_playback = {
          group_name = "Controls",
          index = 6,
        },
        loop_pattern = {
          group_name = "Controls",
          index = 7,
        },
      },
      options = {
        pattern_play = 3,
      }
    },
  }
}