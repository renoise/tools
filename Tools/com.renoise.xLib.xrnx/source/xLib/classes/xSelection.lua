--[[============================================================================
xPatternSelection
============================================================================]]--

--[[--

Static methods for working with pattern/phrase/matrix/sequence-selections
.
#

There are three different types of selections. Each one is just a plain 
lua table containing the following values:

### Pattern-selection 

  {
    start_line,     -- Start pattern line index
    start_track,    -- Start track index
    start_column,   -- Start column index within start_track   
    end_line,       -- End pattern line index
    end_track,      -- End track index
    end_column      -- End column index within end_track
  }

### Phrase-selection 

  {
    start_line,     -- Start pattern line index
    start_column,   -- Start column index within start_track   
    end_line,       -- End pattern line index
    end_column      -- End column index within end_track
  }

### Matrix-selection

  {
    [sequence_index] = {
      [track_index] = true,
      [track_index] = true,
    },
    [sequence_index] = {
      [track_index] = true,
      [track_index] = true,
    },
  }

]]

class 'xSelection'

-------------------------------------------------------------------------------
-- [Static] Retrieve selection spanning an entire pattern-track
-- @param seq_idx (int)
-- @param trk_idx (int)
-- @return table (pattern-selection) or bool (false, on error)
-- @return string (error message when failed)

function xSelection.get_pattern_track(seq_idx,trk_idx)
  TRACE("xSelection.get_pattern_track(seq_idx,trk_idx)",seq_idx,trk_idx)
  
  local patt_idx = rns.sequencer:pattern(seq_idx)
  local patt = rns.patterns[patt_idx]
  local track = rns.tracks[trk_idx]
  if not patt or not track then
    return false, "Could not locate track or pattern"
  end

  return {
    start_line = 1,
    start_track = trk_idx,
    start_column = 1, 
    end_line = patt.number_of_lines,
    end_track = trk_idx,
    end_column = track.visible_note_columns + track.visible_effect_columns,
  }

end

-------------------------------------------------------------------------------
-- [Static] Get a selection spanning the provided column 
-- @param seq_idx (int)
-- @param trk_idx (int)
-- @param col_idx (int)
-- @return table (pattern-selection) or bool (false, on error)
-- @return string (error message when failed)

function xSelection.get_pattern_column(seq_idx,trk_idx,col_idx)
  TRACE("xSelection.get_pattern_column(seq_idx,trk_idx,col_idx)",seq_idx,trk_idx,col_idx)
  
  local sel = xSelection.get_pattern_track(seq_idx,trk_idx)
  sel.start_column = col_idx
  sel.end_column = col_idx

  return sel

end

-------------------------------------------------------------------------------
-- [Static] Get existing pattern selection when valid for a single track
-- @return table (pattern-selection) or bool (false, on error)
-- @return string (error message when failed)

function xSelection.get_pattern_if_single_track()
  TRACE("xSelection.get_pattern_if_single_track()")

  local sel = rns.selection_in_pattern

  if not sel then
    return false, "No selection is defined in the pattern"
  end
  
  if (sel.start_track ~= sel.end_track) then
    return false, "The selection needs to fit within a single track"
  end

  return sel

end


-------------------------------------------------------------------------------
-- [Static] Get selection spanning an entire column in a pattern-track
-- @param seq_idx (int)
-- @param trk_idx (int)
-- @param col_idx (int)
-- @return table (pattern-selection) or bool (false, on error)
-- @return string (error message when failed)

function xSelection.get_column_in_track(seq_idx,trk_idx,col_idx)
  TRACE("xSelection.get_column_in_track(seq_idx,trk_idx,col_idx)",seq_idx,trk_idx,col_idx)

  local sel = xSelection.get_pattern_track(seq_idx,trk_idx)
  if not sel then
    return false, "Could not create selection for the pattern-track"
  end

  sel.start_column = col_idx
  sel.end_column = col_idx

  return sel

end

-------------------------------------------------------------------------------
-- [Static] Get selection spanning an entire group in a pattern-track
-- @param seq_idx (int)
-- @param trk_idx (int)
-- @return table (pattern-selection) or bool (false, on error)
-- @return string (error message when failed)

function xSelection.get_group_in_pattern(seq_idx,trk_idx)
  TRACE("xSelection.get_group_in_pattern(seq_idx,trk_idx)",seq_idx,trk_idx)

  -- TODO

end

-------------------------------------------------------------------------------
-- [Static] Get selection spanning the entire selected phrase
-- @return table (Phrase-selection)

function xSelection.get_phrase()

  local phrase = rns.selected_phrase

  if not phrase then
    return false,"Could not retrieve selection, no phrase selected"
  end

  return {
    start_line = 1,    
    start_column = 1,  
    end_line = phrase.number_of_lines,      
    end_column = phrase.visible_note_columns+phrase.visible_effect_columns      
  }

end

-------------------------------------------------------------------------------
-- [Static] Retrieve the matrix selection 
-- @return table<[sequence_index][track_index]>

function xSelection.get_matrix_selection()
  TRACE("xSelection.get_matrix_selection()")

  local sel = {}
  for k,v in ipairs(rns.sequencer.pattern_sequence) do
    sel[k] = {}
    for k2,v2 in ipairs(rns.tracks) do
      if rns.sequencer:track_sequence_slot_is_selected(k2,k) then
        sel[k][k2] = true
      end
    end
    if table.is_empty(sel[k]) then
      sel[k] = nil
    end
  end
  return sel

end

---------------------------------------------------------------------------------------------------
-- [Static] Test if selection is limited to a single column
-- @param patt_sel (table ) 
-- @return bool

function xSelection.is_single_column(patt_sel)
  TRACE("xSelection.is_single_column(patt_sel)",patt_sel)

  return xSelection.is_single_track(patt_sel)
    and (patt_sel.start_column == patt_sel.end_column)

end

---------------------------------------------------------------------------------------------------
-- [Static] Test if selection is limited to a single track
-- @param patt_sel (table ) 
-- @return bool

function xSelection.is_single_track(patt_sel)
  TRACE("xSelection.is_single_track(patt_sel)",patt_sel)

  return (patt_sel.start_track == patt_sel.end_track)

end

---------------------------------------------------------------------------------------------------
-- [Static] Test if selection includes note columns 
-- @param patt_sel (table ) 
-- @return bool

function xSelection.includes_note_columns(patt_sel)

  -- TODO support track-spanning selections
  
  local track = rns.tracks[patt_sel.start_track]
  return (patt_sel.start_column <= track.visible_note_columns)

end

---------------------------------------------------------------------------------------------------
-- [Static] Test if selection spans entire line 
-- @param patt_sel (table) 
-- @param number_of_columns (number)
-- @return bool

function xSelection.spans_entire_line(patt_sel,number_of_columns)
  TRACE("xSelection.spans_entire_line(patt_sel,number_of_columns)",patt_sel,number_of_columns)

  -- TODO

end

