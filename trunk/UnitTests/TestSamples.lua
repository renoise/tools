--[[--------------------------------------------------------------------------
TestSamples.lua
--------------------------------------------------------------------------]]--

-- tools

local function assert_error(statement)
  assert(pcall(statement) == false, "expected function error")
end

function float_cmp(f1, f2)
  return math.abs(f1 - f2) < 0.0001
end


------------------------------------------------------------------------------
-- insert/delete/swap

local song = renoise.song()
local selected_instrument = song.selected_instrument

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


------------------------------------------------------------------------------
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


------------------------------------------------------------------------------
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
local new_num_frames = new_rate / 2

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

for frame = 1,new_num_frames do
  sample_buffer:set_sample_data(1, frame, math.sin(new_num_frames / 
    frame * math.pi))
  sample_buffer:set_sample_data(2, frame, math.cos(new_num_frames / 
    frame * math.pi))
end

sample_buffer:finalize_sample_data_changes()


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
