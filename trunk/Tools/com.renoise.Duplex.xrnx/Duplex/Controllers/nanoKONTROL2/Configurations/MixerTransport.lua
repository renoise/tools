--[[----------------------------------------------------------------------------
-- Duplex.NanoKontrol2
----------------------------------------------------------------------------]]--


-- setup "Mixer + Transport" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = "NanoKontrol2",          
    display_name = "nanoKONTROL2",
    device_port_in = "nanoKONTROL2",
    device_port_out = "nanoKONTROL2",
    control_map = "Controllers/nanoKONTROL2/Controlmaps/nanoKONTROL2.xml",
    thumbnail = "Controllers/nanoKONTROL2/nanoKONTROL2.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
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
        panning = {
          group_name= "Encoders",
        },
        levels = {
          group_name = "Faders",
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
      },
      options = {
      }
    },
    TrackSelector = {
      mappings = {
        prev_next_track = {
          group_name = "TRACK",
          index = 1,
        },
        select_track = {
          group_name = "Buttons3",
          index = 1,
        },
      },
    },
    Metronome = {
      mappings = {
        toggle = {
          group_name = "MARKER",
          index = 1,
        },
      },
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



