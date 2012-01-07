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

  -- ## NRPN
  self.nrpn_message = NRPNMessage()
  self.buffer99 = nil
  self.buffer98 = nil
  self.nrpn_step = 3
  self.nrpn_timestamp = os.clock()
  -- -- NRPN
  
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
    if(message[1]>143)then -- on
      msg.channel = message[1]-143  
      msg.value = message[3]
      if (msg.value==0) then -- off
        msg.is_note_off = true      
      end
    else  -- off
      msg.channel = message[1]-127 
      msg.is_note_off = true
    end
    value_str = self._note_to_string(self,message[2])
  elseif (message[1]>=176) and (message[1]<=191) then
    msg.context = MIDI_CC_MESSAGE
    msg.value = message[3]
    msg.channel = message[1]-175
    value_str = self._midi_cc_to_string(self,message[2])
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
  
    if not duplex_preferences.nrpn_support then

      if (param) then
        self:_send_message(msg,param["xarg"])
      end

    else

      -- ## NRPN

      local pace = 1

      -- if NRPN message, write to buffer and handle when complete.
      if (string.sub(value_str,4,5) == "99") then
        -- CC#99 is either the parameter-MSB or a finetuning value.
        -- we'll buffer it, so we can use this later when there is an unambigous NRPN-message
        self.buffer99 = msg.value
        if (self.nrpn_message.msb) then --assume this must be the fine1 value then
          self.nrpn_message.fine1 = msg.value
        end
      elseif (string.sub(value_str,4,5) == "98") then
        -- CC#98 is either the parameter-LSB or another finetuning value.
        self.buffer98 = msg.value
        if (self.nrpn_message.lsb) then --assume this must be the fine2 value then, which means that the NRPN message is complete
          self.nrpn_message.fine2 = msg.value
          -- NRPN message (should be) completely received. Now, make a pseudo-CC-message out of it
          value_str = string.format("CC#%s|Ch%i",self.nrpn_message.msb,self.nrpn_message.channel)
          param = self.control_map:get_param_by_value(value_str)
          if (param and self.nrpn_message.is_valid) then
            TRACE('MidiDevice: NRPN complete. value_str=',value_str,', param=',param)
            TRACE('MidiDevice: ',self.nrpn_message)
            msg.context = self.nrpn_message.context
            local track = renoise.song().tracks[renoise.song().selected_track_index]
            local device = track.devices[renoise.song().selected_device_index]
            local parameter = device.parameters[param["xarg"].index]
            local quantum = (parameter.value_max - parameter.value_min)/127
            local value_norm = parameter.value - parameter.value_min --if value_min is negative, transpose value into positive range
            local value_midi = math.floor( value_norm / quantum )
            if (value_norm/quantum-value_midi >= 0.5) then value_midi = value_midi + 1 end --round to nearest integer

            --print('parameter.name = ',parameter.name)
            --print('parameter.value = ',parameter.value)
            --print('parameter.value_quantum = ',parameter.value_quantum)
            --print('parameter.value_min = ',parameter.value_min)
            --print('parameter.value_max = ',parameter.value_max)
            --print('            quantum = ',quantum)
            --print('         value_norm = ',value_norm)
            --print('         value_midi = ',value_midi)
            msg.value = value_midi

            -- try to detect fast changes and apply configurable pace 
            local currtime = os.clock()
            TRACE("MidiDevice: NRPN 'pace' = " .. 1000*(currtime - self.nrpn_timestamp) .. " (" .. currtime .. " - " .. self.nrpn_timestamp .. ")")
            pace = currtime - self.nrpn_timestamp
            self.nrpn_timestamp = currtime

            -- if messages arrive faster than 20/s, speed up
            if( pace < 0.03 ) then pace = self.nrpn_message.lsb else pace = 1 end
            if( pace > 32 )   then pace = 3 end  --avoid misconfiguration by applying a mild default
            msg.channel = self.nrpn_message.channel
            
          elseif( not self.nrpn_message.is_valid() ) then
            -- something ran out of sync. Clean up.
            TRACE("MidiDevice: NRPN message is incomplete. Ignoring.")
            self.nrpn_message = NRPNMessage()
          end
        end
      elseif (string.sub(value_str,4,5) == "96") then
        -- CC#96 = NRPN-Increment
        self.nrpn_message = NRPNMessage()
        self.nrpn_message.msb = self.buffer99
        self.nrpn_message.lsb = self.buffer98
        self.nrpn_message.channel = msg.channel
        self.nrpn_message.increment = true
        self.nrpn_message.decrement = false
      elseif (string.sub(value_str,4,5) == "97") then
        -- CC#97 = NRPN-Decrement
        self.nrpn_message = NRPNMessage()
        self.nrpn_message.msb = self.buffer99
        self.nrpn_message.lsb = self.buffer98
        self.nrpn_message.channel = msg.channel
        self.nrpn_message.increment = false
        self.nrpn_message.decrement = true
      elseif (string.sub(value_str,4,5) == "6") then
        -- CC#6 = NRPN-SetValue
        self.nrpn_message = NRPNMessage()
        self.nrpn_message.msb = self.buffer99
        self.nrpn_message.lsb = self.buffer98
        self.nrpn_message.channel = msg.channel
        self.nrpn_message.increment = false
        self.nrpn_message.decrement = false
        self.nrpn_message.value = msg.value
      end

      if (param) then
        for i=1, pace, 1 do
          if( self.nrpn_message.increment ) then msg.value = math.min(127, msg.value+1) end
          if( self.nrpn_message.decrement ) then msg.value = math.max(0,   msg.value-1) end
        self:_send_message(msg,param["xarg"])
      end
        -- as we have parsed the NRPNMessage (if there was one), we can reset it.
        self.nrpn_message = NRPNMessage()
      end

      -- -- NRPN

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

  -- ## NRPN
  if duplex_preferences.nrpn_support then
    -- hack to stop NRPN messages from being forwarded
    if (type(number) ~= "number") then 
      return 
    end
  end
  -- -- NRPN

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

