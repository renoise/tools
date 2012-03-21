--[[----------------------------------------------------------------------------
-- Duplex.KONTROL49
----------------------------------------------------------------------------]]--

-- set up "GridPie + Mixer" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "GridPie + Mixer",
  pinned = true,

  -- device properties
  device = {
    display_name = "KONTROL49",
    device_port_in = "MIDIIN2 (KONTROL49)",
    device_port_out = "MIDIOUT2 (KONTROL49)",
    control_map = "Controllers/KONTROL49/Controlmaps/KONTROL49_GridPie.xml",
    thumbnail = "Controllers/KONTROL49/KONTROL49.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },

  applications = {
    GridPie = {
      mappings = {
        grid = {
          group_name = "Pads"
        },
        h_prev = {
          group_name = "Switches",
          index = 1
        },
        h_next = {
          group_name = "Switches",
          index = 2
        }
      },
      options = {
        v_step = 2,
        h_step = 2,
      }
    },
    Mixer = {
      mappings = {
        --[[
        mute = {
          group_name = "Pads A"
        },
        solo = {
          group_name = "Pads B"
        },
        ]]
        panning = {
          group_name = "Encoders"
        },
        levels = {
          group_name = "Sliders"
        },
        --[[
        page = {
          group_name = "Switches"
        }
        ]]
        master = {
          group_name = "Master"
        }
      },
      options = {
        pre_post = 2
      }
    }
  }
}

