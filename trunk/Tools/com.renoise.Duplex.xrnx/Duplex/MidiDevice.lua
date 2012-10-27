--[[----------------------------------------------------------------------------
-- Duplex.MidiDevice
----------------------------------------------------------------------------]]--

--[[

Inheritance: MidiDevice -> Device

Requires: Globals, ControlMap, Message

--]]


--==============================================================================

class 'MidiDevice' (Device)

--------------------------------------------------------------------------------

--- Initialize MidiDevice class
-- @param display_name (String) the friendly name of the device
-- @param message_stream (MessageStream) the msg-stream we should attach to
-- @param port_in (String) the MIDI input port 
-- @param port_out (String) the MIDI output port 

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

  -- boolean, specifies if the device dumps midi to the console
  self.dump_midi = false

  -- when using the virtual control surface, and the control-map
  -- doesn't specify a specific channel, we use this value: 
  self.default_midi_channel = 1

  -- number, used for quantized output and relative step size
  self.default_midi_resolution = 127

  -- enable this to quantize output to given resolution before
  -- actually sending it to the MIDI controller (less traffic)
  self.output_quantize = true

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

--- Attempt to open the device MIDI ports

function MidiDevice:open()

  local input_devices = renoise.Midi.available_input_devices()
  local output_devices = renoise.Midi.available_output_devices()

  if table.find(input_devices, self.port_in) then
    self.midi_in = renoise.Midi.create_input_device(self.port_in,
      {self, MidiDevice.midi_callback},
      {self, MidiDevice.sysex_callback}
    )
  else
    LOG("Notice: Could not create MIDI input device ", self.port_in)
  end

  if table.find(output_devices, self.port_out) then
    self.midi_out = renoise.Midi.create_output_device(self.port_out)
  else
    LOG("Notice: Could not create MIDI output device ", self.port_out)
  end

end

--------------------------------------------------------------------------------

--- Attempt to release the device MIDI ports

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

--- Invoked when we receive MIDI from device, construct a string identical 
-- to the <Param> value attribute, which is then used to locate the parameter 
-- in the control-map
-- @param message (Table/MIDIMessage)

