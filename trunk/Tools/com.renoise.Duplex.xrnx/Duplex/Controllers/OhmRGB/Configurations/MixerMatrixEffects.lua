--[[----------------------------------------------------------------------------
-- Duplex.OhmRGB 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix, Mixer & Effects",
  pinned = true,

  -- device properties
  device = {
    class_name = "OhmRGB",          
    display_name = "OhmRGB",
    device_port_in = "OhmRGB MIDI 1",
    device_port_out = "OhmRGB MIDI 1",
    control_map = "Controllers/OhmRGB/Controlmaps/OhmRGB.xml",
    thumbnail = "Controllers/OhmRGB/OhmRGB.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    Mixer = {
      mappings = {
        panning = {
          group_name = "Panning_*",
        },
        levels = {
          group_name = "Volume_*",
        },
        mute = {
          group_name = "Buttons_*",
        },
      },
      options = {
        invert_mute = 1,
        follow_track = 1,
        page_size = 5,
      }
    },
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Grid",
        },
        triggers = {
          group_name = "Grid2",
        },
        prev_seq_page = {
          group_name = "ControlsRight",
          index = 1,
        },
        next_seq_page = {
          group_name = "ControlsRight",
          index = 2,
        },
        track = {
          group_name = "ControlsRight",
          index = 2,
        }
      },
      options = {
        follow_track = 1,
        page_size = 5,
      },
      palette = {
        -- pattern matrix
        out_of_bounds       = { color={0x00,0x00,0x00}},
        slot_empty          = { color={0x00,0x00,0x00}},
        slot_empty_muted    = { color={0x00,0x00,0x00}},
        slot_filled         = { color={0xff,0xff,0x00}},
        slot_filled_muted   = { color={0xff,0x00,0x00}},
        slot_master_filled  = { color={0xff,0xff,0x00}},
        slot_master_empty   = { color={0xff,0x00,0x00}},
        -- pattern sequence (buttonstrip)
        trigger_active      = { color={0xff,0xff,0xff}},
        trigger_loop        = { color={0x00,0xff,0xff}},
        trigger_back        = { color={0x00,0x00,0x00}},
        -- pattern sequence navigation (prev/next)
        --[[
        prev_seq_on         = { color={0xFF,0xFF,0xFF}},
        prev_seq_off        = { color={0x00,0x00,0x00}},
        next_seq_on         = { color={0xFF,0xFF,0xFF}},
        next_seq_off        = { color={0x00,0x00,0x00}},
        -- track navigation (prev/next)
        prev_track_on       = { color={0xFF,0xFF,0xFF}},
        prev_track_off      = { color={0x00,0x00,0x00}},
        next_track_on       = { color={0xFF,0xFF,0xFF}},
        next_track_off      = { color={0x00,0x00,0x00}},
        ]]
      
      }
    },
    --[[
    Effect = {
      mappings = {
        parameters = {
          group_name= "EncodersEffect",
        },
        param_prev = {
          group_name = "ControlsRight",
          index = 5,
        },
        param_next = {
          group_name = "ControlsRight",
          index = 6,
        },
      }
    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name = "CrossFader",
          index = 1,
        },
        goto_next = {
          group_name = "CrossFader",
          index = 3,
        },
        start_playback = {
          group_name = "BigButton",
          index = 1,
        },        
      },
      options = {
        pattern_play = 3,
      }
    },
    ]]

  }
}



