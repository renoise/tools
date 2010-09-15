--[[============================================================================
 testing.lua
============================================================================]]--


-- test applications and configurations for UIComponents


--------------------------------------------------------------------------------

duplex_configurations:insert {

  -- configuration properties
  name = "TestUIPushButton",
  pinned = true,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Launchpad.xml",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    TestUIPushButton = {
      mappings = {
        grid = {
          group_name = "Grid",
        },
      }
    }
  }
}

--------------------------------------------------------------------------------

duplex_configurations:insert {

  -- configuration properties
  name = "Bogus",
  pinned = true,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Launchpad.xml",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  -- setup "Bogus" as test for a non-existing application class
  applications = {
    Bogus = {}
  }
}

--------------------------------------------------------------------------------

duplex_configurations:insert {

  -- configuration properties
  name = "TestUIPushButton",
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
    TestUIPushButton = {
      mappings = {
        grid = {
          group_name = "Grid",
        },
      }
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
    device_port_in = "Ohm64 MIDI 1",
    device_port_out = "Ohm64 MIDI 1",
    control_map = "Controllers/Ohm64/Ohm64.xml",
    protocol = DEVICE_MIDI_PROTOCOL
  },

  applications = {
    TestUISpinner = {
      mappings = {}
    }
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
    device_port_in = "Ohm64 MIDI 1",
    device_port_out = "Ohm64 MIDI 1",
    control_map = "Controllers/Ohm64/Ohm64.xml",
    protocol = DEVICE_MIDI_PROTOCOL
  },

  applications = {
    TestUISlider = {
      mappings = {}
    }
  }
}