function MidiDevice:midi_callback(message)
  TRACE(("MidiDevice: %s received MIDI %X %X %X"):format(
    self.port_in, message[1], message[2], message[3]))


  local value_str = nil

  if (self.dump_midi) then
    LOG(("MidiDevice: %s received MIDI %X %X %X"):format(
      self.port_in, message[1], message[2], message[3]))
  end

  -- message attributes
  local msg_value,msg_context,msg_channel,msg_value,msg_is_note_off

  -- determine the type of signal : note/cc/etc
  if (message[1]>=128) and (message[1]<=159) then
    msg_context = MIDI_NOTE_MESSAGE
    if(message[1]>143)then -- on
      msg_channel = message[1]-143  
      msg_value = message[3]
      if (msg_value==0) then -- off
        msg_is_note_off = true      
      end
    else  -- off
      msg_channel = message[1]-127 
      msg_is_note_off = true
    end
    value_str = self._note_to_string(self,message[2])
  elseif (message[1]>=176) and (message[1]<=191) then
    msg_context = MIDI_CC_MESSAGE
    msg_value = message[3]
    msg_channel = message[1]-175
    value_str = self._midi_cc_to_string(self,message[2])
  elseif (message[1]>=208) and (message[1]<=223) then
    msg_context = MIDI_CHANNEL_PRESSURE
    msg_value = message[2]
    msg_channel = message[1]-207
    value_str = "CP"
  elseif (message[1]>=224) and (message[1]<=239) then
    msg_context = MIDI_PITCH_BEND_MESSAGE
    msg_value = message[3] -- todo: support LSB for higher resolution
    msg_channel = message[1]-223
    value_str = "PB"
    --print("MidiDevice: - msg_value",msg_value)
  else
    -- ignore unsupported/unhandled messages...
    -- possible data include timing clock, active sensing etc.
  end


  if (value_str) then

    --print("*** value_str",value_str,msg_context)

    -- add the channel info to the value
    value_str = string.format("%s|Ch%i",value_str,msg_channel)

    -- retrieve all matching parameters
    local params = self.control_map:get_params_by_value(value_str,msg_context)
    --print("#params",#params)

    -- remember the current value, reset on each loop
    -- (as send_message might change it)


    for k,v in ipairs(params) do

      -- deep-copy the parameter table, so we can modify   
      -- it's values without changing the original 
      local param = table.rcopy(v)
    
      -- create the message
      local msg = Message()
      msg.value = msg_value
      msg.midi_msg = message
      msg.context = msg_context
      msg.channel = msg_channel
      msg.value = msg_value
      msg.is_note_off = msg_is_note_off

      -- special case: if we have received input from a MIDI keyboard
      -- by means of the "keyboard" input method, stick the note back on
      if (msg.context == MIDI_NOTE_MESSAGE) and
        (param["xarg"].value=="|Ch"..msg_channel) or
        (param["xarg"].value=="|") 
      then
        param["xarg"].value = value_str
      end

      if (duplex_preferences.nrpn_support.value == false) then

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
            local params2 = self.control_map:get_params_by_value(value_str)
            param = table.rcopy(param2[1])
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

end


--------------------------------------------------------------------------------

--- Invoked when we receive sysex data from the device
-- @param message (Table/MIDIMessage)

function MidiDevice:sysex_callback(message)
  TRACE("MidiDevice:sysex_callback()",message)

  if(self.dump_midi)then
    LOG(("MidiDevice: %s got SYSEX with %d bytes"):format(
      self.port_in, #message))
  end
  
end


--------------------------------------------------------------------------------

---  Send CC message to device
--  @param number (Number/7BitInt) the control-number 
--  @param value (Number/7BitInt) the control-value
--  @param channel (Number) the midi channel, between 1-16

function MidiDevice:send_cc_message(number,value,channel)
  TRACE("MidiDevice:send_cc_message()",number,value,channel)

  if (not self.midi_out or not self.midi_out.is_open) then
    return
  end

  if not channel then
    channel = self.default_midi_channel
  end

  -- ## NRPN
  if (duplex_preferences.nrpn_support.value == true) then
    -- hack to stop NRPN messages from being forwarded
    if (type(number) ~= "number") then 
      return 
    end
  end
  -- -- NRPN

  local message = {0xAF+channel, math.floor(number), math.floor(value)}

  local dump_str = ("MidiDevice: %s send MIDI %X %X %X"):format(
      self.port_out, message[1], message[2], message[3])

  if(self.dump_midi)then
    LOG(dump_str)
  else
    TRACE(dump_str)
  end


  self.midi_out:send(message)
end


--------------------------------------------------------------------------------

---  Send sysex message to device (adding the initial 0xF0 and 0xF7 values)
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
    LOG(("MidiDevice: %s send MIDI %s"):format(
      self.port_out, message_str))
  end

  self.midi_out:send(message)
end

--------------------------------------------------------------------------------

--- Send Pitch-Bend message to device
-- @param value (Number) the pitch-bend value
-- @param channel (Number) the MIDI channel

function MidiDevice:send_pitch_bend_message(value,channel)
  TRACE("MidiDevice:send_pitch_bend_message()",value,channel)

  if (not self.midi_out or not self.midi_out.is_open) then
    return
  end
  if not channel then
    channel = self.default_midi_channel
  end

  local message = {223+channel, 0, value} -- todo: LSB for higher precision

  TRACE(("MidiDevice: %s send MIDI %X %X %X"):format(
    self.port_out, message[1], message[2], message[3]))
    
  if(self.dump_midi)then
    LOG(("MidiDevice: %s send MIDI %X %X %X"):format(
      self.port_out, message[1], message[2], message[3]))
  end

  self.midi_out:send(message) 

end

--------------------------------------------------------------------------------

--- Send note message to device
-- @param key (Number) the MIDI note pitch 
-- @param velocity (Number) the MIDI note velocity
-- @param channel (Number) the MIDI channel

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

  -- some devices cannot cope with note-off messages 
  -- being note-on messages with zero velocity...
  if (velocity == 0) and not (self.allow_zero_velocity_note_on) then
    message[1] = 0x7F+channel -- note off
  else
    message[1] = 0x8F+channel -- note-on
  end
  
  TRACE(("MidiDevice: %s send MIDI %X %X %X"):format(
    self.port_out, message[1], message[2], message[3]))
    
  if(self.dump_midi)then
    LOG(("MidiDevice: %s send MIDI %X %X %X"):format(
      self.port_out, message[1], message[2], message[3]))
  end

  self.midi_out:send(message) 
end


--------------------------------------------------------------------------------

--- Convert MIDI note to control-map string, range 0 (C--1) to 120 (C-9)
-- @param int (Number/7BitInt): the MIDI note key
-- @return String

function MidiDevice:_note_to_string(int)
  local key = (int%12)+1
  local oct = math.floor(int/12)-1
  return NOTE_ARRAY[key]..(oct)
end


--------------------------------------------------------------------------------

--- Convert MIDI CC value to string, e.g. "CC#%d"
-- @param int (Number/7BitInt) the CC number

function MidiDevice:_midi_cc_to_string(int)
  return string.format("CC#%d",int)
end


--------------------------------------------------------------------------------

--- Extract MIDI note-value (range C--1 to C9)
-- @param str (String), control-map value such as "C-4" or "F#-1"
-- @return (Number) the MIDI note pitch, 0-127

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
      elseif(octave_segment == "*") then
        rslt=(k-1)+12
      else
        rslt=(k-1)+(12*octave_segment)+12
      end
    end
  end
  return rslt
end


--------------------------------------------------------------------------------

--- Extract MIDI CC number (range 0-127)
-- @param str (string, control-map value attribute)
-- @return (Number) the MIDI CC number, 0-127

function MidiDevice:extract_midi_cc(str)
  TRACE("MidiDevice:extract_midi_cc()",str)

  str = strip_channel_info(str)
  return tonumber(string.sub(str,4))
end

--------------------------------------------------------------------------------


--- Determine channel for the given message (use default port if not specified)
-- @param str (String), control-map value)
-- @return (Number) the MIDI channel, 1-16

function MidiDevice:extract_midi_channel(str)
  TRACE("MidiDevice:extract_midi_channel()",str)

  return string.match(str, "|Ch([0-9]+)")
end


--------------------------------------------------------------------------------

--- Convert the point to an output value
-- @param pt (CanvasPoint)
-- @param elm (Table), control-map parameter
-- @param ceiling (Number), the UIComponent ceiling value
-- @return (Number), the output value

function MidiDevice:point_to_value(pt,elm,ceiling)
  --TRACE("MidiDevice:point_to_value()",pt,elm,ceiling)

  local ceiling = ceiling or 127
  local value = nil
  local val_type = type(pt.val)

  if (val_type == "boolean") then
    if (pt.val) then
      value = elm.maximum
    else
      value = elm.minimum
    end
  --[[
  elseif (val_type == "table") then
    -- multiple-parameter: tilt sensors, xy-pad...
    value = table.create()
    for k,v in ipairs(pt.val) do
      value:insert((v * (1 / ceiling)) * elm.maximum)
    end
  ]]
  else
    -- scale the value from "local" to "external"
    -- for instance, from Renoise dB range (1.4125375747681) 
    -- to a 7-bit controller value (127)
    value = math.floor((pt.val * (1 / ceiling)) * elm.maximum)
  end

  return value
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

