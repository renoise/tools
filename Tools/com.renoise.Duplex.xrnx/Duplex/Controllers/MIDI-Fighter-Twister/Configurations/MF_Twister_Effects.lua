--[[----------------------------------------------------------------------------
-- Duplex.MIDI-Fighter-Twister
----------------------------------------------------------------------------]]--

duplex_configurations:insert {

  -- configuration properties
  name = "Effects",
  pinned = true,

  -- device properties
  device = {
    --class_name = "",          
    device_port_in = "",
    device_port_out = "",
    thumbnail = "Controllers/MIDI-Fighter-Twister/Thumbnail.bmp",
    display_name = "MIDI-Fighter Twister",
    control_map = "Controllers/MIDI-Fighter-Twister/Controlmaps/MF_Twister.xml",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {
    Effect = {
      mappings = {
        parameters = {
          group_name = "Encoder*",
          index = 1,
        },

      },
    },

  }
}


