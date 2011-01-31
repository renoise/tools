--[[============================================================================
export.lua

I tried to make an OO class, but yield would throw:
$ Error: attempt to yield across metamethod/C-call boundary

I also tried to make a Lua module, but I got:
$ Error: attempt to get length of upvalue [...]

Dinked around for hours, gave up.
Thusly, this file is procedural. Each function is to be prepended with `export_`
Good times.
============================================================================]]--


--------------------------------------------------------------------------------
-- Variables & Globals
--------------------------------------------------------------------------------

local filepath = nil
local rns = nil
local instruments = nil
local total_sequence = nil
local data = table.create()


--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

function export_pos_to_time(pos, delay, division, lpb)
  return ((pos - 1) + (delay * 100 / 255 * 0.01)) * (division/lpb)
end


function compare(a, b)
  return a[1] < b[1]
end


--------------------------------------------------------------------------------
-- Build a data table
--------------------------------------------------------------------------------

function export_build_data()
  data:clear()
  -- Instruments
  for i = 1,#instruments do
    data[i] = table.create()
    local j = 0
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
                j > 0 and data[i][j].pos_end == 0
              then
                data[i][j].pos_end = line_index + pattern_offset
                data[i][j].delay_end = note_col.delay_value
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
                j = table.count(data[i])
              end
            end
            pattern_previous = rns.sequencer.pattern_sequence[sequence_index]
          end
          -- Insert terminating Note OFF
          if j > 0 and data[i][j].pos_end == 0 then
            data[i][j].pos_end = pattern_offset + pattern_length + 1
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
end


--------------------------------------------------------------------------------
-- Create and save midi file
--------------------------------------------------------------------------------

function export_midi()

  -- TODO:
  -- Create a second data structure that stores effects, for secondary processing
  -- Stack data in Midi class
  --
  -- And more!

  local midi_division = 96 -- MIDI clicks per quarter note
  local midi = Midi()
  midi:open()
  midi:setBpm(renoise.song().transport.bpm);
  midi:setTimebase(midi_division);

  -- Work in progress
  -- Currently, this is just a proof of concept...
  
  local sort_me = table.create()
  local timestamp = 0
  local msg = ''
  for i=1, #data do
    if table.count(data[i]) > 0 then
      local tn = midi:newTrack()
      for j=1, #data[i] do
        timestamp = export_pos_to_time(
          data[i][j].pos_start, data[i][j].delay_start,
          midi_division, renoise.song().transport.lpb
          )
        msg = " On ch=1 n=" ..  data[i][j].note .. " v=127"
        sort_me:insert{timestamp, msg, tn}

        timestamp = export_pos_to_time(
          data[i][j].pos_start, data[i][j].delay_start,
          midi_division, renoise.song().transport.lpb
          )
        msg = " Off ch=1 n=" ..  data[i][j].note .. " v=0"
        sort_me:insert{timestamp, msg, tn}
      end
    end
    -- Yield every 3rd track to avoid timeout nag screens
    if (i % 3 == 0) then
      coroutine.yield()
      print(("Process(midi()) - Instr: %d.")
        :format(i))
    end
  end

  table.sort(sort_me, compare)
  for i=1, #sort_me do
    midi:addMsg(sort_me[i][3], sort_me[i][1] .. sort_me[i][2])
    -- Yield every 1000 messages to avoid timeout nag screens
    if (i % 1000 == 0) then
      coroutine.yield()
      print(("Process(midi()) - Msg: %d.")
        :format(i))
    end
  end

  -- Save files
  midi:saveTxtFile(filepath .. '.txt')
  midi:saveMidFile(filepath)

end


--------------------------------------------------------------------------------
-- Main procedure(s) wraped in ProcessSlicer
--------------------------------------------------------------------------------

function export_procedure()
  filepath = renoise.app():prompt_for_filename_to_write("midi", "Export MIDI")
  if filepath == '' then return end

  rns = renoise.song()
  instruments = rns.instruments
  total_sequence = #rns.sequencer.pattern_sequence
  local process = ProcessSlicer(export_build, export_done)
  renoise.tool().app_release_document_observable
    :add_notifier(function()
      if (process and process:running()) then
        process:stop()
        print("Process 'build_data()' has been aborted due to song change.")
      end
    end)
  process:start()
end


function export_build()
  export_build_data()
  export_midi()
end


function export_done()
  -- export_build_data()
  -- export_midi()
  print("Done!")
end
