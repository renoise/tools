--[[============================================================================
xVoiceRunner
============================================================================]]--

--[[--

This class reads pattern data and converts it into instances of xVoiceRun
.
#

## Features

* Voices are tracked and captured, including pattern-commands and note-offs
* Options for finetuning how notes are linked, chained together

]]


class 'xVoiceRunner'


xVoiceRunner.COLLECT_MODE = {
  SELECTION = 1,
  CURSOR = 2,
}

-------------------------------------------------------------------------------

function xVoiceRunner:__init(...)
  TRACE("xVoiceRunner:__init(...)",...)

	local args = xLib.unpack_args(...)

  --- bool, split a voice-run when note switches
  self.split_at_note = args.split_at_note or true

  --- bool, split a voice-run when instrument switches
  self.split_at_instrument = args.split_at_instrument or true

  --- bool, stop voice-run when encountering a NOTE-OFF
  self.stop_at_note_off = args.stop_at_note_off or false

  -- internal --

  -- table, represents the active voices as we progress through song
  --  [track_index][column_index] {
  --    instrument_index = int,
  --    note_value = int,
  --    offed = bool,
  --    triggered = { 
  --      sequence = int
  --      line = int
  --    }
  --  } 
  self.voice_columns = {}

  -- table of xNoteColumns, active voice from trigger to (implied) release
  -- table = {
  --  [column_index] = {                  -- pairs
  --    [voice_run_count] = {             -- pairs
  --      [number_of_lines] = int or nil  -- including trailing blank space
  --      [implied_noteoff] = bool or nil -- set when switching note/instr
  --      [open_ended] = bool or nil      -- set when voice is open 
  --      [line_idx] =                    -- xNoteColumn
  --      [line_idx] =                    -- xNoteColumn
  --      [line_idx] =                    -- etc...
  --     }
  --   }
  -- }
  self.voice_runs = {}

  -- table, keeps track of how many unique voices we have encountered
  self.unique_notes = {}

end

-------------------------------------------------------------------------------
-- reset variables to initial state before starting to process

function xVoiceRunner:reset()
  TRACE("xVoiceRunner:reset()")

  self.voice_columns = {}
  self.voice_runs = {}
  self.unique_notes = {}

end

-------------------------------------------------------------------------------
-- prepare for next pattern by removing all terminated voices/voice-runs

function xVoiceRunner:purge_voices()
  TRACE("xVoiceRunner:purge_voices()")

  -- TODO

end


-------------------------------------------------------------------------------
-- gather voice-runs according to the specified settings
-- @param ptrack (renoise.PatternTrack)
-- @param collect_mode (xVoiceRunner.COLLECT_MODE)
-- @param trk_idx (int)
-- @param seq_idx (int)
-- @param patt_sel (table)

