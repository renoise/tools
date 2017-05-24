--[[===============================================================================================
xNoteColumn
===============================================================================================]]--

--[[--

A virtual representation of renoise.NoteColumn.

#

Unlike the renoise.NoteColumn, this one can be freely defined, without 
the need to have the line present somewhere in an actual song 

You create an instance by feeding it a descriptive table in the constructor.
All string-based values are automatically converted into their numeric
counterparts. 

]]

--=================================================================================================

class 'xNoteColumn'

--- number, representing an empty note 
xNoteColumn.EMPTY_NOTE_VALUE = 121

--- string, representing an empty note
xNoteColumn.EMPTY_NOTE_STRING = "---"

--- number, representing a note-off
xNoteColumn.NOTE_OFF_VALUE = 120

--- string, representing a note-off
xNoteColumn.NOTE_OFF_STRING = "OFF"

--- number, representing an empty column 
xNoteColumn.EMPTY_VOLUME_VALUE = 255

--- string, representing an empty column 
xNoteColumn.EMPTY_COLUMN_STRING = ".."

--- table, list of available note-column properties 
xNoteColumn.tokens = {
    "note_value","note_string", 
    "instrument_value","instrument_string",
    "volume_value","volume_string",
    "panning_value","panning_string",
    "delay_value","delay_string",
    "effect_number_value","effect_number_string",
    "effect_amount_value","effect_amount_string",
}

--- table, properties that can be used when writing to pattern
xNoteColumn.output_tokens = {
    "note_value", 
    "instrument_value",
    "volume_value",
    "panning_value",
    "delay_value",
    "effect_number_value",
    "effect_amount_value",
}

--- table, list of note-names (without the octave part)
xNoteColumn.NOTE_ARRAY = {
  "C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"
}

-------------------------------------------------------------------------------
-- [Constructor] Accepts a table with properties as argument
-- @param args (table), descriptor

function xNoteColumn:__init(args)

  --- note_value [number, 0-119, 120=Off, 121=Empty]
  self.note_value = property(self.get_note_value,self.set_note_value)
  self._note_value = nil

  --- note_string [string, 'C-0'-'G-9', 'OFF' or '---']
  self.note_string = property(self.get_note_string,self.set_note_string)
  self._note_string = nil

  --- instrument_value [number, 0-254, 255==Empty]
  self.instrument_value = property(self.get_instrument_value,self.set_instrument_value)
  self._instrument_value = nil

  --- instrument_string [string, '00'-'FE' or '..']
  self.instrument_string = property(self.get_instrument_string,self.set_instrument_string)
  self._instrument_string = nil

  --- volume_value
  --  [number, 0-127, 255==Empty when column value is <= 0x80 or is 0xFF,
  --    i.e. is used to specify volume]
  --  [number, 0-65535 in the form 0x0000xxyy where
  --    xx=effect char 1 and yy=effect char 2,
  --    when column value is > 0x80, is used to specify an effect]
  self.volume_value = property(self.get_volume_value,self.set_volume_value)
  self._volume_value = nil

  --- volume string [string, '00'-'ZF' or '..']
  self.volume_string = property(self.get_volume_string,self.set_volume_string)
  self._volume_string = nil
  
  --- panning_value
  --  [number, 0-127, 255==Empty when column value is <= 0x80 or is 0xFF,
  --    i.e. is used to specify pan]
  --  [number, 0-65535 in the form 0x0000xxyy where
  --    xx=effect char 1 and yy=effect char 2,
  --    when column value is > 0x80, i.e. is used to specify an effect]
  self.panning_value = property(self.get_panning_value,self.set_panning_value)
  self._panning_value = nil

  --- panning_string [string, '00'-'ZF' or '..']
  self.panning_string = property(self.get_panning_string,self.set_panning_string)
  self._panning_string = nil

  --- delay_value [number, 0-255]
  self.delay_value = property(self.get_delay_value,self.set_delay_value)
  self._delay_value = nil

  --- delay_string [string, '00'-'FF' or '..']
  self.delay_string = property(self.get_delay_string,self.set_delay_string)
  self._delay_string = nil

  --- effect_number_value [number, 0-255]
  self.effect_number_value = property(self.get_effect_number_value,self.set_effect_number_value)
  self._effect_number_value = nil

  --- effect_number_string [string, '00'-'FF' or '..']
  self.effect_number_string = property(self.get_effect_number_string,self.set_effect_number_string)
  self._effect_number_string = nil

  --- effect_amount_value [number, 0-255]
  self.effect_amount_value = property(self.get_effect_amount_value,self.set_effect_amount_value)
  self._effect_amount_value = nil

  --- effect_amount_string [string, '00'-'FF' or '..']
  self.effect_amount_string = property(self.get_effect_amount_string,self.set_effect_amount_string)
  self._effect_amount_string = nil

  
  -- initialize (apply values) ----------------------------

  for token,value in pairs(args) do
    if (table.find(xNoteColumn.tokens,token)) then
      self[token] = value
    end
  end

