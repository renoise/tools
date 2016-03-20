--[[============================================================================
xMidiMessage
============================================================================]]--
--[[

	A higher-level MIDI message, as employed by various xLib classes

  The syntax expands upon the standard 3 bytes of a MIDI message, 
  making it possible to pass around data with higher resolution 

  # Test
    ability to cache a message once turned into raw MIDI, 
    (change it only as message properties are modified via setters)

  # See also:
    xMidiInput (for creating xMidiMessages)

]]


-------------------------------------------------------------------------------


class 'xMidiMessage' (xMessage)

-- register
xMidiMessage.TYPE = {
  SYSEX = "sysex",
  NRPN = "nrpn",
  NOTE_ON = "note_on",
  NOTE_OFF = "note_off",
  KEY_AFTERTOUCH = "key_aftertouch",
  CONTROLLER_CHANGE = "controller_change",
  PROGRAM_CHANGE = "program_change",
  CH_AFTERTOUCH = "ch_aftertouch",
  PITCH_BEND = "pitch_bend",
  MTC_QUARTER_FRAME = "mtc_quarter_frame",
  SONG_POSITION = "song_position",
  --RPN = "rpn",
}

-- for display, first two bytes
xMidiMessage.VALUE_LABELS = {
  --SYSEX = {"sysex","not_used"}, -- can be any number of bytes... 
  NRPN = {"number","value"},
  NOTE_ON = {"note","velocity"},
  NOTE_OFF = {"note","velocity"},
  KEY_AFTERTOUCH = {"note","pressure"},
  CONTROLLER_CHANGE = {"number","value"},
  PROGRAM_CHANGE = {"number","not_used"},
  CH_AFTERTOUCH = {"number","not_used"},
  PITCH_BEND = {"fine","coarse"},
  SONG_POSITION = {"fine","coarse"},
  MTC_QUARTER_FRAME = {"mtc_time_code","not_used"},
  --RPN = "rpn",
}

xMidiMessage.BIT_DEPTH = {
  SEVEN = 7,
  FOURTEEN = 14,
}

-------------------------------------------------------------------------------
-- Class Methods
-------------------------------------------------------------------------------

function xMidiMessage:__init(...)
  TRACE("xMidiMessage:__init(...)")

	local args = xLib.unpack_args(...)
  --print("args",rprint(args))

  -- TODO feed raw MIDI message as argument (same as OscMessage)

  -- xMidiMessage.TYPE
  self.message_type = property(self.get_message_type,self.set_message_type)
  self._message_type = args.message_type

  -- int, between 0-16 
  -- 0 should be interpreted as 'undefined' 
  self.channel = property(self.get_channel,self.set_channel)
  self._channel = args.channel 

  -- xMidiMessage.BIT_DEPTH, indicates a multibyte message
  --  (only relevant for CC messages, as they can otherwise be ambivalent)
  self.bit_depth = property(self.get_bit_depth,self.set_bit_depth)
  self._bit_depth = args.bit_depth or xMidiMessage.BIT_DEPTH.SEVEN

  -- string, source/target port
  self.port_name = args.port_name or "Unknown port"

  -- initialize --

  xMessage.__init(self,...)


end

-------------------------------------------------------------------------------

function xMidiMessage:get_message_type()
  return self._message_type
end

function xMidiMessage:set_message_type(val)
  TRACE("xMidiMessage:set_message_type",val)
  -- TODO check if one of the allowed types
  self._message_type = val
  self._raw_cache = nil
end

--[[
function xMidiMessage:convert_type(val)
  -- TODO same as 'set' but will reinterpret values 
  -- complex stuff!! 
end
]]


-------------------------------------------------------------------------------

function xMidiMessage:get_channel()
  return self._channel
end

function xMidiMessage:set_channel(val)
  assert(val,"No value was provided")
  assert(val > -1,"Channel needs to be greater than 0")
  assert(val < 16,"Channel needs to 16 or less")
  self._channel = val
  self._raw_midi_cache = nil
end

-------------------------------------------------------------------------------
--[[
function xMidiMessage:get_value1()
  return self._value1
end

function xMidiMessage:set_value1(val)
  --TRACE("xMidiMessage:set_value1",val)
  -- TODO fit within bit depth
  self._value1 = val
  self._raw_midi_cache = nil
end

-------------------------------------------------------------------------------

function xMidiMessage:get_value2()
  return self._value2
end

function xMidiMessage:set_value2(val)
  -- TODO fit within bit depth
  self._value2 = val
  self._raw_midi_cache = nil
end
]]
-------------------------------------------------------------------------------

function xMidiMessage:get_bit_depth()
  return self._bit_depth
end

function xMidiMessage:set_bit_depth(val)
  self._bit_depth = val
  self._raw_midi_cache = nil
end

--[[
function xMidiMessage:convert_bit_depth(val)
  -- TODO same as 'set' but will keep/scale the current value
end
]]

-------------------------------------------------------------------------------
-- Class Methods
-------------------------------------------------------------------------------