function xVoiceRunner:collect_from_pattern(ptrack,collect_mode,trk_idx,seq_idx,patt_sel)
  TRACE("xVoiceRunner:collect_from_pattern(ptrack,collect_mode,trk_idx,seq_idx,patt_sel)",ptrack,collect_mode,trk_idx,seq_idx,patt_sel)

  --print("self.split_at_note",self.split_at_note)
  --print("self.split_at_instrument",self.split_at_instrument)

  if (collect_mode == xVoiceRunner.COLLECT_MODE.CURSOR) then
    trk_idx = rns.selected_track_index
    seq_idx = rns.selected_sequence_index
    local col_idx = rns.selected_note_column_index
    patt_sel = xSelection.get_column_in_track(seq_idx,trk_idx,col_idx)
  elseif (collect_mode == xVoiceRunner.COLLECT_MODE.SELECTION) then
    assert(type(trk_idx)=="number")
    assert(type(seq_idx)=="number")
    assert(type(patt_sel)=="table")
    patt_sel = patt_sel
  end
  --print("patt_sel",rprint(patt_sel))
  --print("trk_idx",trk_idx)

  xLib.expand_table(self.voice_columns,trk_idx)

  local line_rng = ptrack:lines_in_range(patt_sel.start_line,patt_sel.end_line)
  local track = rns.tracks[trk_idx]

  for k,line in ipairs(line_rng) do
    --print("k,line",k,line)

    local line_idx = k + patt_sel.start_line - 1
    local trigger_pos = {
      sequence = seq_idx,
      line = line_idx,
    }

    if not line.is_empty then
      local has_midi_cmd = xLinePattern.get_midi_command(track,line)
      for col_idx,notecol in ipairs(line.note_columns) do
        if not notecol.is_empty 
          and (col_idx > track.visible_note_columns) 
          or ((col_idx < patt_sel.start_column) 
            or (col_idx > patt_sel.end_column))
        then
          --print("*** process_pattern_track - skip hidden column",col_idx )
        else

          local has_note_on,has_note_off,has_instr_val,note_value,instr_idx = 
            xVoiceRunner.get_run_info_line(notecol)

          local is_midi_cmd = has_midi_cmd and (col_idx == track.visible_note_columns)

          if is_midi_cmd then
            --print("*** process_pattern_track - skip midi command",k,col_idx)
          else

            if note_value then
              self.unique_notes[note_value] = true
            end

            local begin_voice_run = false
            local stop_voice_run = false
            local implied_noteoff = false

            -- custom mode TODO
              -- only collect if note/instrument corresponds to a remapping

            if has_note_off then
              --print("has_note_off",self.stop_at_note_off,rprint(self.voice_columns[trk_idx][col_idx]))
              if self.voice_columns[trk_idx][col_idx] then
                if self.stop_at_note_off then
                  stop_voice_run = true
                  instr_idx = self.voice_columns[trk_idx][col_idx].instrument_index
                  self.voice_columns[trk_idx][col_idx] = nil
                  --print(">>> process_pattern_track - stop voice run",instr_idx,col_idx,k)
                else
                  -- set voice column as 'offed'
                  self.voice_columns[trk_idx][col_idx].offed = true
                  instr_idx = self.voice_columns[trk_idx][col_idx].instrument_index
                  --print(">>> process_pattern_track - voice offed",instr_idx,col_idx,k)
                end
              end
            elseif has_instr_val 
              or has_note_on
            then
              if not self.voice_columns[trk_idx][col_idx] then
                -- create voice run 
                --print(">>> process_pattern_track - create voice run",instr_idx,col_idx,k)
                begin_voice_run = true
                self.voice_columns[trk_idx][col_idx] = {
                  instrument_index = has_instr_val and instr_idx or 0,
                  note_value = has_note_on and note_value or nil,
                  triggered = trigger_pos,
                }
              elseif has_note_on 
                and self.split_at_note
                and (note_value ~= self.voice_columns[trk_idx][col_idx].note_value)
              then
                -- changed note
                --print(">>> process_pattern_track - changed note, create voice run",instr_idx,col_idx,k)
                --print("self.voice_columns[trk_idx] PRE",rprint(self.voice_columns[trk_idx]))
                implied_noteoff = true
                begin_voice_run = true
                self.voice_columns[trk_idx][col_idx] = {
                  instrument_index = has_instr_val and instr_idx or 0,
                  note_value = note_value,
                  triggered = trigger_pos,
                }

                --print("self.voice_columns[trk_idx] POST",rprint(self.voice_columns[trk_idx]))


              elseif has_instr_val 
                and self.split_at_instrument
                and (instr_idx ~= self.voice_columns[trk_idx][col_idx].instrument_index)
              then
                -- changed instrument
                --print(">>> process_pattern_track - changed instrument, create voice run",instr_idx,col_idx,k)
                begin_voice_run = true
                implied_noteoff = true
                self.voice_columns[trk_idx][col_idx] = {
                  instrument_index = instr_idx,
                  note_value = has_note_on and note_value or nil,
                  triggered = trigger_pos
                }
              end
            elseif not notecol.is_empty then
              if self.voice_columns[trk_idx][col_idx] then
                instr_idx = self.voice_columns[trk_idx][col_idx].instrument_index
                --print(">>> process_pattern_track - voice run",k,col_idx)
              else
                -- capture 'orphaned' data and assign to instrument 0 
                --print(">>> process_pattern_track - voice run (orphan)",instr_idx,col_idx,k)
                instr_idx = 0
              end
            end

            if (type(instr_idx)=="number") then
              
              local run_index = nil
              if self.voice_runs and self.voice_runs[col_idx] then
                run_index = #self.voice_runs[col_idx]
              end
              --print("got here...run_index,begin_voice_run,implied_noteoff",run_index,begin_voice_run,implied_noteoff)
              if run_index and begin_voice_run and implied_noteoff then
                local low,high = xLib.get_table_bounds(self.voice_runs[col_idx][run_index])
                local num_lines = k-low
                self.voice_runs[col_idx][run_index].number_of_lines = num_lines
                self.voice_runs[col_idx][run_index].implied_noteoff = true
              end

              xLib.expand_table(self.voice_runs,col_idx)
              run_index = #self.voice_runs[col_idx] + (begin_voice_run and 1 or 0)
              xLib.expand_table(self.voice_runs,col_idx,run_index)
              self.voice_runs[col_idx][run_index][line_idx] = xNoteColumn.do_read(notecol)
              --rprint(self.voice_runs[col_idx][run_index][line_idx])
              --print("got here...run_index,stop_voice_run",run_index,stop_voice_run)

              if run_index and stop_voice_run then
                local low,high = xLib.get_table_bounds(self.voice_runs[col_idx][run_index])
                local num_lines = high-low
                --print(">>> collect - stop_voice_run - low,high,num_lines",low,high,num_lines)
                self.voice_runs[col_idx][run_index].number_of_lines = num_lines
              end

            end

          end -- skip MIDI

        end
      end
    end

  end

  -- assign 'number_of_lines' to voice-runs (use implied note-offs)

  for col_idx,v in pairs(self.voice_runs) do
    for run_idx,v2 in pairs(v) do
      local low,high = xLib.get_table_bounds(v2)
      if not (v2.number_of_lines) then
        local voice = self.voice_columns[trk_idx][col_idx]
        if voice then -- still open

          if self.ends_on_note_off(v2) then
            v2.number_of_lines = high-low
            v2[high] = nil -- shave off note-off
            --print("*** collect - voice open, number_of_lines",v2.number_of_lines)
          else
            -- extend the voice across the selection boundary (actual length)
            local patt_idx = rns.sequencer:pattern(seq_idx)
            local patt = rns.patterns[patt_idx]
            local end_of_run = self:detect_run_length(ptrack,col_idx,voice,low,patt.number_of_lines)
            v2.number_of_lines = end_of_run
            v2.open_ended = true
            --print("*** collect - voice open, number_of_lines",v2.number_of_lines)
          end

        else
          v2.number_of_lines = high-low
          --print("*** collect - voice terminated, number_of_lines",v2.number_of_lines)
        end
      else
        -- implied note-off
      end
    end
  end

