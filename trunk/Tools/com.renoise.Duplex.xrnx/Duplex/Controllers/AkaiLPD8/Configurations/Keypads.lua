--[[----------------------------------------------------------------------------
-- Duplex.AkaiLPD8
----------------------------------------------------------------------------]]--

-- setup "Keyboard" for this configuration

duplex_configurations:insert {
  -- configuration properties
  name = "Keyboard",
  pinned = true,
  -- device properties
  device = {
    display_name = "AkaiLPD8",
    device_port_in = "MIDIIN2 (AkaiLPD8)",
    device_port_out = "MIDIOUT2 (AkaiLPD8)",
    control_map = "Controllers/AkaiLPD8/Controlmaps/AkaiLPD8_Keypad.xml",
    thumbnail = "Controllers/AkaiLPD8/AkaiLPD8.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  applications = {
    Keyboard = {
      mappings = {
        key_grid = {
          group_name = "Pads",
          index = 1,
        },
      },
      options = {},
      hidden_options = {  -- display minimal set of options
        "channel_pressure","pitch_bend","release_type","button_width","button_height"
      },
    },

  }
}