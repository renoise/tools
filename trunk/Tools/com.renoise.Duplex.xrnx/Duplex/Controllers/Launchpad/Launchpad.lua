--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

--[[

Inheritance: Launchpad > MidiDevice > Device

A device-specific class 

--]]


--==============================================================================

class "Launchpad" (MidiDevice)

function Launchpad:__init(display_name, message_stream, port_in, port_out)
  TRACE("Launchpad:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- this device has a color-space with 4 degrees of red and green
  self.colorspace = {4, 4, 0}

  -- double-buffering features (not used)
  --[[
  self.display = 0
  self.update = 0
  self.flash = 0
  self.copy = 0
  ]]
end

--------------------------------------------------------------------------------

-- clear display before releasing device:
-- all LEDs are turned off, and the mapping mode, buffer settings, 
-- and duty cycle are reset to defaults

function Launchpad:release()
  TRACE("Launchpad:release()")

  self:send_cc_message(0,0) 
  MidiDevice.release(self)

end

--------------------------------------------------------------------------------

function Launchpad:point_to_value(pt)
  TRACE("Launchpad:point_to_value")

  -- default color is light/yellow
  local rslt = 127

  local red = pt.color[1]
  local green = pt.color[2]


  red = math.floor(red/64)
  green = math.floor(green/64)

  -- 12 for standard flags
  rslt = 16*green+red+12

  return rslt

end

--[[

--------------------------------------------------------------------------------

-- set grid mapping mode to X-Y layout

function Launchpad:set_xy_map_mode()
    MidiDevice.send_cc_message(self,0,1)
end


--------------------------------------------------------------------------------

-- set grid mapping mode to drum rack layout

function Launchpad:set_drum_map_mode()
  MidiDevice.send_cc_message(self,0,1)
end


--------------------------------------------------------------------------------

-- range: 0-2 (low/medium/high brightness test)

function Launchpad:display_test(number)
  MidiDevice.send_cc_message(self,0,125+number)
end


--------------------------------------------------------------------------------

-- Set buffer 0 or buffer 1 as the new ‘displaying’ buffer. 

function Launchpad:set_active_display(number)
  self.display = 0
  MidiDevice.send_cc_message(self,0,self.getCompositeBufferValue())
end


--------------------------------------------------------------------------------

-- Set buffer 0 or buffer 1 as the new ‘updating’ buffer

function Launchpad:set_update_display(number)
  self.update = 0
    MidiDevice.send_cc_message(self,0,self.getCompositeBufferValue())
end


--------------------------------------------------------------------------------

-- If 1: continually flip ‘displayed’ buffers to make selected LEDs flash

function Launchpad:set_flash_mode(number)
  self.flash = 0
    MidiDevice.send_cc_message(self,0,self.getCompositeBufferValue())
end


--------------------------------------------------------------------------------

-- copy the LED states from the new ‘displayed’ buffer to the new ‘updating’ buffer

function Launchpad:copy_buffer()
  self.flash = 0
    MidiDevice.send_cc_message(self,0,self.getCompositeBufferValue())
end


--------------------------------------------------------------------------------

-- utility function
function Launchpad:getCompositeBufferValue()
  local result = 32+display+(update*4)+(flash*8)+(copy*16)
end
]]


--==============================================================================

-- default configurations for the launchpad

--------------------------------------------------------------------------------

-- setup "Mixer" as the only app for this configuration

--[[
duplex_configurations:insert {

  -- configuration properties
  name = "Mixer",
  pinned = false,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Launchpad.xml",
    thumbnail = "Launchpad.bmp",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "Grid",
        },
        mute = {
          group_name = "Controls",
        },
        master = {
          group_name = "Triggers",
        }
      },
      options = {
        invert_mute = 1
      }
    }
  }
}
]]
--------------------------------------------------------------------------------

-- setup "Recorder + Navigator" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Recorder + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Launchpad_Recorder.xml",
    thumbnail = "Launchpad.bmp",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    Recorder = {
      mappings = {
        recorders = {
          group_name = "Grid",
        },
        sliders = {
          group_name = "Grid",
        },
      },
      options = {
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Triggers",
        }
      }
    },
    Mixer = {
      mappings = {
        mute = {
          group_name = "Row",
        },
      },
      options = {
        follow_track = 2,
      }
    },
    Mixer_Track = {
      application = "Mixer",
      mappings = {
        levels = {
          group_name = "Column",
        },
      },
      options = {
        follow_track = 1,
      }
    },
    TrackSelector = {
      mappings = {
        prev_next_page = {
          group_name = "Controls",
          index = 3,
        },
      },
      options = {
        page_size = 1 ,
      }
    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name= "Controls",
          index = 1,
        },
        goto_next = {
          group_name= "Controls",
          index = 2,
        },
        edit_mode = {
          group_name = "Controls",
          index = 5,
        },
        start_playback = {
          group_name = "Controls",
          index = 6,
        },
        loop_pattern = {
          group_name = "Controls",
          index = 7,
        },
        follow_player = {
          group_name= "Controls",
          index = 8,
        },
      },
      options = {
        pattern_play = 3,
      }
    },
  }
}

--------------------------------------------------------------------------------

