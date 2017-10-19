--[[===============================================================================================
xLinePattern
===============================================================================================]]--

--[[--

This class represents a 'virtual' renoise.PatternLine
.
#

See also:
@{xLine}
@{xLinePattern}

]]


class 'xLinePattern'

--- enum, defines the available column types 
xLinePattern.COLUMN_TYPES = {
  NOTE_COLUMN = 1,
  EFFECT_COLUMN = 2,
}

--- number, maximum number of note columns 
xLinePattern.MAX_NOTE_COLUMNS = 12

--- number, maximum number of effect columns 
xLinePattern.MAX_EFFECT_COLUMNS = 8

--- number, constant value used for representing empty values 
xLinePattern.EMPTY_VALUE = 255     

--- string, constant value used for representing empty values 
xLinePattern.EMPTY_STRING = "00"

--- table, supported effect characters
xLinePattern.EFFECT_CHARS = {
  "0","1","2","3","4","5","6","7", 
  "8","9","A","B","C","D","E","F", 
  "G","H","I","J","K","L","M","N", 
  "O","P","Q","R","S","T","U","V", 
  "W","X","Y","Z"                  
}

---------------------------------------------------------------------------------------------------
-- [Constructor], accepts two arguments for initializing the class
-- @param note_columns (table, xNoteColumn descriptor)
-- @param effect_columns (table, xEffectColumn descriptor)

function xLinePattern:__init(note_columns,effect_columns)

  --- table<xNoteColumn>
  self.note_columns = table.create()

  --- table<xEffectColumn>
  self.effect_columns = table.create()

  -- initialize -----------------------

  if note_columns then
    for _,v in ipairs(note_columns) do
      self.note_columns:insert(v)
    end
  end

  if effect_columns then
    for _,v in ipairs(effect_columns) do
      self.effect_columns:insert(v)
    end
  end

  self:apply_descriptor(self.note_columns,self.effect_columns)

end

---------------------------------------------------------------------------------------------------
-- [Class] Convert descriptors into class instances (empty tables are left as-is)
-- @param note_columns (xNoteColumn or table)
-- @param effect_columns (xEffectColumn or table)

function xLinePattern:apply_descriptor(note_columns,effect_columns)

  if note_columns then
    for k,note_col in ipairs(note_columns) do
      if (type(note_col) == "table") and
        not table.is_empty(note_col)
      then
        -- convert into xNoteColumn 
        self.note_columns[k] = xNoteColumn(note_col)
      end
    end
    for i = #note_columns+1, #self.note_columns do
      self.note_columns[i] = {}
    end
  end
  if effect_columns then
    for k,fx_col in ipairs(effect_columns) do
      if (type(fx_col) == "table") and 
        not table.is_empty(fx_col)
      then
        -- convert into xEffectColumn
        self.effect_columns[k] = xEffectColumn(fx_col)
      end
    end
    for i = #effect_columns+1, #self.effect_columns do
      self.effect_columns[i] = {}
    end

  end

end

---------------------------------------------------------------------------------------------------
-- [Class] Combined method for writing to pattern or phrase
-- @param sequence (int)
-- @param line (int)
-- @param track_idx (int), when writing to pattern
-- @param phrase (renoise.InstrumentPhrase), when writing to phrase
-- @param tokens (table<string>) process these tokens ("note_value", etc)
-- @param include_hidden (bool) apply to hidden columns as well
-- @param expand_columns (bool) reveal columns as they are written to
-- @param clear_undefined (bool) clear existing data when ours is nil

