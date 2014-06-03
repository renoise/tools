--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

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
    protocol = DEVICE_PROTOCOL.OSC,
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
          group_name = "global",
          index = 1,
        },
        clone = {
          group_name = "global",
          index = 2,
        },
        automation = {
          group_name = "automation",
          index = 2,
        },

        -- group mixer --

        group_toggles = {
          group_name = "group_toggles",
        },
        group_levels = {
          group_name = "group_levels",
        },
        group_panning = {
          group_name = "group_panning",
        },

        -- track mixer --

        track_levels = {
          group_name = "track_levels",
        },
        track_panning = {
          group_name = "track_panning",
        },

        -- tracks --

        set_source_slice = {
          group_name = "source_mode",
          index = 2,
        },
        set_source_phrase = {
          group_name = "source_mode",
          index = 3,
        },

        set_mode_hold = {
          group_name = "trigger_mode",
          index = 2,
        },
        set_mode_toggle = {
          group_name = "trigger_mode",
          index = 3,
        },
        set_mode_write = {
          group_name = "trigger_mode",
          index = 4,
        },
        set_mode_touch = {
          group_name = "trigger_mode",
          index = 5,
        },

        toggle_arp = {
          group_name = "arpeggiator",
          index = 2,
        },
        arp_mode = {
          group_name = "arpeggiator",
          index = 3,
        },

        toggle_loop = {
          group_name = "toggle_loop",
          index = 2,
        },

        shuffle_label = {
          group_name = "shuffle",
          index = 1,
        },
        shuffle_amount = {
          group_name = "shuffle",
          index = 2,
        },
        toggle_shuffle_cut = {
          group_name = "shuffle",
          index = 3,
        },

        drift_label = {
          group_name = "drift",
          index = 1,
        },
        drift_amount = {
          group_name = "drift",
          index = 2,
        },
        drift_enable = {
          group_name = "drift",
          index = 3,
        },

        toggle_note_output = {
          group_name = "toggle_output",
          index = 2,
        },
        toggle_sxx_output = {
          group_name = "toggle_output",
          index = 3,
        },
        toggle_exx_output = {
          group_name = "toggle_output",
          index = 4,
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
        set_cycle_es = {
          group_name = "cycle_length",
          index = 6,
        },
        set_cycle_custom = {
          group_name = "cycle_length",
          index = 7,
        },
        increase_cycle = {
          group_name = "cycle_length",
          index = 8,
        },
        decrease_cycle = {
          group_name = "cycle_length",
          index = 9,
        },

        transpose_up = {
          group_name = "instr_transpose",
          index = 2,
        },
        transpose_down = {
          group_name = "instr_transpose",
          index = 3,
        },
        toggle_sync = {
          group_name = "instr_transpose",
          index = 4,
        },
        tempo_up = {
          group_name = "instr_transpose",
          index = 5,
        },
        tempo_down = {
          group_name = "instr_transpose",
          index = 6,
        },

        xy_pad = {
          group_name = "ADC",
          index = 1,
        },
      },

    },
  }
}

