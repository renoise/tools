--[[----------------------------------------------------------------------------
-- Duplex.Launchpad 
----------------------------------------------------------------------------]]--

--[[

Inheritance: Launchpad > MidiDevice > Device

A device-specific class 

--]]


--==============================================================================

class "Launchpad" (MidiDevice)

function Launchpad:__init(name, message_stream)
  TRACE("Launchpad:__init", name, message_stream)

  MidiDevice.__init(self, name, message_stream)

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

-- all LEDs are turned off, and the mapping mode, buffer settings, 
-- and duty cycle are reset to defaults

function Launchpad:reset()
    MidiDevice.send_cc_message(self,0,0)
end


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
-- this is a fullblown implementation (with a custom class + control-map)


--------------------------------------------------------------------------------

device_configurations:insert {

  -- configuration properties
  name = "MixConsole",
  pinned = true,

  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_name = "Launchpad",
    control_map = "Controllers/Launchpad/Launchpad.xml",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  -- setup "MixConsole" as the only app for this configuration
  applications = {
    MixConsole = {
      levels = {
        group_name = "Grid",
      },
      mute = {
        group_name = "Controls",
      },
      master = {
        group_name = "Triggers",
      }
    }
  }
}


--------------------------------------------------------------------------------

device_configurations:insert {

  -- configuration properties
  name = "PatternMatrix",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_name = "Launchpad",
    control_map = "Controllers/Launchpad/Launchpad.xml",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  -- setup "PatternMatrix" as the only app for this configuration
  applications = {
    PatternMatrix = {
      matrix = {
        group_name = "Grid",
      },
      triggers = {
        group_name = "Triggers",
      },
      sequence = {
        group_name = "Controls",
        index = 0,
      },
      track = {
        group_name = "Controls",
        index = 2,
      }
    }
  }
}


--------------------------------------------------------------------------------

device_configurations:insert {

  -- configuration properties
  name = "MixConsole & PatternMatrix",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "Launchpad",
    display_name = "Launchpad",
    device_name = "Launchpad",
    control_map = "Controllers/Launchpad/Launchpad_VerticalSplit.xml",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  -- setup "PatternMatrix" and "MixConsole", vertically split
  applications = {
    PatternMatrix = {
      matrix = {
        group_name = "Grid",
      },
      triggers = {
        group_name = "Grid",
      },
      sequence = {
        group_name = "Controls",
        index = 0,
      },
      track = {
        group_name = "Controls",
        index = 2,
      }
    },
    MixConsole = {
      levels = {
        group_name = "Grid2",
      },
      mute = {
        group_name = "Grid2",
      },
      master = {
        group_name = "Grid2",
      }
    }
  }
}

