--[[----------------------------------------------------------------------------
-- Duplex.BCR2000
----------------------------------------------------------------------------]]--

-- setup a Mixer and Effect application

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer & Effects",
  pinned = true,

  -- device properties
  device = {
    class_name = "BCR2000",          
    display_name = "BCR-2000",
    device_port_in = "BCR2000",
    device_port_out = "BCR2000",
    control_map = "Controllers/BCR-2000/Controlmaps/BCR-2000.xml",
    thumbnail = "Controllers/BCR-2000/BCR-2000.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "EffectEncoders1",
        },
        panning = {
          group_name = "Encoders1",
        },
        solo = {
          group_name = "Buttons1",
        },
        mute = {
          group_name = "Buttons2",
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
    TrackSelector = {
      mappings = {
        select_track = {
          group_name = "DialPush1",
        },
        prev_next_page = {
          group_name = "ControlButtonRow1",
          index = 1,
        },
      },
    },
    Effect = {
      mappings = {
        parameters = {
          group_name= "EffectEncoders2",
        },
        device = {
          group_name= "DialPush3",
        },
        page = {
          group_name= "ControlButtonRow2",
          index = 1,
        },
      },
    },
    Transport = {
      mappings = {
        start_playback = {
          group_name = "DialPush2",
          index = 1,
        },
        stop_playback = {
          group_name = "DialPush2",
          index = 2,
        },
        loop_pattern = {
          group_name = "DialPush2",
          index = 3,
        },
        goto_previous = {
          group_name = "DialPush2",
          index = 4,
        },
        goto_next = {
          group_name = "DialPush2",
          index = 5,
        },
        edit_mode = {
          group_name = "DialPush2",
          index = 6,
        },
        follow_player = {
          group_name = "DialPush2",
          index = 7,
        },
        metronome_toggle = {
          group_name = "DialPush2",
          index = 8,
        },
      },
      options = {
      }
    },
    --[[
    Metronome = {
      mappings = {
        toggle = {
          group_name = "DialPush2",
          index = 8,
        },
      },
    },
    ]]
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


