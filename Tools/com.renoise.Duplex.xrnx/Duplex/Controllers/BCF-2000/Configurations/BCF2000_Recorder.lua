--[[----------------------------------------------------------------------------
-- Duplex.BCF2000
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Recorder",
  pinned = true,

  -- device properties
  device = {
    class_name = "BCF2000",          
    display_name = "BCF-2000",
    device_port_in = "BCF2000",
    device_port_out = "BCF2000",
    control_map = "Controllers/BCF-2000/Controlmaps/BCF-2000.xml",
    thumbnail = "Controllers/BCF-2000/BCF-2000.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    Mixer = {
      mappings = {
        mute = {
          group_name = "Buttons2",
        },
        panning = {
          group_name= "Encoders2",
        },
        levels = {
          group_name = "Faders",
        },
        mode = {
          group_name = "DialPush4",
          index = 6,
        },
      },
      options = {
        invert_mute = 1,
        follow_track = 1,
      }
    },
    Recorder = {
      mappings = {
        recorders = {
          group_name = "Buttons1",
        },
        sliders = {
          group_name = "Encoders1",
        },
      },
      options = {
        -- loop_mode = 2,
        -- auto_seek = 2,
        -- beat_sync = 1,
        -- trigger_mode = 1,
        -- autostart = 4,

      }
    },
    TrackSelector = {
      mappings = {
        select_track = {
          group_name = "DialPush2",
        },
        prev_page = {
          group_name = "ControlButtonRow1",
          index = 1,
        },
        next_page = {
          group_name = "ControlButtonRow1",
          index = 2,
        },
        prev_track = {
          group_name = "ControlButtonRow2",
          index = 1,
        },
        next_track = {
          group_name = "ControlButtonRow2",
          index = 2,
        },

      },
    },
    Transport = {
      mappings = {
        start_playback = {
          group_name = "DialPush1",
          index = 1,
        },
        stop_playback = {
          group_name = "DialPush1",
          index = 2,
        },
        loop_pattern = {
          group_name = "DialPush1",
          index = 3,
        },
        goto_previous = {
          group_name = "DialPush1",
          index = 4,
        },
        goto_next = {
          group_name = "DialPush1",
          index = 5,
        },
        edit_mode = {
          group_name = "DialPush1",
          index = 6,
        },
        follow_player = {
          group_name = "DialPush1",
          index = 7,
        },
        metronome_toggle = {
          group_name = "DialPush1",
          index = 8,
        },

      },
      options = {
      }
    },
    SwitchConfiguration = {
      mappings = {
        goto_previous = {
          group_name = "DialPush4",
          index = 7,
        },
        goto_next = {
          group_name = "DialPush4",
          index = 8,
        },
      }
    },
  }
}


