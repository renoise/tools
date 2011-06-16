--[[----------------------------------------------------------------------------
-- Duplex.Monome 
----------------------------------------------------------------------------]]--

--[[

Inheritance: Monome > OscDevice > Device

A device-specific class, comes with presets for the monome128


Input

  /press [x] [y] [pressed]

  /tilt [hor] [ver]

Output

  /sys/prefix

  /led

  /intensity



--]]


--==============================================================================

class "Monome" (OscDevice)

function Monome:__init(name, message_stream,prefix,address,port_in,port_out)
  TRACE("Monome:__init", name, message_stream,prefix,address,port_in,port_out)

  OscDevice.__init(self, name, message_stream,prefix,address,port_in,port_out)

  -- this device has a monochrome color-space 
  self.colorspace = {1, 1, 1}

  --self.loopback_received_messages = false
--[[
  self.options = {
    cable_orientation = {
      label = "Cable orientation",
      description = "",
      handler = function()
        -- set orientation
      end,
      items = {
        "Left",
        "Up",
        "Right",
        "Down",
      },
      default = 2
    
    }
  
  }
]]
end

--------------------------------------------------------------------------------

-- set prefix both for Duplex and the MonomeSerial application
-- @param prefix (string), e.g. "/my_device" 

function Monome:set_device_prefix(prefix)
  TRACE("Monome:set_device_prefix()",prefix)

  -- unlike the generic OscDevice, monome always need a prefix value
  if (not prefix) then return end

  OscDevice.set_device_prefix(self,prefix)

  if (self.client) and (self.client.is_open) then
    self.client:send(
      renoise.Osc.Message("/sys/prefix",{
        {tag="i", value=0},
        {tag="s", value=self.prefix} 
      })
    )
  end

end

--------------------------------------------------------------------------------

-- clear display before releasing device

function Monome:release()
  TRACE("Monome:release()")

  if (self.client) and (self.client.is_open) then
    self.client:send(
      renoise.Osc.Message(self.prefix.."/clear",{
        {tag="i", value=0},
      })
    )
  end
  OscDevice.release(self)

end


--------------------------------------------------------------------------------

-- quantize value to determine lit/off state
function Monome:point_to_value(pt)
  TRACE("Monome:point_to_value")

  local color = self:quantize_color(pt.color)
  return (color[1]==0xff) and 1 or 0

end

--==============================================================================

-- default configurations for the monome128

--------------------------------------------------------------------------------

-- setup Mixer + Transport for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Transport",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 128",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Monome128_Mixer.xml",
    thumbnail = "Monome.bmp",
    protocol = DEVICE_OSC_PROTOCOL,
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
        page = {
          group_name = "Controls1",
          orientation = HORIZONTAL,
          index = 1,
        },
        mode = {
          group_name = "Controls2",
          index = 1,
        },
      },
      options = {
        invert_mute = 2,
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Navigator",
          orientation = HORIZONTAL,
        }
      }
    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name= "Controls1",
          index = 3,
        },
        goto_next = {
          group_name= "Controls1",
          index = 4,
        },
        --[[
        edit_mode = {
          group_name = "Controls",
          index = 5,
        },
        ]]
        start_playback = {
          group_name = "Controls2",
          index = 2,
        },
        loop_pattern = {
          group_name = "Controls2",
          index = 3,
        },
        follow_player = {
          group_name= "Controls2",
          index = 4,
        },
      },
      options = {
        pattern_play = 3,
      }
    },
  }
}

--------------------------------------------------------------------------------

-- setup Matrix + Effect for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix + Effect",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 128",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Monome128_MatrixEffect.xml",
    thumbnail = "Monome.bmp",
    protocol = DEVICE_OSC_PROTOCOL,
    options = {
      --cable_orientation = 2 -- up
    }
  },

  applications = {
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Grid1",
        },
        triggers = {
          group_name = "Grid1",
        },
        sequence = {
          group_name = "Controls",
          index = 1,
        },
        track = {
          group_name = "Controls",
          index = 3,
        }
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Column",
          orientation = VERTICAL,
        }
      }
    },
    Transport = {
      mappings = {
        start_playback = {
          group_name = "Controls",
          index = 6,
        },
        edit_mode = {
          group_name = "Controls",
          index = 5,
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
    Effect = {
      mappings = {
        parameters = {
          group_name= "Grid2",
        },
        device = {
          group_name = "Controls2",
        },
      },
    },
  }
}

--------------------------------------------------------------------------------

-- setup "Recorder + Mixer" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Recorder + Mixer",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 128",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Monome128_RecorderMixer.xml",
    thumbnail = "Monome.bmp",
    protocol = DEVICE_OSC_PROTOCOL,

  },

  applications = {
    Recorder = {
      mappings = {
        recorders = {
          group_name = "Controls",
        },
        sliders = {
          group_name = "Grid1",
        },
      },
      options = {
        follow_track = 1,
        page_size = 3,
        --autostart
        --trigger_mode
        --beat_sync
        --auto_seek
        --loop_mode
      
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Column",
          orientation = VERTICAL,
        }
      }
    },
    TrackSelector = {
      mappings = {
        prev_next_page = {
          group_name = "Controls2",
          orientation = HORIZONTAL,
          index = 1,
        }
      },
      options = {
        --page_size
      }

    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name= "Controls2",
          index = 3,
        },
        goto_next = {
          group_name= "Controls2",
          index = 4,
        },
        edit_mode = {
          group_name = "Controls2",
          index = 5,
        },
        start_playback = {
          group_name = "Controls2",
          index = 6,
        },
        loop_pattern = {
          group_name = "Controls2",
          index = 7,
        },
        follow_player = {
          group_name= "Controls2",
          index = 8,
        },
      },
      options = {
        pattern_play = 3,
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
          group_name = "Grid2",
        },
        --[[
        page = {
          group_name = "Controls2",
          index = 1
        },
        ]]
        mode = {
          group_name = "Controls2",
          index = 8
        },
        --panning = {},
        --solo = {},
      },
      options = {
        invert_mute = 2,
        follow_track = 1,
        page_size = 3,
        --track_offset
        --pre_post
        --mute_mode
      }
    }
  }
}

