--[[----------------------------------------------------------------------------
-- Duplex.Device
----------------------------------------------------------------------------]]--

--[[
Requires: ControlMap

A generic device class (OSC or MIDI based)
+ Specify the message stream for user-generated events
+ Listen for incoming messages from the device

--]]


--==============================================================================

class 'Device'

function Device:__init(name, message_stream, protocol)
  TRACE('Device:__init')

  assert(name and message_stream and protocol, 
    "expected a valid name sream and protocol for a device")

  self.name = name
  self.message_stream = message_stream
  self.protocol = protocol
  
  self.control_map = ControlMap()

  -- default palette is provided by the display
  self.palette = {}    
end


--------------------------------------------------------------------------------

function Device:get_protocol()
  return self.protocol
end


--------------------------------------------------------------------------------

function Device:set_control_map(xml_file)
  TRACE("Device:set_control_map:",xml_file)
  self.control_map.load_definition(self.control_map,xml_file)
end


--------------------------------------------------------------------------------

-- Converts the point to an output value
-- (override with device-specific implementation)

function Device:point_to_value()
  return 0
end


--------------------------------------------------------------------------------

function Device:__tostring()
  return type(self)
end  

