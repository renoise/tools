--[[----------------------------------------------------------------------------
-- Duplex.APC20
----------------------------------------------------------------------------]]--

--[[

Inheritance: APC20 > MidiDevice > Device

A device-specific class, valid for Akai APC20 models

--]]


--==============================================================================

class "APC20" (MidiDevice)

function APC20:__init(display_name, message_stream, port_in, port_out)
  TRACE("APC20:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- set device to "mode 1"
  self:send_sysex_message(0x47,0x7F,0x7B,0x60,0x00,0x04,0x41,0x08,0x02,0x01)

  -- define a default colorspace
  self.colorspace = {1, 1, 1}

end

--------------------------------------------------------------------------------

function APC20:point_to_value(pt,elm,ceiling)
  TRACE("APC20:point_to_value()",pt,elm,ceiling)

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