function xLinePattern:do_write(sequence,line,track_idx,phrase,tokens,include_hidden,expand_columns,clear_undefined)

  local rns_line,patt_idx,rns_patt,rns_track,rns_ptrack
  local rns_track_or_phrase

  if track_idx then -- pattern
    rns_line,patt_idx,rns_patt,rns_track,rns_ptrack = 
      xLine.resolve_pattern_line(sequence,line,track_idx)
    rns_track_or_phrase = rns_track
  else -- phrase
    rns_line = xLine.resolve_phrase_line(line)
    rns_track_or_phrase = phrase
  end

  local is_seq_track = (rns_track.type == renoise.Track.TRACK_TYPE_SEQUENCER)

  local visible_note_cols = rns_track_or_phrase.visible_note_columns
  local visible_fx_cols = rns_track_or_phrase.visible_effect_columns

  -- figure out which sub-columns to display (VOL/PAN/DLY)
  if is_seq_track and expand_columns and not table.is_empty(self.note_columns) then
    rns_track_or_phrase.volume_column_visible = rns_track_or_phrase.volume_column_visible or 
      (type(table.find(tokens,"volume_value") or table.find(tokens,"volume_string")) ~= 'nil')
    rns_track_or_phrase.panning_column_visible = rns_track_or_phrase.panning_column_visible or
      (type(table.find(tokens,"panning_value") or table.find(tokens,"panning_string")) ~= 'nil')
    rns_track_or_phrase.delay_column_visible = rns_track_or_phrase.delay_column_visible or
      (type(table.find(tokens,"delay_value") or table.find(tokens,"delay_string")) ~= 'nil')
  end
  
  if is_seq_track then
    self:process_columns(rns_line.note_columns,
      rns_track_or_phrase,
      self.note_columns,
      include_hidden,
      expand_columns,
      visible_note_cols,
      xNoteColumn.output_tokens,
      clear_undefined,
      xLinePattern.COLUMN_TYPES.NOTE_COLUMN)
  else
    if self.note_columns then
      LOG("Can only write note-columns to a sequencer track")
    end
  end

  self:process_columns(rns_line.effect_columns,
    rns_track_or_phrase,
    self.effect_columns,
    include_hidden,
    expand_columns,
    visible_fx_cols,
    xEffectColumn.output_tokens,
    clear_undefined,
    xLinePattern.COLUMN_TYPES.EFFECT_COLUMN)

end

---------------------------------------------------------------------------------------------------
-- [Class] Write to either note or effect column
-- @param rns_columns (array<renoise.NoteColumn>) 
-- @param rns_track_or_phrase (renoise.Track or renoise.InstrumentPhrase) 
-- @param xline_columns (table<xNoteColumn or xEffectColumn>)
-- @param include_hidden (bool) apply to hidden columns as well
-- @param expand_columns (bool) reveal columns as they are written to
-- @param visible_cols (int) number of visible note/effect columns
-- @param tokens (table<string>) process these tokens ("note_value", etc)
-- @param clear_undefined (bool) clear existing data when ours is nil
-- @param col_type (xLinePattern.COLUMN_TYPES)

function xLinePattern:process_columns(
  rns_columns,
  rns_track_or_phrase,
  xline_columns,
  include_hidden,
  expand_columns,
  visible_cols,
  tokens,
  clear_undefined,
  col_type)

	for k,rns_col in ipairs(rns_columns) do
    
    if not expand_columns then
      if not include_hidden and (k > visible_cols) then
        break
      end
    end

    local col = xline_columns[k]
    
    if col then

      if expand_columns 
        and ((type(col)=="xNoteColumn") or (type(col)=="xEffectColumn"))
        or ((type(col) == "table") and not table.is_empty(col))
      then
        if (k > visible_cols) then
          visible_cols = k
        end
      end

      if not include_hidden and (k > visible_cols) then
        break
      end

      -- a table can be the result of a redefined column
      if (type(col) == "table") then
        if (col_type == xLinePattern.COLUMN_TYPES.NOTE_COLUMN) then
          col = xNoteColumn(col)
        elseif (col_type == xLinePattern.COLUMN_TYPES.EFFECT_COLUMN) then
          col = xEffectColumn(col)
        end
      end

      col:do_write(
        rns_col,tokens,clear_undefined)
    else
      if clear_undefined then
        rns_col:clear()
      end
    end
	end

  if (col_type == xLinePattern.COLUMN_TYPES.NOTE_COLUMN) then
    rns_track_or_phrase.visible_note_columns = visible_cols
  elseif (col_type == xLinePattern.COLUMN_TYPES.EFFECT_COLUMN) then
    rns_track_or_phrase.visible_effect_columns = visible_cols
  end

end

---------------------------------------------------------------------------------------------------
-- [Static] Read from pattern, return note/effect-column descriptors 
-- @param rns_line (renoise.PatternLine)
-- @param max_note_cols (int)
-- @param max_fx_cols (int)
-- @return table, note columns
-- @return table, effect columns

