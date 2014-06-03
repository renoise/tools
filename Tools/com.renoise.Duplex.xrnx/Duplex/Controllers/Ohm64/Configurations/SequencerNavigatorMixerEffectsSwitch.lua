--[[----------------------------------------------------------------------------
-- Duplex.Ohm64 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Step Sequencer, Navigator, Mixer, Effects & SwitchConfiguration",
  pinned = true,

  -- device properties
  device = {
    class_name = "Ohm64",          
    display_name = "Ohm64Switch",
    device_port_in = "Ohm64 MIDI 1",
    device_port_out = "Ohm64 MIDI 1",
    control_map = "Controllers/Ohm64/Controlmaps/Ohm64.xml",
    thumbnail = "Controllers/Ohm64/Ohm64.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },

  applications = {
    Mixer = {
      mappings = {
        panning = {
          group_name = "Panning_*",
        },
        levels = {
          group_name = "Volume_*",
        },
      },
      options = {
        follow_track = 1,
        page_size = 5,
      }
    },
    StepSequencer = {
      mappings = {
        grid = {
          group_name = "Grid",
        },
        level = {
          group_name = "Buttons_2",
          orientation = ORIENTATION.HORIZONTAL,
          index = 1
        },
        prev_line = {
          group_name = "ControlsRight",
          index = 1
        },
        next_line = {
          group_name = "ControlsRight",
          index = 4
        },
        track = {
          group_name = "ControlsRight",
          orientation = ORIENTATION.HORIZONTAL,
          index = 2
        },
        transpose = {
          group_name = "Buttons_1",
          index = 1
        },
      },
      options = {
        orientation = 1,  
        follow_track = 1,
        page_size = 5,           
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Grid2",
        }
      }
    },
    Effect = {
      mappings = {
        parameters = {
            group_name= "EncodersEffect",
        },
        param_prev = {
          group_name = "ControlsRight",
          index = 5,
        },
        param_next = {
          group_name = "ControlsRight",
          index = 6,
        },
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
      },
    }
  }
}

