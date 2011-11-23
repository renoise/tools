--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

-- setup Daxton's Step Sequencer for the Launchpad

duplex_configurations:insert {

  -- configuration properties
  name = "Step Sequencer",
  pinned = true,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Controlmaps/Launchpad_StepSequencer.xml",
    thumbnail = "Controllers/Launchpad/Launchpad.bmp",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    StepSequencer = {

      -- vertical layout (default)

      mappings = {
        grid = {
          group_name = "Grid",
          orientation = VERTICAL,
        },
        level = {
          group_name = "Triggers",
          orientation = VERTICAL,
        },
        line = {
          group_name = "Controls",
          orientation = HORIZONTAL,
          index = 1
        },
        track = {
          group_name = "Controls",
          orientation = HORIZONTAL,
          index = 3
        },
        transpose = {
          group_name = "Controls",
          orientation = HORIZONTAL,
          index = 5
        },
      },
      options = {
        --line_increment = 8,
        --follow_track = 1,
        --page_size = 5,
      }

      --[[

      -- enable this instead for horizontal layout

      mappings = {
        grid = {
          group_name = "Grid",
          orientation = HORIZONTAL,
        },
        level = {
          group_name = "Controls",
          orientation = HORIZONTAL,
        },
        line = {
          group_name = "Triggers",
          orientation = VERTICAL,
          index = 1
        },
        track = {
          group_name = "Triggers",
          orientation = VERTICAL,
          index = 3
        },
        transpose = {
          group_name = "Triggers",
          orientation = VERTICAL,
          index = 5
        },
      },
      ]]
    },
  }
}

