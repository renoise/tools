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
-- Variables & Globals, captialized for easier recognition
--------------------------------------------------------------------------------

local MIDI_DIVISION = 96 -- MIDI clicks per quarter note
local MIDI_CHANNEL = 1   -- Initial MIDI channel

local FILEPATH = nil
local RNS = nil

local DATA = table.create()
local DATA_BPM = table.create()
local DATA_LPB = table.create()
local DATA_TPL = table.create()
local DATA_TICK_DELAY = table.create()
local DATA_TICK_CUT = table.create()

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

-- Go to next midi channel
function export_ch_rotator()
  MIDI_CHANNEL = MIDI_CHANNEL + 1
  if MIDI_CHANNEL > 16 then MIDI_CHANNEL = 1 end
end

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
  if (a and a[1] == b[1]) then
    return a[2] < b[2]
  else
    return a[1] < b[1]
  end
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

  MIDI_CHANNEL = 1
  DATA:clear(); DATA_BPM:clear(); DATA_LPB:clear(); DATA_TPL:clear()
  DATA_TICK_DELAY:clear(); DATA_TICK_CUT:clear()

  local instruments = RNS.instruments
  local tracks = RNS.tracks
  local sequencer = RNS.sequencer
  local total_instruments = #instruments
  local total_tracks = #tracks
  local total_sequence = #sequencer.pattern_sequence
  local start = { sequence_index = 1, line_start = 1, line_end = nil }
  local constrain_to_selected = false

  -- Plan
  RNS.transport:stop()
  if plan == 'selection' then
    constrain_to_selected = true
    start.sequence_index = RNS.selected_sequence_index
    start.line_start, start.line_end = selection_line_range()
    total_sequence = start.sequence_index
  else
    RNS.transport.playback_pos = renoise.SongPos(1, 1)
  end

  -- Setup data table
  for i=1,total_instruments do
    DATA[i] = table.create()    
  end
  local i = 255 -- instrument_value, 255 means empty
  local j = 0 -- e.g. DATA[i][j]

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
      for sequence_index=start.sequence_index,total_sequence do

        local pattern_index = sequencer.pattern_sequence[sequence_index]
        local current_pattern_track = RNS.patterns[pattern_index].tracks[track_index]

        -- Calculate offset
        if pattern_current ~= sequence_index then
          pattern_current = sequence_index
          if k > 1 then
            pattern_offset = pattern_offset + RNS.patterns[pattern_previous].number_of_lines
          end
        end

        -- Selection hack
        if constrain_to_selected then
          pattern_length = start.line_end
        else
          pattern_length = RNS.patterns[pattern_index].number_of_lines
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
              if 'ZT' == fx_col.number_string then
                -- ZTxx - Set Beats Per Minute (BPM) (20 - FF, 00 = stop song)
                DATA_BPM[pos] = fx_col.amount_string
              elseif 'ZL' == fx_col.number_string  then
                -- ZLxx - Set Lines Per Beat (LPB) (01 - FF, 00 = stop song).
                 DATA_LPB[pos] = fx_col.amount_string
              elseif 'ZK' == fx_col.number_string  then
                -- ZKxx - Set Ticks Per Line (TPL) (01 - 10).
                DATA_TPL[pos] = fx_col.amount_string
              elseif '0Q' == fx_col.number_string  then
                -- 0Qxx, Delay all notes by xx ticks.
                DATA_TICK_DELAY[pos] = fx_col.amount_string              
              end
            end
          end

          -- Notes data
          if
            tracks[track_index].type ~= renoise.Track.TRACK_TYPE_GROUP and
            tracks[track_index].type ~= renoise.Track.TRACK_TYPE_MASTER and
            tracks[track_index].type ~= renoise.Track.TRACK_TYPE_SEND
          then
            -- TODO:
            -- NNA and a more realistic note duration could, in theory,
            -- be calculated with the length of the sample and the instrument
            -- ADSR properties.
            local midicc = false
            local note_col = current_pattern_track:line(line_index).note_columns[column_index]
            local fx_col = current_pattern_track:line(line_index).effect_columns[1]
            if
              not constrain_to_selected or
              constrain_to_selected and note_col.is_selected
            then
              -- Set some defaults
              local volume = 128
              local panning = 64
              local tick_delay = 0 -- Dx - Delay a note by x ticks (0 - F)
              local tick_cut = nil -- Fx - Cut the note after x ticks (0 - F)
              -- Volume column
              if 0 <= note_col.volume_value and note_col.volume_value <= 128 then
                volume = note_col.volume_value
              elseif note_col.volume_string:find('Q') == 1 then
                tick_delay = note_col.volume_string:sub(2)
              elseif note_col.volume_string:find('C') == 1 then
                tick_cut = note_col.volume_string:sub(2)
              end      
              -- Panning col
              if 0 <= note_col.panning_value and note_col.panning_value <= 128 then
                panning = note_col.panning_value
              elseif note_col.panning_string:find('Q') == 1 then
                tick_delay = note_col.panning_string:sub(2)
              elseif note_col.panning_string:find('C') == 1 then
                tick_cut = note_col.panning_string:sub(2)
              end
               -- Midi control messages
              if 'M0' == note_col.panning_string then
                midicc = true
              end             
              -- Note OFF
              if
                not note_col.is_empty and
                j > 0 and ((DATA[i][j] and DATA[i][j].pos_end == 0) or                
                note_col.note_value == 120)
              then
                DATA[i][j].pos_end = pos
                DATA[i][j].delay_end = note_col.delay_value
                DATA[i][j].tick_delay_end = tick_delay
              elseif
              tick_cut ~= nil and
              j > 0 and ((DATA[i][j] and DATA[i][j].pos_end == 0) or
              note_col.note_value == 120)
              then
                DATA[i][j].pos_end = pos
                DATA[i][j].delay_end = note_col.delay_value
                DATA[i][j].tick_delay_end = tick_cut
              end
              -- Note ON
              -- dbug(("note: '%d' instrument: '%d'"):format(note_col.note_value, note_col.instrument_value));
              if
                note_col.instrument_value ~= 255 and
                DATA[note_col.instrument_value + 1] ~= nil and
                note_col.note_value ~= 121 or
                midicc == true
              then
                local cc_number = 0
                local cc_value = 0
                local par = 0                
                if midicc == true then
                  par = pos
                  cc_number = fx_col.number_string
                  cc_value = fx_col.amount_string                  
                end
                i = note_col.instrument_value + 1 -- Lua vs C++
                DATA[i]:insert {
                  note = note_col.note_value,
                  pos_start = pos,
                  pos_end = 0,
                  delay_start = note_col.delay_value,
                  tick_delay_start = tick_delay,
                  delay_end = 0,
                  tick_delay_end = 0,
                  volume = volume,
                  par = par,                 
                  cc_number = cc_number,
                  cc_value = cc_value
                  -- panning = panning, -- TODO: Do something with panning var
                  -- track = track_index,
                  -- column = column_index,
                  -- sequence_index = sequence_index,
                }
                if note_col.note_value ~= 121 then
                  j = table.count(DATA[i])
                end
                if tick_cut ~= nil then
                  DATA[i][j].pos_end = pos
                  DATA[i][j].tick_delay_end = tick_cut
                end
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
        if j > 0 and DATA[i][j].pos_end == 0 then
          DATA[i][j].pos_end = pattern_offset + pattern_length + RNS.transport.lpb
        end

        -- Increment pattern counter
        k = k + 1

      end -- SEQUENCE #

      -- Yield every column to avoid timeout nag screens
      renoise.app():show_status(export_status_progress())
      if COROUTINE_MODE then coroutine.yield() end
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
  local tpl = RNS.transport.tpl
  for i=idx,1,-1 do
    if DATA_TPL[i] ~= nil and i <= pos then
      tpl = tonumber(DATA_TPL[i], 16)
      break
    end
  end
  -- Calculate tick delay
  local float = export_tick_to_delay(tick, tpl)
  if float == false then return false end
  -- Calculate and override with global tick delay
  if DATA_TICK_DELAY[pos] ~= nil then
    local g_float = export_tick_to_delay(tonumber(DATA_TICK_DELAY[pos], 16), tpl)
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
  local lpb = RNS.transport.lpb
  local tmp = math.floor(float + .5)
  for i=idx,1,-1 do
    if DATA_LPB[i] ~= nil and i <= tmp then
      lpb = tonumber(DATA_LPB[i], 16)
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
  if pos_d ~= false and data.note ~= 121 then
    local msg = "On ch=" .. MIDI_CHANNEL .. " n=" ..  data.note .. " v=" .. math.min(data.volume, 127)
    sort_me:insert{pos_d, msg, tn}
  end
