--[[============================================================================
xLinePattern
============================================================================]]--
--[[

  This class is roughly equivalent to renoise.PatternLine, but not bound to 
  any particular pattern or phrase. Instead, you create instances as needed, 
  through the constructor method 

]]


class 'xLinePattern'

xLinePattern.EMPTY_VALUE = 255     
xLinePattern.EMPTY_STRING = "00"
xLinePattern.EFFECT_CHARS = {
  "0","1","2","3","4","5","6","7", 
  "8","9","A","B","C","D","E","F", 
  "G","H","I","J","K","L","M","N", 
  "O","P","Q","R","S","T","U","V", 
  "W","X","Y","Z"                  
}

-------------------------------------------------------------------------------
-- constructor
-- @param note_columns (table<xNoteColumn>)
-- @param effect_columns (table<xEffectColumn>)

function xLinePattern:__init(note_columns,effect_columns)
  TRACE("xLinePattern:__init(note_columns,effect_columns)",note_columns,effect_columns)

  self.note_columns = table.create()
  self.effect_columns = table.create()

  --self.is_empty = property(self.get_is_empty)
  --self._is_empty = true

  -- display columns as they are written to
  --self.auto_expand = true


  -- initialize -----------------------

  if note_columns then
    for k,v in ipairs(note_columns) do
      self.note_columns:insert(xNoteColumn(v))
    end
  end

  if effect_columns then
    for k,v in ipairs(effect_columns) do
      self.effect_columns:insert(xEffectColumn(v))
    end
  end

  --print("xLinePattern.note_columns",rprint(self.note_columns))

end



-------------------------------------------------------------------------------
-- combined method for writing to pattern or phrase
-- @param sequence (int)
-- @param line (int)
-- @param track_index (int), when writing to pattern
-- @param phrase (renoise.InstrumentPhrase), when writing to phrase
-- @param tokens (table<string>) process these tokens ("note_value", etc)
-- @param include_hidden (bool) apply to hidden columns as well
-- @param expand_columns (bool) reveal columns as they are written to
-- @param clear_undefined (bool) clear existing data when ours is nil

function xLinePattern:do_write(sequence,line,track_idx,phrase,tokens,include_hidden,expand_columns,clear_undefined)
  TRACE("xLinePattern:do_write(sequence,line,track_idx,phrase,tokens,include_hidden,expand_columns,clear_undefined)",sequence,line,track_idx,phrase,tokens,include_hidden,expand_columns,clear_undefined)

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
  --print("is_seq_track",is_seq_track)

  local visible_note_cols = rns_track_or_phrase.visible_note_columns
  local visible_fx_cols = rns_track_or_phrase.visible_effect_columns
  --print("visible_note_cols",visible_note_cols)

  -- TODO optimize by moving this into a one-time track preparation
  -- (after the tokens have been extracted and streaming is active)
  if is_seq_track and expand_columns and not table.is_empty(self.note_columns) then
    rns_track_or_phrase.volume_column_visible = rns_track_or_phrase.volume_column_visible or 
      (type(table.find(tokens,"volume_value") or table.find(tokens,"volume_string")) ~= 'nil')
    rns_track_or_phrase.panning_column_visible = rns_track_or_phrase.panning_column_visible or
      (type(table.find(tokens,"panning_value") or table.find(tokens,"panning_string")) ~= 'nil')
    rns_track_or_phrase.delay_column_visible = rns_track_or_phrase.delay_column_visible or
      (type(table.find(tokens,"delay_value") or table.find(tokens,"delay_string")) ~= 'nil')
  end
  
  if is_seq_track then
    for k,rns_col in ipairs(rns_line.note_columns) do
      if not include_hidden and (k > visible_note_cols) then
        break
      end
      local note_col = self.note_columns[k]
      if note_col then
        -- show columns, sub-columns
        if expand_columns then
          if (k > visible_note_cols) then
            visible_note_cols = k
          end
        end
        --print("note_col",note_col,type(note_col))

        -- a table can be the result of a redefined column
        -- convert tables into a xNoteColumn instance
        if (type(note_col) == "table") then
          note_col = xNoteColumn(note_col)
        end

        note_col:do_write(
          rns_col,tokens,clear_undefined)
      else
        --print("clear_undefined",clear_undefined)
        if clear_undefined then
          rns_col:clear()
        end
      end
    end
  else
    if self.note_columns then
      LOG("Can only write note-columns to a sequencer track")
    end
  end

	for k,rns_col in ipairs(rns_line.effect_columns) do
    if not include_hidden and (k > visible_fx_cols) then
      break
    end
    local fx_col = self.effect_columns[k]
    if fx_col then
      if expand_columns and
        (k > visible_fx_cols)
      then
        visible_fx_cols = k
      end
      fx_col:do_write(
        rns_col,tokens,clear_undefined)
    else
      if clear_undefined then
        rns_col:clear()
      end
    end
	end

  rns_track_or_phrase.visible_note_columns = visible_note_cols
  rns_track_or_phrase.visible_effect_columns = visible_fx_cols


end

-------------------------------------------------------------------------------
-- @param rns_line (renoise.PatternLine)
-- @param max_note_cols (int)
-- @param max_fx_cols (int)
-- @return table, note columns
-- @return table, effect columns

function xLinePattern.do_read(rns_line,max_note_cols,max_fx_cols) 
  TRACE("xLinePattern.do_read(rns_line,max_note_cols,max_fx_cols)",rns_line,max_note_cols,max_fx_cols)

  local note_cols = {}
  local fx_cols = {}

  for i = 1, max_note_cols do
    local note_col = rns_line.note_columns[i]
    table.insert(note_cols, xNoteColumn.do_read(note_col))
  end

  for i = 1, max_fx_cols do
    local fx_col = rns_line.effect_columns[i]
    table.insert(fx_cols, xEffectColumn.do_read(fx_col))
  end

  --print("#note_cols",#note_cols,"#fx_cols",#fx_cols)
  return note_cols,fx_cols


end

-------------------------------------------------------------------------------
--[[

function xLinePattern:clear()
  self:__init()
end

-------------------------------------------------------------------------------

function xLinePattern:copy_from(patt_line)
  self:__init(patt_line)
end

-------------------------------------------------------------------------------
-- @param idx (int)
-- return xNoteColumn or nil
function xLinePattern:get_note_column(idx)
  return self.note_columns[idx]
end

-------------------------------------------------------------------------------
-- define a notecolumn, 
-- expand the number of columns if needed? 
-- @param idx (int)
-- @param note_col (xNoteColumn)

function xLinePattern:set_note_column(idx,note_col)
  
end

-------------------------------------------------------------------------------
-- getter/setter
-------------------------------------------------------------------------------

function xLinePattern:get_is_empty()
  return self._is_empty
end

]]

function xLinePattern:__tostring()

  return "xLinePattern "..tostring(self.note_columns[1])

end
