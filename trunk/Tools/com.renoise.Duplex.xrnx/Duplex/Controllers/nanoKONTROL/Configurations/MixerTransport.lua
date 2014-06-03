--[[----------------------------------------------------------------------------
-- Duplex.NanoKontrol
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = "NanoKontrol",          
    display_name = "nanoKONTROL",
    device_port_in = "nanoKONTROL",
    device_port_out = "nanoKONTROL",
    control_map = "Controllers/nanoKONTROL/Controlmaps/nanoKONTROL.xml",
    thumbnail = "Controllers/nanoKONTROL/nanoKONTROL.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    Mixer = {
      mappings = {
        mute = {
          group_name = "Buttons1",
        },
        solo = {
          group_name = "Buttons2",
        },
        panning = {
          group_name= "Encoders",
        },
        levels = {
          group_name = "Faders",
        }
      },
    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name = "TransportRow1",
          index = 1,
        },
        start_playback = {
          group_name = "TransportRow1",
          index = 2,
        },
        goto_next = {
          group_name = "TransportRow1",
          index = 3,
        },
        
        loop_pattern = {
          group_name = "TransportRow2",
          index = 1,
        },
        stop_playback = {
          group_name = "TransportRow2",
          index = 2,
        },
        edit_mode = {
          group_name = "TransportRow2",
          index = 3,
        },
      },
      options = {
      }

    },
  }
}

