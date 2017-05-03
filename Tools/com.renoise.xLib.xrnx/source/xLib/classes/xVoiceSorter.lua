--[[===============================================================================================
xVoiceSorter
===============================================================================================]]--

--[[--

Advanced sorting of pattern-data (including selections) 
.
#

See also: 
@{xVoiceRunner}


]]

class 'xVoiceSorter'

xVoiceSorter.SORT_MODES = {"Low → High","High → Low",}
xVoiceSorter.SORT_MODE = {
  LOW_TO_HIGH = 1,
  HIGH_TO_LOW = 2,
}

xVoiceSorter.SORT_METHODS = {
  "Normal",
  "Unique",
  "Compact",
}
xVoiceSorter.SORT_METHOD = {
  NORMAL = 1,
  UNIQUE = 2,
  COMPACT = 3,
}

xVoiceSorter.MAX_NOTE_COLUMNS = 12

xVoiceSorter.ERROR_CODE = {
  TOO_MANY_COLS = 1,
  CANT_PRESERVE_EXISTING = 2,
}

---------------------------------------------------------------------------------------------------

function xVoiceSorter:__init(...)
  TRACE("xVoiceSorter:__init(...)")

	local args = cLib.unpack_args(...)

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

  --- table, defines the high/low note values in each column
  -- (used when sorting by note)
  --  {
  --    low_note = int,
  --    high_note = int,
  --  }
  self.high_low_columns = {}

  --- table, sorted voice from one line of voice-runs 
  -- (see xVoiceRunner.get_runs_on_line()...)
  self.sorted = {}

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

end

---------------------------------------------------------------------------------------------------
-- call before a sort operation

function xVoiceSorter:reset()

  --self.sorted = {}
  self.unique_map = {}
  self.temp_runs = {}
  self.high_low_columns = {}

end

