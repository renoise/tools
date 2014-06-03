--[[----------------------------------------------------------------------------
-- Duplex.AkaiLPD8
----------------------------------------------------------------------------]]--

duplex_configurations:insert {
  -- configuration properties
  name = "NotesOnWheels",
  pinned = true,
  -- device properties
  device = {
    display_name = "AkaiLPD8",
    device_port_in = "MIDIIN2 (AkaiLPD8)",
    device_port_out = "MIDIOUT2 (AkaiLPD8)",
    control_map = "Controllers/AkaiLPD8/Controlmaps/AkaiLPD8_NOW.xml",
    thumbnail = "Controllers/AkaiLPD8/AkaiLPD8.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  applications = {
    NotesOnWheels = {
      mappings = {
        multi_sliders = {
          group_name = "Knobs",
        },
        set_mode_pitch = {
          group_name = "Pads",
          index = 4,
        },
        set_mode_velocity = {
          group_name = "Pads",
          index = 5,
        },
        set_mode_offset = {
          group_name = "Pads",
          index = 6,
        },
        set_mode_gate = {
          group_name = "Pads",
          index = 7,
        },
        set_mode_retrig = {
          group_name = "Pads",
          index = 8,
        },
        multi_adjust = {
          group_name = "Knobs2",
          index = 1,
        },
        step_spacing = {
          group_name = "Knobs2",
          index = 2,
        },
        write = {
          group_name = "Pads",
          index = 1,
        },
        learn = {
          group_name = "Pads",
          index = 2,
        },
        global = {
          group_name = "Pads",
          index = 3,
        },

      },
      options = {
      }
    },
  }
}