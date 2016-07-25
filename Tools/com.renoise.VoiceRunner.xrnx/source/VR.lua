--[[============================================================================
VoiceRunner
============================================================================]]--
--[[

VoiceRunner application
.
#

An implementation of the xVoiceSorter class

]]

class 'VR'

--------------------------------------------------------------------------------

VR.SCOPES = {
  "Selection in Pattern",
  --"Selection in Matrix",
  "Track in Pattern",
  --"Track in Song",
  "Group in Pattern",
  --"Group in Song",
  "Whole Pattern",
  --"Whole Song",
}

VR.SCOPE = {
  SELECTION_IN_PATTERN = 1,
  --SELECTION_IN_MATRIX = 2,
  TRACK_IN_PATTERN = 3,
  --TRACK_IN_SONG = 4,
  GROUP_IN_PATTERN = 5,
  --GROUP_IN_SONG = 6,
  WHOLE_PATTERN = 7,
  --WHOLE_SONG = 8,
}


--------------------------------------------------------------------------------

function VR:__init(...)

  local args = xLib.unpack_args(...)

  --- VR_Prefs, current settings
  self.prefs = renoise.tool().preferences

  --- string
  self.app_display_name = args.app_display_name

  --- when running tool, this is what we process
  -- table, [seq_idx][track_idx] = {xPatternTrack,xPatternTrack,...}
  self.pattern_tracks = {}

  --- VR_Template
  self.template = VR_Template()

  -- xVoiceRunner
  self.runner = xVoiceRunner{
    split_at_note = args.split_at_note,
    --split_at_instrument = args.split_at_instrument,
    stop_at_note_off = args.stop_at_note_off,
  }

  --- xVoiceSorter
  self.xsorter = xVoiceSorter{
    sort_mode = self.prefs.sort_mode.value,
    runner = self.runner,
  }
  --- configure user-interface
  self.ui = VR_UI{
    dialog_title = self.app_display_name,
    owner = self,
    waiting_to_show_dialog = self.prefs.autostart.value,
  }

  -- notifications --

  renoise.tool().app_idle_observable:add_notifier(function()
    -- 
  end)

  renoise.tool().app_new_document_observable:add_notifier(function()
    rns = renoise.song()
    self:attach_to_song()
  end)

  renoise.tool().app_release_document_observable:add_notifier(function()
    self:detach_from_song()
  end)

  self.prefs.sort_mode:add_notifier(function()
    --print("self.prefs.sort_mode fired...",self.prefs.sort_mode.value)
    self.xsorter.sort_mode = self.prefs.sort_mode.value
  end)

  --[[

  self.prefs.compact_mode:add_notifier(function()
    --print("self.prefs.compact_mode fired...",self.prefs.compact_mode.value)
    self.xsorter.compact_mode = self.prefs.compact_mode.value
  end)

  self.prefs.split_at_instrument:add_notifier(function()
    --print("self.prefs.split_at_instrument fired...",self.prefs.split_at_instrument.value)
    self.runner.split_at_instrument = self.prefs.split_at_instrument.value
  end)

  ]]

  self.prefs.split_at_note:add_notifier(function()
    --print("self.prefs.split_at_note fired...",self.prefs.split_at_note.value)
    self.runner.split_at_note = self.prefs.split_at_note.value
  end)

  self.prefs.stop_at_note_off:add_notifier(function()
    --print("self.prefs.stop_at_note_off fired...",self.prefs.stop_at_note_off.value)
    self.runner.stop_at_note_off = self.prefs.stop_at_note_off.value
  end)


  -- initialize --

  self.template.vb = self.ui.vb
  self.ui:build()

  --self.template:load(self.prefs.selected_template.value)

  self:attach_to_song()

end

--------------------------------------------------------------------------------
-- handlers
--------------------------------------------------------------------------------

function VR:attach_to_song()

end


--------------------------------------------------------------------------------

function VR:detach_from_song()

end

--------------------------------------------------------------------------------
-- Sorting
--------------------------------------------------------------------------------
-- invoked through the 'process' button/shortcuts
-- @param scope (SCOPE), defined when invoked via shortcut

function VR:process(scope)
  TRACE("VR:process(scope)",scope)

  if not scope then
    scope = self.prefs.selected_scope.value
  end

  self.runner:reset()

  if (scope == VR.SCOPE.SELECTION_IN_PATTERN) then
    self:process_pattern_selection()
  --elseif (scope == VR.SCOPE.SELECTION_IN_MATRIX) then
    --self:process_matrix_selection()
  elseif (scope == VR.SCOPE.TRACK_IN_PATTERN) then
    self:process_track_in_pattern()
  --elseif (scope == VR.SCOPE.TRACK_IN_SONG) then
    --self:process_track_in_song()
  elseif (scope == VR.SCOPE.GROUP_IN_PATTERN) then
    self:process_group_in_pattern()
  --elseif (scope == VR.SCOPE.GROUP_IN_SONG) then
    --self:process_group_in_song()
  elseif (scope == VR.SCOPE.WHOLE_PATTERN) then
    self:process_whole_pattern()
  --elseif (scope == VR.SCOPE.WHOLE_SONG) then
    --self:process_whole_song()
  else
    error("Unexpected scope")
  end

  -- post-process / finalize

end

--------------------------------------------------------------------------------

