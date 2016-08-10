--[[============================================================================
xVoiceSorter
============================================================================]]--

--[[--

Advanced sorting of pattern-data (including selections) 
.
#

See also: xVoiceRunner 


]]

class 'xVoiceSorter'

xVoiceSorter.SORT_MODES = {"Low → High","High → Low",}
xVoiceSorter.SORT_MODE = {
  LOW_TO_HIGH = 1,
  HIGH_TO_LOW = 2,
}

xVoiceSorter.SORT_METHODS = {
  "Normal",
  --"Compact",
  "Unique"
}
xVoiceSorter.SORT_METHOD = {
  NORMAL = 1,
  --COMPACT = 2,
  UNIQUE = 2,
}

xVoiceSorter.MAX_NOTE_COLUMNS = 12

xVoiceSorter.ERROR_CODE = {
  TOO_MANY_COLS = 1,
  CANT_PRESERVE_EXISTING = 2,
}

-------------------------------------------------------------------------------

function xVoiceSorter:__init(...)
  TRACE("xVoiceSorter:__init(...)")

	local args = xLib.unpack_args(...)

  --- xVoiceRunner
  self.runner = args.runner

  --- xVoiceSorter.SORT_MODE
  self.sort_mode = args.sort_mode or xVoiceSorter.SORT_MODE.LOW_TO_HIGH

  --- xVoiceSorter.SORT_METHOD
  self.sort_method = args.sort_method or xVoiceSorter.SORT_METHOD.NORMAL

  --- bool
  self.merge_unique = args.merge_unique or true

  --- bool, decide if instrument is considered when sorting
  self.unique_instrument = args.unique_instrument or true

  -- internal -------------------------

  --- table
  self.selection = nil

  --- table, indicating appropriate destination column(s)
  -- (defined while processing each line...)
  --  {
  --    column_index = int,
  --    low_note = int,
  --    high_note = int,
  --  }
  self.marked_columns = {}

  --- table, sorted voice from one line of voice-runs 
  -- (see xVoiceRunner.get_runs_on_line()...)
  self.sorted = {}

  --- table, which notes to include when doing unique sort
  -- (usually defined by user as a result of having too many unique notes)
  --self.template = nil

  --- table, specifies unique/remapped notes
  -- [column] = {
  --    note_value = int,
  --    instrument_value = int,
  --  }
  self.unique_map = nil

  --- table, structure similar to that of xVoiceRunner.voice_runs
  self.temp_runs = {}

  --- int, the columns that _would_ be required to successfully 
  -- complete a sorting operation (copy of unique_map)
  self.required_cols = nil

  -- observables ----------------------

  self.runner.voice_runs_remove_column_observable:add_notifier(function()
    local col_idx = self.runner.removed_column_index
    --print("removed_column_index",col_idx)
    for k,v in ripairs(self.sorted) do
      if (v.col_idx > col_idx) then v.col_idx = v.col_idx-1 
      end
    end
    for k,v in ripairs(self.marked_columns) do
      if (v.column_index > col_idx) then v.column_index = v.column_index-1 end
    end

  end)

  self.runner.voice_runs_insert_column_observable:add_notifier(function()
    local voice_runs = self.runner.voice_runs
    local col_idx = self.runner.inserted_column_index
    --print("inserted_column_index",col_idx)
    for k,v in ipairs(self.sorted) do
      if (v.col_idx >= col_idx) then v.col_idx = v.col_idx+1 
      end
    end
    for k,v in ipairs(self.marked_columns) do
      if (v.column_index >= col_idx) then 
        v.column_index = v.column_index+1 
      end
    end    

  end)

end

-------------------------------------------------------------------------------
-- call before a sort operation

function xVoiceSorter:reset()

  --self.marked_columns = {}
  --self.sorted = {}
  self.unique_map = {}
  self.temp_runs = {}
  self.runner.high_low_columns = {}
  --self.template = nil

end

-------------------------------------------------------------------------------
-- main function - sort a pattern-track, or part thereof
-- @param ptrack, renoise.PatternTrack or renoise.InstrumentPhrase
-- @param trk_idx, int 
-- @param selection, table (pattern-selection)
-- @return bool, true or false if failed/require user input

