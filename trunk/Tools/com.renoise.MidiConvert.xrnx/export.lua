--[[============================================================================
export.lua
============================================================================]]--

--[[

ProcessSlicer() related...

I tried to make an OO class, but yield would throw:
$ Error: attempt to yield across metamethod/C-call boundary

I also tried to make a Lua module, but I got:
$ Error: attempt to get length of upvalue [...]

Dinked around for hours, gave up.
Thusly, this file is procedural. Each function is to be prepended with `export_`
Good times.

]]--

--------------------------------------------------------------------------------
-- Variables & Globals
--------------------------------------------------------------------------------

local midi_division = 96 -- MIDI clicks per quarter note

local filepath = nil
local rns = nil

local data = table.create()
local data_bpm = table.create()
local data_lpb = table.create()
local data_tpl = table.create()
local data_tick_delay = table.create()


--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

-- MF2T Timestamp
function export_pos_to_time(pos, delay, division, lpb)
  local time = ((pos - 1) + delay / 256) * (division / lpb)
  return math.floor(time + .5) --Round
end


-- Tick to Delay (0.XX)
function export_tick_to_delay(tick, tpl)
  if tick >= tpl then return false end
  local delay = tick * 256 / tpl
  return delay / 256
end


-- Used to sort a table in export_midi()
function export_compare(a, b)
  return a[1] < b[1]
end


-- Animate status bar
local status_animation = { "|", "/", "-", "\\" }
local status_animation_pos = 1
function export_status_progress()
  if status_animation_pos >= #status_animation then
    status_animation_pos = 1
  else
    status_animation_pos = status_animation_pos + 1
  end
  return "MIDI Export, Working... " .. status_animation[status_animation_pos]
end


--------------------------------------------------------------------------------
-- Build a data table
--------------------------------------------------------------------------------

