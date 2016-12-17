--[[============================================================================
xNoteCapture
============================================================================]]--

--[[--

Methods for capturing notes in pattern editor
.
#

The class works on a specific note-column in a specific track. Strictly 
speaking it doesn't capture notes, but rather, looks for instrument numbers. 

Note: if you are looking for traditional auto-capture (which will set the 
instrument but not tell you from where), use xInstrument.autocapture()

]]

class 'xNoteCapture'

-------------------------------------------------------------------------------
-- capture the note at the current position, or previous
-- if no previous is found, find the next one
-- @param pos (xNotePos)
-- @return xNotePos or nil if not matched

function xNoteCapture.nearest(notepos)
  TRACE("xNoteCapture.nearest(notepos)",notepos)

  if not notepos then
    notepos = xNotePos()
  end

  print(">>> got here 1 nearest")
  local column,err = notepos:get_column()
  print(">>> column,err",column,err)
  if column and (column.instrument_value < 255) then
    return notepos
  else
    print(">>> got here 2 previous")
    local prev_pos = xNoteCapture.previous(notepos)
    if prev_pos then
      return prev_pos
    else
      print(">>> got here 3 next")
      return xNoteCapture.next(notepos)
    end
  end

end

-------------------------------------------------------------------------------
-- capture the previous note, starting from (but not including) pos
-- @param notepos (xNotePos)
-- @param end_seq_idx (int)[optional], stop searching at this sequence index 
-- @return xNotePos or nil if not matched

function xNoteCapture.previous(notepos,end_seq_idx)
  TRACE("xNoteCapture.previous(notepos,end_seq_idx)",notepos,end_seq_idx)

  notepos = xNotePos(notepos)

  local matched = false
  local min_seq_idx = end_seq_idx or 1
  notepos.line = notepos.line-1 

  while not matched do
    print(">>> xNoteCapture.previous - search this sequence",notepos.sequence)
    local match = xNoteCapture.search_track_reverse(notepos)
    if match then
      print(">>> xNoteCapture.previous - matched here")
      return match
    else
      notepos.sequence = notepos.sequence-1
      if (notepos.sequence < min_seq_idx) then
        return
      end  
      local patt_idx = rns.sequencer:pattern(notepos.sequence)      
      local patt = rns.patterns[patt_idx]
      if (patt) then
        notepos.line = patt.number_of_lines 
      else
        return
      end
    end
  end

end

-------------------------------------------------------------------------------
-- capture the next note, starting from (but not including) pos
-- @param notepos (xNotePos)
-- @param end_seq_idx (int)[optional], stop searching at this sequence index 
-- @return xNotePos or nil if not matched

function xNoteCapture.next(notepos,end_seq_idx)
  TRACE("xNoteCapture.next(notepos,end_seq_idx)",notepos,end_seq_idx)

  notepos = xNotePos(notepos)

  local matched = false
  local max_seq_idx = end_seq_idx or #rns.sequencer.pattern_sequence
  notepos.line = notepos.line+1 

  while not matched do
    local match = xNoteCapture.search_track(notepos)
    if match then
      return match
    else
      notepos.sequence = notepos.sequence+1
      if (notepos.sequence > max_seq_idx) then
        return
      end  
      local patt_idx = rns.sequencer:pattern(notepos.sequence)      
      local patt = rns.patterns[patt_idx]
      if (patt) then
        notepos.line = 1 
      else
        return
      end
    end
  end

end

-------------------------------------------------------------------------------
-- forward search in track
-- @param pos (xNotePos)
-- @return xNotePos or nil if not matched

function xNoteCapture.search_track(notepos)
  TRACE("xNoteCapture.search_track(notepos)",notepos)

  notepos = xNotePos(notepos)

  local visible_only = true 
  local iter = rns.pattern_iterator:note_columns_in_track(notepos.track, visible_only)  
  for pos, column in iter do
    if (pos.column ~= notepos.column) then
      -- do nothing
    elseif (pos.line < notepos.line) then
      -- not there yet
    else
      if (column.instrument_value < 255) then
        notepos.line = pos.line
        return notepos
      end
    end
  end
end

-------------------------------------------------------------------------------
-- reverse iteration: remember each match and continue until notepos 
-- TODO optimize by chunking into smaller segments (lines_in_range)
-- @param pos (xNotePos)
-- @return xNotePos or nil if not matched

function xNoteCapture.search_track_reverse(notepos)
  TRACE("xNoteCapture.search_track_reverse(notepos)",notepos)

  notepos = xNotePos(notepos)

  local visible_only = true   
  local iter = rns.pattern_iterator:note_columns_in_track(notepos.track, visible_only)
  local match = nil  
  for pos, column in iter do
    if (pos.column ~= notepos.column) then
      -- do nothing
    else
      if (column.instrument_value < 255) then
        TRACE("*** found potential match",pos)
        match = pos.line
      end
      if (pos.line == notepos.line) then
        notepos.line = match
        return notepos
      end

    end
  end

end

