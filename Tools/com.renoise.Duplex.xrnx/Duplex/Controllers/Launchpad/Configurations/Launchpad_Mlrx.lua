--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

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
    protocol = DEVICE_PROTOCOL.MIDI,
  },

  applications = {
    Mlrx = {
      mappings = {

        -- global --

        triggers = {
          group_name = "grid",
        },
        select_track = {
          group_name = "track_select",
        },
        track_labels  = {
          group_name = "labels",
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
          index = 1,
        },

        -- mixer --

        group_toggles = {
          group_name = "toggles",
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
          group_name = "track_controls",
          index = 1,
        },
        set_mode_toggle = {
          group_name = "track_controls",
          index = 2,
        },
        set_mode_write = {
          group_name = "track_controls",
          index = 3,
        },
        set_mode_touch = {
          group_name = "track_controls",
          index = 4,
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
          group_name = "track_controls",
          index = 5,
        },
        set_cycle_4 = {
          group_name = "track_controls",
          index = 6,
        },
        set_cycle_8 = {
          group_name = "track_controls",
          index = 7,
        },
        set_cycle_16 = {
          group_name = "track_controls",
          index = 8,
        },
        set_cycle_es = {
          group_name = "edit_step",
          index = 1,
        },

        transpose_up = {
          group_name = "controls",
          index = 1,
        },
        transpose_down = {
          group_name = "controls",
          index = 2,
        },
        toggle_sync = {
          group_name = "controls",
          index = 3,
        },
        tempo_up = {
          group_name = "instr_transpose",
          index = 2,
        },
        tempo_down = {
          group_name = "instr_transpose",
          index = 3,
        },

        toggle_arp = {
          group_name = "controls",
          index = 4,
        },
        arp_mode = {
          group_name = "arpeggiator",
          index = 2,
        },

        toggle_loop = {
          group_name = "toggle_loop",
          index = 2,
        },
        shuffle_amount = {
          group_name = "shuffle",
          index = 2,
        },
        shuffle_label = {
          group_name = "shuffle",
          index = 4,
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

      },

    },

  }
}


