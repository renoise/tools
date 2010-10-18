--[[----------------------------------------------------------------------------
-- Duplex.MidiDevice
----------------------------------------------------------------------------]]--

--[[

Inheritance: MidiDevice -> Device

Requires: Globals, ControlMap, Message

--]]


--==============================================================================

class 'MidiDevice' (Device)

function MidiDevice:__init(display_name, message_stream, port_in, port_out)
  TRACE("MidiDevice:__init()",display_name, message_stream, port_in, port_out)

  assert(display_name and display_name and message_stream and port_in and port_out, 
    "Internal Error. Please report: " ..
    "expected a valid display-name, stream and in/output device names for a MIDI device")

  Device.__init(self, display_name, message_stream, DEVICE_MIDI_PROTOCOL)

  self.port_in = port_in
  self.port_out = port_out

  self.midi_in = nil
  self.midi_out = nil

  -- todo: update all MIDI devices when this setting change
  self.dump_midi = false

  -- when using the virtual control surface, and the control-map
  -- doesn't specify a specific channel, use this value: 
  self.default_midi_channel = 1

  self:open()

end


--------------------------------------------------------------------------------

function MidiDevice:open()

  local input_devices = renoise.Midi.available_input_devices()
  local output_devices = renoise.Midi.available_output_devices()

  if table.find(input_devices, self.port_in) then
    self.midi_in = renoise.Midi.create_input_device(self.port_in,
      {self, MidiDevice.midi_callback},
      {self, MidiDevice.sysex_callback}
    )
  else
    print("Notice: Could not create MIDI input device ", self.port_in)
  end

  if table.find(output_devices, self.port_out) then
    self.midi_out = renoise.Midi.create_output_device(self.port_out)
  else
    print("Notice: Could not create MIDI output device ", self.port_out)
  end

end

--------------------------------------------------------------------------------

function MidiDevice:release()
  TRACE("MidiDevice:release()")

  if (self.midi_in and self.midi_in.is_open) then
    self.midi_in:close()
  end
  
  if (self.midi_out and self.midi_out.is_open) then
    self.midi_out:close()
  end

  self.midi_in = nil
  self.midi_out = nil
end


--------------------------------------------------------------------------------

-- receive MIDI from device
-- construct a string identical to the <Param> value attribute
-- and use this to locate the parameter in the control-map

function MidiDevice:midi_callback(message)
  TRACE(("MidiDevice: %s received MIDI %X %X %X"):format(
    self.port_in, message[1], message[2], message[3]))

  local msg = Message()

  local value_str = nil

  if (self.dump_midi) then
    print(("MidiDevice: %s received MIDI %X %X %X"):format(
      self.port_in, message[1], message[2], message[3]))
  end

  -- determine the type of signal : note/cc/etc
  if (message[1]>=128) and (message[1]<=159) then
    msg.context = MIDI_NOTE_MESSAGE
    msg.value = message[3]
    if(message[1]>143)then
      msg.channel = message[1]-143  -- on
    else
      msg.channel = message[1]-127  -- off
    end
    value_str = self.__note_to_string(self,message[2])
  elseif (message[1]>=176) and (message[1]<=191) then
    msg.context = MIDI_CC_MESSAGE
    msg.value = message[3]
    msg.channel = message[1]-175
    value_str = self.__midi_cc_to_string(self,message[2])
  elseif (message[1]>=224) and (message[1]<=239) then
    msg.context = MIDI_PITCH_BEND_MESSAGE
    msg.value = message[3]
    msg.channel = message[1]-223
    value_str = "PB"
  else
    -- ignore unsupported type...
  end


  if (value_str) then

    value_str = string.format("%s|Ch%i",value_str,msg.channel)
    local param = self.control_map:get_param_by_value(value_str)
  
    if (param) then
      self:__send_message(msg,param["xarg"])
    end
  end
end


--------------------------------------------------------------------------------

