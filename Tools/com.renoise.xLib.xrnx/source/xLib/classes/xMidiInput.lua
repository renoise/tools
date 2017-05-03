--[[===============================================================================================
xMidiInput
===============================================================================================]]--

--[[--

Asynchroneous interpretation of MIDI messages
.
#

### Features
Supports all common MIDI messages (including 14-bit). 

### Notes

About 14-bit multibyte CC messages: when this feature is enabled, the class will wait for the extra messages to arrive, which can delay the processing of "normal" 7-bit messages. So - if you don't need to support multibyte message, you can disable this feature, or exempt certain CC messages from being interpreted as multibyte messages (multibyte_exempted)

About Data Increment and Data Decrement: the value portion of these messages is sometimes given a value or step size, but the transmitted value byte is commonly set to zero. This class will preserve the value, but whether it is used or not depends on the application. 

### How to use

The class is implemented with a callback, which will recieve xMidiMessages

    -- define our callback
    myCallback = function(xmsg)
      -- do something with the message
    end

    -- Then, instantiate this class with the callback as argument:
    myMidiInput = xMidiInput{
      callback_fn = myCallback
    }

    -- Now you can feed it with raw midi messages:
    myMidiInput:input({0x90,0x45,0x6F}) 


### Requires
@{xMidiMessage}

]]


class 'xMidiInput'

---------------------------------------------------------------------------------------------------
--- [Constructor] accepts a single table as argument 
-- @param args, table
--  callback_fn 
--  multibyte_enabled
--  nrpn_enabled
--  terminate_nrpns
--  timeout

function xMidiInput:__init(...)

	local args = cLib.unpack_args(...)

  --assert(args.callback_fn,"You need to provide a callback function")

  --- (function) specify where messages should go
  self.callback_fn = args.callback_fn or nil

  --- (bool) decide if multibyte (14-bit) support is enabled
  self.multibyte_enabled = args.multibyte_enabled or false

  --- (bool) decide if NRPN support is enabled
  self.nrpn_enabled = args.nrpn_enabled or false

  --- (bool) decide whether to throttle incoming messages
  --self.throttling_enabled = true

  --- (bool) true when we expect a Null value from the device
  -- after receiving or transmitting a NRPN message
  -- (enabling this feature will transmit Null values too)
  -- important: only enable this feature if the device is known to transmit 
  -- these messages (midi bytes 2&3: 0x65,0x7F followed by 0x64,0x7F)
  self.terminate_nrpns = args.terminate_nrpns or false

  --- number, the amount of time that should pass before we consider a 
  -- multibyte message obsolete (0.1 = tenth of a second)
  self.timeout = args.timeout or 0.1

  -- internal --

  --- (table) messages that should never be interpreted as multibyte 
  self._multibyte_exempted = {} 

  --- table<fingerprint> NRPN messages that only require the MSB part (7-bit)
  -- note that 7bit NRPN works without this, but might be a bit sluggish as
  -- we need to wait for the idle mode to determine that no LSB part arrived
  self._nrpn_msb_only = {} 

  --- table of pending multibyte messages
  --    [fingerprint]{      
  --      type      = [enum] msg_type
  --      timestamp = [number]
  --      channel   = [int] 
  --      num       = [int] (only for CC messages)
  --      lsb       = [int]
  --      msb       = [int]
  --      port_name = [string]
  --    }
  self._mb_messages = {}

  --- table of pending NRPN messages
  --    {
  --      timestamp = [number] 
  --      channel   = [int]     
  --      num_msb   = [int]
  --      num_lsb   = [int]
  --      data_msb  = {int]
  --      data_lsb  = [int]
  --      port_name = [string]
  --    }
  self._nrpn_messages = {}

  --- (table) messages that should not be throttled
  --self._throttle_exempted = {}

  --- table of most recently received messages
  --  [fingerprint] = {
  --    timestamp   = [number]
  --    msg_context = [enum] 
  --    msg_channel = [int]
  --    value_str   = [string]
  --    msg_value   = [number]
  --    msg_is_note_off
  --    bit_depth   = [int]
  --  }
  --self._throttle_buffer = {}

  -- initialize --

  renoise.tool().app_idle_observable:add_notifier(function()
    self:on_idle()
  end)


end

---------------------------------------------------------------------------------------------------
-- [Class] Process incoming message - will invoke the callback function when able 
-- to construct a xMidiMessage from the data that has been received
-- @param msg (table), raw MIDI message with 3 parts
-- @param port_name (string), where message originated from

