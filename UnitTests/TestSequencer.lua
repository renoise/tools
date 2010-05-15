--[[--------------------------------------------------------------------------
TestSequencer.lua
--------------------------------------------------------------------------]]--

do
  
  ----------------------------------------------------------------------------
  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function error")
  end
  
  
  -- shortcuts
  
  local song = renoise.song()
  local sequencer = song.sequencer
  
  
  ----------------------------------------------------------------------------
  -- sequence table access
  
  local prev_sequence = sequencer.pattern_sequence
  sequencer.pattern_sequence = {1,2,3,4}
  assert(#sequencer.pattern_sequence == 4)
  assert(sequencer.pattern_sequence[4] == 4)
  
  -- insert/delete
  
  sequencer:insert_sequence_at(1, 5)
  assert(#sequencer.pattern_sequence == 5)
  
  sequencer:insert_sequence_at(#sequencer.pattern_sequence, 6)
  assert(#sequencer.pattern_sequence == 6)
  
  assert_error(function()
    sequencer:insert_sequence_at(6, 1001)
  end)
  
  assert_error(function()
    sequencer.pattern_sequence = {}
  end)
  
  assert_error(function()
    sequencer.pattern_sequence = {1001}
  end)
  
  sequencer:delete_sequence_at(2)
  
  assert(
    sequencer.pattern_sequence[1] == 1 and
    sequencer.pattern_sequence[2] == 2 and
    sequencer.pattern_sequence[3] == 3 and
    sequencer.pattern_sequence[4] == 4 and
    sequencer.pattern_sequence[5] == 6)
    
  
  sequencer:insert_new_pattern_at(#sequencer.pattern_sequence)
  
  assert(
    sequencer.pattern_sequence[1] == 1 and
    sequencer.pattern_sequence[2] == 2 and
    sequencer.pattern_sequence[3] == 3 and
    sequencer.pattern_sequence[4] == 4 and
    sequencer.pattern_sequence[5] == 6 and
    sequencer.pattern_sequence[6] == 7)
    
  
  -- sequence_pos / current_pattern
  
  assert_error(function()
    song.selected_sequence_index = 0
  end)
  assert_error(function()
    song.selected_sequence_index = 7
  end)
  
  
  song.selected_sequence_index = 5
  assert(song.selected_pattern_index == 6)
  
  song.selected_pattern_index = 5
  
  assert_error(function()
    song.selected_pattern_index = 0
  end)
  assert_error(function()
    song.selected_pattern_index = 1001
  end)
  
  
  -- make_range_unique
  
  sequencer:make_range_unique(1, 1)
  sequencer:make_range_unique(1, #sequencer.pattern_sequence)
  
  assert_error(function()
    sequencer:make_range_unique(-2, #sequencer.pattern_sequence)
  end)
  assert_error(function()
    sequencer:make_range_unique(1, #sequencer.pattern_sequence + 1)
  end)
  
  
  -- slot muting
  
  sequencer:set_track_sequence_slot_is_muted(1, 3, true)
  sequencer:set_track_sequence_slot_is_muted(2, 1, true)
  
  assert(sequencer:track_sequence_slot_is_muted(1, 3))
  assert(sequencer:track_sequence_slot_is_muted(2, 1))
  assert(not sequencer:track_sequence_slot_is_muted(2, 3))

end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()

    
--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
