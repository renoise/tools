--[[----------------------------------------------------------------------------
-- Duplex.Device
----------------------------------------------------------------------------]]--

--[[
Requires: ControlMap

About

The Device class is the base class for any device. Both the MIDIDevice and 
OSCDevice extend this class, just as the Launchpad is based on the MIDIDevice.


--]]


--==============================================================================

class 'Device'

function Device:__init(name, message_stream, protocol)
  TRACE('Device:__init',name, message_stream, protocol)

  ---- initialzation
  
  assert(name and message_stream and protocol, 
    "Internal Error. Please report: " ..
    "expected a valid name, stream and protocol for a device")

  -- for MIDI devices, name is equal to the port name 
  self.name = name
  -- MIDI or OSC?
  self.protocol = protocol  
  -- transmit messages through this stream
  self.message_stream = message_stream

  -- create our control-map
  self.control_map = ControlMap()
  
  
  ---- configuration
  
  -- default palette is provided by the display
  self.palette = {}   

  -- specify a color-space like this: (r, g, b) or empty
  -- example#1 : {4,4,0} - four degrees of red and grees
  -- example#2 : {1,1,1} - monochrome display (black/white)
  -- example#3 : {0,0,1} - monochrome display (blue)
  -- example#4 : {} - no colors, display as text
  self.colorspace = {}
  
  -- allow sending back the same messages we got from the device as answer 
  -- to the device. some controller which can deal with message feedback,
  -- may want to disable this in its device class...
  self.loopback_received_messages = true
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

