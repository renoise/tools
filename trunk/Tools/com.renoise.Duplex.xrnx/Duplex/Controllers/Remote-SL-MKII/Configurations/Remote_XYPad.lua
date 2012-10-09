-- setup XYPad for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "XYPad",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Remote SL MKII Automap",
    device_port_in = "Automap MIDI",
    device_port_out = "Automap MIDI",
    control_map = "Controllers/Remote-SL-MKII/Controlmaps/Remote-SL-MKII.xml",
    thumbnail = "Controllers/Remote-SL-MKII/Remote-SL-MKII.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    XYPad = {
      mappings = {
        x_slider = {
          group_name = "XYPad",
          index = 1
        },
        y_slider = {
          group_name = "XYPad",
          index = 2
        }
      }
    },
    Keyboard_PitchBend = {
      application = "Keyboard",
      mappings = {
        pitch_bend = {
          group_name = "PB",
          index = 1,
        },
      },
      options = {
        pitch_bend = "Route to CC#41" -- Route to CC#41, as 0-40 are being used
      },
      hidden_options = {  -- hide all options but "pitch_bend"
        "instr_index","track_index","velocity_mode","keyboard_mode","base_volume","channel_pressure","release_type","button_width","button_height","base_octave","upper_note","lower_note",
      },
    },
    --[[
    Mixer = {
      mappings = {
        master = {
          group_name = "XYPad",
          index = 1,
        },
        panning = {
          group_name = "XYPad",
          index = 2,
        }
      },
      options = {
        page_size = 2,     -- "1",
        follow_track = 1,  -- "Follow track enabled"
      }
    },
    ]]
  }
}