function MidiDevice:sysex_callback(message)
  TRACE(("MidiDevice: %s got SYSEX with %d bytes"):format(
    self.port_in, #message))
end


--------------------------------------------------------------------------------

--  send CC message
--  @param number (int) the control-number (0-127)
--  @param value (int) the control-value (0-127)
--  @param channel (int, optional) the midi channel (1-16)

function MidiDevice:send_cc_message(number,value,channel)
  TRACE("MidiDevice:send_cc_message()",number,value,channel)

  if (not self.midi_out or not self.midi_out.is_open) then
    return
  end

  if not channel then
    channel = self.default_midi_channel
  end

  local message = {0xAF+channel, math.floor(number), math.floor(value)}

  TRACE(("MidiDevice: %s send MIDI %X %X %X"):format(
    self.port_out, message[1], message[2], message[3]))

  if(self.dump_midi)then
    print(("MidiDevice: %s send MIDI %X %X %X"):format(
      self.port_out, message[1], message[2], message[3]))
  end


  self.midi_out:send(message)
end


--------------------------------------------------------------------------------

function MidiDevice:send_note_message(key,velocity,channel)

  if (not self.midi_out or not self.midi_out.is_open) then
    return
  end

  key = math.floor(key)
  velocity = math.floor(velocity)
  
  local message = {nil, key, velocity}
  
  if not channel then
    channel = self.default_midi_channel
  end

  if (velocity == 0) then
    message[1] = 0x7F+channel -- note off
  else
    message[1] = 0x8F+channel -- note-on
  end
  
  TRACE(("MidiDevice: %s send MIDI %X %X %X"):format(
    self.port_out, message[1], message[2], message[3]))
    
  if(self.dump_midi)then
    print(("MidiDevice: %s send MIDI %X %X %X"):format(
      self.port_out, message[1], message[2], message[3]))
  end

  self.midi_out:send(message) 
end


--------------------------------------------------------------------------------

-- convert MIDI note to string, range 0 (C--1) to 120 (C-9)
-- @param key: the key (7-bit integer)
-- @return string (e.g. "C#5")

function MidiDevice:__note_to_string(int)
  local key = (int%12)+1
  local oct = math.floor(int/12)-1
  return NOTE_ARRAY[key]..(oct)
end


--------------------------------------------------------------------------------

function MidiDevice:__midi_cc_to_string(int)
  return string.format("CC#%d",int)
end


--------------------------------------------------------------------------------

-- Extract MIDI message note-value (range C--1 to C9)
-- @param str  - string, e.g. "C-4" or "F#-1"
-- @return #note (7-bit integer)

function MidiDevice:extract_midi_note(str) 
  TRACE("MidiDevice:extract_midi_note()",str)

  str = strip_channel_info(str)
  local rslt = nil
  local note_segment = string.sub(str,0,2)
  local octave_segment = string.sub(str,3)
  for k,v in ipairs(NOTE_ARRAY) do 
    if (NOTE_ARRAY[k] == note_segment) then 
      if (octave_segment == "-1") then
        rslt=(k-1)
      else
        rslt=(k-1)+(12*octave_segment)+12
      end
    end
  end
  return rslt
end


--------------------------------------------------------------------------------

-- Extract MIDI CC number (range 0-127)
-- @param str (string, control-map value attribute)
-- @return #cc (integer) 

function MidiDevice:extract_midi_cc(str)
  TRACE("MidiDevice:extract_midi_cc()",str)

  str = strip_channel_info(str)
  return string.sub(str,4)
end

--------------------------------------------------------------------------------


-- Determine channel for the given message
-- Use the default port if nothing is explicitly set
-- @param str (string, control-map value)
-- @return integer (1-16)

function MidiDevice:extract_midi_channel(str)
  TRACE("MidiDevice:extract_midi_channel()",str)

  return string.match(str, "|Ch([0-9]+)")
end


--------------------------------------------------------------------------------

-- Convert the point to an output value
-- (override with device-specific implementation)
-- @param pt (CanvasPoint)
-- @param maximum - attribute from control-map
-- @param minimum - -#-
-- @param ceiling - the UIComponent ceiling value

function MidiDevice:point_to_value(pt,maximum,minimum,ceiling)
  TRACE("MidiDevice:point_to_value()",pt,maximum,minimum,ceiling)

  local ceiling = ceiling or 127
  local value
  
  if (type(pt.val) == "boolean") then
    if (pt.val) then
      value = maximum
    else
      value = minimum
    end

  else
    -- scale the value from "local" to "external"
    -- for instance, from Renoise dB range (1.4125375747681) 
    -- to a 7-bit controller value (127)
    value = math.floor((pt.val * (1 / ceiling)) * maximum)
  end

  return tonumber(value)
end


