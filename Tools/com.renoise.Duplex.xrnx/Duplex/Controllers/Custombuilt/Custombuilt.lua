--[[----------------------------------------------------------------------------
-- Duplex.Custombuilt
----------------------------------------------------------------------------]]--

--[[

Various custom 'devices' for demonstration purposes

--]]

--==============================================================================

class "Custombuilt" (MidiDevice)

function Custombuilt:__init(...)
  TRACE("Custombuilt:__init", ...)

  MidiDevice.__init(self, ...)

  -- this device has a color-space with 16 degrees of RGB
  self.colorspace = {16, 16, 16}

end
