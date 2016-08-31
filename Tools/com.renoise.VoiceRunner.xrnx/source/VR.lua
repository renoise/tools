--[[============================================================================
VoiceRunner
============================================================================]]--
--[[

VoiceRunner application
.
#

]]

class 'VR'

--------------------------------------------------------------------------------

VR.SCOPES = {
  "Selection in Pattern",
  "Selection in Phrase",
  "Column in Pattern",
  --"Column in Phrase",
  "Track in Pattern",
  "Group in Pattern",
  "Whole Pattern",
  "Whole Phrase",
  --"Selection in Matrix",
  --"Track in Song",
  --"Group in Song",
  --"Whole Song",
}

VR.SCOPE = {
  SELECTION_IN_PATTERN = 1,
  SELECTION_IN_PHRASE = 2,
  COLUMN_IN_PATTERN = 3,
  --COLUMN_IN_PHRASE = 4,
  TRACK_IN_PATTERN = 4,
  GROUP_IN_PATTERN = 5,
  WHOLE_PATTERN = 6,
  WHOLE_PHRASE = 7,
  --SELECTION_IN_MATRIX,
  --TRACK_IN_SONG,
  --GROUP_IN_SONG,
  --WHOLE_SONG,
}

VR.MSG_FROM_VOICE_RUNNER = "Message from VoiceRunner: "
VR.MSG_NO_RUN_AVAILABLE = "Not able to select voice-run (N/A)"

VR.MIDI_MAPPING = {
  SELECT_RUN = "Tools:VoiceRunner:Select at cursor position (Pattern) [Trigger]",
  SELECT_NEXT_RUN = "Tools:VoiceRunner:Jump to next voice-run (Pattern) [Trigger]",
  SELECT_PREV_RUN = "Tools:VoiceRunner:Jump to previous voice-run (Pattern) [Trigger]",
  SELECT_NEXT_NOTECOL = "Tools:VoiceRunner:Jump to next note-column (Pattern) [Trigger]",
  SELECT_PREV_NOTECOL = "Tools:VoiceRunner:Jump to previous note-column (Pattern) [Trigger]",
  SORT_NOTES = "Tools:VoiceRunner:Sort Notes [Trigger]",
  SORT_SELECTION_IN_PATTERN = "Tools:VoiceRunner:Sort Notes (Selection in Pattern) [Trigger]",
  SORT_SELECTION_IN_PHRASE = "Tools:VoiceRunner:Sort Notes (Selection in Phrase) [Trigger]",
  SORT_COLUMN_IN_PATTERN = "Tools:VoiceRunner:Sort Notes (Column in Pattern) [Trigger]",
  SORT_TRACK_IN_PATTERN = "Tools:VoiceRunner:Sort Notes (Track in Pattern) [Trigger]",
  SORT_GROUP_IN_PATTERN = "Tools:VoiceRunner:Sort Notes (Group in Pattern) [Trigger]",
  SORT_WHOLE_PATTERN = "Tools:VoiceRunner:Sort Notes (Whole Pattern) [Trigger]",
  SORT_WHOLE_PHRASE = "Tools:VoiceRunner:Sort Notes (Whole Phrase) [Trigger]",
  MERGE_NOTES = "Tools:VoiceRunner:Merge Notes [Trigger]",
  MERGE_SELECTION_IN_PATTERN = "Tools:VoiceRunner:Merge Notes (Selection in Pattern) [Trigger]",
  MERGE_SELECTION_IN_PHRASE = "Tools:VoiceRunner:Merge Notes (Selection in Phrase) [Trigger]",
  MERGE_COLUMN_IN_PATTERN = "Tools:VoiceRunner:Merge Notes (Column in Pattern) [Trigger]",
  MERGE_TRACK_IN_PATTERN = "Tools:VoiceRunner:Merge Notes (Track in Pattern) [Trigger]",
  MERGE_GROUP_IN_PATTERN = "Tools:VoiceRunner:Merge Notes (Group in Pattern) [Trigger]",
  MERGE_WHOLE_PATTERN = "Tools:VoiceRunner:Merge Notes (Whole Pattern) [Trigger]",
  MERGE_WHOLE_PHRASE = "Tools:VoiceRunner:Merge Notes (Whole Phrase) [Trigger]",
}

