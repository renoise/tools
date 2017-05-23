--[[============================================================================
xMidiMessage
============================================================================]]--

--[[--

An extended MIDI message.

##

The syntax expands upon the standard 3 bytes of a MIDI message, 
making it possible to pass around data with higher resolution 

### Test
  ability to cache a message once turned into raw MIDI, 
  (change it only as message properties are modified via setters)

### Requires
@{xMessage} 

]]


-------------------------------------------------------------------------------


class 'xMidiMessage' (xMessage)

-- register
xMidiMessage.TYPE = {
  SYSEX = "sysex",
  NRPN = "nrpn",
  NRPN_INCREMENT = "nrpn_increment",
  NRPN_DECREMENT = "nrpn_decrement",
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

xMidiMessage.BIT_DEPTH = {
  SEVEN = 7,
  FOURTEEN = 14,
}

xMidiMessage.MODE = {
  ABS = "abs",
  ABS_7 = "abs_7",
  ABS_14 = "abs_14",
  REL_7_SIGNED = "rel_7_signed",
  REL_7_SIGNED2 = "rel_7_signed2",
  REL_7_OFFSET = "rel_7_offset",
  REL_7_TWOS_COMP = "rel_7_twos_comp",
  REL_14_MSB = "rel_14_msb",
  REL_14_OFFSET = "rel_14_offset",
  REL_14_TWOS_COMP = "rel_14_twos_comp",
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

xMidiMessage.NRPN_ORDER = {
  MSB_LSB = 1, -- 0x63 followed by 0x62
  LSB_MSB = 2, -- 0x62 followed by 0x63
}

xMidiMessage.DEFAULT_BIT_DEPTH = xMidiMessage.BIT_DEPTH.SEVEN
xMidiMessage.DEFAULT_CHANNEL = 0
xMidiMessage.DEFAULT_PORT_NAME = "Unknown port"
xMidiMessage.DEFAULT_NRPN_ORDER = xMidiMessage.NRPN_ORDER.MSB_LSB

-------------------------------------------------------------------------------

function xMidiMessage:__init(...)

	local args = cLib.unpack_args(...)

  --- xMidiMessage.TYPE (required)
  -- default to sysex - a neutral default when converting from OSC
  self.message_type = property(self.get_message_type,self.set_message_type)
  self._message_type = args.message_type or xMidiMessage.TYPE.SYSEX

  --- int, between 0-16 
  -- 0 should be interpreted as 'undefined' 
  self.channel = property(self.get_channel,self.set_channel)
  self._channel = args.channel or xMidiMessage.DEFAULT_CHANNEL

  --- xMidiMessage.BIT_DEPTH, indicates a multibyte message
  --  (only relevant for CC messages, as they can otherwise be ambivalent)
  self.bit_depth = property(self.get_bit_depth,self.set_bit_depth)
  self._bit_depth = args.bit_depth or xMidiMessage.DEFAULT_BIT_DEPTH

  --- xMidiMessage.MODE, more detailed information about message
  -- (this property can be set, TODO: auto-detect)
  self.mode = args.mode 

  --- string, source/target port
  self.port_name = args.port_name or xMidiMessage.DEFAULT_PORT_NAME

  --- xMidiMessage.NRPN_ORDER
  self.nrpn_order = args.nrpn_order or xMidiMessage.NRPN_ORDER.MSB_LSB

  --- boolean, whether to terminate NRPNs (output)
  self.terminate_nrpns = args.terminate_nrpns or xMidiMessage.DEFAULT_NRPN_ORDER

  -- initialize --

  -- if the mode has not been explicitly set, provide fallback
  -- (using absolute mode for the relevant number of bits)
  if not self.mode then
    if (self.bit_depth == xMidiMessage.BIT_DEPTH.SEVEN) then
      self.mode = xMidiMessage.MODE.ABS_7
    elseif (self.bit_depth == xMidiMessage.BIT_DEPTH.FOURTEEN) then
      self.mode = xMidiMessage.MODE.ABS_14
    end
  end

  xMessage.__init(self,...)


end

-------------------------------------------------------------------------------
-- xMessage
-------------------------------------------------------------------------------

function xMidiMessage:get_definition()

  local def = xMessage.get_definition(self)
  def.message_type = self.message_type
  def.channel = self.channel
  def.bit_depth = self.bit_depth
  def.port_name = self.port_name
  
  return def

end

-------------------------------------------------------------------------------
-- xMidiMessage
-------------------------------------------------------------------------------

function xMidiMessage:get_message_type()
  return self._message_type
end

function xMidiMessage:set_message_type(val)
  -- TODO check if one of the allowed types
  self._message_type = val
  self._raw_cache = nil
end

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

function xMidiMessage:get_bit_depth()
  return self._bit_depth
end

function xMidiMessage:set_bit_depth(val)
  self._bit_depth = val
  self._raw_midi_cache = nil
end

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

        -- build NRPN message (MSB/LSB order applies)...
        --  0xBX,0x63,0xYY  (X = Channel, Y = NRPN Number MSB)
        --  0xBX,0x62,0xYY  (X = Channel, Y = NRPN Number LSB)
        --  0xBX,0x06,0xYY  (X = Channel, Y = Data Entry MSB)
        --  0xBX,0x26,0xYY  (X = Channel, Y = Data Entry LSB)

        local num_msb,num_lsb = xMidiMessage.split_mb(self.values[1])
        local val_msb,val_lsb = xMidiMessage.split_mb(self.values[2])

        local msb_first = (self.nrpn_order == xMidiMessage.NRPN_ORDER.MSB_LSB)
        local num_msb_t = {0xAF + self.channel,0x63, num_msb}
        local num_lsb_t = {0xAF + self.channel,0x62, num_lsb}
        local val_msb_t = {0xAF + self.channel,0x06, val_msb}
        local val_lsb_t = {0xAF + self.channel,0x26, val_lsb}

        local rslt = {
          msb_first and num_msb_t or num_lsb_t,
          msb_first and num_lsb_t or num_msb_t,
          --msb_first and val_msb_t or val_lsb_t,
        }

        if self.bit_depth == xMidiMessage.BIT_DEPTH.SEVEN then
          table.insert(rslt,val_msb_t)
        else
          table.insert(rslt,msb_first and val_msb_t or val_lsb_t)
          table.insert(rslt,msb_first and val_lsb_t or val_msb_t)
        end

        -- optionally, when 'terminate_nrpn' is specified...
        --  0xBX,0x65,0x7F  (X = Channel)
        --  0xBX,0x64,0x7F  (X = Channel)

        if self.terminate_nrpns then
          local terminate_msb = {0xAF + self.channel,0x65,0x7F}
          local terminate_lsb = {0xAF + self.channel,0x64,0x7F}
          table.insert(rslt,msb_first and terminate_msb or terminate_lsb)
          table.insert(rslt,msb_first and terminate_lsb or terminate_msb)
        end

        return rslt

      end,

      [xMidiMessage.TYPE.NRPN_DECREMENT] = function()

        local num_msb,num_lsb = xMidiMessage.split_mb(self.values[1])
        local val_msb = xMidiMessage.split_mb(self.values[2])

        return {{
          {0xAF + self.channel,0x63,num_msb},
          {0xAF + self.channel,0x62,num_msb},
          {0xAF + self.channel,0x61,val_msb},
        }}

      end,

      [xMidiMessage.TYPE.NRPN_INCREMENT] = function()

        local num_msb,num_lsb = xMidiMessage.split_mb(self.values[1])
        local val_msb = xMidiMessage.split_mb(self.values[2])

        return {{
          {0xAF + self.channel,0x63,num_msb},
          {0xAF + self.channel,0x62,num_msb},
          {0xAF + self.channel,0x60,val_msb},
        }}

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
      error("Cound not convert message, unrecognized type"
        ..tostring(self.message_type))
    else
      local raw_midi = converters[self.message_type]()
      self._raw_midi_cache = raw_midi
      return raw_midi
    end
  end

end

-------------------------------------------------------------------------------

function xMidiMessage:__tostring()
  return type(self)
  ..": message_type="..tostring(self.message_type)
  ..", ch="..tostring(self.channel)
  ..", values[1]="..tostring(self.values[1])
  ..", values[2]="..tostring(self.values[2])
  ..", bits="..tostring(self.bit_depth)
  ..", port="..tostring(self.port_name)
  ..", track="..tostring(self.track_index)
  ..", instr="..tostring(self.instrument_index)
  ..", column="..tostring(self.note_column_index)

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

