--[[----------------------------------------------------------------------------
-- Duplex.ZoomR16
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = "ZoomR16",
    display_name = "ZoomR16",
    device_port_in = "ZOOM R16_24 Audio Interface",
    device_port_out = "ZOOM R16_24 Audio Interface",
    control_map = "Controllers/ZoomR16/Controlmaps/ZoomR16.xml",
    --thumbnail = "",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    Transport = {
      mappings = {
        stop_playback = {
          group_name = "Buttons",
          index = 1,
        },
        start_playback = {
          group_name = "Buttons",
          index = 2,
        },

      }
    },

  }
}