end



-------------------------------------------------------------------------------
-- Get/set methods
-------------------------------------------------------------------------------

function xNoteColumn:get_note_value()
  return self._note_value
end

function xNoteColumn:set_note_value(val)
  self._note_value = val
  self._note_string = xNoteColumn.note_value_to_string(val)
end

function xNoteColumn:get_note_string()
  return self._note_string
end

function xNoteColumn:set_note_string(str)
  self._note_string = string.upper(str)
  self._note_value = xNoteColumn.note_string_to_value(str)
end

-------------------------------------------------------------------------------

function xNoteColumn:get_instrument_value()
  return self._instrument_value
end

function xNoteColumn:set_instrument_value(val)
  self._instrument_value = val
  self._instrument_string = xNoteColumn.instr_value_to_string(val) 
end

function xNoteColumn:get_instrument_string()
  return self._instrument_string
end

function xNoteColumn:set_instrument_string(str)
  self._instrument_string = str
  self._instrument_value = xNoteColumn.instr_string_to_value(str)
end

-------------------------------------------------------------------------------

function xNoteColumn:get_volume_value()
  return self._volume_value
end

function xNoteColumn:set_volume_value(val)
  self._volume_value = val
  self._volume_string = xNoteColumn.column_value_to_string(val,"..") 
end

function xNoteColumn:get_volume_string()
  return self._volume_string
end

function xNoteColumn:set_volume_string(str)
  self._volume_string = str
  self._volume_value = xNoteColumn.column_string_to_value(str,xLinePattern.EMPTY_VALUE)
end

-------------------------------------------------------------------------------

function xNoteColumn:get_panning_value()
  return self._panning_value
end

function xNoteColumn:set_panning_value(val)
  self._panning_value = val
  self._panning_string = xNoteColumn.column_value_to_string(val,"..") 
end

function xNoteColumn:get_panning_string()
  return self._panning_string
end

function xNoteColumn:set_panning_string(str)
  self._panning_string = str
  self._panning_value = xNoteColumn.column_string_to_value(str,xLinePattern.EMPTY_VALUE)
end

-------------------------------------------------------------------------------

function xNoteColumn:get_delay_value()
  return self._delay_value
end

function xNoteColumn:set_delay_value(val)
  self._delay_value = val
  self._delay_string = xNoteColumn.delay_value_to_string(val,"..") 
end

function xNoteColumn:get_delay_string()
  return self._delay_string
end

function xNoteColumn:set_delay_string(str)
  self._delay_string = str
  self._delay_value = xNoteColumn.delay_string_to_value(str,xLinePattern.EMPTY_VALUE)
end

-------------------------------------------------------------------------------

function xNoteColumn:get_effect_number_value()
  return self._effect_number_value
end

function xNoteColumn:set_effect_number_value(val)
  self._effect_number_value = val
  self._effect_number_string = xEffectColumn.number_value_to_string(val)
end

function xNoteColumn:get_effect_number_string()
  return self._effect_number_string
end

function xNoteColumn:set_effect_number_string(str)
  self._effect_number_string = str
  self._effect_number_value = xEffectColumn.number_string_to_value(str)
