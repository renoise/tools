--[[============================================================================
-- Duplex.MidiDevice
-- Inheritance: MidiDevice -> Device
============================================================================]]--

--[[--
A generic MIDI device class, providing the ability to send and receive MIDI

### Changes

  0.99.5
    - Full NRPN support (14 bit messages, absolute and relative modes)
    - Input throttling 

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

  --- (bool) decide whether to throttle incoming messages
  -- (the actual threshold is defined in preferences)
  self.throttling_enabled = true

  --- (bool) decide if multibyte (14-bit) support is enabled
  self.multibyte_enabled = true

  --- (bool) decide if NRPN support is enabled
  self.nrpn_enabled = true

  --- (bool) true when we expect a Null value from the device
  -- after receiving or transmitting a NRPN message
  -- (enabling this feature will transmit Null values too)
  -- important: only enable this feature if the device is known to transmit 
  -- these messages (midi bytes 2&3: 0x65,0x7F followed by 0x64,0x7F)
  self.terminate_nrpns = false

  --- (table) table of multibyte messages
  --    [fingerprint]{      
  --      type      = [enum] msg_context
  --      timestamp = [number]
  --      channel   = [int] 
  --      num       = [int] (only for CC messages)
  --      lsb       = [int]
  --      msb       = [int]
  --      midi_msgs = [table]
  --    }
  self._mb_messages = {}

  --- (table) messages that should not be interpreted as multibyte 
  -- (table is created when parsing control-map)
  self._multibyte_exempted = {} 

  --- (table) table of NRPN messages
  --    {
  --      timestamp = [number] 
  --      terminated = [bool]
  --      channel   = [int]     
  --      num_msb   = [int]
  --      num_lsb   = [int]
  --      data_msb  = {int]
  --      data_lsb  = [int]
  --    }
  self._nrpn_messages = {}

  --- (table) NRPN messages that only require the MSB part (7-bit)
  -- (table is created when parsing control-map)
  self._nrpn_msb_only = {} 

  --- (table) most recently received messages
  --  [fingerprint] = {
  --    timestamp   = [number]
  --    msg_context = [enum] 
  --    msg_channel = [int]
  --    value_str   = [string]
  --    msg_value   = [number]
  --    msg_is_note_off
  --    bit_depth   = [int]
  --    midi_msgs   = [table]
  --  }
  self._throttle_buffer = {}

  --- (table) messages that should not be throttled
  -- (table is created when parsing control-map)
  self._throttle_exempted = {}

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
-- to the <Param> value attribute in order to locate the control-map parameter 
-- @param message (Table/MIDIMessage)
-- @param no_multibyte (bool) temporarily disable multibyte support

function MidiDevice:midi_callback(message,no_multibyte)
  TRACE(("MidiDevice: %s received MIDI %X %X %X"):format(
    self.port_in, message[1], message[2], message[3]))

  if (self.dump_midi) then
    LOG(("MidiDevice: %s received MIDI %X %X %X"):format(
      self.port_in, message[1], message[2], message[3]))
  end

  local mb_enabled = self.multibyte_enabled
  if no_multibyte then
    self.multibyte_enabled = false
  end

  -- message attributes
  local value_str,msg_value,msg_context,msg_channel,msg_is_note_off,midi_msgs
  local bit_depth = 7

  if (message[1]>=128) and (message[1]<=159) then

    -- MIDI note message
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
    value_str = self:_note_to_string(message[2])

  elseif (message[1]>=176) and (message[1]<=191) then

    -- standard, NRPN or multibyte CC message
    local interpret_as_cc = true
    msg_channel = message[1]-175
   
    if self.nrpn_enabled and ((message[2]==0x63) or 
      not table.is_empty(self._nrpn_messages))
    then

      -- ### initiate/build NRPN message
      -- check if     0xBX,0x63,0xYY  (X = Channel, Y = NRPN Number MSB)
      -- followed by  0xBX,0x62,0xYY  (X = Channel, Y = NRPN Number LSB)
      -- and          0xBX,0x06,0xYY  (X = Channel, Y = Data Entry MSB)
      -- and          0xBX,0x26,0xYY  (X = Channel, Y = Data Entry LSB)
      -- (optionally, when 'terminate_nrpn' is specified...)
      -- and          0xBX,0x65,0x7F  (X = Channel)
      -- and          0xBX,0x64,0x7F  (X = Channel)

      if (message[2]==0x63) then
        --print("*** First part of NRPN message header")
        local nrpn_msg = {
          timestamp = os.clock(),
          channel = msg_channel,
          num_msb = message[3]
        }
        table.insert(self._nrpn_messages,nrpn_msg)
        return
      end

      -- Locate (partial) message, discard old ones...
      for k,v in ripairs(self._nrpn_messages) do
        if (v.channel == msg_channel) then

          -- helper function (when passing NRPN message on)
          -- @param nrpn_msg_idx (int)
          -- @param nrpn_msg (table)
          -- @return bool (false when message requires termination)
          local process_nrpn = function(nrpn_msg_idx,nrpn_msg)
            msg_context = DEVICE_MESSAGE.MIDI_NRPN
            msg_value = nrpn_msg.data_lsb + (nrpn_msg.data_msb*128)
            local nrpn_num = nrpn_msg.num_lsb + (nrpn_msg.num_msb*128)
            value_str = self:_nrpn_to_string(nrpn_num,nrpn_msg.channel)
            bit_depth = 14
            interpret_as_cc = false
            if not self.terminate_nrpns then
              midi_msgs = self:assemble_nrpn_message(nrpn_num)
              table.remove(self._nrpn_messages,nrpn_msg_idx)
              --print("received NRPN message",msg_value,os.clock())
            else
              -- wait for the termination
              return false
            end
            return true
          end

          if (message[2] == 0x62) and not v.num_lsb then
            --print("*** Second part of NRPN message header")
            v.num_lsb = message[3]
            return
          elseif v.num_lsb and not v.data_msb and (message[2] == 0x06) then
            --print("*** First part of NRPN data (MSB)")
            v.data_msb = message[3]
            -- if MSB-only, transmit the message without waiting for LSB
            local fingerprint = self:_create_fingerprint(DEVICE_MESSAGE.MIDI_NRPN,{
              {0xAF+msg_channel,0x63,v.num_msb},
              {0xAF+msg_channel,0x62,v.num_lsb},
            })
            if table.find(self._nrpn_msb_only,fingerprint) then
              --print("*** MSB-only - send immediately")
              v.data_lsb = 0x00
              if not process_nrpn(k,v) then
                --print("wait for the termination")
                return
              end
            else
              -- if we don't receive the LSB part, this message
              -- is sent as-is once the idle loop detects it...
              return
            end
          elseif v.data_msb and (message[2] == 0x026) then
            --print("*** Second part of NRPN data (LSB)")
            v.data_lsb = message[3]
            if not process_nrpn(k,v) then
              --print("wait for the termination")
              return
            end
          elseif (v.data_msb) and 
            (message[2] == 0x65) and (message[3] == 0x7f) 
          then
            --print("First part of NRPN termination")
          elseif (v.data_msb) and 
            (message[2] == 0x64) and (message[3] == 0x7f) 
          then
            --print("Second part of NRPN termination")
            -- process message when LSB has not been set
            if not v.data_lsb then
              v.terminated = true
              v.data_lsb = 0x00
              local msg = {0xAF+v.channel,0x26,0x00}
              self:midi_callback(msg)
            else
              local nrpn_num = v.num_lsb + (v.num_msb*128)
              midi_msgs = self:assemble_nrpn_message(nrpn_num)
              table.remove(self._nrpn_messages,k)
              bit_depth = 14
            end
          else
            LOG("Received malformed NRPN message...")
          end
        end

      end

      -- ### end NRPN message

    elseif self.multibyte_enabled and
      (message[2] > 0 and message[2] < 65) 
    then

      -- ### multibyte (14-bit) CC message 
      -- check if     0xBX,0xYY,0xZZ (X = Channel, YY = Number,   ZZ = Data MSB)
      -- followed by  0xBX,0xYY,0xZZ (X = Channel, YY = Number+32,ZZ = Data LSB)

      local fingerprint = nil
      if (message[2] < 31) then
        fingerprint = self:_create_fingerprint(DEVICE_MESSAGE.MIDI_CC,{message})
        --print("fingerprint MSB",fingerprint)
        if not table.find(self._multibyte_exempted,fingerprint) then
          local mb_message = self._mb_messages[fingerprint]
          if (mb_message) then
            --print("repeated message")
            -- repeated message - we are dealing with a 7-bit controller?
            -- output the message that got "swallowed"
            local no_mb = true
            local midi_msg = {
              0xAF+mb_message.channel,
              mb_message.num,
              mb_message.msb
            }
            self:midi_callback(midi_msg,no_mb)
            self._mb_messages[fingerprint] = nil
          else
            --print("possible multibyte message initiated",rprint(self._mb_messages),fingerprint)
            -- store the message and wait for the LSB part 
            self._mb_messages[fingerprint] = {
              timestamp = os.clock(),
              type = DEVICE_MESSAGE.MIDI_CC,
              channel = msg_channel,
              num = message[2],
              lsb = nil,
              msb = message[3],
              midi_msgs = {message}
            }
            return
          end
        end
      else
        -- check for first part (lower by 32)
        fingerprint = self:_create_fingerprint(
          DEVICE_MESSAGE.MIDI_CC,{{message[1],message[2]-32,message[3]}})
        local mb_message = self._mb_messages[fingerprint]
        if (mb_message) then
          if (mb_message.timestamp < os.clock()-0.1) then
            -- we shouldn't arrive here
            --print("multibyte message is too old - ignore")
            return
          else 
            -- receive final LSB part 
            mb_message.lsb = message[3]
            table.insert(mb_message.midi_msgs,message)
            midi_msgs = mb_message.midi_msgs
            msg_context = DEVICE_MESSAGE.MIDI_CC
            msg_value = mb_message.lsb + (mb_message.msb*128)
            value_str = self:_midi_cc_to_string(mb_message.num)
            self._mb_messages[fingerprint] = nil
            --print("received 14 bit multibyte message",msg_value,os.clock())
            --print("#midi_msgs",#midi_msgs)
            bit_depth = 14
            interpret_as_cc = false
          end
        end
      end
      -- ### end multibyte message
    end

    if interpret_as_cc then
      --print("standard (7bit) CC message",message[3],os.clock())
      msg_context = DEVICE_MESSAGE.MIDI_CC
      msg_value = message[3]
      value_str = self:_midi_cc_to_string(message[2])
    end

  elseif (message[1]>=192) and (message[1]<=207) then
    msg_context = DEVICE_MESSAGE.MIDI_PROGRAM_CHANGE
    msg_value = message[2]
    msg_channel = message[1]-191
    value_str = self:_program_change_to_string(message[2])

  elseif (message[1]>=208) and (message[1]<=223) then
    msg_context = DEVICE_MESSAGE.MIDI_CHANNEL_PRESSURE
    msg_value = message[2]
    msg_channel = message[1]-207
    value_str = "CP"

  elseif (message[1]>=224) and (message[1]<=239) then
    -- standard or multibyte pitch bend message

    msg_context = DEVICE_MESSAGE.MIDI_PITCH_BEND
    msg_channel = message[1]-223
    value_str = "PB"

    local fingerprint = self:_create_fingerprint(msg_context,{message})

    if self.multibyte_enabled and
      (message[2] >= 0) and (message[3] == 0) 
    then

      -- ### deal with 14-bit pitch-bend messages
      -- check if     0xEX,0x00,0x00 (initiate)
      -- followed by  0xEX,0xYY,0x00 (MSB byte)
      -- and          0xEX,0xYY,0x00 (LSB byte, final value)

      if (message[2] == 0) and (message[3] == 0) and
        not self._mb_messages[fingerprint] 
      then
        -- possible multibyte initiated
        self._mb_messages[fingerprint] = {
          timestamp = os.clock(),
          channel = msg_channel,
          type = msg_context,
          lsb = nil,
          msb = nil
        }
        return
      else
        -- check for previous msg
        local lsb_message = self._mb_messages[fingerprint]
        if (lsb_message) then
          -- too old - purge from list
          if (lsb_message.timestamp < os.clock()-0.1) then
            --self._mb_messages[fingerprint] = nil
            return
          end
          -- previous initiated, receive MSB part
          if not lsb_message.msb then
            lsb_message.msb = message[2]
            return
          end
          -- receive final LSB part
          lsb_message.lsb = message[2]
          msg_value = lsb_message.lsb + (lsb_message.msb*128)
          bit_depth = 14
          self._mb_messages[fingerprint] = nil
          --print("received 14 bit pitch bend message",msg_value)
        end
      end
      -- ### end multibyte message

    else
      self._mb_messages[fingerprint] = nil
      msg_value = message[3] 
      --print("received 7 bit pitch bend message",msg_value)
    end

  else
    -- ignore unsupported/unhandled messages...
    -- possible data include timing clock, active sensing etc.
  end

  if no_multibyte then
    self.multibyte_enabled = mb_enabled
  end

  -- always pass MIDI messages as table, 
  --if (bit_depth == 14) and not (msg_context == DEVICE_MESSAGE.MIDI_NRPN) then
  --  midi_msgs = {message}
  --end
  if not midi_msgs then
    midi_msgs = {message}
  end

  -- throttle input messages
  if (msg_context == DEVICE_MESSAGE.MIDI_NRPN) or
    (msg_context == DEVICE_MESSAGE.MIDI_CC)
  then
    local fingerprint = self:_create_fingerprint(msg_context,midi_msgs)
    local stored_msg = self._throttle_buffer[fingerprint]
    if (stored_msg) then
      local pace = os.clock() - stored_msg.timestamp
      if (pace < 0.05) then
        --print("stored_msg.timestamp:",stored_msg.timestamp,os.clock() - stored_msg.timestamp)
        --print("message is being throttled:",fingerprint,os.clock(),value_str,msg_value)
        -- drop message, but keep a copy (output on idle)
        stored_msg.value_str = value_str
        stored_msg.msg_value = msg_value
        stored_msg.msg_is_note_off = msg_is_note_off
        stored_msg.midi_msgs = midi_msgs
        return
      else
        -- avoid idle loop processing
        stored_msg.value_str = nil
      end
      stored_msg.timestamp = os.clock()
    else
      --print("add to throttle buffer",fingerprint,os.clock())
      self._throttle_buffer[fingerprint] = {
        timestamp = os.clock(),
        msg_context = msg_context,
        msg_channel = msg_channel,
        bit_depth = bit_depth
      }
    end
  end

  -- sometimes (under heavy CPU load), the message can become mangled
  if not msg_is_note_off and not msg_value then
    --print("*** received invalid MIDI message",msg_value)
    return
  end

  self:build_message(value_str,msg_value,msg_context,msg_channel,msg_is_note_off,bit_depth,midi_msgs)

end

--------------------------------------------------------------------------------

--- Following up on the midi_callback, this method will extract parameters 
-- from the control-map and construct messages for each of them...
-- @param value_str (string) the control-map value to look for
-- @param msg_value (int) the value we recieved 
-- @param msg_context (enum) (@{Duplex.Globals.DEVICE_MESSAGE})
-- @param msg_channel (int) between 1 and 16
-- @param msg_is_note_off (bool)
-- @param bit_depth (int) 7 or 14 bits
-- @param midi_msgs (list of tables, each with three bytes)

function MidiDevice:build_message(value_str,msg_value,msg_context,msg_channel,msg_is_note_off,bit_depth,midi_msgs)
  TRACE("MidiDevice:build_message()",value_str,msg_value,msg_context,msg_channel,msg_is_note_off,bit_depth,midi_msgs)

  if (value_str) then

    --print("*** msg_context",msg_context)
    --print("*** msg_value",msg_value)
    --print("*** value_str,msg_value",value_str,msg_value)

    -- add the channel info to the value
    value_str = string.format("%s|Ch%i",value_str,msg_channel)

    -- retrieve all matching parameters
    local params = self.control_map:get_midi_params(value_str)
    --print("get_midi_params",#params)

    -- pass unmatched messages to renoise?
    if (#params == 0) then
      if self:pass_to_renoise(midi_msgs) then
        return
      end
    end

    for k,param in ipairs(params) do

      --print("param.xarg",rprint(param.xarg))

      -- when we have received a 14-bit message, but the parameters
      -- explicitly specifies a 7-bit mode, scale value to 7-bit range
      if (bit_depth == 14) and
        (string.find(param.xarg.mode,"_7") or
        (not param.xarg.mode 
          and self.default_parameter_mode ~= "abs_7")
          and (type(msg_value) == "number"))
      then
        --print("roll 14 bit values back to 7 bit")
        msg_value = math.floor(msg_value/128)
      end
      
      -- create the duplex message
      local msg = Message()
      msg.value = msg_value
      msg.context = msg_context
      msg.channel = msg_channel
      msg.is_note_off = msg_is_note_off
      msg.midi_msgs = midi_msgs

      -- tell message-stream how many messages it can expect to receive
      -- (so it can memoize all relevant ui-objs)
      self.message_stream.queued_messages = #params - k
      self:_send_message(msg,param)

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

---  Send raw MIDI message to device, optionally dump to console
-- (used by send_cc, send_pitch_bend etc. methods)

function MidiDevice:send_midi(msg)

  if (not self.midi_out or not self.midi_out.is_open) then
    return
  end

  local dump_str = ("MidiDevice: %s send MIDI %X %X %X"):format(
    self.port_out, msg[1], msg[2], msg[3])

  if(self.dump_midi)then
    LOG(dump_str)
  else
    TRACE(dump_str)
  end

  self.midi_out:send(msg)

end

--------------------------------------------------------------------------------

--- Send CC message to device
-- @param number (int) 7-bit control-number 
-- @param value (int) 7 or 14-bit control-value
-- @param channel (int) midi channel, between 1-16
-- @param multibyte (bool) true when sending a 14-bit value

function MidiDevice:send_cc_message(number,value,channel,multibyte)
  TRACE("MidiDevice:send_cc_message()",number,value,channel,multibyte)

  if not channel then
    channel = self.default_midi_channel
  end

  local msg_channel = 0xAF+channel
  local msg_number = math.floor(number)

  if multibyte then
    local msg_msb = {msg_channel, msg_number, bit.rshift(value,7)}
    local msg_lsb = {msg_channel, msg_number, value%128}
    self:send_midi(msg_msb)
    self:send_midi(msg_lsb)
  else
    local message = {msg_channel, msg_number, math.floor(value)}
    self:send_midi(message)
  end

end


--------------------------------------------------------------------------------

---  Send NRPN message to device
-- @param number (int) 14-bit control-number 
-- @param value (int) 14-bit control-value
-- @param channel (int) midi channel, between 1-16
-- @param send_only_msb (bool) when sending 7-bit messages

function MidiDevice:send_nrpn_message(number,value,channel,send_only_msb)
  TRACE("MidiDevice:send_nrpn_message()",number,value,channel,send_only_msb)

  if not channel then
    channel = self.default_midi_channel
  end

  local num_channel = 0xAF+channel

  self:send_midi({num_channel, 0x63, bit.rshift(number,7)})
  self:send_midi({num_channel, 0x62, number%128})
  if send_only_msb then
    self:send_midi({num_channel, 0x06, value})
  else
    self:send_midi({num_channel, 0x06, bit.rshift(value,7)})
    self:send_midi({num_channel, 0x26, value%128})
  end
  if self.terminate_nrpns then
    self:send_midi({num_channel, 0x65, 0x7F})
    self:send_midi({num_channel, 0x64, 0x7F})
  end

end

--------------------------------------------------------------------------------

--- (Re)construct the table of MIDI messages that together form a complete 
-- NRPN message (compares the provided number with the active NRPN messages)
-- @param match_nrpn_num
-- @return table or nil

function MidiDevice:assemble_nrpn_message(match_nrpn_num)

  local rslt = nil

  for k,v in ipairs(self._nrpn_messages) do
    local nrpn_num = bit.rshift(v.num_msb,7) + v.num_lsb
    if (match_nrpn_num == nrpn_num) then
      local num_channel = 0xAF+v.channel
      rslt = {
        {num_channel, 0x63, v.num_msb},
        {num_channel, 0x62, v.num_lsb}, 
        {num_channel, 0x06, v.data_msb},
        {num_channel, 0x26, v.data_lsb},
      }
      break
    end
  end

  return rslt

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

  if not channel then
    channel = self.default_midi_channel
  end

  local message = nil
  if (mode == "abs_14") then
    -- 14 bit value (two messages)
    local third = math.floor(value/128)
    local msb = value-(third*128)
    message = {223+channel, 0, 0}
    self:send_midi(message)
    message = {223+channel, msb, third}
    self:send_midi(message)
    return
  else
    -- standard 7 bit message
    message = {223+channel, 0, value}
    self:send_midi(message)
  end

end

--------------------------------------------------------------------------------

--- Send note message to device
-- @param key (int) the MIDI note pitch, 0-127
-- @param velocity (int) the MIDI note velocity, 0-127
-- @param channel (int) the MIDI channel, 1-16

function MidiDevice:send_note_message(key,velocity,channel)

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

  self:send_midi(message)

end

--------------------------------------------------------------------------------

--- Pass unhandled/unmatched message to Renoise? 
-- (this is defined in the device settings panel)
-- @param messages (table of MIDI messages)
-- @return bool (true when message was passed)

function MidiDevice:pass_to_renoise(messages)
  TRACE("MidiDevice:pass_to_renoise(message)",messages)

  local process = self.message_stream.process
  local pass_setting = process.settings.pass_unhandled.value
  if pass_setting then
    local osc_client = process.browser._osc_client
    for _,midi_msg in ipairs(message) do
      osc_client:trigger_midi(midi_msg)
    end
    return true
  end

  return false

end

--------------------------------------------------------------------------------

--- Idle loop implementation for the MidiDevice class
-- main purpose: process (or discard) NRPN messages

function MidiDevice:on_idle()

  local clk = os.clock()

  if (#self._nrpn_messages > 0) then
    --print("self._nrpn_messages...",rprint(self._nrpn_messages))
    for k,v in ripairs(self._nrpn_messages) do
      --print("k,v,",k,v)
      if v and (v.timestamp < clk-0.05) then
        if (v.data_msb and not v.data_lsb) then
          -- process timed-out NRPN message without LSB part: 
          -- construct message and let midi_callback do the rest...
          v.data_lsb = 0x00
          v.terminated = true
          self:midi_callback({0xAF+v.channel,0x26,v.data_lsb})
        elseif (v.num_msb and not v.num_lsb) then
          -- CC#99 that timed out is treated as a normal CC message
          -- (create message and let midi_callback handle it)
          table.remove(self._nrpn_messages,k)
          self.nrpn_enabled = false
          self:midi_callback({0xAF+v.channel,0x63,v.num_msb})
          self.nrpn_enabled = true
        else
          --print("discarding old message")
          table.remove(self._nrpn_messages,k)
        end
      end
    end
  end

  --print("on_idle - self._throttle_buffer",rprint(self._throttle_buffer))

  for k,v in pairs(self._mb_messages) do
    if (v.timestamp < clk-0.1) then
      --print("detected timed-out multibyte message",rprint(self._mb_messages))
      local mb_msg = table.rcopy(v)
      self._mb_messages[k] = nil
      if (v.type == DEVICE_MESSAGE.MIDI_CC) then
        -- case #1: likely a timed-out CC message in the range 0-31
        -- (to avoid this, we can either disable multibyte support entirely,
        -- or add it to the list of exempted multibyte sources)
        local no_mb = true
        local midi_msg = {0xAF+mb_msg.channel,mb_msg.num,mb_msg.msb}
        self:midi_callback(midi_msg,no_mb)
      else
        -- other message types?
      end
      --print("cleared this mb-entry:",k)
    end
  end

  for k,v in pairs(self._throttle_buffer) do
    if (v.value_str) then
      local value_str = v.value_str
      v.value_str = nil
      --print("send throttled, timed-out message - v.value_str",k,value_str,v.msg_value)
      self:build_message(value_str,v.msg_value,v.msg_context,v.msg_channel,
        v.msg_is_note_off,v.bit_depth,v.midi_msgs)
    end
  end

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

--- Convert NRPN value to string, e.g. "NRPN#16383"
-- @param num (int) the parameter number (0-16383)

function MidiDevice:_nrpn_to_string(num)
  return string.format("NRPN#%d",num)
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
-- @param str (string), control-map value attribute (e.g. "CC#10")
-- @return (int) the MIDI CC number, 0-127

function MidiDevice:extract_midi_cc(str)
  TRACE("MidiDevice:extract_midi_cc()",str)

  str = strip_channel_info(str)
  return tonumber(string.sub(str,4))
end

--------------------------------------------------------------------------------

--- Extract MIDI NRPN number (range 0-16383)
-- @param str (string), control-map value attribute (e.g. "NRPN#16383")
-- @return (int) the MIDI NRPN number, 0-16383

function MidiDevice:extract_midi_nrpn(str)
  TRACE("MidiDevice:extract_midi_nrpn()",str)

  str = strip_channel_info(str)
  return tonumber(string.sub(str,6))
end

--------------------------------------------------------------------------------

--- Determine channel for the given message (use default port if not specified)
-- @param str (string), control-map value
-- @return (int) the MIDI channel, 1-16

function MidiDevice:extract_midi_channel(str)
  TRACE("MidiDevice:extract_midi_channel()",str)

  return string.match(str, "|Ch([0-9]+)") 
end

--------------------------------------------------------------------------------

--- Create MIDI 'fingerprint' for the provided message(s)
-- (just enough information to identify the CC/NRPN source)
-- @param msg_context
-- @param midi_msgs
-- @return string

function MidiDevice:_create_fingerprint(msg_context,midi_msgs)
  TRACE("MidiDevice:_create_fingerprint()",msg_context,midi_msgs)

  local rslt = nil
  if (msg_context == DEVICE_MESSAGE.MIDI_NRPN) then
    -- memorize the first two parts of an NRPN message
    rslt = string.format("%x,%x,%x,%x,%x,%x",
      midi_msgs[1][1],midi_msgs[1][2],midi_msgs[1][3],
      midi_msgs[2][1],midi_msgs[2][2],midi_msgs[2][3])
  elseif (msg_context == DEVICE_MESSAGE.MIDI_CC) then
    -- memorize the channel and number
    rslt = string.format("%x,%x",midi_msgs[1][1],midi_msgs[1][2])
  elseif (msg_context == DEVICE_MESSAGE.MIDI_PITCH_BEND) then
    -- memorize the channel
    rslt = string.format("%x",midi_msgs[1][1])
  end

  return rslt


end