end


-- Note OFF
function _export_note_off(tn, sort_me, data, idx)
  -- Create MF2T message
  local pos_d = _export_pos_to_float(data.pos_end, data.delay_end,
    tonumber(data.tick_delay_end, 16), idx)
  if pos_d ~= false and pos_d > 0 and data.note ~= 121 then
    local msg = "Off ch=" .. MIDI_CHANNEL .. " n=" ..  data.note .. " v=0"
    sort_me:insert{pos_d, msg, tn}
  end
end

-- MidiCC
function _export_midi_cc(tn, sort_me, data, idx)
  -- Create MF2T message
  local pos_par = _export_pos_to_float(data.par, 0, 0, idx)  
  if pos_par ~= false and pos_par > 0 then
    local msg = "Par ch=" .. MIDI_CHANNEL .. " c=" ..  tonumber(data.cc_number,16) .. " v=" .. tonumber(data.cc_value,16)
    sort_me:insert{pos_par, msg, tn}
  end
end


function export_midi()

  local midi = Midi()
  midi:open()
  midi:setTimebase(MIDI_DIVISION);
  midi:setBpm(RNS.transport.bpm); -- Initial BPM

  -- Debug
  -- dbug(DATA)  
  -- dbug(DATA_BPM)
  -- dbug(DATA_LPB)
  -- dbug(DATA_TPL)
  -- dbug(DATA_TICK_DELAY)

  -- reusable/mutable "sort_me" table
  local sort_me = table.create()

  -- Whenever we encounter a BPM change, write it to the MIDI tempo track
  local lpb = RNS.transport.lpb -- Initial LPB
  for pos,bpm in pairs(DATA_BPM) do
    sort_me:insert{ pos, bpm }
  end
  -- [1] = Pos, [2] = BPM
  table.sort(sort_me, export_compare)
  for i=1,#sort_me do
    local bpm = tonumber(sort_me[i][2], 16)
    if  bpm > 0 then
      -- TODO:
      -- Apply LPB changes here? See "LBP procedure is flawed?" note below...
      local timestamp = export_pos_to_time(sort_me[i][1], 0, MIDI_DIVISION, lpb)
      if timestamp > 0 then
        midi:addMsg(1, timestamp .. " Tempo " .. bpm_to_tempo(bpm))
      end
    end
  end

  -- Create a new MIDI track for each Renoise Instrument
  local idx = _export_max_pos(DATA_TPL) or 1
  sort_me:clear()
  for i=1,#DATA do
    if table.count(DATA[i]) > 0 then
      local tn = midi:newTrack()
      -- Renoise Instrument Name as MIDI TrkName
      midi:addMsg(tn,
        '0 Meta TrkName "' ..
        string.format("%02d", i - 1) .. ": " ..
        string.gsub(RNS.instruments[i].name, '"', '') .. '"'
      )
      -- Renoise Instrument Name as MIDI InstrName
      midi:addMsg(tn,
        '0 Meta InstrName "' ..
        string.format("%02d", i - 1) .. ": " ..
        string.gsub(RNS.instruments[i].name, '"', '') .. '"'
      )

      -- reuse "sort_me" table:
      -- [1] = Pos+Delay, [2] = Msg, [3] = Track number (tn)

      for j=1,#DATA[i] do
        _export_note_on(tn, sort_me, DATA[i][j], idx)
        _export_note_off(tn, sort_me, DATA[i][j], idx)
        _export_midi_cc(tn, sort_me, DATA[i][j], idx)       
        -- Yield every 250 notes to avoid timeout nag screens
        if (j % 250 == 0) then
          renoise.app():show_status(export_status_progress())
          if COROUTINE_MODE then coroutine.yield() end
          dbug(("Process(midi()) Instr: %d; Note: %d."):format(i, j))
        end
      end
      export_ch_rotator()
    end
    -- Yield every instrument to avoid timeout nag screens
    renoise.app():show_status(export_status_progress())
    if COROUTINE_MODE then coroutine.yield() end
    dbug(("Process(midi()) Instr: %d."):format(i))
  end

  -- TODO:
  -- LBP procedure is flawed? for example:
  -- Note pos:1, LBP changed pos:3, LBP changed pos:5, Note pos:7
  -- Current algorithm only uses last known LBP on pos:5
  -- But, pos:3 will affect the timeline?

  -- reuse "sort_me" table:
  -- [1] = MF2T Timestamp, [2] = Msg, [3] = Track number (tn)

  idx = _export_max_pos(DATA_LPB) or 1
  for j=1,#sort_me do
    sort_me[j][1] = _export_float_to_time(sort_me[j][1], MIDI_DIVISION, idx)
    -- Yield every 250 index to avoid timeout nag screens
    if (j % 250 == 0) then
      renoise.app():show_status(export_status_progress())
      if COROUTINE_MODE then coroutine.yield() end
      dbug(("Process(midi()) _float_to time: %d."):format(j))
    end
  end
  table.sort(sort_me, export_compare)

  -- Meta TrkEnd
  local end_of_track = table.create()
  for i=1,#sort_me do
    midi:addMsg(sort_me[i][3], trim(sort_me[i][1] .. " " .. sort_me[i][2]))
    if (end_of_track[sort_me[i][3]] == nil or end_of_track[sort_me[i][3]] < sort_me[i][1]) then
        end_of_track[sort_me[i][3]] = sort_me[i][1]
    end
    -- Yield every 1000 messages to avoid timeout nag screens
    if (i % 1000 == 0) then
      renoise.app():show_status(export_status_progress())
      if COROUTINE_MODE then coroutine.yield() end
      dbug(("Process(midi()) Msg: %d."):format(i))
    end
  end
  for track,timestamp in pairs(end_of_track) do
    midi:addMsg(track, trim(timestamp .. " Meta TrkEnd"))
  end

  -- Save files
  midi:saveTxtFile(FILEPATH .. '.txt')
  midi:saveMidFile(FILEPATH)

end


--------------------------------------------------------------------------------
-- Main procedure(s) wraped in ProcessSlicer
--------------------------------------------------------------------------------

function export_procedure(plan)
  FILEPATH = renoise.app():prompt_for_filename_to_write("mid", "Export MIDI")
  if FILEPATH == '' then return end

  RNS = renoise.song()
  if COROUTINE_MODE then
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
