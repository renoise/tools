--[[----------------------------------------------------------------------------
-- Duplex.Ohm64 
----------------------------------------------------------------------------]]--

-- setup Mixer + Matrix + Effect + SwitchConfiguration

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix, Mixer, Effects & SwitchConfiguration",
  pinned = true,

  -- device properties
  device = {
    class_name = "Ohm64",          
    display_name = "Ohm64Switch",
    device_port_in = "Ohm64 MIDI 1",
    device_port_out = "Ohm64 MIDI 1",
    control_map = "Controllers/Ohm64/Controlmaps/Ohm64.xml",
    thumbnail = "Controllers/Ohm64/Ohm64.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },

  applications = {
    Mixer = {
      mappings = {
        panning = {
          group_name = "PanningLeft",
        },
        levels = {
          group_name = "VolumeLeft",
        },
        mute = {
          group_name = "ButtonsLeft",
        },
      },
      options = {
        invert_mute = 1,
        follow_track = 1,
        -- track_offset = 1,
        page_size = 5,
      }
    },
    Mixer2 = {
      application = "Mixer",
      mappings = {
        panning = {
          group_name = "PanningRight",
        },
        levels = {
          group_name = "VolumeRight",
        },
        mute = {
          group_name = "ButtonsRight",
        },
        --       Setting the crossfader to master volume may be too annoying, uncomment if you wish to try it!
        master = {
          group_name = "CrossFader",
          index = 2
        },
      },
      options = {
        invert_mute = 1,
        follow_track = 1,
        track_offset = 5,
        page_size = 5,
      }
    },
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Grid",
        },
        triggers = {
          group_name = "Grid2",
        },
        sequence = {
          group_name = "ControlsRight",
          orientation = VERTICAL,
          index = 1,
        },
        track = {
          group_name = "ControlsRight",
          index = 2,
        }
      },
      options = {
        follow_track = 1,
        page_size = 5,
      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name= "EncodersEffect",
        },
        page = {
          group_name = "ControlsRight",
          index = 5,
        }
      }
    },
    Transport = {
      mappings = {
        start_playback = {
          group_name = "BigButton",
          index = 1,
        },        
      },
      options = {
        pattern_play = 3,
      }
    },
    SwitchConfiguration = {
      mappings = {
        goto_previous = {
            group_name = "CrossFader",
            index = 1,
        },
        goto_next = {
            group_name = "CrossFader",
            index = 3,
        },
      }
    },

  }
}

