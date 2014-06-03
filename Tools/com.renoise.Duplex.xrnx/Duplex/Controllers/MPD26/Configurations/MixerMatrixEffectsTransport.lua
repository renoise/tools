--[[----------------------------------------------------------------------------
-- Duplex.MPD26
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Matrix + Effects",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,
    display_name = "MPD26",
    device_port_in = "Akai MPD26",
    device_port_out = "Akai MPD26",
    control_map = "Controllers/MPD26/Controlmaps/MPD26-Generic.xml",
    thumbnail = "Controllers/MPD26/MPD26.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "Faders",
        },
        master = {
          group_name = "Master-Fader",
        },
        solo = {
          group_name = "Pad-Mixer-1",
        },
        mute = {
          group_name = "Pad-Mixer-2",
        },
        page = {
          group_name = "Pad-Page",
          index = 1,
        }
      }
    },
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Pad-Matrix",
        },
        track = {
          group_name = "Pad-Page",
          index = 1,
        },
        prev_seq_page = {
          group_name = "Pad-Page",
          index = 3,
        },
        next_seq_page = {
          group_name = "Pad-Page",
          index = 4,
        },
      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name = "Knobs",
        },
        device = {
          group_name = "Pad-FX-1",
        },
        param_prev = {
          group_name = "Pad-FX-2",
          index = 3,
        },
        param_next = {
          group_name = "Pad-FX-2",
          index = 4,
        },
      }
    },
    Transport = {
      mappings = {
        stop_playback = {
          group_name = "Transport",
          index = 3,
        },
        start_playback = {
          group_name = "Transport",
          index = 4,
        },
        follow_player = {
          group_name = "Transport",
          index = 5,
        },
        goto_previous = {
          group_name = "Transport",
          index = 1,
        },
        goto_next = {
          group_name = "Transport",
          index = 2,
        },
      }
    }
  }
}


