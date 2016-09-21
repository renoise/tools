--[[============================================================================
-- PhraseMate
============================================================================]]--

--[[--

PhraseMate (main application)

#
.

--]]


--==============================================================================


class 'PhraseMate'

PhraseMate.INPUT_SCOPES = {
  "Selection in Pattern",
  "Selection in Matrix",
  "Track in Pattern",
  "Track in Song",
}
PhraseMate.INPUT_SCOPE = {
  SELECTION_IN_PATTERN = 1,
  SELECTION_IN_MATRIX = 2,
  TRACK_IN_PATTERN = 3,
  TRACK_IN_SONG = 4,
}

PhraseMate.SOURCE_INSTR = {
  CAPTURE_ONCE = 1,
  CAPTURE_ALL = 2,
  SELECTED = 3,
  CUSTOM = 4,
}

PhraseMate.TARGET_INSTR = {
  SAME = 1,
  NEW = 2,
  CUSTOM = 3,
}

PhraseMate.OUTPUT_SOURCE = {
  SELECTED = 1,
  PRESET = 2,
}

PhraseMate.OUTPUT_MODE = {
  SELECTION = 1,
  TRACK = 2,
}

PhraseMate.SLICE_MODES = {"Disabled","Pattern","Patt-track"}
PhraseMate.SLICE_MODE = {
  NONE = 1,
  PATTERN = 2,
  PATTERN_TRACK = 3,
}

PhraseMate.PLAYBACK_MODES = {"Off","Prg","Map"}
PhraseMate.PLAYBACK_MODE = {
  PHRASES_OFF = 1,
  PHRASES_PLAY_SELECTIVE = 2,
  PHRASES_PLAY_KEYMAP = 3,
}

PhraseMate.MIDI_MAPPING = {
  SELECT_PHRASE_IN_INSTR = "Tools:PhraseMate:Select Phrase in Instrument [Set]",
  PREV_PHRASE_IN_INSTR = "Tools:PhraseMate:Select Previous Phrase in Instrument [Trigger]",
  NEXT_PHRASE_IN_INSTR = "Tools:PhraseMate:Select Next Phrase in Instrument [Trigger]",
  SET_PLAYBACK_MODE = "Tools:PhraseMate:Select Playback Mode [Set]",
  DELETE_PHRASE = "Tools:PhraseMate:Delete Selected Phrase [Trigger]",
  INSERT_PHRASE = "Tools:PhraseMate:Insert New Phrase [Trigger]",
}

--------------------------------------------------------------------------------

