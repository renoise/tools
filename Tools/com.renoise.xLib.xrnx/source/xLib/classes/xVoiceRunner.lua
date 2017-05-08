--[[===============================================================================================
xVoiceRunner
===============================================================================================]]--

--[[--

This class converts pattern-tracks into 'voice-runs' - small note sequences
.
#

## About

xVoiceRunner provides a highly configurable method for extracting pattern data. 

See also: 
@{xVoiceSorter}

]]

class 'xVoiceRunner'

xVoiceRunner.COLLECT_MODE = {
  SELECTION = 1,
  CURSOR = 2,
}

xVoiceRunner.CONDITIONS = {
  CREATE_VOICE_RUN = 7,
  CREATE_ORPHAN_RUN = 8,
  CONTINUE_VOICE_RUN = 1,
  CONTINUE_GHOST_NOTE = 9,
  CONTINUE_GLIDE_NOTE = 10,
  CONTINUE_RUN_OFFED = 11,
  CONTINUE_ORPHAN_RUN = 12,
  SPLIT_AT_NOTE = 4,
  SPLIT_AT_NOTE_CHANGE = 5,
  SPLIT_AT_INSTR_CHANGE = 6,
  STOP_AT_NOTE_OFF = 2,
  STOP_AT_NOTE_CUT = 3,
}

xVoiceRunner.GHOST_NOTE = 256

---------------------------------------------------------------------------------------------------

function xVoiceRunner:__init(...)
  TRACE("xVoiceRunner:__init(...)",...)

	local args = cLib.unpack_args(...)

  --- bool, split a voice-run when note switches
  self.split_at_note = (type(args.split_at_note)~="boolean") 
    and true or args.split_at_note 

  --- bool, split a voice-run when note switches
  self.split_at_note_change = (type(args.split_at_note_change)~="boolean") 
    and true or args.split_at_note_change 

  --- bool, split a voice-run when instrument switches
  self.split_at_instrument_change = (type(args.split_at_instrument_change)~="boolean") 
    and true or args.split_at_instrument_change 

  --- bool, stop voice-run when encountering a NOTE-OFF
  self.link_ghost_notes = (type(args.link_ghost_notes)~="boolean") 
    and true or args.link_ghost_notes 

  --- bool, stop voice-run when encountering a NOTE-OFF
  self.link_ghost_notes = (type(args.link_ghost_notes)~="boolean") 
    and true or args.link_ghost_notes 

  --- bool, stop voice-run when encountering a NOTE-OFF
  self.stop_at_note_off = (type(args.stop_at_note_off)~="boolean") 
    and false or args.stop_at_note_off 

  --- bool, stop voice-run when encountering a NOTE-OFF
  self.stop_at_note_cut = (type(args.stop_at_note_cut)~="boolean") 
    and false or args.stop_at_note_cut 

  --- bool, remove orphaned runs as they are encountered
  self.remove_orphans = (type(args.remove_orphans)~="boolean") 
    and false or args.remove_orphans 

  self.create_noteoffs = (type(args.create_noteoffs)~="boolean") 
    and false or args.create_noteoffs 

  self.close_open_notes = (type(args.close_open_notes)~="boolean") 
    and false or args.close_open_notes 

  self.reveal_subcolumns = (type(args.reveal_subcolumns)~="boolean") 
    and false or args.reveal_subcolumns 

  --- bool, decide whether 'next/previous' jumps will wrap in pattern
  self.wrap_around_jump = (type(args.wrap_around_jump)~="boolean") 
    and true or args.wrap_around_jump 

  --- bool, compact runs when collecting (remove empty columns)
  self.compact_columns = true

  -- internal -------------------------

  --- xVoiceRunnerTemplate, decides which notes to collect (optional)
  self.template = nil

  --- bool, set to true when pattern data has changed
  -- (optimize step: skip collection when not needed)
  --self.collect_required = true

  -- table, represents the active voices as we progress through song
  --  [column_index] {
  --    instrument_index = int, -- '0' is orphaned data, 256 is ghost note
  --    note_value = int,
  --    offed = bool,
  --  } 
  self.voice_columns = {}

  --- table of xNoteColumns, active voice from trigger to (implied) release
  -- table = {
  --  [column_index] = {                  -- pairs
  --    [voice_run_index] = {             -- pairs
  --      [number_of_lines] = int or nil  -- always set, including trailing blank space
  --      [implied_noteoff] = bool or nil -- set when switching note/instr while having an active (non-offed) voice - see also split_on_note_xx options
  --      [open_ended] = bool or nil      -- set when voice extends beyond selection/pattern boundary
  --      [orphaned] = bool or nil        -- set on data with no prior voice (such as when we stop at note-off, note-cut...)
  --      [actual_noteoff_col] = xNoteColumn or nil -- set when note-off/cut is explicit 
  --      [single_line_trigger] = bool or nil -- set when Cx on same line as note (only possible when stop_at_note_cut is true)
  --      [__skip_template] = bool or nil -- true when the template tell us to ignore this note
  --      [line_idx] =                    -- xNoteColumn
  --      [line_idx] =                    -- xNoteColumn
  --      [line_idx] =                    -- etc...
  --     }
  --   }
  -- }
  self.voice_runs = {}
  
  --- table, keep track of unique note/instrument combinations 
  -- table{
  --    [note_value] = {
  --      [instrument_value] = true
  --    }
  --  ]
  self.unique_notes = {}

  --- int, remember the collected columns indices 
  --  (used for clearing leftovers on output)
  self.low_column = nil
  self.high_column = nil

end

---------------------------------------------------------------------------------------------------
-- reset variables to initial state before starting to process

function xVoiceRunner:reset()
  TRACE("xVoiceRunner:reset()")

  self.voice_columns = {}
  self.voice_runs = {}
  self.unique_notes = {}

end

---------------------------------------------------------------------------------------------------
-- prepare for next pattern by removing all terminated voices/voice-runs

function xVoiceRunner:purge_voices()
  TRACE("xVoiceRunner:purge_voices()")

  -- TODO

end

---------------------------------------------------------------------------------------------------
-- gather voice-runs according to the specified settings
-- @param ptrack_or_phrase (renoise.PatternTrack or renoise.InstrumentPhrase)
-- @param collect_mode (xVoiceRunner.COLLECT_MODE)
-- @param selection (table), xSelection: pattern-selection
-- @param trk_idx (int)
-- @param seq_idx (int)

