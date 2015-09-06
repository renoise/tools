--[[============================================================================
xNoteColumn
============================================================================]]--
--[[

  This class is representing a single renoise.NoteColumn in xLib
  Unlike the renoise.NoteColumn, this one can be freely defined, 
  without the need to have the line present in an actual song 

  TODO additional instructions: add, sub, mul, div... 

]]

class 'xNoteColumn'

xNoteColumn.tokens = {
    "note_value","note_string", 
    "instrument_value","instrument_string",
    "volume_value","volume_string",
    "panning_value","panning_string",
    "delay_value","delay_string",
}

-------------------------------------------------------------------------------
-- constructor
-- @param args (table), e.g. {note_value=60,volume_value=40}

function xNoteColumn:__init(args)

  for token,value in pairs(args) do
    if (table.find(xNoteColumn.tokens,token)) then
      self[token] = args[token]
    end
  end

end

-------------------------------------------------------------------------------
-- @param note_col (renoise.NoteColumn), 
-- @param tokens (table<xStreamModel.output_tokens>)
-- @param clear_undefined (bool)

function xNoteColumn:do_write(note_col,tokens,clear_undefined)
  TRACE("xNoteColumn:do_write(note_col,tokens,clear_undefined)",note_col,tokens,clear_undefined)

  for k,token in ipairs(tokens) do
    if self["do_write_"..token] then
      local success = pcall(function()
        self["do_write_"..token](self,note_col,clear_undefined)
      end)
      if not success then
        LOG("WARNING: Trying to write invalid value to note column:",token,note_col[token])
      end
    end
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
  --print(rslt.note_string,rslt.note_value)
  return rslt

end

-------------------------------------------------------------------------------
-- we need a function for each possible token

function xNoteColumn:do_write_note_value(note_col,clear_undefined)
  if self.note_value then 
    note_col.note_value = self.note_value
  elseif clear_undefined then
    note_col.note_value = xLinePattern.EMPTY_NOTE_VALUE
  end
end

function xNoteColumn:do_write_note_string(note_col,clear_undefined)
  if self.note_string then 
    note_col.note_string = self.note_string
  elseif clear_undefined then
    note_col.note_string = xLinePattern.EMPTY_NOTE_STRING
  end
end

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
