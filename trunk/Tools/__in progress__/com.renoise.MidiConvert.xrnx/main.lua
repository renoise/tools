
require "Midi"
require "process_slicer"

local rns = renoise.song()
local data = table.create()
local instruments = renoise.song().instruments
local total_sequence = #rns.sequencer.pattern_sequence

function build_data()
  -- Instruments
  for i = 1,#instruments do
    data[i] = table.create()
    -- Tracks
    for track_index = 1,#rns.tracks do
      if
        rns.tracks[track_index].type ~= renoise.Track.TRACK_TYPE_MASTER and
        rns.tracks[track_index].type ~= renoise.Track.TRACK_TYPE_SEND
      then
        -- Columns
        for column_index = 1,rns.tracks[track_index].visible_note_columns do
          local pattern_current = nil
          local pattern_previous = rns.sequencer.pattern_sequence[1]
          local pattern_offset = 0
          local pattern_length = 0
          local j = 1          
          for sequence_index = 1,total_sequence do
            -- Calculate offset
            if pattern_current ~= rns.patterns[sequence_index] then
              pattern_current = rns.patterns[sequence_index]
              if sequence_index > 1 then
                pattern_offset = pattern_offset + rns.patterns[pattern_previous].number_of_lines
              end
            end
            local pattern_index = rns.sequencer.pattern_sequence[sequence_index]
            local current_pattern_track = rns.patterns[pattern_index].tracks[track_index]
            pattern_length = rns.patterns[pattern_index].number_of_lines
            -- Lines
            for line_index = 1,pattern_length do
              local note_col = current_pattern_track:line(line_index).note_columns[column_index]
              -- TODO:
              -- NNA and a more realistic note duration could, in theory,
              -- be calculated with the length of the sample and the instrument
              -- ADSR properties.
              --
              -- Note OFF
              if
                not note_col.is_empty and
                j > 1 and data[i][j-1].pos_end == 0
              then
                data[i][j-1].pos_end = line_index + pattern_offset
                data[i][j-1].delay_end = note_col.delay_value
              end
              -- Note ON
              if note_col.instrument_value == i-1 then
                data[i]:insert{
                  note = note_col.note_string,
                  pos_start = line_index + pattern_offset,
                  pos_end = 0,
                  delay_start = note_col.delay_value,
                  delay_end = 0,
                  volume = note_col.volume_value,
                  panning = note_col.panning_value,
                  track = track_index,
                  column = column_index,
                  sequence_index = sequence_index,
                }
                j = j + 1
              end
            end
            pattern_previous = rns.sequencer.pattern_sequence[sequence_index]            
          end
          -- Insert terminating Note OFF
          if j > 1 and data[i][j-1].pos_end == 0 then
            data[i][j-1].pos_end = pattern_offset + pattern_length + 1
          end
        end
      end
      -- Yeild every 3rd track, to avoid timeout nag screens
      if (track_index % 3 == 0) then coroutine.yield() end
    end
  end
end

-- This function encapsulates the workload, used by ProcessSlicer
function build()
  print("Working...")
  build_data()
  -- TODO:
  -- Create a second data structure that stores effects, for secondary processing
end

-- This function is called when ProcessSlicer is finished.
function done(...)
  print("Done!")
  rprint(data)
end

-- Main
function main()
  local process = ProcessSlicer(build, done)
  process:start()
end


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:__Midi Script Debug (WIP...)",
  invoke = main
}

