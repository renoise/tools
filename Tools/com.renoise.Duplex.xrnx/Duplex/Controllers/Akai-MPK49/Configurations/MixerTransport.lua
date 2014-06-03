--[[----------------------------------------------------------------------------
-- Duplex.Akai-MPK49
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Akai-MPK49",
    device_port_in = "Akai MPK49",
    device_port_out = "Akai MPK49",
    control_map = "Controllers/Akai-MPK49/Controlmaps/Akai-MPK49.xml",
    thumbnail = "Controllers/Akai-MPK49/Akai-MPK49.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    Mixer = {
      mappings = {
        panning = {
          group_name = "Encoders",
        },
        levels = {
          group_name = "Faders",
        },
        mute = {
          group_name= "Buttons",
        },
    },
  },
    Transport = {
      mappings = {
        goto_previous = {
          group_name = "Transport",
          index = 1,
        },
        goto_next = {
          group_name = "Transport",
          index = 2,
        },
        stop_playback = {
          group_name = "Transport",
          index = 3,
        },
        start_playback = {
          group_name = "Transport",
          index = 4,
        },
        edit_mode = {
          group_name = "Transport",
          index = 5,
        },
      },
    },
  }
}

