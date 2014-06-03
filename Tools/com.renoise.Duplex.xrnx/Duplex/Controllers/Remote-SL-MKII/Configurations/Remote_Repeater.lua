
duplex_configurations:insert {

  -- configuration properties
  name = "Repeater",
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
    Repeater = {
      mappings = {
        grid = {
          group_name = "SliderButtons",
        },
        prev_device = {
          group_name = "Controls",
          index = 1
        },
        next_device = {
          group_name = "Controls",
          index = 2
        },
        mode_free = {
          group_name = "Controls",
          index = 3
        },
        mode_even = {
          group_name = "Controls",
          index = 4
        },
        mode_triplet = {
          group_name = "Controls",
          index = 5
        },
        mode_dotted = {
          group_name = "Controls",
          index = 6
        },
        lock_button = {
          group_name = "Controls",
          index = 8
        },
        mode_slider = {
          group_name = "Sliders",
          index = 1
        },
        divisor_slider = {
          group_name = "Sliders",
          index = 2
        }
      }
    },

  }
}