function xVoiceSorter:sort(ptrack_or_phrase,selection,trk_idx,seq_idx)
  TRACE("xVoiceSorter:sort(ptrack_or_phrase,selection,trk_idx,seq_idx)",ptrack_or_phrase,selection,trk_idx,seq_idx)

  assert(type(ptrack_or_phrase)=="PatternTrack" or type(ptrack_or_phrase)=="InstrumentPhrase")
  assert(type(selection)=="table")

  local track = nil
  local is_sorting_pattern = (type(ptrack_or_phrase)=="PatternTrack")
  if is_sorting_pattern then
    assert(type(trk_idx)=="number")
    assert(type(seq_idx)=="number")
    track = rns.tracks[trk_idx]
  end

  self.selection = selection
  --print("*** sort - selection",rprint(self.selection))

  local collect_mode = xVoiceRunner.COLLECT_MODE.SELECTION
  self.runner:collect(ptrack_or_phrase,collect_mode,self.selection,trk_idx,seq_idx)

  local voice_runs = self.runner.voice_runs
  if table.is_empty(voice_runs) then
    return true
  end

  -- optimize: skip sorting when using particular methods
  -- on a single column (result would be identical anyway)
  if (#table.keys(voice_runs) == 1)
    and ((self.sort_method == xVoiceSorter.SORT_METHOD.NORMAL))
    --or (self.sort_method == xVoiceSorter.SORT_METHOD.COMPACT))
  then
    LOG("Skip sorting single column with normal/compact method")
    return true
  end
  --print("*** sort - voice_runs PRE",rprint(voice_runs))

  -- prepare for unique sorting
  if (self.sort_method == xVoiceSorter.SORT_METHOD.UNIQUE) then

    -- build map of unique notes 
    for k,v in pairs(self.runner.unique_notes) do
      for k2,v2 in pairs(v) do
        table.insert(self.unique_map,{
          note_value = k,
          instrument_value = self.unique_instrument and k2 or nil
        })
      end
    end
    if (#self.runner.unique_notes > xVoiceSorter.MAX_NOTE_COLUMNS) then
      self.required_cols = table.rcopy(self.unique_map)
      return false,xVoiceSorter.ERROR_CODE.TOO_MANY_COLS
    end
    --[[
    table.sort(self.unique_map,function(e1,e2)
      if (self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH) then
        return e1.note_value < e2.note_value
      elseif (self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW) then
        return e1.note_value > e2.note_value
      end
    end)
    ]]
    table.sort(self.unique_map,function(e1,e2)
      if (self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH) then
        if (e1.note_value == e2.note_value) 
          and (e1.instrument_value)
          and (e2.instrument_value)
        then
          return e1.instrument_value < e2.instrument_value
        else
          return e1.note_value < e2.note_value
        end
      elseif (self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW) then
        if (e1.note_value == e2.note_value) 
          and (e1.instrument_value)
          and (e2.instrument_value)
        then
          return e1.instrument_value > e2.instrument_value
        else
          return e1.note_value > e2.note_value
        end
      end
    end)

    --print("*** sort - initial unique_map",rprint(self.unique_map))

  end

  -- sort - iterate through lines...
  for line_idx = self.selection.start_line,self.selection.end_line do
    local line_runs = xVoiceRunner.get_runs_on_line(voice_runs,line_idx)
    if (self.sort_method == xVoiceSorter.SORT_METHOD.NORMAL)
      --or (self.sort_method == xVoiceSorter.SORT_METHOD.COMPACT) 
    then
      local rslt,err = self:sort_by_note(line_runs,line_idx)
      if err then
        return false,err
      end
    elseif (self.sort_method == xVoiceSorter.SORT_METHOD.UNIQUE) then
      local rslt,err = self:sort_unique(line_runs,line_idx) 
      if err then
        return false,err
      end
      if (#self.unique_map > xVoiceSorter.MAX_NOTE_COLUMNS) then
        self.required_cols = table.rcopy(self.unique_map)
        return false,xVoiceSorter.ERROR_CODE.TOO_MANY_COLS
      end
    elseif (self.sort_method == xVoiceSorter.SORT_METHOD.CUSTOM) then
      -- TODO  
    end
  end

  --print("self.temp_runs POST-SORT",rprint(self.temp_runs))

  -- check which columns to merge into the result
  -- (unselected columns on either side)
  local low_col,high_col = xLib.get_table_bounds(voice_runs)
  --print("low_col,high_col",low_col,high_col)
  local num_sorted_cols = #table.keys(self.temp_runs)
  --print("num_sorted_cols",num_sorted_cols)
  local unsorted_cols = {}
  local sorted_count = 0
  local column_shift = 0
  local shift_from = nil
  local visible_note_columns
  if is_sorting_pattern then
    visible_note_columns = track.visible_note_columns
  else
    visible_note_columns = ptrack_or_phrase.visible_note_columns
  end
  for k = 1,visible_note_columns do
    if (k < selection.start_column)
      or (k > selection.end_column)
    then
      unsorted_cols[k] = true
      if not shift_from and (sorted_count > 0) then
        shift_from = k
      end
    else
      unsorted_cols[k] = false
      sorted_count = sorted_count+1
    end
  end
  --print("unsorted_cols",rprint(unsorted_cols))
  --print("sorted_count",sorted_count)
  --print("shift_from",shift_from)

  -- columns with content on the right-hand side of the selection
  -- are shifted sideways before we write the output...
  if shift_from then
    -- shift amount is equal to left side of selection + 
    local selection_column_span = 1+self.selection.end_column-self.selection.start_column
    --print("selection_column_span",selection_column_span)
    column_shift = math.abs(num_sorted_cols-selection_column_span)
    --print("column_shift",column_shift)
    if (column_shift > 0) then
      xColumns.shift_note_columns(
        ptrack_or_phrase,
        shift_from,
        column_shift,
        self.selection.start_line,
        self.selection.end_line)
    end
  end

  self.selection.end_column = math.max(visible_note_columns,self.selection.start_column+#self.temp_runs-1)
  if (self.selection.end_column > 12) then
    return false,xVoiceSorter.ERROR_CODE.CANT_PRESERVE_EXISTING
  end

    -- align with the left side of selection by inserting empty columns 
    -- (not written to pattern - selection is masking them out)
  local start_column = self.selection.start_column
  if (start_column > 1) then
    repeat
      table.insert(self.temp_runs,1,{})
      start_column=start_column-1
    until (start_column == 1)
  end

  if (self.sort_method == xVoiceSorter.SORT_METHOD.UNIQUE) then
    self.runner.voice_runs = self.temp_runs
  end

  --print("final sorted",rprint(self.runner.voice_runs))

  if shift_from then
    --print("shift_from,column_shift",shift_from,column_shift)
    local num_cols = visible_note_columns + column_shift
    if is_sorting_pattern then
      track.visible_note_columns = math.min(12,math.max(num_cols,track.visible_note_columns))
    else
      ptrack_or_phrase.visible_note_columns = math.min(12,math.max(num_cols,ptrack_or_phrase.visible_note_columns))
    end
  end

  self.runner:write(ptrack_or_phrase,self.selection,trk_idx)
  self.runner:purge_voices()

  return true

end

-------------------------------------------------------------------------------
-- sort line runs according to note and (optionally) instrument

function xVoiceSorter:sort_line_runs(t,line_idx)
  TRACE("xVoiceSorter:sort_line_runs(t,line_idx)",t,line_idx)

  table.sort(t,function(e1,e2)
    local can_sort_by_instr = function()
      return self.unique_instrument 
        and (e1.voice_run[line_idx].note_value == e2.voice_run[line_idx].note_value)
        and (e1.voice_run[line_idx].instrument_value < 255)
        and (e2.voice_run[line_idx].instrument_value < 255)
    end
    if (self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH) then
      if can_sort_by_instr() then
        return e1.voice_run[line_idx].instrument_value < e2.voice_run[line_idx].instrument_value
      else
        return e1.voice_run[line_idx].note_value < e2.voice_run[line_idx].note_value
      end
    elseif (self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW) then
      if can_sort_by_instr() then
        return e1.voice_run[line_idx].instrument_value > e2.voice_run[line_idx].instrument_value
      else
        return e1.voice_run[line_idx].note_value > e2.voice_run[line_idx].note_value
      end
    end
  end)

end

-------------------------------------------------------------------------------
-- sorting by note-value, one line at a time
-- @param line_runs (table), see get_runs_on_line()
-- @param line_idx (int) the line index

function xVoiceSorter:sort_by_note(line_runs,line_idx)
  TRACE("xVoiceSorter:sort_by_note(line_runs,line_idx)",line_runs,line_idx)

  local voice_runs = self.runner.voice_runs

  self.sorted = table.rcopy(line_runs)
  self:sort_line_runs(self.sorted,line_idx)

  local low_col,high_col = self.selection.start_column,self.selection.end_column
  --print("low_col,high_col",low_col,high_col)

  for k,voice in ipairs(self.sorted) do

    local sorted_note = voice.voice_run[line_idx].note_value
    --print("*** processing sorted note...",k,voice.voice_run[line_idx].note_string,sorted_note,"==============================")
    --print("*** high_low_columns...",rprint(self.runner.high_low_columns))

    self.marked_columns = {}   
    local assigned = false

    for col_idx = low_col,high_col do
      local run_col = voice_runs[col_idx]
      if not run_col then
        LOG("*** sort_high_to_low - skip column (no voice-run)",col_idx)
      else
        -- establish highest/lowest note-value prior to this line
        local low_note,high_note = nil,nil
        local high_low_col = self.runner:get_high_low_column(col_idx) 
        if high_low_col then -- 
          --print("*** look at cached values")
          low_note,high_note = high_low_col.low_note,high_low_col.high_note
        else 
          --print("*** look through prior lines in this column")
          local line_end = (line_idx == 1) and line_idx or line_idx-1
          high_note,low_note = xVoiceRunner.get_high_low_note_values(run_col,self.selection.start_line,line_end)
        end

        if high_note then
          --print("*** col_idx,low_note,high_note",col_idx,xNoteColumn.note_value_to_string(low_note),xNoteColumn.note_value_to_string(high_note))
        else
          --print("*** col_idx,low_note,high_note",col_idx,low_note,high_note)
        end

        local mark_column = function()
          self:mark_column(col_idx,low_note,high_note)
        end

        if not high_note then
          --print(">>> no note - remember column")
          mark_column()
        else
          local assign_at_once = false
          if (self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW) then
            assign_at_once = (high_note and low_note) and (high_note < sorted_note) and (low_note < sorted_note) 
          elseif (self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH) then
            assign_at_once = (high_note and low_note) and (high_note > sorted_note) and (low_note > sorted_note) 
          end
          if assign_at_once then
            self:assign_to_marked(voice,line_idx)
            assigned = true
            break
          else
            mark_column()
          end
        end 

      end --/run_col
    end

    if not assigned then
      --print(">>> reached end - marked columns",rprint(self.marked_columns))
      self:assign_to_marked(voice,line_idx)
    end

  end

end

-------------------------------------------------------------------------------
-- supports the sort_by_note() method...
-- traverse through the table of marked columns and find the
-- first one which has room for our voice-run - or insert new column
-- @param voice (table), one of our line-runs
-- @param line_idx (int)

function xVoiceSorter:assign_to_marked(voice,line_idx) 
  TRACE("xVoiceSorter:assign_to_marked(voice,line_idx)",voice,line_idx)

  --print("*** assign_to_marked - self.marked_columns",rprint(self.marked_columns))  

  local voice_runs = self.runner.voice_runs
  local assigned = false

  local low_line,high_line = xLib.get_table_bounds(voice.voice_run)
  --print("*** assign_to_marked - low_line,high_line",low_line,high_line)
  local assign_notecol = voice.voice_run[low_line]
  local assign_note_value = assign_notecol and assign_notecol.note_value or nil
  --print("*** assign_to_marked - assign_note_value",assign_note_value)

  for k,marked_col in ipairs(self.marked_columns) do

    local marked_col_idx = marked_col.column_index
    local marked_run_idx = nil 
    
    -- pick the last marked column with a suitable value
    local skip_column = false
    if (((self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW)
        and marked_col.low_note and (marked_col.low_note > assign_note_value))
      or ((self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH)
        and marked_col.high_note and (marked_col.high_note < assign_note_value)))
    then 
      -- before skipping, ensure that we've got yet another marked column 
      -- which also contains a high note (assuming that the low is present)
      skip_column = (self.marked_columns[k+1] and 
        self.marked_columns[k+1].high_note) and true or false
    end

    if not skip_column then
      -- check if the source and target column is the same
      --print("*** assign_to_marked - voice.col_idx,marked_col_idx",voice.col_idx,marked_col_idx)
      local is_same_column = (voice.col_idx == marked_col_idx)
      if is_same_column then
        --print(">>> same column - pretend that assignment has taken place")
        self.runner:set_high_low_column(marked_col_idx,assign_note_value,assign_note_value)
        assigned = true
        break
      else
        local has_room,in_range = xVoiceRunner.has_room(voice_runs,line_idx,marked_col_idx,voice.voice_run.number_of_lines)
        -- low/high note-values means we can resolve marked_notecol ...
        local marked_notecol = nil
        if marked_col.low_note then
          marked_notecol,marked_run_idx = self.runner:resolve_notecol(marked_col_idx,line_idx)
        end
        local assign_notecol = voice.voice_run[line_idx]
        local assign_note_value = assign_notecol and assign_notecol.note_value or nil
        local set_high_low = function()
          self.runner:set_high_low_column(marked_col_idx,assign_note_value,assign_note_value)
        end
        --print(">>> assign_note_value",assign_note_value)
        if not has_room then 
          -- check if replace is possible
          if marked_notecol 
            and not (marked_notecol.note_value >= renoise.PatternLine.NOTE_OFF)
            --and (marked_notecol.note_value >= assign_note_value)
            and (((self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH)
                and ((marked_col_idx < voice.col_idx)
                  and (marked_notecol.note_value > assign_note_value))
                or ((marked_col_idx > voice.col_idx)
                  and (marked_notecol.note_value < assign_note_value)))
              or ((self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW)
                and ((marked_col_idx < voice.col_idx)
                  and (marked_notecol.note_value < assign_note_value))
                or ((marked_col_idx > voice.col_idx)
                  and (marked_notecol.note_value > assign_note_value))))
          then
            --print(">>> assign_to_marked - no room - target note >= source note")
            local same_pos = (voice.col_idx == marked_col_idx)
              and (voice.run_idx == marked_run_idx)
            if same_pos then
              --print(">>> same_pos - pretend that assignment has taken place")
              set_high_low()
              assigned = true
              break
            else
              if self.runner:replace_run(voice,marked_col_idx,marked_run_idx,marked_notecol,line_idx) then
                set_high_low()
                assigned = true
                break
              end
            end --/same pos
          else 
            --print(">>> cant't replace - no room + no target notecol or lower note-value")
            -- shifting 
            -- + when we have a note-value
            -- + high/low columns are defined
            -- + note-value fits *within* high/row range (but not equal to)
            --print("self.runner.high_low_columns[marked_col_idx]",marked_col_idx,rprint(self.runner.high_low_columns[marked_col_idx]))
            --print("assign_note_value",assign_note_value)
            local range = self.runner.high_low_columns[marked_col_idx]
            if assign_note_value
              and not table.is_empty(self.runner.high_low_columns[marked_col_idx])
              and (range.low_note and range.high_note)
              and ((assign_note_value >= range.low_note) and (assign_note_value <= range.high_note))
              and not ((assign_note_value == range.low_note) and (assign_note_value == range.high_note))
            then
              local shift_upwards = (self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH) 
              if self.runner:shift_runs(voice,marked_col_idx,line_idx,shift_upwards) then
                set_high_low()
                assigned = true
                break
              end
            end
          end
        elseif has_room then
          if not marked_notecol 
            or (marked_notecol.note_value <= assign_note_value)  -- LOW/HIGH?
          then
            -- insert run in target column when target note is empty, equal to, or lower than
            marked_run_idx = marked_run_idx and marked_run_idx+1 or 1 -- 1 when empty
            --print(">>> assign_to_marked - assign - clear:",voice.col_idx,voice.run_idx,"set:",marked_col_idx,marked_run_idx,voice.voice_run)
            table.insert(voice_runs[marked_col_idx],marked_run_idx,voice.voice_run)
            self.runner:clear_in_column(voice.col_idx,voice.run_idx,line_idx)
            set_high_low()
            assigned = true
            break
          else
            --print(">>> skip marked column, target is higher...")
          end
        end
      end
    end

  end

  if not assigned then
    -- insert in rightmost marked column with a defined note-value
    --print("*** not assigned - self.marked_columns",rprint(self.marked_columns))  
    for k,v in ripairs(self.marked_columns) do
      local target_col_idx = v.column_index+1
      local is_same_column = (voice.col_idx == target_col_idx)
      if is_same_column then
        --print(">>> not assigned - is_same_column (skip)")
        local insert_note_val = voice.voice_run[line_idx].note_value
        self.runner:set_high_low_column(target_col_idx,insert_note_val,insert_note_val)
      else
        --print(">>> not assigned - insert as rightmost marked")
        self:insert_or_assign(voice,target_col_idx,line_idx)
      end
      return
    end
    -- everything else failed - insert as first column
    --print(">>> not assigned - insert as first")
    self:insert_or_assign(voice,1,line_idx)
  end

end

-------------------------------------------------------------------------------
-- assign a run into the given column - or insert column if no room
-- supports assign_to_marked()...

function xVoiceSorter:insert_or_assign(voice,col_idx,line_idx)
  TRACE("xVoiceSorter:insert_or_assign(voice,col_idx,line_idx)",voice,col_idx,line_idx)

  local voice_runs = self.runner.voice_runs

  --print(">>> insert_or_assign - clear:",voice.col_idx,voice.run_idx)
  if self.runner:clear_in_column(voice.col_idx,voice.run_idx,line_idx) then
    -- by clearing we also removed the column
    --print("*** insert_or_assign - voice.col_idx,col_idx",voice.col_idx,col_idx)
    if (voice.col_idx < col_idx) then
      col_idx = col_idx -1
      --print(">>> insert_or_assign - adjusted col_idx",col_idx)
    end
  end
  if voice_runs[col_idx] then
    local has_room,in_range = xVoiceRunner.has_room(voice_runs,line_idx,col_idx,voice.voice_run.number_of_lines)
    --print("*** insert_or_assign - has_room:",has_room)
    if has_room then -- target_col has room, find the run index
      --print("*** insert_or_assign - in_range...",rprint(in_range))
      local target_run_idx = 1+xVoiceRunner.get_most_recent_run_index(voice_runs[col_idx],line_idx)
      --print(">>> insert_or_assign - set:",col_idx,target_run_idx,voice.voice_run)
      table.insert(voice_runs[col_idx],target_run_idx,voice.voice_run)
      self.runner:set_high_low_column(col_idx,nil,nil,nil,line_idx)
      return
    end

  end
  -- if no room, insert new column
  --print(">>> insert_or_assign - insert:",col_idx,voice.voice_run)
  self.runner:insert_voice_column(col_idx,voice.voice_run)

end

-------------------------------------------------------------------------------
-- get marked column by column index 

function xVoiceSorter:get_marked_column(col_idx)
  TRACE("xVoiceSorter:get_marked_column(col_idx)",col_idx)

  for k,v in ipairs(self.marked_columns) do
    if (v.column_index == col_idx) then
      return v,k
    end
  end

end

-------------------------------------------------------------------------------
-- mark a column as an appropriate destination 

function xVoiceSorter:mark_column(col_idx,low_note,high_note)
  TRACE("xVoiceSorter:mark_column(col_idx,low_note,high_note)",col_idx,low_note,high_note)

  -- if already marked
  local marked_col = self:get_marked_column(col_idx)
  if marked_col then
    marked_col.low_note = low_note
    marked_col.high_note = high_note
    return
  end
  --print("self.marked_columns PRE",rprint(self.marked_columns))

  table.sort(self.marked_columns,function(e1,e2)
    return e1.column_index < e2.column_index
  end)

  -- clean up markers 
  local clear = false -- (high_note) and true or false
  for k,v in ripairs(self.marked_columns) do
    if not clear then
      if high_note 
        and (self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH)
        and v.high_note and (v.high_note < high_note) 
      then
        -- clear markers with a lower 'high' note-value
        clear = true
      elseif low_note
        and (self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW)
        and v.low_note and (v.low_note > high_note) 
      then
        -- clear markers with a higher 'low' note-value
        clear = true
      end
    end
    if clear then
      table.remove(self.marked_columns,k)
    end
  end

  -- add new marker
  table.insert(self.marked_columns,{
    column_index = col_idx,
    low_note = low_note,
    high_note = high_note,
  })
  --print("*** mark_column - add marker - ",col_idx,low_note,high_note)
  --print("self.marked_columns POST",rprint(self.marked_columns))

end

-------------------------------------------------------------------------------
-- sort by unique note-values (a single line)
-- @param line_runs (table)
-- @param line_idx (int)
-- @return bool, false when too many unique/overlapping notes 

function xVoiceSorter:sort_unique(line_runs,line_idx) 
  TRACE("xVoiceSorter:sort_unique(line_runs,line_idx)",#line_runs,line_idx)

  self.sorted = table.rcopy(line_runs)
  self:sort_line_runs(self.sorted,line_idx)

  -- insert 
  for k,voice in ipairs(self.sorted) do
    local notecol = xVoiceRunner.get_initial_notecol(voice.voice_run)
    --print("PROCESSING ----------------------------- ",notecol.note_string,notecol.instrument_value)
    local num_lines = voice.voice_run.number_of_lines
    local found_room,col_idx,in_range = self:find_unique_column(notecol,line_idx,num_lines)
    if not found_room then
      --print("*** sort_unique - insert column after this one",col_idx)
      -- TODO consider instrument index, should sort as well... 
      col_idx = col_idx+1
      xLib.sparse_table_insert(self.temp_runs,col_idx,{voice.voice_run})
      table.insert(self.unique_map,col_idx,{
        note_value = notecol.note_value,
        instrument_value = notecol.instrument_value
      })
    else
      --print("*** sort_unique - insert run into this column",col_idx)
      xLib.expand_table(self.temp_runs,col_idx)
      table.insert(self.temp_runs[col_idx],voice.voice_run)
      -- update the map with the instrument number - this will 
      -- cause the next find_unique_column() to be more precise
      self.unique_map[col_idx].instrument_value = notecol.instrument_value
    end
  end  

  --print("*** sort_unique - unique_map...",rprint(self.unique_map))

end


-------------------------------------------------------------------------------
-- check if a notecol belongs to a given unique column 
-- @param notecol (xNoteColumn)
-- @param col_idx (int)
-- @return bool, true when matched

function xVoiceSorter:matches_unique_column(notecol,col_idx)
  TRACE("xVoiceSorter:matches_unique_column(notecol,col_idx)",notecol,col_idx)

  local map = self.unique_map[col_idx]
  if not map then
    --print("*** matches_unique_column - unable to match unmapped column")
    return false
  end
  --print("*** matches_unique_column - map",rprint(map))
  --print("*** matches_unique_column - notecol",rprint(notecol))

  local can_sort_by_instr = function()
    return self.unique_instrument 
      and map.instrument_value
      and (notecol.instrument_value)
      --and (map.instrument_value < 255)
      --and (notecol.instrument_value < 255)
      and (notecol.note_value == map.note_value)
  end

  local sort_by_instr = can_sort_by_instr()
  --print("*** matches_unique_column - sort_by_instr",sort_by_instr)
  if sort_by_instr then
    return (notecol.instrument_value == map.instrument_value)
  else
    return (notecol.note_value == map.note_value)
  end

  return false

end

-------------------------------------------------------------------------------
-- look for remap column (matching note) with free space
-- @return bool, true when column exist + has available space 
-- @return int, column index (last matching column or column with room)
-- @return table, runs in range or nil

function xVoiceSorter:find_unique_column(notecol,line_idx,num_lines)
  TRACE("xVoiceSorter:find_unique_column(notecol,line_idx,num_lines)",notecol,line_idx,num_lines)

  local col_idx = nil 
  local found_room = false
  local has_room,in_range = nil,nil

  -- locate column, optionally taking instrument number into consideration
  for k,v in pairs(self.unique_map) do
    if self:matches_unique_column(notecol,k) then
      col_idx = k
      break
    end
  end
  --print("*** find_unique_column - col_idx #A",col_idx)

  -- failed to find column, probably because of instrument index
  -- (return the first with a matching note - _has_ to be present)
  if not col_idx then
    for k,v in pairs(self.unique_map) do
      if (v.note_value == notecol.note_value) then
        --print("*** failed to find column, return last matching note",k)
        return false,k        
      end
    end
  end

  --print("*** find_unique_column - temp_runs",rprint(self.temp_runs))

  repeat 
    has_room,in_range = xVoiceRunner.has_room(self.temp_runs,line_idx,col_idx,num_lines)
    if has_room then
      found_room = true
      break
    else
      col_idx = col_idx+1
    end
  until not self:matches_unique_column(notecol,col_idx)

  --print("*** find_unique_column - col_idx #B",col_idx)

  if not found_room then
    col_idx = col_idx-1
  end
  --print("*** find_unique_column - col_idx #C",col_idx)

  return found_room,col_idx,in_range

end

-------------------------------------------------------------------------------
-- Meta-methods
-------------------------------------------------------------------------------

function xVoiceSorter:__tostring()

  return type(self)
    ..", sort_mode="..tostring(self.sort_mode)

end
