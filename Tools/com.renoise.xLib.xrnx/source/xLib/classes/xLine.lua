--[[===============================================================================================
xLine
===============================================================================================]]--

--[[--

Represents a single line, including note/effect-columns and automation.

## 

The class uses xLinePattern for notes and effect-columns, and xLineAutomation to represent the automation within that line. 

See also:
@{xLinePattern}
@{xLineAutomation}

]]

--=================================================================================================

class 'xLine'

--- table, containing 12 empty tables 
xLine.EMPTY_NOTE_COLUMNS = {
  {},{},{},{},
  {},{},{},{},
  {},{},{},{},
}

--- table, containing 8 empty tables 
xLine.EMPTY_EFFECT_COLUMNS = {
  {},{},{},{},
  {},{},{},{},
}

--- table, containing the following
--    {
--      note_columns = xLine.EMPTY_NOTE_COLUMNS,
--      effect_columns = xLine.EMPTY_EFFECT_COLUMNS,
--    }
xLine.EMPTY_XLINE = {
  note_columns = xLine.EMPTY_NOTE_COLUMNS,
  effect_columns = xLine.EMPTY_EFFECT_COLUMNS,
} 

---------------------------------------------------------------------------------------------------
-- [Constructor] accepts a single argument to use as class initializer
-- @param args (table)

function xLine:__init(args)

  --- xLinePattern
  self.pattern_line = nil

  --- xLineAutomation
  self.automation = nil

  -- initialize -----------------------

  if args.note_columns or args.effect_columns then
    self.pattern_line = xLinePattern(args.note_columns,args.effect_columns)

    -- these tables are used 'outside' the class to access/set values,
    -- will need a call to apply_descriptor() afterwards
    self.note_columns = self.pattern_line.note_columns
    self.effect_columns = self.pattern_line.effect_columns

  end

  if args.automation then
    self.automation = xLineAutomation(args.automation)
  end

end


---------------------------------------------------------------------------------------------------
-- [Class] Write to pattern/phrase/automation - all defined types of data 
-- @param sequence (int)
-- @param line (int)
-- @param track_idx (int)
-- @param phrase (renoise.InstrumentPhrase)
-- @param ptrack_auto (renoise.PatternTrackAutomation)
-- @param patt_num_lines (int), length of the playpos pattern 
-- @param tokens (table<string>)
-- @param include_hidden (bool)
-- @param expand_columns (bool)
-- @param clear_undefined (bool)

function xLine:do_write(
  sequence,
  line,
  track_idx,
  phrase,
  ptrack_auto,
  patt_num_lines,
  tokens,
  include_hidden,
  expand_columns,
  clear_undefined)

  -- pattern/phrase
  if self.pattern_line then
    self.pattern_line.note_columns = self.note_columns
    self.pattern_line.effect_columns = self.effect_columns
    self.pattern_line:do_write(
      sequence,
      line,
      track_idx,
      phrase,
      tokens,
      include_hidden,
      expand_columns,
      clear_undefined)
  elseif clear_undefined then
    self:clear_pattern_line(
      sequence,
      line,
      track_idx,
      phrase)
  end

  -- track automation
  if self.automation and ptrack_auto then
    self.automation:do_write(
      line,
      ptrack_auto,
      patt_num_lines)
  end


end

---------------------------------------------------------------------------------------------------
-- [Class] clear the renoise.PatternLine 
-- TODO refactor to xLinePattern 
-- @param sequence (int)
-- @param line (int)
-- @param track_idx (int), when writing to pattern
-- @param phrase (renoise.InstrumentPhrase)

function xLine:clear_pattern_line(sequence,line,track_idx,phrase)

  local rns_line
  if track_idx then
    rns_line = xLine.resolve_pattern_line(sequence,line,track_idx) 
  elseif phrase then
    rns_line = xLine.resolve_phrase_line(line,phrase)
  end

  if rns_line then
  	rns_line:clear()
  end

end

---------------------------------------------------------------------------------------------------
-- [Static] Resolve a column (note or effect), optionally a similar approach to that
-- used by "selection_in_pattern" - meaning that, if a given line contains
-- two visible note columns and some effect columns then "col_idx=3" will 
-- indicate the first effect column  
-- @param line (renoise.PatternLine)
-- @param col_idx (number)
-- @param track (renoise.Track) 
-- @param visible_only (boolean), default is true
-- @return renoise.NoteColumn/renoise.EffectColumn or nil 

function xLine.get_column(line,col_idx,track,visible_only)
  TRACE("xLine.get_column(line,col_idx,track,visible_only)",line,col_idx,track,visible_only)

  assert(type(line)=="PatternLine","Expected 'PatternLine' as argument")
  assert(type(col_idx)=="number","Expected 'col_idx' to be a number")
  assert(type(track)=="Track" or type(track)=="GroupTrack","Expected 'Track' as argument")

  if not visible_only then
    visible_only = true
  end

  if not visible_only then
    -- UNTESTED
    if (track.max_note_columns > 0) 
      and (col_idx <= track.visible_note_columns)
    then -- sequencer track 
      return line.note_columns[col_idx]
    else -- other track type (group, send, master...)
      return line.effect_columns[col_idx]
    end
  else
    local column = nil
    if (track.max_note_columns > 0)  
      and (col_idx <= track.visible_note_columns) 
    then
      return line.note_columns[col_idx]
    elseif 
      (col_idx <= (track.visible_note_columns + track.visible_effect_columns)) 
    then
      return line.effect_columns[col_idx-track.visible_note_columns]    
    else
      return nil, "Could not resolve column"
    end  
  end

  error("Should not get here")

