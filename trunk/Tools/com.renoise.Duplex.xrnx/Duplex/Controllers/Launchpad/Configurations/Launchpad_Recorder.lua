--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Recorder + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Controlmaps/Launchpad_Recorder.xml",
    thumbnail = "Controllers/Launchpad/Launchpad.bmp",
    protocol = DEVICE_PROTOCOL.MIDI,
  },

  applications = {
    Recorder = {
      mappings = {
        recorders = {
          group_name = "Grid",
        },
        sliders = {
          group_name = "Grid",
        },
      },
      options = {
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Triggers",
        }
      }
    },
    Mixer = {
      mappings = {
        mute = {
          group_name = "Row",
        },
      },
      options = {
        follow_track = 2,
      }
    },
    Mixer_Track = {
      application = "Mixer",
      mappings = {
        levels = {
          group_name = "Column",
        },
      },
      options = {
        follow_track = 1,
      }
    },
    TrackSelector = {
      mappings = {
        prev_page = {
          group_name = "Controls",
          index = 3,
        },
        next_page = {
          group_name = "Controls",
          index = 4,
        },
      },
      options = {
        page_size = 1 ,
      }
    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name= "Controls",
          index = 1,
        },
        goto_next = {
          group_name= "Controls",
          index = 2,
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
        follow_player = {
          group_name= "Controls",
          index = 8,
        },
      },
      options = {
        pattern_play = 3,
      }
    },
  }
}

