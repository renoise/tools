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

-- Include these configurations for TouchOSC

local CTRL_PATH = "Duplex/Controllers/TouchOSC/Configurations/"
require (CTRL_PATH.."MixerRecorderMatrix")

