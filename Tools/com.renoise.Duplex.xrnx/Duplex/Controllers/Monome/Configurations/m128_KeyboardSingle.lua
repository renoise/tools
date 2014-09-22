--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "KeyboardSingle",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 128",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Controlmaps/Monome128_KeyboardSingle.xml",
    thumbnail = "Controllers/Monome/Monome.bmp",
    protocol = DEVICE_PROTOCOL.OSC,
  },
  applications = {
    Keyboard = {
      mappings = {
        key_grid = {
          group_name = "Grid"
        },
        pitch_bend = {
          group_name = "ADC",
          index = 1,
        },
        volume = {
          group_name = "ADC",
          index = 2,
        },
        cycle_layout = {
          group_name = "Toggle",
          index = 1,
        },
        volume_sync = {
          group_name = "AltToggle",
          index = 1,
        }
      }, 
      palette = {
        key_released_content = { color = {0xff,0xff,0xff}, val=true,text="·", },
      }
    },
    Instrument = {
      mappings = {
        prev_scale = {
          group_name = "Controls",
          index = 2,
        },
        next_scale = {
          group_name = "Controls",
          index = 3,
        },
        set_key = {
          group_name = "ButtonRow",
          --index = 3,
        },
      }
    },
    TrackSelector = {
      mappings = {
        select_track = {
          group_name = "AltControls",
        },
      }
    }
  }
}

