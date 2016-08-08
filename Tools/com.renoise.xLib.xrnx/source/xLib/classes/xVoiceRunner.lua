--[[============================================================================
xVoiceRunner
============================================================================]]--

--[[--

This class converts pattern-tracks into 'voice-runs' - small note sequences
.
#

## About

xVoiceRunner provides a highly configurable method for extracting pattern data. 

See also: xVoiceSorter

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

-------------------------------------------------------------------------------

function xVoiceRunner:__init(...)
  TRACE("xVoiceRunner:__init(...)",...)

	local args = xLib.unpack_args(...)

  --print("type(args.split_at_note)",type(args.split_at_note),args.split_at_note)

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

  -- internal -------------------------

  -- xVoiceRunnerTemplate, decides which notes to collect (optional)
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

  -- table of xNoteColumns, active voice from trigger to (implied) release
  -- table = {
  --  [column_index] = {                  -- pairs
  --    [voice_run_index] = {             -- pairs
  --      [number_of_lines] = int or nil  -- always set, including trailing blank space
  --      [implied_noteoff] = bool or nil -- set when switching note/instr while having an active (non-offed) voice - see also split_on_note_xx options
  --      [open_ended] = bool or nil      -- set when voice extends beyond selection/pattern boundary
  --      [orphaned] = bool or nil        -- set on data with no prior voice (such as when we stop at note-off, note-cut...)
  --      [actual_noteoff_col] = xNoteColumn or nil -- set when note-off/cut is explicit 
  --      [single_line_trigger] = bool or nil -- set when Cx on same line as note (only possible when stop_at_note_cut is true)
  --      [__replaced] = bool or nil      -- temporarily set when replacing entries (TODO clear when done with line)
  --      [__skip_template] = bool or nil -- true when the template tell us to ignore this note
  --      [line_idx] =                    -- xNoteColumn
  --      [line_idx] =                    -- xNoteColumn
  --      [line_idx] =                    -- etc...
  --     }
  --   }
  -- }
  self.voice_runs = {}

  --- table, defines the high/low note values in each column
  -- (used when sorting by note)
  --  {
  --    column_index = int,
  --    low_note = int,
  --    high_note = int,
  --  }
  self.high_low_columns = {}
  
  --- another important structure is the 'voice', a single voice-run 
  --  with some additional information. The table is produced by the
  --  get_runs_on_line() method
  --
  --  table{
  --    voice_run = v2,
  --    col_idx = col_idx,
  --    run_idx = run_idx,
  --    line_idx = low,
  --  }

  self.voice_runs_remove_column_observable = renoise.Document.ObservableBang()
  self.removed_column_index = nil

  self.voice_runs_insert_column_observable = renoise.Document.ObservableBang()
  self.inserted_column_index = nil

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

  -- bool, compact runs when collecting (remove empty columns)
  self.compact_columns = true

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
-- remove a column and trigger the observable 

function xVoiceRunner:remove_voice_column(col_idx)
  TRACE("xVoiceRunner:remove_voice_column(col_idx)",col_idx)

  assert(type(col_idx)=="number")

  xLib.sparse_table_remove(self.voice_runs,col_idx)
  --[[
  local is_sparse = xLib.is_sparse_table(self.voice_runs)
  if is_sparse then
    self.voice_runs[col_idx] = nil
  else
    table.remove(self.voice_runs,col_idx)
  end
  ]]

  self.removed_column_index = col_idx
  self.voice_runs_remove_column_observable:bang()

  for k,v in ripairs(self.high_low_columns) do
    if (v.column_index == col_idx) then table.remove(self.high_low_columns,k) end
    if (v.column_index > col_idx) then v.column_index = v.column_index-1 end
  end

end



-------------------------------------------------------------------------------

function xVoiceRunner:insert_voice_column(col_idx,voice_run)
  print("xVoiceRunner:insert_voice_column(col_idx,voice_run)",col_idx,voice_run)

  assert(type(col_idx)=="number")

  xLib.sparse_table_insert(self.voice_runs,col_idx,{voice_run})
  --[[
  local is_sparse = xLib.is_sparse_table(self.voice_runs)
  if is_sparse and not self.voice_runs[col_idx] then
    self.voice_runs[col_idx] = {voice_run}
  elseif not is_sparse then
    table.insert(self.voice_runs,col_idx,{voice_run})
  end
  ]]

  self.inserted_column_index = col_idx
  self.voice_runs_insert_column_observable:bang()

  -- update high_low_columns
  for k,v in ipairs(self.high_low_columns) do
    if (v.column_index >= col_idx) then v.column_index = v.column_index+1 end
  end
  local high_note,low_note = xVoiceRunner.get_high_low_note_values(self.voice_runs[col_idx])
  self:set_high_low_column(col_idx,high_note,low_note)

  --print("*** insert_voice_column - voice_runs...",rprint(self.voice_runs))

end

-------------------------------------------------------------------------------
-- gather voice-runs according to the specified settings
-- @param ptrack_or_phrase (renoise.PatternTrack)
-- @param collect_mode (xVoiceRunner.COLLECT_MODE)
-- @param trk_idx (int)
-- @param seq_idx (int)
-- @param selection (table)

function xVoiceRunner:collect(ptrack_or_phrase,collect_mode,selection,trk_idx,seq_idx)
  TRACE("xVoiceRunner:collect(ptrack_or_phrase,collect_mode,selection,trk_idx,seq_idx)",ptrack_or_phrase,collect_mode,selection,trk_idx,seq_idx)

  assert(type(ptrack_or_phrase)=="PatternTrack" or type(ptrack_or_phrase)=="InstrumentPhrase")
  assert(type(collect_mode)=="number")

  if ptrack_or_phrase.is_empty then
    LOG("Skip empty pattern-track...")
    return
  end

  local collecting_from_pattern = (type(ptrack_or_phrase)=="PatternTrack")

  local prnt = function(...)
    print(...)
  end

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
    --selection = selection
  end
  --print("selection",rprint(selection))
  --print("trk_idx",trk_idx)

  --xLib.expand_table(self.voice_columns,trk_idx)


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
    --prnt("collect - line",k)

    local line_idx = k + selection.start_line - 1

    if not line.is_empty then
      --local has_midi_cmd = xLinePattern.get_midi_command(track,line)
      for col_idx,notecol in ipairs(line.note_columns) do
        if not notecol.is_empty 
          and (col_idx > visible_note_columns) 
          or ((col_idx < selection.start_column) 
            or (col_idx > selection.end_column))
        then
          --prnt("*** process_pattern_track - skip hidden column",col_idx )
        else

          prnt("*** process_pattern_track - line_idx,col_idx",line_idx,col_idx)

          --[[
          local has_note_on,has_note_off,has_note_cut,has_instr_val,note_val,instr_idx,has_glide_cmd = 
            xVoiceRunner.get_notecol_info(notecol,track,true)

          print("has_glide_cmd",has_glide_cmd)
          print("has_note_cut",has_note_cut)
          ]]

          --local is_midi_cmd = has_midi_cmd and (col_idx == track.visible_note_columns)
          --if is_midi_cmd then
            --prnt("*** process_pattern_track - skip midi command",k,col_idx)
          --else

            --[[
            if note_val and instr_idx then
              xLib.expand_table(self.unique_notes,note_val,instr_idx-1)
              self.unique_notes[note_val][instr_idx-1] = true
            elseif note_val then
              xLib.expand_table(self.unique_notes,note_val)
            end
            ]]

            local begin_voice_run = false
            local stop_voice_run = false
            local implied_noteoff = false
            local orphaned = false
            local actual_noteoff_col = nil

            local run_condition,has_note_on,has_note_off,has_note_cut,has_instr_val,note_val,instr_idx,has_glide_cmd
              = self:detect_run_condition(notecol,col_idx,vol_visible,pan_visible)

            print("instr_idx,note_val",instr_idx,note_val)

            local assign_instr_and_note = function()
              instr_idx = has_instr_val and instr_idx or xVoiceRunner.GHOST_NOTE
              note_val = has_note_on and note_val or nil
              print("assign_instr_and_note",instr_idx,note_val)
            end

            local handle_note_off_cut = function()
              prnt(">>> handle_note_off_cut - stop voice run")
              actual_noteoff_col = xNoteColumn(xNoteColumn.do_read(notecol))
              stop_voice_run = true
              instr_idx = self.voice_columns[col_idx].instrument_index
              self.voice_columns[col_idx] = nil
            end

            local handle_offed_run = function()
              prnt(">>> handle_offed_run - voice offed")
              self.voice_columns[col_idx].offed = true
              instr_idx = self.voice_columns[col_idx].instrument_index
            end

            local handle_create_voice_run = function()
              prnt(">>> handle_create_voice_run - create voice run")
              assign_instr_and_note()
              begin_voice_run = true
              self.voice_columns[col_idx] = {
                instrument_index = instr_idx,
                note_value = note_val,
              }
            end

            local handle_create_orphan_run = function()
              prnt(">>> handle_create_orphan_run")
              begin_voice_run = true
              orphaned = true
              instr_idx = 0
              self.voice_columns[col_idx] = {
                instrument_index = instr_idx,
              }
            end

            local handle_split_at_note_or_change = function()
              prnt(">>> handle_split_at_note_or_change")
              assign_instr_and_note()
              implied_noteoff = not self.voice_columns[col_idx].offed and true or false
              begin_voice_run = true
              self.voice_columns[col_idx] = {
                instrument_index = instr_idx, 
                note_value = note_val,
              }
            end

            local handle_instrument_change = function()
              prnt(">>> handle_instrument_change")
              implied_noteoff = not self.voice_columns[col_idx].offed and true or false 
              begin_voice_run = true
              self.voice_columns[col_idx] = {
                instrument_index = instr_idx,
                note_value = note_val,
              }
            end

            local handle_continue_orphan_run = function()
              prnt(">>> handle_continue_orphan_run")
              --begin_voice_run = true
              self.voice_columns[col_idx] = {
                instrument_index = instr_idx,
                note_value = note_val,
              }
            end

            local handle_continue_voice_run = function()
              prnt(">>> handle_continue_voice_run")
              instr_idx = self.voice_columns[col_idx].instrument_index
            end

            local handle_continue_ghost_note = function()
              prnt(">>> handle_continue_ghost_note")
              assign_instr_and_note()
            end

            local handle_continue_glide_note = function()
              prnt(">>> handle_continue_glide_note")
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

            --[[
            if (has_note_off 
              or has_note_cut)
              and not has_note_on
            then -- note-off/cut *after* triggering note
              prnt("*** note-off/cut *after* triggering note")
              prnt("*** has_note_off,has_note_cut",has_note_off,has_note_cut)
              if self.voice_columns[col_idx] then
                if (self.stop_at_note_off and has_note_off)
                  or (self.stop_at_note_cut and has_note_cut)
                then
                  actual_noteoff_col = xNoteColumn(xNoteColumn.do_read(notecol))
                  --prnt("actual_noteoff_col",notecol)
                  stop_voice_run = true
                  instr_idx = self.voice_columns[col_idx].instrument_index
                  self.voice_columns[col_idx] = nil
                  prnt(">>> process_pattern_track - stop voice run")
                else
                  -- continue collecting from column, but set as 'offed'
                  self.voice_columns[col_idx].offed = true
                  instr_idx = self.voice_columns[col_idx].instrument_index
                  prnt(">>> process_pattern_track - voice offed")
                end
              end
            elseif has_instr_val 
              or has_note_on
            then -- continue or create voice-run
              prnt("*** continue or create voice-run")
              instr_idx = has_instr_val and instr_idx or xVoiceRunner.GHOST_NOTE
              note_val = has_note_on and note_val or nil

              --prnt("*** collect - trk_idx,self.voice_columns...",trk_idx,rprint(self.voice_columns))

              if not self.voice_columns[col_idx] then
                -- create voice run 
                prnt(">>> process_pattern_track - create voice run")
                begin_voice_run = true
                self.voice_columns[col_idx] = {
                  instrument_index = has_instr_val and instr_idx or xVoiceRunner.GHOST_NOTE,
                  note_value = note_val,
                }
              elseif has_note_on 
                and (self.split_at_note
                  or (self.split_at_note_change
                    and (note_val ~= self.voice_columns[col_idx].note_value)))
              then
                -- changed note
                if self.link_ghost_notes 
                  and (instr_idx == xVoiceRunner.GHOST_NOTE)
                then
                  prnt(">>> process_pattern_track - link ghost notes (continue run)")
                elseif self.link_glide_notes 
                  and has_glide_cmd
                then
                  prnt(">>> process_pattern_track - link glide notes (continue run)")
                else
                  prnt(">>> process_pattern_track - changed note, create voice run")
                  implied_noteoff = not self.voice_columns[col_idx].offed and true or false
                  begin_voice_run = true
                  self.voice_columns[col_idx] = {
                    instrument_index = instr_idx, 
                    note_value = note_val,
                  }
                end

              elseif has_instr_val 
                and self.split_at_instrument_change
                and (instr_idx ~= self.voice_columns[col_idx].instrument_index)
              then
                -- changed instrument
                prnt(">>> process_pattern_track - changed instrument, create voice run")
                implied_noteoff = not self.voice_columns[col_idx].offed and true or false 
                begin_voice_run = true
                self.voice_columns[col_idx] = {
                  instrument_index = instr_idx,
                  note_value = note_val,
                }
              elseif (self.voice_columns[col_idx].instrument_index == 0) 
                and not (has_note_on or has_instr_val)
              then
                prnt(">>> process_pattern_track - orphaned run")
                begin_voice_run = true
                self.voice_columns[col_idx] = {
                  instrument_index = instr_idx,
                  note_value = note_val,
                }
              end

            elseif not notecol.is_empty then
              if self.voice_columns[col_idx] then
                instr_idx = self.voice_columns[col_idx].instrument_index
                prnt(">>> process_pattern_track - continue voice run")
              else
                -- capture 'orphaned' data and assign to instrument 0 
                prnt(">>> process_pattern_track - voice run (orphan)")                
                begin_voice_run = true
                orphaned = true
                instr_idx = 0
                self.voice_columns[col_idx] = {
                  instrument_index = instr_idx,
                }

              end
            end
            ]]

            local include_as_unique = true

            -- add entry to the voice_runs table
            print("instr_idx",type(instr_idx),instr_idx)  
            if (type(instr_idx)=="number") then

              prnt("*** collect - k,notecol,instr_idx",k,notecol.note_string,instr_idx)
              
              local voice_run,run_index = nil,nil
              if self.voice_runs and self.voice_runs[col_idx] then
                run_index = #self.voice_runs[col_idx]
              end
              if run_index then
                voice_run = self.voice_runs[col_idx][run_index]
              end

              if voice_run and implied_noteoff then
                voice_run.implied_noteoff = implied_noteoff
                prnt("*** collect - implied_noteoff",implied_noteoff)
              end

              prnt("*** collect - line_idx,voice_run,begin_voice_run",line_idx,voice_run,begin_voice_run)
              prnt("*** collect - notecol.note_string",notecol.note_string)

              -- opportune moment to compute number of lines: before a new run
              if voice_run and begin_voice_run 
                --and not voice_run.single_line_trigger 
                and not voice_run.number_of_lines
              then
                local low,high = xLib.get_table_bounds(voice_run)
                prnt("collect - before new run - number_of_lines",low,high,k-low)
                voice_run.number_of_lines = k-low
              end

              xLib.expand_table(self.voice_runs,col_idx)
              run_index = #self.voice_runs[col_idx] + (begin_voice_run and 1 or 0)
              xLib.expand_table(self.voice_runs,col_idx,run_index)

              voice_run = self.voice_runs[col_idx][run_index]
              voice_run[line_idx] = xNoteColumn.do_read(notecol)
              --rprint(voice_run[line_idx])
              prnt("*** collect - line_idx,run_index,stop_voice_run",line_idx,run_index,stop_voice_run)
              prnt("*** collect - has_note_cut,self.stop_at_note_cut",has_note_cut,self.stop_at_note_cut)

              if stop_voice_run then
                local low,high = xLib.get_table_bounds(voice_run)
                local num_lines = high-low
                prnt("collect - stop_voice_run - number_of_lines",low,high,num_lines)
                voice_run.number_of_lines = num_lines

                -- shave off the last note-column when using 'actual_noteoff_col' 
                if actual_noteoff_col then
                  voice_run[high] = nil
                end

              elseif begin_voice_run and has_note_cut and self.stop_at_note_cut then
                -- capture single line
                prnt("collect - note-cut on triggering line")
                voice_run.number_of_lines = 1
                voice_run.single_line_trigger = true
              end

              if has_note_cut or has_note_off then
                if (self.stop_at_note_off and has_note_off)
                  or (self.stop_at_note_cut and has_note_cut)
                then
                  self.voice_columns[col_idx] = nil
                  prnt("*** collect - has_note_cut or has_note_off - nullify voice",col_idx)
                else
                  self.voice_columns[col_idx].offed = true
                  prnt("*** collect - has_note_cut or has_note_off - set voice as offed",col_idx)
                end
              end

              if actual_noteoff_col then
                voice_run.actual_noteoff_col = actual_noteoff_col
              end

              if orphaned then
                voice_run.orphaned = orphaned
              end


              if begin_voice_run and has_note_on and self.template then
                -- the template can tell whether to include this run 
                local entries,indices = self.template:get_entries({
                  note_value = note_val,
                  instrument_value = instr_idx-1 
                })
                print("include this run? entries,indices",rprint(entries),rprint(indices))
                if (#indices > 0) then
                  for k,v in ipairs(entries) do
                    if not v.active then
                      print(">>> __skip_template")
                      voice_run.__skip_template = true
                      include_as_unique = false
                      break
                    end
                  end
                end
              end

            end

            if include_as_unique then
              if note_val and instr_idx then
                xLib.expand_table(self.unique_notes,note_val,instr_idx-1)
                self.unique_notes[note_val][instr_idx-1] = true
              elseif note_val then
                xLib.expand_table(self.unique_notes,note_val)
              end
            end


          --end -- skip MIDI

        end
      end
    end

  end

  --prnt("voice-runs PRE post-process...",rprint(self.voice_runs))
  
  self.low_column,self.high_column = xLib.get_table_bounds(self.voice_runs)

  -- post-process

  for col_idx,run_col in pairs(self.voice_runs) do
    --local initial_notecol,initial_line = xVoiceRunner.get_initial_notecol(self.voice_runs[col_idx])

    for run_idx,run in pairs(run_col) do
      prnt("*** collect - post-process: col_idx,run_idx",col_idx,run_idx)

      if run.__skip_template then
        --print(">>> template tells us to skip this run",col_idx,run_idx)
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
          local low_line,high_line = xLib.get_table_bounds(run)
          prnt(">>> low_line,high_line",low_line,high_line)
          if not (run.number_of_lines) then
            local voice = self.voice_columns[col_idx]
            if voice then -- still open

              local final_on,final_off,final_cut = xVoiceRunner.get_final_notecol_info(run,true,vol_visible,pan_visible)
              print("final_on,final_off,final_cut",final_on,final_off,final_cut)

              if not run.single_line_trigger
                and ((final_cut and self.stop_at_note_cut)
               or (final_off and self.stop_at_note_off))
              then
                run.number_of_lines = 1+selection.end_line-high_line
                prnt("collect - still open (ends on off) - high_line-low_line,#lines",high_line-low_line,run.number_of_lines)
              else
                -- extend to the selection boundary (actual length)
                local run_length = self:detect_run_length(ptrack_or_phrase,col_idx,high_line,num_lines,vol_visible,pan_visible)
                prnt("collect - still open (extended) - run_length",run_length)
                run.number_of_lines = high_line - low_line + run_length
                --run.open_ended = ((low_line + run.number_of_lines - 1) >= num_lines)
                run.open_ended = ((low_line + run.number_of_lines - 1) >= selection.end_line)
                prnt("collect - still open (extended) - #lines",run.number_of_lines)
                prnt("*** collect - low_line,num_lines",low_line,num_lines)
                prnt("*** collect - run.open_ended",run.open_ended)
              end

            else
              run.number_of_lines = high_line-low_line
              prnt("collect - voice terminated - #lines",run.number_of_lines)
            end
          else
            -- implied note-off
          end
        end
      end

    end
  end

  if self.compact_columns 
    and (collect_mode ~= xVoiceRunner.COLLECT_MODE.CURSOR)   
  then
    xLib.compact_table(self.voice_runs)
  end

  --prnt("*** sort - unique_notes",rprint(self.unique_notes))

end

-------------------------------------------------------------------------------
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
    local low_line_idx,_ = xLib.get_table_bounds(in_range[col_idx])
    return in_range[col_idx][low_line_idx]
  end

end

-------------------------------------------------------------------------------
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
    local low,high = xLib.get_table_bounds(in_range[col_idx])
    for k = high,low,-1 do
      if in_range[col_idx][k] then
        local low_line,high_line = xLib.get_table_bounds(in_range[col_idx][k])
        if (line_idx > low_line) then
          return in_range[col_idx][k]
        end
      end
    end
  end

  if self.wrap_around_jump then
    if self.voice_runs[col_idx] then
      local low,high = xLib.get_table_bounds(self.voice_runs[col_idx])
      return self.voice_runs[col_idx][high]
    end
  end

end

-------------------------------------------------------------------------------
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
  local in_range = xVoiceRunner.in_range(self.voice_runs,line_idx,patt.number_of_lines,{
    restrict_to_column = col_idx,
    include_before = true,
    include_after = true,
  })

  if in_range[col_idx] then
    local low,high = xLib.get_table_bounds(in_range[col_idx])
    for k = low,high do
      if in_range[col_idx][k] then
        local low_line,high_line = xLib.get_table_bounds(in_range[col_idx][k])
        if (line_idx < low_line) then
          return in_range[col_idx][k]
        end
      end
    end
    --return in_range[col_idx][low]
  end

  --print("self.wrap_around_jump",self.wrap_around_jump)
  if self.wrap_around_jump then
    if self.voice_runs[col_idx] then
      local low,high = xLib.get_table_bounds(self.voice_runs[col_idx])
      return self.voice_runs[col_idx][low]
    end
  end

end

-------------------------------------------------------------------------------
-- detect what action to take on a given note-column

function xVoiceRunner:detect_run_condition(notecol,col_idx,vol_visible,pan_visible)
  --print("xVoiceRunner:detect_run_condition(notecol,col_idx,vol_visible,pan_visible)",notecol,col_idx,vol_visible,pan_visible)

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
        --and not (line_idx == start_line))
        or (self.split_at_note_change
        and note_changed))
    then
      -- changed note
      --print("self.link_ghost_notes",self.link_ghost_notes)
      if self.link_ghost_notes 
        --and (instr_idx == xVoiceRunner.GHOST_NOTE)
        and not has_instr_val
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

-------------------------------------------------------------------------------
-- check when a voice-run ends by examining the pattern-track
-- @param ptrack_or_phrase, renoise.PatternTrack
-- @param col_idx (int)
-- @param start_line (int), the line where the voice got triggered
-- @param num_lines (int), iterate until this line
-- @return int, line index

function xVoiceRunner:detect_run_length(ptrack_or_phrase,col_idx,start_line,num_lines,vol_visible,pan_visible)
  print("xVoiceRunner:detect_run_length(ptrack_or_phrase,col_idx,start_line,num_lines,vol_visible,pan_visible)",ptrack_or_phrase,col_idx,start_line,num_lines,vol_visible,pan_visible)

  assert(type(ptrack_or_phrase)=="PatternTrack" or type(ptrack_or_phrase)=="InstrumentPhrase")
  assert(type(col_idx)=="number")
  assert(type(start_line)=="number")
  assert(type(num_lines)=="number")

  if (start_line > num_lines) then
    return 0
  end

  local line_rng = ptrack_or_phrase:lines_in_range(start_line,num_lines)
  for k,line in ipairs(line_rng) do
    local line_idx = k + start_line - 1
    if not line.is_empty then
      for notecol_idx,notecol in ipairs(line.note_columns) do
        if not notecol.is_empty 
          and (col_idx == notecol_idx)
        then
          print("*** detect_run_length - line,notecol",k,notecol)

          local run_condition = self:detect_run_condition(notecol,col_idx,vol_visible,pan_visible)
          print("run_condition",run_condition)
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
  
  print("*** detect_run_length - all the way...")
  return 1+num_lines-start_line

end


-------------------------------------------------------------------------------
-- get a specific note-column and its index
-- @param col_idx (int)
-- @param line_idx (int)
-- @return xNoteColumn or nil
-- @return int (run index) or nil

function xVoiceRunner:resolve_notecol(col_idx,line_idx)
  print("xVoiceRunner:resolve_notecol(col_idx,line_idx)",col_idx,line_idx)

  assert(type(col_idx)=="number")
  assert(type(line_idx)=="number")

  local run_idx = xVoiceRunner.get_most_recent_run_index(self.voice_runs[col_idx],line_idx)
  --print("*** resolve_notecol - run_idx",run_idx)
  if run_idx then
    local run = self.voice_runs[col_idx][run_idx]
    --print("*** resolve_notecol - self.voice_runs[col_idx]",rprint(self.voice_runs[col_idx]))
    --print("*** resolve_notecol - run",run)
    if run then
      return run[line_idx],run_idx
    end
  end

end

-------------------------------------------------------------------------------
-- look for previous notes which are equal or higher, insert in new column
-- testcases: Complex II 
-- return bool, true when shifting took place

function xVoiceRunner:shift_runs(voice,target_col_idx,line_idx,shift_upwards)
  print("xVoiceRunner:shift_runs(voice,target_col_idx,line_idx,shift_upwards)",voice,target_col_idx,line_idx,shift_upwards)

  assert(type(col_idx)=="number")

  --print(">>> shift_runs - voice...",rprint(voice))

  local assign_notecol = voice.voice_run[line_idx]
  local target_run_col = self.voice_runs[target_col_idx]
  local higher_runs = xVoiceRunner.get_higher_notes_in_column(self.voice_runs[target_col_idx],assign_notecol.note_value-1)
  --print(">>> shift_runs - higher_runs...",rprint(higher_runs))
  local insert_col_idx = nil
  local highest_run_idx = 1
  if not table.is_empty(higher_runs) then
    local higher_run = target_run_col[higher_runs[1].run_idx]
    --print(">>> shift - higher_run: ",higher_run)
    insert_col_idx = shift_upwards and target_col_idx+1 or target_col_idx
    highest_run_idx = 1
    --print(">>> shift higher run into new column - clear: ",target_col_idx,higher_runs[1].run_idx)
    --print(">>> shift higher run into new column - insert: ",insert_col_idx)
    if self:clear_in_column(target_col_idx,higher_runs[1].run_idx,line_idx) then
      if (target_col_idx < insert_col_idx) then
        insert_col_idx = insert_col_idx -1
        --print(">>> adjusted insert_col_idx",insert_col_idx)
      end
    end
    self:insert_voice_column(insert_col_idx,higher_run)
    if (insert_col_idx <= target_col_idx) then
      target_col_idx = target_col_idx+1
      --print(">>> adjusted target_col_idx",target_col_idx)
    end
    -- column is created, set remaining runs 
    for k = 2,#higher_runs do
      higher_run = target_run_col[higher_runs[k].run_idx]
      highest_run_idx = k
      --print(">>> shift higher run into new column - clear: ",target_col_idx,higher_runs[k].run_idx)
      --print(">>> shift higher run into new column - set: ",insert_col_idx,k,higher_run)
      --print(">>> shift higher run into new column - run: ",rprint(higher_run))
      table.insert(self.voice_runs[insert_col_idx],k,higher_run)
      self:clear_in_column(target_col_idx,higher_runs[k].run_idx,higher_runs[k].line_idx)
    end
    self:set_high_low_column(target_col_idx,nil,nil,nil,line_idx)
  end
  -- now bring our run into target column
  if insert_col_idx then
    local high_note,low_note = xVoiceRunner.get_high_low_note_values(self.voice_runs[insert_col_idx])
    --print("*** high_note,low_note",high_note,low_note)

    local assigned = false
    if (high_note == assign_notecol.note_value)
      and (low_note == assign_notecol.note_value)
    then
      -- prefer same notes in same column if possible
      --print(">>> shift_runs - shifted notes are strictly equal, attempt to assign")
      assigned = self:assign_if_room(voice,insert_col_idx,line_idx,highest_run_idx+1)
    end
    if not assigned then
      --print(">>> shift_runs - shifted column not same note, or no room - attempt assign")
      assigned = self:assign_if_room(voice,target_col_idx,line_idx) 
    end
    if not assigned then
      --print(">>> shift_runs, try shifted/inserted column (perhaps for the 2nd time)")
      assigned = self:assign_if_room(voice,insert_col_idx,line_idx,highest_run_idx+1)
    end
    if not assigned then
      --print(">>> no room found anywhere, insert between inserted and target")
      self:insert_voice_column(insert_col_idx,voice.voice_run)
    end

    return true

  end 
end

-------------------------------------------------------------------------------
-- replace run in target column 
-- if begin on this line and has a different note value, or smaller range
-- return bool, true when replace took place

function xVoiceRunner:replace_run(voice,target_col_idx,target_run_idx,notecol,line_idx)
  print("xVoiceRunner:replace_run(voice,target_col_idx,target_run_idx,notecol,line_idx)",voice,target_col_idx,target_run_idx,notecol,line_idx)
  --print("voice",rprint(voice))

  local target_run_col = self.voice_runs[target_col_idx]
  local target_notecol = voice.voice_run[line_idx]

  local replaceable = true
  if target_run_idx then
    local target_run = target_run_col[target_run_idx]
    local start_line,end_line = xLib.get_table_bounds(target_run)
    if (start_line ~= line_idx) then
      replaceable = false
      --print(">>> not replaceable, no run on this line")
    end
    --print("*** replace_run - notecol.note_value",notecol.note_value)
    if (notecol.note_value == target_notecol.note_value) then
      replaceable = false
      --print(">>> replace_run - not replaceable, source and target note is the same")
    end
  else
    for k2,v2 in pairs(in_range[target_col_idx]) do
      if (v2.number_of_lines > voice.voice_run.number_of_lines) then
        replaceable = false
        --print(">>> replace_run - not replaceable, entry cover a greater range than ours...")
        break
      end
    end
  end
  if replaceable then
    --print(">>> replace_run - replaceable - clear:",voice.col_idx,voice.run_idx,"set:",target_col_idx,target_run_idx,voice.voice_run)
    target_run_col[target_run_idx] = voice.voice_run
    target_run_col[target_run_idx].__replaced = true -- avoid clearing when replaced entry is processed
    self:clear_in_column(voice.col_idx,voice.run_idx,line_idx)
    return true
  end

end

-------------------------------------------------------------------------------
-- @return bool, true when there was room

function xVoiceRunner:assign_if_room(voice,col_idx,line_idx,assign_run_idx)
  print("xVoiceRunner:assign_if_room(voice,col_idx,line_idx,assign_run_idx)",voice,col_idx,line_idx,assign_run_idx)

  local has_room,in_range = self:has_room(line_idx,col_idx,voice.voice_run.number_of_lines)
  --print(">>> assign_if_room - has_room",has_room)
  if has_room then
    --print(">>> clear:",voice.col_idx,voice.run_idx,assign_run_idx)
    --print(">>> set:",col_idx,assign_run_idx,voice.voice_run)
    -- TODO ensure col_idx is kept in sync (see xVoiceSorter:insert_or_assign)
    self:clear_in_column(voice.col_idx,voice.run_idx,line_idx)
    if assign_run_idx then
      if self.voice_runs[col_idx][assign_run_idx] then
        --print("*** assigning where a run already exists",col_idx,assign_run_idx)
        error("...")
      end
      table.insert(self.voice_runs[col_idx],assign_run_idx,voice.voice_run)
    else
      table.insert(self.voice_runs[col_idx],voice.voice_run)
    end
    --local high_note,low_note = xVoiceRunner.get_high_low_note_values(self.voice_runs[col_idx],start_line,line_idx)
    self:set_high_low_column(col_idx,nil,nil,nil,line_idx)
    return true
  end
end

-------------------------------------------------------------------------------
-- clear a voice-run from a column + remove column if empty
-- @return bool, true when column was removed as well

function xVoiceRunner:clear_in_column(col_idx,run_idx,line_idx,leave_column) 
  print("xVoiceRunner:clear_in_column(col_idx,run_idx,line_idx,leave_column)",col_idx,run_idx,line_idx,leave_column)

  local run_col = self.voice_runs[col_idx]
  if not run_col[run_idx] then
    --print("*** clear_in_column - voice-run not found")
    return
  end

  if not run_col[run_idx].__replaced then
    --print("run_col PRE...",rprint(run_col))
    --print("*** clear_in_column - run indices",rprint(table.keys(run_col)))
    run_col[run_idx] = nil
    if table.is_empty(run_col) and not leave_column then
      self:remove_voice_column(col_idx)
    else
      -- update high/low from prior lines
      self:set_high_low_column(col_idx,nil,nil,nil,line_idx)
    end
  else
    print("*** clear_in_column - this voice-run was __replaced (protected from being cleared)")
  end

end

-------------------------------------------------------------------------------
-- TODO implement as 'naive' xTrack method, using selection-based approach (start_column,end_column)
-- merge columns: preserve note-offs from both columns 
-- (source takes precedence when both exist)
-- @param source_col_idx (int)
-- @param target_col_idx (int)

--[[
function xVoiceRunner:merge_columns(source_col_idx,target_col_idx)
  print("xVoiceRunner:merge_columns(source_col_idx,target_col_idx)",source_col_idx,target_col_idx)

  local source_col = self.voice_runs[source_col_idx]
  local target_col = self.voice_runs[target_col_idx]

  assert(type(source_col)=="table")
  assert(type(target_col)=="table")

  ----print("*** merge_columns - source_col PRE",rprint(source_col))
  --print("*** merge_columns - target_col PRE",rprint(target_col))

  for src_run_idx,src_run in pairs(source_col) do    
    --print("*** merge_columns - src_run_idx,src_run",src_run_idx,src_run)
    local src_low_line,src_high_line = xLib.get_table_bounds(src_run)
    local has_room,in_range = self:has_room(src_low_line,target_col_idx,src_run.number_of_lines) 
    --print("*** merge_columns - has_room,in_range",has_room,in_range)
    if not has_room then
      -- shorten or remove the runs in this range
      --print("*** merge_columns - in_range...",rprint(in_range))
      local first_tgt_run_idx,last_run_idx = xLib.get_table_bounds(in_range[target_col_idx])
      --print("*** merge_columns - first_tgt_run_idx",first_tgt_run_idx)
      local first_tgt_run_line_idx,__ = xLib.get_table_bounds(in_range[target_col_idx][first_tgt_run_idx])
      --print("*** merge_columns - first_tgt_run_line_idx,src_low_line",first_tgt_run_line_idx,src_low_line)
      -- if the first run ...
      if (first_tgt_run_line_idx < src_low_line) then
        --print(">>> merge_columns - first target run starts before our line: shorten")
        --print("*** merge_columns - first_tgt_run_line_idx,src_low_line",first_tgt_run_line_idx,src_low_line)
        self.voice_runs[target_col_idx][first_tgt_run_idx].number_of_lines = 
          src_low_line-first_tgt_run_line_idx
      elseif (first_tgt_run_line_idx == src_low_line) then
        --print(">>> merge_columns - first run starts on line: remove")
        self.voice_runs[target_col_idx][first_tgt_run_idx] = nil
      end
      -- included (if only partially) - remove trailing lines
      if self.voice_runs[target_col_idx][first_tgt_run_idx] then
        for tgt_line_idx,tgt_notecol in pairs(self.voice_runs[target_col_idx][first_tgt_run_idx]) do
          if (type(tgt_notecol)=="table") then 
            if (tgt_line_idx >= src_low_line) then
              self.voice_runs[target_col_idx][first_tgt_run_idx][tgt_line_idx] = nil
              --print(">>> merge_columns - removed trailing target run on line",tgt_line_idx)
            end
          end
        end
      end
    end

    local recent_run_idx = xVoiceRunner.get_most_recent_run_index(target_col,src_low_line)
    --print("*** merge_columns - recent_run_idx",recent_run_idx)
    if recent_run_idx then
      table.insert(self.voice_runs[target_col_idx],recent_run_idx+1,src_run)
    end

  end

  self:remove_voice_column(source_col_idx)

  --print("*** merge_columns - target_col POST",rprint(target_col))
  error("...")

end
]]

-------------------------------------------------------------------------------
-- maintain high/low note-values in column
-- @param col_idx (int)
-- @param high_note (int)
-- @param low_note (int)
-- @param force (bool), if defined the high/low values are explicitly set 
--  (otherwise they will expand the already existing range)
-- @param line_idx (int), set to high/low of existing runs until this line

function xVoiceRunner:set_high_low_column(col_idx,high_note,low_note,force,line_idx)
  TRACE("xVoiceRunner:set_high_low_column(col_idx,high_note,low_note,force,line_idx)",col_idx,high_note,low_note,force,line_idx)

  assert(type(col_idx)=="number")

  if line_idx then
    local run_col = self.voice_runs[col_idx]
    local start_line,end_line = xVoiceRunner.get_column_start_end_line(run_col)
    --print("*** set_high_low_column - start_line,end_line,line_idx",start_line,end_line,line_idx)
    if start_line and (start_line < line_idx) then
      local high_note,low_note = xVoiceRunner.get_high_low_note_values(run_col,start_line,line_idx)
      --print("*** set_high_low_column - refresh low/high note",low_note,high_note)
      self:set_high_low_column(col_idx,high_note,low_note,true)
    else
      --print("*** set_high_low_column - clear low/high notes",start_line,line_idx)
      self:set_high_low_column(col_idx,nil,nil,true)
    end
    return
  end

  local t,k = self:get_high_low_column(col_idx)
  if t then
    --print("*** set_high_low_column - updating existing entry")
  
    if force then
      self.high_low_columns[k].high_note = high_note
      self.high_low_columns[k].low_note = low_note
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
    --print("*** set_high_low_column - inserting new entry")
    table.insert(self.high_low_columns,{
      column_index = col_idx,
      low_note = low_note,
      high_note = high_note,
    })
  end

  table.sort(self.high_low_columns,function(e1,e2)
    return e1.column_index < e2.column_index
  end)

  --print("*** set_high_low_column...",rprint(self.high_low_columns))

end

-------------------------------------------------------------------------------

function xVoiceRunner:get_high_low_column(col_idx)
  TRACE("xVoiceRunner:get_high_low_column(col_idx)",col_idx)

  for k,v in ipairs(self.high_low_columns) do
    if (v.column_index == col_idx) then
      return v,k
    end
  end

end

-------------------------------------------------------------------------------
-- write the current voice-runs to the provided pattern-track
-- @param ptrack_or_phrase (renoise.PatternTrack or renoise.InstrumentPhrase)
-- @param selection (table)
-- @param trk_idx (int)

function xVoiceRunner:write(ptrack_or_phrase,selection,trk_idx)
  TRACE("xVoiceRunner:write(ptrack_or_phrase,selection,trk_idx)",ptrack_or_phrase,selection,trk_idx)

  assert(type(ptrack_or_phrase)=="PatternTrack" or type(ptrack_or_phrase)=="InstrumentPhrase")

  local writing_to_pattern = (type(ptrack_or_phrase)=="PatternTrack")

  local vol_visible,pan_visible,dly_visible
  if writing_to_pattern then
    local track = rns.tracks[trk_idx]
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
    --print("k,line",k,line)
    local line_idx = k + selection.start_line - 1
    --print("*** line_idx",line_idx,selection.end_line)

    for col_idx,run_col in pairs(self.voice_runs) do

      local within_range = (col_idx >= selection.start_column)
        and (col_idx < selection.end_column)

      if within_range then
        local notecol = line.note_columns[col_idx]
        notecol:clear()
        for run_idx,run in pairs(run_col) do
          if run[line_idx] then
            local low,high = xLib.get_table_bounds(run)
            local xnotecol = xNoteColumn(run[line_idx])
            --print("xnotecol",xnotecol)
            xnotecol:do_write(notecol)
            if self.create_noteoffs then
              scheduled_noteoffs[col_idx] = {
                line_index = low+run.number_of_lines,
                run_index = run_idx,
              }
            end
            open_ended[col_idx] = run.open_ended 
            --print("open_ended[",col_idx,"]",rprint(open_ended))

            --print("col_idx,run_idx,scheduled_noteoffs[col_idx]",col_idx,run_idx,scheduled_noteoffs[col_idx])
          elseif scheduled_noteoffs[col_idx]
            and (scheduled_noteoffs[col_idx].line_index == line_idx)
            and (scheduled_noteoffs[col_idx].run_index == run_idx)
          then
            --print("write scheduled noteoff - line_idx,col_idx,run_idx",line_idx,col_idx,run_idx)
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
              xVoiceRunner.terminate_note(notecol,self.reveal_subcolumns,vol_visible,pan_visible,dly_visible)
            end
          end
        end
      end -- /within range

    end

  end

  local low_col,high_col = xLib.get_table_bounds(self.voice_runs)

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
  local line_rng = ptrack_or_phrase:lines_in_range(selection.start_line,selection.end_line)
  for k,line in ipairs(line_rng) do
    local line_idx = k + selection.start_line - 1
    for col_idx = self.high_column,high_col+1,-1 do
      print("clear leftover column",line_idx,col_idx)
      local notecol = line.note_columns[col_idx]
      notecol:clear()
    end
  end

end


-------------------------------------------------------------------------------
-- Static Methods
-------------------------------------------------------------------------------
-- @return table, pattern selection spanning the provided voice-run

function xVoiceRunner.get_voice_run_selection(vrun,trk_idx,col_idx)
  TRACE("xVoiceRunner.get_voice_run_selection(vrun,trk_idx,col_idx)",vrun,trk_idx,col_idx)

  local low,high = xLib.get_table_bounds(vrun)
  local end_line = low + vrun.number_of_lines - 1
  end_line = ((vrun.implied_noteoff and not vrun.actual_noteoff_col)
      or vrun.open_ended  
      or not vrun.actual_noteoff_col
      or vrun.single_line_trigger) and end_line 
    or end_line+1
  return {
    start_line = low,
    start_track = trk_idx,
    start_column = col_idx,
    end_line = end_line,
    end_track = trk_idx,
    end_column = col_idx,
  }

end

-------------------------------------------------------------------------------
-- figure out if a given range contains any voice-runs
-- @param line_start (int)
-- @param col_idx (int)
-- @param num_lines (int)
-- @return bool, true when no runs
-- @return table, voice-runs in range

function xVoiceRunner.has_room(voice_runs,line_start,col_idx,num_lines)
  print("xVoiceRunner:has_room(voice_runs,line_start,col_idx,num_lines)",voice_runs,line_start,col_idx,num_lines)

  assert(type(line_start)=="number")
  assert(type(col_idx)=="number")
  assert(type(num_lines)=="number")

  local line_end = line_start + num_lines -1
  local in_range = xVoiceRunner.in_range(voice_runs,line_start,line_end,{
    restrict_to_column = col_idx,
    include_before = true,
    include_after = true,
  })
  --print("*** has_room - in_range",line_start,line_end,rprint(in_range))
  local has_room = (#table.keys(in_range) == 0)
  --print("*** has_room",has_room,"line_start,line_end",line_start,line_end,"col_idx",col_idx)
  return has_room,in_range

end

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
  --print("xVoiceRunner.in_range(voice_runs,line_start,line_end,args)",voice_runs,line_start,line_end,args)
  --rprint(args)

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
  --print("exclude_columns",rprint(exclude_columns))

  local do_include_run = function(col_idx,run_idx)
    --print("*** in range - include run - col_idx,run_idx",col_idx,run_idx)
    xLib.expand_table(rslt,col_idx)
    rslt[col_idx][run_idx] = voice_runs[col_idx][run_idx]
    matched_columns[col_idx] = true 
  end

  -- first, look for runs that start on the line
  for line_idx = line_start,line_end do
    --print("line_idx",line_idx)

    for col_idx,run_col in pairs(voice_runs) do
      --print("*** in_range - col_idx,run_col",col_idx,run_col)

      if exclude_columns[col_idx] then
        --print("*** in_range - skip column",col_idx)
      else 
        for run_idx,v3 in pairs(run_col) do
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
    --print("*** in_range/include_before - matched_columns",rprint(matched_columns))
    for col_idx,run_col in pairs(voice_runs) do
      -- examine non-triggered/excluded lines only...
      if exclude_columns[col_idx] 
        or matched_columns[col_idx]
      then
        --print("*** in_range/include_before - skip column",col_idx)
      else
        local prev_run_idx = xVoiceRunner.get_open_run(run_col,line_start) 
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
-- collect runs that begin on a specific line 
-- @param line_idx (int)
-- @return table 

function xVoiceRunner.get_runs_on_line(voice_runs,line_idx)
  TRACE("xVoiceRunner.get_runs_on_line(voice_runs,line_idx)",voice_runs,line_idx)

  local line_runs = {}
  for col_idx,run_col in pairs(voice_runs) do
    for run_idx,run in pairs(run_col) do
      local low_line,high_line = xLib.get_table_bounds(run)
      if (low_line == line_idx) then
        local voice = xVoiceRunner.create_voice(run,col_idx,run_idx,low_line)
        table.insert(line_runs,voice) 
      end
    end
  end

  return line_runs

end

-------------------------------------------------------------------------------
-- create a voice table (to ensure correct variable types...)
-- @return table

function xVoiceRunner.create_voice(voice_run,col_idx,run_idx,line_idx)

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

-------------------------------------------------------------------------------
-- Voice-run methods
-------------------------------------------------------------------------------
-- @param voice_run, table
-- @return int, note value or nil
-- @return int, line index

function xVoiceRunner.get_initial_notecol(voice_run)
  TRACE("xVoiceRunner.get_initial_notecol(voice_run)",voice_run)

  local low_line,high_line = xLib.get_table_bounds(voice_run)
  return voice_run[low_line],low_line

end

-------------------------------------------------------------------------------
-- Voice-run (column methods)
-------------------------------------------------------------------------------
-- retrieve the previous run if it overlaps with the provided line
-- @param run_col (table)
-- @param line_start (int)
-- @return int or nil

function xVoiceRunner.get_open_run(run_col,line_start)
  TRACE("xVoiceRunner.get_open_run(run_col,line_start)",run_col,line_start)

  local matched = false
  for run_idx,run in pairs(run_col) do
    --print("get_open_run - run",rprint(run))
    local low,high = xLib.get_table_bounds(run)
    local end_line = low+run.number_of_lines-1
    if (low < line_start) and (end_line >= line_start) then
      return run_idx
    end
  end

end

-------------------------------------------------------------------------------
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
      local low_line,high_line = xLib.get_table_bounds(voice_run)
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

-------------------------------------------------------------------------------
-- find the index of the most recent run at the provided line
-- @param run_col (table)
-- @param line_idx (int)
-- @return int or nil

function xVoiceRunner.get_most_recent_run_index(run_col,line_idx)
  print("xVoiceRunner.get_most_recent_run_index(run_col,line_idx)",run_col,line_idx)

  assert(type(run_col)=="table")
  assert(type(line_idx)=="number")

  local most_recent = nil
  local is_empty = table.is_empty(run_col)
  if not is_empty then
    for run_idx,run in pairs(run_col) do
      local low,high = xLib.get_table_bounds(run)
      --print("*** get_most_recent_run_index - low,high",low,high)
      if high then
        for k = 1,math.min(line_idx,high) do
          --print("*** get_most_recent_run_index - k",k)
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

-------------------------------------------------------------------------------
-- check the lowest/highest note-values for a given column
-- @param run_col (table), required
-- @param line_start (int)
-- @param line_end (int) 
-- @return int, low note-value or nil
-- @return int, high note-value or nil

function xVoiceRunner.get_high_low_note_values(run_col,line_start,line_end)
  TRACE("xVoiceRunner.get_high_low_note_values(run_col,line_start,line_end)",run_col,line_start,line_end)

  assert(type(run_col)=="table")

  --print("*** get_high_low_note_values - run_col...",rprint(run_col))
  local restrict_to_lines = (line_start and line_end) and true or false
  local low_note,high_note = 1000,-1000
  local matched = false
  local within_range = false
  for run_idx,run in pairs(run_col) do
    --print("*** get_high_low_note_values - run_idx,run...",run_idx,rprint(run))
    for line_idx,v3 in pairs(run) do
      --print("*** get_high_low_note_values - restrict_to_lines,line_idx,line_start,line_end",restrict_to_lines,line_idx,line_start,line_end)
      if (type(v3)=="table") then 
        within_range = (restrict_to_lines 
          and (line_idx >= line_start)
          and (line_idx <= line_end)) 
        if (v3.note_value < renoise.PatternLine.NOTE_OFF)
          and not restrict_to_lines 
            or (restrict_to_lines and within_range)
        then
          --print("*** get_high_low_note_values - line_idx,note_val",line_idx,xNoteColumn.note_value_to_string(v3.note_value))
          low_note = math.min(low_note,v3.note_value)
          high_note = math.max(high_note,v3.note_value)
          matched = true
        end
      end
    end
    if matched and not within_range then
      --print("break")
      break
    end    
  end

  if matched then
    return high_note,low_note
  end

end

-------------------------------------------------------------------------------
-- retrieve the first and last line in column

function xVoiceRunner.get_column_start_end_line(run_col)
  TRACE("xVoiceRunner.get_column_start_end_line(run_col)",run_col)

  if table.is_empty(table.keys(run_col)) then
    --print("*** get_column_start_end_line - no runs",rprint(run_col))
    return
  end

  local start_line,end_line = 513,0
  for run_idx,run in pairs(run_col) do
    local high,low = xLib.get_table_bounds(run_col[run_idx])
    end_line = math.max(end_line,high) 
    start_line = math.min(start_line,low) 
  end

  return start_line,end_line

end

-------------------------------------------------------------------------------
-- @param voice_run, table
-- @return vararg - see xVoiceRunner.get_notecol_info()

function xVoiceRunner.get_final_notecol_info(voice_run,respect_visibility,vol_visible,pan_visible)
  TRACE("xVoiceRunner.get_final_notecol_info(voice_run,respect_visibility,vol_visible,pan_visible)",voice_run,respect_visibility,vol_visible,pan_visible)

  local low,high = xLib.get_table_bounds(voice_run)
  return xVoiceRunner.get_notecol_info(voice_run[high],respect_visibility,vol_visible,pan_visible)

end

-------------------------------------------------------------------------------
-- obtain a bunch of useful info about a note-column
-- @param notecol (renoise.NoteColumn or xNoteColumn)
-- @param vol_visible (bool)
-- @param pan_visible (bool)
-- @param respect_visibility (bool)

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

-------------------------------------------------------------------------------
-- terminate the note by whichever means

function xVoiceRunner.terminate_note(notecol,reveal_subcolumns,vol_visible,pan_visible,dly_visible)
  print("xVoiceRunner.terminate_note(notecol,reveal_subcolumns,vol_visible,pan_visible,dly_visible)",notecol,reveal_subcolumns,vol_visible,pan_visible,dly_visible)

  --local track = rns.tracks[track_idx]
  local max_tick = rns.transport.tpl-1 -- TODO fixed amount in phrases
  local str_note_cut = ("C%X"):format(max_tick)

  local has_note_on,has_note_off,has_note_cut = 
    xVoiceRunner.get_notecol_info(notecol,true,vol_visible,pan_visible)

  if has_note_off or has_note_cut then
    --print("*** terminate_note - do nothing (already terminated)")
  elseif has_note_on then
    if (notecol.panning_value == 255) 
    then      
      --print("*** terminate_note - terminate using note_cut in panning column")
      notecol.panning_string = str_note_cut
      if reveal_subcolumns then pan_visible = true end

    elseif (notecol.volume_value == 255) 
    then
      --print("*** terminate_note - terminate using note_cut in volume column")
      notecol.volume_string = str_note_cut
      if reveal_subcolumns then vol_visible = true end
    end
  else
    --print("*** terminate_note - terminate using note-off with delay")
    notecol.note_value = renoise.PatternLine.NOTE_OFF
    notecol.delay_value = 255
    if reveal_subcolumns then dly_visible = true end
  end

end

