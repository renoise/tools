--[[----------------------------------------------------------------------------
-- Duplex.Custombuilt
----------------------------------------------------------------------------]]--

-- UIComponents demo configuration

duplex_configurations:insert {

  -- configuration properties
  name = "UISlider Demo",
  pinned = true,
  
  -- device properties
  device = {
    class_name = nil,          
    display_name = "Custombuilt",
    device_port_in = "",
    device_port_out = "",
    control_map = "Controllers/Custombuilt/Controlmaps/UISlider_Demo.xml",
    protocol = DEVICE_PROTOCOL.MIDI
  },

  applications = {
    UISlider_dial = {
      application = "MidiActions",
      mappings = {
        control = {
          group_name = "UISlider",
          index = 1,
        },
      },
      options = {
        action = "Transport:Song:BPM [Set]",
        max_scaling = "270",
        scaling = "Exp"
      }
    },
    UISlider_fader = {
      application = "MidiActions",
      mappings = {
        control = {
          group_name = "UISlider",
          index = 2,
        },
      },
      options = {
        action = "Transport:Song:BPM [Set]",
        max_scaling = "270",
        scaling = "Exp"
      }
    },
    UISlider_button = {
      application = "MidiActions",
      mappings = {
        control = {
          group_name = "UISlider_button",
          index = 1,
        },
      },
      options = {
        action = "Transport:Song:BPM [Set]",
        max_scaling = "270",
        scaling = "Exp"
      }
    },
    UISlider_button_column = {
      application = "MidiActions",
      mappings = {
        control = {
          group_name = "UISlider_column",
          orientation = ORIENTATION.VERTICAL,
        },
      },
      options = {
        action = "Transport:Song:BPM [Set]",
        max_scaling = "270",
        scaling = "Exp"
      }
    },
    UISlider_button_row = {
      application = "MidiActions",
      mappings = {
        control = {
          group_name = "UISlider_row",
          orientation = ORIENTATION.HORIZONTAL,
        },
      },
      options = {
        action = "Transport:Song:BPM [Set]",
        max_scaling = "270",
        scaling = "Exp"
      }
    },
    UISlider_button_grid = {
      application = "MidiActions",
      mappings = {
        control = {
          group_name = "UISlider_grid",
          orientation = ORIENTATION.NONE,
        },
      },
      options = {
        action = "Transport:Song:BPM [Set]",
        max_scaling = "270",
        scaling = "Exp"
      },
    },
  }
}

