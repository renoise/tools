--[[----------------------------------------------------------------------------
-- Duplex.APC40
----------------------------------------------------------------------------]]--

--[[

Inheritance: APC40 > MidiDevice > Device

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

--- override default Device method
-- @see Device.output_boolean

function APC40:output_boolean(pt,xarg,ui_obj)

  local value = nil

  local color = self:quantize_color(pt.color)
  -- use the local colorspace if it's available
  local colorspace = xarg.colorspace or self.colorspace
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
    value = (pt.val == true) and xarg.maximum or xarg.minimum
  end

  return value

end

