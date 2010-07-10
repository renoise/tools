--[[--------------------------------------------------------------------------
 Test applications for the various UIComponents
--------------------------------------------------------------------------]]--

require "Duplex/Applications/TestUISlider"
require "Duplex/Applications/TestUISpinner"
require "Duplex/Applications/TestUITriggerButton"

--------------------------------------------------------------------------------

duplex_configurations:insert {

  -- configuration properties
  name = "TestUITriggerButton",
  pinned = true,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_name = "Launchpad",
    control_map = "Controllers/Launchpad/Launchpad.xml",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    TestUITriggerButton = {
      grid = {
        group_name = "Grid",
      },
    }
  }
}


duplex_configurations:insert {

  -- configuration properties
  name = "TestUITriggerButton",
  pinned = true,

  -- device properties
  device = {
    class_name = "Ohm64",          
    display_name = "Ohm64",
    device_name = "Ohm64 MIDI 1",
    control_map = "Controllers/Ohm64/Ohm64.xml",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    TestUITriggerButton = {
      grid = {
        group_name = "Grid",
      },
    }
  }
}

--------------------------------------------------------------------------------

duplex_configurations:insert {

  -- configuration properties
  name = "TestUISpinner",
  pinned = true,

  -- device properties
  device = {
    class_name = "Ohm64",          
    display_name = "Ohm64",
    device_name = "Ohm64 MIDI 1",
    control_map = "Controllers/Ohm64/Ohm64.xml",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    TestUISpinner = {}
  }
}

--------------------------------------------------------------------------------

duplex_configurations:insert {

  -- configuration properties
  name = "TestUISlider",
  pinned = true,

  -- device properties
  device = {
    class_name = "Ohm64",          
    display_name = "Ohm64",
    device_name = "Ohm64 MIDI 1",
    control_map = "Controllers/Ohm64/Ohm64.xml",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    TestUISlider = {}
  }
}

