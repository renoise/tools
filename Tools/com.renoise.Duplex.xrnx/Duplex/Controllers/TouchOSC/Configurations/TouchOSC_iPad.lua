--[[----------------------------------------------------------------------------
-- Duplex.TouchOSC 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "TouchOSC - Renoise iPad",
  pinned = true,

  -- device properties
  device = {
    class_name = "TouchOSC",
    display_name = "TouchOSC",
    device_prefix = nil,
    device_address = "10.0.0.2",
    device_port_in = "8001",
    device_port_out = "8081",
    control_map = "Controllers/TouchOSC/Controlmaps/TouchOSC_iPad.xml",
    thumbnail = "Controllers/TouchOSC/TouchOSC.bmp",
    protocol = DEVICE_PROTOCOL.OSC,
  },

  applications = {
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Navigator"
        },
        prev_block = {
          group_name = "NavigatorPrev",
          index = 1,
        },
        next_block = {
          group_name = "NavigatorNext",
          index = 1,
        }
      }
    },
    Matrix = {
      mappings = {
        triggers = {
          group_name = "Sequence",
          orientation = ORIENTATION.VERTICAL
        },
        prev_seq_page = {
          group_name = "SequencePrev",
          index = 1
        },
        next_seq_page = {
          group_name = "SequenceNext",
          index = 1
        }
      }	
    },
    Mixer = {
      mappings = {
        mute = {
          group_name = "MixerMutes"
        },
        prev_page = {
          group_name = "MixerPrev",
          index = 2
        },
        next_page = {
          group_name = "MixerNext",
          index = 1
        }
      }
    },
    TrackSelector = {
      mappings = {
        select_track = {
          group_name = "TrackSelector"
        },
        select_first = {
          group_name = "FirstTrack",
          index = 2,
        },
        select_master = {
          group_name = "MasterTrack",
          index = 1,
        }
      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name = "EffectFaders",        
          index = 1
        },
        param_names = {
          group_name = "EffectParamLabels*",
          index = 1
        },
        param_values = {
          group_name = "EffectParamLabels*",
          index = 2
        },
        device = {
          group_name = "Devices",        
        },
        device_name = {
          group_name = "DeviceName",
          index = 2,
        },
        preset_prev = {
          group_name = "DevicePreset",
          index = 1,
        },
        preset_next = {
          group_name = "DevicePreset",
          index = 2,
        },
        param_prev = {
          group_name = "FXPage",
          index = 1,
        },
        param_next = {
          group_name = "FXPage",
          index = 2,
        },
      }
    },
    Hydra = {
      mappings = {
        input_slider = {
          group_name = "HydraDial",
          index = 2
        },
        value_display = {
          group_name = "HydraDial",
          index = 1
        },
        lock_button = {
          group_name = "HydraControls",
          index = 2,
        },
        prev_device = {
          group_name = "HydraControls",
          index = 3,
        },
        next_device = {
          group_name = "HydraControls",
          index = 4,
        },
      }
    },
    XYPad = {
      mappings = {
        xy_pad = {
          group_name = "XYPad",
          index = 1
        },
        lock_button = {
          group_name = "XYPadControls",
          index = 2,
        },
        prev_device = {
          group_name = "XYPadControls",
          index = 3,
        },
        next_device = {
          group_name = "XYPadControls",
          index = 4,
        },
      }
    },
    Repeater = {
      mappings = {
        grid = {
          group_name = "RepeaterGrid"
        },
        lock_button = {
          group_name = "RepeaterControls",
          index = 2,
        },
        prev_device = {
          group_name = "RepeaterControls",
          index = 3,
        },
        next_device = {
          group_name = "RepeaterControls",
          index = 4,
        },
      }
    },

    Transport = {
      mappings = {
        bpm_decrease = {
          group_name = "Controls",
          index = 1,
        },
        bpm_display = {
          group_name = "Controls",
          index = 2,
        },
        bpm_increase = {
          group_name = "Controls",
          index = 3,
        },
        goto_previous = {
          group_name = "Controls",
          index = 5,
        },
        start_playback = {
          group_name = "Controls",
          index = 6,
        },
        stop_playback = {
          group_name = "Controls",
          index = 7,
        },
        goto_next = {
          group_name = "Controls",
          index = 8,
        },
        loop_pattern = {
          group_name = "Controls",
          index = 9,
        },
        block_loop = {
          group_name = "Controls",
          index = 10,
        },
        follow_player = {
          group_name = "Controls",
          index = 11,        
        },
        edit_mode = {
          group_name = "Controls",
          index = 12,
        },
        metronome_toggle = {
          group_name = "Controls",
          index = 13,
        },
        songpos_display = {
          group_name = "SongPos",
          index = 2,
        }
      }
    }
  }
}

