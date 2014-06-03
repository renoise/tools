--[[----------------------------------------------------------------------------
-- Duplex.MPD32
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "PerformancePads",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,
    display_name = "MPD32",
    device_port_in = "Akai MPD32 (Port 1)",
    device_port_out = "Akai MPD32 (Port 1)",
    control_map = "Controllers/MPD32/Controlmaps/MPD32_Pads.xml",
    thumbnail = "Controllers/MPD32/MPD32.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  applications = {
    Pad01 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad1" }},
      options  = {track_index = 2, instr_index = 2},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },
    Pad02 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad2" }},
      options  = {track_index = 3, instr_index = 3},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },
    Pad03 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad3" }},
      options  = {track_index = 4, instr_index = 4},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },
    Pad04 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad4" }},
      options  = {track_index = 5, instr_index = 5},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },
    Pad05 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad5" }},
      options  = {track_index = 6, instr_index = 6},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },
    Pad06 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad6" }},
      options  = {track_index = 7, instr_index = 7},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },
    Pad07 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad7" }},
      options  = {track_index = 8, instr_index = 8},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },
    Pad08 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad8" }},
      options  = {track_index = 9, instr_index = 9},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },
    Pad09 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad9" }},
      options  = {track_index = 10, instr_index = 10},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },
    Pad10 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad10" }},
      options  = {track_index = 11, instr_index = 11},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },
    Pad11 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad11" }},
      options  = {track_index = 12, instr_index = 12},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },
    Pad12 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad12" }},
      options  = {track_index = 13, instr_index = 13},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },
    Pad13 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad13" }},
      options  = {track_index = 14, instr_index = 14},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },
    Pad14 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad14" }},
      options  = {track_index = 15, instr_index = 15},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },
    Pad15 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad15" }},
      options  = {track_index = 16, instr_index = 16},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },
    Pad16 = {
      application = "Keyboard",
      mappings = {key_grid = {group_name = "Pad16" }},
      options  = {track_index = 17, instr_index = 17},
      hidden_options = {  "base_volume","channel_pressure","pitch_bend","release_type","button_width","button_height","base_octave","keyboard_mode","velocity_mode","upper_note","lower_note"},
    },


  }
}