end

-------------------------------------------------------------------------------

function xNoteColumn:get_effect_amount_value()
  return self._effect_amount_value
end

function xNoteColumn:set_effect_amount_value(val)
  self._effect_amount_value = val
  self._effect_amount_string = xEffectColumn.amount_value_to_string(val)
end

function xNoteColumn:get_effect_amount_string()
  return self._effect_amount_string
end

function xNoteColumn:set_effect_amount_string(str)
  self._effect_amount_string = str
  self._effect_amount_value = xEffectColumn.amount_string_to_value(str)
end

-------------------------------------------------------------------------------
-- Converter methods (static implementation)
-------------------------------------------------------------------------------
-- convert note_string into a numeric value
-- @param str_val (string), for example "C#4" or "---"
-- @return int (value, xNoteColumn.EMPTY_NOTE_VALUE when not matched)
-- @return int (key) or nil 
-- @return int (octave) or nil

function xNoteColumn.note_string_to_value(str_val)
  TRACE("xNoteColumn.note_string_to_value(str_val)",str_val,type(str_val))

  str_val = string.upper(str_val)

  local note = nil
  local octave = nil

  if (str_val == xNoteColumn.NOTE_OFF_STRING) then
    return xNoteColumn.NOTE_OFF_VALUE
  elseif (str_val == xNoteColumn.EMPTY_NOTE_STRING) then
    return xNoteColumn.EMPTY_NOTE_VALUE
  end

  -- use first letter to match note
  local note_part = str_val:sub(0,2)
  for k,v in ipairs(xNoteColumn.NOTE_ARRAY) do
    if (note_part==v) then
      note = k-1
      break
    end
  end
  octave = tonumber((str_val):sub(3))
  if not octave then
    --LOG("WARNING: xNoteColumn - Trying to write invalid note-string:",str_val)
    return xNoteColumn.EMPTY_NOTE_VALUE
  elseif not note then
    --LOG("WARNING: xNoteColumn - Trying to write invalid note-string:",str_val)
    return xNoteColumn.EMPTY_NOTE_VALUE
  else
    return note+(octave*12),note,octave
  end

end

-------------------------------------------------------------------------------

function xNoteColumn.note_value_to_string(val)
  TRACE("xNoteColumn.note_value_to_string(val)",val)

  -- renoise accepts floats
  val = math.floor(val)

  if not val then
    return nil
  elseif (val==120) then
    return xNoteColumn.NOTE_OFF_STRING
  elseif(val==121) then
    return xNoteColumn.EMPTY_NOTE_STRING
  elseif(val==0) then
    return "C-0"
  else
    local oct = math.floor(val/12)
    local note = xNoteColumn.NOTE_ARRAY[(val%12)+1]
    return string.format("%s%s",note,oct)
  end

end

-------------------------------------------------------------------------------
-- @param str (string), e.g. ".." or "1F"
-- @return int (0-255)

function xNoteColumn.instr_string_to_value(str)
  TRACE("xNoteColumn.instr_string_to_value(str)",str)
  return (str == "..") and 255 or tonumber(str)
end

function xNoteColumn.instr_value_to_string(val)
  TRACE("xNoteColumn.instr_value_to_string(val)",val)
  return (val == 255) and ".." or ("%.2X"):format(val)
end

-------------------------------------------------------------------------------
-- @param str (string), e.g. ".." or "1F"
-- @return int (0-255)

function xNoteColumn.delay_string_to_value(str)
  TRACE("xNoteColumn.delay_string_to_value(str)",str)
  return (str == "..") and 0 or tonumber(str)
end
-------------------------------------------------------------------------------
-- @param val (int), between 0-255
-- @return string

function xNoteColumn.delay_value_to_string(val)
  TRACE("xNoteColumn.delay_value_to_string(val)",val)
  return (val == 255) and ".." or ("%.2X"):format(val)
end

-------------------------------------------------------------------------------
-- convert vol/panning into a numeric value
-- (everything above 0x80 is interpreted as an fx command)
-- @param str_val (string), for example "40", "G5" or ".."
-- @param empty (int), the default empty value to return
-- @return int