-- produce a raw MIDI message from an xMidiMessage (cached)
-- @return table<table> (table, as we might return a multi-byte message)
function xMidiMessage:create_raw_message()
  --TRACE("xMidiMessage:create_raw_message()")

  if self._raw_midi_cache then
    -- not modified, just return the cached message
    return self._raw_midi_cache
  else

    local converters = {

      [xMidiMessage.TYPE.NOTE_ON] = function()
        return {{
          0x8F + self.channel,
          self.values[1],
          self.values[2]
        }}
      end,

      [xMidiMessage.TYPE.NOTE_OFF] = function()
        return {{
          0x7F + self.channel,
          self.values[1],
          self.values[2]
        }}
      end,

      [xMidiMessage.TYPE.KEY_AFTERTOUCH] = function()
        return {{
          0x9F + self.channel,
          self.values[1],
          self.values[2]
        }}
      end,

      [xMidiMessage.TYPE.CONTROLLER_CHANGE] = function()
        if (self.bit_depth == xMidiMessage.BIT_DEPTH.SEVEN) then
          return {{
            0xAF + self.channel,
            self.values[1],
            self.values[2],
          }}
        elseif (self.bit_depth == xMidiMessage.BIT_DEPTH.FOURTEEN) then
          local msb,lsb = self.split_mb(self.values[2])
          --print("msb,lsb",msb,lsb)
          return {
            {
              0xAF + self.channel,
              self.values[1],
              msb,
            },
            {
              0xAF + self.channel,
              self.values[1]+32,
              lsb,
            }  
          }
        else
          error("Unsupported bit depth")
        end
      end,

      [xMidiMessage.TYPE.PROGRAM_CHANGE] = function()
        return {{
          0xBF + self.channel,
          self.values[1],
          0
        }}
      end,

      [xMidiMessage.TYPE.CH_AFTERTOUCH] = function()
        return {{
          0xCF + self.channel,
          self.values[1],  
          0
        }}
      end,

      [xMidiMessage.TYPE.PITCH_BEND] = function()

        if (self.bit_depth == xMidiMessage.BIT_DEPTH.SEVEN) then
          return {{
            0xDF + self.channel,
            self.values[1],  -- LSB
            self.values[2]   -- MSB
          }}

        elseif (self.bit_depth == xMidiMessage.BIT_DEPTH.FOURTEEN) then

          local msb,lsb = self.split_mb(self.values[1])
          return {
            {0xDF + self.channel,0,0},
            {0xDF + self.channel,msb,0},
            {0xDF + self.channel,lsb,0},
          }

        else
          error("Unsupported bit depth")
        end

      end,

      [xMidiMessage.TYPE.NRPN] = function()

        -- ### build NRPN message
        --  0xBX,0x63,0xYY  (X = Channel, Y = NRPN Number MSB)
        --  0xBX,0x62,0xYY  (X = Channel, Y = NRPN Number LSB)
        --  0xBX,0x06,0xYY  (X = Channel, Y = Data Entry MSB)
        --  0xBX,0x26,0xYY  (X = Channel, Y = Data Entry LSB)

        local num_msb,num_lsb = xMidiMessage.split_mb(self.values[1])
        local val_msb,val_lsb = xMidiMessage.split_mb(self.values[2])

        local rslt = {
          {0xAF + self.channel,0x63,num_msb},
          {0xAF + self.channel,0x62,num_lsb},
          {0xAF + self.channel,0x06,val_msb},
        }

        if self.bit_depth ~= xMidiMessage.BIT_DEPTH.SEVEN then
          table.insert(rslt,{0xAF + self.channel,0x26,val_lsb})        
        end

        -- TODO optionally, when 'terminate_nrpn' is specified...
        --  0xBX,0x65,0x7F  (X = Channel)
        --  0xBX,0x64,0x7F  (X = Channel)

        return rslt

      end,

      [xMidiMessage.TYPE.MTC_QUARTER_FRAME] = function()
        return {{
          0xF2,
          self.values[1],  -- time_code
          0
        }}
      end,

      [xMidiMessage.TYPE.SONG_POSITION] = function()
        return {{
          0xF2,
          self.values[1],  -- LSB
          self.values[2]   -- MSB
        }}
      end,

      [xMidiMessage.TYPE.SYSEX] = function()

        local sysex_msg = table.create()
        sysex_msg:insert(0xF0)
        for _, e in ipairs(self.values) do
          sysex_msg:insert(e)
        end
        sysex_msg:insert(0xF7)
        return sysex_msg

      end,


      --[[

      [xMidiMessage.TYPE.RPN] = function()
        error("Not implemented")
      end,

      ]]

    }

    if not converters[self.message_type] then
      error("Cound not convert message, unrecognized type")
    else
      local raw_midi = converters[self.message_type]()
      self._raw_midi_cache = raw_midi
      return raw_midi
    end
  end

end

-------------------------------------------------------------------------------

function xMidiMessage:get_definition()
  --print("xMidiMessage:get_definition()")

  local def = xMessage.get_definition(self)
  def.message_type = self.message_type
  def.channel = self.channel
  def.bit_depth = self.bit_depth
  def.port_name = self.port_name
  
  return def

end

-------------------------------------------------------------------------------

function xMidiMessage:__tostring()
  return type(self)
  ..": "..tostring(self.message_type)
  ..", ch="..tostring(self.channel)
  ..", data1="..tostring(self.values[1])
  ..", data2="..tostring(self.values[2])
  ..", bits="..tostring(self.bit_depth)
  ..", port="..tostring(self.port_name)
  ..", track="..tostring(self.track_index)
  ..", instr="..tostring(self.instrument_index)

end

-------------------------------------------------------------------------------
-- Static Methods
-------------------------------------------------------------------------------
-- provided with a 14-bit value, we return the MSB/LSB parts

function xMidiMessage.split_mb(val)

  local msb = math.floor(val/0x80)
  local lsb = val - (msb*0x80)
  return msb,lsb

end

-------------------------------------------------------------------------------
-- provided with a 14-bit value, we return the MSB/LSB parts

function xMidiMessage.merge_mb(msb,lsb)
  --return bit.rshift(msb,7) + lsb
  return (msb*0x80) + lsb
end

