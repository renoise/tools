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
        select_track = {
          group_name= "Pots",
          index = 1,
        },
      },
    }
  }
}