function VR:process_pattern_selection()
  TRACE("VR:process_pattern_selection()")

  local patt_sel = rns.selection_in_pattern
  local seq_idx = rns.selected_sequence_index

  self:do_process(nil,nil,patt_sel)

end

--------------------------------------------------------------------------------
  --[[

function VR:process_matrix_selection()
  TRACE("VR:process_matrix_selection()")

  local matrix_sel,err = xSelection.get_matrix_selection()
  if table.is_empty(matrix_sel) then
    return false,"No selection is defined in the matrix"
  end

  -- TODO

  for seq_idx = 1, #rns.sequencer.pattern_sequence do
    if matrix_sel[seq_idx] then
      for trk_idx = 1, #rns.tracks do
        if matrix_sel[seq_idx][trk_idx] then
          self:do_process(seq_idx,trk_idx)
        end
      end
      -- display progress
      if (options.process_slice_mode.value ~= SLICE_MODE.NONE) then
        progress_handler(("Collecting phrases : sequence index = %d"):format(seq_idx))
        coroutine.yield()
      end
    end
  end

end
--------------------------------------------------------------------------------

function VR:process_track_in_song()
  TRACE("VR:process_track_in_song()")

  -- TODO

end

--------------------------------------------------------------------------------

function VR:process_group_in_song()
  TRACE("VR:process_group_in_song()")

  -- TODO

end

--------------------------------------------------------------------------------

function VR:process_whole_song()
  TRACE("VR:process_whole_song()")

  -- TODO

end

--------------------------------------------------------------------------------

  ]]


function VR:process_track_in_pattern()
  TRACE("VR:process_track_in_pattern()")

  local trk_idx = rns.selected_track_index
  local seq_idx = rns.selected_sequence_index
  self:do_process(seq_idx,trk_idx)

end

--------------------------------------------------------------------------------

function VR:process_group_in_pattern()
  TRACE("VR:process_group_in_pattern()")

  -- TODO

end

--------------------------------------------------------------------------------

function VR:process_whole_pattern()
  TRACE("VR:process_whole_pattern()")

end

--------------------------------------------------------------------------------
-- process (sort) pattern-track 
-- @param seq_idx, int (if not provided, use selected)
-- @param trk_idx, int (if not provided, use selected)
-- @param patt_sel, table (only when SELECTION_IN_PATTERN)

function VR:do_process(seq_idx,trk_idx,patt_sel)
  TRACE("VR:do_process(seq_idx,trk_idx,patt_sel)",seq_idx,trk_idx,patt_sel)

  if not seq_idx then
    seq_idx = rns.selected_sequence_index
  end
  --print("*** do_process - seq_idx",seq_idx)

  if not trk_idx then
    trk_idx = rns.selected_track_index
  end
  --print("*** do_process - trk_idx",trk_idx)

  if not patt_sel then
    patt_sel = xSelection.get_pattern_track(seq_idx,trk_idx)
  end
  --print("*** do_process - patt_sel",rprint(patt_sel))

  local patt_idx = rns.sequencer:pattern(seq_idx)
  local patt = rns.patterns[patt_idx]
  if not patt then
    return false,"Unable to process: couldn't locate pattern"
  end
  local ptrack = patt.tracks[trk_idx]
  if not ptrack then
    return false,"Unable to process: couldn't locate pattern-track"
  end
  --local sort_mode = self.prefs.sort_mode.value
  local rslt,err = self.xsorter:sort(ptrack,trk_idx,seq_idx,patt_sel)
  --print("*** do_process - rslt,err",rslt,err)

  --xVoiceSorter.detect_end_of_run(v2,low,patt.number_of_lines)


end


--------------------------------------------------------------------------------
-- select the voice-run below the cursor position

function VR:select_voice_run()
  TRACE("VR:select_voice_run()")

  local patt_sel = self.runner:select_voice_run()
  --print("patt_sel",rprint(patt_sel))

  if not table.is_empty(patt_sel) then
    rns.selection_in_pattern = patt_sel
  end

end

--------------------------------------------------------------------------------
-- for testing...

function VR:test_list_info()
  TRACE("VR:test_list_info()")

  local patt_sel = rns.selection_in_pattern
  if not patt_sel then
    print("*** No selection in pattern")
    return false
  end

  local ptrack = rns.selected_pattern_track
  local trk_idx = rns.selected_track_index
  local seq_idx = rns.selected_sequence_index
  local line_start = patt_sel.start_line
  local line_end = patt_sel.end_line
  local col_idx = patt_sel.start_column

  self.runner:reset()
  self.runner:collect_from_pattern(ptrack,xVoiceRunner.COLLECT_MODE.SELECTION,trk_idx,seq_idx,patt_sel)
  --print(">>> voice_runs",rprint(self.runner.voice_runs))

  if self.runner.voice_runs[col_idx] then
    local low_note,high_note = 
      xVoiceRunner.get_low_high_note_values(self.runner.voice_runs[col_idx],line_start,line_end)
    --print(">>> low_note,high_note",low_note,high_note)
  end

  local within_range,matched_columns = xVoiceRunner.in_range(self.runner.voice_runs,line_start,line_end,{
    --exclude_column = args.exclude_column,
    --restrict_to_column = col_idx,
    include_before = true,
    include_after = false,  
  })
  --print(">>> within_range",rprint(within_range))
  --print(">>> matched_columns",rprint(matched_columns))

end

