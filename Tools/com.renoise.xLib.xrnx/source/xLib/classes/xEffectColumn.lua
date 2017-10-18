--[[===============================================================================================
xEffectColumn
===============================================================================================]]--

--[[--

A virtual representation of renoise.EffectColumn.

#

Unlike the renoise.EffectColumn, this one can be freely defined, without the need to have 
the line present somewhere in the actual song.

You can create an instance by feeding it a descriptive table in the constructor, or by letting 
the class read a specific effect-column (via the method `do_read()`)

Note that all string-based values are automatically converted into numbers, and vice versa. 
Setting the `note_string` and then requesting the `note_value` will yield the same value, 
represented as string or number, respectively. 

]]

--=================================================================================================

class 'xEffectColumn'

--- List of effect-column properties 
xEffectColumn.tokens = {
    "number_value","number_string", 
    "amount_value","amount_string",
}

--- Properties to use when writing to pattern 
xEffectColumn.output_tokens = {
    "number_value", 
    "amount_value",
}

--- List of supported effect commands. <br>Values are represented 
-- in the accompanying table, `xEffectColumn.SUPPORTED_EFFECT_CHARS` 
xEffectColumn.SUPPORTED_EFFECTS = {
  "Axy - Arpeggio", -- `SUPPORTED_EFFECT_CHARS` = 10
  "Bxx - Backwards", -- `SUPPORTED_EFFECT_CHARS` = 11
  "Cxy - Cut Volume", -- `SUPPORTED_EFFECT_CHARS` = 12
  "Dxx - Slide Pitch Down", -- `SUPPORTED_EFFECT_CHARS` = 13
  "Exx - Set Envelope Pos", -- `SUPPORTED_EFFECT_CHARS` = 14
  "Gxx - Glide Note ", -- `SUPPORTED_EFFECT_CHARS` = 16
  "Ixx - Fade Volume In", -- `SUPPORTED_EFFECT_CHARS` = 18
  "Jxx - Track Routing", -- `SUPPORTED_EFFECT_CHARS` = 19
  "Lxx - Set Track Level", -- `SUPPORTED_EFFECT_CHARS` = 21
  "Mxx - Set Note Volume", -- `SUPPORTED_EFFECT_CHARS` = 22
  "Nxy - Set Auto Pan", -- `SUPPORTED_EFFECT_CHARS` = 23
  "Pxx - Set Track Pan", -- `SUPPORTED_EFFECT_CHARS` = 25
  "Qxx - Delay By Ticks", -- `SUPPORTED_EFFECT_CHARS` = 26
  "Rxy - Retrigger Line", -- `SUPPORTED_EFFECT_CHARS` = 27
  "Sxx - Trigger Offset/Slice", -- `SUPPORTED_EFFECT_CHARS` = 28
  "Txy - Set Tremolo", -- `SUPPORTED_EFFECT_CHARS` = 29
  "Uxy - Slide Pitch Up", -- `SUPPORTED_EFFECT_CHARS` = 30
  "Vxy - Set Vibrato", -- `SUPPORTED_EFFECT_CHARS` = 31
  "Wxx - Set Track Width", -- `SUPPORTED_EFFECT_CHARS` = 32
  "Xxx - Stop All Notes", -- `SUPPORTED_EFFECT_CHARS` = 33
  "Yxx - MaYbe Trigger Line", -- `SUPPORTED_EFFECT_CHARS` = 34
  "Zxy - Trigger Phrase", -- -- `SUPPORTED_EFFECT_CHARS` = 35 (API5 ONLY)
}

xEffectColumn.SUPPORTED_EFFECT_CHARS = {
  10,11,12,13,14,16,18,19,21,22,23,25,26,27,28,29,30,31,32,33,34,35       
}

---------------------------------------------------------------------------------------------------
-- [Constructor] accepts a single argument for initializing the class  
-- @param args (table), descriptor

function xEffectColumn:__init(args)

  --- number, 0-255
  self.number_value = property(self.get_number_value,self.set_number_value)
  self._number_value = nil

  --- string, '00'-'FF' or '..'
  self.number_string = property(self.get_number_string,self.set_number_string)
  self._number_string = nil

  --- number, 0-255
  self.amount_value = property(self.get_amount_value,self.set_amount_value)
  self._amount_value = nil

  --- string, '00'-'FF' or '..'
  self.amount_string = property(self.get_amount_string,self.set_amount_string)
  self._amount_string = nil

  for token,value in pairs(args) do
    if (table.find(xEffectColumn.tokens,token)) then
      self[token] = args[token]
    end
  end

end

-- Get/set methods
---------------------------------------------------------------------------------------------------

function xEffectColumn:get_number_value()
  return self._number_value
end

function xEffectColumn:set_number_value(val)
  self._number_value = val
  self._number_string = xEffectColumn.number_value_to_string(val)
end

function xEffectColumn:get_number_string()
  return self._number_string
