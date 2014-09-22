--[[============================================================================
-- Duplex.MidiDevice
-- Inheritance: MidiDevice -> Device
============================================================================]]--

--[[--
A generic MIDI device class, providing the ability to send and receive MIDI

### Changes

  0.99
    - Support for MMC (Midi Machine Control) messages over sysex
    - Support for 14-bit MIDI pitch bend messages 
    - Ability to pass unmatched (not just unhandled) messages to Renoise 

  0.98.28
    - FIXME MIDI pass-on got ignored when message was not handled by any controls

  0.98.21
    - Fixed: bug when handling MIDI ports that are added/removed while running

  0.9
    - First release 



--]]

--==============================================================================


class 'MidiDevice' (Device)

--------------------------------------------------------------------------------

--- Initialize MidiDevice class
-- @param display_name (string) the friendly name of the device
-- @param message_stream (MessageStream) the msg-stream we should attach to
-- @param port_in (string) the MIDI input port 
-- @param port_out (string) the MIDI output port 

function MidiDevice:__init(display_name, message_stream, port_in, port_out)
  TRACE("MidiDevice:__init()",display_name, message_stream, port_in, port_out)

  assert(display_name and display_name and message_stream and port_in and port_out, 
    "Internal Error. Please report: " ..
    "expected a valid display-name, stream and in/output device names for a MIDI device")

  Device.__init(self, display_name, message_stream, DEVICE_PROTOCOL.MIDI)

  --- (string) the MIDI input port 
  self.port_in = port_in

  --- (string) the MIDI output port
  self.port_out = port_out

  --- (MidiInputDevice)
  self.midi_in = nil

  --- (MidiOutputDevice)
  self.midi_out = nil

  -- (bool) specifies if the device dumps midi to the console
  self.dump_midi = false

  -- (int) when using the virtual control surface, and the control-map
  -- doesn't specify a specific channel, use this value: 
  self.default_midi_channel = 1

  --- (@{Duplex.Globals.PARAM_MODE}) the default parameter mode
  self.default_parameter_mode = "abs_7"

  --- (table) table of multibyte messages
  --    [int]{  -- channel
  --     lsb = [int]
  --     msb = {int]
  --    }
  self.composite_messages = {}

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
    msg_context = DEVICE_MESSAGE.MIDI_NOTE
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
    msg_context = DEVICE_MESSAGE.MIDI_CC
    msg_value = message[3]
    msg_channel = message[1]-175
    value_str = self._midi_cc_to_string(self,message[2])
  elseif (message[1]>=192) and (message[1]<=207) then
    msg_context = DEVICE_MESSAGE.MIDI_PROGRAM_CHANGE
    msg_value = message[2]
    msg_channel = message[1]-191
    value_str = self._program_change_to_string(self,message[2])
  elseif (message[1]>=208) and (message[1]<=223) then
    msg_context = DEVICE_MESSAGE.MIDI_CHANNEL_PRESSURE
    msg_value = message[2]
    msg_channel = message[1]-207
    value_str = "CP"
  elseif (message[1]>=224) and (message[1]<=239) then
    msg_context = DEVICE_MESSAGE.MIDI_PITCH_BEND
    msg_channel = message[1]-223


    if (message[2] >= 0) and (message[3] == 0) then

      -- ### start multibyte message 
      -- (14-bit pitch-bend)
      -- check if     0xE0,0x00,0x00 (initiate)
      -- followed by  0xE0,0xnn,0x00 (msb byte)
      -- and          0xE0,0xnn,0x00 (msb byte, final value)

      if (message[2] == 0) and (message[3] == 0) and
        not self.composite_messages[msg_channel] 
      then
        -- possible LSB initiated
        self.composite_messages[msg_channel] = {
          timestamp = os.clock(),
          lsb = nil,
          msb = nil
        }
        return
      else
        -- check for previous LSB
        local lsb_message = self.composite_messages[msg_channel]
        if (lsb_message) then
          -- too old - purge from list
          if (lsb_message.timestamp < os.clock()-0.1) then
            self.composite_messages[msg_channel] = nil
            return
          end
          -- previous initiated, receive lsb 
          if not lsb_message.lsb then
            lsb_message.lsb = message[2]
            return
          end
          -- receive msb and continue
          lsb_message.msb = message[2]
          msg_value = lsb_message.lsb + (lsb_message.msb*128)
          self.composite_messages[msg_channel] = nil
          --print("received 14 bit pitch bend message",msg_value)


        end
      end
      -- ### end multibyte message

    else
      self.composite_messages[msg_channel] = nil
      msg_value = message[3] 
      --print("received 7 bit pitch bend message",msg_value)
    end
    value_str = "PB"
  else
    -- ignore unsupported/unhandled messages...
    -- possible data include timing clock, active sensing etc.
  end

  -- sometimes (under heavy CPU load), the message can become mangled
  if not msg_is_note_off and not msg_value then
    --print("*** received invalid MIDI message",msg_value)
    return
  end

  if (value_str) then

    --print("*** value_str",value_str,msg_context)

    -- add the channel info to the value
    value_str = string.format("%s|Ch%i",value_str,msg_channel)

    -- retrieve all matching parameters
    local params = self.control_map:get_midi_params(value_str)
    --print("get_midi_params",#params)

    -- pass unmatched messages to renoise?
    if (#params == 0) then
      if self:pass_to_renoise(message) then
        return
      end
    end

    for k,param in ipairs(params) do
      
      -- roll 14 bit values back to 7 bit
      --print("param.mode",param.mode)
      --print("msg_value",msg_value,type(msg_value))
      if (not param.xarg.mode 
        or (param.xarg.mode ~= "abs_14"))
        and (type(msg_value) == "number") 
        and (msg_value > 127) 
      then
        --print("scale 14 bit values back to 7 bit - param.mode",param.xarg.mode,"type(msg_value)",type(msg_value))
        msg_value = math.floor(msg_value/128)
      end
      
      -- create the message
      local msg = Message()
      msg.value = msg_value
      msg.midi_msg = message
      msg.context = msg_context
      msg.channel = msg_channel
      msg.is_note_off = msg_is_note_off

      if (duplex_preferences.nrpn_support.value == false) then

        -- tell message-stream how many messages it can expect to receive
        -- (so it can memoize all relevant ui-objs)
        self.message_stream.queued_messages = #params - k
        self:_send_message(msg,param)

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
            local params2 = self.control_map:get_midi_params(value_str)
            param = table.rcopy(param2[1])
            if (param and self.nrpn_message.is_valid) then
              TRACE('MidiDevice: NRPN complete. value_str=',value_str,', param=',param)
              TRACE('MidiDevice: ',self.nrpn_message)
              msg.context = self.nrpn_message.context
              local track = renoise.song().tracks[renoise.song().selected_track_index]
              local device = track.devices[renoise.song().selected_device_index]
              local parameter = device.parameters[param.xarg.index]
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
            self:_send_message(msg,param)
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
-- @param message (table) MIDIMessage

function MidiDevice:sysex_callback(message)
  TRACE("MidiDevice:sysex_callback()",message)

  if(self.dump_midi)then
    LOG(("MidiDevice: %s got SYSEX with %d bytes"):format(
      self.port_in, #message))
  end
  
  -- the internal MIDI trigger functionality (via OscClient) does not support 
  -- sysex messages, however the MMC functionality is emulated here:

  if (#message == 6) then
    if (message[2] == 127) and
      -- (message[3]) device id is irrelevant
      (message[4] == 6) then

      local rns = renoise.song()

      if (message[5] == 1) then 
        --print("MMC Start")
        rns.transport:start(renoise.Transport.PLAYMODE_RESTART_PATTERN)
      elseif (message[5] == 2) then 
        --print("MMC Stop")
        rns.transport:stop()
      elseif (message[5] == 3) then
        --print("MMC Deferred play")
        rns.transport:start(renoise.Transport.PLAYMODE_CONTINUE_PATTERN)
      elseif (message[5] == 4) then
        --print("MMC Fast Forward")
        local play_pos = rns.transport.playback_pos
        play_pos.sequence = play_pos.sequence + 1
        local seq_len = #rns.sequencer.pattern_sequence
        if (play_pos.sequence <= seq_len) then
          local new_patt_idx = rns.sequencer.pattern_sequence[play_pos.sequence]
          local new_patt = rns:pattern(new_patt_idx)
          if (play_pos.line > new_patt.number_of_lines) then
            play_pos.line = 1
          end
          rns.transport.playback_pos = play_pos
        end
      elseif (message[5] == 5) then
        --print("MMC Rewind")
        local play_pos = rns.transport.playback_pos
        play_pos.sequence = play_pos.sequence - 1
        if (play_pos.sequence < 1) then
          play_pos.sequence = 1
        end
        local new_patt_idx = rns.sequencer.pattern_sequence[play_pos.sequence]
        local new_patt = rns:pattern(new_patt_idx)
        if (play_pos.line > new_patt.number_of_lines) then
          play_pos.line = 1
        end
        rns.transport.playback_pos = play_pos
      elseif (message[5] == 6) then
        --print("MMC Record Strobe")
        rns.transport.edit_mode = true
      elseif (message[5] == 7) then
        --print("MMC Record Exit")
        rns.transport.edit_mode = false
      elseif (message[5] == 9) then
        --print("MMC Pause")
        rns.transport:stop()
      end
    end
  end


  

end


--------------------------------------------------------------------------------

---  Send CC message to device
--  @param number (int) 7-bit control-number 
--  @param value (int) 7-bit control-value
--  @param channel (int) midi channel, between 1-16

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

--- Send Pitch-Bend message to device.
-- sending pitch-bend back to a device doesn't make sense when
-- you're using a keyboard - it's generally recommended to tag 
-- the parameter with the "skip_echo" attribute in such a case...
-- however, some device setups are different (e.g. Mackie Control)
--
-- @param value (int) the pitch-bend value, 7 bit value
-- @param channel (int) the MIDI channel, 1-16 (optional)
-- @param mode (string) specify sending mode, e.g. "abs" or "abs_14"

function MidiDevice:send_pitch_bend_message(value,channel,mode)
  TRACE("MidiDevice:send_pitch_bend_message()",value,channel,mode)

  if (not self.midi_out or not self.midi_out.is_open) then
    return
  end
  if not channel then
    channel = self.default_midi_channel
  end

  local dump_midi = function(msg) 
    if(self.dump_midi)then
      LOG(("MidiDevice: %s send MIDI %X %X %X"):format(
        self.port_out, msg[1], msg[2], msg[3]))
    else
      TRACE(("MidiDevice: %s send MIDI %X %X %X"):format(
        self.port_out, msg[1], msg[2], msg[3]))
    end
  end

  local message = nil

  if (mode == "abs_14") then
    
    -- 14 bit value (two messages)
    local third = math.floor(value/128)
    local msb = value-(third*128)
    message = {223+channel, 0, 0}
    dump_midi(message)
    self.midi_out:send(message) 
    message = {223+channel, msb, third}
    dump_midi(message)
    self.midi_out:send(message) 

    return
  
  else
    -- standard 7 bit message
    message = {223+channel, 0, value}
    dump_midi(message)
    self.midi_out:send(message) 

  end


end

--------------------------------------------------------------------------------

--- Send note message to device
-- @param key (int) the MIDI note pitch, 0-127
-- @param velocity (int) the MIDI note velocity, 0-127
-- @param channel (int) the MIDI channel, 1-16

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

--- Pass unhandled/unmatched message to Renoise? 
-- (this is defined in the device settings panel)
-- @param message (MIDI message)
-- @return bool (true when message was passed)

function MidiDevice:pass_to_renoise(message)
  TRACE("MidiDevice:pass_to_renoise(message)",message)

  local process = self.message_stream.process
  local pass_setting = process.settings.pass_unhandled.value
  if pass_setting then
    local osc_client = process.browser._osc_client
    osc_client:trigger_midi(message)
    return true
  end

  return false

end

--------------------------------------------------------------------------------

--- Convert MIDI note to control-map string, range C--1 to C-9
-- @param int (int) the MIDI note key, between 0-120
-- @return string

function MidiDevice:_note_to_string(int)
  local key = (int%12)+1
  local oct = math.floor(int/12)-1
  return NOTE_ARRAY[key]..(oct)
end


--------------------------------------------------------------------------------

--- Convert MIDI CC value to string, e.g. "CC#%d"
-- @param int (int) the 7-bit CC number

function MidiDevice:_midi_cc_to_string(int)
  return string.format("CC#%d",int)
end


--------------------------------------------------------------------------------

--- Convert Program Change value to string, e.g. "Prg#%d"
-- @param int (int) the 7-bit Program Change number

function MidiDevice:_program_change_to_string(int)
  return string.format("Prg#%d",int)
end


--------------------------------------------------------------------------------

--- Extract MIDI note-value (range C--1 to C9)
-- @param str (string), control-map value such as "C-4" or "F#-1"
-- @return (int) the MIDI note pitch, 0-127

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
-- @param str (string), control-map value attribute
-- @return (int) the MIDI CC number, 0-127

function MidiDevice:extract_midi_cc(str)
  TRACE("MidiDevice:extract_midi_cc()",str)

  str = strip_channel_info(str)
  return tonumber(string.sub(str,4))
end

--------------------------------------------------------------------------------


--- Determine channel for the given message (use default port if not specified)
-- @param str (string), control-map value
-- @return (int) the MIDI channel, 1-16

function MidiDevice:extract_midi_channel(str)
  TRACE("MidiDevice:extract_midi_channel()",str)

  return string.match(str, "|Ch([0-9]+)")
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
  
  self.context = DEVICE_MESSAGE.MIDI_CC
end

function NRPNMessage:__tostring()
  return string.format("NRPNmessage: [%s|%s|%s|%s|%s|%s|%s] context:%s, group_name:%s",
    tostring(self.msb), tostring(self.lsb), tostring(self.value), tostring(self.increment), tostring(self.decrement), tostring(self.fine1), tostring(self.fine2), tostring(self.context), tostring(self.group_name))
end

function NRPNMessage:is_valid()
  return (self ~= nil and self.msb ~= nil and self.lsb ~= nil and self.fine1 ~= nil and self.fine2 ~= nil)
end
-- -- NRPN

