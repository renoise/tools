--[[----------------------------------------------------------------------------
-- Duplex.NanoKontrol2
----------------------------------------------------------------------------]]--

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
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    StepSequencer = {
      mappings = {
        level = {
          group_name = "Buttons1",
          orientation = ORIENTATION.HORIZONTAL,
        },
        grid = {
          group_name = "Buttons2",
          orientation = ORIENTATION.HORIZONTAL,
        },
        prev_line = {
          group_name = "Encoders",
          index = 7
        },
        next_line = {
          group_name = "Encoders",
          index = 8
        },
        transpose = {
          group_name = "Encoders",
          orientation = ORIENTATION.HORIZONTAL,
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

