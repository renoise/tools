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
  print("xTrack.next_sequencer_track(wrap_pattern)",wrap_pattern)

  local track_index = rns.selected_track_index
  local master_idx = xTrack.get_master_track_index()
  local matched = false

  repeat
    track_index = track_index+1
    --local track = rns.tracks[track_index]

    if (track_index >= master_idx) then
      print("*** master or send track",track_index)
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
  print("*** next_sequencer_track - set track_index",track_index)
  rns.selected_track_index = track_index
  return true

end

--------------------------------------------------------------------------------
-- navigate to the previous sequencer track (skip other types)
-- @param wrap_pattern

function xTrack.previous_sequencer_track(wrap_pattern)
  print("xTrack.previous_sequencer_track(wrap_pattern)",wrap_pattern)

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
    print("*** track_index,track_type",track_index,track_type)
    if (track_type == renoise.Track.TRACK_TYPE_SEQUENCER) then
      matched = true
    end
  until matched

  print("*** previous_sequencer_track - selected_track_index",rns.selected_track_index)
  print("*** previous_sequencer_track - selected_note_column_index",rns.selected_note_column_index)
  rns.selected_track_index = track_index
  return true

end


