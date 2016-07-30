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

local prnt = function(...)
  print(...)
end

class 'xVoiceSorter'

xVoiceSorter.SORT_MODES_FULL = {
  "Auto : low-to-high",
  "Auto : high-to-low",
  --"Auto : unique columns",
  --"Custom",
}
xVoiceSorter.SORT_MODES = {
  "Low > High",
  "High > Low",
  --"Unique Cols",
  --"Custom",
}

xVoiceSorter.SORT_MODE = {
  LOW_TO_HIGH = 1,
  HIGH_TO_LOW = 2,
  --UNIQUE = 3,
  --CUSTOM = 4,
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

  -- observables

  self.runner.voice_runs_remove_column_observable:add_notifier(function()
    print(">>> self.runner.voice_runs_remove_column_observable fired...")

    local col_idx = self.runner.removed_column_index
    print("removed_column_index",col_idx)

    for k,v in ripairs(self.sorted) do
      if (v.col_idx > col_idx) then v.col_idx = v.col_idx-1 end
    end
    for k,v in ripairs(self.marked_columns) do
      if (v.column_index > col_idx) then v.column_index = v.column_index-1 end
    end
    for k,v in ripairs(self.high_low_columns) do
      if (v.column_index == col_idx) then table.remove(self.high_low_columns,k) end
      if (v.column_index > col_idx) then v.column_index = v.column_index-1 end
    end

  end)

  self.runner.voice_runs_insert_column_observable:add_notifier(function()
    print(">>> self.runner.voice_runs_insert_column_observable fired...")

    local voice_runs = self.runner.voice_runs
    local col_idx = self.runner.inserted_column_index
    print("inserted_column_index",col_idx)
    
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
    

  end)

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
  print("*** sort - voice_runs PRE",rprint(voice_runs))

  self.high_low_columns = {}

  --print("*** sort - self.sort_mode",self.sort_mode)

  for line_idx = self.patt_sel.start_line,self.patt_sel.end_line do
    local line_runs = xVoiceSorter.get_runs_on_line(voice_runs,line_idx)
    if (self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH) 
      or (self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW) 
    then
      self:sort_by_note(line_runs,line_idx,self.patt_sel)
    --[[
    elseif (self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW) then
      self:sort_high_to_low(line_runs,line_idx,self.patt_sel)
    ]]
    elseif (self.sort_mode == xVoiceSorter.SORT_MODE.UNIQUE) then
      -- TODO if more than twelve, ask which ones to keep
      -- create a remap table and pass on to SORT_MODE.CUSTOM
    elseif (self.sort_mode == xVoiceSorter.SORT_MODE.CUSTOM) then
      -- TODO  
    end
  end

  print("post-sort",rprint(voice_runs))

  self.runner:write_to_pattern(ptrack,trk_idx,self.patt_sel)
  self.runner:purge_voices()

end

-------------------------------------------------------------------------------
-- sorting by note-value, one line at a time
-- @param line_runs (table), see get_runs_on_line()
-- @param line_idx (int) the line index

function xVoiceSorter:sort_by_note(line_runs,line_idx)
  TRACE("xVoiceSorter:sort_by_note(line_runs,line_idx)",line_runs,line_idx)

  local voice_runs = self.runner.voice_runs

  -- sort line by note value
  self.sorted = table.rcopy(line_runs)
  table.sort(self.sorted,function(e1,e2)
    if (self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH) then
      return e1.voice_run[line_idx].note_value < e2.voice_run[line_idx].note_value
    elseif (self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW) then
      return e1.voice_run[line_idx].note_value > e2.voice_run[line_idx].note_value
    end
  end)
  --prnt("*** sort_high_to_low - sorted",rprint(self.sorted))

  local low_col,high_col = self.patt_sel.start_column,self.patt_sel.end_column
  prnt("low_col,high_col",low_col,high_col)

  for k,v in ipairs(self.sorted) do

    local sorted_note = v.voice_run[line_idx].note_value
    prnt("*** processing sorted note...",k,v.voice_run[line_idx].note_string,sorted_note,"==============================")
    prnt("*** high_low_columns...",rprint(self.high_low_columns))


    self.marked_columns = {}   

    local assigned = false

    for col_idx = low_col,high_col do

      local run_col = voice_runs[col_idx]
      if not run_col then
        LOG("*** sort_high_to_low - skip column (no voice-run)",col_idx)
      else
        -- establish highest/lowest note-value prior to this line
        local low_note,high_note = nil,nil
        local high_low_col = self:get_high_low_column(col_idx) 
        if high_low_col then -- look at cached values
          low_note,high_note = high_low_col.low_note,high_low_col.high_note
        else -- look through prior lines in this column
          local line_end = (line_idx == 1) and line_idx or line_idx-1
          high_note,low_note = xVoiceRunner.get_high_low_note_values(run_col,self.patt_sel.start_line,line_end)
        end

        if high_note then
          prnt("*** col_idx,low_note,high_note",col_idx,xNoteColumn.note_value_to_string(low_note),xNoteColumn.note_value_to_string(high_note))
        else
          prnt("*** col_idx,low_note,high_note",col_idx,low_note,high_note)
        end
  
        local mark_column = function()
          self:mark_column(col_idx,low_note,high_note)
        end

        if not high_note then
          prnt(">>> no note - remember column")
          mark_column()
        else

          local assign_at_once = false
          if (self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW) then
            assign_at_once = (high_note and low_note) and (high_note < sorted_note) and (low_note < sorted_note) 
          elseif (self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH) then
            assign_at_once = (high_note and low_note) and (high_note > sorted_note) and (low_note > sorted_note) 
          end
          
          if assign_at_once then
            self:assign_to_marked(v,line_idx)
            assigned = true
            break
          else
            mark_column()
          end

        end 


      end --/run_col

    end

    if not assigned then
      prnt(">>> reached end - marked columns",rprint(self.marked_columns))
      self:assign_to_marked(v,line_idx)
    end

  end

end


-------------------------------------------------------------------------------
-- traverse through the table of marked columns and find the
-- first one which has room for our voice-run - or insert new column
-- @param v (table), one of our line-runs
-- @param line_idx (int)

function xVoiceSorter:assign_to_marked(v,line_idx) 
  TRACE("xVoiceSorter:assign_to_marked(v,line_idx)",v,line_idx)

  print("*** assign_to_marked - self.marked_columns",rprint(self.marked_columns))  

  local voice_runs = self.runner.voice_runs
  local assigned = false

  for _,marked_col in ipairs(self.marked_columns) do

    local marked_col_idx = marked_col.column_index
    local target_run_idx = nil 
    local run_col = voice_runs[marked_col_idx]
    
    -- first, check if the source and target column is the same
    print("*** assign_to_marked - v.col_idx,marked_col_idx",v.col_idx,marked_col_idx)
    local is_same_column = (v.col_idx == marked_col_idx)
    if is_same_column then
      print(">>> same column - pretend that assignment has taken place")

      local low_line,high_line = xLib.get_table_bounds(v.voice_run)
      local assign_notecol = v.voice_run[low_line]
      local assign_note_value = assign_notecol and assign_notecol.note_value or nil
      self:set_high_low_column(marked_col_idx,assign_note_value,assign_note_value)
      assigned = true
      break
    else
      local has_room,in_range = self.runner:has_room(line_idx,marked_col_idx,v.voice_run.number_of_lines)
      print("*** assign_to_marked - has_room,",has_room)
      --print("*** assign_to_marked - in_range",rprint(in_range))

      -- only when the column has low/high note-value 
      -- can the target_notecol be resolved ...
      local target_notecol = nil
      if marked_col.low_note then
        target_notecol,target_run_idx = self.runner:resolve_notecol(marked_col_idx,line_idx)
        print("target_notecol,target_run_idx",target_notecol,target_run_idx)
      end

      -- the value to update high_low_columns with...
      local assign_notecol = v.voice_run[line_idx]
      local assign_note_value = assign_notecol and assign_notecol.note_value or nil
      local set_high_low = function()
        self:set_high_low_column(marked_col_idx,assign_note_value,assign_note_value)
      end
      print(">>> assign_note_value",assign_note_value)

      if not has_room then 

        if target_notecol 
          and (target_notecol.note_value >= assign_note_value)
          and not (target_notecol.note_value >= renoise.PatternLine.NOTE_OFF)
        then
          print(">>> assign_to_marked - no room - target note > source note")

          -- if source and target refer to same position
          local same_pos = (v.col_idx == marked_col_idx)
            and (v.run_idx == target_run_idx)

          if same_pos then
            print(">>> same_pos - pretend that assignment has taken place")
            set_high_low()
            assigned = true
            break
          else

            -- replace: 
            -- + target column contains a run which 
            --    begin on this line
            --    has a different note value 
            -- + or: range occupied by that entry is equal to/smaller than ours
            -- (note: the replaced entry is not lost, will be output later on...)
            --print("in_range...",#in_range[marked_col_idx],rprint(in_range))
            local replaceable = true
 
            
            if target_run_idx then
              
              local target_run = run_col[target_run_idx]
              local start_line,end_line = xLib.get_table_bounds(target_run)
              if (start_line ~= line_idx) then
                replaceable = false
                print(">>> not replaceable, no run on this line")
              end

              print(">>> target_notecol.note_value",target_notecol.note_value)
              if (target_notecol.note_value == assign_note_value) then
                replaceable = false
                print(">>> not replaceable, source and target note is the same")
              end

            else
              for k2,v2 in pairs(in_range[marked_col_idx]) do
                if (v2.number_of_lines > v.voice_run.number_of_lines) then
                  replaceable = false
                  print(">>> not replaceable, entry cover a greater range than ours...")
                  break
                end
              end
            end
            if replaceable then
              print(">>> assign_to_marked - replaceable - clear:",v.col_idx,v.run_idx,"set:",marked_col_idx,target_run_idx)
              run_col[target_run_idx] = v.voice_run
              run_col[target_run_idx].__replaced = true -- avoid clearing when replaced entry is processed
              self:clear_in_column(v.col_idx,v.run_idx,line_idx)
              set_high_low()
              assigned = true
              break
            end

          end --/same pos

        else 
          print(">>> cant't replace - no room + no target notecol or lower note-value")

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

            print(">>> shift earlier runs")

            -- TODO check if shifting makes sense - 
            -- perhaps there still is not room afterwards? 
            -- (invoke in_range() with include_before set to false)

            -- look for previous note in column which are equal or higher, 
            -- and insert them in a new column
            -- difference between LOW/HIGH? Check with 'Complex II' 
            local higher_runs = xVoiceRunner.get_higher_notes_in_column(run_col,assign_note_value-1)
            --local higher_runs = xVoiceRunner.get_lower_notes_in_column(run_col,assign_note_value)
            print("*** higher_runs",rprint(higher_runs))
            print("*** higher_runs - run_col",rprint(run_col))
            local insert_col_idx = nil
            local highest_run_idx = 0
            if not table.is_empty(higher_runs) then
              if (self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH) then
                insert_col_idx = marked_col_idx+1
              elseif (self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW) then
                insert_col_idx = marked_col_idx --1
              end
              local higher_run_idx = higher_runs[1].run_idx
              highest_run_idx = math.max(highest_run_idx,higher_run_idx)
              local higher_run = run_col[higher_run_idx]
              local higher_line_idx = higher_runs[1].line_idx
              print(">>> shift higher run into new column - clear: ",marked_col_idx,higher_run_idx)
              print(">>> shift higher run into new column - insert: ",insert_col_idx)
              print(">>> shift higher run into new column - higher_run: ",higher_run)
              self:clear_in_column(marked_col_idx,higher_run_idx,line_idx)
              self.runner:insert_voice_column(insert_col_idx,higher_run,higher_line_idx)
              -- get high/low note of newly created column
              --local high_note,low_note = xVoiceRunner.get_high_low_note_values(run_col)
              --print(">>> high_note,low_note",high_note,low_note)
              --self:set_high_low_column(insert_col_idx,high_note,low_note)

              for k = 2,#higher_runs do
                higher_run_idx = higher_runs[k].run_idx
                higher_run = run_col[higher_run_idx]
                highest_run_idx = math.max(highest_run_idx,higher_run_idx)
                local insert_note_val = xVoiceRunner.get_initial_note(higher_run)
                print(">>> shift higher run into new column - insert_note_val: ",insert_note_val)
                print(">>> shift higher run into new column - clear: ",marked_col_idx,higher_run_idx)
                print(">>> shift higher run into new column - set: ",insert_col_idx,k)
                table.insert(voice_runs[insert_col_idx],k,higher_run)
                self:clear_in_column(marked_col_idx,higher_run_idx,higher_runs[k].line_idx)
                self:set_high_low_column(insert_col_idx,insert_note_val,insert_note_val)
              end
            end

            -- now bring our run into target column
            if insert_col_idx then
              --  run index might have changed due to shifting but we know the column + line
              print("*** run index might have changed, check column",v.col_idx)
              print("*** voice_columns...",rprint(voice_runs[v.col_idx]))
              local source_notecol,source_run_idx = self.runner:resolve_notecol(v.col_idx,line_idx)
              print("*** source_notecol,source_run_idx",source_notecol,source_run_idx)
              -- get high/low note of newly created column
              local high_note,low_note = xVoiceRunner.get_high_low_note_values(voice_runs[insert_col_idx])
              print("*** high_note,low_note",high_note,low_note)
              if (high_note == assign_note_value)
                and (low_note == assign_note_value)
              then
                print(">>> source and target are strictly equal: bring our run into the inserted column")
                print(">>> highest_run_idx",highest_run_idx)

                print(">>> clear:",v.col_idx,source_run_idx)
                print(">>> set:",insert_col_idx,highest_run_idx+1)

                self:clear_in_column(v.col_idx,source_run_idx,line_idx)
                table.insert(voice_runs[insert_col_idx],highest_run_idx+1,v.voice_run)

                --rprint(voice_runs)
                --error("...")

              else
                print(">>> shifted columns are higher, bring our run into marked column")
                print(">>> bring our run into this column - clear:",v.col_idx,source_run_idx)
                print(">>> bring our run into this column - set:",marked_col_idx,#run_col)
                self:clear_in_column(v.col_idx,source_run_idx,line_idx)
                table.insert(voice_runs[marked_col_idx],#run_col,v.voice_run)

                --print("*** high_low_columns...",rprint(self.high_low_columns))
                --rprint(voice_runs)
                --error("...")


              end

              --self:set_high_low_column(insert_col_idx,insert_note_val,insert_note_val)

              set_high_low()
              assigned = true
              break

            end

          end

        end
      elseif has_room then
        if not target_notecol 
          or (target_notecol.note_value <= assign_note_value)  -- LOW/HIGH?
        then
          -- insert run in target column when target note is empty, equal to, or lower than
          target_run_idx = target_run_idx and target_run_idx+1 or 1 -- 1 when empty
          print(">>> assign_to_marked - assign - clear:",v.col_idx,v.run_idx,"set:",marked_col_idx,target_run_idx)
          table.insert(voice_runs[marked_col_idx],target_run_idx,v.voice_run)
          self:clear_in_column(v.col_idx,v.run_idx,line_idx)
          set_high_low()
          assigned = true
          --rprint(voice_runs)
          --error("...")
          break
        else
          print(">>> skip marked column, target is higher...")
        end
      end

    end


  end

  local insert_or_assign = function(col_idx)
    print("insert_or_assign(col_idx)",col_idx)

    print(">>> insert_or_assign - clear:",v.col_idx,v.run_idx)
    if self:clear_in_column(v.col_idx,v.run_idx,line_idx) then
      -- by clearing we also removed the column
      print("*** insert_or_assign - v.col_idx,col_idx",v.col_idx,col_idx)
      if (v.col_idx < col_idx) then
        col_idx = col_idx -1
        print(">>> insert_or_assign - adjusted col_idx",col_idx)
      end
    end
    if voice_runs[col_idx] then
      local has_room,in_range = self.runner:has_room(line_idx,col_idx,v.voice_run.number_of_lines)
      print("*** insert_or_assign - has_room:",has_room)
      if has_room then -- target_col has room, find the run index
        print("*** insert_or_assign - in_range...",rprint(in_range))
        local target_run_idx = 1+xVoiceRunner.get_most_recent_run_index(voice_runs[col_idx],line_idx)
        print(">>> insert_or_assign - set:",col_idx,target_run_idx)
        table.insert(voice_runs[col_idx],target_run_idx,v.voice_run)
        return
      end
    end
    -- if no room, insert new column
    print(">>> insert_or_assign - insert:",col_idx,v.voice_run)
    self.runner:insert_voice_column(col_idx,v.voice_run,line_idx)

  end

  if not assigned then
    -- insert in rightmost marked column with a defined note-value
    print("*** not assigned - self.marked_columns",rprint(self.marked_columns))  
    for k2,v2 in ripairs(self.marked_columns) do
      local target_col_idx = v2.column_index+1
      local is_same_column = (v.col_idx == target_col_idx)
      if is_same_column then
        print(">>> not assigned - is_same_column (skip)")
        local insert_note_val = v.voice_run[line_idx].note_value
        self:set_high_low_column(target_col_idx,insert_note_val,insert_note_val)
      else
        print(">>> not assigned - insert as rightmost marked")
        insert_or_assign(target_col_idx)
      end
      return
    end
    -- everything else failed - insert as first column
    print(">>> not assigned - insert as first")
    insert_or_assign(1)

  end

end

-------------------------------------------------------------------------------

function xVoiceSorter:set_high_low_column(col_idx,high_note,low_note,force)
  print("xVoiceSorter:set_high_low_column(col_idx,high_note,low_note)",col_idx,high_note,low_note)

  local t = self:get_high_low_column(col_idx)
  if t then
    print("*** set_high_low_column - updating existing entry")
  
    if force then
      t.high_note = high_note
      t.low_note = low_note
    else
      -- if defined, expand range of existing value 
      -- else set to provided value
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
    print("*** set_high_low_column - inserting new entry")
    table.insert(self.high_low_columns,{
      column_index = col_idx,
      low_note = low_note,
      high_note = high_note,
    })
  end

  table.sort(self.high_low_columns,function(e1,e2)
    return e1.column_index < e2.column_index
  end)

  print("*** set_high_low_column...",rprint(self.high_low_columns))

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
-- clear a voice-run from a column + remove column if empty

function xVoiceSorter:clear_in_column(col_idx,run_idx,line_idx) 
  print("xVoiceSorter:clear_in_column(col_idx,run_idx,line_idx)",col_idx,run_idx,line_idx)

  local run_col = self.runner.voice_runs[col_idx]
  if not run_col[run_idx] then
    print("*** clear_in_column - voice-run not found")
    return
  end

  if not run_col[run_idx].__replaced then
    --print("run_col PRE...",rprint(run_col))
    --print("*** clear_in_column - run indices",rprint(table.keys(run_col)))
    run_col[run_idx] = nil
    if table.is_empty(run_col) then
      self.runner:remove_voice_column(col_idx)

      return true
    else
      -- update high_low_columns (look through prior lines)
      local start_line,end_line = xVoiceRunner.get_column_start_end_line(run_col)
      --print("*** clear_in_column - start_line,end_line,line_idx",start_line,end_line,line_idx)
      if start_line 
        and (start_line < line_idx)
      then
        local high_note,low_note = xVoiceRunner.get_high_low_note_values(run_col,start_line,line_idx)
        --print("*** clear_in_column - refresh low/high note",low_note,high_note)
        self:set_high_low_column(col_idx,high_note,low_note,true)
      elseif not start_line then
        --print("*** clear_in_column - start_line > line_idx",start_line,line_idx)
        self:set_high_low_column(col_idx,nil,nil,true)
      end
    end
  else
    print("*** clear_in_column - this voice-run was __replaced (protected from being cleared)")
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
