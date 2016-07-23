--[[============================================================================
xVoiceSorter
============================================================================]]--

--[[--

Advanced sorting of pattern-data (including selections) 
.
#

Relies heavily on xVoiceRunner, containing the actual data

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

  -- table, used for indicating an appropriate destination
  --  {
  --    column_index = int,
  --    low_note = int,
  --    high_note = int,
  --  }
  self.marked_columns = {}

  -- int, number of inserted columns while sorting
  self.inserted_columns = nil

  --- table
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

  local collect_mode = xVoiceRunner.COLLECT_MODE.SELECTION
  self.runner:collect_from_pattern(ptrack,collect_mode,trk_idx,seq_idx,patt_sel)
  --print("voice_runs...",rprint(self.runner.voice_runs))
  if (self.sort_mode == xVoiceSorter.SORT_MODE.LOW_TO_HIGH) then
    for line_idx = patt_sel.start_line,patt_sel.end_line do
      local line_runs = xVoiceSorter.get_runs_on_line(self.runner.voice_runs,line_idx)
      self:sort_low_to_high(line_runs,line_idx,patt_sel)
    end
  elseif (self.sort_mode == xVoiceSorter.SORT_MODE.HIGH_TO_LOW) then
    -- TODO  
  elseif (self.sort_mode == xVoiceSorter.SORT_MODE.UNIQUE) then
    -- TODO if more than twelve, ask which ones to keep
    -- create a remap table and pass on to SORT_MODE.CUSTOM
  elseif (self.sort_mode == xVoiceSorter.SORT_MODE.CUSTOM) then
    -- TODO  
  end

  --print("post-sort",rprint(voice_runs))

  self.runner:write_to_pattern(ptrack,trk_idx,patt_sel)
  self.runner:purge_voices()

end

-------------------------------------------------------------------------------
-- low to high sorting, one line at a time
-- @param line_runs (table), see get_runs_on_line()
-- @param line_idx (int) the line index
-- @param patt_sel (table)

function xVoiceSorter:sort_low_to_high(line_runs,line_idx,patt_sel)
  TRACE("xVoiceSorter:sort_low_to_high(line_runs,line_idx,patt_sel)",line_runs,line_idx,patt_sel)

  local voice_runs = self.runner.voice_runs
  self.inserted_columns = 0

  -- sort line by note value
  self.sorted = table.rcopy(line_runs)
  table.sort(self.sorted,function(e1,e2)
    return e1.voice_run[line_idx].note_value < e2.voice_run[line_idx].note_value
  end)
  print("*** sort_low_to_high - sorted",rprint(self.sorted))

  local line_start = patt_sel.start_line
  local low_col,high_col = patt_sel.start_column,patt_sel.end_column
  --print("low_col,high_col",low_col,high_col)

  for k,v in ipairs(self.sorted) do

    --print("self.voice_runs",rprint(self.voice_runs))
    print("*** processing sorted note...",k,v.voice_run[line_idx].note_string,v.voice_run[line_idx].note_value,"............................")

    self.marked_columns = {}    -- table, appropriate columns
    local same_column_idx = nil -- int, when we have found 'ourselves' 
    local assigned = false      -- bool, true when we could assign to a column

    for col_idx = low_col,high_col do

      local voice_run = voice_runs[col_idx]
      if not voice_run then
        LOG("*** sort_low_to_high - skip column (no voice-run)",col_idx)
      else

        -- look for the lowest and highest note-value 
        -- in lines *above* the current position 
        local line_end = (line_idx == 1) and line_idx or line_idx-1
        local low_note,high_note = xVoiceRunner.get_low_high_note_values(voice_run,line_start,line_end)

        -- a bit of debugging
        --[[
        if high_note then
          print("*** low_note,high_note",xNoteColumn.note_value_to_string(low_note),xNoteColumn.note_value_to_string(high_note))
        else
          print("*** low_note,high_note",low_note,high_note)
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
          print(">>> no note - remember column",col_idx)
          mark_column()
        else
          if (high_note == sorted_note) then
            -- TODO better implementation
            print(">>> equal to",col_idx,v.col_idx)
            same_column_idx = col_idx
            mark_column()

          elseif (high_note > sorted_note) then
            print(">>> higher than",col_idx)

            local has_marked_columns = (#self.marked_columns > 0)
            
            if (low_note <= sorted_note) then
              -- add non-overlapping notes to same column (compact)
              print(">>> higher than - target already contains equal or lower note")
              mark_column()
            elseif has_marked_columns then
              print(">>> higher than - already found a possible spot")     
              self:assign_to_marked_column(v,line_idx)
              assigned = true
              break
            else
              print(">>> higher than - insert? (no marked column and replace not possible)")
              self:insert_column(k,v)
              assigned = true
              break
            end

          elseif (high_note < sorted_note) then
            print(">>> lower than",col_idx)
            mark_column()
          end
        end

      end

    end

    if not assigned then
      if same_column_idx then
        --print(">>> reached end - same column, marked...",same_column_idx,rprint(self.marked_columns))
        local last_marked_column = self.marked_columns[#self.marked_columns].column_index
        if (last_marked_column - same_column_idx > 1) then
          print(">>> reached end - skipped one or more columns along the way")
          self:assign_to_marked_column(v,line_idx)
        else
          print(">>> reached end - same column was prior, do nothing")
        end
      else
        print(">>> reached end - marked columns",rprint(self.marked_columns))
        self:assign_to_marked_column(v,line_idx)
      end
    end

  end

end

-------------------------------------------------------------------------------
-- get marked column by column index 

function xVoiceSorter:get_marked_column(col_idx)

  for k,v in ipairs(self.marked_columns) do
    if (v.column_index == col_idx) then
      return k
    end
  end

  return nil

end

-------------------------------------------------------------------------------
-- mark a column as an appropriate destination 

function xVoiceSorter:mark_column(col_idx,low_note,high_note)
  TRACE("xVoiceSorter:mark_column(col_idx,low_note,high_note)",col_idx,low_note,high_note)

  -- if already marked
  local marker_idx = self:get_marked_column(col_idx)
  if marker_idx then
    --print("*** update existing marker")
    self.marked_columns[marker_idx].low_note = low_note
    self.marked_columns[marker_idx].high_note = high_note
    return
  end

  --print("self.marked_columns PRE",rprint(self.marked_columns))

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
  print("self.marked_columns POST",rprint(self.marked_columns))

end

-------------------------------------------------------------------------------
-- @param v (table), see get_runs_on_line()
-- @param col_idx (int), the target column

function xVoiceSorter:insert_column(col_idx,v) 
  print("xVoiceSorter:insert_column(col_idx,v)",col_idx,v)

  local voice_runs = self.runner.voice_runs

  --print("insert_column - clear:",v.col_idx,v.run_idx,"insert:",col_idx,v.run_idx)
  voice_runs[v.col_idx][v.run_idx] = nil
  table.insert(voice_runs,col_idx,{[v.run_idx] = v.voice_run})
  self.inserted_columns = self.inserted_columns+1

  -- adjust column indices on the fly
  for k,v in ipairs(self.sorted) do
    if (v.col_idx >= col_idx) then
      v.col_idx = v.col_idx+1
      --print("adjust sorted column indices...",v.col_idx)
    end
  end
  for k,v in ipairs(self.marked_columns) do
    if (v.column_index >= col_idx) then
      v.column_index = v.column_index+1
      --print("adjust marked_columns indices...",v.col_idx)
    end
  end

end

-------------------------------------------------------------------------------
-- traverse through the table of marked columns and find the
-- first one which has room for our voice-run. If none are able
-- to provide space, insert a new column before the first one
-- @param line_idx (int)

function xVoiceSorter:assign_to_marked_column(v,line_idx) 
  print("xVoiceSorter:assign_to_marked_column(v,line_idx)",v,line_idx)

  local voice_runs = self.runner.voice_runs
            
  local assigned = false

  for _,marked_col in ipairs(self.marked_columns) do
    local marked_col_idx = marked_col.column_index
    local target_run_idx = 1 -- when track is empty 
    local has_room,in_range = self.runner:has_room(line_idx,marked_col_idx,v.voice_run.number_of_lines)
    local in_range_count = in_range and in_range[marked_col_idx] and #table.keys(in_range[marked_col_idx]) or 0
    --print("*** assign_to_marked_column - marked_col_idx",marked_col_idx)
    --print("*** assign_to_marked_column - has_room, in_range_count",has_room,in_range_count)
    --print("*** assign_to_marked_column - in_range",rprint(in_range))

    -- only when the column has low/high note-value 
    -- can the target_notecol be resolved ...
    local target_notecol,assign_notecol = nil,nil
    if marked_col.low_note then
      target_notecol,target_run_idx = self.runner:resolve_notecol(marked_col_idx,line_idx)
      assign_notecol = v.voice_run[line_idx]
      --print("*** assign_notecol...",rprint(assign_notecol))
    end

    if not has_room then

      if target_notecol 
        and (target_notecol.note_value >= assign_notecol.note_value)
      then
        print("*** assign_to_marked_column - replace?")

        -- if source and target refer to same position
        local same_pos = (v.col_idx == marked_col_idx)
          and (v.run_idx == target_run_idx)

        if same_pos then
          print(">>> pretend that assignment has taken place")
          assigned = true
          break
        else

          -- replace: if the column already contain a (single) entry,
          -- and that entry is equal to, or smaller than our entry 
          -- (note: the replaced entry is not lost, will be output later on...)
          --print("in_range...",#in_range[marked_col_idx],rprint(in_range))
          local replaceable = true

          if (in_range_count > 1) then
            replaceable = false
            print(">>> not replaceable, more than one entry in range...")
            rprint(in_range[marked_col_idx])
          else
            for k2,v2 in pairs(in_range[marked_col_idx]) do
              if (v2.number_of_lines > v.voice_run.number_of_lines) then
                replaceable = false
                print(">>> not replaceable, entry cover a greater range than ours...")
                break
              end
            end
          end
          --print("replaceable",replaceable)
          if replaceable then
            print("assign_to_marked_column - replace - clear:",v.col_idx,v.run_idx,"set:",marked_col_idx,target_run_idx)
            voice_runs[marked_col_idx][target_run_idx] = v.voice_run
            voice_runs[marked_col_idx][target_run_idx].__replaced = true -- avoid clearing
            voice_runs[v.col_idx][v.run_idx] = nil
            assigned = true
            break
          end

        end --/same pos

      else
        print(">>> don't replace - target has a lower note-value")        
      end
    elseif has_room then
      print("*** assign_to_marked_column - assign?")  
      -- assign: when target value is empty, equal to, or lower than
      if not target_notecol 
        or (target_notecol.note_value <= assign_notecol.note_value) 
      then
        print("assign_to_marked_column - assign - clear:",v.col_idx,v.run_idx,"set:",marked_col_idx,target_run_idx)
        table.insert(voice_runs[marked_col_idx],target_run_idx,v.voice_run)
        if not voice_runs[v.col_idx][v.run_idx].__replaced then
          voice_runs[v.col_idx][v.run_idx] = nil
        else
          print("*** assign_to_marked_column - assign - skipped clear...")
        end
        assigned = true
        break
      else
        print(">>> skip marked column, target is higher...")
      end
    end

  end

  if not assigned then
    -- insert after the first marked column 
    local marked_col_idx = self.marked_columns[1].column_index+1
    self:insert_column(marked_col_idx,v)
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
