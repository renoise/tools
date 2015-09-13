--[[============================================================================
xLine
============================================================================]]--
--[[

	This class is used to describe a single line in the song - including
  patterns, phrases or automation (limited to a single track at a time)


]]

class 'xLine'

-------------------------------------------------------------------------------
-- constructor method
-- @param args (table), can contain the following entries (all optional)
--  note_columns
--  effect_columns
--  automation

function xLine:__init(args)
  print("xLine:__init(args)",args)

  -- xLinePattern
  self.pattern_line = nil

  -- xLineAutomation
  self.automation = nil

  -- initialize -----------------------

  if args.note_columns or args.effect_columns then
    self.pattern_line = xLinePattern(args.note_columns,args.effect_columns)
  end

  if args.automation then
    self.automation = xLineAutomation(args.automation)
  end

  --print("created xLine...")

end

-------------------------------------------------------------------------------
-- write to pattern/phrase/automation - all defined types of data 
-- @param sequence (int)
-- @param line (int)
-- @param track_index (int)
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

  --print("xLine:do_write - clear_undefined",clear_undefined)
  
  -- pattern/phrase
  if self.pattern_line then
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
      sequence,
      line,
      ptrack_auto,
      patt_num_lines)
  end


end

-------------------------------------------------------------------------------
-- @param sequence (int)
-- @param line (int)
-- @param track_index (int), when writing to pattern
-- @param phrase (renoise.InstrumentPhrase)

function xLine:clear_pattern_line(sequence,line,track_idx,phrase)
  TRACE("xLine:clear_pattern_line(sequence,line,track_idx,phrase)",sequence,line,track_idx,phrase)

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

-------------------------------------------------------------------------------
-- read from song, return a descriptive table 
-- @param sequence (int)
-- @param line (int)
-- @param include_hidden (bool),
-- @param track_index (int), when reading from pattern
-- @param phrase (renoise.InstrumentPhrase)
-- @param device_index (int), TODO include automation
-- @param param_index (int), TODO include automation
-- @return table

function xLine.do_read(sequence,line,include_hidden,track_idx,phrase)
  TRACE("xLine.do_read(sequence,line,include_hidden,track_idx,phrase)",sequence,line,include_hidden,track_idx,phrase)

  local rns_line,patt_idx,rns_patt,rns_track,rns_ptrack
  if track_idx then
    rns_line,patt_idx,rns_patt,rns_track,rns_ptrack = xLine.resolve_pattern_line(sequence,line,track_idx) 
  elseif phrase then
    rns_line = xLine.resolve_phrase_line(line,phrase)
  end

  assert(type(rns_line)=="PatternLine","Failed to resolve PatternLine")

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

-------------------------------------------------------------------------------
-- resolve_pattern_line: MUST be valid 
-- @param sequence (int)
-- @param line (int)
-- @param track_idx (int)
-- @return rns_line (renoise.PatternLine)
-- @return patt_idx (int),
-- @return rns_patt (renoise.Pattern)
-- @return rns_track (renoise.Track)
-- @return rns_ptrack (renoise.PatternTrack)

function xLine.resolve_pattern_line(sequence,line,track_idx)
  TRACE("xLine.resolve_pattern_line(sequence,line,track_idx)",sequence,line,track_idx)

  local patt_idx = xSongPos.get_pattern_index(sequence)
  local rns_patt = rns.patterns[patt_idx] 
  local rns_track = rns.tracks[track_idx] 
  assert(rns_patt,"The specied track does not exist")
  local rns_ptrack = rns_patt.tracks[track_idx]
  assert(rns_ptrack,"The specied pattern-track does not exist")
  local rns_line = rns_ptrack:line(line)
  assert(rns_line,"The specied pattern-line does not exist")

  return rns_line,patt_idx,rns_patt,rns_track,rns_ptrack

end

-------------------------------------------------------------------------------
-- resolve_phrase_line: MUST be valid 
-- @param line (int)
-- @return rns_line (renoise.PatternLine)

function xLine.resolve_phrase_line(line,phrase)

  assert(phrase,"The specied phrase does not exist")
  local rns_line = phrase:line(line)
  assert(rns_line,"The specied pattern-line does not exist")

  return rns_line

end

-------------------------------------------------------------------------------

function xLine:__tostring()

  return "xLine:"..tostring(self.pattern_line)..","..tostring(self.automation)

end