function export_build_data(plan)

  data:clear(); data_bpm:clear(); data_lpb:clear()
  data_tpl:clear(); data_tick_delay:clear()

  local instruments = rns.instruments
  local tracks = rns.tracks
  local sequencer = rns.sequencer
  local total_instruments = #instruments
  local total_tracks = #tracks
  local total_sequence = #sequencer.pattern_sequence
  local start = { pattern_index = 1, line_start = 1, line_end = nil }
  local constrain_to_selected = false

  -- Plan
  rns.transport:stop()
  if plan == 'selection' then
    constrain_to_selected = true
    start.pattern_index = rns.selected_pattern_index
    start.line_start, start.line_end = selection_line_range()
    total_sequence = start.pattern_index
  else
    rns.transport.playback_pos = renoise.SongPos(1, 1)
  end

  -- Setup data table
  for i=1,total_instruments do
    data[i] = table.create()
  end

  local i = 255 -- instrument_value, 255 means empty
  local j = 0 -- e.g. data[i][j]

  -- # TRACKS
  for track_index=1,total_tracks do

    -- Total must be 1 or more, used to process master and send tracks
    local total_note_columns = 1
    if tracks[track_index].visible_note_columns > 1 then
      total_note_columns = tracks[track_index].visible_note_columns
    end

    -- # NOTE COLUMNS
    for column_index=1,total_note_columns do

      local pattern_current = -1
      local pattern_previous = sequencer.pattern_sequence[1]
      local pattern_length = 0
      local pattern_offset = 0
      if constrain_to_selected then
        pattern_offset = 1 - start.line_start
      end
      local k = 1 -- Pattern counter

      -- # SEQUENCE
      for sequence_index=start.pattern_index,total_sequence do

        local pattern_index = sequencer.pattern_sequence[sequence_index]
        local current_pattern_track = rns.patterns[pattern_index].tracks[track_index]

        -- Calculate offset
        if pattern_current ~= sequence_index then
          pattern_current = sequence_index
          if k > 1 then
            pattern_offset = pattern_offset + rns.patterns[pattern_previous].number_of_lines
          end
        end

        -- Selection hack
        if constrain_to_selected then
          pattern_length = start.line_end
        else
          pattern_length = rns.patterns[pattern_index].number_of_lines
        end

        -- # LINES
        for line_index=start.line_start,pattern_length do

          --------------------------------------------------------------------
          -- Data chug-a-lug start >>>
          --------------------------------------------------------------------

          local pos = line_index + pattern_offset

          -- Look for global changes, don't repeat more than once
          -- Override pos, from left to right
          for fx_column_index=1,tracks[track_index].visible_effect_columns do
            local fx_col = current_pattern_track:line(line_index).effect_columns[fx_column_index]
            if
              not constrain_to_selected or
              constrain_to_selected and fx_col.is_selected
            then
              if 'F0' == fx_col.number_string then
                -- F0xx - Set Beats Per Minute (BPM) (20 - FF, 00 = stop song)
                data_bpm[pos] = fx_col.amount_string
              elseif 'F1' == fx_col.number_string  then
                -- F1xx - Set Lines Per Beat (LPB) (01 - FF, 00 = stop song).
                 data_lpb[pos] = fx_col.amount_string
              elseif 'F2' == fx_col.number_string  then
                -- F2xx - Set Ticks Per Line (TPL) (01 - 10).
                data_tpl[pos] = fx_col.amount_string
              elseif '0D' == fx_col.number_string  then
                -- 0Dxx, Delay all notes by xx ticks.
                data_tick_delay[pos] = fx_col.amount_string
              end
            end
          end

          -- Notes data
          if
            tracks[track_index].type ~= renoise.Track.TRACK_TYPE_MASTER and
            tracks[track_index].type ~= renoise.Track.TRACK_TYPE_SEND
          then
            -- TODO:
            -- NNA and a more realistic note duration could, in theory,
            -- be calculated with the length of the sample and the instrument
            -- ADSR properties.

            local note_col = current_pattern_track:line(line_index).note_columns[column_index]
            if
              not constrain_to_selected or
              constrain_to_selected and note_col.is_selected
            then
              -- Set some defaults
              local volume = 128
              local panning = 64
              local tick_delay = 0 -- Dx - Delay a note by x ticks (0 - F).
              -- Volume column
              if 0 <= note_col.volume_value and note_col.volume_value <= 128 then
                volume = note_col.volume_value
              elseif note_col.volume_string:find('D') == 1 then
                tick_delay = note_col.volume_string:sub(2)
              end
              -- Panning col
              if 0 <= note_col.panning_value and note_col.panning_value <= 128 then
                panning = note_col.panning_value
              elseif note_col.panning_string:find('D') == 1 then
                tick_delay = note_col.panning_string:sub(2)
              end
              -- Note OFF
              if
                not note_col.is_empty and
                j > 0 and data[i][j].pos_end == 0
              then
                data[i][j].pos_end = pos
                data[i][j].delay_end = note_col.delay_value
                data[i][j].tick_delay_end = tick_delay
              end
              -- Note ON
              if note_col.instrument_value ~= 255 then
                i = note_col.instrument_value + 1 -- Lua vs C++
                data[i]:insert{
                  note = note_col.note_value,
                  pos_start = pos,
                  pos_end = 0,
                  delay_start = note_col.delay_value,
                  tick_delay_start = tick_delay,
                  delay_end = 0,
                  tick_delay_end = 0,
                  volume = volume,
                  -- panning = panning, -- TODO: Do something with panning var
                  -- track = track_index,
                  -- column = column_index,
                  -- sequence_index = sequence_index,
                }
                j = table.count(data[i])
              end
            end
            -- Next
            pattern_previous = sequencer.pattern_sequence[sequence_index]
          end

          --------------------------------------------------------------------
          -- <<< Data chug-a-lug end
          --------------------------------------------------------------------

        end -- LINES #

        -- Insert terminating Note OFF
        if j > 0 and data[i][j].pos_end == 0 then
          data[i][j].pos_end = pattern_offset + pattern_length + rns.transport.lpb
        end

        -- Increment pattern counter
        k = k + 1

      end -- SEQUENCE #

      -- Yield every column to avoid timeout nag screens
      renoise.app():show_status(export_status_progress())
      if coroutine_mode then coroutine.yield() end
      dbug(("Process(build_data()) Track: %d; Column: %d")
        :format(track_index, column_index))

    end -- NOTE COLUMNS #

  end -- TRACKS #
