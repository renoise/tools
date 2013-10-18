--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

-- setup the "mlrx" sequencer for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Mlrx",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 128",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Controlmaps/Monome128_Mlrx.xml",
    thumbnail = "Controllers/Monome/Monome.bmp",
    protocol = DEVICE_OSC_PROTOCOL,
  },
  applications = {
    Mlrx = {
      mappings = {

        -- global --

        triggers = {
          group_name = "triggers",
        },
        select_track = {
          group_name = "track_select",
        },
        track_labels  = {
          group_name = "track_labels",
        },
        matrix = {
          group_name = "group_matrix",
        },
        erase = {
          group_name = "modifiers",
          index = 1,
        },
        clone = {
          group_name = "modifiers",
          index = 2,
        },

        -- mixer --

        group_toggles = {
          group_name = "group_toggles",
        },
        group_levels = {
          group_name = "group_levels",
        },

        -- tracks --

        set_mode_loop = {
          group_name = "trigger_mode",
          index = 1,
        },
        set_mode_hold = {
          group_name = "trigger_mode",
          index = 2,
        },

        toggle_sample_offset = {
          group_name = "toggle_offsets",
          index = 1,
        },
        toggle_envelope_offset = {
          group_name = "toggle_offsets",
          index = 2,
        },

        set_cycle_1 = {
          group_name = "cycle_length",
          index = 1,
        },
        set_cycle_2 = {
          group_name = "cycle_length",
          index = 2,
        },
        set_cycle_4 = {
          group_name = "cycle_length",
          index = 3,
        },
        set_cycle_8 = {
          group_name = "cycle_length",
          index = 4,
        },
        set_cycle_16 = {
          group_name = "cycle_length",
          index = 5,
        },

        transpose_up = {
          group_name = "instr_transpose",
          index = 1,
        },
        transpose_down = {
          group_name = "instr_transpose",
          index = 2,
        },
        toggle_sync = {
          group_name = "instr_transpose",
          index = 3,
        },
        toggle_keys = {
          group_name = "instr_transpose",
          index = 4,
        },

      },

    },




  }
}

