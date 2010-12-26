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

function Ohm64:point_to_value(pt,elm,ceiling)

  local ceiling = ceiling or 127
  local value
  
  if (type(pt.val) == "boolean") then
    -- buttons
    local color = self:quantize_color(pt.color)
    value = (color[1]==0xff) and elm.maximum or elm.minimum
  else
    -- dials/faders
    value = math.floor((pt.val * (1 / ceiling)) * elm.maximum)
  end

  return tonumber(value)
end


--------------------------------------------------------------------------------

-- setup Mixer + Matrix + Effect as apps - 

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix, Mixer & Effects",
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
      },
      options = {
        invert_mute = 1,
        follow_track = 1,
--        track_offset = 1,
        track_increment = 5,
      }
    },
    Mixer2 = {
      application = "Mixer",
      mappings = {
        panning = {
          group_name = "PanningRight",
        },
        levels = {
          group_name = "VolumeRight",
        },
        mute = {
          group_name = "ButtonsRight",
        },
--       Setting the crossfader to master volume may be too annoying, uncomment if you wish to try it!
--        master = {
--          group_name = "CrossFader",
--          index = 2
--        },
      },
      options = {
        invert_mute = 1,
        follow_track = 1,
        track_offset = 5,
        track_increment = 5,
      }
    },
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Grid",
        },
        triggers = {
          group_name = "Grid2",
        },
        sequence = {
          group_name = "ControlsRight",
          orientation = VERTICAL,
          index = 1,
        },
        track = {
          group_name = "ControlsRight",
          index = 2,
        }
      },
      options = {
        follow_track = 1,
        track_increment = 5,
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
        start_playback = {
          group_name = "BigButton",
          index = 1,
        },        
      },
      options = {
        pattern_play = 3,
      }
    },

  }
}




--------------------------------------------------------------------------------
-- setup Mixer + Step sequencer + Navigator + Effects as apps - 

duplex_configurations:insert {

  -- configuration properties
  name = "Step Sequencer, Navigator, Mixer & Effects",
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
      },
      options = {
--        invert_mute = 1,
        follow_track = 1,
        track_offset = 1,
        track_increment = 5,
      }
    },
    Mixer2 = {
      application = "Mixer",
      mappings = {
        panning = {
          group_name = "PanningRight",
        },
        levels = {
          group_name = "VolumeRight",
        }, 
--       Setting the crossfader to master volume may be too annoying, uncomment if you wish to try it!
--        master = {
--          group_name = "CrossFader",
--          index = 2
--        },
      },
      options = {
--        invert_mute = 1,
        follow_track = 1,
        track_offset = 5,
        track_increment = 5,
      }
    },
    StepSequencer = {
      mappings = {
        grid = {
          group_name = "Grid",
        },
        level = {
          group_name = "ButtonsRight",
          orientation = HORIZONTAL,
          index = 1
        },
        line = {
          group_name = "ControlsRight",
          orientation = VERTICAL,
          index = 1
        },
        track = {
          group_name = "ControlsRight",
          orientation = HORIZONTAL,
          index = 2
        },
        transpose = {
          group_name = "ButtonsLeft",
          index = 1
        },
      },
      options = {
        orientation = 1,  
        follow_track = 1,
        track_increment = 5,           
      }
     },
     Navigator = {
      mappings = {
        blockpos = {
          group_name = "Grid2",
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
        start_playback = {
          group_name = "BigButton",
          index = 1,
        },        
      },
      options = {
        pattern_play = 3,
      }
    },

  }
}