end

-------------------------------------------------------------------------------
-- select the voice-run below the current cursor position
-- @return table (pattern-selection, see xSelection) or nil 

function xVoiceRunner:select_voice_run()
  TRACE("xVoiceRunner:select_voice_run()")

  local ptrack = rns.selected_pattern_track
  local trk_idx = rns.selected_track_index
  --local seq_idx = rns.selected_sequence_index
  local col_idx = rns.selected_note_column_index
  local line_idx = rns.selected_line_index

  self:reset()
  local collect_mode = xVoiceRunner.COLLECT_MODE.CURSOR
  self:collect_from_pattern(ptrack,collect_mode)
  --print("voice_runs",rprint(self.voice_runs))

  local voice_run = xVoiceRunner.in_range(self.voice_runs,line_idx,line_idx,{
    restrict_to_column = col_idx,
    include_before = true,
    include_after = true,
  })

  --print("voice_run",rprint(voice_run))

  if not table.is_empty(voice_run) then
    local low,high = xLib.get_table_bounds(voice_run[col_idx])
    --print("low,high",low,high)
    local vrun = voice_run[col_idx][low]
    --print("vrun.number_of_lines",vrun.number_of_lines)
    local low,high = xLib.get_table_bounds(vrun)
    local end_line = low + vrun.number_of_lines - 1
    end_line = vrun.implied_noteoff 
      and end_line or vrun.open_ended and end_line or end_line+1
    return {
      start_line = low,
      start_track = trk_idx,
      start_column = col_idx,
      end_line = end_line,
      end_track = trk_idx,
      end_column = col_idx,
    }
  end

end

-------------------------------------------------------------------------------
-- check when a voice-run ends by examining the pattern-track
-- (note: this is a simplified version of collect_from_pattern() that doesn't 
-- collect data as it progresses through the pattern...)
-- @param ptrack, renoise.PatternTrack
-- @param col_idx, int
-- @param start_line, int
-- @param num_lines, int
-- @return int, line index