function PhraseMate:__init(...)
  TRACE("PhraseMate:__init()")

  self.prefs = renoise.tool().preferences

  local args = cLib.unpack_args(...)

  --- string
  self.app_display_name = args.app_display_name

  -- internal -------------------------

  --- int, can change during collection when auto-capturing
  self.source_instr_idx = nil

  --- int, the destination for our collected phrases
  self.target_instr_idx = nil

  --- bool, true when we have successfully determined the source instr.
  self.done_with_capture = false

  --- (table) source -> target mappings, when creating new instrument(s)
  self.source_target_map = {}

  --- keep track of 'ghost notes' when reading note columns
  -- [track_index][column_index]{
  --    instrument_index = int,
  --    offed = bool,
  --  }
  self.ghost_columns = {}

  --- keep track of 'initial state' of source before reading note columns
  --  {
  --    number_of_phrases = int
  --    playback_mode = renoise.Instrument.PHRASES_XXX,
  --  }
  self.initial_instr_states = {}

  --- table<[instr_idx]{
  --  {
  --    instrument_index = int,
  --    sequence_index = int,
  --    track_index = int,
  --    phrase_index = int,
  --  }
  self.collected_phrases = {}

  --- table<[string] = bool>
  self.collected_messages = {}

  --- table<[int] = bool>, remember which patterns we have collected from
  self.processed_ptracks = {}

  --- table, changed while in realtime mode
  self.modified_lines = {} 

  --- bool, do not trigger handler while true
  self.suppress_line_notifier = false 

  --- (ProcessSlicer)
  self.process_slicer = nil 

  --- function, when running as sliced process
  --self.collect_yield_fn = nil

  --- PhraseMateUI
  self.ui = nil

  --- PhraseMateExportDialog
  self.export_dialog = nil

  --- PhraseMateSmartDialog
  self.smart_dialog = nil 

  --- string, error message when failing to allocate phrase during collection
  self.allocation_error_msg = nil

  -- notifications --------------------

  renoise.tool().app_idle_observable:add_notifier(function()
    if (#self.modified_lines > 0) then
      if rns.transport.edit_mode then
        for k,v in ipairs(self.modified_lines) do
          self:handle_modified_line(v)
        end
      end
      self.modified_lines = {}
    end
  end)

  renoise.tool().app_new_document_observable:add_notifier(function()
    rns = renoise.song()
    self:attach_to_song()
  end)

  self.prefs.zxx_mode:add_notifier(function()
    self.modified_lines = {}  
  end)

  -- final steps ----------------------

  self:attach_to_song()

end

--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

function PhraseMate:invoke_task(rslt,err)
  TRACE("PhraseMate:invoke_task(rslt,err)",rslt,err)

  if (rslt == false and err) then
    renoise.app():show_status(err)
  end

end

--------------------------------------------------------------------------------

function PhraseMate:progress_handler(msg)
  TRACE("PhraseMate:progress_handler(msg)",msg)

  self.ui.progress_txt_count = self.ui.progress_txt_count+1
  if (self.ui.progress_txt_count == #PhraseMateUI.UI_PROGRESS_TXT) then
    self.ui.progress_txt_count = 1
  end
  self.ui.status_update = msg

end

--------------------------------------------------------------------------------

function PhraseMate:done_handler(msg)
  TRACE("PhraseMate:done_handler(msg)",msg)

  self.ui.status_update = "(PhraseMate) Done processing!"
  self:initialize_variables()
  collectgarbage()
  --print("Memory used:",collectgarbage("count")*1024)

  self.process_slicer = nil

  self.ui:update_submit_buttons()
  renoise.app():show_message(msg)

end

--------------------------------------------------------------------------------
-- reset variables to initial state 

function PhraseMate:initialize_variables()
  TRACE("PhraseMate:initialize_variables()")

  self.done_with_capture = false
  self.source_target_map = {}
  self.collected_phrases = {}
  self.processed_ptracks = {}
  self.ghost_columns = {}
  self.initial_instr_states = {}
  self.collected_messages = {}
  self.source_instr_idx = nil
  self.target_instr_idx = nil

end

--------------------------------------------------------------------------------

function PhraseMate:invoke_sliced_task(fn,arg)
  TRACE("PhraseMate:invoke_sliced_task(fn,arg)",fn,arg)

  if (self.prefs.process_slice_mode.value ~= PhraseMate.SLICE_MODE.NONE) then
    self.process_slicer = ProcessSlicer(fn,arg)
    self.process_slicer:start()
  else
    fn(arg)
  end

end

--------------------------------------------------------------------------------
-- forward keypresses to UI 
-- NB: proxy method - 'self' refers to PhraseMateUI...

function PhraseMate:keyhandler(dialog,key)
  TRACE("PhraseMate:keyhandler(dialog,key)",dialog,key)

  self:keyhandler(dialog,key)

end

--------------------------------------------------------------------------------

function PhraseMate:show_main_dialog()
  TRACE("PhraseMate:show_main_dialog()")

  if not self.ui then
    self.ui = PhraseMateUI{
      dialog_title = self.app_display_name,
      dialog_keyhandler = self.keyhandler,
      owner = self,
      waiting_to_show_dialog = self.prefs.autostart.value and not self.prefs.autostart_hidden.value,
    }
  end

  self.ui:show()

end
--------------------------------------------------------------------------------

function PhraseMate:show_export_dialog()
  TRACE("PhraseMate:show_export_dialog()")

  if not self.export_dialog then
    self.export_dialog = PhraseMateExportDialog{
      dialog_title = "PhraseMate: Export presets",
      owner = self,
    }
  end

  self.export_dialog:show()

end

--------------------------------------------------------------------------------

function PhraseMate:show_smart_dialog()
  TRACE("PhraseMate:show_smart_dialog()")

  if not self.smart_dialog then
    self.smart_dialog = PhraseMateSmartDialog{
      dialog_title = "PhraseMate: Smart Write",
      owner = self,
    }
  end

  self.smart_dialog:show()

end

--------------------------------------------------------------------------------
-- Input methods
--------------------------------------------------------------------------------
-- return pattern name, or "Patt XX" if not defined

function PhraseMate:get_pattern_name(seq_idx)
  --TRACE("PhraseMate:get_pattern_name(seq_idx)",seq_idx)
  local name = rns.patterns[rns.sequencer:pattern(seq_idx)].name
  return (name=="") and ("Pattern %.2d"):format(seq_idx) or "Pattern "..name
end

--------------------------------------------------------------------------------
-- return track name, or "Track XX" if not defined

function PhraseMate:get_track_name(trk_idx)
  local name = rns.tracks[trk_idx].name
  return (name=="") and ("Track %.2d") or name 
end

--------------------------------------------------------------------------------
-- when doing CAPTURE_ONCE, grab the instrument nearest to our cursor 

function PhraseMate:do_capture_once(trk_idx,seq_idx)
  TRACE("PhraseMate:do_capture_once(trk_idx,seq_idx)",trk_idx,seq_idx)

  if not self.done_with_capture 
    and (self.prefs.input_source_instr.value == PhraseMate.SOURCE_INSTR.CAPTURE_ONCE) 
  then
    local seq_idx,trk_idx = rns.selected_sequence_index,rns.selected_track_index
    rns.selected_sequence_index = seq_idx
    rns.selected_track_index = trk_idx
    --print("*** capture source instrument",source_instr_idx)
    self:set_source_instr(xInstrument.autocapture())
    rns.selected_sequence_index,rns.selected_track_index = seq_idx,trk_idx
    self.done_with_capture = true
    --print("*** captured instrument",source_instr_idx)
  end

end

--------------------------------------------------------------------------------
-- look for implicit/explicit phrase trigger in the provided patternline
-- @param line (renoise.PatternLine)
-- @param note_col_idx (int)
-- @param instr_idx (int)
-- @param trk_idx (int)
-- @return bool

function PhraseMate:note_is_phrase_trigger(line,note_col_idx,instr_idx,trk_idx)
  TRACE("PhraseMate:note_is_phrase_trigger(line,note_col_idx,instr_idx,trk_idx)",line,note_col_idx,instr_idx,trk_idx)

  -- no note means no triggering 
  local note_col = line.note_columns[note_col_idx]
  if (note_col.note_value > renoise.PatternLine.NOTE_OFF) then
    --print("*** note_is_phrase_trigger - false, no note is present")
    return false
  end

  -- no phrases means no triggering 
  local instr = rns.instruments[instr_idx]
  if (#instr.phrases == 0) then
    --print("*** note_is_phrase_trigger - false, no phrases available in instrument")
    return false
  end

  local track = rns.tracks[trk_idx]
  local visible_fx_cols = track.visible_effect_columns

  if (instr.phrase_playback_mode == renoise.Instrument.PHRASES_PLAY_SELECTIVE) 
    and (self.initial_instr_states[instr_idx].number_of_phrases > 0)
  then
    return true, "Can't collect phrases while the source instrument contains phrases and is set to phrase playback. Please switch playback mode to 'Off' and try again.\n"
        
  elseif (instr.phrase_playback_mode == renoise.Instrument.PHRASES_PLAY_KEYMAP) 
    and (self.initial_instr_states[instr_idx].number_of_phrases > 0)
    and xPhrase.note_is_keymapped(note_col.note_value,self.initial_instr_states[instr_idx])
  then
    return true,"One or more notes in the pattern were triggered using a phrase in keymap mode. To collect these notes, please switch playback mode to 'Off' and try again.\n"
  else
    local zxx_index = self:get_zxx_command(line,note_col_idx,visible_fx_cols) 
    --print("*** note_is_phrase_trigger - zxx_index",zxx_index)
    if zxx_index and (zxx_index > 0x00) and (zxx_index <= 0x7F) then
      return true
    end
  end

  return false

end

--------------------------------------------------------------------------------
-- obtain Zxx value from the provided line, if any
-- (look in both local and master fx-columns)
-- @param line (renoise.PatternLine)
-- @param note_col_idx (int)
-- @param visible_fx_cols (int)
-- @return int or nil

function PhraseMate:get_zxx_command(line,note_col_idx,visible_fx_cols)
  TRACE("PhraseMate:get_zxx_command(line,note_col_idx,visible_fx_cols)",line,note_col_idx,visible_fx_cols)

  local note_col = line.note_columns[note_col_idx]
  if (note_col.effect_number_string == "0Z") then
    return note_col.effect_amount_value
  end
  for k,v in ipairs(line.effect_columns) do
    if (k > visible_fx_cols) then
      break
    elseif (v.number_string == "0Z") then
      return v.amount_value
    end
  end

end


--------------------------------------------------------------------------------
-- update source instr by calling this fn 

function PhraseMate:set_source_instr(instr_idx)
  TRACE("PhraseMate:set_source_instr(instr_idx)",instr_idx)

  assert(type(instr_idx)=="number","Expected instr_idx to be a number")

  self.source_instr_idx = instr_idx
  self:save_instr_state(instr_idx)
  self:sync_source_target_instr()

  --print("*** set_source_instr - source_instr_idx",self.source_instr_idx)

end

--------------------------------------------------------------------------------
-- when collecting phrases into instrument itself, we need to know if the 
-- instrument originally contained phrases or we won't be able to reliably 
-- detect notes that trigger phrases later on... 

function PhraseMate:save_instr_state(instr_idx)
  TRACE("PhraseMate:save_instr_state(instr_idx)",instr_idx)

  local instr = rns.instruments[instr_idx]
  if not instr then
    LOG("Could not locate instrument, state was not saved")
    return
  end
  if not self.initial_instr_states[instr_idx] then
    self.initial_instr_states[instr_idx] = {
      number_of_phrases = #instr.phrases,
      playback_mode = instr.phrase_playback_mode,
      phrase_mappings = table.rcopy(instr.phrase_mappings)
    }
  end

end

--------------------------------------------------------------------------------
-- when target is 'same as source', invoke this whenever source is set

function PhraseMate:sync_source_target_instr()
  TRACE("PhraseMate:sync_source_target_instr()")

  if (self.prefs.input_target_instr.value == PhraseMate.TARGET_INSTR.SAME) then
    self.target_instr_idx = self.source_instr_idx
  end

end

--------------------------------------------------------------------------------
-- when pressing the '+' button or when we're importing phrases
-- will apply the default settings for new phrases
-- @return bool, true when phrase was inserted
-- @return string, error message when failed

function PhraseMate:insert_phrase()

  local instr = rns.selected_instrument
  if not instr then
    return false,"Can't insert phrase, no instrument is selected"
  end

  local instr_idx = rns.selected_instrument_index
  local keymap_args = self.prefs.create_keymappings.value and {
    keymap_range = self.prefs.create_keymap_range.value,
    keymap_offset = self.prefs.create_keymap_offset.value,
  }

  local insert_at_idx = rns.selected_phrase_index+1

  local phrase,phrase_idx_or_err = xPhraseManager.auto_insert_phrase(instr_idx,insert_at_idx,nil,keymap_args)
  if not phrase then
    return false,phrase_idx_or_err
  end

  local looping = self.prefs.input_loop_phrases.value
  local looping_set,err = xPhraseManager.set_universal_property(instr_idx,phrase_idx_or_err,"looping",looping)
  if not looping_set then
    LOG(err)
  end

  rns.selected_phrase_index = phrase_idx_or_err

  return true

end

--------------------------------------------------------------------------------
-- when pressing the '+' button or when we're importing phrases
-- will apply the default settings for new phrases
-- @return bool, true when phrase was inserted
-- @return string, error message when failed

function PhraseMate:delete_phrase(phrase_idx)

  --local phrase_idx = rns.selected_phrase_index
  if not phrase_idx or (phrase_idx == 0) then
    return false,"Can't delete phrase, none is selected"
  end

  local instr = rns.selected_instrument
  instr:delete_phrase_at(phrase_idx)

  return true

end

--------------------------------------------------------------------------------
-- reuse instrument (via map), take over (when empty) or create as needed
-- will update self.target_instr_idx ...

function PhraseMate:allocate_target_instr()
  TRACE("PhraseMate:allocate_target_instr()")

  if (self.prefs.input_target_instr.value == PhraseMate.TARGET_INSTR.NEW) then

    -- attempt to re-use previously created
    local do_copy = false
    if self.source_target_map[self.source_instr_idx] then
      self.target_instr_idx = self.source_target_map[self.source_instr_idx]
      --print("*** allocate_target_instr - reuse",self.target_instr_idx)
    else
      self.target_instr_idx = xInstrument.get_first_available()
      self.source_target_map[self.source_instr_idx] = self.target_instr_idx
      --print("*** allocate_target_instr - takeover",self.target_instr_idx)
      do_copy = true
    end

    if not self.target_instr_idx then
      self.target_instr_idx = #rns.instruments+1
      rns:insert_instrument_at(self.target_instr_idx)
      self.source_target_map[self.source_instr_idx] = self.target_instr_idx
      --print("*** allocate_target_instr - create",self.target_instr_idx)
      do_copy = true
    end

    if do_copy then
      local target_instr = rns.instruments[self.target_instr_idx]
      local source_instr = rns.instruments[self.source_instr_idx]
      target_instr:copy_from(source_instr)
      target_instr.name = ("#%s"):format(source_instr.name)
    end

  end

end

--------------------------------------------------------------------------------
-- continue existing phrase, take over empty phrase or create as needed
-- @return bool, true when allocated
-- @return string, error message when failed

function PhraseMate:allocate_phrase(track,seq_idx,trk_idx,selection)
  TRACE("PhraseMate:allocate_phrase(track,seq_idx,trk_idx,selection)",track,seq_idx,trk_idx,selection)

  local phrase,phrase_idx_or_err

  -- only add when instrument exists
  local instr = rns.instruments[self.target_instr_idx]
  --print("*** allocate_phrase - self.target_instr_idx",self.target_instr_idx,instr)
  if not instr then
    return false,"Could not locate instrument, unable to allocate phrase"
  end

  -- continue existing
  if self.collected_phrases[self.source_instr_idx] then
    for k,v in ipairs(self.collected_phrases[self.source_instr_idx]) do
      if (v.sequence_index == seq_idx) 
        and (v.track_index == trk_idx) 
      then
        phrase,phrase_idx_or_err = instr.phrases[v.phrase_index],v.phrase_index
        --print(">>> reusing phrase in seq,trk",seq_idx,trk_idx,"for source/target",self.source_instr_idx,self.target_instr_idx,phrase_idx_or_err,phrase)
      end
    end
  end

  -- takeover/create
  if not phrase then
    
    local takeover = not self.prefs.input_include_empty_phrases.value 
    local insert_at_idx = nil
    local keymap_args = self.prefs.create_keymappings.value and {
      keymap_range = self.prefs.create_keymap_range.value,
      keymap_offset = self.prefs.create_keymap_offset.value
    } or nil

    phrase,phrase_idx_or_err = xPhraseManager.auto_insert_phrase(self.target_instr_idx,insert_at_idx,takeover,keymap_args)
    --print("*** allocate_phrase - phrase,phrase_idx_or_err",phrase,phrase_idx_or_err)
    if not phrase then
      return false,phrase_idx_or_err
      --LOG(phrase_idx_or_err) -- carries error msg
    end

    phrase:clear() -- clear default C-4 

    -- maintain a record for later
    if not self.collected_phrases[self.source_instr_idx] then
      self.collected_phrases[self.source_instr_idx] = {}
    end
    local t = {
      instrument_index = self.target_instr_idx,
      track_index = trk_idx,
      sequence_index = seq_idx,
      phrase_index = phrase_idx_or_err,
    }
    table.insert(self.collected_phrases[self.source_instr_idx],t)
    --print(">>> allocate_phrase - t...",#self.collected_phrases,rprint(t))

    -- name & configure the phrase
    if phrase then
      phrase.name = ("%s : %s"):format(self:get_pattern_name(seq_idx),self:get_track_name(trk_idx))
      phrase.number_of_lines = 1 + selection.end_line - selection.start_line
      phrase.volume_column_visible = track.volume_column_visible
      phrase.panning_column_visible = track.panning_column_visible
      phrase.delay_column_visible = track.delay_column_visible
      phrase.sample_effects_column_visible = track.sample_effects_column_visible
      if (track.type == renoise.Track.TRACK_TYPE_SEQUENCER) then
        phrase.visible_note_columns = track.visible_note_columns
      end
      phrase.visible_effect_columns = track.visible_effect_columns

      local looping_set,err = xPhraseManager.set_universal_property(self.target_instr_idx,phrase_idx_or_err,"looping",self.prefs.input_loop_phrases.value)
      if not looping_set then
        LOG(err)
      end

    end

  end

  if not phrase then
    return false,"Could not allocate phrase"
  end

  return phrase,phrase_idx_or_err

end

--------------------------------------------------------------------------------
-- the yield function, invoked while collecting phrases 

function PhraseMate:collect_yield_fn(seq_idx,trk_idx)
  TRACE("PhraseMate:collect_yield_fn(seq_idx,trk_idx)",seq_idx,trk_idx)

  if trk_idx and (self.prefs.process_slice_mode.value == PhraseMate.SLICE_MODE.PATTERN_TRACK) then
    self:progress_handler(("Collecting phrases : sequence index = %d, track index = %d"):format(seq_idx,trk_idx))
  elseif (self.prefs.process_slice_mode.value == PhraseMate.SLICE_MODE.PATTERN) then
    self:progress_handler(("Collecting phrases : sequence index = %d"):format(seq_idx))
  end

  if self.process_slicer and self.process_slicer:running() then
    coroutine.yield()
  end
end

--------------------------------------------------------------------------------
-- invoked through the 'collect phrases' button/shortcuts
-- @param scope (PhraseMate.INPUT_SCOPE), defined when invoked via shortcut
-- @return table (created phrase indices)

function PhraseMate:collect_phrases(scope)
  TRACE("PhraseMate:collect_phrases(scope)",scope)

  if not scope then
    scope = self.prefs.input_scope.value
  end

  self:initialize_variables()

  -- set initial source/target instruments
  -- (might change during collection)

  if (self.prefs.input_source_instr.value == PhraseMate.SOURCE_INSTR.CUSTOM) then
    if vb then
      self.source_instr_idx = vb.views["ui_source_popup"].value - #PhraseMate.SOURCE_INSTR-2
    end
  elseif (self.prefs.input_source_instr.value == PhraseMate.SOURCE_INSTR.SELECTED) then
    self.source_instr_idx = rns.selected_instrument_index
  end
  if (self.prefs.input_target_instr.value == PhraseMate.TARGET_INSTR.CUSTOM) then
    if vb then
      self.target_instr_idx = vb.views["ui_target_popup"].value - #PhraseMate.TARGET_INSTR-2
    end
  end

  local capture_all = (self.prefs.input_source_instr.value == PhraseMate.SOURCE_INSTR.CAPTURE_ALL)
  if not capture_all then
    self:save_instr_state(self.source_instr_idx)
  end

  if self.source_instr_idx then
    self:sync_source_target_instr()
  end

  -- do collection

  if (scope == PhraseMate.INPUT_SCOPE.SELECTION_IN_PATTERN) then
    self:invoke_sliced_task(self.collect_from_pattern_selection,self)
  elseif (scope == PhraseMate.INPUT_SCOPE.SELECTION_IN_MATRIX) then
    self:invoke_sliced_task(self.collect_from_matrix_selection,self)
  elseif (scope == PhraseMate.INPUT_SCOPE.TRACK_IN_PATTERN) then
    self:invoke_sliced_task(self.collect_from_track_in_pattern,self)
  elseif (scope == PhraseMate.INPUT_SCOPE.TRACK_IN_SONG) then
    self:invoke_sliced_task(self.collect_from_track_in_song,self)
  else
    error("Unexpected output scope")
  end

  -- note: the various collect_xx methods will call do_finalize()
  -- which will clean up/create the phrases

end

--------------------------------------------------------------------------------
-- @return bool
-- @return string (error message)

function PhraseMate:collect_from_pattern_selection()
  TRACE("PhraseMate:collect_from_pattern_selection()")

  local patt_sel,err = xSelection.get_pattern_if_single_track()
  if not patt_sel then
    return false,err
  end

  local seq_idx = rns.selected_sequence_index
  self:do_capture_once(patt_sel.start_track,seq_idx)

  local rslt,err = self:do_collect(nil,nil,patt_sel)
  if not rslt then
    return false,err
  end

end

--------------------------------------------------------------------------------
-- collect phrases from the matrix selection
-- @return bool
-- @return string (error message)

function PhraseMate:collect_from_matrix_selection()
  TRACE("PhraseMate:collect_from_matrix_selection()")

  local matrix_sel,err = xSelection.get_matrix_selection()
  if table.is_empty(matrix_sel) then
    return false,"No selection is defined in the matrix"
  end

  local create_keymap = self.prefs.create_keymappings.value
  for seq_idx = 1, #rns.sequencer.pattern_sequence do
    if matrix_sel[seq_idx] then
      for trk_idx = 1, #rns.tracks do
        if matrix_sel[seq_idx][trk_idx] then
          self:do_capture_once(trk_idx,seq_idx)
          local rslt,err = self:do_collect(seq_idx,trk_idx)
          if not rslt then
            return false,err
          end

        end
      end
      --self:progress_handler(("Collecting phrases : sequence index = %d, track index = %d"):format(seq_idx,trk_idx))
      self:collect_yield_fn(seq_idx)
    end
  end

  self:do_finalize()

end

--------------------------------------------------------------------------------
-- collect phrases from the selected pattern-track 
-- @return bool
-- @return string (error message)

function PhraseMate:collect_from_track_in_pattern()
  TRACE("PhraseMate:collect_from_track_in_pattern()")

  local trk_idx = rns.selected_track_index
  local seq_idx = rns.selected_sequence_index
  self:do_capture_once(trk_idx,seq_idx)

  local rslt,err = self:do_collect()
  if not rslt then
    return false,err
  end

end

--------------------------------------------------------------------------------
-- collect phrases from the selected track in the song
-- @return bool
-- @return string (error message)

function PhraseMate:collect_from_track_in_song()
  TRACE("PhraseMate:collect_from_track_in_song()")

  local trk_idx = rns.selected_track_index

  for seq_idx = 1, #rns.sequencer.pattern_sequence do
    self:do_capture_once(trk_idx,seq_idx)
    local rslt,err = self:do_collect(seq_idx)
    if not rslt then
      return false,err
    end

    --self:progress_handler(("Collecting phrases : sequence index = %d"):format(seq_idx))
    self:collect_yield_fn(seq_idx)
  end

end

--------------------------------------------------------------------------------
-- invoked as we travel through pattern-tracks...
-- @param seq_idx (int)
-- @param trk_idx (int)
-- @param patt_sel (table), specified when doing SELECTION_IN_PATTERN
-- @return bool, true when collected
-- @return string, error message when failed

function PhraseMate:do_collect(seq_idx,trk_idx,patt_sel)
  TRACE("PhraseMate:do_collect(seq_idx,trk_idx,patt_sel)",seq_idx,trk_idx,patt_sel)

  if not seq_idx then
    seq_idx = rns.selected_sequence_index
  end
  if not trk_idx then
    trk_idx = rns.selected_track_index
  end

  local track = rns.tracks[trk_idx]
  local patt_idx = rns.sequencer:pattern(seq_idx)
  local patt = rns.patterns[patt_idx]
  local ptrack = patt:track(trk_idx)

  -- encountering the same pattern-track can happen when processing
  -- a song whose sequence contain pattern-aliases
  if not self.processed_ptracks[patt_idx] then
    self.processed_ptracks[patt_idx] = {}
  end
  if self.processed_ptracks[patt_idx][trk_idx] then
    local msg = "(At sequence #%.2d: We've already processed this pattern, skip..."
    return false,msg:format(seq_idx)
  end

  if not patt_sel then
    patt_sel = xSelection.get_pattern_track(seq_idx,trk_idx)
  end
  --print("*** patt_sel",rprint(patt_sel))

  -- make sure ghost columns are initialized
  if not self.ghost_columns[trk_idx] then
    self.ghost_columns[trk_idx] = {}
  end

  -- loop through pattern, create phrases/instruments as needed
  local patt_lines = rns.pattern_iterator:lines_in_pattern_track(patt_idx,trk_idx)
  local target_phrase,target_phrase_idx_or_err = nil
  for pos, line in patt_lines do
    if pos.line > patt_sel.end_line then break end
    if pos.line >= patt_sel.start_line then

        local phrase_line_idx = pos.line - (patt_sel.start_line-1)

        -- iterate through note-columns
        for note_col_idx,note_col in ipairs(line.note_columns) do

          if (note_col_idx > track.visible_note_columns) then
            --print("*** do_collect - skip hidden note-column",note_col_idx)
          else
            --print("*** do_collect - seq_idx",seq_idx,"trk_idx",trk_idx,"note_col_idx",note_col_idx,"pos.line",pos.line)

            local instr_value = note_col.instrument_value
            local has_instr_value = (instr_value < 255)
            local capture_all = (self.prefs.input_source_instr.value == PhraseMate.SOURCE_INSTR.CAPTURE_ALL)

            -- before switching instrument/phrase, produce a note-off
            -- (unless a note-off was already detected)
            if has_instr_value and target_phrase then
              local do_note_off = false
              if capture_all 
                and self.ghost_columns[trk_idx][note_col_idx]
                and (instr_value+1 ~= self.ghost_columns[trk_idx][note_col_idx].instrument_index)
              then
                --print("*** do_collect - produce a note-off ('capture_all')")
                do_note_off = true
                self:set_source_instr(self.ghost_columns[trk_idx][note_col_idx].instrument_index)
                self:allocate_target_instr()
                target_phrase,target_phrase_idx_or_err = self:allocate_phrase(track,seq_idx,trk_idx,patt_sel)
              elseif (self.source_instr_idx ~= instr_value+1)
                and self.ghost_columns[trk_idx][note_col_idx]
                and (self.source_instr_idx == self.ghost_columns[trk_idx][note_col_idx].instrument_index)
              then
                --print("*** do_collect - produce a note-off ('fixed' instrument)")
                do_note_off = true
              end
              if do_note_off 
                and self.ghost_columns[trk_idx][note_col_idx]
                and not self.ghost_columns[trk_idx][note_col_idx].offed
              then
                local phrase_col = target_phrase:line(phrase_line_idx).note_columns[note_col_idx]
                phrase_col.note_value = renoise.PatternLine.NOTE_OFF
              end
            end

            -- do we need to change source/create instruments on the fly? 
            if capture_all then
              self.source_instr_idx = nil
              if has_instr_value then
                --print("*** do_collect - has_instr_value - switch to source instrument...")
                self:set_source_instr(instr_value+1)
                target_phrase = nil
              elseif self.ghost_columns[trk_idx][note_col_idx] then
                --print("*** do_collect - let ghost columns decide source instrument...trk_idx,note_col_idx",trk_idx,rprint(self.ghost_columns))
                self:set_source_instr(self.ghost_columns[trk_idx][note_col_idx].instrument_index)
                target_phrase = nil
              end
            end

            -- initialize the phrase
            -- will work only when we have an active voice (self.ghost_columns)
            if not target_phrase 
              and self.source_instr_idx
              and not ptrack.is_empty
            then
              self:allocate_target_instr()
              target_phrase,target_phrase_idx_or_err = self:allocate_phrase(track,seq_idx,trk_idx,patt_sel)
              --print("*** do_collect - allocated phrase",target_phrase_idx_or_err,target_phrase)
              if not target_phrase then
                self.allocation_error_msg = target_phrase_idx_or_err
              end
            end

            if target_phrase then

              local phrase_col = target_phrase:line(phrase_line_idx).note_columns[note_col_idx]
              --print("phrase_col",phrase_col)

              --print("*** do_collect - self.ghost_columns PRE",rprint(self.ghost_columns))
              if (instr_value < 255) then
                self.ghost_columns[trk_idx][note_col_idx] = {}
                self.ghost_columns[trk_idx][note_col_idx].instrument_index = instr_value+1
                --print("*** added self.ghost_columns",rprint(self.ghost_columns))
              end
              if (note_col.note_value == renoise.PatternLine.NOTE_OFF) then
                if self.ghost_columns[trk_idx][note_col_idx] then
                  self.ghost_columns[trk_idx][note_col_idx].offed = true
                end
              end
              --print("*** do_collect - self.ghost_columns POST",rprint(self.ghost_columns))

              -- copy note-column when we have an active (ghost-)note 
              local do_copy = capture_all and self.ghost_columns[trk_idx][note_col_idx] or
                (self.ghost_columns[trk_idx][note_col_idx] 
                and (self.ghost_columns[trk_idx][note_col_idx].instrument_index == self.source_instr_idx))
  
              if (do_copy) then
                local is_trigger,msg = self:note_is_phrase_trigger(line,note_col_idx,self.source_instr_idx,trk_idx)
                if is_trigger and msg then
                  --renoise.app():show_message(msg)
                  self.collected_messages[msg] = true
                else
                  phrase_col:copy_from(note_col)                
                  --print("*** do_collect - copied this column",note_col)
                  if self.prefs.input_replace_collected.value then
                    note_col:clear()
                  end
                end
              end

            end
          
          end

        end

        -- fx columns are always copied
        -- TODO allocate phrase here as well (when in group/master/send track)
        if target_phrase then
          for fx_col_idx,fx_col in ipairs(line.effect_columns) do

            -- extra check: skip track (Zxxx) and global commands (0xxx-Fxxx)
            local do_copy = true
            local first_digit = tonumber(fx_col.number_string:sub(0,1))
            if (fx_col.number_string:sub(0,1) == "Z")
              or ((type(first_digit)=="number")
              and (first_digit > 0))
            then
              do_copy = false
              --LOG("*** do_collect - skip track/global command",fx_col)
            end

            if do_copy then
              local phrase_col = target_phrase:line(phrase_line_idx).effect_columns[fx_col_idx]
              phrase_col:copy_from(fx_col)
              if self.prefs.input_replace_collected.value then
                fx_col:clear()
              end
            end
          end
        end

      --end
    end
  end

  self.processed_ptracks[patt_idx][trk_idx] = true

  --self:progress_handler(("Collecting phrases : sequence index = %d, track index = %d"):format(seq_idx,trk_idx))
  self:collect_yield_fn(seq_idx,trk_idx)

  return true

end

--------------------------------------------------------------------------------
-- collect: post-process / finalize 

function PhraseMate:do_finalize()
  TRACE("PhraseMate:do_finalize()")

  local collected_phrase_count = 0
  local collected_instruments = {}
  local delete_instruments = {} -- table<[instrument_index]=bool>
  local empty_phrases = {}     -- table<[instrument_index]={phrase_index,...}>

  -- table<[instrument_index]={
  --    {
  --      source_phrase_index=int,
  --      target_phrase_index=int,
  --    },
  --  }>
  local duplicate_phrases = {}  

  --print("*** post-process - self.collected_phrases",rprint(self.collected_phrases))
  --print("*** post-process - self.collected_phrases",rprint(table.keys(self.collected_phrases)))
  if (#table.keys(self.collected_phrases) == 0) then

    local msg = "No phrases were collected"
    self.collected_messages[msg] = true

  else

    local cached_instr_idx = rns.selected_instrument_index

    for instr_idx,collected in pairs(self.collected_phrases) do
      --print("*** post-process - instr_idx,collected",instr_idx,collected)
      for __,v in pairs(collected) do

        local instr = rns.instruments[v.instrument_index]
        if not instr then
          --LOG("Skip collected phrase - instrument not found...",rprint(v))
        else
          -- check for duplicates 
          if not self.prefs.input_include_duplicate_phrases.value 
            and not duplicate_phrases[v.instrument_index]
          then
            duplicate_phrases[v.instrument_index] = xPhraseManager.find_duplicates(instr)
            --print(">>> post-process - duplicate_phrases @instr-index",v.instrument_index,rprint(duplicate_phrases[v.instrument_index]))
          end

          -- remove instrument when without phrases
          if (self.prefs.input_target_instr.value == PhraseMate.TARGET_INSTR.NEW) 
            and (#instr.phrases == 0)
          then
            delete_instruments[v.instrument_index] = true
          else

            local phrase_idx = v.phrase_index

            collected_instruments[v.instrument_index] = true
            local phrase = instr.phrases[phrase_idx]
              
            -- TODO don't process if we are going to remove 
            -- the (empty,duplicate) phrase anyway

            if phrase then

              --print("*** post-process - phrase,instr",phrase.name,instr.name)

              xPhrase.clear_foreign_commands(phrase)

              -- remove empty phrases
              if phrase.is_empty 
                and not self.prefs.input_include_empty_phrases.value
              then
                if not empty_phrases[v.instrument_index] then
                  empty_phrases[v.instrument_index] = {}
                end
                table.insert(empty_phrases[v.instrument_index],phrase_idx)
                --print("got here 1")

              else
                collected_phrase_count = collected_phrase_count+1
                --print("got here 2")

                if not self.prefs.input_include_duplicate_phrases.value then
                  -- check if phrase is a duplicate and use source instead
                  -- (as duplicates will be removed)
                  if duplicate_phrases[v.instrument_index] then
                    for k2,v2 in ipairs(duplicate_phrases[v.instrument_index]) do
                      if (v2.target_phrase_index == phrase_idx) then
                        --print("This phrase is a duplicate - use source",rprint(v2))
                        phrase_idx = v2.source_phrase_index
                        phrase = instr.phrases[phrase_idx]
                      end
                    end
                  end
                end

                -- replace notes with phrase trigger 
                -- (if multiple instruments, each is a separate note-column)
                if self.prefs.input_replace_collected.value then
                  local track = rns.tracks[v.track_index]
                  local patt_idx = rns.sequencer:pattern(v.sequence_index)
                  local patt_lines = rns.pattern_iterator:lines_in_pattern_track(patt_idx,v.track_index)
                  for ___,line in patt_lines do
                    
                    -- allocate column
                    local col_idx = 1
                    for k,note_col in ipairs(line.note_columns) do
                      if (note_col.effect_number_string ~= "0Z") then
                        col_idx = k
                        track.visible_note_columns = math.max(track.visible_note_columns,k)
                        break
                      end
                    end
                    --print("*** replace notes, create trigger in column",col_idx)

                    local trigger_note_col = line.note_columns[col_idx]
                    trigger_note_col.instrument_value = v.instrument_index-1
                    trigger_note_col.note_string = "C-4"
                    trigger_note_col.effect_number_string = "0Z"
                    trigger_note_col.effect_amount_value = phrase_idx
                    track.sample_effects_column_visible = true
                    break
                  end
                end

              end

              -- bring the phrase editor to front for all created instruments 
              instr.phrase_editor_visible = true

              -- switch to the relevant playback mode
              if self.prefs.create_keymappings.value then
                instr.phrase_playback_mode = renoise.Instrument.PHRASES_PLAY_KEYMAP
              end

            end

          end

        end


      end
    end

    if (self.prefs.input_target_instr.value == PhraseMate.TARGET_INSTR.NEW) then
      rns.selected_instrument_index = self.target_instr_idx
    end
    if (#rns.selected_instrument.phrases > 0) then
      rns.selected_phrase_index = #rns.selected_instrument.phrases
    end

    -- remove from table while maintaining phrase-index order 
    -- @param t - 
    --  empty_phrases (look for table indices) 
    --  duplicate_phrases (look for 'target_phrase_index' property)
    -- @return int, #removed phrases
    local remove_phrases_via_table = function(t)
      --print("remove_phrases_via_table - t",rprint(t))
      local count = 0
      for instr_idx,v in pairs(t) do
        local instr = rns.instruments[instr_idx]
        if instr then
          for __,phrase_idx in pairs(v) do
            --print("type(phrase_idx)",type(phrase_idx),rprint(phrase_idx))
            if type(phrase_idx)=="table" then
              -- special treatment for 'duplicate_phrases'
              phrase_idx = phrase_idx.target_phrase_index
            end
            --print("instr.phrases[phrase_idx]",phrase_idx,instr.phrases[phrase_idx])
            if instr.phrases[phrase_idx] then
              instr:delete_phrase_at(phrase_idx)
              count = count+1
              -- adjust phrase indices
              for k2,v2 in pairs(v) do
                if type(v2)=="table" then
                  --print(">>> duplicate_phrases")
                  if (v2.target_phrase_index > phrase_idx) then
                    v[k2].target_phrase_index = v2.target_phrase_index-1
                    --print(">>> bring target phrase down")
                  end
                  if (v2.source_phrase_index > phrase_idx) then
                    v[k2].source_phrase_index = v2.source_phrase_index-1
                    --print(">>> bring source phrase down")
                  end
                else
                  --print(">>> empty_phrases")
                  if (v2 > phrase_idx) then
                    v[k2] = v2-1
                    --print(">>> bring phrase down")
                  end
                end
              end
            end
          end
        end
      end
      return count
    end

    -- remove duplicate/empty phrases
    local empty_phrase_count = remove_phrases_via_table(empty_phrases)
    local duplicate_phrase_count = remove_phrases_via_table(duplicate_phrases)

    collected_phrase_count = collected_phrase_count-
      (empty_phrase_count+duplicate_phrase_count)

    -- remove newly created instruments without phrases
    if not table.is_empty(delete_instruments) then
      for k = 127,1,-1 do
        if delete_instruments[k] then
          --print("*** post-process - delete instrument at",k)
          rns:delete_instrument_at(k)
          collected_instruments[k] = false
        end
      end
      rns.selected_instrument_index = cached_instr_idx
    end

    local msg_include_empty = self.prefs.input_include_empty_phrases.value
      and "" or (#table.keys(empty_phrases) > 0) and ("\nEmpty phrases skipped: %d "):format(empty_phrase_count) or ""
    --print("msg_include_empty",msg_include_empty)

    local msg_include_duplicates = self.prefs.input_include_duplicate_phrases.value
      and "" or (#table.keys(duplicate_phrases) > 0) and ("\nDuplicate phrases skipped: %d "):format(duplicate_phrase_count) or ""
    --print("msg_include_duplicates",msg_include_duplicates)

    local msg_error = self.allocation_error_msg 
      and "\n\nOne or more errors was encountered during collection:\n"
        ..self.allocation_error_msg 
      or ""

    local msg = ("Created a total of %d phrase(s) across %d instrument(s)%s%s%s"):format(
      collected_phrase_count,#table.keys(collected_instruments),msg_include_empty,msg_include_duplicates,msg_error)
    self.collected_messages[msg] = true

  end

  if not table.is_empty(self.collected_messages) then
    local msg = table.concat(table.keys(self.collected_messages),"\n")
    self:done_handler(msg)
  end

end

--------------------------------------------------------------------------------
-- Output methods
--------------------------------------------------------------------------------
-- @param start_col - note/effect column index
-- @param end_col - note/effect column index
-- @param start_line - pattern line
-- @param end_line - pattern line
-- @return boolean, true when applied
-- @return string, error message when failed

function PhraseMate:apply_to_track(sel)
  TRACE("PhraseMate:apply_to_track(sel)",sel)

  if not rns.selected_phrase then
    return false,"No phrase was selected"
  end

  local options = {
    instr_index = rns.selected_instrument_index,
    phrase = rns.selected_phrase,
    sequence_index = rns.selected_sequence_index,
    track_index = sel and sel.start_track or rns.selected_track_index,
    anchor_to_selection = self.prefs.anchor_to_selection.value,
    cont_paste = self.prefs.cont_paste.value,
    skip_muted = self.prefs.skip_muted.value,
    expand_columns = self.prefs.expand_columns.value,
    expand_subcolumns = self.prefs.expand_subcolumns.value,
    insert_zxx = self.prefs.output_insert_zxx.value,
    mix_paste = self.prefs.mix_paste.value,
    selection = sel,
  }

  self.suppress_line_notifier = true
  --self:invoke_sliced_task(xPhrase.apply_to_track,options)
  xPhrase.apply_to_track(options)
  self.suppress_line_notifier = false

  return true

end

--------------------------------------------------------------------------------
-- @return boolean, true when applied
-- @return string, error message when failed

function PhraseMate:apply_to_selection()
  TRACE("PhraseMate:apply_to_selection()")

  local sel,err = xSelection.get_pattern_if_single_track()
  if not sel then
    return false,err
  end

  return self:apply_to_track(sel)

end

--------------------------------------------------------------------------------
-- insert temp phrase, load preset and write 
-- @param source (PhraseMate.OUTPUT_MODE)
-- @param fpath (string), full path to .xrnz file
-- @return boolean, true when applied
-- @return string, error message when failed

function PhraseMate:apply_external_phrase(mode,fpath)
  TRACE("PhraseMate:apply_external_phrase(mode,fpath)",mode,fpath)

  --print("*** apply_external_phrase - fpath",fpath)
  if not io.exists(fpath) then
    return false,"Could not locate phrase"
  end

  local cached_phrase_idx = rns.selected_phrase_index
  local instr_idx = rns.selected_instrument_index
  local phrase,phrase_idx_or_err = xPhraseManager.auto_insert_phrase(instr_idx)
  --print("*** apply_external_phrase - phrase,phrase_idx_or_err",phrase,phrase_idx_or_err)
  if not phrase then
    return false,phrase_idx_or_err
  end

  local function cleanup()
    local rslt,err = self:delete_phrase(phrase_idx_or_err)
    if not rslt then
      return false,err
    end
    --print("*** apply_external_phrase - done")
    rns.selected_phrase_index = cached_phrase_idx
    return true
  end

  rns.selected_phrase_index = phrase_idx_or_err

  renoise.app():load_instrument_phrase(fpath)

  local rslt,err
  if (mode == PhraseMate.OUTPUT_MODE.SELECTION) then
    rslt,err = self:apply_to_selection()
  elseif (mode == PhraseMate.OUTPUT_MODE.TRACK) then
    rslt,err = self:apply_to_track()
  else
    error("Unsupported output mode")
  end
  if not rslt then
    cleanup()
    return false,err
  end

  return cleanup()

end


--------------------------------------------------------------------------------
-- Realtime methods
--------------------------------------------------------------------------------

function PhraseMate:line_notifier_fn(pos)
  TRACE("PhraseMate:line_notifier_fn(pos)",pos)

  --print("self",self)

  if not self.prefs.zxx_mode.value then
    return
  end

  if not self.suppress_line_notifier then
    table.insert(self.modified_lines,pos)
    --print("modified_lines",#self.modified_lines)
  end
end

--------------------------------------------------------------------------------

function PhraseMate:handle_modified_line(pos)
  TRACE("PhraseMate:handle_modified_line(pos)",pos)

  local patt = rns.patterns[pos.pattern]
  local ptrack = patt:track(pos.track)
  local line = ptrack:line(pos.line)
  local instr = rns.selected_instrument
  local has_phrases = (#instr.phrases > 0)
  local program_mode = (instr.phrase_playback_mode == renoise.Instrument.PHRASES_PLAY_SELECTIVE)

  local matching_note = nil

  for k,note_col in ipairs(line.note_columns) do
    if (note_col.instrument_value == rns.selected_instrument_index-1) then
      matching_note = {
        note_column_index = k,
      }
      break
    end
  end
  --print("matching_note",rprint(matching_note))

  if matching_note and has_phrases and program_mode then
    --print("add Zxx command")
    for k,fx_col in ipairs(line.effect_columns) do
      local has_zxx_command = (fx_col.number_string == "0Z")
      if has_zxx_command then
        --print("existing zxx command",fx_col.amount_value)
        local where_we_were = rns.transport.edit_pos.line - rns.transport.edit_step
        if (pos.line == where_we_were) then
          local num_phrases = #rns.selected_instrument.phrases
          local zxx_command_value = has_zxx_command and fx_col.amount_value or rns.selected_phrase_index
          fx_col.number_string = "0Z"
          fx_col.amount_value = zxx_command_value
        else
          --print("got here")
        end
        break
      elseif fx_col.is_empty then
        --print("no zxx - add selected")
        fx_col.number_string = "0Z"
        fx_col.amount_value = rns.selected_phrase_index
        break
      end
    end

  elseif not matching_note then
    --print("clear Zxx command")
    local zxx_command = nil
    for k,fx_col in ipairs(line.effect_columns) do
      if (fx_col.number_string == "0Z") then
        zxx_command = {
          effect_column_index = k,
        }
        break
      end
    end
    if zxx_command then
      if zxx_command.note_column_index then
        --line.note_columns[zxx_command.note_column_index].effect_amount_value = 0
        --line.note_columns[zxx_command.note_column_index].effect_number_value = 0
      elseif zxx_command.effect_column_index then
        line.effect_columns[zxx_command.effect_column_index].amount_value = 0
        line.effect_columns[zxx_command.effect_column_index].number_value = 0
      end
    end

  end

end

--------------------------------------------------------------------------------

function PhraseMate:attach_to_pattern()
  TRACE("PhraseMate:attach_to_pattern()")

  self.modified_lines = {}
  local pattern = rns.selected_pattern
  if not pattern:has_line_notifier(self.line_notifier_fn,self) then
    pattern:add_line_notifier(self.line_notifier_fn,self)
  end

end

--------------------------------------------------------------------------------

function PhraseMate:attach_to_song()
  TRACE("PhraseMate:attach_to_song()")

  cObservable.attach(rns.selected_pattern_observable,self.attach_to_pattern,self)
  self:attach_to_pattern()

end

--------------------------------------------------------------------------------
-- Batch/Properties
--------------------------------------------------------------------------------
-- set phrase properties based on operator 
-- @param prop_name (string)
-- @param operator (vEditField.OPERATOR)
-- @param operator_value (boolean,string or number)
-- @return bool, true when properties were modified
-- @return string, error message when failed

function PhraseMate:apply_properties(instr,prop_name,operator,operator_value,phrase_indices)
  TRACE("PhraseMate:apply_properties(instr,prop_name,operator,operator_value,phrase_indices)",instr,prop_name,operator,operator_value,phrase_indices)

  for k,v in ipairs(phrase_indices) do
    local phrase = instr.phrases[v]
    if not phrase then
      return false,"Can't set property, missing phrase"
    end

    
    local prop,prop_idx = cDocument.get_property(xPhrase.DOC_PROPS,prop_name)
    local cval = cLib.create_cvalue(prop)
    local prop_val = cval.zero_based and phrase[prop_name]-1 or phrase[prop_name]
    cval.value = prop_val

    if (operator == vEditField.OPERATOR.SET) then
      cval.value = operator_value
    elseif (operator == vEditField.OPERATOR.ADD) then
      cval:add(operator_value)
    elseif (operator == vEditField.OPERATOR.SUB) then
      cval:subtract(operator_value)
    elseif (operator == vEditField.OPERATOR.MUL) then
      cval:multiply(operator_value)
    elseif (operator == vEditField.OPERATOR.DIV) then
      cval:divide(operator_value)
    elseif (operator == vEditField.OPERATOR.INVERT) then
      error("Not implemented")
    end

    xPhrase.set_property(phrase,prop_name,cval.value)

  end

  return true

end

--------------------------------------------------------------------------------
-- Import/Export
--------------------------------------------------------------------------------

function PhraseMate:import_presets(files)
  TRACE("PhraseMate:import_presets(files)",files)

  local instr_idx = rns.selected_instrument_index
  local insert_at_idx = rns.selected_phrase_index+1
  local takeover = false
  local keymap_args = self.prefs.create_keymappings.value and {
    keymap_range = self.prefs.create_keymap_range.value,
    keymap_offset = self.prefs.create_keymap_offset.value,
  }

  local rslt,err = xPhraseManager.import_presets(files,instr_idx,insert_at_idx,takeover,keymap_args)
  if err then
    return false,err
  end

end

--------------------------------------------------------------------------------
-- @return bool, true when presets were exported
-- @return string, error message when failed

function PhraseMate:export_presets(indices,overwrite)
  TRACE("PhraseMate:export_presets(indices,overwrite)",indices,overwrite)

  --print("*** export_presets - self.prefs.output_folder.value",self.prefs.output_folder.value)

  if (self.prefs.output_folder.value == "") then
    return false,"Please select a valid output path"
  end

  overwrite = overwrite or self.prefs.overwrite_on_export.value
  --print("*** export_presets - overwrite",overwrite)

  local prefix = self.prefs.prefix_with_index.value
  local folder = self.prefs.output_folder.value
  local instr_idx = rns.selected_instrument_index
  --print("*** export_presets - prefix",prefix)
  --print("*** export_presets - folder",folder)
  --print("*** export_presets - instr_idx",instr_idx)

  local use_subfolder = self.prefs.use_instr_subfolder.value
  if use_subfolder then
    folder = folder .. cFilesystem.sanitize_filename(rns.selected_instrument.name) .. "/"
  end

  local rslt,err,indices = xPhraseManager.export_presets(folder,instr_idx,indices,overwrite,prefix)
  if err then
    return false, err
  end

  return true

end
