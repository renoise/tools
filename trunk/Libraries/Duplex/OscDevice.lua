--[[----------------------------------------------------------------------------
-- Duplex.OscDevice
----------------------------------------------------------------------------]]--

--[[

Inheritance: OscDevice -> Device

Requires: Globals

--]]


--==============================================================================

class 'OscDevice' (Device)

function OscDevice:__init(name)
  print("OscDevice:__init("..name..")")
  
  Device.__init(self, name, DEVICE_OSC_PROTOCOL)
end


--------------------------------------------------------------------------------

function OscDevice:release()
  print("OscDevice:release()")
end


