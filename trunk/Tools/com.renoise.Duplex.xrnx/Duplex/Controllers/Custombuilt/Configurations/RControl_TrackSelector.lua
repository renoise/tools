--[[----------------------------------------------------------------------------
-- Duplex.Custombuilt
----------------------------------------------------------------------------]]--

-- setup "TrackSelector" for the imaginary "R-Control" device

duplex_configurations:insert {

  -- configuration properties
  name = "TrackSelector",
  pinned = true,
  
  -- device properties
  device = {
    display_name = "R-control",
    device_port_in = "",
    device_port_out = "",
    control_map = "Controllers/Custombuilt/Controlmaps/R-control.xml",
    thumbnail = "Controllers/Custombuilt/R-control.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },

  applications = {
    TrackSelector = {
      mappings = {
        select_first = {
          group_name = "Switches",
          index = 5,
        },
        select_sends = {
          group_name = "Switches",
          index = 7,
        },
        select_track = {
          group_name = "Master",
        },
      },
    },
  }
}

