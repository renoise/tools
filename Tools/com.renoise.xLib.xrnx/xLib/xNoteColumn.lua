--[[============================================================================
xNoteColumn
============================================================================]]--
--[[

  This class is representing a single renoise.NoteColumn in xLib. 
  Unlike the renoise.NoteColumn, this one can be freely defined, without 
  the need to have the line present somewhere in an actual song 

  You create an instance by feeding it a descriptive table in the constructor.
  All string-based values are automatically converted into their numeric
  counterpart. 

]]

class 'xNoteColumn'

xNoteColumn.EMPTY_NOTE_VALUE = 121
xNoteColumn.EMPTY_NOTE_STRING = "---"
xNoteColumn.NOTE_OFF_VALUE = 120
xNoteColumn.NOTE_OFF_STRING = "OFF"

xNoteColumn.tokens = {
    "note_value","note_string", 
    "instrument_value","instrument_string",
    "volume_value","volume_string",
    "panning_value","panning_string",
    "delay_value","delay_string",
}

xNoteColumn.NOTE_ARRAY = {
  "C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"
}

-------------------------------------------------------------------------------
-- constructor
-- @param args (table), e.g. {note_value=60,volume_value=40}

function xNoteColumn:__init(args)

  -- if set, attempt to provide a reasonable value
  -- in those cases where a direct assign fails 
  --self.fix_out_of_range_values = true

  for token,value in pairs(args) do
    if (table.find(xNoteColumn.tokens,token)) then
      --print("token,value",token,value)
      -- string values are converted into their value equivalent
      if (string.sub(token,#token-6) == "_string") then
        --print("*** xNoteColumn --> convert string into value",token,value)
        if (token == "note_string") then
          self["note_value"] = 
            xNoteColumn.note_string_to_value(value)
          --print("note_value",self["note_value"])
        elseif (token == "instrument_string") then
          self["instrument_value"] = 
            xNoteColumn.column_string_to_value(value,xLinePattern.EMPTY_VALUE)
        elseif (token == "volume_string") then
          self["volume_value"] = 
            xNoteColumn.column_string_to_value(value,xLinePattern.EMPTY_VALUE)
        elseif (token == "panning_string") then
          self["panning_value"] = 
            xNoteColumn.column_string_to_value(value,xLinePattern.EMPTY_VALUE)
        elseif (token == "delay_string") then
          self["delay_value"] = 
            xNoteColumn.column_string_to_value(value,0)
        end        
        --break
      end
      self[token] = args[token]
    else
      --LOG("WARNING - unsupported property name for xNoteColumn:"..token)
    end
  end


end

-------------------------------------------------------------------------------
-- convert note_string into a numeric value
-- @param str_val (string), for example "C#4" or "---"
-- @return int (value, xNoteColumn.EMPTY_NOTE_VALUE when not matched)
-- @return int (key) or nil 
-- @return int (octave) or nil

function xNoteColumn.note_string_to_value(str_val)
  TRACE("xNoteColumn.note_string_to_value(str_val)",str_val)

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
    return xNoteColumn.EMPTY_NOTE_VALUE
  else
    return note+(octave*12),note,octave
  end

end

-------------------------------------------------------------------------------
-- convert instr/vol/panning into a numeric value
-- @param str_val (string), for example "40", "G5" or ".."
-- @return value

function xNoteColumn.column_string_to_value(str_val,empty)
  TRACE("xNoteColumn.column_string_to_value(str_val)",str_val)

  if (str_val == "..") then
    return empty
  end

  local numeric = tonumber("0x"..str_val)
  if numeric then
    return numeric
  else
    return xNoteColumn.convert_fx_to_value(str_val)
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
  --print("fx_num,fx_amt,fx_val",fx_num,fx_amt,fx_val)
  if fx_val then
    return fx_val*256 + tonumber(fx_amt)
  end

end


-------------------------------------------------------------------------------
-- @param note_col (renoise.NoteColumn)
-- @return table 

function xNoteColumn.do_read(note_col)
  TRACE("xNoteColumn.do_read(note_col)")

  --print(note_col)
  local rslt = {}
  for k,v in ipairs(xNoteColumn.tokens) do
    rslt[v] = note_col[v]
  end
  --print("xNoteColumn.do_read",rprint(rslt))
  return rslt

end

-------------------------------------------------------------------------------
-- @param note_col (renoise.NoteColumn), 
-- @param tokens (table<xStreamModel.output_tokens>)
-- @param clear_undefined (bool) clear existing data when ours is nil

function xNoteColumn:do_write(note_col,tokens,clear_undefined)
  TRACE("xNoteColumn:do_write(note_col,tokens,clear_undefined)",note_col,tokens,clear_undefined)

  for k,token in ipairs(tokens) do
    --print("k,token",k,token)

    -- convert token into a value version
    -- (we converted into values in the constructor)
    --if (string.sub(token,#token-6) == "_string") then
    --end


    if self["do_write_"..token] then
      local success = pcall(function()
        --print("xNoteColumn:do_write",token)
        self["do_write_"..token](self,note_col,clear_undefined)
      end)
      if not success then
        LOG("WARNING: xNoteColumn - Trying to write invalid value to property:",token,self[token])
        --[[
        if not fix_out_of_range then
          LOG("WARNING: xNoteColumn - Trying to write invalid value to property:",token,self[token])
        else
          -- let's just assume that out-of-range errors are unlikely
          -- so we can avoid these expensive checks for every write
          LOG("WARNING: xNoteColumn - Trying to write invalid value, attempting to fix",token,self[token])
          success = pcall(function()
            --print("xNoteColumn:do_write",token)
            self["do_fix_"..token](self,note_col)
          end)
          if not success then
            LOG("WARNING: xNoteColumn - Failed to fix value for property:",token,self[token])
          end
        end
        ]]
      end
    --else
    --  LOG("WARNING: xNoteColumn - Trying to assign value to non-existing property:",token)
    end
  end

end

-------------------------------------------------------------------------------
-- we need a function for each possible token

function xNoteColumn:do_write_note_value(note_col,clear_undefined)
  if self.note_value then 
    note_col.note_value = self.note_value
  elseif clear_undefined then
    note_col.note_value = xNoteColumn.EMPTY_NOTE_VALUE
  end
end
--[[
function xNoteColumn:do_fix_note_value(note_col,clear_undefined)
  if self.note_safe_mode and (self.note_value > 119) then
    note_col.note_value = 119
  elseif (self.note_value > 121) then 
    note_col.note_value = xNoteColumn.EMPTY_NOTE_VALUE
  elseif (self.note_value < 0) then 
    note_col.note_value = 0
  end
end
]]
function xNoteColumn:do_write_note_string(note_col,clear_undefined)
  if self.note_string then 
    --print("xNoteColumn:do_write_note_string - note_string",self.note_string)
    note_col.note_string = self.note_string
  elseif clear_undefined then
    note_col.note_string = xNoteColumn.EMPTY_NOTE_STRING
  end
end

function xNoteColumn:do_write_instrument_value(note_col,clear_undefined)
  if self.instrument_value then 
    note_col.instrument_value = self.instrument_value
  elseif clear_undefined then
    note_col.instrument_value = xLinePattern.EMPTY_VALUE
  end
end
--[[
function xNoteColumn:do_fix_instrument_value(note_col)
  if self.instrument_value > 121 then 
    note_col.instrument_value = xNoteColumn.EMPTY_NOTE_VALUE
  elseif self.instrument_value < 0 then 
    note_col.instrument_value = 0
  end
end
]]
function xNoteColumn:do_write_instrument_string(note_col,clear_undefined)
  if self.instrument_string then 
    note_col.instrument_string = self.instrument_string
  elseif clear_undefined then
    note_col.instrument_string = xLinePattern.EMPTY_STRING
  end
end

function xNoteColumn:do_write_volume_value(note_col,clear_undefined)
  if self.volume_value then 
    note_col.volume_value = self.volume_value
  elseif clear_undefined then
    note_col.volume_value = xLinePattern.EMPTY_VALUE
  end
end
--[[
function xNoteColumn:do_fix_volume_value(note_col)
  if self.volume_value > 128 then 
    note_col.volume_value = 128
  elseif self.volume_value < 0 then 
    note_col.volume_value = 0
  end
end
]]
function xNoteColumn:do_write_volume_string(note_col,clear_undefined)
  if self.volume_string then 
    note_col.volume_string = self.volume_string
  elseif clear_undefined then
    note_col.volume_string = xLinePattern.EMPTY_STRING
  end
end

function xNoteColumn:do_write_panning_value(note_col,clear_undefined)
  if self.panning_value then 
    note_col.panning_value = self.panning_value
  elseif clear_undefined then
    note_col.panning_value = xLinePattern.EMPTY_VALUE
  end
end
--[[
function xNoteColumn:do_fix_panning_value(note_col)
  if self.panning_value > 128 then 
    note_col.panning_value = 128
  elseif self.panning_value < 0 then 
    note_col.panning_value = 0
  end
end
]]
function xNoteColumn:do_write_panning_string(note_col,clear_undefined)
  if self.panning_string then 
    note_col.panning_string = self.panning_string
  elseif clear_undefined then
    note_col.panning_string = xLinePattern.EMPTY_STRING
  end
end

function xNoteColumn:do_write_delay_value(note_col,clear_undefined)
  if self.delay_value then 
    note_col.delay_value = self.delay_value
  elseif clear_undefined then
    note_col.delay_value = 0
  end
end
--[[
function xNoteColumn:do_fix_delay_value(note_col)
  if self.delay_value > 255 then 
    note_col.delay_value = 255
  elseif self.delay_value < 0 then 
    note_col.delay_value = 0
  end
end
]]
function xNoteColumn:do_write_delay_string(note_col,clear_undefined)
  if self.delay_value then 
    note_col.delay_string = self.delay_string
  elseif clear_undefined then
    note_col.delay_string = xLinePattern.EMPTY_STRING 
  end
end

-------------------------------------------------------------------------------

function xNoteColumn:__tostring()

  return "xNoteColumn"

end