-- setup "Mixer + Transport" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Navigator + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Launchpad_Mixer.xml",
    thumbnail = "Launchpad.bmp",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "Grid",
        },
        mute = {
          group_name = "Grid",
        },
        solo = {
          group_name = "Grid",
        },
        master = {
          group_name = "Grid",
        },
        page = {
          group_name = "Controls",
          index = 3
        },
      },
      options = {
        invert_mute = 1,
        page_size = 2,
        follow_track = 1,
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Triggers",
        }
      }
    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name= "Controls",
          index = 1,
        },
        goto_next = {
          group_name= "Controls",
          index = 2,
        },
        edit_mode = {
          group_name = "Controls",
          index = 5,
        },
        start_playback = {
          group_name = "Controls",
          index = 6,
        },
        loop_pattern = {
          group_name = "Controls",
          index = 7,
        },
        follow_player = {
          group_name= "Controls",
          index = 8,
        },
      },
      options = {
        pattern_play = 3,
      },
    },
  }
}


--------------------------------------------------------------------------------

-- setup "Matrix + Transport" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix + Transport",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Launchpad_Matrix.xml",
    thumbnail = "Launchpad.bmp",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Grid",
        },
        triggers = {
          group_name = "Triggers",
        },
        sequence = {
          group_name = "Controls",
          index = 1,
        },
        track = {
          group_name = "Controls",
          index = 3,
        }
      },
      options = {
        sequence_mode = 2,
      }
    },
    Transport = {
      mappings = {
        --[[
        stop_playback = {
          group_name= "Controls",
          index = 5,
        },
        ]]
        edit_mode = {
          group_name = "Controls",
          index = 5,
        },
        start_playback = {
          group_name = "Controls",
          index = 6,
        },
        loop_pattern = {
          group_name = "Controls",
          index = 7,
        },
        follow_player = {
          group_name= "Controls",
          index = 8,
        },
      },
      options = {
        pattern_play = 3,
      }
    },

  }
}


--------------------------------------------------------------------------------

-- setup "Matrix" as the only app for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Effect + Transport",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Launchpad_Effect.xml",
    thumbnail = "Launchpad.bmp",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {

    Transport = {
      mappings = {
        --[[
        stop_playback = {
          group_name= "Controls",
          index = 5,
        },
        ]]
        edit_mode = {
          group_name = "Controls",
          index = 5,
        },
        start_playback = {
          group_name = "Controls",
          index = 6,
        },
        loop_pattern = {
          group_name = "Controls",
          index = 7,
        },
        follow_player = {
          group_name= "Controls",
          index = 8,
        },
      },
      options = {
        pattern_play = 3,
      }
    },
    TrackSelector = {
      mappings = {
      --[[
        prev_next_track = {
          group_name = "Controls",
          index = 1,
        },
        ]]
        prev_next_page = {
          group_name = "Controls",
          index = 3,
        },
        --[[
        select_first = {
          group_name = "Controls",
          index = 5,
        },
        select_master = {
          group_name = "Controls",
          index = 6,
        },
        select_sends = {
          group_name = "Controls",
          index = 7,
        },
        ]]
        select_track = {
          group_name = "Row",
          index = 1,
        },
      },
      options = {      
        page_size = 3,
      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name= "Grid",
        },
        page = {
          group_name = "Controls",
          index = 1,
        },
        device = {
          group_name = "Triggers",
        },
      },
    },


  }
}

--------------------------------------------------------------------------------

-- setup "Matrix + Mixer + Transport", vertically split

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix + Mixer + Transport",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_port_in = "Launchpad",
    device_port_out = "Launchpad",
    control_map = "Controllers/Launchpad/Launchpad_MatrixMixer.xml",
    thumbnail = "Launchpad.bmp",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Grid",
        },
        triggers = {
          group_name = "Triggers",
        },
        sequence = {
          group_name = "Controls",
          index = 1,
        },
        track = {
          group_name = "Controls",
          index = 3,
        }
      },
      options = {      
      }
    },
    Mixer = {
      mappings = {
        levels = {
          group_name = "Grid2",
        },
        mute = {
          group_name = "Grid2",
        },
        master = {
          group_name = "Triggers2",
        }
      },
      options = {
        invert_mute = 1
      }
    },
    Transport = {
      mappings = {
        stop_playback = {
          group_name= "Controls",
          index = 5,
        },
        start_playback = {
          group_name = "Controls",
          index = 6,
        },
        loop_pattern = {
          group_name = "Controls",
          index = 7,
        },
        edit_mode = {
          group_name = "Controls",
          index = 8,
        },
      },
      options = {
      }
    },
  }
}


--------------------------------------------------------------------------------

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
    control_map = "Controllers/Launchpad/Launchpad_StepSequencer.xml",
    thumbnail = "Launchpad.bmp",
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

      -- enable this for horizontal layout

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

--------------------------------------------------------------------------------

-- Here's how to make a second Launchpad show up as a separate device 
-- Notice that the "display name" is different

--[[
duplex_configurations:insert {

  -- configuration properties
  name = "Matrix + Transport",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad (2)",
    device_port_in = "Launchpad (2)",
    device_port_out = "Launchpad (2)",
    control_map = "Controllers/Launchpad/Launchpad.xml",
    thumbnail = "Launchpad.bmp",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Grid",
        },
        triggers = {
          group_name = "Triggers",
        },
        sequence = {
          group_name = "Controls",
          index = 1,
        },
        track = {
          group_name = "Controls",
          index = 3,
        }
      },
      options = {
        --switch_mode = 4,
      }
    },
    Transport = {
      mappings = {
        edit_mode = {
          group_name = "Controls",
          index = 5,
        },
        start_playback = {
          group_name = "Controls",
          index = 6,
        },
        loop_pattern = {
          group_name = "Controls",
          index = 7,
        },
        follow_player = {
          group_name= "Controls",
          index = 8,
        },
      },
      options = {
        pattern_play = 3,
      },
    },

  }
}

]]
