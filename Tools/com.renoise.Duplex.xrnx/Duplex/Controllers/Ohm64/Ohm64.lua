--[[----------------------------------------------------------------------------
-- Duplex.Ohm64 
----------------------------------------------------------------------------]]--

--[[

Inheritance: Ohm64 > MidiDevice > Device

A device-specific class 

--]]


--==============================================================================

class "Ohm64" (MidiDevice)

function Ohm64:__init(display_name, message_stream, port_in, port_out)
  TRACE("Ohm64:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- setup a monochrome colorspace for the OHM
  self.colorspace = {1,1,1}
end

--------------------------------------------------------------------------------

function Ohm64:point_to_value(pt,elm,ceiling)

  local ceiling = ceiling or 127
  local value
  
  if (type(pt.val) == "boolean") then
    -- buttons
    local color = self:quantize_color(pt.color)
    value = (color[1]==0xff) and elm.maximum or elm.minimum
  else
    -- dials/faders
    value = math.floor((pt.val * (1 / ceiling)) * elm.maximum)
  end

  return value
end