function xVoiceRunner:detect_run_length(ptrack,col_idx,voice,start_line,num_lines)
  TRACE("xVoiceRunner:detect_run_length(ptrack,col_idx,voice,start_line,num_lines)",ptrack,col_idx,voice,start_line,num_lines)

  local line_rng = ptrack:lines_in_range(start_line,num_lines)
  for k,line in ipairs(line_rng) do
    if not line.is_empty then
      for notecol_idx,notecol in ipairs(line.note_columns) do
        if not notecol.is_empty 
          and (col_idx == notecol_idx)
        then
          --print("notecol",notecol)
          local has_note_on,has_note_off,has_instr_val,note_value,instr_idx = 
            xVoiceRunner.get_run_info_line(notecol)

          if has_note_off then
            if self.stop_at_note_off then
              -- stop at note-off
              --print("*** detect_run_length - stop at note-off")
              return k
            end
          elseif has_instr_val 
            or has_note_on
          then
            if has_note_on 
              and self.split_at_note
              and (note_value ~= voice.note_value)
            then
              -- changed note
              --print("*** detect_run_length - changed note")
              return k
            elseif has_instr_val 
              and self.split_at_instrument
              and (instr_idx ~= voice.instrument_index)            
            then
              -- changed instrument
              --print("*** detect_run_length - changed instrument")
              return k
            end
          end

        end
      end
    end

  end
  
  --print("*** detect_run_length - all the way...")
  return 1+num_lines-start_line

end


-------------------------------------------------------------------------------
-- figure out if a given range contains any voice-runs
-- @param line_start (int)
-- @param col_idx (int)
-- @param num_lines (int)
-- @return bool, true when no runs
-- @return table, voice-runs in range

