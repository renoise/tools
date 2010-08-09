--[[============================================================================
SampleBuffer.lua
============================================================================]]--

error("do not run this file. read and copy/paste from it only...")


-- modify the selected sample

local sample_buffer = renoise.song().selected_sample.sample_buffer

-- check if sample data is preset at all first
if (sample_buffer.has_sample_data) then

  -- modify sample data in the selection (defaults to the whole sample)
  for channel = 1, sample_buffer.number_of_channels do
    for frame = sample_buffer.selection_start, sample_buffer.selection_end do
      local value = sample_buffer:sample_data(channel, frame)
      value = -value -- do something with the value
      sample_buffer:set_sample_data(channel, frame, value)
    end
  end

  -- let renoise update sample overviews and caches. apply bit depth 
  -- quantization. create undo/redo data if needed...
  sample_buffer:finalize_sample_data_changes()

else
  renoise.app():show_warning("No sample preset...")
end


-------------------------------------------------------------------------------
-- generate a new sample

local selected_sample = renoise.song().selected_sample
local sample_buffer = selected_sample.sample_buffer

-- create new or overwrite sample data for our sound:
local sample_rate = 44100
local num_channels = 1
local bit_depth = 32
local num_frames = sample_rate / 2

local allocation_succeeded = sample_buffer:create_sample_data(
  sample_rate, bit_depth, num_channels, num_frames)
  
-- check for allocation failures
if (not allocation_succeeded) then
  renoise.app():show_error("Out of memory. Failed to allocate sample data")
  return
end

-- fill in the sample data with an amazing zapp sound
for channel = 1,num_channels do
  for frame = 1,num_frames do
    local sample_value = math.sin(num_frames / frame)
    sample_buffer:set_sample_data(channel, frame, sample_value)
  end
end

-- let renoise update sample overviews and caches. apply bit depth 
-- quantization. create undo/redo data if needed...
sample_buffer:finalize_sample_data_changes()

-- setup a pingpong loop for our new sample
selected_sample.loop_mode = renoise.Sample.LOOP_MODE_PING_PONG
selected_sample.loop_start = 1
selected_sample.loop_end = num_frames

