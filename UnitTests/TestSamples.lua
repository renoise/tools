--[[--------------------------------------------------------------------------
TestSamples.lua
--------------------------------------------------------------------------]]--

do

  ----------------------------------------------------------------------------
  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function error")
  end
  
  function float_cmp(f1, f2)
    return math.abs(f1 - f2) < 0.0001
  end
  
  
  ----------------------------------------------------------------------------
  -- insert/delete/swap
  
  local song = renoise.song()
  local selected_instrument = song.selected_instrument
  
  selected_instrument:clear() -- test with a empty samples
  
  local new_sample = selected_instrument:insert_sample_at(
    #selected_instrument.samples + 1)
  new_sample.name = "New Sample!"
  
  song.selected_sample_index = #selected_instrument.samples
  assert(song.selected_sample.name == "New Sample!")
  
  selected_instrument:insert_sample_at(#selected_instrument.samples + 1)
  selected_instrument:delete_sample_at(#selected_instrument.samples)
  
  assert_error(function()
    selected_instrument:insert_sample_at(#selected_instrument.samples + 2)
  end)
  
  assert_error(function()
    selected_instrument:insert_sample_at(0)
  end)
  
  selected_instrument:insert_sample_at(1)
  selected_instrument:delete_sample_at(1)
  
  selected_instrument.samples[1].name = "1"
  selected_instrument.samples[2].name = "2"
  selected_instrument:swap_samples_at(1, 2)
  
  assert(selected_instrument.samples[1].name == "2")
  assert(selected_instrument.samples[2].name == "1")
  
  selected_instrument:swap_samples_at(1, 2)
  assert(selected_instrument.samples[1].name == "1")
  assert(selected_instrument.samples[2].name == "2")
  
  selected_instrument:delete_sample_at(#selected_instrument.samples)
  
  
  ----------------------------------------------------------------------------
  -- basic properties
  
  local selected_sample = song.selected_sample
  
  selected_sample.panning = 0.75
  assert(selected_sample.panning == 0.75)
  assert_error(function()
    selected_sample.panning = 1.2 
  end)
  
  selected_sample.volume = 2.25
  
  selected_sample.base_note = 48 + 12
  selected_sample.fine_tune = -127
  
  selected_sample.beat_sync_enabled = false
  selected_sample.beat_sync_lines = 0
  selected_sample.beat_sync_lines = 128
  assert_error(function()
    selected_sample.beat_sync_lines = -1
  end)
  
  selected_sample.interpolation_mode = 
    renoise.Sample.INTERPOLATE_NONE
  selected_sample.interpolation_mode = 
    renoise.Sample.INTERPOLATE_LINEAR
  selected_sample.interpolation_mode = 
    renoise.Sample.INTERPOLATE_CUBIC
  assert_error(function()
    selected_sample.interpolation_mode = 0
  end)
  assert_error(function()
    selected_sample.interpolation_mode = 
      renoise.Sample.INTERPOLATE_CUBIC + 1
  end)
  
  selected_sample.new_note_action = 
    renoise.Sample.NEW_NOTE_ACTION_NOTE_CUT
  selected_sample.new_note_action =
    renoise.Sample.NEW_NOTE_ACTION_NOTE_OFF
  selected_sample.new_note_action = 
    renoise.Sample.NEW_NOTE_ACTION_SUSTAIN
  assert_error(function()
    selected_sample.new_note_action = 0
  end)
  assert_error(function()
    selected_sample.new_note_action = 
      renoise.Sample.NEW_NOTE_ACTION_SUSTAIN + 1
  end)
  
  selected_sample.loop_mode = 
    renoise.Sample.LOOP_MODE_OFF
  selected_sample.loop_mode = 
    renoise.Sample.LOOP_MODE_FORWARD
  selected_sample.loop_mode = 
    renoise.Sample.LOOP_MODE_REVERSE
  selected_sample.loop_mode = 
    renoise.Sample.LOOP_MODE_PING_PONG
  assert_error(function()
    selected_sample.loop_mode = 0
  end)
  assert_error(function()
    selected_sample.loop_mode = 
      renoise.Sample.LOOP_MODE_PING_PONG + 1
  end)
  
  
  ----------------------------------------------------------------------------
  -- sample buffer & loops
  
  local sample_buffer = selected_sample.sample_buffer
  
  if sample_buffer.has_sample_data then
    sample_buffer:delete_sample_data()
  end
  
  assert_error(function()
    print(sample_buffer.sample_rate)
  end)
  assert_error(function()
    print(sample_buffer.bit_depth)
  end)
  assert_error(function()
    print(sample_buffer.number_of_channels)
  end)
  assert_error(function()
    print(sample_buffer.number_of_frames)
  end)
  
  local new_rate = 96000
  local new_bit_depth = 24
  local new_num_channels = 2
  local new_num_frames = math.floor(new_rate / 2)
  
  local succeeded = sample_buffer:create_sample_data(
    new_rate, new_bit_depth, new_num_channels, new_num_frames)
    
  assert(succeeded)
  
  assert(new_rate == sample_buffer.sample_rate)
  assert(new_bit_depth == sample_buffer.bit_depth)
  assert(new_num_channels == sample_buffer.number_of_channels)
  assert(new_num_frames == sample_buffer.number_of_frames)
  
  sample_buffer:set_sample_data(1, 1, 0.1)
  sample_buffer:set_sample_data(2, 1, 0.2)
  
  assert(float_cmp(sample_buffer:sample_data(1, 1), 0.1))
  assert(float_cmp(sample_buffer:sample_data(2, 1), 0.2))
  
  sample_buffer:set_sample_data(1, new_num_frames, -0.3)
  sample_buffer:set_sample_data(2, new_num_frames, 0.4)
  sample_buffer:set_sample_data(2, new_num_frames - 1, 2.1)
  
  assert(float_cmp(sample_buffer:sample_data(1, new_num_frames), -0.3))
  assert(float_cmp(sample_buffer:sample_data(2, new_num_frames), 0.4))
  assert(float_cmp(sample_buffer:sample_data(2, new_num_frames - 1), 1.0))
  
  assert_error(function()
    print(sample_buffer:sample_data(1, new_num_frames + 1))
  end)
  assert_error(function()
    print(sample_buffer:sample_data(1, 0))
  end)
  assert_error(function()
    print(sample_buffer:sample_data(0, 1))
  end)
  assert_error(function()
    print(sample_buffer:sample_data(3, 1))
  end)
  
  selected_sample.loop_start = 1
  selected_sample.loop_end = new_num_frames
  
  assert_error(function()
    selected_sample.loop_start = 0
  end)
  assert_error(function()
    selected_sample.loop_end = 0
  end)
  assert_error(function()
    selected_sample.loop_start = new_num_frames + 1
  end)
  assert_error(function()
    selected_sample.loop_end = new_num_frames + 1
  end)
  
  sample_buffer:prepare_sample_data_changes()
  
  for frame = 1,new_num_frames do
    sample_buffer:set_sample_data(1, frame, math.sin(new_num_frames / 
      frame * math.pi))
    sample_buffer:set_sample_data(2, frame, math.cos(new_num_frames / 
      frame * math.pi))
  end
  
  sample_buffer:finalize_sample_data_changes()


  ----------------------------------------------------------------------------
  -- sample selection
  
  sample_buffer.selection_range = {1, new_num_frames}
  
  -- range and start/end must match
  assert(sample_buffer.selection_range[1] == 1)
  assert(sample_buffer.selection_range[2] == new_num_frames)
  assert(sample_buffer.selection_start == 1)
  assert(sample_buffer.selection_end == new_num_frames)

  sample_buffer.selection_start = math.random(new_num_frames / 2)
  assert(sample_buffer.selection_start == sample_buffer.selection_range[1])

  sample_buffer.selection_range = {new_num_frames/2, new_num_frames}
  
  assert_error(function() -- start out of bounds
    selected_sample.selection_start = new_num_frames + 1
  end)
  assert_error(function()
    selected_sample.selection_start = 0
  end)
  
  assert_error(function() -- end out of bounds
    selected_sample.selection_end = new_num_frames + 1
  end)
  assert_error(function()
    selected_sample.selection_end = 0
  end)
  
  
  ----------------------------------------------------------------------------
  -- sample slices
  
  assert(#selected_sample.slice_markers == 0)
  assert(not selected_sample.is_slice_alias)
  
  selected_sample.slice_markers = {1,2,3,4,5,6,7,8,9}
  selected_sample.slice_markers = {}
  
  selected_sample:insert_slice_marker(math.floor(new_num_frames / 4))
  selected_sample:insert_slice_marker(math.floor(new_num_frames / 3))
  selected_sample:insert_slice_marker(math.floor(new_num_frames / 2))
  selected_sample:insert_slice_marker(math.floor(new_num_frames / 1))
  
  assert(#selected_sample.slice_markers == 4)
  
  assert_error(function() -- out of bounds
    selected_sample:insert_slice_marker(0)
  end)
  assert_error(function() -- out of bounds
    selected_sample:insert_slice_marker(new_num_frames + 1)
  end)
  
  selected_sample:delete_slice_marker(math.floor(new_num_frames / 2))
  
  assert_error(function() -- out of bounds
    selected_sample:delete_slice_marker(math.floor(new_num_frames / 5))
  end)
  
  assert(#selected_sample.slice_markers == 3)
  
  selected_sample:insert_slice_marker(math.floor(new_num_frames / 2))
  
  assert(#selected_sample.slice_markers == 4)
  assert(selected_sample.slice_markers[1] == new_num_frames / 4)
  assert(selected_sample.slice_markers[2] == new_num_frames / 3)
  assert(selected_sample.slice_markers[3] == new_num_frames / 2)
  assert(selected_sample.slice_markers[4] == new_num_frames / 1)

  selected_sample:move_slice_marker(
    math.floor(new_num_frames / 2), math.floor(new_num_frames / 8))
  
  assert(selected_sample.slice_markers[1] == new_num_frames / 8)
  assert(selected_sample.slice_markers[2] == new_num_frames / 4)
  assert(selected_sample.slice_markers[3] == new_num_frames / 3)
  assert(selected_sample.slice_markers[4] == new_num_frames / 1)

  -- sliced sample lists can't be modified
  assert_error(function() -- 
    selected_instrument:insert_sample_at(
      #selected_instrument.samples + 1)
  end)
  
  assert_error(function() -- 
    selected_instrument:delete_sample_at(
      #selected_instrument.samples)
  end)
  
  -- sliced samples can't be edited
  assert(#selected_instrument.samples == #selected_sample.slice_markers + 1)
  
  assert(not selected_instrument.samples[1].is_slice_alias)
  assert(not selected_instrument.samples[1].sample_buffer.read_only)
  
  assert(selected_instrument.samples[2].is_slice_alias)
  assert(selected_instrument.samples[2].sample_buffer.read_only)
  
  
  ----------------------------------------------------------------------------
  -- sample mappings
  
  local LAYER_NOTE_ON = renoise.Instrument.LAYER_NOTE_ON
  
  -- create 4 samples to test
  selected_instrument:clear() -- test with a empty samples
  selected_instrument:insert_sample_at(#selected_instrument.samples + 1)
  selected_instrument:insert_sample_at(#selected_instrument.samples + 1)
  selected_instrument:insert_sample_at(#selected_instrument.samples + 1)
  
  assert(#selected_instrument.sample_mappings[LAYER_NOTE_ON] == 1)
  
  local new_mapping = selected_instrument:insert_sample_mapping(
    LAYER_NOTE_ON, 2)
    
  assert(#selected_instrument.sample_mappings[LAYER_NOTE_ON] == 2)
  
  assert(new_mapping.sample_index == 2)
  assert(new_mapping.note_range[1] == 0)
  assert(new_mapping.note_range[2] == 119)
  assert(new_mapping.velocity_range[1] == 0)
  assert(new_mapping.velocity_range[2] == 127)
  
  new_mapping = selected_instrument:insert_sample_mapping(
    LAYER_NOTE_ON, 1, 36, {0,48})
  assert(#selected_instrument.sample_mappings[LAYER_NOTE_ON] == 3)
  assert(new_mapping.base_note == 36)
  assert(new_mapping.note_range[1] == 0)
  assert(new_mapping.note_range[2] == 48)
  
  new_mapping = selected_instrument:insert_sample_mapping(
    LAYER_NOTE_ON, 3, 49, {49,49}, {0,32})
  assert(new_mapping.base_note == 49)
  assert(new_mapping.note_range[1] == 49)
  assert(new_mapping.note_range[2] == 49)
  assert(new_mapping.velocity_range[1] == 0)
  assert(new_mapping.velocity_range[2] == 32)
  
  assert_error(function() -- invalid sample index
    new_mapping.sample_index = #selected_instrument.samples + 1
  end)
  assert_error(function() -- invalid base note
    new_mapping.base_note = 120
  end)
  assert_error(function() -- invalid note range
    new_mapping.note_range = {0,-1}
  end)
  assert_error(function()
    new_mapping.note_range = {0}
  end)
  assert_error(function() -- invalid note range
    new_mapping.velocity_range = {128,128}
  end)
  assert_error(function()
    new_mapping.velocity_range = {20}
  end)
  
  while (#selected_instrument.sample_mappings[LAYER_NOTE_ON] > 1) do
    selected_instrument:delete_sample_mapping_at(LAYER_NOTE_ON, 
      #selected_instrument.sample_mappings[LAYER_NOTE_ON])
  end
  
  assert_error(function()
    selected_instrument:delete_sample_mapping_at(LAYER_NOTE_ON, 
      #selected_instrument.sample_mappings[LAYER_NOTE_ON] + 1)
  end)
  
  assert(#selected_instrument.sample_mappings[LAYER_NOTE_ON] == 1)
end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
