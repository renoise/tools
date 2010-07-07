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
  self.colorspace = {1,1,1}
end


--------------------------------------------------------------------------------

device_configurations:insert {

  -- configuration properties
  name = "Default",
  pinned = true,

  -- device properties
  device = {
    class_name = "Ohm64",          
    display_name = "Ohm64",
    device_name = "Ohm64 MIDI 1",
    control_map = "Controllers/Ohm64/Ohm64.xml",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  -- setup a "MixConsole" and "PatternMatrix" as apps
  applications = {
    MixConsole = {
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
    PatternMatrix = {
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

