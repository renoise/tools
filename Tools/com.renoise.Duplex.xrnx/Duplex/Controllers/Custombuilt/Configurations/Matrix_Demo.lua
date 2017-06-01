--[[----------------------------------------------------------------------------
-- Duplex.Custombuilt
----------------------------------------------------------------------------]]--

-- This configuration demonstrates the Matrix application

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix (demo)",
  pinned = true,

  -- device properties
  device = {
    class_name = "Custombuilt",          
    display_name = "Custombuilt",
    device_port_in = "",
    device_port_out = "",
    control_map = "Controllers/Custombuilt/Controlmaps/Matrix.xml",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Matrix",
        },
        triggers = {
          group_name = "Triggers",
        },
        trigger_labels = {
          group_name = "TriggerLabels",
        },
        prev_seq_page = {
          group_name = "Controls",
          index = 1,
        },
        next_seq_page = {
          group_name = "Controls",
          index = 2,
        },
        prev_track_page = {
          group_name = "Controls",
          index = 3,
        },
        next_track_page = {
          group_name = "Controls",
          index = 4,
        },
      },
      
    },

  }
}


