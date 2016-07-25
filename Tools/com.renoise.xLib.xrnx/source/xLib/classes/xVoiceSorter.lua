--[[============================================================================
xVoiceSorter
============================================================================]]--

--[[--

Advanced sorting of pattern-data (including selections) 
.
#

Relies heavily on xVoiceRunner, containing the actual data

PLANNED 

* multi-pattern: inject voices that are carried over from previous pattern 
* selections: consider that the number of columns might grow as a result of sorting


]]


class 'xVoiceSorter'

xVoiceSorter.SORT_MODES_FULL = {
  "Auto : low-to-high",
  "Auto : high-to-low",
  "Auto : unique columns",
  "Custom",
}
xVoiceSorter.SORT_MODES = {
  "Low > High",
  "High > Low",
  "Unique Cols",
  "Custom",
}

xVoiceSorter.SORT_MODE = {
  LOW_TO_HIGH = 1,
  HIGH_TO_LOW = 2,
  UNIQUE = 3,
  CUSTOM = 4,
}

-------------------------------------------------------------------------------

function xVoiceSorter:__init(...)
  TRACE("xVoiceSorter:__init(...)")

	local args = xLib.unpack_args(...)

  -- xVoiceRunner
  self.runner = args.runner

  -- xVoiceSorter.SORT_MODE
  self.sort_mode = args.sort_mode or xVoiceSorter.SORT_MODE.LOW_TO_HIGH

  -- table, indicating appropriate destination column(s)
  -- (defined while processing each line...)
  --  {
  --    column_index = int,
  --    low_note = int,
  --    high_note = int,
  --  }
  self.marked_columns = {}

  --- table, defines the high/low note values in each column
  -- (set as we begin sorting and kept/updated throughout...)
  --  {
  --    column_index = int,
  --    low_note = int,
  --    high_note = int,
  --  }
  self.high_low_columns = {}

  --- table, sorted entries from one line of voice-runs 
  self.sorted = {}

end

-------------------------------------------------------------------------------
-- main function - sort a pattern-track, or part thereof
-- @param ptrack, renoise.PatternTrack
-- @param trk_idx, int 
-- @param patt_sel, table (pattern-selection)

function xVoiceSorter:sort(ptrack,trk_idx,seq_idx,patt_sel)
  TRACE("xVoiceSorter:sort(ptrack,trk_idx,seq_idx,patt_sel)",ptrack,trk_idx,seq_idx,patt_sel)

  assert(type(ptrack)=="PatternTrack")
  assert(type(trk_idx)=="number")
  assert(type(seq_idx)=="number")
  assert(type(patt_sel)=="table")

  self.patt_sel = patt_sel

  local collect_mode = xVoiceRunner.COLLECT_MODE.SELECTION
  self.runner:collect_from_pattern(ptrack,collect_mode,trk_idx,seq_idx,self.patt_sel)

  local voice_runs = self.runner.voice_runs
  if table.is_empty(voice_runs) then
    --print("xVoiceSorter - can't sort empty table...")
    return 
  end
  --print("*** sort - voice_runs PRE",rprint(voice_runs))

  self.high_low_columns = {}

  print("*** sort - self.sort_mode",self.sort_mode)

  if (self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH) then
    for line_idx = self.patt_sel.start_line,self.patt_sel.end_line do
      local line_runs = xVoiceSorter.get_runs_on_line(voice_runs,line_idx)
      self:sort_low_to_high(line_runs,line_idx,self.patt_sel)
    end
  elseif (self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW) then
    for line_idx = self.patt_sel.start_line,self.patt_sel.end_line do
      local line_runs = xVoiceSorter.get_runs_on_line(voice_runs,line_idx)
      self:sort_high_to_low(line_runs,line_idx,self.patt_sel)
    end
  elseif (self.sort_mode == xVoiceSorter.SORT_MODE.UNIQUE) then
    -- TODO if more than twelve, ask which ones to keep
    -- create a remap table and pass on to SORT_MODE.CUSTOM
  elseif (self.sort_mode == xVoiceSorter.SORT_MODE.CUSTOM) then
    -- TODO  
  end

  --print("post-sort",rprint(voice_runs))

  self.runner:write_to_pattern(ptrack,trk_idx,self.patt_sel)
  self.runner:purge_voices()

