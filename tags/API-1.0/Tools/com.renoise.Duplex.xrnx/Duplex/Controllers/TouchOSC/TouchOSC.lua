--[[----------------------------------------------------------------------------
-- Duplex.TouchOSC 
----------------------------------------------------------------------------]]--

--[[

Inheritance: TouchOSC > OscDevice > Device

A device-specific class 


--]]


--==============================================================================

class "TouchOSC" (OscDevice)

function TouchOSC:__init(name, message_stream,prefix,address,port_in,port_out)
  TRACE("TouchOSC:__init", name, message_stream,prefix,address,port_in,port_out)

  OscDevice.__init(self, name, message_stream,prefix,address,port_in,port_out)

  -- this device has a monochrome color-space 
  self.colorspace = {1, 1, 1}

end


--------------------------------------------------------------------------------

function TouchOSC:point_to_value(pt,elm,ceiling)
  TRACE("TouchOSC:point_to_value()",pt,elm,ceiling)

  local value

  if (type(pt.val) == "boolean") then
    -- buttons
    -- quantize value to determine lit/off state
    local color = self:quantize_color(pt.color)
    value = (color[1]==0xff) and elm.maximum or elm.minimum
  else
    -- faders
    value = (pt.val * (1 / ceiling)) * elm.maximum
  
  end
  return value

end

--==============================================================================

-- default configurations for the TouchOSC

--------------------------------------------------------------------------------

-- setup "Mixer" as the only app for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer + Recorder + Matrix",
  pinned = true,

  -- device properties
  device = {
    class_name = "TouchOSC",
    display_name = "TouchOSC",
    device_prefix = nil,
    device_address = "10.0.0.2",
    device_port_in = "8001",
    device_port_out = "8081",
    control_map = "Controllers/TouchOSC/TouchOSC.xml",
    thumbnail = "TouchOSC.bmp",
    protocol = DEVICE_OSC_PROTOCOL,
  },

  applications = {
    Mixer = {
      mappings = {
        levels = {
          group_name = "1_Faders",
        },
        mute = {
          group_name = "1_Buttons",
        },
        master = {
          group_name = "1_Fader",
        }
      },
    },
    Recorder = {
      mappings = {
        recorders = {
          group_name = "2_Buttons",
        },
        sliders = {
          group_name = "2_TriggerPad",
        },
      },
      options = {
      }
    },
    Matrix = {
      mappings = {
        matrix = {
          group_name = "4_Grid",
        },
        triggers = {
          group_name = "4_Grid",
        },
        sequence = {
          group_name = "4_Buttons",
          index = 1,
        },
        track = {
          group_name = "4_Buttons",
          index = 3,
        }
      },
      options = {
        sequence_mode = 2,  -- to support "togglebutton" input
      }
    }
  }
}

