--[[----------------------------------------------------------------------------
-- Duplex.ZoomR16
----------------------------------------------------------------------------]]--

--[[

Inheritance: ZoomR16 > MidiDevice > Device

A device-specific class 

--]]


--==============================================================================

class "ZoomR16" (MidiDevice)

function ZoomR16:__init(display_name, message_stream, port_in, port_out)
  TRACE("ZoomR16:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- setup a monochrome colorspace for the Zoom
  self.colorspace = {1,1,1}
end


--==============================================================================

-- Include these configurations for the ZoomR16

local CTRL_PATH = "Duplex/Controllers/ZoomR16/Configurations/"
require (CTRL_PATH.."Transport")