end


-------------------------------------------------------------------------------
-- low to high sorting, one line at a time
-- @param line_runs (table), see get_runs_on_line()
-- @param line_idx (int) the line index
-- @return int or nil, number means 'go back and re-iterate from here' 

function xVoiceSorter:sort_low_to_high(line_runs,line_idx)
  TRACE("xVoiceSorter:sort_low_to_high(line_runs,line_idx)",line_runs,line_idx)

  local voice_runs = self.runner.voice_runs

  -- sort line by note value
  self.sorted = table.rcopy(line_runs)
  table.sort(self.sorted,function(e1,e2)
    return e1.voice_run[line_idx].note_value < e2.voice_run[line_idx].note_value
  end)
  --print("*** sort_low_to_high - sorted",rprint(self.sorted))

  local low_col,high_col = self.patt_sel.start_column,self.patt_sel.end_column
  --print("low_col,high_col",low_col,high_col)

  for k,v in ipairs(self.sorted) do

    --print("*** processing sorted note...",k,v.voice_run[line_idx].note_string,v.voice_run[line_idx].note_value,"==============================")
    --print("*** high_low_columns...",rprint(self.high_low_columns))

    self.marked_columns = {}   

    local same_column_idx = nil -- int, when we have found 'ourselves' 
    local assigned = false      -- bool, true when we could assign to a column

    for col_idx = low_col,high_col do

      local run_col = voice_runs[col_idx]
      if not run_col then
        LOG("*** sort_low_to_high - skip column (no voice-run)",col_idx)
      else
        -- establish highest/lowest note-value prior to this line
        -- (re-iterating will include already processed lines)
        local low_note,high_note = nil,nil
        local high_low_col = self:get_high_low_column(col_idx) 
        if high_low_col then
          -- look at cached values
          low_note,high_note = high_low_col.low_note,high_low_col.high_note
        else
          -- look through prior lines in this column
          local line_end = (line_idx == 1) and line_idx or line_idx-1
          high_note,low_note = xVoiceRunner.get_high_low_note_values(run_col,self.patt_sel.start_line,line_end)
        end

        --[[
        if high_note then
          print("*** col_idx,low_note,high_note",col_idx,xNoteColumn.note_value_to_string(low_note),xNoteColumn.note_value_to_string(high_note))
        else
          print("*** col_idx,low_note,high_note",col_idx,low_note,high_note)
        end
        ]]
  
        -- for convenience
        local mark_column = function()
          self:mark_column(col_idx,low_note,high_note)
        end

        local sorted_note = v.voice_run[line_idx].note_value
        --print("sorted_note",sorted_note)

        if not high_note then
          -- no note, but that doesn't mean that this is an appropriate
          -- column - only once we reach an *inappropriate* column will
          -- we know for sure... 
          --print(">>> no note - remember column",col_idx)
          mark_column()
        else
          if (high_note > sorted_note) then
            --print(">>> target is higher than",col_idx)
            local has_marked_columns = (#self.marked_columns > 0)
            if (low_note <= sorted_note) then
              --print(">>> higher than - target already contains equal or lower note")
              mark_column()
            elseif has_marked_columns then
              --print(">>> higher than - already found a possible spot")     
              self:assign_to_marked(v,line_idx)
              assigned = true
              break
            else
              --print(">>> higher than - insert? (no marked column and replace not possible)")
              self:clear_in_column(v.col_idx,v.run_idx,line_idx)
              self:insert_column(k,v.voice_run,line_idx)
              assigned = true
              break
            end
          elseif (high_note <= sorted_note) then
            --print(">>> target is lower than or equal to",col_idx)
            mark_column()
          end
        end --/high_note

      end --/run_col

    end

    if not assigned then
      if same_column_idx then
        --print(">>> reached end - same column, marked...",same_column_idx,rprint(self.marked_columns))
        local last_marked_column = self.marked_columns[#self.marked_columns].column_index
        if (last_marked_column - same_column_idx > 1) then
          --print(">>> reached end - skipped one or more columns along the way")
          self:assign_to_marked(v,line_idx)
        else
          --print(">>> reached end - same column was prior, do nothing")
        end
      else
        --print(">>> reached end - marked columns",rprint(self.marked_columns))
        self:assign_to_marked(v,line_idx)
      end
    end

  end

end

-------------------------------------------------------------------------------
-- low to high sorting, one line at a time
-- @param line_runs (table), see get_runs_on_line()
-- @param line_idx (int) the line index
-- @return int or nil, number means 'go back and re-iterate from here' 

function xVoiceSorter:sort_high_to_low(line_runs,line_idx)
  TRACE("xVoiceSorter:sort_high_to_low(line_runs,line_idx)",line_runs,line_idx)

  local voice_runs = self.runner.voice_runs

  -- sort line by note value
  self.sorted = table.rcopy(line_runs)
  table.sort(self.sorted,function(e1,e2)
    return e1.voice_run[line_idx].note_value > e2.voice_run[line_idx].note_value
  end)
  --print("*** sort_high_to_low - sorted",rprint(self.sorted))

  local low_col,high_col = self.patt_sel.start_column,self.patt_sel.end_column
  --print("low_col,high_col",low_col,high_col)

  for k,v in ipairs(self.sorted) do

    --print("*** processing sorted note...",k,v.voice_run[line_idx].note_string,v.voice_run[line_idx].note_value,"==============================")
    --print("*** high_low_columns...",rprint(self.high_low_columns))

    self.marked_columns = {}   

    local same_column_idx = nil -- int, when we have found 'ourselves' 
    local assigned = false      -- bool, true when we could assign to a column

    for col_idx = high_col,low_col do

      local run_col = voice_runs[col_idx]
      if not run_col then
        LOG("*** sort_high_to_low - skip column (no voice-run)",col_idx)
      else
        -- establish highest/lowest note-value prior to this line
        -- (re-iterating will include already processed lines)
        local low_note,high_note = nil,nil
        local high_low_col = self:get_high_low_column(col_idx) 
        if high_low_col then
          -- look at cached values
          low_note,high_note = high_low_col.low_note,high_low_col.high_note
        else
          -- look through prior lines in this column
          local line_end = (line_idx == 1) and line_idx or line_idx-1
          high_note,low_note = xVoiceRunner.get_high_low_note_values(run_col,self.patt_sel.start_line,line_end)
        end

        --[[
        if high_note then
          print("*** col_idx,low_note,high_note",col_idx,xNoteColumn.note_value_to_string(low_note),xNoteColumn.note_value_to_string(high_note))
        else
          print("*** col_idx,low_note,high_note",col_idx,low_note,high_note)
        end
        ]]
  
        -- for convenience
        local mark_column = function()
          self:mark_column(col_idx,low_note,high_note)
        end

        local sorted_note = v.voice_run[line_idx].note_value
        --print("sorted_note",sorted_note)

        if not high_note then
          -- no note, but that doesn't mean that this is an appropriate
          -- column - only once we reach an *inappropriate* column will
          -- we know for sure... 
          --print(">>> no note - remember column",col_idx)
          mark_column()
        else
          if (high_note <= sorted_note) then
            --print(">>> target is lower or equal to",col_idx)
            local has_marked_columns = (#self.marked_columns > 0)
            if (low_note > sorted_note) then
              --print(">>> lower than - target already contains higher note")
              mark_column()
            elseif has_marked_columns then
              --print(">>> lower than - found a possible spot")     
              self:assign_to_marked(v,line_idx)
              assigned = true
              break
            else
              --print(">>> lower than - insert? (no marked column and replace not possible)")
              self:clear_in_column(v.col_idx,v.run_idx,line_idx)
              self:insert_column(k,v.voice_run,line_idx)
              assigned = true
              break
            end
          elseif (high_note > sorted_note) then
            --print(">>> target is higher than ",col_idx)
            mark_column()
          end
        end --/high_note

      end --/run_col

    end

    if not assigned then
      if same_column_idx then
        --print(">>> reached end - same column, marked...",same_column_idx,rprint(self.marked_columns))
        local last_marked_column = self.marked_columns[#self.marked_columns].column_index
        if (last_marked_column - same_column_idx > 1) then
          --print(">>> reached end - skipped one or more columns along the way")
          self:assign_to_marked(v,line_idx)
        else
          --print(">>> reached end - same column was prior, do nothing")
        end
      else
        --print(">>> reached end - marked columns",rprint(self.marked_columns))
        self:assign_to_marked(v,line_idx)
      end
    end

  end

end

-------------------------------------------------------------------------------

function xVoiceSorter:set_high_low_column(col_idx,high_note,low_note)
  TRACE("xVoiceSorter:set_high_low_column(col_idx,high_note,low_note)",col_idx,high_note,low_note)

  -- TODO alternative mode for updating values
  -- supply a single value, and it will expand min & max 
  -- supply two values, and you set min/max explicitly

  local t = self:get_high_low_column(col_idx)
  if t then
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
  else
    table.insert(self.high_low_columns,{
      column_index = col_idx,
      low_note = low_note,
      high_note = high_note,
    })
  end

  table.sort(self.high_low_columns,function(e1,e2)
    return e1.column_index < e2.column_index
  end)

  --print("*** set_high_low_column",rprint(self.high_low_columns))

end

-------------------------------------------------------------------------------

function xVoiceSorter:get_high_low_column(col_idx)

  for k,v in ipairs(self.high_low_columns) do
    if (v.column_index == col_idx) then
      return v,k
    end
  end

end

-------------------------------------------------------------------------------
-- get marked column by column index 

function xVoiceSorter:get_marked_column(col_idx)

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
    --print("*** update existing marker")
    marked_col.low_note = low_note
    marked_col.high_note = high_note
    return
  end
  --print("self.marked_columns PRE",rprint(self.marked_columns))

  table.sort(self.marked_columns,function(e1,e2)
    return e1.column_index < e2.column_index
  end)

  -- clean up markers 
  -- + any marker with a lower note-value, and those before it
  local clear = (high_note) and true or false
  for k,v in ripairs(self.marked_columns) do
    if not clear and high_note and v.high_note and (v.high_note <= high_note) then
      --print(">>> start to clear",v.high_note)
      clear = true
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
-- insert the provided voice-run in a new column
-- @param v (table), see get_runs_on_line()
-- @param col_idx (int), the target column

function xVoiceSorter:insert_column(col_idx,voice_run,line_idx) 
  TRACE("xVoiceSorter:insert_column(col_idx,voice_run,line_idx)",col_idx,voice_run,line_idx)

  local voice_runs = self.runner.voice_runs

  --print("insert_column - clear:",v.col_idx,v.run_idx,"insert:",col_idx,1)
  --self:clear_in_column(v.col_idx,v.run_idx,line_idx)
  table.insert(voice_runs,col_idx,{voice_run})

  -- adjust column indices on the fly
  for k,v in ipairs(self.sorted) do
    if (v.col_idx >= col_idx) then v.col_idx = v.col_idx+1 end
  end
  for k,v in ipairs(self.marked_columns) do
    if (v.column_index >= col_idx) then v.column_index = v.column_index+1 end
  end
  for k,v in ipairs(self.high_low_columns) do
    if (v.column_index >= col_idx) then v.column_index = v.column_index+1 end
  end

  -- update high_low_columns
  local high_note,low_note = xVoiceRunner.get_high_low_note_values(voice_runs[col_idx])
  self:set_high_low_column(col_idx,high_note,low_note)

end

-------------------------------------------------------------------------------
-- clear a voice-run from a column + remove column if empty

function xVoiceSorter:clear_in_column(col_idx,run_idx,line_idx) 
  TRACE("xVoiceSorter:clear_in_column(col_idx,run_idx,line_idx)",col_idx,run_idx,line_idx)

  local run_col = self.runner.voice_runs[col_idx]
  if not run_col[run_idx] then
    print("*** clear_in_column - voice-run not found")
    return
  end

  if not run_col[run_idx].__replaced then
    --print("*** clear_in_column - run indices",rprint(table.keys(run_col)))
    run_col[run_idx] = nil
    -- update high_low_columns (look through prior lines)
    local start_line,end_line = xVoiceRunner.get_column_start_end_line(run_col)
    if start_line 
      and (start_line < line_idx)
    then
      --print("*** clear_in_column - start_line,end_line",start_line,end_line)
      local high_note,low_note = xVoiceRunner.get_high_low_note_values(run_col,start_line,line_idx)
      --print("*** clear_in_column - refresh low/high note",low_note,high_note)
      self:set_high_low_column(col_idx,high_note,low_note)
    else
      self:set_high_low_column(col_idx,nil,nil)
    end
    if table.is_empty(run_col) then
      self:remove_column(col_idx)
    end
  else
    print("*** clear_in_column - this voice-run was __replaced (protected from being cleared)")
  end

end

-------------------------------------------------------------------------------
-- remove a column 
-- @param col_idx (int)

function xVoiceSorter:remove_column(col_idx) 
  TRACE("xVoiceSorter:remove_column(col_idx)",col_idx)

  local voice_runs = self.runner.voice_runs
  table.remove(voice_runs,col_idx)

  -- adjust column indices on the fly
  for k,v in ipairs(self.sorted) do
    if (v.col_idx >= col_idx) then v.col_idx = v.col_idx-1 end
  end
  for k,v in ipairs(self.marked_columns) do
    if (v.column_index >= col_idx) then v.column_index = v.column_index-1 end
  end
  for k,v in ipairs(self.high_low_columns) do
    if (v.column_index == col_idx) then table.remove(self.high_low_columns,k) end
    if (v.column_index >= col_idx) then v.column_index = v.column_index-1 end
  end

end

-------------------------------------------------------------------------------
-- traverse through the table of marked columns and find the
-- first one which has room for our voice-run - or insert new column
-- @param v (table), one of our line-runs
-- @param line_idx (int)

function xVoiceSorter:assign_to_marked(v,line_idx) 
  TRACE("xVoiceSorter:assign_to_marked(v,line_idx)",v,line_idx)

  --print("*** assign_to_marked - self.marked_columns",rprint(self.marked_columns))  

  local voice_runs = self.runner.voice_runs
  local assigned = false

  for _,marked_col in ipairs(self.marked_columns) do

    local marked_col_idx = marked_col.column_index
    local target_run_idx = nil 
    local run_col = voice_runs[marked_col_idx]
    
    -- first, check if the source and target column is the same
    --print("*** assign_to_marked - v.col_idx,marked_col_idx",v.col_idx,marked_col_idx)
    local is_same_column = (v.col_idx == marked_col_idx)
    if is_same_column then
      --print(">>> same column - pretend that assignment has taken place")

      local low_line,high_line = xLib.get_table_bounds(v.voice_run)
      local assign_notecol = v.voice_run[low_line]
      local assign_note_value = assign_notecol and assign_notecol.note_value or nil
      self:set_high_low_column(marked_col_idx,assign_note_value,assign_note_value)
      assigned = true
      break
    else
      local has_room,in_range = self.runner:has_room(line_idx,marked_col_idx,v.voice_run.number_of_lines)
      local in_range_count = in_range and in_range[marked_col_idx] and #table.keys(in_range[marked_col_idx]) or 0
      --print("*** assign_to_marked - has_room, in_range_count",has_room,in_range_count)
      --print("*** assign_to_marked - in_range",rprint(in_range))

      -- only when the column has low/high note-value 
      -- can the target_notecol be resolved ...
      local target_notecol = nil
      if marked_col.low_note then
        target_notecol,target_run_idx = self.runner:resolve_notecol(marked_col_idx,line_idx)
        --print("target_notecol,target_run_idx",target_notecol,target_run_idx)
      end

      -- the value to update high_low_columns with...
      local assign_notecol = v.voice_run[line_idx]
      --print("*** assign_notecol...",assign_notecol) --rprint(assign_notecol))
      local assign_note_value = assign_notecol and assign_notecol.note_value or nil
      local set_high_low = function()
        self:set_high_low_column(marked_col_idx,assign_note_value,assign_note_value)
      end

      if not has_room then 

        if target_notecol 
          and (target_notecol.note_value >= assign_note_value)
        then
          --print("*** assign_to_marked - replace?")

          -- if source and target refer to same position
          local same_pos = (v.col_idx == marked_col_idx)
            and (v.run_idx == target_run_idx)

          if same_pos then
            --print(">>> pretend that assignment has taken place")
            set_high_low()
            assigned = true
            break
          else

            -- replace: if the column already contain a (single) entry,
            -- and the range occupied by that entry is equal to/smaller than ours
            -- (note: the replaced entry is not lost, will be output later on...)
            --print("in_range...",#in_range[marked_col_idx],rprint(in_range))
            local replaceable = true

            if (in_range_count > 1) then
              replaceable = false
              --print(">>> not replaceable, more than one entry in range...")
              --rprint(in_range[marked_col_idx])
            else
              for k2,v2 in pairs(in_range[marked_col_idx]) do
                if (v2.number_of_lines > v.voice_run.number_of_lines) then
                  replaceable = false
                  --print(">>> not replaceable, entry cover a greater range than ours...")
                  break
                end
              end
            end
            --print("replaceable",replaceable)
            if replaceable then
              --print("assign_to_marked - replace - clear:",v.col_idx,v.run_idx,"set:",marked_col_idx,target_run_idx)
              run_col[target_run_idx] = v.voice_run
              run_col[target_run_idx].__replaced = true -- avoid clearing when replaced entry is processed
              self:clear_in_column(v.col_idx,v.run_idx,line_idx)
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
          --print("self.high_low_columns[marked_col_idx]",marked_col_idx,rprint(self.high_low_columns[marked_col_idx]))
          --print("assign_note_value",assign_note_value)
          local range = self.high_low_columns[marked_col_idx]
          if assign_note_value
            and not table.is_empty(self.high_low_columns[marked_col_idx])
            and (range.low_note and range.high_note)
            and ((assign_note_value >= range.low_note) and (assign_note_value <= range.high_note))
            and not ((assign_note_value == range.low_note) and (assign_note_value == range.high_note))
          then

            -- TODO check if shifting makes sense - 
            -- perhaps there still is not room afterwards? 
            -- (invoke in_range() with include_before set to false)


            -- look for previous note in column which are higher,
            -- and insert them in a new column
            local higher_runs = xVoiceRunner.get_higher_notes_in_column(run_col,assign_note_value)
            --print("*** higher_runs",rprint(higher_runs))
            --print("*** higher_runs - run_col",rprint(run_col))
            if not table.is_empty(higher_runs) then
              local insert_col_idx = marked_col_idx+1
              local higher_run_idx = higher_runs[1].run_idx
              local higher_run = run_col[higher_run_idx]
              local higher_line_idx = higher_runs[1].line_idx
              --print(">>> shift higher run into new column - clear: ",marked_col_idx,higher_run_idx)
              --print(">>> shift higher run into new column - insert: ",insert_col_idx,1)
              --print(">>> shift higher run into new column - higher_run: ",higher_run)
              self:clear_in_column(marked_col_idx,higher_run_idx,higher_line_idx)
              self:insert_column(insert_col_idx,higher_run,higher_line_idx)
              for k = 2,#higher_runs do
                higher_run_idx = higher_runs[k].run_idx
                local insert_note_val = xVoiceRunner.get_initial_note(run_col[higher_run_idx])
                --print(">>> shift higher run into new column - insert_note_val: ",insert_note_val)
                --print(">>> shift higher run into new column - clear: ",marked_col_idx,higher_run_idx)
                --print(">>> shift higher run into new column - set: ",insert_col_idx,k)
                table.insert(voice_runs[insert_col_idx],k,run_col[higher_run_idx])
                self:clear_in_column(marked_col_idx,higher_run_idx,higher_runs[k].line_idx)
                self:set_high_low_column(insert_col_idx,insert_note_val,insert_note_val)
              end
            end

            -- now bring our run into this column
            --print(">>> bring our run into this column - clear:",v.col_idx,v.run_idx)
            --print(">>> bring our run into this column - set:",marked_col_idx,#run_col)
            self:clear_in_column(v.col_idx,v.run_idx,line_idx)
            table.insert(voice_runs[marked_col_idx],#run_col,v.voice_run)

            --print("*** high_low_columns...",rprint(self.high_low_columns))

            set_high_low()
            assigned = true
            break

          end

        end
      elseif has_room then
        if not target_notecol 
          or (target_notecol.note_value <= assign_note_value) 
        then
          -- assign when target value is empty, equal to, or lower than
          target_run_idx = target_run_idx or 1 -- when empty
          --print("assign_to_marked - assign - clear:",v.col_idx,v.run_idx,"set:",marked_col_idx,target_run_idx)
          table.insert(voice_runs[marked_col_idx],target_run_idx,v.voice_run)
          self:clear_in_column(v.col_idx,v.run_idx,line_idx)
          set_high_low()
          assigned = true
          break
        else
          --print(">>> skip marked column, target is higher...")
        end
      end

    end


  end

  if not assigned then
    -- insert after column with highest note-value
    --print("self.marked_columns",rprint(self.marked_columns))  
    for k2,v2 in ripairs(self.marked_columns) do
      if v2.high_note then
        --print("*** insert after column with highest note-value",xNoteColumn.note_value_to_string(v2.high_note))
        self:clear_in_column(v.col_idx,v.run_idx,line_idx)
        self:insert_column(v2.column_index+1,v.voice_run,line_idx)
        return
      end
    end
    -- insert as first column
    self:clear_in_column(v.col_idx,v.run_idx,line_idx)
    self:insert_column(1,v.voice_run,line_idx)
  end

end

-------------------------------------------------------------------------------
-- Static Methods
-------------------------------------------------------------------------------
-- collect runs that begin on a specific line 
-- @param line_idx (int)
-- @return table {
--    voice_run = table,
--    col_idx = int,
--    run_idx = int,
--    line_idx = int,
--  }

function xVoiceSorter.get_runs_on_line(voice_runs,line_idx)
  TRACE("xVoiceSorter.get_runs_on_line(voice_runs,line_idx)",voice_runs,line_idx)

  local line_runs = {}
  for col_idx,v in pairs(voice_runs) do
    for run_idx,v2 in pairs(v) do
      local low,high = xLib.get_table_bounds(v2)
      if (low == line_idx) then
        table.insert(line_runs,{
          voice_run = v2,
          col_idx = col_idx,
          run_idx = run_idx,
          line_idx = low,
        })
      end
    end
  end

  return line_runs

end


-------------------------------------------------------------------------------
-- Meta-methods
-------------------------------------------------------------------------------

function xVoiceSorter:__tostring()

  return type(self)
    ..", sort_mode="..tostring(self.sort_mode)

end
