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
--- get_master_track

function xTrack.get_master_track_index()
  for i,v in pairs(rns.tracks) do
    if v.type == renoise.Track.TRACK_TYPE_MASTER then
      return i
    end
  end
end

--------------------------------------------------------------------------------
--- get_master_track_index

function xTrack.get_master_track()
  for i,v in pairs(rns.tracks) do
    if v.type == renoise.Track.TRACK_TYPE_MASTER then
      return v
    end
  end
end

--------------------------------------------------------------------------------
--- get send track

function xTrack.get_send_track(send_index)
  if (send_index <= rns.send_track_count) then
    local trk_idx = rns.sequencer_track_count + 1 + send_index
    return rns:track(trk_idx)
  else
    return nil
  end
end

--------------------------------------------------------------------------------
-- @param renoise.Track.TRACK_TYPE_xxx
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

function xTrack.determine_track_type(track_index)
  local master_idx = get_master_track_index()
  local tracks = rns.tracks
  if (track_index < master_idx) then
    return renoise.Track.TRACK_TYPE_SEQUENCER
  elseif (track_index == master_idx) then
    return renoise.Track.TRACK_TYPE_MASTER
  elseif (track_index <= #tracks) then
    return renoise.Track.TRACK_TYPE_SEND
  end
end

