--[[----------------------------------------------------------------------------
-- Duplex.Controllers.Oxygen88 
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "TestPad",
  pinned = true,
  
  -- device properties
  device = {
    class_name = nil,
    display_name = "Oxygen88",
    device_port_in = "none",
    device_port_out = "none",
    control_map = "Controllers/Oxygen88/Controlmaps/Oxygen88.xml",
    --thumbnail = nil,
    protocol = DEVICE_PROTOCOL.MIDI,
  },

  applications = {

    PatternCursor = {
      mappings = {
        prev_line_editstep = {
          group_name = "PrevNext",
          index = 1,
        },
        next_line_editstep = {
          group_name = "PrevNext",          
          index = 2,
        }
      }
    },

  }
}

