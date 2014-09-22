--[[----------------------------------------------------------------------------
-- Duplex.TouchOSC 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "KeyPad",
  pinned = true,

  -- device properties
  device = {
    class_name = "TouchOSC",
    display_name = "TouchOSC",
    device_prefix = nil,
    device_address = "10.0.0.2",
    device_port_in = "8001",
    device_port_out = "8081",
    control_map = "Controllers/TouchOSC/Controlmaps/TouchOSC_KeyPad.xml",
    thumbnail = "Controllers/TouchOSC/TouchOSC.bmp",
    protocol = DEVICE_PROTOCOL.OSC,
  },
  applications = {

    ---- Global
    --[[
    ]]
    TiltSensor = {
      application = "XYPad",
      mappings = {
        slider_x = {
          group_name = "TiltSensor",
          index = 1
        },
        slider_y = {
          group_name = "TiltSensor",
          index = 2
        },
        xy_pad = {
          group_name = "TiltSensor",
          index = 3,
        },

      },
    },

    ---- Page #1

    Keyboard = {
      mappings = {
        keys = {
          group_name = "Keyboard",
        },
        key_grid = {
          group_name = "Pads",
        },
        octave_set = {
          group_name = "Controls1",
          index = 2,
        },
        volume = {
          group_name = "Controls2",
          index = 1,
        },
        pitch_bend = {
          group_name = "Controls2",
          index = 2,
        },
        mod_wheel = {
          group_name = "Controls2",
          index = 3,
        },
      },
      -- set palette to fully monochrome
      palette = { 
        key_released_content  = { color = {0x00,0x00,0x00} },
        key_released_selected = { color = {0x00,0x00,0x00} },
      },
      -- TouchOSC seems to leave out a note-release every now and then - 
      -- setting keys to release "when possible" fixes that problem
      options = {
        release_type = 2,
      }
    },
    XYPad = {
      mappings = {
        xy_pad = {
          group_name = "Controls2",
          index = 4,
        },
      },
    },



  }
}