function xVoiceRunner:has_room(line_start,col_idx,num_lines)
  TRACE("xVoiceRunner:has_room(line_start,col_idx,num_lines)",line_start,col_idx,num_lines)

  local line_end = line_start + num_lines -1
  local in_range = xVoiceRunner.in_range(self.voice_runs,line_start,line_end,{
    restrict_to_column = col_idx,
    include_before = true,
    include_after = true,
  })
  --print("*** has_room - in_range",line_start,line_end,rprint(in_range))
  local has_room = (#table.keys(in_range) == 0)
  print("*** has_room",has_room,"line_start,line_end",line_start,line_end,"col_idx",col_idx)
  return has_room,in_range

end

-------------------------------------------------------------------------------
-- helper function to get a specific note-column (and its index)
-- @return xNoteColumn or nil
-- @return int (run index) or nil

function xVoiceRunner:resolve_notecol(col_idx,line_idx)
  TRACE("xVoiceRunner:resolve_notecol(col_idx,line_idx)",col_idx,line_idx)

  local run_idx = xVoiceRunner.get_run_index_from_line(self.voice_runs[col_idx],line_idx)
  --print("*** run_idx",run_idx)
  if run_idx then
    local run = self.voice_runs[col_idx][run_idx]
    if run then
      return run[line_idx],run_idx
    end
  end

end

-------------------------------------------------------------------------------
-- write the current voice-runs to the provided pattern-track

function xVoiceRunner:write_to_pattern(ptrack,trk_idx,patt_sel)
  TRACE("xVoiceRunner:write_to_pattern(ptrack,trk_idx,patt_sel)",ptrack,trk_idx,patt_sel)

  local scheduled_noteoffs = {}

  --local clear_undefined = true
  local line_rng = ptrack:lines_in_range(patt_sel.start_line,patt_sel.end_line)
  for k,line in ipairs(line_rng) do
    --print("k,line",k,line)
    line:clear()
    local line_idx = k + patt_sel.start_line - 1
    for col_idx,v in pairs(self.voice_runs) do
      local notecol = line.note_columns[col_idx]
      for run_idx,v2 in pairs(v) do
        if v2[line_idx] then
          local xnotecol = xNoteColumn(v2[line_idx])
          xnotecol:do_write(notecol,xNoteColumn.output_tokens)
          scheduled_noteoffs[col_idx] = line_idx+v2.number_of_lines
        elseif (scheduled_noteoffs[col_idx] == line_idx) then
          notecol.note_value = renoise.PatternLine.NOTE_OFF
          scheduled_noteoffs[col_idx] = nil
        end
      end
    end
  end

  local track = rns.tracks[trk_idx]
  local low_col,high_col = xLib.get_table_bounds(self.voice_runs)
  if high_col then
    track.visible_note_columns = math.max(high_col,track.visible_note_columns)
  end

end


-------------------------------------------------------------------------------
-- Static Methods
-------------------------------------------------------------------------------
-- collect runs that are triggered during a particular range of lines
-- @param t (voice_runs)
-- @param line_start (int)
-- @param line_end (int)
-- @param args (table)
--  exclude_columns (table) 
--  restrict_to_column (int)
--  include_before (bool), include runs that started before line_start
--  include_after (bool), include runs that continue beyond line_end
--  matched_columns (table), set when called recursively
-- @return table
-- @return matched_columns

function xVoiceRunner.in_range(voice_runs,line_start,line_end,args)
  TRACE("xVoiceRunner.in_range(voice_runs,line_start,line_end,args)",voice_runs,line_start,line_end,args)
  --rprint(args)

  local rslt = {}
  if args.exclude_columns and args.restrict_to_column then
    LOG("*** in_range - warning: use _either_ exclude_columns or restrict_to_column, not both!")
    return rslt
  end

  local matched_columns = args.matched_columns or {}
  local exclude_columns = args.exclude_columns or {}

  -- convert 'restrict' to exclude filter
  if args.restrict_to_column then
    for k = 1,12 do
      exclude_columns[k] = (k ~= args.restrict_to_column) and true or false
    end
  end
  --print("exclude_columns",rprint(exclude_columns))

  local do_include_run = function(col_idx,run_idx)
    print("*** in range - include run - col_idx,run_idx",col_idx,run_idx)
    xLib.expand_table(rslt,col_idx)
    rslt[col_idx][run_idx] = voice_runs[col_idx][run_idx]
    matched_columns[col_idx] = true 
  end


  -- first, look for runs that start on the line
  for line_idx = line_start,line_end do
    --print("line_idx",line_idx)

    for col_idx,v2 in pairs(voice_runs) do
      --print("*** in_range - col_idx,v2",col_idx,v2)

      if exclude_columns[col_idx] then
        --print("*** in_range - skip column",col_idx)
      else 
        for run_idx,v3 in pairs(v2) do
          --print("*** in_range - run_idx,v3",col_idx,v3)
          --print("v3",rprint(v3))
          if v3[line_idx] then
            --print("*** in_range - found on same line",line_idx)
            local include_run = false
            if args.include_after then
              include_run = true
            else 
              -- verify that run ends within the range
              include_run = (line_end >= line_idx+v3.number_of_lines)
              --print(">>> include_run",include_run,"line_end",line_end,"line_idx",line_idx,"v3.number_of_lines",v3.number_of_lines)
            end
            if include_run then
              do_include_run(col_idx,run_idx)
              break
            end
          end
        end -- /runs
      end -- /skip 
    end -- /columns
  end -- /lines

  -- secondly, iterate back through lines to catch "open runs"
  if args.include_before then
    --print("*** in_range/include_before - exclude_columns",rprint(exclude_columns))
    --print("*** in_range/include_before - matched_columns",rprint(matched_columns))
    for col_idx,v in pairs(voice_runs) do
      -- examine non-triggered/excluded lines only...
      if exclude_columns[col_idx] 
        or matched_columns[col_idx]
      then
        --print("*** in_range/include_before - skip column",col_idx)
      else
        --print("*** in_range/include_before - column",col_idx,v)
        local prev_run_idx = xVoiceRunner.get_open_run(v,line_start) 
        --print("prev_run_idx",prev_run_idx)
        if prev_run_idx then
          do_include_run(col_idx,prev_run_idx)
        end
      end
    end
  end

  return rslt,matched_columns

end

-------------------------------------------------------------------------------
-- retrieve the previous run if it overlaps with the provided line

function xVoiceRunner.get_open_run(run_col,line_start)
  print("xVoiceRunner.get_open_run(run_col,line_start)",run_col,line_start)

  local matched = false
  for run_idx,run in pairs(run_col) do
    --print("run_idx,run",run_idx,run)

    -- check if run overlaps
    local low,high = xLib.get_table_bounds(run)
    local end_line = low+run.number_of_lines-1
    --print("*** get_open_run - low,high",low,high)
    --print("*** get_open_run - end_line",end_line)
    if (low < line_start) and (end_line >= line_start) then
      return run_idx
    end

  end

end

-------------------------------------------------------------------------------
-- check if a given voice-run ends on a note-off (implied or actual)
-- run on voices after collection to simplify structure
-- @param voice_run, table
-- @return bool, true when note-off
-- @return bool, true when implied

function xVoiceRunner.ends_on_note_off(voice_run)
  TRACE("xVoiceRunner.ends_on_note_off(voice_run)",voice_run)

  local low,high = xLib.get_table_bounds(voice_run)
  if (voice_run[high].note_value == renoise.PatternLine.NOTE_OFF) then
    return true,false
  elseif voice_run.implied_noteoff then
    return true,true
  end

  return false

end

-------------------------------------------------------------------------------
-- obtain a bunch of info about a note-column

function xVoiceRunner.get_run_info_line(notecol)

  local has_note_on = (notecol.note_value < renoise.PatternLine.NOTE_OFF)
  local has_note_off = (notecol.note_value == renoise.PatternLine.NOTE_OFF)
  local has_instr_val = (notecol.instrument_value < 255) 

  local note_value = (notecol.note_value < renoise.PatternLine.NOTE_OFF) 
    and notecol.note_value or nil

  local instr_idx = has_instr_val 
    and notecol.instrument_value+1 or nil

  --print("has_note_on,has_note_off,has_instr_val,note_value,instr_idx",has_note_on,has_note_off,has_instr_val,note_value,instr_idx)
  return has_note_on,has_note_off,has_instr_val,note_value,instr_idx

end

-------------------------------------------------------------------------------
-- when inserting voice-runs, find the proper index 
-- @param run_col (table)
-- @param line_idx (int)
-- @return int (1 or larger)

function xVoiceRunner.get_run_index_from_line(run_col,line_idx)
  TRACE("xVoiceRunner.get_run_index_from_line(run_col,line_idx)",run_col,line_idx)
  --print("*** get_run_index_from_line - run_col",rprint(run_col))

  local matched_idx = nil
  local is_empty = table.is_empty(run_col)
  if not is_empty then
    for run_idx,voice_run in pairs(run_col) do
      local low,high = xLib.get_table_bounds(voice_run)
      --print("*** get_run_index_from_line - low,high",low,high)
      for k = 1,high do
        --print("*** get_run_index_from_line - k",k)
        if voice_run[k] then
          matched_idx = matched_idx and matched_idx+1 or 1
          --print("*** matched_idx",matched_idx)
        end
        if matched_idx and (k == line_idx) then
          --print("*** get_run_index_from_line - matched trigger",matched_idx)
          return matched_idx -- exact on line
        end
      end  
    end  
  end

  --print("*** get_run_index_from_line - after trigger?",matched_idx)
  if matched_idx then
    return matched_idx    -- during run
  elseif not is_empty then
    return #run_col -- append to end
  else
    return nil            -- when empty
  end

end

-------------------------------------------------------------------------------
-- check the lowest/highest note-values for a given column
-- @param run_col (table)
-- @param line_start (int)
-- @param line_end (int) 
-- @return int, low note-value or nil
-- @return int, high note-value or nil

function xVoiceRunner.get_low_high_note_values(run_col,line_start,line_end)
  TRACE("xVoiceRunner.get_low_high_note_values(run_col,line_start,line_end)",run_col,line_start,line_end)

  local restrict_to_lines = (line_start and line_end) and true or false
  local low_note,high_note = 1000,-1000
  local matched = false
  for run_idx,v2 in pairs(run_col) do
    for line_idx,v3 in pairs(v2) do
      if (type(v3)=="table") 
        and (v3.note_value < renoise.PatternLine.NOTE_OFF)
        and (not restrict_to_lines
          or (restrict_to_lines 
          and (line_idx >= line_start)
          and (line_idx <= line_end)))
      then
        low_note = math.min(low_note,v3.note_value)
        high_note = math.max(high_note,v3.note_value)
        matched = true
      end
    end
  end

  if matched then
    return low_note,high_note
  end

end

