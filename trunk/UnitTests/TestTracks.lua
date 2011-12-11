--[[--------------------------------------------------------------------------
TestTracks.lua
--------------------------------------------------------------------------]]--

do

  ----------------------------------------------------------------------------
  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function error")
  end
  
  
  -- shortcuts
  
  local song = renoise.song()
  
  song.selected_track_index = 1 -- make sure its a player track
  local selected_track = song.tracks[song.selected_track_index]
  
  
  ----------------------------------------------------------------------------
  -- insert/delete/swap
  
  new_track = song:insert_track_at(1)
  new_track:mute()
  
  song:delete_track_at(1)
  
  song:insert_track_at(#song.tracks + 1)
  song:delete_track_at(#song.tracks)
  
  song:swap_tracks_at(1, 2)
  song:swap_tracks_at(1, 2)
  
  song:insert_track_at(#song.tracks + 1)
  
  assert_error(function()
    song:insert_track_at(#song.tracks + 2)
  end)
  
  assert_error(function()
    song:insert_track_at(0)
  end)


  ----------------------------------------------------------------------------
  --mute/unmute/solo
  
  selected_track:mute()
  selected_track:unmute()
  selected_track.mute_state = renoise.Track.MUTE_STATE_ACTIVE
  selected_track.mute_state = renoise.Track.MUTE_STATE_MUTED
  selected_track.mute_state = renoise.Track.MUTE_STATE_OFF
  selected_track:solo()
  
  for _,track in ipairs(song.tracks) do
    track:unmute()
    assert(track.mute_state == renoise.Track.MUTE_STATE_ACTIVE)
  end
  
  
  ----------------------------------------------------------------------------
  -- track color
  
  assert(#selected_track.color == 3)
  selected_track.color = {255, 12, 88}
  assert(selected_track.color[1] == 255)
  assert(selected_track.color[2] == 12)
  assert(selected_track.color[3] == 88)
  
  assert_error(function()
    selected_track.color = {256, 12, 88}
  end)
  assert_error(function()
    selected_track.color = {"255", 12, 88}
  end)
  assert_error(function()
    selected_track.color = {"255", 12}
  end)
  
  
  ----------------------------------------------------------------------------
  -- track types
  
  local seq_tracks = {}
  local master_tracks = {}
  local send_tracks = {}
  local group_tracks = {}
  
  for _,track in ipairs(song.tracks) do
  
    if track.type == renoise.Track.TRACK_TYPE_SEQUENCER then
      seq_tracks[#seq_tracks + 1] = track
  
    elseif track.type == renoise.Track.TRACK_TYPE_MASTER then
      master_tracks[#master_tracks + 1] = track
  
    elseif track.type == renoise.Track.TRACK_TYPE_SEND then
      send_tracks[#send_tracks + 1] = track
  
    elseif track.type == renoise.Track.TRACK_TYPE_GROUP then
      group_tracks[#group_tracks + 1] = track
  
    else
      error("unknown track type")    
    end
  end
  
  assert(#seq_tracks >= 1)
  assert(#group_tracks >= 0)
  assert(#master_tracks == 1)
  assert(#send_tracks >= 0)
  
  assert_error(function()
    master_tracks[1]:mute()
  end)
  
  
  ----------------------------------------------------------------------------
  -- delay
  
  selected_track.output_delay = -20.0
  assert(selected_track.output_delay == -20.0)
  
  seq_tracks[1].output_delay = -10.0
  
  assert_error(function()
    master_tracks[1].output_delay = -10.0
  end)
  
  if #send_tracks then
    assert_error(function()
      send_tracks[1].output_delay = -10.0
    end)
  end
  
  
  ----------------------------------------------------------------------------
  -- routing
  
  local available_routings = seq_tracks[1].available_output_routings
  
  for _,routing in ipairs(available_routings) do
    seq_tracks[1].output_routing = routing
  end
  
  assert(table.find(available_routings, "Master Track") ~= nil)
  seq_tracks[1].output_routing = available_routings[1]
  
  
  ----------------------------------------------------------------------------
  -- columns
  
  assert(seq_tracks[1].min_effect_columns == 0)
  assert(seq_tracks[1].max_effect_columns == 8)
  
  seq_tracks[1].visible_effect_columns = 4
  seq_tracks[1].visible_effect_columns = 0
  
  assert_error(function()
    seq_tracks[1].visible_effect_columns = 9
  end)
  
  master_tracks[1].visible_effect_columns = 4
  master_tracks[1].visible_effect_columns = 1
  
  assert(seq_tracks[1].min_note_columns == 1)
  assert(seq_tracks[1].max_note_columns == 12)
  
  assert(master_tracks[1].min_note_columns == 0)
  assert(master_tracks[1].max_note_columns == 0)
  
  assert_error(function()
    master_tracks[1].volume_column_visible = true
  end)
  
  assert_error(function()
    master_tracks[1].panning_column_visible = true
  end)
  
  assert_error(function()
    master_tracks[1].delay_column_visible = true
  end)
  
  seq_tracks[1].volume_column_visible = true
  assert(seq_tracks[1].volume_column_visible)
  
  seq_tracks[1].panning_column_visible = true
  assert(seq_tracks[1].panning_column_visible)
  
  seq_tracks[1].delay_column_visible = true
  assert(seq_tracks[1].delay_column_visible)
  
  seq_tracks[1].volume_column_visible = true
  seq_tracks[1].panning_column_visible = false
  seq_tracks[1].delay_column_visible = false
  
  
  ----------------------------------------------------------------------------
  -- device_index
  
  song.selected_device_index = 1
  assert(song.selected_device_index == 1)
  
  song.selected_device_index = 0
  assert(song.selected_device_index == 0)


  ----------------------------------------------------------------------------
  -- groups

  new_group = song:insert_group_at(1)
  assert(#new_group.members == 0)

  song:add_track_to_group(2, 1)
  assert(#new_group.members == 1)

  assert(rawequal(new_group.members[1].group_parent, new_group))

  local available_routings = new_group.members[1].available_output_routings
  
  for _,routing in ipairs(available_routings) do
    new_group.members[1].output_routing = routing
  end
  
  assert(available_routings[1] == "Group 02")
  assert(available_routings[2] == "Master Track")

  new_group.group_collapsed = true

  song:delete_group_at(1)

end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
