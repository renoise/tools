--[[----------------------------------------------------------------------------
-- Duplex.NanoKontrol2
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Recorder + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = "NanoKontrol2",          
    display_name = "nanoKONTROL2",
    device_port_in = "nanoKONTROL2",
    device_port_out = "nanoKONTROL2",
    control_map = "Controllers/nanoKONTROL2/Controlmaps/nanoKONTROL2.xml",
    thumbnail = "Controllers/nanoKONTROL2/nanoKONTROL2.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    Mixer = {
      mappings = {
        solo = {
          group_name = "Buttons1",
        },
        mute = {
          group_name = "Buttons2",
        },
      },
      options = {
        invert_mute = 1,
        follow_track = 1,
      }
    },
    Transport = {
      mappings = {
        loop_pattern = {
          group_name = "CYCLE",
          index = 1,
        },
        goto_previous = {
          group_name = "Transport",
          index = 1,
        },
        goto_next = {
          group_name = "Transport",
          index = 2,
        },
        stop_playback = {
          group_name = "Transport",
          index = 3,
        },
        start_playback = {
          group_name = "Transport",
          index = 4,
        },
        edit_mode = {
          group_name = "Transport",
          index = 5,
        },
        metronome_toggle = {
          group_name = "MARKER",
          index = 1,
        },
      },
      options = {
      }
    },
    TrackSelector = {
      mappings = {
        prev_track = {
          group_name = "TRACK",
          index = 1,
        },
        next_track = {
          group_name = "TRACK",
          index = 2,
        },

      },
    },
    Recorder = {
      mappings = {
        recorders = {
          group_name = "Buttons3",
        },
        sliders = {
          group_name = "Faders",
        },
      },
    },
    Effect = {
      mappings = {
        parameters = {
          group_name = "Encoders",
        },
      },
      options = {
        include_parameters = 3,
      }
    },
    SwitchConfiguration = {
      mappings = {
        goto_previous = {
          group_name = "MARKER",
          index = 2,
        },
        goto_next = {
          group_name = "MARKER",
          index = 3,
        },
      }
    },
  }
}