function xVoiceRunner:collect(ptrack_or_phrase,collect_mode,selection,trk_idx,seq_idx)
  TRACE("xVoiceRunner:collect(ptrack_or_phrase,collect_mode,selection,trk_idx,seq_idx)",ptrack_or_phrase,collect_mode,selection,trk_idx,seq_idx)

  assert(type(ptrack_or_phrase)=="PatternTrack" or type(ptrack_or_phrase)=="InstrumentPhrase")
  assert(type(collect_mode)=="number")

  if ptrack_or_phrase.is_empty then
    --LOG("Skip empty pattern-track...")
    return
  end

  local collecting_from_pattern = (type(ptrack_or_phrase)=="PatternTrack")

  if (collect_mode == xVoiceRunner.COLLECT_MODE.CURSOR) then
    trk_idx = rns.selected_track_index
    seq_idx = rns.selected_sequence_index
    local col_idx = rns.selected_note_column_index
    selection = xSelection.get_column_in_track(seq_idx,trk_idx,col_idx)
  elseif (collect_mode == xVoiceRunner.COLLECT_MODE.SELECTION) then
    if collecting_from_pattern then
      assert(type(trk_idx)=="number")
      assert(type(seq_idx)=="number")
    end
    assert(type(selection)=="table")
  end

  local num_lines,visible_note_columns,vol_visible,pan_visible,dly_visible
  if collecting_from_pattern then
    local track = rns.tracks[trk_idx]
    local patt_idx = rns.sequencer:pattern(seq_idx)
    local patt = rns.patterns[patt_idx]
    num_lines = patt.number_of_lines
    visible_note_columns = track.visible_note_columns
    vol_visible = track.volume_column_visible
    pan_visible = track.panning_column_visible
    dly_visible = track.delay_column_visible
  else
    num_lines = ptrack_or_phrase.number_of_lines
    visible_note_columns = ptrack_or_phrase.visible_note_columns
    vol_visible = ptrack_or_phrase.volume_column_visible
    pan_visible = ptrack_or_phrase.panning_column_visible
    dly_visible = ptrack_or_phrase.delay_column_visible
  end

  local line_rng = ptrack_or_phrase:lines_in_range(selection.start_line,selection.end_line)
  for k,line in ipairs(line_rng) do

    local line_idx = k + selection.start_line - 1

    if not line.is_empty then
      for col_idx,notecol in ipairs(line.note_columns) do
        if not notecol.is_empty 
          and (col_idx > visible_note_columns) 
          or ((col_idx < selection.start_column) 
            or (col_idx > selection.end_column))
        then
          -- skip hidden column 
        else

          local begin_voice_run = false
          local stop_voice_run = false
          local implied_noteoff = false
          local orphaned = false
          local actual_noteoff_col = nil

          local run_condition,has_note_on,has_note_off,has_note_cut,has_instr_val,note_val,instr_idx,has_glide_cmd
            = self:detect_run_condition(notecol,col_idx,vol_visible,pan_visible,collecting_from_pattern)

          local assign_instr_and_note = function()
            TRACE("xVoiceRunner:collect() - assign_instr_and_note")
            instr_idx = has_instr_val and instr_idx or xVoiceRunner.GHOST_NOTE
            note_val = has_note_on and note_val or nil
          end

          local handle_note_off_cut = function()
            TRACE("xVoiceRunner:collect() - handle_note_off_cut")
            actual_noteoff_col = xNoteColumn(xNoteColumn.do_read(notecol))
            stop_voice_run = true
            instr_idx = self.voice_columns[col_idx].instrument_index
            self.voice_columns[col_idx] = nil
          end

          local handle_offed_run = function()
            TRACE("xVoiceRunner:collect() - handle_offed_run")
            self.voice_columns[col_idx].offed = true
            instr_idx = self.voice_columns[col_idx].instrument_index
          end

          local handle_create_voice_run = function()
            TRACE("xVoiceRunner:collect() - handle_create_voice_run")
            assign_instr_and_note()
            begin_voice_run = true
            self.voice_columns[col_idx] = {
              instrument_index = instr_idx,
              note_value = note_val,
            }
          end

          local handle_create_orphan_run = function()
            TRACE("xVoiceRunner:collect() - handle_create_orphan_run")
            begin_voice_run = true
            orphaned = true
            instr_idx = 0
            self.voice_columns[col_idx] = {
              instrument_index = instr_idx,
            }
          end

          local handle_split_at_note_or_change = function()
            TRACE("xVoiceRunner:collect() - handle_split_at_note_or_change")
            assign_instr_and_note()
            implied_noteoff = not self.voice_columns[col_idx].offed and true or false
            begin_voice_run = true
            self.voice_columns[col_idx] = {
              instrument_index = instr_idx, 
              note_value = note_val,
            }
          end

          local handle_instrument_change = function()
            TRACE("xVoiceRunner:collect() - handle_instrument_change")
            implied_noteoff = not self.voice_columns[col_idx].offed and true or false 
            begin_voice_run = true
            self.voice_columns[col_idx] = {
              instrument_index = instr_idx,
              note_value = note_val,
            }
          end

          local handle_continue_orphan_run = function()
            TRACE("xVoiceRunner:collect() - handle_continue_orphan_run")
            self.voice_columns[col_idx] = {
              instrument_index = instr_idx,
              note_value = note_val,
            }
          end

          local handle_continue_voice_run = function()
            TRACE("xVoiceRunner:collect() - handle_continue_voice_run")
            instr_idx = self.voice_columns[col_idx].instrument_index
          end

          local handle_continue_ghost_note = function()
            TRACE("xVoiceRunner:collect() - handle_continue_ghost_note")
            assign_instr_and_note()
          end

          local handle_continue_glide_note = function()
            TRACE("xVoiceRunner:collect() - handle_continue_glide_note")
            assign_instr_and_note()
          end

          local handlers = {
            [xVoiceRunner.CONDITIONS.CREATE_VOICE_RUN] = handle_create_voice_run,
            [xVoiceRunner.CONDITIONS.CREATE_ORPHAN_RUN] = handle_create_orphan_run,
            [xVoiceRunner.CONDITIONS.CONTINUE_VOICE_RUN] = handle_continue_voice_run,
            [xVoiceRunner.CONDITIONS.CONTINUE_GHOST_NOTE] = handle_continue_ghost_note,
            [xVoiceRunner.CONDITIONS.CONTINUE_GLIDE_NOTE] = handle_continue_glide_note,
            [xVoiceRunner.CONDITIONS.CONTINUE_RUN_OFFED] = handle_offed_run,
            [xVoiceRunner.CONDITIONS.CONTINUE_ORPHAN_RUN] = handle_continue_orphan_run,
            [xVoiceRunner.CONDITIONS.STOP_AT_NOTE_OFF] = handle_note_off_cut,
            [xVoiceRunner.CONDITIONS.STOP_AT_NOTE_CUT] = handle_note_off_cut,
            [xVoiceRunner.CONDITIONS.SPLIT_AT_NOTE] = handle_split_at_note_or_change,
            [xVoiceRunner.CONDITIONS.SPLIT_AT_NOTE_CHANGE] = handle_split_at_note_or_change,
            [xVoiceRunner.CONDITIONS.SPLIT_AT_INSTR_CHANGE] = handle_instrument_change,
          }

          if handlers[run_condition] then handlers[run_condition]() end

          local include_as_unique = true

          -- add entry to the voice_runs table
          if (type(instr_idx)=="number") then

            local voice_run,run_index = nil,nil
            if self.voice_runs and self.voice_runs[col_idx] then
              run_index = #self.voice_runs[col_idx]
            end
            if run_index then
              voice_run = self.voice_runs[col_idx][run_index]
            end

            if voice_run and implied_noteoff then
              voice_run.implied_noteoff = implied_noteoff
            end
            
            --print(">>> voice_run",voice_run)
            --print(">>> col_idx",col_idx)
            --print(">>> notecol",notecol)
            --print(">>> begin_voice_run",begin_voice_run)
            --print(">>> stop_voice_run",stop_voice_run)
            --print(">>> has_note_cut",has_note_cut)
            --print(">>> has_note_off",has_note_off)

            -- opportune moment to compute number of lines: before a new run
            if voice_run and begin_voice_run 
              and not voice_run.number_of_lines
            then
              local low,high = cLib.get_table_bounds(voice_run)
              voice_run.number_of_lines = k-low
            end

            cLib.expand_table(self.voice_runs,col_idx)
            run_index = #self.voice_runs[col_idx] + (begin_voice_run and 1 or 0)
            cLib.expand_table(self.voice_runs,col_idx,run_index)

            voice_run = self.voice_runs[col_idx][run_index]
            voice_run[line_idx] = xNoteColumn.do_read(notecol)

            if stop_voice_run then
              local low,high = cLib.get_table_bounds(voice_run)
              local num_lines = high-low
              voice_run.number_of_lines = num_lines

              -- shave off the last note-column when using 'actual_noteoff_col' 
              if actual_noteoff_col then
                voice_run[high] = nil
              end

            elseif begin_voice_run and has_note_cut and self.stop_at_note_cut then
              voice_run.number_of_lines = 1
              voice_run.single_line_trigger = true
            end

            if has_note_cut or has_note_off then
              if self.voice_columns[col_idx] then 
                if (self.stop_at_note_off and has_note_off)
                  or (self.stop_at_note_cut and has_note_cut)
                then
                  self.voice_columns[col_idx] = nil
                else
                  self.voice_columns[col_idx].offed = true
                end
              else 
                LOG("*** xVoiceRunner: tried to access non-existing voice column")
              end 
            end

            if actual_noteoff_col then
              voice_run.actual_noteoff_col = actual_noteoff_col
            end

            if orphaned then
              voice_run.orphaned = orphaned
            end

            -- if we've got a template, check whether to include this run 
            --[[
            if begin_voice_run and has_note_on and self.template then
              local entries,indices = self.template:get_entries({
                note_value = note_val,
                instrument_value = instr_idx-1 
              })
              if (#indices > 0) then
                for k,v in ipairs(entries) do
                  if not v.active then
                    voice_run.__skip_template = true
                    include_as_unique = false
                    break
                  end
                end
              end
            end
            ]]

          end

          -- register unique notes as they are encountered
          if include_as_unique then
            if note_val and instr_idx then
              cLib.expand_table(self.unique_notes,note_val,instr_idx-1)
              self.unique_notes[note_val][instr_idx-1] = true
            elseif note_val then
              cLib.expand_table(self.unique_notes,note_val)
            end
          end

        end
      end
    end

  end

  self.low_column,self.high_column = cLib.get_table_bounds(self.voice_runs)

  -- post-process

  for col_idx,run_col in pairs(self.voice_runs) do
    for run_idx,run in pairs(run_col) do
      if run.__skip_template then
        self.voice_runs[col_idx][run_idx] = nil
      else
        -- check for (and remove) orphaned data
        if self.remove_orphans and run.orphaned then
          self.voice_runs[col_idx][run_idx] = nil
          if table.is_empty(self.voice_runs[col_idx]) then
            table.remove(self.voice_runs,col_idx)
          end
        else
          -- always-always assign 'number_of_lines' to voice-runs
          local low_line,high_line = cLib.get_table_bounds(run)
          if not (run.number_of_lines) then
            local voice = self.voice_columns[col_idx]
            if voice then -- still open
              local final_on,final_off,final_cut = xVoiceRunner.get_final_notecol_info(run,true,vol_visible,pan_visible)
              if not run.single_line_trigger
                and ((final_cut and self.stop_at_note_cut)
               or (final_off and self.stop_at_note_off))
              then
                run.number_of_lines = 1+selection.end_line-high_line
                TRACE("xVoiceRunner:collect() - post-process, assigned length to open voice",run.number_of_lines)
              else
                -- extend to the selection boundary (actual length)
                local run_length = self:detect_run_length(ptrack_or_phrase,col_idx,high_line,num_lines,vol_visible,pan_visible)
                run.number_of_lines = high_line - low_line + run_length
                run.open_ended = ((low_line + run.number_of_lines - 1) >= selection.end_line)
                TRACE("xVoiceRunner:collect() - post-process, extend length to selection boundary",run.number_of_lines)
              end

            else
              run.number_of_lines = high_line-low_line
              TRACE("xVoiceRunner:collect() - post-process, set length",run.number_of_lines)
            end
          else
            -- implied note-off
          end
        end
      end

      -- purge zero-length runs - 
      -- can be caused e.g. by orphaned note-offs with #instrument  
      if (run.number_of_lines == 0) then
        self.voice_runs[col_idx][run_idx] = nil
        TRACE("xVoiceRunner:collect() - post-process, removed zero-length run")
      end 

    end
  end

  if self.compact_columns 
    and (collect_mode ~= xVoiceRunner.COLLECT_MODE.CURSOR)   
  then
    cLib.compact_table(self.voice_runs)
  end

end

---------------------------------------------------------------------------------------------------
-- select the voice-run directly below the cursor position
-- @return table or nil

function xVoiceRunner:collect_at_cursor()
  TRACE("xVoiceRunner:collect_at_cursor()")

  local ptrack_or_phrase = rns.selected_pattern_track
  local col_idx = rns.selected_note_column_index
  local line_idx = rns.selected_line_index

  self:reset()
  self:collect(ptrack_or_phrase,xVoiceRunner.COLLECT_MODE.CURSOR)
  local in_range = xVoiceRunner.in_range(self.voice_runs,line_idx,line_idx,{
    restrict_to_column = col_idx,
    include_before = true,
    include_after = true,
  })

  if in_range[col_idx] then
    local low_line_idx,_ = cLib.get_table_bounds(in_range[col_idx])
    return in_range[col_idx][low_line_idx]
  end

end

---------------------------------------------------------------------------------------------------
-- select the voice-run directly above the cursor position
-- @return table or nil

function xVoiceRunner:collect_above_cursor()
  TRACE("xVoiceRunner:collect_above_cursor()")

  local ptrack_or_phrase = rns.selected_pattern_track
  local col_idx = rns.selected_note_column_index
  local line_idx = rns.selected_line_index

  self:reset()
  self:collect(ptrack_or_phrase,xVoiceRunner.COLLECT_MODE.CURSOR)
  local in_range = xVoiceRunner.in_range(self.voice_runs,1,line_idx,{
    restrict_to_column = col_idx,
    include_before = true,
    include_after = true,
  })

  if in_range[col_idx] then
    local low,high = cLib.get_table_bounds(in_range[col_idx])
    for k = high,low,-1 do
      if in_range[col_idx][k] then
        local low_line,high_line = cLib.get_table_bounds(in_range[col_idx][k])
        if (line_idx > low_line) then
          return in_range[col_idx][k]
        end
      end
    end
  end

  if self.wrap_around_jump then
    if self.voice_runs[col_idx] then
      local low,high = cLib.get_table_bounds(self.voice_runs[col_idx])
      return self.voice_runs[col_idx][high]
    end
  end

end

---------------------------------------------------------------------------------------------------
-- select the voice-run directly below the cursor position
-- @return table or nil

function xVoiceRunner:collect_below_cursor()
  TRACE("xVoiceRunner:collect_below_cursor()")

  local ptrack_or_phrase = rns.selected_pattern_track
  local col_idx = rns.selected_note_column_index
  local line_idx = rns.selected_line_index
  local seq_idx = rns.selected_sequence_index
  local patt_idx = rns.sequencer:pattern(seq_idx)
  local patt = rns.patterns[patt_idx]

  self:reset()
  self:collect(ptrack_or_phrase,xVoiceRunner.COLLECT_MODE.CURSOR)
  --print(">>> post-collect self.voice_runs...")

  local in_range = xVoiceRunner.in_range(self.voice_runs,line_idx,patt.number_of_lines,{
    restrict_to_column = col_idx,
    include_before = true,
    include_after = true,
  })

  if in_range[col_idx] then
    local low,high = cLib.get_table_bounds(in_range[col_idx])
    for k = low,high do
      if in_range[col_idx][k] then
        local low_line,high_line = cLib.get_table_bounds(in_range[col_idx][k])
        if (line_idx < low_line) then
          return in_range[col_idx][k]
        end
      end
    end
  end

  if self.wrap_around_jump then
    if self.voice_runs[col_idx] then
      local low,high = cLib.get_table_bounds(self.voice_runs[col_idx])
      return self.voice_runs[col_idx][low]
    end
  end

end

---------------------------------------------------------------------------------------------------
-- detect what action to take on a given note-column
-- @return xVoiceRunner.CONDITIONS.XX

function xVoiceRunner:detect_run_condition(notecol,col_idx,vol_visible,pan_visible,from_pattern)
  TRACE("xVoiceRunner:detect_run_condition(notecol,col_idx,vol_visible,pan_visible,from_pattern)",notecol,col_idx,vol_visible,pan_visible,from_pattern)

  assert(type(notecol)=="NoteColumn" or type(notecol)=="xNoteColumn")
  assert(type(col_idx)=="number")
  assert(type(vol_visible)=="boolean")
  assert(type(pan_visible)=="boolean")

  local has_note_on,
    has_note_off,
    has_note_cut,
    has_instr_val,
    note_val,
    instr_idx,
    has_glide_cmd = xVoiceRunner.get_notecol_info(notecol,true,vol_visible,pan_visible)

  local condition = nil

  if (has_note_off or has_note_cut) and not has_note_on then 
    -- note-off/cut *after* triggering note
    if self.voice_columns[col_idx] then
      if (self.stop_at_note_off and has_note_off) then
        condition = xVoiceRunner.CONDITIONS.STOP_AT_NOTE_OFF
      elseif (self.stop_at_note_cut and has_note_cut) then
        condition = xVoiceRunner.CONDITIONS.STOP_AT_NOTE_CUT
      else
        condition = xVoiceRunner.CONDITIONS.CONTINUE_RUN_OFFED
      end
    end
  elseif has_instr_val or has_note_on then
    local note_changed = self.voice_columns[col_idx] 
      and (note_val ~= self.voice_columns[col_idx].note_value) or false
    if not self.voice_columns[col_idx] then
      condition = xVoiceRunner.CONDITIONS.CREATE_VOICE_RUN
    elseif has_note_on 
      and (self.split_at_note
        or (self.split_at_note_change
        and note_changed))
    then
      if self.link_ghost_notes 
        and not has_instr_val
        and from_pattern
      then
        condition = xVoiceRunner.CONDITIONS.CONTINUE_GHOST_NOTE
      elseif self.link_glide_notes 
        and has_glide_cmd
      then
        condition = xVoiceRunner.CONDITIONS.CONTINUE_GLIDE_NOTE
      else
        if note_changed then
          condition = xVoiceRunner.CONDITIONS.SPLIT_AT_NOTE_CHANGE
        else
          condition = xVoiceRunner.CONDITIONS.SPLIT_AT_NOTE
        end
      end
    elseif has_instr_val 
      and self.split_at_instrument_change
      and (instr_idx ~= self.voice_columns[col_idx].instrument_index)            
    then
      condition = xVoiceRunner.CONDITIONS.SPLIT_AT_INSTR_CHANGE
    elseif (self.voice_columns[col_idx].instrument_index == 0) 
      and not (has_note_on or has_instr_val)
    then
      condition = xVoiceRunner.CONDITIONS.CREATE_ORPHAN_RUN
    end
  elseif not notecol.is_empty then
    if self.voice_columns[col_idx] then
      condition = xVoiceRunner.CONDITIONS.CONTINUE_VOICE_RUN
    else
      condition = xVoiceRunner.CONDITIONS.CONTINUE_ORPHAN_RUN
    end
  end

  return condition,
    has_note_on,
    has_note_off,
    has_note_cut,
    has_instr_val,
    note_val,
    instr_idx,
    has_glide_cmd

end

---------------------------------------------------------------------------------------------------
-- check when a voice-run ends by examining the pattern-track
-- @param ptrack_or_phrase, renoise.PatternTrack
-- @param col_idx (int)
-- @param start_line (int), the line where the voice got triggered
-- @param end_line (int), iterate until this 
-- @param vol_visible (bool)
-- @param pan_visible (bool)
-- @return int, line index

function xVoiceRunner:detect_run_length(ptrack_or_phrase,col_idx,start_line,end_line,vol_visible,pan_visible)
  TRACE("xVoiceRunner:detect_run_length(ptrack_or_phrase,col_idx,start_line,end_line,vol_visible,pan_visible)",ptrack_or_phrase,col_idx,start_line,end_line,vol_visible,pan_visible)

  assert(type(ptrack_or_phrase)=="PatternTrack" or type(ptrack_or_phrase)=="InstrumentPhrase")
  assert(type(col_idx)=="number")
  assert(type(start_line)=="number")
  assert(type(end_line)=="number")

  if (start_line > end_line) then
    return 0
  end

  local from_pattern = (type(ptrack_or_phrase)=="PatternTrack")

  local line_rng = ptrack_or_phrase:lines_in_range(start_line,end_line)
  for k,line in ipairs(line_rng) do
    if (k > 1) then -- skip triggering line
      local line_idx = k + start_line - 1
      if not line.is_empty then
        for notecol_idx,notecol in ipairs(line.note_columns) do
          if not notecol.is_empty 
            and (col_idx == notecol_idx)
          then
            local run_condition = self:detect_run_condition(notecol,col_idx,vol_visible,pan_visible,from_pattern)
            if (run_condition == xVoiceRunner.CONDITIONS.STOP_AT_NOTE_OFF)
             or (run_condition == xVoiceRunner.CONDITIONS.STOP_AT_NOTE_CUT)
             or (run_condition == xVoiceRunner.CONDITIONS.SPLIT_AT_INSTR_CHANGE)
             or (run_condition == xVoiceRunner.CONDITIONS.CREATE_VOICE_RUN)
            then  
              return k
            elseif (run_condition == xVoiceRunner.CONDITIONS.SPLIT_AT_NOTE_OR_CHANGE) then
              return k-1
            end
          end
        end
      end
    end

  end
  
  return 1+end_line-start_line

end


---------------------------------------------------------------------------------------------------
-- get a specific note-column and its index
-- @param col_idx (int)
-- @param line_idx (int)
-- @return xNoteColumn or nil
-- @return int (run index) or nil

function xVoiceRunner:resolve_notecol(col_idx,line_idx)
  TRACE("xVoiceRunner:resolve_notecol(col_idx,line_idx)",col_idx,line_idx)

  assert(type(col_idx)=="number")
  assert(type(line_idx)=="number")

  local run_idx = xVoiceRunner.get_most_recent_run_index(self.voice_runs[col_idx],line_idx)
  if run_idx then
    local run = self.voice_runs[col_idx][run_idx]
    if run then
      return run[line_idx],run_idx
    end
  end

end

---------------------------------------------------------------------------------------------------
-- merge columns: rightmost notes in selection overrides earlier ones

function xVoiceRunner:merge_columns(ptrack_or_phrase,selection,trk_idx,seq_idx)
  TRACE("xVoiceRunner:merge_columns(ptrack_or_phrase,selection,trk_idx,seq_idx)",ptrack_or_phrase,selection,trk_idx,seq_idx)

  local collect_mode = xVoiceRunner.COLLECT_MODE.SELECTION
  self:collect(ptrack_or_phrase,collect_mode,selection,trk_idx,seq_idx)

  local temp_runs = {{}}
  local most_recent_run_idx = nil
  local most_recent_line_idx = nil

  local do_insert = function(voice,line_idx)
    table.insert(temp_runs[1],voice.voice_run)
    most_recent_run_idx = #temp_runs[1]
    most_recent_line_idx = line_idx
  end

  for line_idx = selection.start_line,selection.end_line do
    local line_runs = xVoiceRunner.get_runs_on_line(self.voice_runs,line_idx)
    for k,voice in ipairs(line_runs) do
      local notecol = voice.voice_run[line_idx]
      if (notecol.note_value < renoise.PatternLine.NOTE_OFF) then
        local has_room,in_range = xVoiceRunner.has_room(temp_runs,line_idx,1,voice.voice_run.number_of_lines)
        if not has_room then
          if (most_recent_line_idx == line_idx) then
            -- replace when column contains a run which start on this line
            temp_runs[1][most_recent_run_idx] = voice.voice_run
          elseif (most_recent_line_idx < line_idx) then
            -- the previous run was started prior to this line
            -- shorten it to make room for this one
            local previous_run = temp_runs[1][most_recent_run_idx]
            local num_lines = line_idx-most_recent_line_idx
            temp_runs[1][most_recent_run_idx] = xVoiceRunner.shorten_run(previous_run,num_lines)
            do_insert(voice,line_idx)
          end
        else
          do_insert(voice,line_idx)
        end
      end
    end
  end

  -- align merged runs to the left side of selection 
  -- (not written to pattern - selection is masking them out)
  local start_column = selection.start_column
  if (start_column > 1) then
    repeat
      table.insert(temp_runs,1,{})
      start_column=start_column-1
    until (start_column == 1)
  end

  self.voice_runs = temp_runs

  self:write(ptrack_or_phrase,selection,trk_idx)
  self:purge_voices()

end

---------------------------------------------------------------------------------------------------
-- if voice-run is longer than num_lines, shorten it 
-- (remove lines/note-columns, update #lines, set to implied off)

function xVoiceRunner.shorten_run(voice_run,num_lines)
  TRACE("xVoiceRunner.shorten_run(voice_run,num_lines)",voice_run,num_lines)

  local low,high = cLib.get_table_bounds(voice_run)
  for k,v in pairs(voice_run) do
    if (type(k)=="number") then
      if (k > (low+num_lines-1)) then
        voice_run[k] = nil
      end
    end
  end
  voice_run.number_of_lines = num_lines
  return voice_run

end

---------------------------------------------------------------------------------------------------
-- write the current voice-runs to the provided pattern-track
-- @param ptrack_or_phrase (renoise.PatternTrack or renoise.InstrumentPhrase)
-- @param selection (table)
-- @param trk_idx (int)

function xVoiceRunner:write(ptrack_or_phrase,selection,trk_idx)
  TRACE("xVoiceRunner:write(ptrack_or_phrase,selection,trk_idx)",ptrack_or_phrase,selection,trk_idx)

  assert(type(ptrack_or_phrase)=="PatternTrack" or type(ptrack_or_phrase)=="InstrumentPhrase")

  local writing_to_pattern = (type(ptrack_or_phrase)=="PatternTrack")

  local vol_visible,pan_visible,dly_visible
  local track = rns.tracks[trk_idx]
  if writing_to_pattern then
    vol_visible = track.volume_column_visible
    pan_visible = track.panning_column_visible
    dly_visible = track.delay_column_visible
  else
    vol_visible = ptrack_or_phrase.volume_column_visible
    pan_visible = ptrack_or_phrase.panning_column_visible
    dly_visible = ptrack_or_phrase.delay_column_visible
  end

  local scheduled_noteoffs = {}
  local open_ended = {}

  --local clear_undefined = true
  local line_rng = ptrack_or_phrase:lines_in_range(selection.start_line,selection.end_line)
  for k,line in ipairs(line_rng) do
    local line_idx = k + selection.start_line - 1

    for col_idx,run_col in pairs(self.voice_runs) do
      local within_range = (col_idx >= selection.start_column)
        and (col_idx <= selection.end_column)
      if within_range then
        local notecol = line.note_columns[col_idx]
        notecol:clear()
        for run_idx,run in pairs(run_col) do
          if run[line_idx] then
            local low,high = cLib.get_table_bounds(run)
            local xnotecol = xNoteColumn(run[line_idx])
            xnotecol:do_write(notecol)
            if self.create_noteoffs then
              scheduled_noteoffs[col_idx] = {
                line_index = low+run.number_of_lines,
                run_index = run_idx,
              }
            end
            open_ended[col_idx] = run.open_ended 
          elseif scheduled_noteoffs[col_idx]
            and (scheduled_noteoffs[col_idx].line_index == line_idx)
            and (scheduled_noteoffs[col_idx].run_index == run_idx)
          then
            if run.actual_noteoff_col then
              run.actual_noteoff_col:do_write(notecol) 
            elseif not run.single_line_trigger 
              and not run.orphaned
            then
              notecol.note_value = renoise.PatternLine.NOTE_OFF
            end
            scheduled_noteoffs[col_idx] = nil
          end
        end

        -- do stuff at the last line? 
        if (line_idx == selection.end_line) then
          if self.close_open_notes then
            if open_ended[col_idx] then
              xVoiceRunner.terminate_note(
                notecol,
                self.reveal_subcolumns,
                vol_visible,
                pan_visible,
                dly_visible,
                track or ptrack_or_phrase)
            end
          end
        end
      end -- /within range

    end

  end

  local low_col,high_col = cLib.get_table_bounds(self.voice_runs)

  -- figure out # visible columns (expand when needed)
  local track_or_phrase
  if writing_to_pattern then
    track_or_phrase = rns.tracks[trk_idx]
  else
    track_or_phrase = rns.selected_phrase
  end
  if high_col then
    track_or_phrase.visible_note_columns = math.max(high_col,track_or_phrase.visible_note_columns)
  end

  -- clear leftover columns
  if high_col and self.high_column then
    local line_rng = ptrack_or_phrase:lines_in_range(selection.start_line,selection.end_line)
    for k,line in ipairs(line_rng) do
      local line_idx = k + selection.start_line - 1
      for col_idx = self.high_column,high_col+1,-1 do
        local notecol = line.note_columns[col_idx]
        notecol:clear()
      end
    end
  end


end


---------------------------------------------------------------------------------------------------
-- Static Methods
---------------------------------------------------------------------------------------------------
-- @param vrun (table)
-- @param trk_idx (number)
-- @param col_idx (number)
-- @return table, pattern selection spanning the provided voice-run

function xVoiceRunner.get_voice_run_selection(vrun,trk_idx,col_idx)
  TRACE("xVoiceRunner.get_voice_run_selection(vrun,trk_idx,col_idx)",vrun,trk_idx,col_idx)

  local low,high = cLib.get_table_bounds(vrun)
  local end_line = low + vrun.number_of_lines - 1

  end_line = ((vrun.implied_noteoff and not vrun.actual_noteoff_col)
      or vrun.open_ended  
      or not vrun.actual_noteoff_col
      or vrun.single_line_trigger) and end_line or end_line+1

  return {
    start_line = low,
    start_track = trk_idx,
    start_column = col_idx,
    end_line = end_line,
    end_track = trk_idx,
    end_column = col_idx,
  }

end

---------------------------------------------------------------------------------------------------
-- figure out if a given range contains any voice-runs
-- @param voice_runs (table)
-- @param line_start (int)
-- @param col_idx (int)
-- @param num_lines (int)
-- @return bool, true when no runs
-- @return table, voice-runs in range

function xVoiceRunner.has_room(voice_runs,line_start,col_idx,num_lines)
  TRACE("xVoiceRunner:has_room(voice_runs,line_start,col_idx,num_lines)",voice_runs,line_start,col_idx,num_lines)

  assert(type(line_start)=="number")
  assert(type(col_idx)=="number")
  assert(type(num_lines)=="number")

  local line_end = line_start + num_lines -1
  local in_range = xVoiceRunner.in_range(voice_runs,line_start,line_end,{
    restrict_to_column = col_idx,
    include_before = true,
    include_after = true,
  })
  local has_room = (#table.keys(in_range) == 0)
  return has_room,in_range

end

---------------------------------------------------------------------------------------------------
-- collect runs that are triggered during a particular range of lines
-- @param voice_runs (table)
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

  local rslt = {}
  if args.exclude_columns and args.restrict_to_column then
    LOG("*** in_range - warning: use _either_ exclude_columns or restrict_to_column, not both!")
    return rslt
  end

  local matched_columns = args.matched_columns or {}
  local exclude_columns = args.exclude_columns or {}

  -- convert restrict->exclude (negate)
  if args.restrict_to_column then
    for k = 1,12 do
      exclude_columns[k] = (k ~= args.restrict_to_column) and true or false
    end
  end

  local do_include_run = function(col_idx,run_idx)
    cLib.expand_table(rslt,col_idx)
    rslt[col_idx][run_idx] = voice_runs[col_idx][run_idx]
    matched_columns[col_idx] = true 
  end

  -- first, look for runs that start on the line
  for line_idx = line_start,line_end do
    for col_idx,run_col in pairs(voice_runs) do
      if exclude_columns[col_idx] then
      else 
        for run_idx,v3 in pairs(run_col) do
          if v3[line_idx] then
            local include_run = false
            if args.include_after then
              include_run = true
            else 
              -- verify that run ends within the range
              include_run = (line_end >= line_idx+v3.number_of_lines)
            end
            if include_run then
              do_include_run(col_idx,run_idx)
              break
            end
          end
        end 
      end 
    end 
  end

  -- secondly, iterate back through lines to catch "open runs"
  if args.include_before then
    for col_idx,run_col in pairs(voice_runs) do
      -- examine non-triggered/excluded lines only...
      if exclude_columns[col_idx] 
        or matched_columns[col_idx]
      then
        -- in_range/include_before - skip column 
      else
        local prev_run_idx = xVoiceRunner.get_open_run(run_col,line_start) 
        if prev_run_idx then
          do_include_run(col_idx,prev_run_idx)
        end
      end
    end
  end

  return rslt,matched_columns

end

---------------------------------------------------------------------------------------------------
-- collect runs that begin on a specific line 
-- @param voice_runs (table)
-- @param line_idx (int)
-- @return table - see xVoiceRunner.create_voice()

function xVoiceRunner.get_runs_on_line(voice_runs,line_idx)
  TRACE("xVoiceRunner.get_runs_on_line(voice_runs,line_idx)",voice_runs,line_idx)

  local line_runs = {}
  for col_idx,run_col in pairs(voice_runs) do
    for run_idx,run in pairs(run_col) do
      local low_line,high_line = cLib.get_table_bounds(run)
      if (low_line == line_idx) then
        local voice = xVoiceRunner.create_voice(run,col_idx,run_idx,low_line)
        table.insert(line_runs,voice) 
      end
    end
  end

  return line_runs

end

---------------------------------------------------------------------------------------------------
-- create a voice table (to ensure correct variable types...)
-- @param voice_run (table)
-- @param col_idx (number)
-- @param run_idx (number)
-- @param line_idx (number)
-- @return table

function xVoiceRunner.create_voice(voice_run,col_idx,run_idx,line_idx)
  TRACE("xVoiceRunner.create_voice(voice_run,col_idx,run_idx,line_idx)",voice_run,col_idx,run_idx,line_idx)

  assert(type(voice_run)=="table")
  assert(type(col_idx)=="number")
  assert(type(run_idx)=="number")
  assert(type(line_idx)=="number")

  return {
    voice_run = voice_run,
    col_idx = col_idx,
    run_idx = run_idx,
    line_idx = line_idx,
  }

end

---------------------------------------------------------------------------------------------------
-- Voice-run methods
---------------------------------------------------------------------------------------------------
-- @param voice_run, table
-- @return int, note value or nil
-- @return int, line index

function xVoiceRunner.get_initial_notecol(voice_run)
  TRACE("xVoiceRunner.get_initial_notecol(voice_run)",voice_run)

  local low_line,high_line = cLib.get_table_bounds(voice_run)
  return voice_run[low_line],low_line

end

---------------------------------------------------------------------------------------------------
-- Voice-run (column methods)
---------------------------------------------------------------------------------------------------
-- retrieve the previous run if it overlaps with the provided line
-- @param run_col (table)
-- @param line_start (int)
-- @return int or nil

function xVoiceRunner.get_open_run(run_col,line_start)
  TRACE("xVoiceRunner.get_open_run(run_col,line_start)",run_col,line_start)

  local matched = false
  for run_idx,run in pairs(run_col) do
    local low,high = cLib.get_table_bounds(run)
    local end_line = low+run.number_of_lines-1
    if (low < line_start) and (end_line >= line_start) then
      return run_idx
    end
  end

end

---------------------------------------------------------------------------------------------------
-- find occurrences of notes which are higher than the specified one
-- (NB: will only look for the _initial_ note)
-- @param run_col (table)
-- @param note_val (int)
-- @return int, run index or nil
-- @return int, line index or nil

function xVoiceRunner.get_higher_notes_in_column(run_col,note_val)
  TRACE("xVoiceRunner.get_higher_notes_in_column(run_col,note_val)",run_col,xNoteColumn.note_value_to_string(note_val))

  local matches = {}
  if not table.is_empty(run_col) then
    for run_idx,voice_run in pairs(run_col) do
      local low_line,high_line = cLib.get_table_bounds(voice_run)
      if (voice_run[low_line].note_value > note_val) then
        table.insert(matches,{
          run_idx = run_idx,
          line_idx = low_line,
        })
      end
    end
  end

  return matches

end

---------------------------------------------------------------------------------------------------
-- find the index of the most recent run at the provided line
-- @param run_col (table)
-- @param line_idx (int)
-- @return int or nil

function xVoiceRunner.get_most_recent_run_index(run_col,line_idx)
  TRACE("xVoiceRunner.get_most_recent_run_index(run_col,line_idx)",run_col,line_idx)

  assert(type(run_col)=="table")
  assert(type(line_idx)=="number")

  local most_recent = nil
  local is_empty = table.is_empty(run_col)
  if not is_empty then
    for run_idx,run in pairs(run_col) do
      local low,high = cLib.get_table_bounds(run)
      if high then
        for k = 1,math.min(line_idx,high) do
          if run[k] then
            most_recent = run_idx
          end
          if most_recent and (k == line_idx) then
            break
          end
        end  
      end  
    end  
  end

  return most_recent

end

---------------------------------------------------------------------------------------------------
-- check the lowest/highest note-values for a given column
-- @param run_col (table), required
-- @param line_start (int)
-- @param line_end (int) 
-- @return int, low note-value or nil
-- @return int, high note-value or nil

function xVoiceRunner.get_high_low_note_values(run_col,line_start,line_end)
  TRACE("xVoiceRunner.get_high_low_note_values(run_col,line_start,line_end)",run_col,line_start,line_end)

  assert(type(run_col)=="table")

  local restrict_to_lines = (line_start and line_end) and true or false
  local low_note,high_note = 1000,-1000
  local matched = false
  local within_range = false
  for run_idx,run in pairs(run_col) do
    for line_idx,v3 in pairs(run) do
      if (type(v3)=="table") then 
        within_range = (restrict_to_lines 
          and (line_idx >= line_start)
          and (line_idx <= line_end)) 
        if (v3.note_value < renoise.PatternLine.NOTE_OFF)
          and (not restrict_to_lines 
            or (restrict_to_lines and within_range))
        then
          low_note = math.min(low_note,v3.note_value)
          high_note = math.max(high_note,v3.note_value)
          matched = true
        end
      end
    end
    if matched and not within_range then
      break
    end    
  end

  if matched then
    return high_note,low_note
  end

end

---------------------------------------------------------------------------------------------------
-- retrieve the first and last line in column
-- @param run_col (table), "voice-run column"

function xVoiceRunner.get_column_start_end_line(run_col)
  TRACE("xVoiceRunner.get_column_start_end_line(run_col)",run_col)

  if not run_col or table.is_empty(table.keys(run_col)) then
    return
  end

  local start_line,end_line = 513,0
  for run_idx,run in pairs(run_col) do
    local low,high = cLib.get_table_bounds(run_col[run_idx])
    end_line = math.max(end_line,high) 
    start_line = math.min(start_line,low) 
  end
  return start_line,end_line

end

---------------------------------------------------------------------------------------------------
-- @param voice_run, table
-- @param respect_visibility (bool)
-- @param vol_visible (bool)
-- @param pan_visible (bool)
-- @return vararg - see xVoiceRunner.get_notecol_info()

function xVoiceRunner.get_final_notecol_info(voice_run,respect_visibility,vol_visible,pan_visible)
  TRACE("xVoiceRunner.get_final_notecol_info(voice_run,respect_visibility,vol_visible,pan_visible)",voice_run,respect_visibility,vol_visible,pan_visible)

  local low,high = cLib.get_table_bounds(voice_run)
  return xVoiceRunner.get_notecol_info(voice_run[high],respect_visibility,vol_visible,pan_visible)

end

---------------------------------------------------------------------------------------------------
-- obtain a bunch of useful info about a note-column
-- @param notecol (renoise.NoteColumn or xNoteColumn)
-- @param respect_visibility (bool)
-- @param vol_visible (bool)
-- @param pan_visible (bool)

function xVoiceRunner.get_notecol_info(notecol,respect_visibility,vol_visible,pan_visible)
  TRACE("xVoiceRunner.get_notecol_info(notecol,respect_visibility,vol_visible,pan_visible)",notecol,respect_visibility,vol_visible,pan_visible)

  local has_instr_val = (notecol.instrument_value < 255) 
  local note_val = (notecol.note_value < renoise.PatternLine.NOTE_OFF) 
    and notecol.note_value or nil
  local instr_idx = has_instr_val and notecol.instrument_value+1 or nil
  local has_note_on = (notecol.note_value < renoise.PatternLine.NOTE_OFF)
  local has_note_off = (notecol.note_value == renoise.PatternLine.NOTE_OFF)

  local has_note_cut = false
  local volume_is_cut = (string.sub(notecol.volume_string,0,1) == "C")
  local panning_is_cut = (string.sub(notecol.panning_string,0,1) == "C")
  if respect_visibility then
    if volume_is_cut then
      has_note_cut = vol_visible 
    elseif panning_is_cut then
      has_note_cut = pan_visible 
    end
  else
    has_note_cut = volume_is_cut or panning_is_cut
  end

  local has_glide_cmd = false
  local volume_glides = (string.sub(notecol.volume_string,0,1) == "G")
  local panning_glides = (string.sub(notecol.panning_string,0,1) == "G")
  if respect_visibility then
    if volume_glides then
      has_glide_cmd = vol_visible 
    elseif panning_glides then
      has_glide_cmd = pan_visible 
    end
  else
    has_glide_cmd = volume_glides or panning_glides
  end


  return has_note_on,has_note_off,has_note_cut,has_instr_val,note_val,instr_idx,has_glide_cmd

end

---------------------------------------------------------------------------------------------------
-- terminate the note by whichever means
-- @param notecol (renoise.NoteColumn or xNoteColumn)
-- @param reveal_subcolumns (boolean)
-- @param vol_visible (boolean)
-- @param pan_visible (boolean)
-- @param dly_visible (boolean)
-- @param track_or_phrase (renoise.PatternTrack or renoise.InstrumentPhrase)

function xVoiceRunner.terminate_note(notecol,reveal_subcolumns,vol_visible,pan_visible,dly_visible,track_or_phrase)
  TRACE("xVoiceRunner.terminate_note(notecol,reveal_subcolumns,vol_visible,pan_visible,dly_visible,track_or_phrase)",notecol,reveal_subcolumns,vol_visible,pan_visible,dly_visible,track_or_phrase)

  local max_tick = rns.transport.tpl-1 -- TODO fixed amount in phrases
  local str_note_cut = ("C%X"):format(max_tick)

  local has_note_on,has_note_off,has_note_cut = 
    xVoiceRunner.get_notecol_info(notecol,true,vol_visible,pan_visible)

  if has_note_off or has_note_cut then
    -- terminate_note - already terminated 
  elseif has_note_on then
    if (notecol.panning_value == 255) 
    then      
      notecol.panning_string = str_note_cut
      pan_visible = true
    elseif (notecol.volume_value == 255) 
    then
      notecol.volume_string = str_note_cut
      vol_visible = true
    end
  else
    notecol.note_value = renoise.PatternLine.NOTE_OFF
    notecol.delay_value = 255
    dly_visible = true
  end

  if reveal_subcolumns then
    track_or_phrase.volume_column_visible = vol_visible
    track_or_phrase.panning_column_visible = pan_visible
    track_or_phrase.delay_column_visible = dly_visible
  end

end

