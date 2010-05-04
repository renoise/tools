--[[

This procedure hides empty volume, panning, and delay colums.

]]--

for track_index,track in pairs(renoise.song().tracks) do 
  -- Set some bools
  local found_volume = false
  local found_panning = false
  local found_delay = false
  -- Check whether or not this is a regular track
  if
    track.type ~= renoise.Track.TRACK_TYPE_MASTER and
    track.type ~= renoise.Track.TRACK_TYPE_SEND
  then
    -- Iterate through the regular track
    local iter = renoise.song().pattern_iterator:lines_in_track(track_index)
    for _,line in iter do
      -- Check whether or not the line is empty
      if not line.is_empty then
        -- Check each column on the line
        for _,note_column in ipairs(line.note_columns) do
          -- Check for volume 
          if  note_column.volume_value ~= renoise.PatternTrackLine.EMPTY_VOLUME then
            found_volume = true
          end
          -- Check for panning 
          if note_column.panning_value ~= renoise.PatternTrackLine.EMPTY_PANNING then
            found_panning = true
          end
          -- Check for delay
          if note_column.delay_value ~= renoise.PatternTrackLine.EMPTY_DELAY then
            found_delay = true
          end
        end
        -- If we found something in all three vol, pan, and del
        -- Then there's no point in continuing down the rest of the track 
        -- We break this loop and move on to the next track
        if found_volume and found_panning and found_delay then
          break
        end
      end
    end
    -- Set some properties
    renoise.song().tracks[track_index].volume_column_visible = found_volume
    renoise.song().tracks[track_index].panning_column_visible = found_panning
    renoise.song().tracks[track_index].delay_column_visible = found_delay
  end
end
