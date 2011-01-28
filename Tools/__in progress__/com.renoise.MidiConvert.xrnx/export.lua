--[[
I tried to make an OO class, but yield would throw:
$ Error: attempt to yield across metamethod/C-call boundary

I also tried to make a Lua module, but I got:
$ Error: attempt to get length of upvalue [...]

Dinked around for hours, gave up.
Thusly, this file is procedural. Each function is to be prepended with `export_`
Good times.
]]--

local midi_division = 96 -- MIDI clicks per quarter note

local filepath = nil
local rns = nil
local instruments = nil
local total_sequence = nil

function export_procedure()
  filepath = renoise.app():prompt_for_filename_to_write("midi", "Export")
  rns = renoise.song()
  instruments = rns.instruments
  total_sequence = #rns.sequencer.pattern_sequence
  local process = ProcessSlicer(export_build_data, export_build_data_done)
  renoise.tool().app_release_document_observable
    :add_notifier(function()
      if (process and process:running()) then
        process:stop()
        print("Process 'build_data()' has been aborted due to song change.")
      end
    end)
  process:start()
end


function export_pos_to_time(pos, delay, bpm, lpb)   
  -- TODO
  return timestamp
end


function export_build_data()
  local data = table.create()
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
                  note = note_col.note_value,
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
      -- Yield every 3rd track to avoid timeout nag screens
      if (track_index % 3 == 0) then
        coroutine.yield()
        print(("Process(build_data()) - Instr: %d; Track: %d.")
          :format(i,track_index))
      end
    end
  end
  return "No errors", data
end


-- This function is called when build_data is finished.
-- @param result  Table containing the return values from export_build_data()
function export_build_data_done(result)

  rprint(result)
  print("Process 'build_data()' has finished!")

  -- TODO:
  -- Create a second data structure that stores effects, for secondary processing
  -- Stack data in Midi class
  --
  
  local midi = Midi()
  midi:open()
  midi:newTrack()
  midi:setTimebase(midi_division);

  -- TODO: Something
  -- midi:saveTxtFile(filepath .. '.txt')
  -- midi:saveMidFile(filepath)

end