function xMidiInput:input(msg,port_name)
  TRACE("xMidiInput:input(msg,port_name)",msg,port_name)

  assert(type(msg)=="table","Expected MIDI message to be a table")
  assert(#msg==3,"Malformed MIDI message, expected 3 parts")
  assert(type(port_name)=="string","Expected port_name to be a string")

  local msg_type,
        msg_channel,
        msg_bit_depth

  -- initialize with two bytes
  local msg_values = {0,0}
          

  if (msg[1]>=0x80) and (msg[1]<=0x9F) then
    -- note-on/note-off
    msg_values[1] = msg[2] -- note
    msg_values[2] = msg[3] -- velocity

    if(msg[1]>0x8F)then
      msg_channel = msg[1]-0x8F  
      if (msg[3]==0) then
        msg_type = xMidiMessage.TYPE.NOTE_OFF
      else
        msg_type = xMidiMessage.TYPE.NOTE_ON
      end
    else  
      msg_type = xMidiMessage.TYPE.NOTE_OFF
      msg_channel = msg[1]-0x7F 
    end

  elseif (msg[1]>=0xA0) and (msg[1]<=0xAF) then
    -- key aftertouch
    msg_type = xMidiMessage.TYPE.KEY_AFTERTOUCH
    msg_channel = msg[1]-0x9F 
    msg_values[1] = msg[2] -- note
    msg_values[2] = msg[3] -- pressure

  elseif (msg[1]>=0xB0) and (msg[1]<=0xBF) then
    -- standard, NRPN or multibyte CC message
    local interpret_as_cc = true
    msg_channel = msg[1]-0xAF
   
    if self.nrpn_enabled and ((msg[2]==0x63) or 
      not table.is_empty(self._nrpn_messages))
    then

      -- ### initiate/build NRPN message
      -- check if     0xBX,0x63,0xYY  (X = Channel, Y = NRPN Number MSB)  99
      -- followed by  0xBX,0x62,0xYY  (X = Channel, Y = NRPN Number LSB)  98
      -- (if inc/dec mode - note that multiple of these messages can be 
      --  sent after the header has been received)
      -- and          0xBX,0x61,0xYY  Decrement #97
      -- or           0xBX,0x60,0xYY  Increment #96
      -- (else)
      -- and          0xBX,0x06,0xYY  (X = Channel, Y = Data Entry MSB)   
      -- (if 7bit NRPN, it stops here)
      -- and          0xBX,0x26,0xYY  (X = Channel, Y = Data Entry LSB)
      -- (optionally, when 'terminate_nrpn' is specified...)
      -- and          0xBX,0x65,0x7F  (X = Channel)
      -- and          0xBX,0x64,0x7F  (X = Channel)

      if (msg[2]==0x63) then
        -- First part of NRPN msg header
        local nrpn_msg = {
          timestamp = os.clock(),
          channel = msg_channel,
          num_msb = msg[3],
          port_name = port_name,
        }
        table.insert(self._nrpn_messages,nrpn_msg)
        return 
      end

      -- Locate (partial) message, discard old ones...
      for k,v in ripairs(self._nrpn_messages) do
        if (v.channel == msg_channel) then

          -- define NRPN message 
          -- @param nrpn_msg_idx (int)
          -- @param nrpn_msg (table)
          -- @return bool (false when message requires termination)

          local process_nrpn = function(nrpn_msg_idx,nrpn_msg)
            msg_type = xMidiMessage.TYPE.NRPN
            msg_values[1] = xMidiMessage.merge_mb(nrpn_msg.num_msb,nrpn_msg.num_lsb)
            msg_values[2] = xMidiMessage.merge_mb(nrpn_msg.data_msb,nrpn_msg.data_lsb)
            msg_bit_depth = xMidiMessage.BIT_DEPTH.FOURTEEN
            interpret_as_cc = false
            if (self.terminate_nrpns == false) then
              table.remove(self._nrpn_messages,nrpn_msg_idx)
              return true
            else
              return false
            end
          end

          if (v.port_name ~= port_name) then
            -- Message looked like NRPN data, but origin is different
          else
            if (msg[2] == 0x62) and not v.num_lsb then
              -- Second part of NRPN message header
              v.num_lsb = msg[3]
              return
            elseif v.num_lsb and not v.data_msb 
              and (msg[2] == 0x06)  -- NRPN Data
              or (msg[2] == 0x61)   -- NRPN Decrement
              or (msg[2] == 0x60)   -- NRPN Increment
            then
              if (msg[2] == 0x06) then
                -- First part of NRPN data (MSB)
                v.data_msb = msg[3]
                -- if MSB-only, transmit the message without waiting for LSB
                local fingerprint = self:_create_fingerprint(xMidiMessage.TYPE.NRPN,{
                  {0xAF+msg_channel,0x63,v.num_msb},
                  {0xAF+msg_channel,0x62,v.num_lsb},
                })
                if table.find(self._nrpn_msb_only,fingerprint) then
                  -- MSB-only - send immediately?
                  v.data_lsb = 0x00
                  if not process_nrpn(k,v) then
                    -- no, wait for termination in idle time
                    return
                  end
                else
                  -- MSB-only - wait for idle loop or new NRPN message with same number (7bit)
                  -- if we don't receive the LSB part, this message
                  -- is sent as-is once the idle loop detects it...
                  return
                end
              else

                -- NRPN increment/decrement

                local msg_type = nil
                if (msg[2] == 0x61) then
                  msg_type = xMidiMessage.TYPE.NRPN_DECREMENT
                elseif (msg[2] == 0x60) then
                  msg_type = xMidiMessage.TYPE.NRPN_INCREMENT
                end

                self.callback_fn(xMidiMessage{
                  message_type = msg_type,
                  channel = msg_channel,
                  values = {
                    xMidiMessage.merge_mb(v.num_msb,v.num_lsb),
                    msg[3]
                  },
                  bit_depth = xMidiMessage.BIT_DEPTH.SEVEN,
                  port_name = port_name,
                })
                -- don't remove the nrpn message - let us receive 
                -- multiple inc/dec messages after the NRPN header
                --table.remove(self._nrpn_messages,k)
                return

              end
            elseif v.data_msb and (msg[2] == 0x026) then
              -- Second part of NRPN data (LSB)
              v.data_lsb = msg[3]
              if not process_nrpn(k,v) then
                -- wait for termination in idle time
                return
              end
            elseif (v.data_msb) and 
              (msg[2] == 0x65) and (msg[3] == 0x7f) 
            then
              -- First part of NRPN termination
              return
            elseif (v.data_msb) and 
              (msg[2] == 0x64) and (msg[3] == 0x7f) 
            then
              -- Second part of NRPN termination
              if not v.data_lsb then
                v.data_lsb = 0x00
              end
              table.remove(self._nrpn_messages,k)
              msg_type = xMidiMessage.TYPE.NRPN
              msg_values[1] = xMidiMessage.merge_mb(v.num_msb,v.num_lsb)
              msg_values[2] = xMidiMessage.merge_mb(v.data_msb,v.data_lsb)
              msg_bit_depth = xMidiMessage.BIT_DEPTH.FOURTEEN
            else
              LOG("*** Received malformed NRPN message...")
            end
          end
        end

      end

      -- ### end NRPN message
    elseif self.multibyte_enabled and
      (msg[2] >= 0 and msg[2] < 65) 
    then

      -- ### multibyte (14-bit) CC message 
      -- check if     0xBX,0xYY,0xZZ (X = Channel, YY = Number,   ZZ = Data MSB)
      -- followed by  0xBX,0xYY,0xZZ (X = Channel, YY = Number+32,ZZ = Data LSB)

      local fingerprint = nil
      if (msg[2] < 31) then
        fingerprint = self:_create_fingerprint(xMidiMessage.TYPE.CONTROLLER_CHANGE,{msg})
        if not table.find(self._multibyte_exempted,fingerprint) then
          local mb_message = self._mb_messages[fingerprint]
          if (mb_message) then
            -- repeated message - seems we are dealing with 7-bit after all...
            -- output the message that got "swallowed"
            self.callback_fn(xMidiMessage{
              message_type = xMidiMessage.TYPE.CONTROLLER_CHANGE,
              channel = mb_message.channel,
              values = {
                mb_message.num,
                mb_message.msb,
              },
              bit_depth = xMidiMessage.BIT_DEPTH.SEVEN,
              port_name = mb_message.port_name,
            })
            self._mb_messages[fingerprint] = nil
          else
            -- possible multibyte message initiated
            -- store the message and wait for the LSB part 
            self._mb_messages[fingerprint] = {
              timestamp = os.clock(),
              type = xMidiMessage.TYPE.CONTROLLER_CHANGE,
              channel = msg_channel,
              num = msg[2],
              lsb = nil,
              msb = msg[3],
              port_name = port_name,
            }
            return
          end
        else
          -- message is exempted - do not interpret as multibyte
        end
      else
        -- check for first part (lower by 32)
        fingerprint = self:_create_fingerprint(
          xMidiMessage.TYPE.CONTROLLER_CHANGE,{{msg[1],msg[2]-32,msg[3]}})
        local mb_message = self._mb_messages[fingerprint]
        if (mb_message) then
          if (mb_message.port_name ~= port_name) then
            -- Message looked like multibyte CC, but origin is different
          else
            if (mb_message.timestamp < os.clock()- self.timeout) then
              -- we shouldn't arrive here
              -- multibyte message is too old - ignore
              return
            else 
              -- receive final LSB part 
              -- (14 bit multibyte message)
              mb_message.lsb = msg[3]
              msg_type = xMidiMessage.TYPE.CONTROLLER_CHANGE
              msg_values[1] = mb_message.num
              msg_values[2] = xMidiMessage.merge_mb(mb_message.msb,mb_message.lsb)
              self._mb_messages[fingerprint] = nil
              msg_bit_depth = xMidiMessage.BIT_DEPTH.FOURTEEN
              interpret_as_cc = false
            end
          end
        end
      end
      -- ### end multibyte message
    end

    if interpret_as_cc then
      msg_type = xMidiMessage.TYPE.CONTROLLER_CHANGE
      msg_values[1] = msg[2] -- CC number
      msg_values[2] = msg[3] -- CC value
    end

  elseif (msg[1]>=0xC0) and (msg[1]<=0xCF) then
    msg_type = xMidiMessage.TYPE.PROGRAM_CHANGE
    msg_channel = msg[1]-0xBF
    msg_values[1] = msg[2] -- program

  elseif (msg[1]>=0xD0) and (msg[1]<=0xDF) then
    msg_type = xMidiMessage.TYPE.CH_AFTERTOUCH
    msg_channel = msg[1]-0xCF
    msg_values[1] = msg[2] -- pressure

  elseif (msg[1]>=0xE0) and (msg[1]<=0xEF) then
    -- standard or multibyte pitch bend message
    msg_type = xMidiMessage.TYPE.PITCH_BEND
    msg_channel = msg[1]-0xDF

    local fingerprint = self:_create_fingerprint(msg_type,{msg})

    if self.multibyte_enabled and
      (msg[2] >= 0) and (msg[3] == 0) 
    then

      -- ### deal with 14-bit pitch-bend messages
      -- check if     0xEX,0x00,0x00 (initiate)
      -- followed by  0xEX,0xYY,0x00 (MSB byte)
      -- and          0xEX,0xYY,0x00 (LSB byte, final value)

      if (msg[2] == 0) and not self._mb_messages[fingerprint] then
        -- possible multibyte pitch-bend initiated
        self._mb_messages[fingerprint] = {
          timestamp = os.clock(),
          channel = msg_channel,
          type = msg_type,
          lsb = nil,
          msb = nil,
          port_name = port_name,
        }
        return
      else
        -- check for previous msg
        local lsb_message = self._mb_messages[fingerprint]
        if (lsb_message) then
          if (lsb_message.port_name ~= port_name) then
            -- Message looked like multibyte PB, but origin is different
          else
            if (lsb_message.timestamp < os.clock()- self.timeout) then
              -- pitchbend too old - purge from list
              return
            end
            -- previous initiated, receive MSB part
            if not lsb_message.msb then
              lsb_message.msb = msg[2]
              return
            end
            -- receive final LSB part
            -- received 14 bit pitch bend message
            lsb_message.lsb = msg[2]
            msg_values[1] = xMidiMessage.merge_mb(lsb_message.msb,lsb_message.lsb)
            msg_bit_depth = xMidiMessage.BIT_DEPTH.FOURTEEN
            self._mb_messages[fingerprint] = nil
          end
        end
      end
      -- ### end multibyte message

    else
      -- received 7 bit pitch bend message
      self._mb_messages[fingerprint] = nil
      msg_values[1] = msg[2] -- LSB
      msg_values[2] = msg[3] -- MSB
    end

  elseif (msg[1]==0xF1) then
    msg_type = xMidiMessage.TYPE.MTC_QUARTER_FRAME
    msg_values[1] = msg[2] -- time code

  elseif (msg[1]==0xF2) then
    msg_type = xMidiMessage.TYPE.SONG_POSITION
    msg_values[1] = msg[2] -- LSB
    msg_values[2] = msg[3] -- MSB

  else
    LOG("Unrecognized MIDI message: "..cLib.serialize_table(msg))
  end

  self.callback_fn(xMidiMessage{
    message_type = msg_type,
    channel = msg_channel,
    values = msg_values,
    bit_depth = msg_bit_depth,
    port_name = port_name,
  })


end

---------------------------------------------------------------------------------------------------
-- [Class] Create MIDI 'fingerprint' for the provided message(s)
-- (just enough information to identify the CC/NRPN source)
-- @param msg_type
-- @param midi_msgs
-- @return string

function xMidiInput:_create_fingerprint(msg_type,midi_msgs)
  --TRACE("xMidiInput:_create_fingerprint()",msg_type,midi_msgs)

  local rslt = nil
  if (msg_type == xMidiMessage.TYPE.NRPN) then
    -- memorize the first two parts of an NRPN message
    rslt = string.format("%x,%x,%x,%x,%x,%x",
      midi_msgs[1][1],midi_msgs[1][2],midi_msgs[1][3],
      midi_msgs[2][1],midi_msgs[2][2],midi_msgs[2][3])
  elseif (msg_type == xMidiMessage.TYPE.CONTROLLER_CHANGE) then
    -- memorize the channel and number
    rslt = string.format("%x,%x",midi_msgs[1][1],midi_msgs[1][2])
  elseif (msg_type == xMidiMessage.TYPE.PITCH_BEND) then
    -- memorize the channel
    rslt = string.format("%x",midi_msgs[1][1])
  end

  return rslt


end

---------------------------------------------------------------------------------------------------
-- [Class] Convenience method for adding messages to the exempt list

function xMidiInput:add_multibyte_exempt(msg_type,msgs)

  local fingerprint = self:_create_fingerprint(msg_type,msgs)
  table.insert(self._multibyte_exempted,fingerprint)

end

---------------------------------------------------------------------------------------------------
--- [Class] Idle loop : process (or discard) multibyte messages, 
--  output messages which got delayed due to throttling

function xMidiInput:on_idle()
  --TRACE("xMidiInput:on_idle()")

  local clk = os.clock()

  if (#self._nrpn_messages > 0) then
    for k,v in ripairs(self._nrpn_messages) do
      if v and (v.timestamp < (clk- (self.timeout/2))) then
        if (v.data_msb and not v.data_lsb) then
          -- process timed-out NRPN message without LSB part
          self.callback_fn(xMidiMessage{
            message_type = xMidiMessage.TYPE.NRPN,
            channel   = v.channel,
            values = {
              xMidiMessage.merge_mb(v.num_msb,v.num_lsb),
              v.data_msb,
            },
            bit_depth = xMidiMessage.BIT_DEPTH.SEVEN,
            port_name = v.port_name,
          })
          table.remove(self._nrpn_messages,k)
        elseif (v.num_msb and not v.num_lsb) then
          -- CC#99 that timed out is treated as a normal CC message
          self.callback_fn(xMidiMessage{
            message_type = xMidiMessage.TYPE.CONTROLLER_CHANGE,
            channel   = v.channel,
            values = {
              0x63,
              v.data_msb,
            },
            bit_depth = xMidiMessage.BIT_DEPTH.SEVEN,
            port_name = v.port_name,
          })
          table.remove(self._nrpn_messages,k)

        else
          -- discarding old message
          table.remove(self._nrpn_messages,k)
        end
      end
    end
  end

  for k,v in pairs(self._mb_messages) do
    if (v.timestamp < (clk - self.timeout)) then
      -- detected timed-out multibyte message
      local mb_msg = table.rcopy(v)
      self._mb_messages[k] = nil
      if (v.type == xMidiMessage.TYPE.CONTROLLER_CHANGE) then
        -- likely timed-out multibyte CC message in the range 0-31
        -- (to avoid this, we can either disable multibyte support entirely,
        -- or add it to the list of exempted multibyte sources)
        self.callback_fn(xMidiMessage{
          message_type = xMidiMessage.TYPE.CONTROLLER_CHANGE,
          channel   = mb_msg.channel,
          values = {mb_msg.num,mb_msg.msb},
          port_name = v.port_name,
          bit_depth = xMidiMessage.BIT_DEPTH.SEVEN,
        })
      elseif (v.type == xMidiMessage.TYPE.PITCH_BEND) then
        -- timed-out: treat possible multibyte pitch-bend message as 7bit
        self.callback_fn(xMidiMessage{
          message_type = v.type,
          channel = v.channel,
          values = {0,0},
          bit_depth = xMidiMessage.BIT_DEPTH.SEVEN,
          port_name = v.port_name,
        })

      else
        -- other message types?
        LOG("*** timed out multibyte message with no handler",v)
      end
    end
  end

end

