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
  TRACE('Device:__init',name, message_stream, protocol)

  assert(name and message_stream and protocol, 
    "expected a valid name, stream and protocol for a device")

  -- for MIDI devices, name is equal to the port name 
  self.name = name

  -- default palette is provided by the display
  self.palette = {}   

  -- specify a color-space like this: (r, g, b) or empty
  -- example#1 : {4,4,0} - four degrees of red and grees
  -- example#2 : {0,0,1} - monochrome display (blue)
  -- example#2 : {} - no colors, display as text
  self.colorspace = {}
  
  -- MIDI or OSC?
  self.protocol = protocol

  -- transmit messages through this stream
  self.message_stream = message_stream
  
  -- allow midi loopback of messages to the real device
  self.loopback_received_messages = false

  -- init control-map
  self.control_map = ControlMap()

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


--------------------------------------------------------------------------------

function Device:open_settings_dialog()
  if not self.settings_dialog then
    self.settings_dialog = DeviceSettings(self)
  end

  self.settings_dialog.show()

end  


--==============================================================================
--[[

Show dialog with configuration options 
+ Show device name + type (generic or custom)
+ (MidiDevice) choose port
+ (MidiDevice) choose channel


--]]

class "DeviceSettings"

function DeviceSettings:__init(device)
  
  

end  

