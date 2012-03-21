--[[----------------------------------------------------------------------------
-- Duplex.Ohm64 
----------------------------------------------------------------------------]]--

-- setup Step Sequencer, Navigator, Mixer, Effects & SwitchConfiguration

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
        },
        options = {
            --        invert_mute = 1,
            follow_track = 1,
            track_offset = 1,
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
            --       Setting the crossfader to master volume may be too annoying, uncomment if you wish to try it!
            master = {
                group_name = "CrossFader",
                index = 2
            },
        },
        options = {
            --        invert_mute = 1,
            follow_track = 1,
            track_offset = 5,
            page_size = 5,
        }
    },
    StepSequencer = {
        mappings = {
            grid = {
                group_name = "Grid",
            },
            level = {
                group_name = "ButtonsRight",
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
                group_name = "ButtonsLeft",
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
        },
    }
  }
}

