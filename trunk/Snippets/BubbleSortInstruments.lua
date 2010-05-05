--[[

This procedure sorts instruments from biggest to smallest using the Bubble
Sort algorithm.

Bubble sort is Computer Science 101 material. It is included as a code snippet
for learning purposes, but to be honest, this is a horrible idea. The
procedure "works" but will take a long time to finish. This is not a practical
solution, only educational.

]]--

-- Set up a table named 'placeholder'
-- The key is the instrument position
-- The value is the size of the sample(s) contained within

local placeholder = { }
local instruments = renoise.song().instruments
local total = #instruments
for i = 1,total do
  for j = 1,#instruments[i].samples do
    placeholder[i] = 0
    if instruments[i].samples[j].sample_buffer.has_sample_data then
      -- Shortcuts
      local frames = instruments[i].samples[j].sample_buffer.number_of_frames
      local n_channels = instruments[i].samples[j].sample_buffer.number_of_channels
      local bits_per_sample = instruments[i].samples[j].sample_buffer.bit_depth
      -- Calculate the size of the sample
      local bytes_in_frame = n_channels * (bits_per_sample / 8)
      local size = bytes_in_frame * frames
      -- Append to the table
      placeholder[i] = placeholder[i] + size
    end
  end
end

-- Debug: Before
-- rprint(placeholder)

-- Bubble Sort

local num_swaps = 0
local i = 1
while( i < total ) do
  local j = i + 1
  while( j <= total ) do
    if ( placeholder[j] > placeholder[i] ) then
      local tmp = placeholder[j]
      placeholder[j] = placeholder[i];
      renoise.song():swap_instruments_at(j, i)
      placeholder[i] = tmp
      num_swaps = num_swaps + 1
    end
    j = j + 1;
  end
  i = i + 1;
end

-- Debug: After
-- rprint(placeholder)

-- Alert box
local alert = renoise.app():show_prompt(
  'Bubble Sort Complete',
  'Total number of swaps was: ' .. num_swaps,
  {'Ok'}
)
