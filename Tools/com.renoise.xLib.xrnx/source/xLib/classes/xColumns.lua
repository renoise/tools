--[[============================================================================
-- xColumns
============================================================================]]--

--[[--

Static Methods for working with note/effect-columns 
.
#

Requires xTrack

--]]

--==============================================================================

class 'xColumns'

--------------------------------------------------------------------------------
-- TODO test

function xColumns:previous_column()

  local sel_track_index = rns.selected_track_index
  local sel_track = rns.tracks[sel_track_index]

  local note_column_count = sel_track.visible_note_columns
  local effect_column_count = sel_track.visible_effect_columns
  local column_count = note_column_count + effect_column_count

  local new_column_index = 0

  if rns.selected_note_column_index > 0 then
    new_column_index = rns.selected_note_column_index - 1

  elseif rns.selected_effect_column_index > 0 then
    new_column_index = note_column_count +
      rns.selected_effect_column_index - 1
  end

  -- jump to the previous effect column
  if new_column_index >= 1 and
     new_column_index > note_column_count then
    rns.selected_effect_column_index = new_column_index -
      note_column_count

  -- jump to the previous note column
  elseif new_column_index >= 1 then
    rns.selected_note_column_index = new_column_index

  -- jump to the previous effect or note column
  else
    sel_track_index = wrap_value(sel_track_index - 1, 1, #rns.tracks)
    sel_track = rns.tracks[sel_track_index]

    note_column_count = sel_track.visible_note_columns
    effect_column_count = sel_track.visible_effect_columns
    column_count = note_column_count + effect_column_count

    rns.selected_track_index = sel_track_index

    if effect_column_count > 0 then
      rns.selected_effect_column_index = effect_column_count
    else
      rns.selected_note_column_index = note_column_count
    end
  end

end

--------------------------------------------------------------------------------
-- TODO test

function xColumns.next_column()

  local sel_track_index = rns.selected_track_index
  local sel_track = rns.tracks[sel_track_index]

  local note_column_count = sel_track.visible_note_columns
  local effect_column_count = sel_track.visible_effect_columns
  local column_count = note_column_count + effect_column_count

  local new_column_index = 0

  if rns.selected_note_column_index > 0 then
    new_column_index = rns.selected_note_column_index + 1

  elseif rns.selected_effect_column_index > 0 then
    new_column_index = note_column_count +
      rns.selected_effect_column_index + 1
  end

  -- jump to the next note column
  if new_column_index <= note_column_count then
    rns.selected_note_column_index = new_column_index

  -- jump to the next effect column
  elseif new_column_index <= column_count then
    rns.selected_effect_column_index = new_column_index -
      note_column_count

  -- jump to the next tracks note or effect column
  else
    sel_track_index = wrap_value(sel_track_index + 1, 1, #rns.tracks)
    sel_track = rns.tracks[sel_track_index]
    note_column_count = sel_track.visible_note_columns

    rns.selected_track_index = sel_track_index

    if note_column_count > 0 then
      rns.selected_note_column_index = 1
    else
      rns.selected_effect_column_index = 1
    end
  end

end


--------------------------------------------------------------------------------
-- navigate through note-columns - if the track is selected, use the  
-- selected note column as basis (else, the first one...)
-- @param wrap_pattern (bool) 
-- @param wrap_track (bool)
-- @param track_index (number)

function xColumns.next_note_column(wrap_pattern,wrap_track,track_index)
  TRACE("xColumns.next_note_column(wrap_pattern,wrap_track,track_index)",wrap_pattern,wrap_track,track_index)

  if not track_index then
    track_index = rns.selected_track_index
  end

  local track = rns.tracks[track_index]

  local is_sel_track = (rns.selected_track_index == track_index)

  -- enter next track?
  local col_idx = rns.selected_note_column_index
  if is_sel_track then
    col_idx = col_idx+1
    if (col_idx > track.visible_note_columns) then
      col_idx = 1
      if not wrap_track then
        xTrack.next_sequencer_track(wrap_pattern)
      end
    end

  else
    rns.selected_track_index = track_index
    col_idx = 1
  end
  rns.selected_note_column_index = col_idx

end

--------------------------------------------------------------------------------
-- navigate through note-columns - if the track is selected, use the  
-- selected note column as basis (else, the first one...)
-- @param wrap_pattern (bool) 
-- @param wrap_track (bool)
-- @param track_index (number)

function xColumns.previous_note_column(wrap_pattern,wrap_track,track_index)
  TRACE("xColumns.previous_note_column(wrap_pattern,wrap_track,track_index)",track_index,wrap_track,wrap_pattern)

  if not track_index then
    track_index = rns.selected_track_index
  end

  local track = rns.tracks[track_index]

  local is_sel_track = (rns.selected_track_index == track_index)

  local col_idx = rns.selected_note_column_index
  if is_sel_track then
    col_idx = col_idx-1
    if (col_idx < 1) then
      if not wrap_track then
        if xTrack.previous_sequencer_track(wrap_pattern) then
          col_idx = rns.selected_track.visible_note_columns
        end
      else
        col_idx = track.visible_note_columns
      end
    end

  else
    rns.selected_track_index = track_index
    col_idx = 1
  end
  if (col_idx < track.max_note_columns and col_idx > 0) then
    rns.selected_note_column_index = col_idx
  end

end

--------------------------------------------------------------------------------
-- insert #amount of empty columns at 'col_idx' 
-- TODO refactor into xPatternTrack

function xColumns.shift_note_columns(ptrack_or_phrase,col_idx,amount,line_start,line_end)
  TRACE("xColumns.shift_note_columns(ptrack_or_phrase,col_idx,amount,line_start,line_end)",ptrack_or_phrase,col_idx,amount,line_start,line_end)

  local line_rng = ptrack_or_phrase:lines_in_range(line_start,line_end)
  for k,v in ipairs(line_rng) do
    for k2,v2 in ripairs(v.note_columns) do
      if ((k2-amount) >= col_idx)--(k2 <= col_idx+amount) 
        --and (k2 >= col_idx)
      then
        v2:copy_from(v.note_columns[k2-amount])
      end
    end
  end

end

