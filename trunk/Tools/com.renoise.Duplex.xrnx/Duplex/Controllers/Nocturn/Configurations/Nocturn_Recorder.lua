--[[----------------------------------------------------------------------------
-- Duplex.Nocturn
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Recorder",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Nocturn Automap",
    device_port_in = "Automap MIDI",
    device_port_out = "Automap MIDI",
    control_map = "Controllers/Nocturn/Controlmaps/Nocturn.xml",
    thumbnail = "Controllers/Nocturn/Nocturn.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    Recorder = {
      mappings = {
        recorders = {
          group_name = "Pots",
        },
        sliders = {
          group_name = "Encoders",
        },
      },
      options = {
        --writeahead = 1,
        --loop_mode = 2,
        --beat_sync = 1,
        --trigger_mode = 1,
      }
    }
  }
}
