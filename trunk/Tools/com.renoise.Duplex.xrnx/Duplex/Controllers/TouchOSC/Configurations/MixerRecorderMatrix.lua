--[[----------------------------------------------------------------------------
-- Duplex.TouchOSC 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Handset - simple",
  pinned = true,

  -- device properties
  device = {
    class_name = "TouchOSC",
    display_name = "TouchOSC",
    device_prefix = nil,
    device_address = "10.0.0.2",
    device_port_in = "8001",
    device_port_out = "8081",
    control_map = "Controllers/TouchOSC/Controlmaps/TouchOSC.xml",
    thumbnail = "Controllers/TouchOSC/TouchOSC.bmp",
    protocol = DEVICE_PROTOCOL.OSC,
  },

  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "1_Faders",
        },
        mute = {
          group_name = "1_Buttons",
        },
        master = {
          group_name = "1_Fader",
        }
      },
    },
    Recorder = {
      mappings = {
        recorders = {
          group_name = "2_Buttons",
        },
        sliders = {
          group_name = "2_TriggerPad",
        },
      },
      options = {
      },
      palette = {
        slider_dimmed = {
          color = {0x80,0x80,0x80},
          text="□",
        },
      }
    },
    PadXY = {
      application = "XYPad",
      mappings = {
        xy_pad = {
          group_name = "3_XYPad",
        },
        lock_button = {
          group_name = "3_Buttons",
          index = 1
        },
        focus_button = {
          group_name = "3_Buttons",
          index = 2
        },
        prev_device = {
          group_name = "3_Buttons",
          index = 3
        },
        next_device = {
          group_name = "3_Buttons",
          index = 4
        }
      },
      options = {
      }
    },
    Matrix = {
      mappings = {
        matrix = {
          group_name = "4_Grid",
        },
        triggers = {
          group_name = "4_Grid",
        },
        prev_seq_page = {
          group_name = "4_Buttons",
          index = 1,
        },
        next_seq_page = {
          group_name = "4_Buttons",
          index = 2,
        },
        track = {
          group_name = "4_Buttons",
          index = 3,
        }
      },
      options = {
        sequence_mode = 2,  -- to support "togglebutton" input
      },
      palette = {
        -- remove text from matrix, there's not enough room...
        out_of_bounds       = { text=""},
        slot_empty          = { text=""},
        slot_empty_muted    = { text=""},
        slot_filled         = { text=""},
        slot_filled_muted   = { text=""},
        slot_master_filled  = { text=""},
        trigger_active      = { text=""},
        trigger_loop        = { text=""},
        trigger_back        = { text=""},
      }
    },
    TiltSensorPad = {
      application = "XYPad",
      mappings = {
        xy_pad = {
          group_name = "Extra",
        },
      },
      options = {
      }
    }
  }
}

