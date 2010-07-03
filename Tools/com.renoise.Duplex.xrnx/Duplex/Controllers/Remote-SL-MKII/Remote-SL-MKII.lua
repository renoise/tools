--[[----------------------------------------------------------------------------
-- Duplex.Remote-SL-MKII
----------------------------------------------------------------------------]]--

-- default configurations of the Remote-SL
-- only uses a control map and the MixConsole application

--------------------------------------------------------------------------------

device_configurations:insert {

  -- configuration properties
  name = "MixConsole",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Remote SL MKII Automap",
    device_name = "Automap MIDI",
    control_map = "Controllers/Remote-SL-MKII/Remote-SL-MKII.xml",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  -- setup "MixConsole" as the only app for this configuration
  applications = {
    MixConsole = {
      levels = {
        group_name = "Sliders",
      },
      mute = {
        group_name = "SliderButtons",
      }
      --master_group_name = "XFader",
    },
  }
}