function xLinePattern.do_read(rns_line,max_note_cols,max_fx_cols)

  local line_str = tostring(rns_line)
  local note_cols, fx_cols = {}, {}

  local string_sub, start_pos = string.sub

  local note_string_to_value   = xNoteColumn.note_string_to_value
  local instr_string_to_value  = xNoteColumn.instr_string_to_value
  local delay_string_to_value  = xNoteColumn.delay_string_to_value
  local column_string_to_value = xNoteColumn.column_string_to_value
  local number_string_to_value = xEffectColumn.number_string_to_value
  
  for ncol = 1, max_note_cols do

    start_pos = (ncol*18)-17

    local note_string          = string_sub(line_str, start_pos, start_pos+2)
    local instrument_string    = string_sub(line_str, start_pos+3, start_pos+4)
    local volume_string        = string_sub(line_str, start_pos+5, start_pos+6)
    local panning_string       = string_sub(line_str, start_pos+7, start_pos+8)
    local delay_string         = string_sub(line_str, start_pos+9, start_pos+10)
    local effect_number_string = string_sub(line_str, start_pos+11, start_pos+12)
    local effect_amount_string = string_sub(line_str, start_pos+13, start_pos+14)

    note_cols[ncol] = {
      note_string          = note_string,
      instrument_string    = instrument_string,
      volume_string        = volume_string,
      panning_string       = panning_string,
      delay_string         = delay_string,
      effect_number_string = effect_number_string,
      effect_amount_string = effect_amount_string,
      note_value           = note_string_to_value(note_string),
      instrument_value     = instr_string_to_value(instrument_string),
      delay_value          = delay_string_to_value(delay_string),
      volume_value         = column_string_to_value(volume_string),
      panning_value        = column_string_to_value(panning_string),
      effect_number_value  = number_string_to_value(effect_number_string),
      effect_amount_value  = tonumber("0x"..effect_amount_string)
    }

  end

  for fxcol = 1, max_fx_cols do

    start_pos = (fxcol*7)+209

    local number_string = string_sub(line_str, start_pos+3, start_pos+4)
    local amount_string = string_sub(line_str, start_pos, start_pos+2)

    fx_cols[fxcol] = {
      number_string = number_string,
      amount_string = amount_string,
      number_value  = number_string_to_value(number_string),
      amount_value  = tonumber("0x"..amount_string)
    }

  end

  return note_cols, fx_cols

end

---------------------------------------------------------------------------------------------------
-- [Static] Look for a specific type of effect command in line, return all matches
-- (the number of characters in 'fx_type' decides if we search columns or sub-columns)
-- @param track (renoise.Track)
-- @param line (renoise.PatternLine)
-- @param fx_type (number), e.g. "0S" or "B" 
-- @param notecol_idx (number), note-column index
-- @param [visible_only] (boolean), restrict search to visible columns in track 
-- @return table<{
--  index: note/effect column index (across visible columns)
--  value: number 
--  string: string 
-- }>