VR.PROCESS_MODE = {
  SORT = 1,
  MERGE = 2,
}

--------------------------------------------------------------------------------

function VR:__init(...)

  local args = cLib.unpack_args(...)

  --- VR_Prefs, current settings
  self.prefs = renoise.tool().preferences

  --- string
  self.app_display_name = args.app_display_name

  --- bool, retain the number of selected columns on 'select'
  --self.maintain_selected_columns = self.prefs.maintain_selected_columns.value
  self.select_all_columns = self.prefs.select_all_columns.value

  --- bool, 
  self.toggle_line_selection = self.prefs.toggle_line_selection.value

  --- bool, whether to prompt user when 'too many columns' occur
  self.safe_mode = self.prefs.safe_mode.value

  --- when running tool, this is what we process
  -- table, [seq_idx][track_idx] = {xPatternTrack,xPatternTrack,...}
  --self.pattern_tracks = {}

  -- xVoiceRunner
  self.runner = xVoiceRunner{
    split_at_note = self.prefs.split_at_note.value,
    split_at_note_change = self.prefs.split_at_note_change.value,
    split_at_instrument_change = self.prefs.split_at_instrument_change.value,
    link_ghost_notes = self.prefs.link_ghost_notes.value,
    link_glide_notes = self.prefs.link_glide_notes.value,
    stop_at_note_off = self.prefs.stop_at_note_off.value,
    stop_at_note_cut = self.prefs.stop_at_note_cut.value,
    remove_orphans = self.prefs.remove_orphans.value,
    create_noteoffs = self.prefs.create_noteoffs.value,
    close_open_notes = self.prefs.close_open_notes.value,
    reveal_subcolumns = self.prefs.reveal_subcolumns.value,
  }

  --- xVoiceSorter
  self.xsorter = xVoiceSorter{
    runner = self.runner,
    sort_mode = self.prefs.sort_mode.value,
    sort_method = self.prefs.sort_method.value,
    merge_unique = self.prefs.merge_unique.value,
    unique_instrument = self.prefs.unique_instrument.value,
  }

  --- configure user-interface
  self.ui = VR_UI{
    dialog_title = self.app_display_name,
    owner = self,
    waiting_to_show_dialog = self.prefs.autostart.value,
  }

  -- notifications --------------------

  --renoise.tool().app_idle_observable:add_notifier(function()
    ---- 
  --end)

  renoise.tool().app_new_document_observable:add_notifier(function()
    rns = renoise.song()
    self:attach_to_song()
  end)

  renoise.tool().app_release_document_observable:add_notifier(function()
    self:detach_from_song()
  end)

  --self.prefs.maintain_selected_columns:add_notifier(function()
    --self.maintain_selected_columns = self.prefs.maintain_selected_columns.value
  --end)

  self.prefs.select_all_columns:add_notifier(function()
    self.select_all_columns = self.prefs.select_all_columns.value
  end)

  self.prefs.toggle_line_selection:add_notifier(function()
    self.toggle_line_selection = self.prefs.toggle_line_selection.value
    self.select_all_columns = self.prefs.select_all_columns.value
  end)

  self.prefs.safe_mode:add_notifier(function()
    self.safe_mode = self.prefs.safe_mode.value
  end)

  -- xVoiceSorter

  self.prefs.sort_mode:add_notifier(function()
    self.xsorter.sort_mode = self.prefs.sort_mode.value
  end)

  self.prefs.sort_method:add_notifier(function()
    self.xsorter.sort_method = self.prefs.sort_method.value
  end)

  self.prefs.unique_instrument:add_notifier(function()
    self.xsorter.unique_instrument = self.prefs.unique_instrument.value
  end)

  -- xVoiceRunner

  self.prefs.remove_orphans:add_notifier(function()
    self.runner.remove_orphans = self.prefs.remove_orphans.value
  end)

  self.prefs.split_at_note:add_notifier(function()
    self.runner.split_at_note = self.prefs.split_at_note.value
  end)

  self.prefs.split_at_note_change:add_notifier(function()
    self.runner.split_at_note_change = self.prefs.split_at_note_change.value
  end)

  self.prefs.split_at_instrument_change:add_notifier(function()
    self.runner.split_at_instrument_change = self.prefs.split_at_instrument_change.value
  end)

  self.prefs.link_ghost_notes:add_notifier(function()
    self.runner.link_ghost_notes = self.prefs.link_ghost_notes.value
  end)

  self.prefs.link_glide_notes:add_notifier(function()
    self.runner.link_glide_notes = self.prefs.link_glide_notes.value
  end)

  self.prefs.stop_at_note_off:add_notifier(function()
    self.runner.stop_at_note_off = self.prefs.stop_at_note_off.value
  end)

  self.prefs.stop_at_note_cut:add_notifier(function()
    self.runner.stop_at_note_cut = self.prefs.stop_at_note_cut.value
  end)

  self.prefs.create_noteoffs:add_notifier(function()
    self.runner.create_noteoffs = self.prefs.create_noteoffs.value
  end)

  self.prefs.close_open_notes:add_notifier(function()
    self.runner.close_open_notes = self.prefs.close_open_notes.value
  end)
  
  self.prefs.reveal_subcolumns:add_notifier(function()
    self.runner.reveal_subcolumns = self.prefs.reveal_subcolumns.value
  end)


  -- initialize -----------------------

  self.ui:build()

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
-- Merging
--------------------------------------------------------------------------------

