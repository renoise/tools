--[[============================================================================
-- xTrack
============================================================================]]--

--[[--

  Static Methods for working with tracks

--]]

--==============================================================================

class 'xTrack'

--------------------------------------------------------------------------------
--- get_master_track

function xTrack:get_master_track_index()
  for i,v in pairs(renoise.song().tracks) do
    if v.type == renoise.Track.TRACK_TYPE_MASTER then
      return i
    end
  end
end

--------------------------------------------------------------------------------
--- get_master_track_index

function xTrack:get_master_track()
  for i,v in pairs(renoise.song().tracks) do
    if v.type == renoise.Track.TRACK_TYPE_MASTER then
      return v
    end
  end
end

--------------------------------------------------------------------------------
--- get send track

function send_track(send_index)
  if (send_index <= renoise.song().send_track_count) then
    local trk_idx = renoise.song().sequencer_track_count + 1 + send_index
    return renoise.song():track(trk_idx)
  else
    return nil
  end
end

--------------------------------------------------------------------------------
--- get the type of track: sequencer/master/send

function determine_track_type(track_index)
  local master_idx = get_master_track_index()
  local tracks = renoise.song().tracks
  if (track_index < master_idx) then
    return renoise.Track.TRACK_TYPE_SEQUENCER
  elseif (track_index == master_idx) then
    return renoise.Track.TRACK_TYPE_MASTER
  elseif (track_index <= #tracks) then
    return renoise.Track.TRACK_TYPE_SEND
  end
end
