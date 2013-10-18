--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

-- setup "Mixer + Transport" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Mlrx",
  pinned = true,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Controlmaps/Launchpad_Mlrx.xml",
    thumbnail = "Controllers/Launchpad/Launchpad.bmp",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    Mlrx = {
      mappings = {

        -- global --

        triggers = {
          group_name = "Grid",
        },
        select_track = {
          group_name = "Triggers",
        },
        track_labels  = {
          group_name = "Labels",
        },
        matrix = {
          group_name = "group_matrix",
        },
        --[[
        erase = {
          group_name = "modifiers",
          index = 1,
        },
        clone = {
          group_name = "modifiers",
          index = 2,
        },
        ]]

        -- mixer --

        group_toggles = {
          group_name = "Toggles",
        },
        group_levels = {
          group_name = "group_levels",
        },

        -- tracks --

        set_mode_loop = {
          group_name = "trigger_mode",
          index = 2,
        },
        set_mode_hold = {
          group_name = "trigger_mode",
          index = 3,
        },
        --[[
        cycle_mode = {
          group_name = "Controls",
          index = 4,
        },
        ]]

        toggle_sample_offset = {
          group_name = "toggle_offsets",
          index = 2,
        },
        toggle_envelope_offset = {
          group_name = "toggle_offsets",
          index = 3,
        },

        set_cycle_1 = {
          group_name = "cycle_length",
          index = 2,
        },
        set_cycle_2 = {
          group_name = "cycle_length",
          index = 3,
        },
        set_cycle_4 = {
          group_name = "cycle_length",
          index = 4,
        },
        set_cycle_8 = {
          group_name = "cycle_length",
          index = 5,
        },
        set_cycle_16 = {
          group_name = "cycle_length",
          index = 6,
        },

        transpose_up = {
          group_name = "Controls",
          index = 1,
        },
        transpose_down = {
          group_name = "Controls",
          index = 2,
        },
        toggle_sync = {
          group_name = "Controls",
          index = 3,
        },
        --toggle_keys = {
        --  group_name = "instr_transpose",
        --  index = 4,
        --},

      },

    },

  }
}