function VR:do_merge(scope)

  if not scope then
    scope = self.prefs.selected_scope.value
  end

  self.process_mode = VR.PROCESS_MODE.MERGE

  self.runner:reset()
  self.xsorter:reset()

  local rslt,err = nil,nil

  if (scope == VR.SCOPE.SELECTION_IN_PATTERN) then    rslt,err = self:process_pattern_selection()
  elseif (scope == VR.SCOPE.SELECTION_IN_PHRASE) then rslt,err = self:process_phrase_selection()
  elseif (scope == VR.SCOPE.COLUMN_IN_PATTERN) then rslt,err = self:process_column_in_pattern()
  --elseif (scope == VR.SCOPE.COLUMN_IN_PHRASE) then rslt,err = self:process_column_in_phrase()
  elseif (scope == VR.SCOPE.TRACK_IN_PATTERN) then    rslt,err = self:process_track_in_pattern()
  elseif (scope == VR.SCOPE.GROUP_IN_PATTERN) then    rslt,err = self:process_group_in_pattern()
  elseif (scope == VR.SCOPE.WHOLE_PATTERN) then       rslt,err = self:process_whole_pattern()
  elseif (scope == VR.SCOPE.WHOLE_PHRASE) then        rslt,err = self:process_whole_phrase()
  --elseif (scope == VR.SCOPE.SELECTION_IN_MATRIX) then rslt,err = self:process_matrix_selection()
  --elseif (scope == VR.SCOPE.TRACK_IN_SONG) then       rslt,err = self:process_track_in_song()
  --elseif (scope == VR.SCOPE.GROUP_IN_SONG) then       rslt,err = self:process_group_in_song()
  --elseif (scope == VR.SCOPE.WHOLE_SONG) then          rslt,err = self:process_whole_song()
  else
    error("Unexpected scope")
  end

  --print("*** VR:do_merge - rslt,err",rslt,err)

  if err then
    renoise.app():show_warning(err)
  end

end

--------------------------------------------------------------------------------
-- Sorting
--------------------------------------------------------------------------------
-- invoked through the 'Sort' button/shortcuts
-- @param scope (SCOPE), defined when invoked via shortcut
-- @param template (VR_Template), user-specified 

