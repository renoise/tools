--[[----------------------------------------------------------------------------
-- Duplex.Launch Control XL
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Transport",
  pinned = true,

  -- device properties
  device = {
      -- class_name = nil,
      class_name = "LaunchControlXL",
      display_name = "Launch Control XL",
      device_port_in = "Launch Control XL",
      device_port_out = "Launch Control XL",
      control_map = "Controllers/Launch-Control-XL/Controlmaps/03_Transport.xml",
      thumbnail = "Controllers/Launch-Control-XL/Launch-Control-XL.bmp",
      protocol = DEVICE_PROTOCOL.MIDI,
  },

  applications = {
  
    Effect = {
      mappings = {
        parameters = {
            group_name = "DeviceEncoders"
        },
        device_prev = {
          group_name = "DeviceSelect",
          index = 1
        },
        device_next = {
          group_name = "DeviceSelect",
          index = 2
        },
        param_active = {
            group_name = "DeviceEncoderLEDs"
        },
      },
      palette = {
        prev_device_on = {
          color = {0xFF,0x00,0x00},
          text = "▴",
          val = true
        },
        prev_device_off = {
          text = "▴",
          val = false
        },
        next_device_on = {
          color = {0xFF,0x00,0x00},
          text = "▾",
          val = true
        },
        next_device_off = {
          text = "▾",
          val = false
        }
      }
    },

    Mixer = {
      application = "Mixer",
      mappings = {
        panning = {group_name = "PanEncoders"},
        levels = {group_name = "VolumeFaders"}
      },
      options = {
        pre_post = 2,
        follow_track = 1,
        take_over_volumes = 2,
        page_size = 8
      },
      palette = {
        normal_mute_on = {
          color = {0x00,0x00,0x00},
          val = true
        },
        normal_mute_off = {
          color = {0xFF,0x00,0x00},
          val = false
        }
      }
    },

    TrackSelector = {
      mappings = {
        prev_page = {
          group_name = "PageSelectors",
          index = 1
        },
        next_page = {
          group_name = "PageSelectors",
          index = 2
        },
        select_track = {
          group_name = "TrackSelection",
          index = 1
        }
      },
      palette = {
        select_device_tip = {
            color = {0x00,0xFF,0x00},
            text = "▬",
            val = true
        },
        select_device_back = {
            color = {0x00,0x00,0x00},
            text = "▬",
            val = false
        },
        page_prev_on = {
            color = {0xFF,0x00,0x00},
            text = "◂",
            val = true
        },
        page_prev_off = {
            text = "◂",
            val = false
        },
        page_next_on = {
            color = {0xFF,0x00,0x00},
            text = "▸",
            val = true
        },
        page_next_off = {
            text = "▸",
            val = false
        }
      }
    },

    Transport = {
      mappings = {
        start_playback = {
          group_name = "TransportButtons",
          index = 1
        },
        stop_playback = {
          group_name = "TransportButtons",
          index = 2
        },
        goto_previous = {
          group_name = "TransportButtons",
          index = 3
        },
        goto_next = {
          group_name = "TransportButtons",
          index = 4
        },
        follow_player = {
          group_name = "TransportButtons",
          index = 5
        },
        loop_pattern = {
          group_name = "TransportButtons",
          index = 6
        },
        block_loop = {
          group_name = "TransportButtons",
          index = 7
        },
        metronome_toggle = {
          group_name = "TransportButtons",
          index = 8
        },
        edit_mode = {
          group_name = "Modes",
          index = 1
        },
        
      },
      palette = {
        edit_mode_off = {     color = {0x00,0x00,0x00}, text = "●", val = false,},
        edit_mode_on = {      color = {0xFF,0x80,0x00}, text = "●", val = true, },
        follow_player_off = { color = {0x00,0x00,0x00}, text = "↓", val = false },
        follow_player_on = {  color = {0xFF,0x80,0x00}, text = "↓", val = true  },
        loop_block_off = {    color = {0x00,0x00,0x00}, text = "═", val = false,},
        loop_block_on = {     color = {0xFF,0x80,0x00}, text = "═", val = true  },
        loop_pattern_off = {  color = {0x00,0x00,0x00}, text = "∞", val = false,},
        loop_pattern_on = {   color = {0xFF,0x80,0x00}, text = "∞", val = true  },
        metronome_off = {     color = {0x00,0x00,0x00}, text = "∆", val = false,},
        metronome_on = {      color = {0xFF,0x80,0x00}, text = "∆", val = true, },
        next_patt_dimmed = {  color = {0x80,0x80,0x00}, text = "►|",val = false,},
        next_patt_off = {     color = {0x00,0x00,0x00}, text = "►|",val = false,},
        next_patt_on = {      color = {0xFF,0x80,0x00}, text = "►|",val = true, },
        playing_off = {       color = {0x00,0x00,0x00}, text = "►", val = false,},
        playing_on = {        color = {0xFF,0x80,0x00}, text = "►", val = true  },
        prev_patt_dimmed = {  color = {0x80,0x80,0x00}, text = "|◄",val = false,},
        prev_patt_off = {     color = {0x00,0x00,0x00}, text = "|◄",val = false,},
        prev_patt_on = {      color = {0xFF,0x80,0x00}, text = "|◄",val = true, },
        stop_playback_off = { color = {0x00,0x00,0x00}, text = "■", val = false,},
        stop_playback_on = {  color = {0xFF,0x80,0x00}, text = "□", val = true, },
      }
    },
    
    SwitchConfiguration = {
      mappings = {
        goto_1 = {
          group_name = "Modes",
          index = 2
        },
        goto_2 = {
          group_name = "Modes",
          index = 3
        },
        goto_3 = {
          group_name = "Modes",
          index = 4
        }
      },
      palette = {
        set_config_on = {
          color = {0xFF,0x80,0x00},
          text = "",
          val = true
        },
        set_config_off = {
          color = {0x00,0x00,0x00},
          text = "",
          val = false
        }
      }
    }
  }
}
