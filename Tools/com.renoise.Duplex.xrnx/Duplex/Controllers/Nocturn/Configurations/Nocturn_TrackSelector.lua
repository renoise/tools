--[[----------------------------------------------------------------------------
-- Duplex.Nocturn
----------------------------------------------------------------------------]]--

-- setup TrackSelector as the only app for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "TrackSelector",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Nocturn Automap",
    device_port_in = "Automap MIDI",
    device_port_out = "Automap MIDI",
    control_map = "Controllers/Nocturn/Controlmaps/Nocturn.xml",
    thumbnail = "Controllers/Nocturn/Nocturn.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    TrackSelector = {
      mappings = {
      --[[
        prev_next_track = {
          -- mapped to a UISpinner
          group_name= "Pots",
          orientation = HORIZONTAL,
          index = 1,
        },
        ]]
        prev_next_page = {
          -- mapped to a UISpinner
          group_name= "XFader",
          orientation = HORIZONTAL,
          index = 1,
        },
        select_track = {
          -- mapped to a UISlider
          group_name= "Pots",
          --orientation = HORIZONTAL,
          index = 1,
        },
      },
    }
  }
}

