
duplex_configurations:insert {

  -- configuration properties
  name = "MidiActions",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Remote SL MKII Automap",
    device_port_in = "Automap MIDI",
    device_port_out = "Automap MIDI",
    control_map = "Controllers/Remote-SL-MKII/Controlmaps/Remote-SL-MKII.xml",
    thumbnail = "Controllers/Remote-SL-MKII/Remote-SL-MKII.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    LPB_Buttons = {
      application = "MidiActions",
      mappings = {
        control = {
          group_name = "SliderButtons",
          -- no index == use entire row, get a "grid slider" as the result
        },
      },
      options = {
        action = "Transport:Song:LPB [Set]",
        min_scaling = "1",
        max_scaling = "9",
      }
    },
    BPM_90 = {
      application = "MidiActions",
      mappings = {
        control = {
          group_name = "Controls",
          index = 1,
        },
      },
      options = {
        action = "Transport:Song:BPM [Set]",
        min_scaling = "90",
        max_scaling = "90",
      }
    },
    BPM_110 = {
      application = "MidiActions",
      mappings = {
        control = {
          group_name = "Controls",
          index = 2,
        },
      },
      options = {
        action = "Transport:Song:BPM [Set]",
        min_scaling = "110",
        max_scaling = "110",
      }
    },
    BPM_130 = {
      application = "MidiActions",
      mappings = {
        control = {
          group_name = "Controls",
          index = 3,
        },
      },
      options = {
        action = "Transport:Song:BPM [Set]",
        min_scaling = "130",
        max_scaling = "130",
      }
    },

  }
}
