--[[============================================================================
xVoiceSorter
============================================================================]]--

--[[--

Advanced sorting of pattern-data (including selections) 
.
#

See also: xVoiceRunner 


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

  --- table, sorted entries from one line of voice-runs 
  -- (see xVoiceRunner.get_runs_on_line()...)
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
    return 
  end
  print("*** sort - voice_runs PRE",rprint(voice_runs))

  self.runner.high_low_columns = {}

  for line_idx = self.patt_sel.start_line,self.patt_sel.end_line do
    local line_runs = xVoiceRunner.get_runs_on_line(voice_runs,line_idx)
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

  --print("post-sort",rprint(voice_runs))

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

  for k,voice in ipairs(self.sorted) do

    local sorted_note = voice.voice_run[line_idx].note_value
    prnt("*** processing sorted note...",k,voice.voice_run[line_idx].note_string,sorted_note,"==============================")
    prnt("*** high_low_columns...",rprint(self.runner.high_low_columns))

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
          print("*** look at cached values")
          low_note,high_note = high_low_col.low_note,high_low_col.high_note
        else 
          print("*** look through prior lines in this column")
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
      --prnt(">>> reached end - marked columns",rprint(self.marked_columns))
      self:assign_to_marked(voice,line_idx)
    end

  end

end


-------------------------------------------------------------------------------
-- traverse through the table of marked columns and find the
-- first one which has room for our voice-run - or insert new column
-- @param voice (table), one of our line-runs
-- @param line_idx (int)

function xVoiceSorter:assign_to_marked(voice,line_idx) 
  TRACE("xVoiceSorter:assign_to_marked(voice,line_idx)",voice,line_idx)

  print("*** assign_to_marked - self.marked_columns",rprint(self.marked_columns))  

  local voice_runs = self.runner.voice_runs
  local assigned = false

  local low_line,high_line = xLib.get_table_bounds(voice.voice_run)
  print("*** assign_to_marked - low_line,high_line",low_line,high_line)
  local assign_notecol = voice.voice_run[low_line]
  local assign_note_value = assign_notecol and assign_notecol.note_value or nil
  print("*** assign_to_marked - assign_note_value",assign_note_value)

  for k,marked_col in ipairs(self.marked_columns) do

    local marked_col_idx = marked_col.column_index
    local marked_run_idx = nil 
    
    -- pick the last marked column with a suitable value
    -- testcase: Simple V + Simple III + Complex II
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
      print("*** assign_to_marked - marked_col.high_note",marked_col.high_note)
      print("*** assign_to_marked - self.marked_columns[k+1]",self.marked_columns[k+1])
      print("*** assign_to_marked - skip_column",skip_column)
      --error("...")
    end

    if not skip_column then
      -- check if the source and target column is the same
      print("*** assign_to_marked - voice.col_idx,marked_col_idx",voice.col_idx,marked_col_idx)
      local is_same_column = (voice.col_idx == marked_col_idx)
      if is_same_column then
        print(">>> same column - pretend that assignment has taken place")
        self.runner:set_high_low_column(marked_col_idx,assign_note_value,assign_note_value)
        assigned = true
        break
      else
        local has_room,in_range = self.runner:has_room(line_idx,marked_col_idx,voice.voice_run.number_of_lines)
        print("*** assign_to_marked - has_room,",has_room)
        --print("*** assign_to_marked - in_range",rprint(in_range))
        -- low/high note-values means we can resolve marked_notecol ...
        local marked_notecol = nil
        if marked_col.low_note then
          marked_notecol,marked_run_idx = self.runner:resolve_notecol(marked_col_idx,line_idx)
          print("marked_notecol,marked_run_idx",marked_notecol,marked_run_idx)
        end
        local assign_notecol = voice.voice_run[line_idx]
        local assign_note_value = assign_notecol and assign_notecol.note_value or nil
        local set_high_low = function()
          self.runner:set_high_low_column(marked_col_idx,assign_note_value,assign_note_value)
        end
        print(">>> assign_note_value",assign_note_value)
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
            print(">>> assign_to_marked - no room - target note >= source note")
            -- if source and target refer to same position
            local same_pos = (voice.col_idx == marked_col_idx)
              and (voice.run_idx == marked_run_idx)
            if same_pos then
              print(">>> same_pos - pretend that assignment has taken place")
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
            print(">>> cant't replace - no room + no target notecol or lower note-value")
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
            print(">>> assign_to_marked - assign - clear:",voice.col_idx,voice.run_idx,"set:",marked_col_idx,marked_run_idx,voice.voice_run)
            table.insert(voice_runs[marked_col_idx],marked_run_idx,voice.voice_run)
            self.runner:clear_in_column(voice.col_idx,voice.run_idx,line_idx)
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

  end

  if not assigned then
    -- insert in rightmost marked column with a defined note-value
    --print("*** not assigned - self.marked_columns",rprint(self.marked_columns))  
    for k,v in ripairs(self.marked_columns) do
      local target_col_idx = v.column_index+1
      local is_same_column = (voice.col_idx == target_col_idx)
      if is_same_column then
        print(">>> not assigned - is_same_column (skip)")
        local insert_note_val = voice.voice_run[line_idx].note_value
        self.runner:set_high_low_column(target_col_idx,insert_note_val,insert_note_val)
      else
        print(">>> not assigned - insert as rightmost marked")
        self:insert_or_assign(voice,target_col_idx,line_idx)
      end
      return
    end
    -- everything else failed - insert as first column
    print(">>> not assigned - insert as first")
    self:insert_or_assign(voice,1,line_idx)
  end

end

-------------------------------------------------------------------------------

function xVoiceSorter:insert_or_assign(voice,col_idx,line_idx)
  TRACE("xVoiceSorter:insert_or_assign(voice,col_idx,line_idx)",voice,col_idx,line_idx)

  local voice_runs = self.runner.voice_runs

  print(">>> insert_or_assign - clear:",voice.col_idx,voice.run_idx)
  if self.runner:clear_in_column(voice.col_idx,voice.run_idx,line_idx) then
    -- by clearing we also removed the column
    print("*** insert_or_assign - voice.col_idx,col_idx",voice.col_idx,col_idx)
    if (voice.col_idx < col_idx) then
      col_idx = col_idx -1
      print(">>> insert_or_assign - adjusted col_idx",col_idx)
    end
  end
  if voice_runs[col_idx] then
    --[[
    local target_run_idx = 1+xVoiceRunner.get_most_recent_run_index(voice_runs[col_idx],line_idx)
    self.runner:assign_if_room(voice,col_idx,voice.run_idx,line_idx,target_run_idx)
    ]]
    local has_room,in_range = self.runner:has_room(line_idx,col_idx,voice.voice_run.number_of_lines)
    print("*** insert_or_assign - has_room:",has_room)
    if has_room then -- target_col has room, find the run index
      --print("*** insert_or_assign - in_range...",rprint(in_range))
      local target_run_idx = 1+xVoiceRunner.get_most_recent_run_index(voice_runs[col_idx],line_idx)
      print(">>> insert_or_assign - set:",col_idx,target_run_idx,voice.voice_run)
      table.insert(voice_runs[col_idx],target_run_idx,voice.voice_run)
      self.runner:set_high_low_column(col_idx,nil,nil,nil,line_idx)
      return
    end

  end
  -- if no room, insert new column
  print(">>> insert_or_assign - insert:",col_idx,voice.voice_run)
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
  print("xVoiceSorter:mark_column(col_idx,low_note,high_note)",col_idx,low_note,high_note)

  -- if already marked
  local marked_col = self:get_marked_column(col_idx)
  if marked_col then
    marked_col.low_note = low_note
    marked_col.high_note = high_note
    return
  end
  print("self.marked_columns PRE",rprint(self.marked_columns))

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
        print(">>> LOW_TO_HIGH: clear markers with a lower 'high' note-value")
        clear = true
      elseif low_note
        and (self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW)
        and v.low_note and (v.low_note > high_note) 
      then
        print(">>> HIGH_TO_LOW: clear markers with a higher 'low' note-value")
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
  print("self.marked_columns POST",rprint(self.marked_columns))

end


-------------------------------------------------------------------------------
-- Meta-methods
-------------------------------------------------------------------------------

function xVoiceSorter:__tostring()

  return type(self)
    ..", sort_mode="..tostring(self.sort_mode)

end