end

function xEffectColumn:set_number_string(str)
  self._number_string = str
  self._number_value = xEffectColumn.number_string_to_value(str)
end

---------------------------------------------------------------------------------------------------

function xEffectColumn:get_amount_value()
  return self._amount_value
end

function xEffectColumn:set_amount_value(val)
  self._amount_value = val
  self._amount_string = xEffectColumn.amount_value_to_string(val) 
end

function xEffectColumn:get_amount_string()
  return self._amount_string
end

function xEffectColumn:set_amount_string(str)
  self._amount_string = str
  self._amount_value = xEffectColumn.amount_string_to_value(str)
end

---------------------------------------------------------------------------------------------------
-- [Class] Write output to the provided effect-column 
-- @param fx_col (renoise.EffectColumn)
-- @param tokens (table<xStreamModel.output_tokens>)
-- @param clear_undefined (bool)

function xEffectColumn:do_write(fx_col,tokens,clear_undefined)

  for k,token in ipairs(tokens) do
    if self["do_write_"..token] then
      local success = pcall(function()
        self["do_write_"..token](self,fx_col,clear_undefined)
      end)
      if not success then
         LOG("WARNING: xEffectColumn - Trying to write invalid value to property:",token,self[token])
      end
    --else
    --  LOG("WARNING: xEffectColumn - Trying to assign value to non-existing property:",token)
    end
  end

end

---------------------------------------------------------------------------------------------------
-- [Class] Define a function for each possible token (see above)

function xEffectColumn:do_write_number_value(fx_col,clear_undefined)
  --TRACE("xEffectColumn:do_write_number_value(fx_col,clear_undefined)",fx_col,clear_undefined)
  if self.number_value then 
    fx_col.number_value = self.number_value
  elseif clear_undefined then
    fx_col.number_value = 0
  end
end

function xEffectColumn:do_write_number_string(fx_col,clear_undefined)
  --TRACE("xEffectColumn:do_write_number_string(fx_col,clear_undefined)",fx_col,clear_undefined)
  if self.number_string then 
    fx_col.number_string = self.number_string
  elseif clear_undefined then
    fx_col.number_string = xLinePattern.EMPTY_STRING
  end
end

function xEffectColumn:do_write_amount_value(fx_col,clear_undefined)
  --TRACE("xEffectColumn:do_write_amount_value(fx_col,clear_undefined)",fx_col,clear_undefined)
  if self.amount_value then 
    fx_col.amount_value = self.amount_value
  elseif clear_undefined then
    fx_col.amount_value = 0
  end
end

function xEffectColumn:do_write_amount_string(fx_col,clear_undefined)
  --TRACE("xEffectColumn:do_write_amount_string(fx_col,clear_undefined)",fx_col,clear_undefined)
  if self.amount_string then 
    fx_col.amount_string = self.amount_string
  elseif clear_undefined then
    fx_col.amount_string = xLinePattern.EMPTY_STRING
  end
end

---------------------------------------------------------------------------------------------------
-- [Static] Convert number value to string 
-- @param val (number)
-- @return string 

function xEffectColumn.number_value_to_string(val)
  --TRACE("xEffectColumn.number_value_to_string(val)",val)
  local first = math.floor(val/256)
  local str_first = xLinePattern.EFFECT_CHARS[first+1]
  local str_second = xLinePattern.EFFECT_CHARS[val-(first*256)+1]
  if str_first and str_second then
    return str_first..str_second
  else
    error("Unexpected effect number. Expected two bytes between 0-35 respectively")
  end
end

function xEffectColumn.number_string_to_value(str)
  local digit_1 = table.find(xLinePattern.EFFECT_CHARS,string.sub(str,1,1))-1
  local digit_2 = table.find(xLinePattern.EFFECT_CHARS,string.sub(str,2,2))-1
  if digit_1 and digit_2 then
    return digit_1*256 + digit_2
  else
    return 0
  end
end

---------------------------------------------------------------------------------------------------
-- [Static] Convert amount value to string 
-- @param val (number)
-- @return string 

function xEffectColumn.amount_value_to_string(val)
  --TRACE("xEffectColumn.amount_value_to_string(val)",val)
  return ("%.2X"):format(val)
end

function xEffectColumn.amount_string_to_value(str)
  return tonumber("0x"..str)
end

---------------------------------------------------------------------------------------------------
-- [Static] Read from pattern and turn into descriptor 
-- @param fx_col (renoise.EffectColumn)
-- @return table 

function xEffectColumn.do_read(fx_col)
  --TRACE("xEffectColumn.do_read(fx_col)")

  local rslt = {}
  for k,v in ipairs(xEffectColumn.tokens) do
    rslt[v] = fx_col[v]
  end

  return rslt

end


---------------------------------------------------------------------------------------------------

function xEffectColumn:__tostring()

  return "xEffectColumn"

end