function VR:do_sort(scope,template)
  TRACE("VR:do_sort(scope,template)",scope,template)

  if self.ui.dialog_too_many_cols 
    and self.ui.dialog_too_many_cols.visible
  then
    self.ui.dialog_too_many_cols:close()
  end

  if not scope then
    scope = self.prefs.selected_scope.value
  end

  self.process_mode = VR.PROCESS_MODE.SORT

  self.runner:reset()
  self.xsorter:reset()

  self.runner.template = template

  local rslt,err = nil,nil

  if (scope == VR.SCOPE.SELECTION_IN_PATTERN) then    rslt,err = self:process_pattern_selection()
  elseif (scope == VR.SCOPE.SELECTION_IN_PHRASE) then rslt,err = self:process_phrase_selection()
  elseif (scope == VR.SCOPE.COLUMN_IN_PATTERN) then rslt,err = self:process_column_in_pattern()
  --elseif (scope == VR.SCOPE.COLUMN_IN_PHRASE) then rslt,err = self:process_column_in_phrase()
  elseif (scope == VR.SCOPE.TRACK_IN_PATTERN) then    rslt,err = self:process_track_in_pattern()
  elseif (scope == VR.SCOPE.GROUP_IN_PATTERN) then    rslt,err = self:process_group_in_pattern()
  elseif (scope == VR.SCOPE.WHOLE_PATTERN) then       rslt,err = self:process_whole_pattern()
  elseif (scope == VR.SCOPE.WHOLE_PHRASE) then        rslt,err = self:process_whole_phrase()
  --elseif (scope == VR.SCOPE.SELECTION_IN_MATRIX) then rslt,err = self:process_matrix_selection()
  --elseif (scope == VR.SCOPE.TRACK_IN_SONG) then       rslt,err = self:process_track_in_song()
  --elseif (scope == VR.SCOPE.GROUP_IN_SONG) then       rslt,err = self:process_group_in_song()
  --elseif (scope == VR.SCOPE.WHOLE_SONG) then          rslt,err = self:process_whole_song()
  else
    error("Unexpected scope")
  end

  --print("*** VR:do_sort - rslt,err",rslt,err)

  if err then
    if (err == xVoiceSorter.ERROR_CODE.TOO_MANY_COLS) then
      self.ui:show_too_many_cols_dialog(function(template)
        --print("triggered callback - template",rprint(template.entries))
        self:do_sort(scope,template)
      end)
    elseif (err == xVoiceSorter.ERROR_CODE.CANT_PRESERVE_EXISTING) then
      renoise.app():show_warning("Can't preserve existing notes outside selection")
    else
      renoise.app():show_warning(err)
    end

  end

end

--------------------------------------------------------------------------------
-- process (sort/merge) selection in pattern-track 
-- @param scope (VR.SCOPE)
-- @param sel (table), supply when SELECTION_IN_PATTERN/PHRASE
-- @param seq_idx (int), if not provided, use selected
-- @param trk_idx (int), if not provided, use selected
-- @return bool, true if processed
-- @return string, error message when failed

function VR:do_process(scope,sel,seq_idx,trk_idx)
  TRACE("VR:do_process(scope,sel,seq_idx,trk_idx)",scope,sel,seq_idx,trk_idx)

  local ptrack_or_phrase = nil

  if (scope == VR.SCOPE.SELECTION_IN_PHRASE)
    or (scope == VR.SCOPE.COLUMN_IN_PHRASE)
    or (scope == VR.SCOPE.WHOLE_PHRASE)
  then -- instrument-phrase
    ptrack_or_phrase = rns.selected_phrase
    if not sel then
      --if (scope == VR.SCOPE.COLUMN_IN_PHRASE) then
        --sel = xSelection.get_phrase()
      --else
      if (scope == VR.SCOPE.WHOLE_PHRASE) then
        sel = xSelection.get_phrase()
      end
    end
    if not ptrack_or_phrase then
      return false,"Unable to process: no phrase is selected"
    end
  else -- pattern-track
    if not seq_idx then seq_idx = rns.selected_sequence_index end
    if not trk_idx then trk_idx = rns.selected_track_index end
    if not sel then
      if (scope == VR.SCOPE.WHOLE_PATTERN) then
        error("TODO")
      elseif (scope == VR.SCOPE.TRACK_IN_PATTERN) then
        sel = xSelection.get_pattern_track(seq_idx,trk_idx)
      elseif (scope == VR.SCOPE.COLUMN_IN_PATTERN) then
        local col_idx = rns.selected_note_column_index
        sel = xSelection.get_pattern_column(seq_idx,trk_idx,col_idx)
      end
    else
      trk_idx = sel.start_track
    end
    local patt_idx = rns.sequencer:pattern(seq_idx)
    local patt = rns.patterns[patt_idx]
    if not patt then
      return false,"Unable to process: couldn't locate pattern"
    end
    ptrack_or_phrase = patt.tracks[trk_idx]
    if not ptrack_or_phrase then
      return false,"Unable to process: couldn't locate pattern-track"
    end
    --print("*** do_process - pattern track: trk_idx,seq_idx",trk_idx,seq_idx)
    --print("*** do_process - pattern track: sel...",rprint(sel))
  end
  
  local rslt,err 
  if (self.process_mode == VR.PROCESS_MODE.SORT) then
    rslt,err = self.xsorter:sort(ptrack_or_phrase,sel,trk_idx,seq_idx)
  elseif (self.process_mode == VR.PROCESS_MODE.MERGE) then
    rslt,err = self.runner:merge_columns(ptrack_or_phrase,sel,trk_idx,seq_idx)
  end

  if err then
    return false,err
  end

  return true

