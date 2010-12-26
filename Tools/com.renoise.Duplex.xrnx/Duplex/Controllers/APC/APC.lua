--[[----------------------------------------------------------------------------
-- Duplex.APC
----------------------------------------------------------------------------]]--

--[[

Inheritance: APC > MidiDevice > Device

A device-specific class, valid for Akai APC20 and APC40 models

--]]


--==============================================================================

class "APC" (MidiDevice)

function APC:__init(display_name, message_stream, port_in, port_out)
  TRACE("APC:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- set device to "mode 1"
  self:send_sysex_message(0x47,0x7F,0x7B,0x60,0x00,0x04,0x41,0x08,0x02,0x01)

  -- define a default colorspace
  self.colorspace = {1, 1, 1}

end

--------------------------------------------------------------------------------

function APC:point_to_value(pt,elm,ceiling)
  TRACE("APC:point_to_value()",pt,elm,ceiling)

  local value

  if (type(pt.val) == "boolean") then

    -- buttons
    local color = self:quantize_color(pt.color)
    -- use the local colorspace if it's available
    local colorspace = elm.colorspace or self.colorspace
    if (colorspace[1]>1) then
      -- clip launch buttons can have multiple colors
      local red = (pt.color[1]==0xff)
      local green = (pt.color[2]==0xff)
      if red and green then
        value = 5 -- yellow
      elseif red then
        value = 3 -- red
      elseif green then
        value = 1 -- green
      else
        value = 0 -- turned off
      end
    else
      -- normal LED buttons are monochrome
      value = (color[1]==0xff) and elm.maximum or elm.minimum
    end

  else

    -- faders
    value = (pt.val * (1 / ceiling)) * elm.maximum

  end

  return value

end


--==============================================================================

-- default configurations for the APC20

--------------------------------------------------------------------------------


-- setup "Matrix + Navigator + Transport + Mixer",

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix + Navigator + Transport + Mixer",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "APC",
    display_name = "APC20",
    device_port_in = "APC20",
    device_port_out = "APC20",
    control_map = "Controllers/APC/APC20.xml",
    thumbnail = "APC20.bmp",
    protocol = DEVICE_MIDI_PROTOCOL,
  },

  applications = {
    Matrix = {
      mappings = {
        matrix = {
          group_name = "Slot",
        },
        triggers = {
          group_name = "Trigger",
        },
        sequence = {
          group_name = "Activator",
          index = 7,
        },
        track = {
          group_name = "Activator",
          index = 5,
        }
      }
    },
    Transport = {
      mappings = {
        start_playback = {
          group_name = "Transport",
          index = 1,
        },
        stop_playback = {
          group_name = "Transport",
          index = 2,
        },
        edit_mode = {
          group_name = "Transport",
          index = 3,
        },
        loop_pattern = {
          group_name = "Transport",
          index = 4,
        },
        follow_player = {
          group_name = "Transport",
          index = 5,
        },
        block_loop = {
          group_name = "Transport",
          index = 6,
        },
        goto_previous = {
          group_name = "Transport",
          index = 7,
        },
        goto_next = {
          group_name = "Transport",
          index = 8,
        },
      }
    },
    Mixer = {
      mappings = {
        levels = {
          group_name = "Track Fader",
        },
        mode = {
          group_name = "Note Mode",
          index = 1,
        },
        mute = {
          group_name = "Mute",
        },
        solo = {
          group_name = "Solo",
        },
        master = {
          group_name = "Master Fader",
        },
        page = {
          group_name = "Activator",
          index = 5,
        },
      },
      options = {
        invert_mute = 1,
      }
    },
    Navigator = {
      mappings = {
        blockpos = {
          group_name = "Navigator",
          orientation = HORIZONTAL,
        },
      }
    },
  }
}

--------------------------------------------------------------------------------