function xNoteColumn.column_string_to_value(str_val,empty)
  TRACE("xNoteColumn.column_string_to_value(str_val,empty)",str_val,empty)

  if (str_val == "..") then
    return empty
  end

  local numeric = tonumber("0x"..str_val)
  if numeric and (numeric <= 0x80) then
    return numeric --tonumber("0x"..str_val)
  else
    return xNoteColumn.convert_fx_to_value(str_val)
  end

end

-------------------------------------------------------------------------------
-- convert instr/vol/panning into a numeric value
-- @param val (int), 0-127, 255==Empty or 0-65535 when value is > 0x80
-- @param empty (string), the default empty value to return
-- @return value

function xNoteColumn.column_value_to_string(val,empty)
  TRACE("xNoteColumn.column_value_to_string(val,empty)",val,empty)

  if (val == xLinePattern.EMPTY_VALUE) then
    return empty
  end

  local numeric = val <= 0x80
  if numeric then
    return ("%.2X"):format(val)
  else
    return xNoteColumn.convert_fx_to_string(val)
  end

end

-------------------------------------------------------------------------------
-- convert two-character effect string into a numeric value
-- @param str_val (string), for example "G5"
-- @return value or nil

function xNoteColumn.convert_fx_to_value(str_val)
  TRACE("xNoteColumn.convert_fx_to_value(str_val)",str_val)

  local fx_num = string.sub(str_val,1,1)
  local fx_amt = string.sub(str_val,2,2)
  local fx_val = table.find(xLinePattern.EFFECT_CHARS,fx_num)-1
  if fx_val then
    return fx_val*256 + tonumber("0x"..fx_amt)
  end

end


-------------------------------------------------------------------------------
-- convert a numeric value into a two-character effect string
-- @param val (int), for example 4615 ("I7") or 0x80
-- @return string

function xNoteColumn.convert_fx_to_string(val)
  TRACE("xNoteColumn.convert_fx_to_string(val)",val)

  local first = math.floor(val/256)
  local second = val-(first*256)
  return ("%s%X"):format(xLinePattern.EFFECT_CHARS[first+1],second)

end

-------------------------------------------------------------------------------
-- Read method (static implementation)
-------------------------------------------------------------------------------
-- @param note_col (renoise.NoteColumn)
-- @param tokens (table), xStreamModel.tokens
-- @return table 

function xNoteColumn.do_read(note_col,tokens)
  TRACE("xNoteColumn.do_read(note_col,tokens)",note_col,tokens)

  if not tokens then
    tokens = xNoteColumn.tokens
  end

  local rslt = {}
  for _,v in ipairs(tokens) do
    rslt[v] = note_col[v]
  end
  return rslt

end

-------------------------------------------------------------------------------
-- Write methods
-------------------------------------------------------------------------------
-- @param note_col (renoise.NoteColumn), 
-- @param tokens (table), xStreamModel.output_tokens
-- @param clear_undefined (bool) clear existing data when ours is nil

function xNoteColumn:do_write(note_col,tokens,clear_undefined)
  TRACE("xNoteColumn.do_write(note_col,tokens,clear_undefined)",note_col,tokens,clear_undefined)

  if not tokens then
    tokens = xNoteColumn.output_tokens
  end

  for _,token in ipairs(tokens) do
    if self["do_write_"..token] then
      local success = pcall(function()
        self["do_write_"..token](self,note_col,clear_undefined)
      end)
      if not success then
        LOG("WARNING: xNoteColumn - Trying to write invalid value to property:",token,self[token])
      end
    end
  end

end

-------------------------------------------------------------------------------

function xNoteColumn:do_write_note_value(note_col,clear_undefined)
  if self.note_value then 
    note_col.note_value = self.note_value
  elseif clear_undefined then
    note_col.note_value = xNoteColumn.EMPTY_NOTE_VALUE
  end