--  send sysex message
--  the method will take care of adding the initial 0xF0 and 0xF7 values
--  @param ... (vararg) values to send, e.g. 0x47, 0x7F, 0x7B,...

function MidiDevice:send_sysex_message(...)
  TRACE("MidiDevice:send_sysex_message(...)")

  if (not self.midi_out or not self.midi_out.is_open) then
    return
  end

  local message = table.create()
  local message_str = "0xF0"

  message:insert(0xF0)
  for _, e in ipairs({...}) do
    message:insert(e)
    message_str = string.format("%s,0x%02X",message_str,e)
  end
  message:insert(0xF7)
  message_str = string.format("%s,0x%02X",message_str,0xF7)

  if(self.dump_midi)then
    print(("MidiDevice: %s send MIDI %s"):format(
      self.port_out, message_str))
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

function MidiDevice:_note_to_string(int)
  local key = (int%12)+1
  local oct = math.floor(int/12)-1
  return NOTE_ARRAY[key]..(oct)
end


--------------------------------------------------------------------------------

function MidiDevice:_midi_cc_to_string(int)
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
  return tonumber(string.sub(str,4))
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
-- @param pt (CanvasPoint)
-- @param elm - control-map parameter
-- @param ceiling - the UIComponent ceiling value

function MidiDevice:point_to_value(pt,elm,ceiling)
  TRACE("MidiDevice:point_to_value()",pt,elm,ceiling)

  local ceiling = ceiling or 127
  local value
  
  if (type(pt.val) == "boolean") then
    if (pt.val) then
      value = tonumber(elm.maximum)
    else
      value = tonumber(elm.minimum)
    end

  else
    -- scale the value from "local" to "external"
    -- for instance, from Renoise dB range (1.4125375747681) 
    -- to a 7-bit controller value (127)
    value = math.floor((pt.val * (1 / ceiling)) * elm.maximum)
  end

  return tonumber(value)
end


-- ## NRPN
--==============================================================================

--[[
  NRPN Message class, that adds certain properties and helper functions.
--]]

class 'NRPNMessage' (Message)

function NRPNMessage:__init(device)
  TRACE('NRPNMessage:__init')

  self.msb = nil
  self.lsb = nil
  self.increment = nil
  self.decrement = nil
  self.fine1 = nil
  self.fine2 = nil

  Message:__init(device)
  
  self.context = MIDI_CC_MESSAGE
end

function NRPNMessage:__tostring()
  return string.format("NRPNmessage: [%s|%s|%s|%s|%s|%s|%s] context:%s, group_name:%s",
    tostring(self.msb), tostring(self.lsb), tostring(self.value), tostring(self.increment), tostring(self.decrement), tostring(self.fine1), tostring(self.fine2), tostring(self.context), tostring(self.group_name))
end

function NRPNMessage:is_valid()
  return (self ~= nil and self.msb ~= nil and self.lsb ~= nil and self.fine1 ~= nil and self.fine2 ~= nil)
end
-- -- NRPN