function xLinePattern.get_effect_command(track,line,fx_type,notecol_idx,visible_only)
  --TRACE("xLinePattern.get_effect_command(track,line,fx_type,notecol_idx,visible_only)")

  assert(type(track)=="Track","Expected renoise.Track as argument")
  assert(type(line)=="PatternLine","Expected renoise.PatternLine as argument")
  assert(type(fx_type)=="string","Expected string as argument")
  assert(type(notecol_idx)=="number","Expected number as argument")

  if (#fx_type == 1) then 
    return xLinePattern.get_effect_subcolumn_command(track,line,fx_type,notecol_idx,visible_only)
  elseif (#fx_type == 2) then 
    return xLinePattern.get_effect_column_command(track,line,fx_type,notecol_idx,visible_only)
  else 
    error("Unexpected effects type")
  end 

  return {}

end

---------------------------------------------------------------------------------------------------
-- [Static] Get effect command using single-digit syntax (sub-column)
-- (look through vol/pan subcolumns in note-columns)

function xLinePattern.get_effect_subcolumn_command(track,line,fx_type,notecol_idx,visible_only)
  TRACE("xLinePattern.get_effect_subcolumn_command(track,line,fx_type,notecol_idx,visible_only)",track,line,fx_type,notecol_idx,visible_only)

    error("Not yet implemented")

end 

---------------------------------------------------------------------------------------------------
-- [Static] Get effect command using two-digit syntax (effect-column)
-- (look through note effect-columns and effect-columns)

function xLinePattern.get_effect_column_command(track,line,fx_type,notecol_idx,visible_only)
  TRACE("xLinePattern.get_effect_column_command(track,line,fx_type,notecol_idx,visible_only)",track,line,fx_type,notecol_idx,visible_only)

  local matches = table.create()
  local col_idx = 1

  if track.sample_effects_column_visible then
    for k,notecol in ipairs(line.note_columns) do
      if visible_only and (k > track.visible_note_columns) then
        break
      else
        if (k == notecol_idx) then 
          if (notecol.effect_number_string == fx_type) then
            matches:insert({
              index = col_idx,
              value = notecol.effect_amount_value,
              string = notecol.effect_amount_string
            })
          end
        end
        col_idx = col_idx + 1
      end
    end
  end 

  for k,fxcol in ipairs(line.effect_columns) do
    if visible_only and (k > track.visible_effect_columns) then 
      break 
    else
      if (fxcol.number_string == fx_type) then
        matches:insert({
          index = col_idx,
          value = fxcol.amount_value,
          string = fxcol.amount_string
        })
      end
      col_idx = col_idx + 1
    end
  end

  return matches 

end 

---------------------------------------------------------------------------------------------------
-- [Static] Get midi command from line
-- (look in last note-column, panning + first effect column)
-- @return xMidiCommand or nil if not found

function xLinePattern.get_midi_command(track,line)
  TRACE("xLinePattern.get_midi_command(track,line)",track,line)

  assert(type(track)=="Track","Expected renoise.Track as argument")
  assert(type(line)=="PatternLine","Expected renoise.PatternLine as argument")

  local note_col = line.note_columns[track.visible_note_columns]
  local fx_col = line.effect_columns[1]

  if note_col.is_empty or fx_col.is_empty then 
    return 
  end 

  -- command number/value needs to be plain numeric 
  local fx_num_val = xEffectColumn.amount_string_to_value(fx_col.number_string)
  if not fx_num_val then 
    return 
  end 

  if (note_col.instrument_value < 255) 
    and (note_col.panning_string:sub(1,1) == "M")
  then
    local msg_type = tonumber(note_col.panning_string:sub(2,2))
    return xMidiCommand{
      instrument_index = note_col.instrument_value+1,
      message_type = msg_type,
      number_value = fx_col.number_value,
      amount_value = fx_col.amount_value,
    }
  end

end

---------------------------------------------------------------------------------------------------
-- [Static] Set midi command (write to pattern)
-- @param track renoise.Track
-- @param line renoise.PatternLine
-- @param cmd xMidiCommand
-- @param [expand] boolean, show target panning/effect-column (default is true)
-- @param [replace] boolean, replace existing commands (default is false - push to side)

function xLinePattern.set_midi_command(track,line,cmd,expand,replace)

  assert(type(track)=="Track","Expected renoise.Track as argument")
  assert(type(line)=="PatternLine","Expected renoise.PatternLine as argument")
  assert(type(cmd)=="xMidiCommand","Expected xMidiCommand as argument")

  expand = expand or true
  replace = replace or false

  local note_col = line.note_columns[track.visible_note_columns]
  local fx_col = line.effect_columns[1]

  -- if there is an existing non-MIDI command, push it to the side 
  -- (insert in next available effect column)
  if not replace and not fx_col.is_empty then 
    local xcmd = xLinePattern.get_midi_command(track,line) 
    if not xcmd then 
      -- only non-numeric effects are pushed to side
      local fx_num_val = xEffectColumn.amount_string_to_value(fx_col.number_string)
      if not fx_num_val then 
        for k = 2, xLinePattern.MAX_EFFECT_COLUMNS do
          local tmp_fx_col = line.effect_columns[k]
          if tmp_fx_col.is_empty then 
            tmp_fx_col.number_value = fx_col.number_value
            tmp_fx_col.amount_value = fx_col.amount_value
            fx_col:clear()
            -- make column visible if needed 
            if expand and (k > track.visible_effect_columns) then
              track.visible_effect_columns = k
            end
            break
          end 
        end 
      end 
    end 
  end

  note_col.instrument_value = cmd.instrument_index-1
  note_col.panning_string = ("M%d"):format(cmd.message_type)
  fx_col.number_value = cmd.number_value
  fx_col.amount_value = cmd.amount_value

  if expand then
    if not track.panning_column_visible then 
      track.panning_column_visible = true
    end
    if (track.visible_effect_columns == 0) then
      track.visible_effect_columns = 1
    end
  end 

end

---------------------------------------------------------------------------------------------------
-- [Static] Clear previously set midi command. 
-- @param track renoise.Track
-- @param line renoise.PatternLine

function xLinePattern.clear_midi_command(track,line)
  TRACE("xLinePattern.clear_midi_command(track,line)",track,line)

  assert(type(track)=="Track","Expected renoise.Track as argument")
  assert(type(line)=="PatternLine","Expected renoise.PatternLine as argument")

  local note_col = line.note_columns[track.visible_note_columns]
  local fx_col = line.effect_columns[1]

  note_col.panning_value = xLinePattern.EMPTY_VALUE
  fx_col.number_value = 0
  fx_col.amount_value = 0

  -- remove instrument if last thing left
  if (note_col.volume_value == xLinePattern.EMPTY_VALUE)
    and (note_col.delay_value == 0)
    and (note_col.note_value == 121)
  then 
    note_col.instrument_value = xLinePattern.EMPTY_VALUE
  end

end


---------------------------------------------------------------------------------------------------

function xLinePattern:__tostring()

  return type(self)
    ..":column#1="..tostring(self.note_columns[1])

end