end
function xNoteColumn:do_write_note_string(note_col,clear_undefined)
  if self.note_string then 
    note_col.note_string = self.note_string
  elseif clear_undefined then
    note_col.note_string = xNoteColumn.EMPTY_NOTE_STRING
  end
end

-------------------------------------------------------------------------------

function xNoteColumn:do_write_instrument_value(note_col,clear_undefined)
  if self.instrument_value then 
    note_col.instrument_value = self.instrument_value
  elseif clear_undefined then
    note_col.instrument_value = xLinePattern.EMPTY_VALUE
  end
end
function xNoteColumn:do_write_instrument_string(note_col,clear_undefined)
  if self.instrument_string then 
    note_col.instrument_string = self.instrument_string
  elseif clear_undefined then
    note_col.instrument_string = xNoteColumn.EMPTY_COLUMN_STRING
  end
end

-------------------------------------------------------------------------------

function xNoteColumn:do_write_volume_value(note_col,clear_undefined)
  if self.volume_value then 
    note_col.volume_value = self.volume_value
  elseif clear_undefined then
    note_col.volume_value = xLinePattern.EMPTY_VALUE
  end
end
function xNoteColumn:do_write_volume_string(note_col,clear_undefined)
  if self.volume_string then 
    note_col.volume_string = self.volume_string
  elseif clear_undefined then
    note_col.volume_string = xNoteColumn.EMPTY_COLUMN_STRING
  end
end

-------------------------------------------------------------------------------

function xNoteColumn:do_write_panning_value(note_col,clear_undefined)
  if self.panning_value then 
    note_col.panning_value = self.panning_value
  elseif clear_undefined then
    note_col.panning_value = xLinePattern.EMPTY_VALUE
  end
end
function xNoteColumn:do_write_panning_string(note_col,clear_undefined)
  if self.panning_string then 
    note_col.panning_string = self.panning_string
  elseif clear_undefined then
    note_col.panning_string = xNoteColumn.EMPTY_COLUMN_STRING
  end
end

-------------------------------------------------------------------------------

function xNoteColumn:do_write_delay_value(note_col,clear_undefined)
  if self.delay_value then 
    note_col.delay_value = self.delay_value
  elseif clear_undefined then
    note_col.delay_value = 0
  end
end
function xNoteColumn:do_write_delay_string(note_col,clear_undefined)
  if self.delay_string then 
    note_col.delay_string = self.delay_string
  elseif clear_undefined then
    note_col.delay_string = xNoteColumn.EMPTY_COLUMN_STRING
  end
end

-------------------------------------------------------------------------------

function xNoteColumn:do_write_effect_number_value(note_col,clear_undefined)
  if self.effect_number_value then 
    note_col.effect_number_value = self.effect_number_value
  elseif clear_undefined then
    note_col.effect_number_value = 0
  end
end
function xNoteColumn:do_write_effect_number_string(note_col,clear_undefined)
  if self.effect_number_string then 
    note_col.effect_number_string = self.effect_number_string
  elseif clear_undefined then
    note_col.effect_number_string = xLinePattern.EMPTY_STRING
  end
end

-------------------------------------------------------------------------------

function xNoteColumn:do_write_effect_amount_value(note_col,clear_undefined)
  if self.effect_amount_value then 
    note_col.effect_amount_value = self.effect_amount_value
  elseif clear_undefined then
    note_col.effect_amount_value = 0
  end
end

function xNoteColumn:do_write_effect_amount_string(note_col,clear_undefined)
  if self.effect_amount_string then 
    note_col.effect_amount_string = self.effect_amount_string
  elseif clear_undefined then
    note_col.effect_amount_string = xLinePattern.EMPTY_STRING
  end
end

-------------------------------------------------------------------------------

function xNoteColumn:__tostring()

  return type(self)
    ..", note="..tostring(self.note_string)
    ..", instrument="..tostring(self.instrument_string)
    ..", volume_string="..tostring(self.volume_string)
    ..", panning="..tostring(self.panning_string)
    ..", delay="..tostring(self.delay_string)
    ..", effect_number="..tostring(self.effect_number_string)
    ..", effect_amount="..tostring(self.effect_amount_string)

end
