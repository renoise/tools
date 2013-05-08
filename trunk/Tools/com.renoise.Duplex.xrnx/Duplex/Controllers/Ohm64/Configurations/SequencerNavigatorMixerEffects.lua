--[[----------------------------------------------------------------------------
-- Duplex.Ohm64 
----------------------------------------------------------------------------]]--

-- setup Mixer + Step sequencer + Navigator + Effects

duplex_configurations:insert {

  -- configuration properties
  name = "Step Sequencer, Navigator, Mixer & Effects",
  pinned = true,

  -- device properties
  device = {
    class_name = "Ohm64",          
    display_name = "Ohm64",
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
          group_name = "Panning_*",
        },
        levels = {
          group_name = "Volume_*",
        },
--       Setting the crossfader to master volume may be too annoying, uncomment if you wish to try it!
--        master = {
--          group_name = "CrossFader",
--          index = 2
--        },
      },
      options = {
--        invert_mute = 1,
        follow_track = 1,
        page_size = 5,
      }
    },
    --[[
     ]]
    StepSequencer = {
      mappings = {
        grid = {
          group_name = "Grid",
        },
        level = {
          group_name = "Buttons_2",
          orientation = HORIZONTAL,
          index = 1
        },
        line = {
          group_name = "ControlsRight",
          orientation = VERTICAL,
          index = 1
        },
        track = {
          group_name = "ControlsRight",
          orientation = HORIZONTAL,
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
        --page = {
        --  group_name = "ControlsRight",
        --  index = 5,
        --}
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
        goto_previous = {
          group_name = "CrossFader",
          index = 1,
        },
        goto_next = {
          group_name = "CrossFader",
          index = 3,
        },
        start_playback = {
          group_name = "BigButton",
          index = 1,
        },        
      },
      options = {
        pattern_play = 3,
      }
    },

  }
}

