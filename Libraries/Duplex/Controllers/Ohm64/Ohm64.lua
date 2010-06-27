--[[----------------------------------------------------------------------------
-- Duplex.Ohm64 
----------------------------------------------------------------------------]]--

--[[

Inheritance: Ohm64 > MIDIDevice > Device

A device-specific class 

--]]


--==============================================================================

class "Ohm64" (MIDIDevice)

function Ohm64:__init(name, message_stream)
  TRACE("Ohm64:__init", name, message_stream)

  MIDIDevice.__init(self, name, message_stream)

  -- double-buffering features (not used)
  --[[
  self.display = 0
  self.update = 0
  self.flash = 0
  self.copy = 0
  ]]
end


--------------------------------------------------------------------------------

function Ohm64:point_to_value(pt, maximum, minimum, ceiling)
  TRACE("Ohm64:point_to_value")

  return MIDIDevice.point_to_value(self, pt, maximum, minimum, ceiling)
end

