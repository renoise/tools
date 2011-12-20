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

--==============================================================================

-- Include these configurations for the Launchpad

local CTRL_PATH = "Duplex/Controllers/Launchpad/Configurations/"
require (CTRL_PATH.."EffectTrackSelectorTransport")
require (CTRL_PATH.."MatrixMixerTransport")
require (CTRL_PATH.."MatrixNavigatorTransport")
require (CTRL_PATH.."MixerTransport")
require (CTRL_PATH.."RecorderNavigator")
require (CTRL_PATH.."StepSequencer")
require (CTRL_PATH.."LaunchPad_GridPie")
require (CTRL_PATH.."LaunchPad_XYPad")

--------------------------------------------------------------------------------
-- A couple of sample configurations
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
