--[[--------------------------------------------------------------------------
TestSequencer.lua
--------------------------------------------------------------------------]]--

do
  
  ----------------------------------------------------------------------------
  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function error")
  end
  
  local function tables_equal(t1, t2)
    if (#t1 ~= #t2) then
      return false
    end
    for i in ipairs(t1) do
      if t1[i] ~= t2[i] then
        return false
      end
    end
    return true
  end
  
  
  -- shortcuts
  
  local song = renoise.song()
  local sequencer = song.sequencer
  
  
  ----------------------------------------------------------------------------
  -- sequence table access
  
  local prev_sequence = sequencer.pattern_sequence

  local sequence = table.create{1,2,3,4}
  sequencer.pattern_sequence = sequence
  assert(tables_equal(sequencer.pattern_sequence, sequence))

    
  -- insert/delete

  sequence:insert(2, 5)
  sequencer:insert_sequence_at(2, 5)
  assert(tables_equal(sequencer.pattern_sequence, sequence))
  
  sequence:insert(#sequence, 6)
  sequencer:insert_sequence_at(#sequencer.pattern_sequence, 6)
  assert(tables_equal(sequencer.pattern_sequence, sequence))
  
  sequence:insert(#sequence + 1, 7)
  sequencer:insert_sequence_at(#sequencer.pattern_sequence + 1, 7)
  assert(tables_equal(sequencer.pattern_sequence, sequence))
  
  assert_error(function()
    sequencer:insert_sequence_at(7, 1001)
  end)
  
  assert_error(function()
    sequencer.pattern_sequence = {}
  end)
  
  assert_error(function()
    sequencer.pattern_sequence = {1001}
  end)
  
  sequence:remove(2)
  sequencer:delete_sequence_at(2)
  assert(tables_equal(sequencer.pattern_sequence, sequence))
  
  sequence:insert(#sequencer.pattern_sequence + 1, 8)
  sequencer:insert_new_pattern_at(#sequencer.pattern_sequence + 1)
  assert(tables_equal(sequencer.pattern_sequence, sequence))
    
  
  -- sequence_pos / current_pattern
  
  assert_error(function()
    song.selected_sequence_index = 0
  end)
  assert_error(function()
    song.selected_sequence_index = 8
  end)
  
  
  song.selected_sequence_index = 5
  assert(song.selected_pattern_index == 4)
  
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
  
  
  -- sort
  
  sequencer:sort()
  assert(tables_equal(sequencer.pattern_sequence, {1,2,3,4,5,6,7}))
  
  
  -- selection range
  
  sequencer.selection_range = {}
  assert(tables_equal(sequencer.selection_range, {0, 0}))
  
  sequencer.selection_range = {1, #sequencer.pattern_sequence}
  assert(tables_equal(sequencer.selection_range,
    {1, #sequencer.pattern_sequence}))
  
  assert_error(function()
    sequencer.selection_range = {1, 1, 1}
  end)
  assert_error(function()
    sequencer.selection_range = {1}
  end)
  
  
  -- sections
  
  for seq = 1, #sequencer.pattern_sequence do  
    sequencer:set_sequence_is_start_of_section(seq, false)
  end
  
  for seq = 1, #sequencer.pattern_sequence do  
    assert(not sequencer:sequence_is_part_of_section(seq))
    assert(not sequencer:sequence_is_start_of_section(seq))
    assert(not sequencer:sequence_is_end_of_section(seq))
  end
  
  assert_error(function()
    sequencer:set_sequence_is_start_of_section(0, true)
  end)
  assert_error(function()
    sequencer:sequence_is_start_of_section(#sequencer.pattern_sequence + 1)
  end)
  
  local sections_changed_count = 0
  function sections_changed()
    sections_changed_count = sections_changed_count + 1  
  end
  
  sequencer:sequence_sections_changed_observable():add_notifier(sections_changed)
  
  sequencer:set_sequence_is_start_of_section(2, true)
  assert(sequencer:sequence_is_start_of_section(2))
  assert(not sequencer:sequence_is_end_of_section(2))
  
  sequencer:set_sequence_is_start_of_section(4, true)
  assert(sequencer:sequence_is_start_of_section(4))
  assert(not sequencer:sequence_is_end_of_section(4))
  
  assert(sequencer:sequence_is_part_of_section(1))
  assert(sequencer:sequence_is_part_of_section(7))
  assert(sequencer:sequence_is_part_of_section(3))
  
  assert(sequencer:sequence_is_end_of_section(3))
  assert(sequencer:sequence_is_end_of_section(7))
  
  
  sequencer:set_sequence_section_name(2, "Wurst")
  assert(sequencer:sequence_section_name(2) == "Wurst")
  
  sequencer:set_sequence_section_name(4, "Grob")
  
  assert(sequencer:sequence_section_name(1) == "Untitled Section")
  
  sequencer:set_sequence_is_start_of_section(2, false)
  
  assert(sections_changed_count == 3)
  sequencer:sequence_sections_changed_observable():remove_notifier(sections_changed)
  
  
  -- slot muting
  
  sequencer:set_track_sequence_slot_is_muted(1, 3, true)
  sequencer:set_track_sequence_slot_is_muted(2, 1, true)
  
  assert(sequencer:track_sequence_slot_is_muted(1, 3))
  assert(sequencer:track_sequence_slot_is_muted(2, 1))
  assert(not sequencer:track_sequence_slot_is_muted(2, 3))
  
  
  -- slot selecting
  
  sequencer:set_track_sequence_slot_is_selected(1, 3, true)
  sequencer:set_track_sequence_slot_is_selected(2, 1, true)
  sequencer:set_track_sequence_slot_is_selected(2, 3, false)
  
  assert(sequencer:track_sequence_slot_is_selected(1, 3))
  assert(sequencer:track_sequence_slot_is_selected(2, 1))
  assert(not sequencer:track_sequence_slot_is_selected(2, 3))

end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()

    
--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
