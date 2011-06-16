--[[----------------------------------------------------------------------------
-- Duplex.APC40
----------------------------------------------------------------------------]]--

--[[

Inheritance: APC > MidiDevice > Device

A device-specific class, valid for Akai APC40 models

--]]


--==============================================================================

class "APC40" (MidiDevice)

function APC40:__init(display_name, message_stream, port_in, port_out)
  TRACE("APC40:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- set device to "mode 1"
  self:send_sysex_message(0x47,0x7F,0x73,0x60,0x00,0x04,0x41,0x08,0x02,0x01)

  -- define a default colorspace
  self.colorspace = {1, 1, 1}

end

--------------------------------------------------------------------------------

function APC40:point_to_value(pt,elm,ceiling)
  TRACE("APC40:point_to_value()",pt,elm,ceiling)

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

-- default configurations for the APC40

--------------------------------------------------------------------------------


-- setup "Matrix + Navigator + Transport + Mixer",

duplex_configurations:insert {

  -- configuration properties
  name = "Matrix + Navigator + Transport + Mixer",
  pinned = true,
  
  -- device properties
  device = {
    class_name = "APC40",
    display_name = "APC40",
    device_port_in = "APC40",
    device_port_out = "APC40",
    control_map = "Controllers/APC40/APC40.xml",
    thumbnail = "APC40.bmp",
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
          group_name = "Move",
          index = 3,
        },
        track = {
          group_name = "Move",
          index = 1,
        }
      }
    },
    TrackSelector = {
      mappings = {
        prev_next_page = {
          group_name = "Move",
          index = 1,
        },
        select_track = {
          group_name = "Track Selector",
          index = 1,
        },
      },
    },
    Transport = {
      mappings = {
        stop_playback = {
          group_name = "Transport",
          index = 2,
        },
        start_playback = {
          group_name = "Transport",
          index = 1,
        },
        edit_mode = {
          group_name = "Transport",
          index = 3,
        },
        goto_previous = {
          group_name = "Control",
          index = 5,
        },
        goto_next = {
          group_name = "Control",
          index = 6,
        },
        follow_player = {
          group_name = "Control",
          index = 7,
        },
        block_loop = {
          group_name = "Block Loop",
          index = 1,
        },
      }
    },
    Mixer = {
      mappings = {
        levels = {
          group_name = "Track Fader",
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
          group_name = "Move",
          index = 1,
        },
        panning = {
          group_name = "Panning Knob",
        },
        mode = {
          group_name = "Note Mode",
        },
      },
      options = {
        invert_mute = 1
      }
    },
    Effect = {
      mappings = {
        parameters = {
          group_name = "Device Knob",
        },
        page = {
          group_name = "Control",
          index = 3,
        },
        device = {
          group_name = "Device Selector",
        },
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
