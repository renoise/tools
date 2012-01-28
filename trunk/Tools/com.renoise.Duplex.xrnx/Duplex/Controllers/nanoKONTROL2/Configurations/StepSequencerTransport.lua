--[[----------------------------------------------------------------------------
-- Duplex.NanoKontrol2
----------------------------------------------------------------------------]]--


-- setup "StepSeq + Transport" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "StepSequencer + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = "NanoKontrol2",          
    display_name = "nanoKONTROL2",
    device_port_in = "nanoKONTROL2",
    device_port_out = "nanoKONTROL2",
    control_map = "Controllers/nanoKONTROL2/Controlmaps/nanoKONTROL2_Seq.xml",
    thumbnail = "Controllers/nanoKONTROL2/nanoKONTROL2.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    StepSequencer = {
      mappings = {
        level = {
          group_name = "Buttons1",
          orientation = HORIZONTAL,
        },
        grid = {
          group_name = "Buttons2",
          orientation = HORIZONTAL,
        },
        line = {
          group_name = "Encoders",
          orientation = HORIZONTAL,
          index = 7
        },
        transpose = {
          group_name = "Encoders",
          orientation = HORIZONTAL,
          index = 1
        },
        metronome_toggle = {
          group_name = "MARKER",
          index = 1,
        },
      },
      options = {
        follow_track = 1,
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Buttons3",
          orientation = HORIZONTAL,
        },
      },
    },
    TrackSelector = {
      mappings = {
        prev_next_track = {
          group_name = "TRACK",
          index = 1,
        },
      },
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

