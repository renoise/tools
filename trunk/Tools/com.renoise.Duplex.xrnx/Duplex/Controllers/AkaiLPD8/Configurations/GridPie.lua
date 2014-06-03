--[[----------------------------------------------------------------------------
-- Duplex.AkaiLPD8
----------------------------------------------------------------------------]]--

duplex_configurations:insert {
  -- configuration properties
  name = "GridPie",
  pinned = true,
  -- device properties
  device = {
    display_name = "AkaiLPD8",
    device_port_in = "MIDIIN2 (AkaiLPD8)",
    device_port_out = "MIDIOUT2 (AkaiLPD8)",
    control_map = "Controllers/AkaiLPD8/Controlmaps/AkaiLPD8_GridPie.xml",
    thumbnail = "Controllers/AkaiLPD8/AkaiLPD8.bmp",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  applications = {
    GridPie = {
      mappings = {
        grid = {
          group_name = "Pads",
        },
        v_slider = {
          group_name = "Knobs",
          index = 1
        },
        h_slider = {
          group_name = "Knobs",
          index = 2
        },
      },
      options = {
        -- keep at minimum step size
        v_step = 2,
        h_step = 2,
      }
    },

  }
}