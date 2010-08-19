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
print("Change orientation")  
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

-- default configurations for the monome

--------------------------------------------------------------------------------

-- setup "Mixer" as the only app for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Mixer",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 128",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Monome128.xml",
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
        master = {
          --group_name = "Grid",
        }
      },
      options = {
        invert_mute = 2
      }
    }
  }
}

--------------------------------------------------------------------------------

-- setup "Mixer" as the only app for this configuration

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix + Mixer",
  pinned = true,

  -- device properties
  device = {
    class_name = "Monome",
    display_name = "Monome 128",
    device_prefix = "/duplex",
    device_address = "127.0.0.1",
    device_port_in = "8002",
    device_port_out = "8082",
    control_map = "Controllers/Monome/Monome128_split.xml",
    thumbnail = "Monome.bmp",
    protocol = DEVICE_OSC_PROTOCOL,
--[[
    options = {
      cable_orientation = 2 -- up
    }
]]
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
        page = {
          group_name = "Controls2",
          index = 1
        },
        mode = {
          group_name = "Controls2",
          index = 8
        }
      },
      options = {
        invert_mute = 2
      }
    }
  }
}