end


--------------------------------------------------------------------------------
-- Create and save midi file
--------------------------------------------------------------------------------

-- Note: we often re-use a special `sort_me` table
-- because we need to sort timestamps before they can be added

-- Returns max pos in table
-- (a) is a table where key is pos
function _export_max_pos(a)
  local keys = a:keys()
  local mi = 1
  local m = keys[mi]
  for i, val in ipairs(keys) do
    if val > m then
      mi = i
      m = val
    end
  end
  return m
end


-- Return a float representing, pos, delay, and tick
--
-- * Delay in pan overrides existing delays in volume column.
-- * Delay in effect column overrides delay in volume or pan columns.
-- * Notecolumn delays are applied in addition to the tick delays - summ up.
--
-- @see: http://www.renoise.com/board/index.php?showtopic=28604&view=findpost&p=224642
--
function _export_pos_to_float(pos, delay, tick, idx)
  -- Find last known tpl value
  local tpl = rns.transport.tpl
  for i=idx,1,-1 do
    if data_tpl[i] ~= nil and i <= pos then
      tpl = tonumber(data_tpl[i], 16)
      break
    end
  end
  -- Calculate tick delay
  local float = export_tick_to_delay(tick, tpl)
  if float == false then return false end
  -- Calculate and override with global tick delay
  if data_tick_delay[pos] ~= nil then
    local g_float = export_tick_to_delay(tonumber(data_tick_delay[pos], 16), tpl)
    if g_float == false then return false
    else float = g_float end
  end
  -- Convert to pos
  float = float + delay / 256
  return pos + float
end


-- Return a MF2T timestamp
function _export_float_to_time(float, division, idx)
  -- Find last known tick value
  local lpb = rns.transport.lpb
  local tmp = math.floor(float + .5)
  for i=idx,1,-1 do
    if data_lpb[i] ~= nil and i <= tmp then
      lpb = tonumber(data_lpb[i], 16)
      break
    end
  end
  -- Calculate time
  local time = (float - 1) * (division / lpb)
  return math.floor(time + .5) --Round
end


-- Note ON
function _export_note_on(tn, sort_me, data, idx)
  -- Create MF2T message
  local pos_d = _export_pos_to_float(data.pos_start, data.delay_start,
    tonumber(data.tick_delay_start, 16), idx)
  if pos_d ~= false then
    local msg = "On ch=1 n=" ..  data.note .. " v=" .. math.min(data.volume, 127)
    sort_me:insert{pos_d, msg, tn}
  end
end


-- Note OFF
function _export_note_off(tn, sort_me, data, idx)
  -- Create MF2T message
  local pos_d = _export_pos_to_float(data.pos_end, data.delay_end,
    tonumber(data.tick_delay_end, 16), idx)
  if pos_d ~= false then
    local msg = "Off ch=1 n=" ..  data.note .. " v=0"
    sort_me:insert{pos_d, msg, tn}
  end
end