--------------------------------------------------------------------------------

-- setup "StepSequencer" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "StepSequencer",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 128",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Monome128_StepSequencer.xml",
    thumbnail = "Monome.bmp",
    protocol = DEVICE_OSC_PROTOCOL,
  },
  applications = {
    StepSequencer = {
      mappings = {
        grid = {
          group_name = "Grid",
          orientation = HORIZONTAL,
        },
        level = {
          group_name = "Row2",
          orientation = HORIZONTAL,
          index = 1,
        },
        line = { 
          group_name = "Controls",
          orientation = HORIZONTAL,
          index = 3,
        },
        track = {
          group_name = "Controls",
          orientation = HORIZONTAL,
          index = 5,
        },
        transpose = {
          group_name = "Column1",
          index = 1,
        },
      },
      options = {
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Row1",
          orientation = HORIZONTAL,
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
        start_playback = {
          group_name = "Column2",
          index = 2,
        },
        loop_pattern = {
          group_name = "Column2",
          index = 4,
        },
        follow_player = {
          group_name= "Column2",
          index = 3,
        },
      },
      options = {
        pattern_play = 3,
      }
    },

  }
}

--==============================================================================

-- default configurations for the monome64 / 40h

--------------------------------------------------------------------------------

-- setup "Mixer" as the only app for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 64",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Monome64_Mixer.xml",
    thumbnail = "Monome.bmp",
    protocol = DEVICE_OSC_PROTOCOL,
  },

  applications = {
    Transport = {
      mappings = {
        goto_previous = {
          group_name= "Controls",
          index = 3,
        },
        goto_next = {
          group_name= "Controls",
          index = 4,
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
        --[[
        follow_player = {
          group_name= "Controls",
          index = 8,
        },
        ]]
      },
      options = {
        pattern_play = 3,
      }
    },
    Mixer = {
      mappings = {
        levels = {
          group_name = "Grid",
        },
        mute = {
          group_name = "Grid",
        },
        page = {
          group_name = "Controls",
          index = 1
        },
        mode = {
          group_name = "Controls",
          index = 8
        }
      },
      options = {
        invert_mute = 2,
        follow_track = 1,
        --page_size
        --track_offset
        --mute_mode
        --pre_post
      }
    }
  }
}

--------------------------------------------------------------------------------

-- setup "Matrix" for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 64",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Monome64_Matrix.xml",
    thumbnail = "Monome.bmp",
    protocol = DEVICE_OSC_PROTOCOL,

  },
  applications = {
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Grid1",
        },
        triggers = {
          group_name = "TrigControls",
        },
        sequence = {
          group_name = "Controls",
          index = 1,
        },
        track = {
          group_name = "Controls",
          index = 3,
        }
      }
    }
  }
}

--------------------------------------------------------------------------------

-- setup StepSequencer for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "StepSequencer",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 64",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Monome64_StepSequencer.xml",
    thumbnail = "Monome.bmp",
    protocol = DEVICE_OSC_PROTOCOL,
  },
  applications = {
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Column1",
          orientation = VERTICAL,
        }
      }
    },
    StepSequencer = {
      mappings = {
        grid = {
          group_name = "Grid",
        },
        level = {
          group_name = "Column2",
          index = 1,
        },
        line = { 
          group_name = "Column3",
          orientation = VERTICAL,
          index = 1,
        },
        track = {
          group_name = "Column3",
          orientation = VERTICAL,
          index = 3,
        },
        transpose = {
          group_name = "Column3",
          index = 5,
        },
      },
    }
  }
}

--------------------------------------------------------------------------------

-- setup "Recorder" as the only app for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Recorder",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 64",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Monome64_Recorder.xml",
    thumbnail = "Monome.bmp",
    protocol = DEVICE_OSC_PROTOCOL,
  },

  applications = {
    TrackSelector = {
      mappings = {
        prev_next_page = {
          group_name = "Controls",
          index = 1,
        },
      },
      options = {
        page_size = 8,
      }
    },
    Recorder = {
      mappings = {
        recorders = {
          group_name = "Row",
        },
        sliders = {
          group_name = "Grid",
        },
      },
      options = {
        follow_track = 1,
        --page_size
        --autostart
        --trigger_mode
        --beat_sync
        --auto_seek
        --loop_mode
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Column",
          orientation = VERTICAL,
        }
      }
    },
    Transport = {
      mappings = {
        goto_previous = {
          group_name= "Controls",
          index = 3,
        },
        goto_next = {
          group_name= "Controls",
          index = 4,
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
      },
      options = {
        pattern_play = 3,
      }
    },
  }
}