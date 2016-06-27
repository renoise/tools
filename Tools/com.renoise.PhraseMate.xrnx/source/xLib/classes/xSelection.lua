--[[============================================================================
xPatternSelection
============================================================================]]--

--[[--

Static methods for working with pattern/phrase/matrix/sequence-selections
.
#

### Pattern-selection 

  {
    start_line,     -- Start pattern line index
    start_track,    -- Start track index
    start_column,   -- Start column index within start_track   
    end_line,       -- End pattern line index
    end_track,      -- End track index
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
-- retrieve pattern-selection for the provided pattern-track
-- @return table (pattern-selection) or bool (false, on error)
-- @return string (error message when failed)

function xSelection.get_pattern_track(seq_idx,trk_idx)
  TRACE("xSelection.get_pattern_track(seq_idx,trk_idx)",seq_idx,trk_idx)
  
  local patt_idx = rns.sequencer:pattern(seq_idx)
  local patt = rns.patterns[patt_idx]
  local track = rns.tracks[trk_idx]
  --print("patt_idx",patt_idx)
  --print("patt",patt)
  --print("track",track)
  if not patt or not track then
    return false, "Could not locate track or pattern"
  end

  local note_cols = track.visible_note_columns
  local fx_cols = track.visible_effect_columns
  local total_cols = note_cols+fx_cols

  return {
    start_line = 1,
    end_line = patt.number_of_lines,
    start_track = trk_idx,
    end_track = trk_idx,
    start_column = 1, 
    end_column = total_cols,
  }

end

-------------------------------------------------------------------------------
-- retrieve the existing pattern selection when valid for a single track
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
-- retrieve the existing matrix selection when valid for a single track
-- @return table (matrix-selection) or bool (false, on error)
-- @return string (error message)
--[[
function xSelection.get_matrix_if_single_track()
  TRACE("xSelection.get_matrix_if_single_track()")
    
  local sel = xSelection.get_matrix_selection()
  --print("sel",rprint(sel))

  if table.is_empty(sel) then
    return false, "No selection is defined in the matrix"
  end

  local track_idx = sel[1].track_index
  for k,v in ipairs(sel) do
    if (v.track_index ~= track_idx) then
      return false, "The selection needs to fit within a single track"
    end
  end

  return sel

end
]]

-------------------------------------------------------------------------------
-- retrieve the matrix selection 
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

