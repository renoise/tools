--[[----------------------------------------------------------------------------
-- Duplex.MidiDevice
----------------------------------------------------------------------------]]--

--[[

Inheritance: MidiDevice -> Device

Requires: Globals, ControlMap, Message

--]]


--==============================================================================

class 'MidiDevice' (Device)

function MidiDevice:__init(display_name, port_name, message_stream)
  TRACE("MidiDevice:__init()",display_name, port_name, message_stream)

  assert(display_name and port_name and message_stream, 
    "Internal Error. Please report: " ..
    "expected a valid port-name, display-name and stream for a device")

  Device.__init(self, display_name, message_stream, DEVICE_MIDI_PROTOCOL)

  self.port_name = port_name

  self.midi_in = nil
  self.midi_out = nil

  -- todo: update all MIDI devices when this setting change
  self.dump_midi = false

  self:open()

end


--------------------------------------------------------------------------------

function MidiDevice:open()

  local input_devices = renoise.Midi.available_input_devices()
  local output_devices = renoise.Midi.available_output_devices()

  if table.find(input_devices, self.port_name) then
    self.midi_in = renoise.Midi.create_input_device(self.port_name,
      {self, MidiDevice.midi_callback},
      {self, MidiDevice.sysex_callback}
    )
  else
    print("Notice: Could not create MIDI input device "..self.port_name)
  end

  if table.find(output_devices, self.port_name) then
    self.midi_out = renoise.Midi.create_output_device(self.port_name)
  else
    print("Notice: Could not create MIDI output device "..self.port_name)
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

function MidiDevice:midi_callback(message)
  TRACE(("MidiDevice: %s received MIDI %X %X %X"):format(
    self.port_name, message[1], message[2], message[3]))

  local msg = Message()

  local value_str = nil

  if (self.dump_midi) then
    print(("MidiDevice: %s received MIDI %X %X %X"):format(
    self.port_name, message[1], message[2], message[3]))
  end

  -- determine the type of signal : note/cc/etc
  if (message[1] == 144) then
    msg.context = MIDI_NOTE_MESSAGE
    msg.value = message[3]
    value_str = self.note_to_string(self,message[2])
  
  elseif (message[1] == 176) then
    msg.context = MIDI_CC_MESSAGE
    msg.value = message[3]
    value_str = self.midi_cc_to_string(self,message[2])

  elseif (message[1] == 224) then
    msg.context = MIDI_PITCH_BEND_MESSAGE
    msg.value = message[3]
    value_str = "PB"
  end

  if (value_str) then
    -- locate the relevant parameter in the control-map
    local param = self.control_map:get_param_by_value(value_str)
  
    if (param) then
      local xarg = param["xarg"]
      
      -- determine input method
      if (xarg.type == "button") then
        msg.input_method = CONTROLLER_BUTTON
      elseif (xarg.type == "togglebutton") then
        msg.input_method = CONTROLLER_TOGGLEBUTTON
      elseif (xarg.type == "fader") then
        msg.input_method = CONTROLLER_FADER
      elseif (xarg.type == "dial") then
        msg.input_method = CONTROLLER_DIAL
      else
        error(("Internal Error. Please report: " ..
          "unknown msg.input_method %s"):format(xarg.type or "nil"))
      end

      -- include meta-properties
      msg.name = xarg.name
      msg.group_name = xarg.group_name
      msg.max = tonumber(xarg.maximum)
      msg.min = tonumber(xarg.minimum)
      msg.id = xarg.id
      msg.index = xarg.index
      msg.column = xarg.column
      msg.row = xarg.row
      msg.timestamp = os.clock()
  
      -- send the message
      self.message_stream:input_message(msg)
     
      -- immediately update the display after having received a message
      -- to improve response of the display
      if (self.display) then
        self.display:update()
      end
    end
  end
end


--------------------------------------------------------------------------------

function MidiDevice:sysex_callback(message)
  TRACE(("MidiDevice: %s got SYSEX with %d bytes"):format(
    self.port_name, #message))
end


--------------------------------------------------------------------------------

--  send CC message
--  @param number (int) the control-number (0-127)
--  @param value (int) the control-value (0-127)

function MidiDevice:send_cc_message(number,value)

  if (not self.midi_out or not self.midi_out.is_open) then
    return
  end

  local message = {0xB0, number, value}

  TRACE(("MidiDevice: %s send MIDI %X %X %X"):format(
    self.port_name, message[1], message[2], message[3]))

  if(self.dump_midi)then
    print(("MidiDevice: %s send MIDI %X %X %X"):format(
      self.port_name, message[1], message[2], message[3]))
  end


  self.midi_out:send(message)
end


--------------------------------------------------------------------------------

function MidiDevice:send_note_message(key,velocity)

  if (not self.midi_out or not self.midi_out.is_open) then
    return
  end

  key = math.floor(key)
  velocity = math.floor(velocity)
  
  local message = {nil, key, velocity}
  
  if (velocity == 0) then
    message[1] = 0x80 -- note off
  else
    message[1] = 0x90 -- note-on
  end
  
  TRACE(("MidiDevice: %s send MIDI %X %X %X"):format(
    self.port_name, message[1], message[2], message[3]))
    
  if(self.dump_midi)then
    print(("MidiDevice: %s send MIDI %X %X %X"):format(
      self.port_name, message[1], message[2], message[3]))
  end

  self.midi_out:send(message) 
end


--------------------------------------------------------------------------------

-- convert MIDI note to string, range 0 (C--1) to 120 (C-9)
-- @param key: the key (7-bit integer)
-- @return string (e.g. "C#5")

function MidiDevice:note_to_string(int)
  local key = (int%12)+1
  local oct = math.floor(int/12)-1
  return NOTE_ARRAY[key]..(oct)
end


--------------------------------------------------------------------------------

function MidiDevice:midi_cc_to_string(int)
  return string.format("CC#%d",int)
end


--------------------------------------------------------------------------------

-- Extract MIDI message note-value (range C--1 to C9)
-- @param str  - string, e.g. "C-4" or "F#-1"
-- @return #note (7-bit integer)

function MidiDevice:extract_midi_note(str) 
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
-- @return #cc (integer) 

function MidiDevice:extract_midi_cc(str)
  return tonumber(string.sub(str, 4))
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