end

--------------------------------------------------------------------------------

function VR:process_pattern_selection()
  TRACE("VR:process_pattern_selection()")

  if not self:pattern_editor_visible() then
    return false,"Unable to process: pattern editor is not visible"
  end

  local patt_sel = rns.selection_in_pattern
  if not patt_sel then      
    return false,"Please create a selection in the pattern"
  end

  if not xSelection.is_single_track(patt_sel) then
    return false,"Please restrict the selection to a single track"
  end

  if not xSelection.includes_note_columns(patt_sel) then
    return false,"Sorting only works on note-columns"
  end

  local seq_idx = rns.selected_sequence_index

  return self:do_process(VR.SCOPE.SELECTION_IN_PATTERN,patt_sel)

end

--------------------------------------------------------------------------------

function VR:process_phrase_selection()
  TRACE("VR:process_phrase_selection()")

  if not rns.selected_phrase then
    return false,"Unable to process: no phrase is selected"
  end

  if not self:phrase_editor_visible() then
    return false,"Unable to process: phrase-editor is not visible"
  end

  local phrase_sel = rns.selection_in_phrase
  return self:do_process(VR.SCOPE.SELECTION_IN_PHRASE,phrase_sel)

end

--------------------------------------------------------------------------------

function VR:process_matrix_selection()
  TRACE("VR:process_matrix_selection()")

  -- TODO

  --[[
  local matrix_sel,err = xSelection.get_matrix_selection()
  if table.is_empty(matrix_sel) then
    return false,"No selection is defined in the matrix"
  end

  for seq_idx = 1, #rns.sequencer.pattern_sequence do
    if matrix_sel[seq_idx] then
      for trk_idx = 1, #rns.tracks do
        if matrix_sel[seq_idx][trk_idx] then
          if not self:do_process(nil,seq_idx,trk_idx)
            -- TODO handle errors during processing
            -- (such as when exceeding #columns)
          end
        end
      end
      -- display progress
      if (options.process_slice_mode.value ~= SLICE_MODE.NONE) then
        progress_handler(("Collecting phrases : sequence index = %d"):format(seq_idx))
        coroutine.yield()
      end
    end
  end
  ]]

end
--------------------------------------------------------------------------------

function VR:process_track_in_song()
  TRACE("VR:process_track_in_song()")

  if not self:pattern_editor_visible() then
    return false,"Unable to process: pattern editor is not visible"
  end

end

--------------------------------------------------------------------------------

function VR:process_group_in_song()
  TRACE("VR:process_group_in_song()")

  if not self:pattern_editor_visible() then
    return false,"Unable to process: pattern editor is not visible"
  end

end

--------------------------------------------------------------------------------

function VR:process_whole_song()
  TRACE("VR:process_whole_song()")

  if not self:pattern_editor_visible() then
    return false,"Unable to process: pattern editor is not visible"
  end

end

--------------------------------------------------------------------------------

function VR:process_column_in_pattern()
  TRACE("VR:process_column_in_pattern()")

  if not self:pattern_editor_visible() then
    return false,"Unable to process: pattern editor is not visible"
  end

  return self:do_process(VR.SCOPE.COLUMN_IN_PATTERN)

end

--------------------------------------------------------------------------------
--[[
function VR:process_column_in_phrase()
  TRACE("VR:process_column_in_phrase()")

  if not rns.selected_phrase then
    return false,"Unable to process: no phrase is selected"
  end

  if not self:phrase_editor_visible() then
    return false,"Unable to process: phrase editor is not visible"
  end

  return self:do_process(VR.SCOPE.COLUMN_IN_PHRASE)

end
]]

--------------------------------------------------------------------------------

function VR:process_track_in_pattern()
  TRACE("VR:process_track_in_pattern()")

  if not self:pattern_editor_visible() then
    return false,"Unable to process: pattern editor is not visible"
  end

  return self:do_process(VR.SCOPE.TRACK_IN_PATTERN)

end

--------------------------------------------------------------------------------

function VR:process_group_in_pattern()
  TRACE("VR:process_group_in_pattern()")

  if not self:pattern_editor_visible() then
    return false,"Unable to process: pattern editor is not visible"
  end

  -- iterate through sequencer tracks in group
  local group_track_index = xTrack.get_group_track_index(rns.selected_track_index)
  --print("group_track_index",group_track_index)

  if not group_track_index then
    return false,"Unable to process: track is not part of a group"
  end

  local seq_idx = rns.selected_sequence_index

  for trk_idx = group_track_index-1,1,-1 do
    local track = rns.tracks[trk_idx]
    if (track.type == renoise.Track.TRACK_TYPE_GROUP) then
      --print("*** encountered group track, abort...",trk_idx)
      break
    elseif (track.type == renoise.Track.TRACK_TYPE_SEQUENCER) then

      self.runner:reset()
      self.xsorter:reset()

      --print("*** encountered sequencer track, process...",trk_idx)
      local sel = xSelection.get_pattern_track(seq_idx,trk_idx)
      --print("*** encountered sequencer track, sel",rprint(sel))

      local rslt,err = self:do_process(VR.SCOPE.TRACK_IN_PATTERN,sel,seq_idx,trk_idx)
      if not rslt then
        --print("*** rslt,err",rslt,err)
        return false,err
      end 
    end

  end

end

--------------------------------------------------------------------------------

function VR:process_whole_pattern()
  TRACE("VR:process_whole_pattern()")

  if not self:pattern_editor_visible() then
    return false,"Unable to process: pattern editor is not visible"
  end

  if not self:pattern_editor_visible() then
    return false,"Unable to process: pattern editor is not visible"
  end

  -- iterate through sequencer tracks in group
  local seq_idx = rns.selected_sequence_index
  for trk_idx = 1,#rns.tracks do
    local track = rns.tracks[trk_idx]
    if (track.type == renoise.Track.TRACK_TYPE_SEQUENCER) then
      self.runner:reset()
      self.xsorter:reset()
      local sel = xSelection.get_pattern_track(seq_idx,trk_idx)
      local rslt,err = self:do_process(VR.SCOPE.TRACK_IN_PATTERN,sel,seq_idx,trk_idx)
      if not rslt then
        return false,err
      end 
    end
  end

end

--------------------------------------------------------------------------------

function VR:process_whole_phrase()
  TRACE("VR:process_whole_phrase()")

  if not rns.selected_phrase then
    return false,"Unable to process: no phrase is selected"
  end

  if not self:phrase_editor_visible() then
    return false,"Unable to process: phrase editor is not visible"
  end

  return self:do_process(VR.SCOPE.WHOLE_PHRASE)

end

-------------------------------------------------------------------------------

function VR:select_in_pattern(patt_sel)

  if not table.is_empty(patt_sel) then
    --[[
    if self.maintain_selected_columns 
      and rns.selection_in_pattern
    then
      patt_sel.start_column = rns.selection_in_pattern.start_column
      patt_sel.end_column = rns.selection_in_pattern.end_column
    end
    ]]
    if self.select_all_columns then
      local track = rns.selected_track
      local total_cols = track.visible_note_columns + track.visible_effect_columns
      patt_sel.start_column = 1
      patt_sel.end_column = total_cols
    end

    rns.selection_in_pattern = patt_sel
  end

end

--------------------------------------------------------------------------------
-- select the voice-run below the cursor position

function VR:select_voice_run(prevent_toggle)
  TRACE("VR:select_voice_run()")

  local trk_idx = rns.selected_track_index
  local col_idx = rns.selected_note_column_index
  local voice_run = self.runner:collect_at_cursor()
  --print("*** select_voice_run - voice_run...",rprint(voice_run))

  if voice_run then
    if self.toggle_line_selection and not prevent_toggle then
      self.select_all_columns = not self.select_all_columns
    end
    local patt_sel = xVoiceRunner.get_voice_run_selection(voice_run,trk_idx,col_idx)
    --print("*** select_voice_run - patt_sel",rprint(patt_sel))
    self:select_in_pattern(patt_sel)
  else
    renoise.app():show_status(
      VR.MSG_FROM_VOICE_RUNNER..
      VR.MSG_NO_RUN_AVAILABLE)
  end

end

-------------------------------------------------------------------------------
-- select the next voice-run relative to the cursor position
-- @return table, pattern-selection or nil

function VR:select_next_voice_run()
  TRACE("VR:select_next_voice_run()")

  local patt_sel = {}
  local trk_idx = rns.selected_track_index
  local col_idx = rns.selected_note_column_index

  local voice_run = self.runner:collect_below_cursor()
  --print("*** select_next_voice_run - voice_run",voice_run)
  if voice_run then
    local patt_sel = xVoiceRunner.get_voice_run_selection(voice_run,trk_idx,col_idx)
    self:select_in_pattern(patt_sel)
    rns.selected_line_index = patt_sel.start_line
  else
    renoise.app():show_status(
      VR.MSG_FROM_VOICE_RUNNER..
      VR.MSG_NO_RUN_AVAILABLE)
  end

end

-------------------------------------------------------------------------------
-- select the previous voice-run relative to the cursor position
-- @return table, pattern-selection or nil

function VR:select_previous_voice_run()
  TRACE("VR:select_previous_voice_run()")

  local patt_sel = {}
  local trk_idx = rns.selected_track_index
  local col_idx = rns.selected_note_column_index

  local voice_run = self.runner:collect_above_cursor()
  --print("*** select_previous_voice_run - voice_run",voice_run)
  if voice_run then
    local patt_sel = xVoiceRunner.get_voice_run_selection(voice_run,trk_idx,col_idx)
    self:select_in_pattern(patt_sel)
    rns.selected_line_index = patt_sel.start_line
  else
    renoise.app():show_status(
      VR.MSG_FROM_VOICE_RUNNER..
      VR.MSG_NO_RUN_AVAILABLE)
  end

end

--------------------------------------------------------------------------------

function VR:select_next_note_column()
  xColumns.next_note_column(true)
  self:select_voice_run(true)
end

--------------------------------------------------------------------------------

function VR:select_previous_note_column()

  if not self:pattern_editor_visible() then
    renoise.app():show_status("[VoiceRunner] setting the position in the pattern editor")
  end
  xColumns.previous_note_column(true)
  self:select_voice_run(true)

end

--------------------------------------------------------------------------------
-- for testing...

function VR:test_list_info()
  TRACE("VR:test_list_info()")

  local patt_sel = rns.selection_in_pattern
  if not patt_sel then
    --print("*** No selection in pattern")
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

--------------------------------------------------------------------------------
-- check if phrase editor is visible

function VR:phrase_editor_visible()

  --print("rns.selected_instrument.phrase_editor_visible",rns.selected_instrument.phrase_editor_visible)
  --print("renoise.app().window.instrument_editor_is_detached",renoise.app().window.instrument_editor_is_detached)
  --print("renoise.app().window.active_middle_frame",renoise.app().window.active_middle_frame,renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR)
  if renoise.app().window.instrument_editor_is_detached then
    if not rns.selected_instrument.phrase_editor_visible then
      return false
    end
  elseif (renoise.app().window.active_middle_frame ~= 
    renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_PHRASE_EDITOR) 
  then
    return false
  end

  return true

end

--------------------------------------------------------------------------------
-- check if pattern editor is visible

function VR:pattern_editor_visible()

  return (renoise.app().window.active_middle_frame == 
    renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR) 

end