---------------------------------------------------------------------------------------------------
-- main function - sort a pattern-track, or part thereof
-- @param ptrack_or_phrase (renoise.PatternTrack or renoise.InstrumentPhrase)
-- @param selection (table), pattern-selection
-- @param trk_idx (number)
-- @param seq_idx (number)
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

  local collect_mode = xVoiceRunner.COLLECT_MODE.SELECTION
  self.runner:collect(ptrack_or_phrase,collect_mode,self.selection,trk_idx,seq_idx)

  local voice_runs = self.runner.voice_runs
  if table.is_empty(voice_runs) then
    return true
  end

  -- optimize: skip sorting when using particular methods
  -- on a single column (result would be identical anyway)
  if (#table.keys(voice_runs) == 1)
    and ((self.sort_method == xVoiceSorter.SORT_METHOD.NORMAL)
      or (self.sort_method == xVoiceSorter.SORT_METHOD.COMPACT))
  then
    LOG("Skip sorting single column with normal/compact method")
    return true
  end

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
    -- TODO merge with sort_line_runs()
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

  end

  -- sort - iterate through lines...
  for line_idx = self.selection.start_line,self.selection.end_line do

    local rslt,err = nil,nil
    local line_runs = xVoiceRunner.get_runs_on_line(voice_runs,line_idx)

    if (self.sort_method == xVoiceSorter.SORT_METHOD.NORMAL) then
      rslt,err = self:sort_by_note(line_runs,line_idx)
    elseif (self.sort_method == xVoiceSorter.SORT_METHOD.COMPACT) then
      rslt,err = self:sort_compact(line_runs,line_idx) 
    elseif (self.sort_method == xVoiceSorter.SORT_METHOD.UNIQUE) then
      rslt,err = self:sort_unique(line_runs,line_idx) 
      if (#self.unique_map > xVoiceSorter.MAX_NOTE_COLUMNS) then
        self.required_cols = table.rcopy(self.unique_map)
        return false,xVoiceSorter.ERROR_CODE.TOO_MANY_COLS
      end
    end

    if err then
      return false,err
    end

  end

  -- check which columns to merge into the result
  -- (unselected columns on either side)
  local low_col,high_col = cLib.get_table_bounds(voice_runs)
  local num_sorted_cols = #table.keys(self.temp_runs)
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

  -- columns with content on the right-hand side of the selection
  -- are shifted sideways before we write the output...
  if shift_from then
    -- shift amount is equal to left side of selection + 
    local selection_column_span = 1+self.selection.end_column-self.selection.start_column
    column_shift = math.abs(num_sorted_cols-selection_column_span)
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

  self.runner.voice_runs = self.temp_runs

  if shift_from then
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

---------------------------------------------------------------------------------------------------
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

---------------------------------------------------------------------------------------------------
-- sorting by note-value, one line at a time
-- @param line_runs (table), see get_runs_on_line()
-- @param line_idx (int) the line index

function xVoiceSorter:sort_by_note(line_runs,line_idx)
  TRACE("xVoiceSorter:sort_by_note(line_runs,line_idx)",line_runs,line_idx)

  self.sorted = table.rcopy(line_runs)
  self:sort_line_runs(self.sorted,line_idx)

  local low_col,high_col = self.selection.start_column,self.selection.end_column

  for k,voice in ipairs(self.sorted) do

    local num_lines = voice.voice_run.number_of_lines
    local notecol = xVoiceRunner.get_initial_notecol(voice.voice_run)


    local found_room,col_idx,upwards = self:find_note_column(notecol.note_value,line_idx,num_lines)

    if found_room then
      cLib.expand_table(self.temp_runs,col_idx)
      table.insert(self.temp_runs[col_idx],voice.voice_run)
      self:set_high_low_column(col_idx,notecol.note_value,notecol.note_value)
    else
      local initial_column = not col_idx
      local exact_match = false
      if initial_column then
        col_idx = 1
      else
        local v = self.high_low_columns[col_idx]
        if v then 
          exact_match = (notecol.note_value == v.low_note)
            and (notecol.note_value == v.high_note)
        end
      end

      -- create column (but wait with assign...)
      self:insert_temp_column(col_idx)

      -- shift existing notes?
      if not initial_column and not exact_match then
        local source_col_idx = upwards and col_idx-1 or col_idx
        local target_col_idx = upwards and col_idx or col_idx+1
        local shifted = self:shift_runs(notecol.note_value,source_col_idx,target_col_idx,line_idx-1) 
        if shifted then -- check where we've got room 
          found_room,col_idx = self:find_note_column(notecol.note_value,line_idx,num_lines)
        end
      end
      self:insert_note_run(col_idx,voice.voice_run,line_idx)
    end

  end

end

---------------------------------------------------------------------------------------------------
-- look for a matching note column (with or without available space)
-- @return bool, true when column has space 
-- @return int, column index (when no space, "where to create column")
-- @return bool, when true, column is 'after'

function xVoiceSorter:find_note_column(note_value,line_idx,num_lines)
  TRACE("xVoiceSorter:find_note_column(note_value,line_idx,num_lines)",note_value,line_idx,num_lines)

  local has_room = nil
  local marked_cols = {}

  -- initially, no columns are created and high/low is empty
  if table.is_empty(self.high_low_columns) then
    return false
  end

  local low_col,high_col = cLib.get_table_bounds(self.temp_runs)

  -- mark column, while maintaining previous marks
  local do_mark_column = function(col_idx)

    local clear_to = nil
    local clear_from = nil
    local prev_high,prev_low

    marked_cols[col_idx] = true

    for k = low_col,high_col do
      if marked_cols[k] then
        local v = self.high_low_columns[k]
        if (self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW) then
          if prev_low and (prev_low > v.low_note) 
            and (note_value <= v.low_note)
          then
            -- better match than previous column
            clear_to = k-1
          end
          if prev_low and (prev_low > v.high_note)
            and (note_value <= v.high_note)
          then
            -- better match than previous column
            clear_to = k-1
          end
          if prev_high and (prev_high < note_value) then
            -- previous column a better match
            clear_from = k
          end
          --[[
          if prev_low and (prev_low < note_value) then
            -- previous column a better match
            clear_from = k
          end
          ]]

        elseif (self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH) then
          if prev_high and (prev_high < v.low_note) 
            and (note_value >= v.low_note)
          then 
            -- better match than previous column
            clear_to = k-1
          end
            
          if prev_high and (prev_high < v.high_note) 
            and (note_value >= v.low_note)
          then
            -- better match than previous column
            clear_to = k-1
          end

          if prev_low and (prev_low > note_value) then
            -- previous column a better match
            clear_from = k
          end
          if prev_high and (prev_high > note_value) then
            -- previous column a better match
            clear_from = k
          end

        end
        prev_high = v.high_note
        prev_low = v.low_note
      end
    end

    if clear_from then
      for k = clear_from,high_col do
        if marked_cols[k] then
          marked_cols[k] = false
        end
      end
    end

    if clear_to then
      for k = 1,clear_to do
        if marked_cols[k] then
          marked_cols[k] = false
        end
      end
    end

  end

  -- go through high/low columns, mark appropriate ones
  -- while paying special attention to exact matches
  for col_idx,v in pairs(self.high_low_columns) do
    if (note_value == v.low_note)
      and (note_value == v.high_note)
    then
      has_room = xVoiceRunner.has_room(self.temp_runs,line_idx,col_idx,num_lines)
      if has_room then
        return true,col_idx
      else
        do_mark_column(col_idx)
      end
    else
      do_mark_column(col_idx)
    end

  end

  -- failed to find exact match of column - 
  -- check marked columns and return first one with room
  for col_idx = low_col,high_col do
    if marked_cols[col_idx] then
      has_room = xVoiceRunner.has_room(self.temp_runs,line_idx,col_idx,num_lines)
      if has_room then
        return true,col_idx
      end
    end
  end

  local check_columns = function(col_idx)
    local v = self.high_low_columns[col_idx]
    if v.high_note then
      
      local in_range = (v.low_note <= note_value) 
        and (v.high_note >= note_value)

      if (self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW) then
        if in_range then
          return false,col_idx+1,true
        elseif (v.low_note >= note_value) then
          return false,col_idx+1,true
        else
          return false,col_idx
        end
      elseif (self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH) then
        if in_range then
          return false,col_idx+1,true
        elseif (v.high_note <= note_value) then
          return false,col_idx+1,true
        elseif (v.high_note >= note_value) then
          return false,col_idx
        end
      end
    end
  end

  -- no marked column had room, insert a new column 
  -- using the markings as basis...
  for col_idx = low_col,high_col do
    if marked_cols[col_idx] then
      local has_room,idx,upwards = check_columns(col_idx)
      if (type(has_room)=="boolean") then
        return has_room,idx,upwards
      end
    end
  end

  -- final option: check columns, marked or not
  for col_idx = low_col,high_col do
    local has_room,idx,upwards = check_columns(col_idx)
    if (type(has_room)=="boolean") then
      return has_room,idx,upwards
    end
  end

  error("shouldn't get here - at least one marked column") 

end


---------------------------------------------------------------------------------------------------
-- look for previous notes which are equal/higher, move to target column 
-- (important: target should be empty or voice-runs could be overwritten)
-- return bool (true when shifting took place)

function xVoiceSorter:shift_runs(note_value,source_col_idx,target_col_idx,line_idx)
  TRACE("xVoiceSorter:shift_runs(note_value,source_col_idx,target_col_idx,line_idx)",note_value,source_col_idx,target_col_idx,line_idx)

  assert(type(note_value)=="number")
  assert(type(source_col_idx)=="number")
  assert(type(target_col_idx)=="number")
  assert(type(line_idx)=="number")

  if (line_idx < 1) then
    -- no shifting, line_idx is too small
    return false
  end

  local source_run_col = self.temp_runs[source_col_idx]

  if not source_run_col then
    -- no shifting, column is empty
    return false
  end

  local high_note,low_note = xVoiceRunner.get_high_low_note_values(source_run_col,1,line_idx)

  if not high_note then
    -- no shifting, source_run_col contains no notes
    return false
  end

  if (note_value == high_note)
    and (note_value == low_note) 
  then
    -- no shifting, notes are equal
    return false
  end

  if (note_value > high_note) 
    or (note_value < low_note) 
  then
    -- no shifting, all notes are higher or lower
    return false
  end

  local higher_runs = xVoiceRunner.get_higher_notes_in_column(self.temp_runs[source_col_idx],note_value-1)
  local highest_run_idx = 1
  if not table.is_empty(higher_runs) then
    for k = 1,#higher_runs do
      local higher_run = source_run_col[higher_runs[k].run_idx]
      highest_run_idx = k
      table.insert(self.temp_runs[target_col_idx],k,higher_run)
      self:clear_temp_run(source_col_idx,higher_runs[k].run_idx,higher_runs[k].line_idx) 
    end
    self:set_high_low_column(target_col_idx,nil,nil,nil,line_idx)
    self:set_high_low_column(source_col_idx,nil,nil,nil,line_idx) 
    return true
  end

  return false

end

---------------------------------------------------------------------------------------------------
-- convenience method, clear a given run 
-- + will also remove the column if no runs are left...

function xVoiceSorter:clear_temp_run(col_idx,run_idx) 
  TRACE("xVoiceSorter:clear_temp_run(col_idx,run_idx)",col_idx,run_idx)

  local run_col = self.temp_runs[col_idx]

  if not run_col[run_idx] then
    return
  end

  run_col[run_idx] = nil
  if table.is_empty(run_col) then
    self:remove_temp_column(col_idx)
  end

end

---------------------------------------------------------------------------------------------------
-- remove temp column, maintain high/low table

function xVoiceSorter:remove_temp_column(col_idx)
  TRACE("xVoiceSorter:remove_temp_column(col_idx)",col_idx)

  table.remove(self.temp_runs,col_idx)
  table.remove(self.high_low_columns,col_idx)

end

---------------------------------------------------------------------------------------------------
-- insert temp column, maintain high/low table

function xVoiceSorter:insert_temp_column(col_idx,voice_run)
  TRACE("xVoiceSorter:insert_temp_column(col_idx,voice_run)",col_idx,voice_run)

  assert(type(col_idx)=="number")

  table.insert(self.temp_runs,col_idx,{voice_run})
  table.insert(self.high_low_columns,col_idx,{})

  local high_note,low_note = xVoiceRunner.get_high_low_note_values(self.temp_runs[col_idx])
  self:set_high_low_column(col_idx,high_note,low_note)

end

---------------------------------------------------------------------------------------------------
-- maintain high/low note-values in column
-- @param col_idx (int)
-- @param high_note (int)
-- @param low_note (int)
-- @param force (bool), if defined the high/low values are explicitly set 
--  (otherwise they will expand the already existing range)
-- @param line_idx (int), set to high/low of existing runs until this line

function xVoiceSorter:set_high_low_column(col_idx,high_note,low_note,force,line_idx)
  TRACE("xVoiceSorter:set_high_low_column(col_idx,high_note,low_note,force,line_idx)",col_idx,high_note,low_note,force,line_idx)

  assert(type(col_idx)=="number")

  if line_idx then
    -- figure out from existing runs until line
    local run_col = self.temp_runs[col_idx]
    local start_line,end_line = xVoiceRunner.get_column_start_end_line(run_col)
    if start_line and (start_line < line_idx) then
      local high_note,low_note = xVoiceRunner.get_high_low_note_values(run_col,start_line,line_idx)
      self:set_high_low_column(col_idx,high_note,low_note,true)
    else
      self:set_high_low_column(col_idx,nil,nil,true)
    end
    return
  end

  local t = self.high_low_columns[col_idx]

  if t then
    -- updating existing entry
  
    if force then
      t.high_note = high_note
      t.low_note = low_note
    else
      -- expand range of existing value or set to provided value
      if t.high_note then
        t.high_note = high_note and math.max(high_note,t.high_note) or nil
      else
        t.high_note = high_note 
      end
      if t.low_note then
        t.low_note = low_note and math.min(low_note,t.low_note) or nil
      else
        t.low_note = low_note
      end
    end
  else
    -- inserting new entry
    self.high_low_columns[col_idx] = {
      low_note = low_note,
      high_note = high_note,
    }
  end

end

---------------------------------------------------------------------------------------------------
-- insert a voice-run, and shift existing entries if needed
-- invoked by sort_by_note() - 

function xVoiceSorter:insert_note_run(col_idx,voice_run,line_idx)
  TRACE("xVoiceSorter:insert_note_run(col_idx,voice_run)",col_idx,voice_run)

  -- TODO
  --[[

  local notecol = xVoiceRunner.get_initial_notecol(voice_run)

  local source_col_idx = col_idx
  local target_col_idx = nil

  -- find the most suitable target column, create if needed
  -- testcase: Unique III (low-high), 

  local shifted = self:shift_runs(notecol.note_value,source_col_idx,target_col_idx,line_idx-1) 
  if shifted then -- check where we've got room 
    found_room,col_idx = self:find_note_column(notecol.note_value,line_idx,num_lines)
  end
  ]]

  -- assign to new column
  cLib.expand_table(self.temp_runs,col_idx)
  table.insert(self.temp_runs[col_idx],voice_run)
  self:set_high_low_column(col_idx,nil,nil,nil,line_idx+1)

end

---------------------------------------------------------------------------------------------------
-- sort note-values, unique style 
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
    --TRACE("PROCESSING ----------------------------- ",notecol.note_string,notecol.instrument_value)
    local num_lines = voice.voice_run.number_of_lines
    local found_room,col_idx = self:find_unique_column(notecol,line_idx,num_lines)
    if not found_room then
      -- TODO consider instrument index, should sort as well... 
      col_idx = col_idx+1
      self:insert_temp_column(col_idx,voice.voice_run)

      table.insert(self.unique_map,col_idx,{
        note_value = notecol.note_value,
        instrument_value = notecol.instrument_value
      })
    else
      cLib.expand_table(self.temp_runs,col_idx)
      table.insert(self.temp_runs[col_idx],voice.voice_run)
      -- update the map with the instrument number - this will 
      -- cause the next find_unique_column() to be more precise
      self.unique_map[col_idx].instrument_value = notecol.instrument_value
    end
  end  

end

---------------------------------------------------------------------------------------------------
-- look for remap column (matching note) with free space
-- @return bool, true when column exist + has available space 
-- @return int, column index (last matching column or column with room)

function xVoiceSorter:find_unique_column(notecol,line_idx,num_lines)
  TRACE("xVoiceSorter:find_unique_column(notecol,line_idx,num_lines)",notecol,line_idx,num_lines)

  local col_idx = nil 
  local found_room = false
  local has_room = nil

  -- locate column, optionally taking instrument number into consideration
  for k,v in pairs(self.unique_map) do
    if self:matches_unique_column(notecol,k) then
      col_idx = k
      break
    end
  end
  -- failed to find column, probably because of instrument index
  -- (return the first with a matching note - _has_ to be present)
  if not col_idx then
    for k,v in pairs(self.unique_map) do
      if (v.note_value == notecol.note_value) then
        return false,k        
      end
    end
  end

  repeat 
    has_room = xVoiceRunner.has_room(self.temp_runs,line_idx,col_idx,num_lines)
    if has_room then
      found_room = true
      break
    else
      col_idx = col_idx+1
    end
  until not self:matches_unique_column(notecol,col_idx)

  if not found_room then
    col_idx = col_idx-1
  end
  return found_room,col_idx

end

---------------------------------------------------------------------------------------------------
-- check if a notecol belongs to a given unique column 
-- @param notecol (xNoteColumn)
-- @param col_idx (int)
-- @return bool, true when matched

function xVoiceSorter:matches_unique_column(notecol,col_idx)
  TRACE("xVoiceSorter:matches_unique_column(notecol,col_idx)",notecol,col_idx)

  local map = self.unique_map[col_idx]
  if not map then
    -- unable to match unmapped column
    return false
  end

  local can_sort_by_instr = function()
    return self.unique_instrument 
      and map.instrument_value
      and (notecol.instrument_value)
      and (notecol.note_value == map.note_value)
  end

  local sort_by_instr = can_sort_by_instr()
  if sort_by_instr then
    return (notecol.instrument_value == map.instrument_value)
  else
    return (notecol.note_value == map.note_value)
  end

  return false

end

---------------------------------------------------------------------------------------------------
-- sort note-values, compact style
-- @param line_runs (table)
-- @param line_idx (int)
-- @return bool, false when too many unique/overlapping notes 

function xVoiceSorter:sort_compact(line_runs,line_idx) 
  TRACE("xVoiceSorter:sort_compact(line_runs,line_idx)",#line_runs,line_idx)

  self.sorted = table.rcopy(line_runs)
  self:sort_line_runs(self.sorted,line_idx)

  for k,voice in ipairs(self.sorted) do

    local num_lines = voice.voice_run.number_of_lines
    local col_idx = self:find_compact_column(line_idx,num_lines)
    local column_exist = self.temp_runs[col_idx]
    if not column_exist then
      self:insert_temp_column(col_idx,voice.voice_run)
    else
      cLib.expand_table(self.temp_runs,col_idx)
      table.insert(self.temp_runs[col_idx],voice.voice_run)
    end
  end  

end

---------------------------------------------------------------------------------------------------
-- @return int, column index

function xVoiceSorter:find_compact_column(line_idx,num_lines)

  local col_idx = 1
  local found_room = false

  repeat 
    if xVoiceRunner.has_room(self.temp_runs,line_idx,col_idx,num_lines) then 
      found_room = true
      break
    else
      col_idx = col_idx+1
    end
  until not self.temp_runs[col_idx]

  return col_idx

end

---------------------------------------------------------------------------------------------------
-- Meta-methods
---------------------------------------------------------------------------------------------------

function xVoiceSorter:__tostring()

  return type(self)
    ..", sort_mode="..tostring(self.sort_mode)

end
