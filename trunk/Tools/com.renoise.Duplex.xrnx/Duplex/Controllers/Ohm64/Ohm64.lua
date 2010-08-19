--[[----------------------------------------------------------------------------
-- Duplex.Ohm64 
----------------------------------------------------------------------------]]--

--[[

Inheritance: Ohm64 > MidiDevice > Device

A device-specific class 

--]]


--==============================================================================

class "Ohm64" (MidiDevice)

function Ohm64:__init(display_name, message_stream, port_in, port_out)
  TRACE("Ohm64:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- setup a monochrome colorspace for the OHM
  self.colorspace = {1,1,1}
end


--------------------------------------------------------------------------------

-- setup Mixer + Matrix + Effect as apps

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer, Matrix & Effects",
  pinned = true,

  -- device properties
  device = {
    class_name = "Ohm64",          
    display_name = "Ohm64",
    device_port_in = "Ohm64 MIDI 1",
    device_port_out = "Ohm64 MIDI 1",
    control_map = "Controllers/Ohm64/Ohm64.xml",
    thumbnail = "Ohm64.bmp",
    protocol = DEVICE_MIDI_PROTOCOL
  },
  
  applications = {
    Mixer = {
      mappings = {
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
    },
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Grid",
        },
        triggers = {
          group_name = "Grid",
        },
        sequence = {
          group_name = "ControlsRight",
          index = 1,
        },
        track = {
          group_name = "ControlsRight",
          index = 3,
        }
      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name= "EncodersEffect",
        },
        page = {
          group_name = "ControlsRight",
          index = 5,

        }
      }
    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name = "CrossFader",
          index = 1,
        },
        goto_next = {
          group_name = "CrossFader",
          index = 3,
        },

      }
    },

  }
}