function export_midi()

  local midi = Midi()
  midi:open()
  midi:setTimebase(midi_division);
  midi:setBpm(rns.transport.bpm); -- Initial BPM

  -- Debug
  -- dbug(data)
  -- dbug(data_bpm)
  -- dbug(data_lpb)
  -- dbug(data_tpl)
  -- dbug(data_tick_delay)

  -- Whenever we encounter a BPM change, write it to the MIDI tempo track
  local sort_me = table.create()
  local lpb = rns.transport.lpb -- Initial LPB
  for pos,bpm in pairs(data_bpm) do
    sort_me:insert{ pos, bpm }
  end
  -- [1] = Pos, [2] = BPM
  table.sort(sort_me, export_compare)
  for i=1,#sort_me do
    local bpm = tonumber(sort_me[i][2], 16)
    if  bpm > 0 then
      -- TODO:
      -- Apply LPB changes here? See "LBP procedure is flawed?" note below...
      local timestamp = export_pos_to_time(sort_me[i][1], 0, midi_division, lpb)
      if timestamp > 0 then
        midi:addMsg(1, timestamp .. " Tempo " .. bpm_to_tempo(bpm))
      end
    end
  end

  -- Create a new MIDI track for each Renoise Instrument
  local idx = _export_max_pos(data_tpl) or 1
  sort_me:clear()
  for i=1,#data do
    if table.count(data[i]) > 0 then
      local tn = midi:newTrack()
      -- Renoise Instrument Name as MIDI TrkName
      midi:addMsg(tn,
        '0 Meta TrkName "' ..
        string.format("%02d", i - 1) .. ": " ..
        string.gsub(rns.instruments[i].name, '"', '') .. '"'
      )
      -- Renoise Instrument Name as MIDI InstrName
      midi:addMsg(tn,
        '0 Meta InstrName "' ..
        string.format("%02d", i - 1) .. ": " ..
        string.gsub(rns.instruments[i].name, '"', '') .. '"'
      )

      -- [1] = Pos+Delay, [2] = Msg, [3] = Track number (tn)
      for j=1,#data[i] do
        _export_note_on(tn, sort_me, data[i][j], idx)
        _export_note_off(tn, sort_me, data[i][j], idx)
        -- Yield every 250 notes to avoid timeout nag screens
        if (j % 250 == 0) then
          renoise.app():show_status(export_status_progress())
          if coroutine_mode then coroutine.yield() end
          dbug(("Process(midi()) Instr: %d; Note: %d."):format(i, j))
        end
      end

    end
    -- Yield every instrument to avoid timeout nag screens
    renoise.app():show_status(export_status_progress())
    if coroutine_mode then coroutine.yield() end
    dbug(("Process(midi()) Instr: %d."):format(i))
  end

  -- TODO:
  -- LBP procedure is flawed? for example:
  -- Note pos:1, LBP changed pos:3, LBP changed pos:5, Note pos:7
  -- Current algorithm only uses last known LBP on pos:5
  -- But, pos:3 will affect the timeline?

  -- [1] = MF2T Timestamp, [2] = Msg, [3] = Track number (tn)
  idx = _export_max_pos(data_lpb) or 1
  for j=1,#sort_me do
    sort_me[j][1] = _export_float_to_time(sort_me[j][1], midi_division, idx)
    -- Yield every 250 index to avoid timeout nag screens
    if (j % 250 == 0) then
      renoise.app():show_status(export_status_progress())
      if coroutine_mode then coroutine.yield() end
      dbug(("Process(midi()) _float_to time: %d."):format(j))
    end
  end
  table.sort(sort_me, export_compare)
  for i=1,#sort_me do
    midi:addMsg(sort_me[i][3], trim(sort_me[i][1] .. " " .. sort_me[i][2]))
    -- Yield every 1000 messages to avoid timeout nag screens
    if (i % 1000 == 0) then
      renoise.app():show_status(export_status_progress())
      if coroutine_mode then coroutine.yield() end
      dbug(("Process(midi()) Msg: %d."):format(i))
    end
  end

  -- Save files
  midi:saveTxtFile(filepath .. '.txt')
  midi:saveMidFile(filepath)

end


--------------------------------------------------------------------------------
-- Main procedure(s) wraped in ProcessSlicer
--------------------------------------------------------------------------------

function export_procedure(plan)
  filepath = renoise.app():prompt_for_filename_to_write("mid", "Export MIDI")
  if filepath == '' then return end

  rns = renoise.song()
  if coroutine_mode then
    local process = ProcessSlicer(function() export_build(plan) end, export_done)
    renoise.tool().app_release_document_observable
      :add_notifier(function()
        if (process and process:running()) then
          process:stop()
          dbug("Process 'build_data()' has been aborted due to song change.")
        end
      end)
    process:start()
  else
    export_build(plan)
    export_done()
  end
end


function export_build(plan)
  renoise.app():show_status(export_status_progress())
  export_build_data(plan)
  export_midi()
end


function export_done()
  renoise.app():show_status("MIDI Export, Done!")
end