end

---------------------------------------------------------------------------------------------------
-- [Static] Read from song, return a descriptive table 
-- @param sequence (int)
-- @param line (int)
-- @param include_hidden (bool),
-- @param track_idx (int), when reading from pattern
-- @param phrase (renoise.InstrumentPhrase)
-- TODO @param device_index (int),  include automation
-- TODO @param param_index (int),  include automation
-- @return table

function xLine.do_read(sequence,line,include_hidden,track_idx,phrase)
  TRACE("xLine.do_read(sequence,line,include_hidden,track_idx,phrase)",sequence,line,include_hidden,track_idx,phrase)

  local rns_line,patt_idx,rns_patt,rns_track,rns_ptrack
  if track_idx then
    rns_line,patt_idx,rns_patt,rns_track,rns_ptrack = xLine.resolve_pattern_line(sequence,line,track_idx) 
  elseif phrase then
    rns_line = xLine.resolve_phrase_line(line,phrase)
  end

  if (renoise.API_VERSION > 3) then
    assert(type(rns_line)=="PatternLine","Failed to resolve PatternLine")
  else
    assert(type(rns_line)=="PatternTrackLine","Failed to resolve PatternLine")
  end

  local note_cols,fx_cols,automation

  if rns_line then

    local max_note_cols,max_fx_cols
    if not include_hidden then
      if rns_track then
        max_note_cols = rns_track.visible_note_columns
        max_fx_cols = rns_track.visible_effect_columns
      elseif phrase then
        max_note_cols = phrase.visible_note_columns
        max_fx_cols = phrase.visible_effect_columns
      end
    else
      max_note_cols = renoise.InstrumentPhrase.MAX_NUMBER_OF_NOTE_COLUMNS 
      max_fx_cols = renoise.InstrumentPhrase.MAX_NUMBER_OF_EFFECT_COLUMNS 
    end

    note_cols,fx_cols = xLinePattern.do_read(rns_line,max_note_cols,max_fx_cols)
    --automation = xLineAutomation.do_read()
  end

  return {
    note_columns = note_cols,
    effect_columns = fx_cols,
  }

end

---------------------------------------------------------------------------------------------------
-- [Static] Resolve_pattern_line: MUST be valid 
-- @param sequence (int)
-- @param line (int)
-- @param track_idx (int)
-- @return rns_line (renoise.PatternLine)
-- @return patt_idx (int),
-- @return rns_patt (renoise.Pattern)
-- @return rns_track (renoise.Track)
-- @return rns_ptrack (renoise.PatternTrack)

function xLine.resolve_pattern_line(sequence,line,track_idx)

  local patt_idx = rns.sequencer:pattern(sequence)
  local rns_patt = rns.patterns[patt_idx] 
  local rns_track = rns.tracks[track_idx] 
  assert(rns_patt,"The specied track does not exist")
  local rns_ptrack = rns_patt.tracks[track_idx]
  assert(rns_ptrack,"The specied pattern-track does not exist")
  local rns_line = rns_ptrack:line(line)
  assert(rns_line,"The specied pattern-line does not exist")

  return rns_line,patt_idx,rns_patt,rns_track,rns_ptrack

end

---------------------------------------------------------------------------------------------------
-- [Static] Resolve_phrase_line: MUST be valid 
-- @param line (int)
-- @param phrase (renoise.Phrase)
-- @return rns_line (renoise.PatternLine)

function xLine.resolve_phrase_line(line,phrase)

  assert(phrase,"The specied phrase does not exist")
  local rns_line = phrase:line(line)
  assert(rns_line,"The specied pattern-line does not exist")

  return rns_line

end

---------------------------------------------------------------------------------------------------
-- [Static] Convert descriptors into class instances (empty tables are left as-is)
-- @param xline (xLine or table) will create xLine instance if table 
-- @return xLine 

function xLine.apply_descriptor(xline)
  --TRACE("xLine.apply_descriptor(xline)",xline)

  if (type(xline) == "table") then -- entire xline redefined
    xline = xLine(xline)
  elseif (type(xline) == "xLine") then -- check xLine content
    xline.pattern_line:apply_descriptor(xline.note_columns,xline.effect_columns)
    if not table.is_empty(xline.automation) then
      xline.automation = xLineAutomation(xline.automation)
    end
  else
    error("Unexpected xline type")
  end

  return xline

end


---------------------------------------------------------------------------------------------------

function xLine:__tostring()

  return type(self)
       ..", line="..tostring(self.pattern_line)
       ..", automation="..tostring(self.automation)

end

