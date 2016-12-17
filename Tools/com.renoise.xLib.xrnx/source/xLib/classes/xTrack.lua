--[[============================================================================
-- xTrack
============================================================================]]--

--[[--

Static Methods for working with renoise.Tracks objects
.
#

--]]

--==============================================================================

class 'xTrack'

--------------------------------------------------------------------------------
--- get_master_track_index

function xTrack.get_master_track_index()
  for i,v in pairs(rns.tracks) do
    if v.type == renoise.Track.TRACK_TYPE_MASTER then
      return i
    end
  end
end

--------------------------------------------------------------------------------
--- get_master_track

function xTrack.get_master_track()
  for i,v in pairs(rns.tracks) do
    if v.type == renoise.Track.TRACK_TYPE_MASTER then
      return v
    end
  end
end

--------------------------------------------------------------------------------
--- get send track
-- @param send_index (int)

function xTrack.get_send_track(send_index)
  if (send_index <= rns.send_track_count) then
    local trk_idx = rns.sequencer_track_count + 1 + send_index
    return rns:track(trk_idx)
  else
    return nil
  end
end

--------------------------------------------------------------------------------
-- @param track_type (renoise.Track.TRACK_TYPE_xxx)
-- @return int, number of tracks matching the type 

function xTrack.get_track_count(track_type)

  local count=0
  for k,v in ipairs(rns.tracks) do
    if (v.type == track_type) then
      count = count + 1
    end
  end
  return count

end

--------------------------------------------------------------------------------
--- get the group track associated with the provided track 
-- @return number, group track index

function xTrack.get_group_track_index(track_index,match_self)
  TRACE("xTrack.get_group_track_index(track_index)",track_index,match_self)

  local trk = rns.tracks[track_index]
  local group_trk = trk.group_parent

  if not group_trk and (trk.type == renoise.Track.TRACK_TYPE_GROUP) then
    return track_index
  end

  for k,v in ipairs(rns.tracks) do
    if rawequal(v,group_trk) then
      return k
    end
  end

end

--------------------------------------------------------------------------------
--- get the first sequencer-track associated with the provided group 

function xTrack.get_first_sequencer_track_in_group(track_index)
  TRACE("xTrack.get_first_sequencer_track_in_group(track_index)",track_index)

  local group_track = rns.tracks[track_index]
  if (group_track.type ~= renoise.Track.TRACK_TYPE_GROUP) then
    return nil, "Expected a group track as argument"
  end

  for k,v in ipairs(rns.tracks) do
    if rawequal(v.group_parent,group_track) then
      return k
    end
  end

end

--------------------------------------------------------------------------------
--- get the type of track: sequencer/master/send
-- @param track_index (int)

function xTrack.determine_track_type(track_index)

  local master_idx = xTrack.get_master_track_index()
  local tracks = rns.tracks
  if (track_index < master_idx) then
    local track = rns.tracks[track_index]
    return track.type -- renoise.Track.TRACK_TYPE_SEQUENCER
  elseif (track_index == master_idx) then
    return renoise.Track.TRACK_TYPE_MASTER
  elseif (track_index <= #tracks) then
    return renoise.Track.TRACK_TYPE_SEND
  end

end

--------------------------------------------------------------------------------
-- navigate to the next sequencer track (skip other types)
-- @param wrap_pattern

function xTrack.next_sequencer_track(wrap_pattern)
  TRACE("xTrack.next_sequencer_track(wrap_pattern)",wrap_pattern)

  local track_index = rns.selected_track_index
  local master_idx = xTrack.get_master_track_index()
  local matched = false

  repeat
    track_index = track_index+1
    if (track_index >= master_idx) then
      if wrap_pattern then
        track_index = 1
      else
        return
      end
    end
    local track_type = xTrack.determine_track_type(track_index)
    if (track_type == renoise.Track.TRACK_TYPE_SEQUENCER) then
      matched = true
    end
  until matched
  rns.selected_track_index = track_index
  return true

end

--------------------------------------------------------------------------------
-- navigate to the previous sequencer track (skip other types)
-- @param wrap_pattern

function xTrack.previous_sequencer_track(wrap_pattern)
  TRACE("xTrack.previous_sequencer_track(wrap_pattern)",wrap_pattern)

  local track_index = rns.selected_track_index
  local matched = false

  repeat
    track_index = track_index-1
    --local track = rns.tracks[track_index]
    if (track_index == 0) then
      if wrap_pattern then
        track_index = xTrack.get_master_track_index()
      else
        return false
      end
    end
    local track_type = xTrack.determine_track_type(track_index)
    if (track_type == renoise.Track.TRACK_TYPE_SEQUENCER) then
      matched = true
    end
  until matched

  rns.selected_track_index = track_index
  return true

end

--------------------------------------------------------------------------------
-- obtain a specific pattern-track
-- @return PatternTrack or nil (when failed)
-- @return string, error message when failed

function xTrack:get_pattern_track(seq_idx,track_index)

  local patt_idx = rns.sequencer:pattern(seq_idx)
  if not patt_idx then
    return false,"Could not locate pattern"
  end
  local patt = rns.patterns[patt_idx]
  local ptrack = patt:track(track_index)
  if not ptrack then
    return nil,"Could not locate pattern-track"
  end

  return ptrack

end

-------------------------------------------------------------------------------
-- get column_index, based on visible columns 
-- (similar to e.g. renoise.song().selection_in_pattern)

function xTrack.get_selected_column_index()

  if rns.selected_note_column then
    return rns.selected_note_column_index
  else
    local track = rns.selected_track 
    return rns.selected_note_column_index + track.visible_note_columns   
  end
end

-------------------------------------------------------------------------------
-- set column_index, based on visible columns 
-- (similar to e.g. renoise.song().selection_in_pattern)
-- @return string, error message when failed 

function xTrack.set_selected_column_index(track,col_idx)

  if (track.type == renoise.Track.TRACK_TYPE_SEQUENCER) 
    and (track.visible_note_columns >= col_idx) 
  then
    rns.selected_note_column_index = col_idx
  elseif (col_idx < track.visible_note_columns+track.visible_effect_columns) then
    rns.selected_effect_column_index = col_idx-track.visible_note_columns
  else
    return "Can't select this effect column (out of bounds)"
  end 

end


