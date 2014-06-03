--[[----------------------------------------------------------------------------
-- Duplex.Custombuilt
----------------------------------------------------------------------------]]--

-- Standard Notes On Wheels configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Notes On Wheels",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Custombuilt",
    device_port_in = "",
    device_port_out = "",
    control_map = "Controllers/Custombuilt/Controlmaps/NOW_Controller.xml",
    thumbnail = "Controllers/Custombuilt/NOW_Controller.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    NotesOnWheels = {
      mappings = {
        pitch_sliders = {
          group_name = "DialRow_2",
        },
        pitch_adjust = {
          group_name = "Fader_2",
        },
        velocity_sliders = {
          group_name = "DialRow_3",
        },
        velocity_adjust = {
          group_name = "Fader_3",
        },
        offset_sliders = {
          group_name = "DialRow_4",
        },
        offset_adjust = {
          group_name = "Fader_4",
        },
        gate_sliders = {
          group_name = "DialRow_5",
        },
        gate_adjust = {
          group_name = "Fader_5",
        },
        retrig_sliders = {
          group_name = "DialRow_6",
        },
        retrig_adjust = {
          group_name = "Fader_6",
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
        fill = {
          group_name = "Controls",
          index = 3,
        },
        global = {
          group_name = "Controls",
          index = 4,
        },
        shrink = {
          group_name = "Dials",
          index = 2,
        },
        extend = {
          group_name = "Dials",
          index = 3,
        },
        set_mode_pitch = {
          group_name = "Controls",
          index = 5,
        },
        set_mode_velocity = {
          group_name = "Controls",
          index = 6,
        },
        set_mode_offset = {
          group_name = "Controls",
          index = 7,
        },
        set_mode_gate = {
          group_name = "Controls",
          index = 8,
        },
        set_mode_retrig = {
          group_name = "Controls",
          index = 9,
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


