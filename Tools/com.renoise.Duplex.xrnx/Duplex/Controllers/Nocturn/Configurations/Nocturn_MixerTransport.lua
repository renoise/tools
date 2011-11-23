--[[----------------------------------------------------------------------------
-- Duplex.Nocturn
----------------------------------------------------------------------------]]--

-- setup Mixer + Transport for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Nocturn Automap",
    device_port_in = "Automap MIDI",
    device_port_out = "Automap MIDI",
    control_map = "Controllers/Nocturn/Controlmaps/Nocturn.xml",
    thumbnail = "Controllers/Nocturn/Nocturn.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "Encoders",
        },
        master = {
          group_name = "XFader",
        },
        mode = {
          group_name = "Pots",
          index = 8,
        }

      },
    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name = "Pots",
          index = 1,
        },
        goto_next = {
          group_name = "Pots",
          index = 2,
        },
        stop_playback = {
          group_name = "Pots",
          index = 3,
        },
        start_playback = {
          group_name = "Pots",
          index = 4,
        },
        loop_pattern = {
          group_name = "Pots",
          index = 5,
        },
        --[[
        edit_mode = {
          group_name = "Pots",
          index = 6,
        },
        block_loop = {
          group_name = "Pots",
          index = 7,
        },
        ]]
        follow_player = {
          group_name = "Pots",
          index = 6,
        },
        metronome_toggle = {
          group_name = "Pots",
          index = 7,
        },

      },
      options = {
      }

    },
  }
}


