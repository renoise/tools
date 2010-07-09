--[[----------------------------------------------------------------------------
-- Duplex.Ohm64 
----------------------------------------------------------------------------]]--

--[[

Inheritance: Ohm64 > MidiDevice > Device

A device-specific class 

--]]


--==============================================================================

class "Ohm64" (MidiDevice)

function Ohm64:__init(name, message_stream)
  TRACE("Ohm64:__init", name, message_stream)

  MidiDevice.__init(self, name, message_stream)

  -- setup a monochrome colorspace for the OHM
  --self.colorspace = {1,1,1}
end


--------------------------------------------------------------------------------

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer, Matrix & Effects",
  pinned = true,

  -- device properties
  device = {
    class_name = "Ohm64",          
    display_name = "Ohm64",
    device_name = "Ohm64 MIDI 1",
    control_map = "Controllers/Ohm64/Ohm64.xml",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  -- setup a Mixer and Matrix as apps
  applications = {
    Mixer = {
      panning = {
        group_name = "PanningLeft",
      },
      levels = {
        group_name = "VolumeLeft",
      },
      mute = {
        group_name = "ButtonsLeft",
      },
      master = {
        group_name = "VolumeRight",
      },
    },
    Matrix = {
      matrix = {
        group_name = "Grid",
      },
      sequence = {
        group_name = "CrossFader",
        index = 1,
      },
      triggers = {
        group_name = "Grid",
      },
      --[[
      sequence = {
        group_name = "ControlsRight",
        index = 0,
      },
      ]]
      track = {
        group_name = "ControlsRight",
        index = 2,
      }

    },
  }
}

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
  
  -- setup a Mixer and Matrix as apps
  applications = {
    TestUISpinner = {}
  }
}

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
