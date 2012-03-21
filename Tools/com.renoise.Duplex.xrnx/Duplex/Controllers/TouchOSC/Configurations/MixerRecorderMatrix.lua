--[[----------------------------------------------------------------------------
-- Duplex.TouchOSC 
----------------------------------------------------------------------------]]--

-- setup "Mixer + Recorder + Matrix" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Handset (simple template)",
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
    protocol = DEVICE_OSC_PROTOCOL,
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
        sequence = {
          group_name = "4_Buttons",
          index = 1,
        },
        track = {
          group_name = "4_Buttons",
          index = 3,
        }
      },
      options = {
        sequence_mode = 2,  -- to support "togglebutton" input
      }
    }
  }
}

