--[[----------------------------------------------------------------------------
-- Duplex.Custombuilt
----------------------------------------------------------------------------]]--

-- Compact Notes On Wheels configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Notes On Wheels (compact)",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Custombuilt",
    device_port_in = "",
    device_port_out = "",
    control_map = "Controllers/Custombuilt/Controlmaps/NOW_Controller_compact.xml",
    thumbnail = "Controllers/Custombuilt/NOW_Controller.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    NotesOnWheels = {
      mappings = {
        multi_sliders = {
          group_name = "DialRow_1",
        },
        multi_adjust = {
          group_name = "Fader_1",
        },

        num_steps = {
          group_name = "ButtonRow",
          --orientation = ORIENTATION.HORIZONTAL,
        },
        step_spacing = {
          group_name = "Dials",
          index = 1,
        },
        write = {
          group_name = "Controls",
          index = 1,
        },
        learn = {
          group_name = "Controls",
          index = 2,
        },
        global = {
          group_name = "Controls",
          index = 3,
        },
        set_mode_pitch = {
          group_name = "Controls",
          index = 4,
        },
        set_mode_velocity = {
          group_name = "Controls",
          index = 5,
        },
        set_mode_offset = {
          group_name = "Controls",
          index = 6,
        },
        set_mode_gate = {
          group_name = "Controls",
          index = 7,
        },
        set_mode_retrig = {
          group_name = "Controls",
          index = 8,
        },
        shift_up = {
          group_name = "ButtonPair",
          index = 1,
        },
        shift_down = {
          group_name = "ButtonPair",
          index = 2,
        },
        position = {
          group_name = "LedRow",
        },

      }
    }
  }
}

