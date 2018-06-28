--[[============================================================================
SliceMate
============================================================================]]--
--[[

SliceMate - main application
.
#

]]

class 'SliceMate'

---------------------------------------------------------------------------------------------------

function SliceMate:__init(...)
  TRACE("SliceMate:__init()")

  local args = cLib.unpack_args(...)

  --- SliceMate_Prefs, current settings
  self.prefs = renoise.tool().preferences

  --- the name of the application (dialog title)
  self.app_display_name = args.app_display_name

  -- number, number of samples that control slice "snapping"
  self.slice_snap_threshold = 200

  -- 'focused' instrument (0 = none)
  self.instrument_index = renoise.Document.ObservableNumber(0)

  -- instr. status (empty string means no problems)
  self.instrument_status = renoise.Document.ObservableString("")
  self.slice_index = renoise.Document.ObservableNumber(-1)

  -- the computed slice and root positions (in frames)
  self.position_slice = renoise.Document.ObservableNumber(-1)
  self.position_root = renoise.Document.ObservableNumber(-1)
  -- the computed phrase index and line position 
  self.phrase_index = renoise.Document.ObservableNumber(-1)
  self.phrase_line = renoise.Document.ObservableNumber(-1)
  -- the edited pattern (bound with line notifiers)
  self.pattern_index = renoise.Document.ObservableNumber(-1)

  -- used for determining when to update 
  -- renoise.songpos (either playpos or editpos)
  self.cursor_pos = nil
  self.track_idx = nil
  self.notecol_idx = nil

  -- delayed execution (idle updates)
  self.select_requested = false

  -- contains our observable sample properties 
  self._sample_observables = table.create()

  -- contains our observable instr. properties 
  self._instrument_observables = table.create()

  -- contains our observable song properties 
  self._song_observables = table.create()


  -- initialize ---------------------------------

  -- apply some defaults
  xSongPos.DEFAULT_BOUNDS_MODE = xSongPos.OUT_OF_BOUNDS.LOOP
  xSongPos.DEFAULT_LOOP_MODE = xSongPos.LOOP_BOUNDARY.SOFT
  xSongPos.DEFAULT_BLOCK_MODE = xSongPos.BLOCK_BOUNDARY.SOFT

  --- configure user-interface
  self.ui = SliceMate_UI{
    dialog_title = self.app_display_name,
    owner = self,
    waiting_to_show_dialog = args.show_dialog,
  }

  -- comparison function for xNoteCapture - 
  -- match notes in the pattern which also specifies an instrument 
  self.compare_fn = function(notecol)
    local matched = false 
    local match_note = true
    local match_instr = true
    local match_all = true -- need both note AND instrument
    if match_note then
      if match_all and matched then
        return true
      else
        matched = notecol.note_value < 121
      end
    end
    if match_instr then
      if match_all and matched then
        return true
      else
        matched = notecol.instrument_value < 255
      end
    end
    return matched
  end

  -- notifications ------------------------------

  renoise.tool().app_new_document_observable:add_notifier(function()
    rns = renoise.song()
  end)

  renoise.tool().app_idle_observable:add_notifier(function()
    self:on_idle()
  end)
  
  self.prefs.support_phrases:add_notifier(function()
    self.select_requested = true
  end)

  self.prefs.autoselect_instr:add_notifier(function()
    self:on_idle()
  end)

  self.prefs.autoselect_in_wave:add_notifier(function()
    self.cursor_pos = nil
    self:on_idle()
  end)

  self.prefs.autoselect_in_list:add_notifier(function()
    self:on_idle()
  end)

  self.prefs.quantize_enabled:add_notifier(function()
    self.cursor_pos = nil
    self:on_idle()
  end)

  self.prefs.quantize_amount:add_notifier(function()
    self.cursor_pos = nil
    self:on_idle()
  end)

  self.slice_index:add_notifier(function()    
    self:attach_to_sample()
  end)

  self.instrument_index:add_notifier(function()    
    self:attach_to_instrument()
  end)

  renoise.tool().app_new_document_observable:add_notifier(function()
    self:attach_to_song()
  end)

  -- initialize -----------------------

  self.ui:build()
  self.cursor_pos = self:get_cursor()

  self:attach_to_song()
  self:attach_to_pattern()
  self:attach_to_sample()

end

---------------------------------------------------------------------------------------------------
-- @return Renoise.SongPos

function SliceMate:get_cursor()
  --TRACE("SliceMate:get_cursor()")

  if (rns.transport.playing) then
    return rns.transport.playback_pos
  else 
    return rns.transport.edit_pos
  end
end

---------------------------------------------------------------------------------------------------
-- obtain current values based on cursor-position
-- @param user_selected (boolean), when true we update the selected instr/sample/etc.

function SliceMate:select(user_selected)
  TRACE("SliceMate:select(user_selected)",user_selected)

  local cursor_pos = self:get_position()
  local trigger_pos = xNoteCapture.nearest(self.compare_fn)
  if not trigger_pos then
    self.instrument_status.value = ""
    self.instrument_index.value = 0  
  else
    -- (attempt to) determine position in phrase 
    local rslt,err = self:get_phrase_position(trigger_pos,cursor_pos)
    if (rslt ~= nil) then 
      self.position_slice.value = -1
      self.slice_index.value = -1    
      self.phrase_index.value = rslt.phrase_index 
      self.phrase_line.value = rslt.phrase_line
      self.instrument_status.value = ""
      self.instrument_index.value = rslt.instrument_index
      -- select instrument
      if user_selected or self.prefs.autoselect_instr.value then
        rns.selected_instrument_index = rslt.instrument_index
      end      
    else 
      -- no phrase, determine position in sample buffer 
      self.phrase_index.value = -1
      self.phrase_line.value = -1
      local frame,sample_idx,instr_idx,notecol = self:get_buffer_position(trigger_pos,cursor_pos)
      if not frame and sample_idx then
        -- failed - display reason
        local notecol = trigger_pos:get_column()
        self.position_slice.value = -1
        self.slice_index.value = -1
        self.instrument_status.value = sample_idx -- error message
        self.instrument_index.value = notecol and notecol.instrument_value+1 or 0      
      elseif sample_idx then
        local instr = rns.instruments[instr_idx]
        if user_selected or self.prefs.autoselect_instr.value then
          rns.selected_instrument_index = instr_idx
        end
        if user_selected or self.prefs.autoselect_in_list.value then
          if (rns.selected_instrument_index == instr_idx) then
            rns.selected_sample_index = sample_idx
          end
        end -- /autoselect_in_list
        -- compute 'root' frame 
        local root_frame = 0
        if (sample_idx > 1) then
          root_frame = xInstrument.get_slice_marker_by_sample_idx(instr,sample_idx)
        end
        self.position_root.value = math.ceil(frame+root_frame) 
        self.position_slice.value = math.ceil(frame)
        self.slice_index.value = frame and sample_idx-1 
        if user_selected or self.prefs.autoselect_in_wave.value then
          local sample = instr.samples[sample_idx]
          if (rns.selected_sample_index == 1) then
            frame = frame + root_frame
            sample = instr.samples[1]
          end
          local success,error = xSample.set_buffer_selection(sample,frame,frame)
          if error then
            renoise.app():show_status(error)
          end
        self.instrument_status.value = ""
        self.instrument_index.value = instr_idx 
        end -- /autoselect_in_wave
      end
    end 
  end 
end                  

---------------------------------------------------------------------------------------------------
-- 

function SliceMate:remove_active_slice()

  if (self.instrument_index.value == 0) then 
    return false,"No active instrument to remove slice from"
  end 

  if (self.slice_index.value == -1) then 
    return false,"No active slice to remove"
  end

  if (self.slice_index.value < 1) then 
    return false,"Can't remove root sample"
  end
  
  local instr = self:get_instrument()
  local sample = instr and instr.samples[1]
  if not instr or not sample then 
    return 
  end   

  local marker_pos = xInstrument.get_slice_marker_by_sample_idx(instr,self.slice_index+1)
  if marker_pos then
    sample:delete_slice_marker(marker_pos)
  end

end

---------------------------------------------------------------------------------------------------

function SliceMate:previous_column()
  TRACE("SliceMate:previous_column()")

  xColumns.previous_note_column()
  self.select_requested = true
end

---------------------------------------------------------------------------------------------------

function SliceMate:next_column()
  TRACE("SliceMate:next_column()")

  xColumns.next_note_column()
  self.select_requested = true
end

---------------------------------------------------------------------------------------------------

function SliceMate:previous_note()
  TRACE("SliceMate:previous_note()")

  local trigger_pos = xNoteCapture.previous(self.compare_fn)
  if trigger_pos then
    trigger_pos:select()
    self.select_requested = true
  end
end

---------------------------------------------------------------------------------------------------

function SliceMate:next_note()
  TRACE("SliceMate:next_note()")

  local trigger_pos = xNoteCapture.next(self.compare_fn)
  if trigger_pos then
    trigger_pos:select()
    self.select_requested = true
  end
end

---------------------------------------------------------------------------------------------------

function SliceMate:previous_line()
  TRACE("SliceMate:previous_line()")

  xPatternPos.jump_to_previous_line()
  self.select_requested = true
end

---------------------------------------------------------------------------------------------------

function SliceMate:next_line()
  TRACE("SliceMate:next_line()")

  xPatternPos.jump_to_next_line()
  self.select_requested = true
end

---------------------------------------------------------------------------------------------------

function SliceMate:detach_sampler()
  TRACE("SliceMate:detach_sampler()")

  local enum_sampler = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
  local middle_frame = renoise.app().window.active_middle_frame
  renoise.app().window.instrument_editor_is_detached = true
  renoise.app().window.active_middle_frame = enum_sampler
  renoise.app().window.active_middle_frame = middle_frame

end

---------------------------------------------------------------------------------------------------
-- determine if we can slice the provided instrument 
-- @param instr (renoise.Instrument) 
-- @param attempt_fix (boolean), attempt to fix problems as they are encountered 
-- @return boolean, true when sliceable/convertable 
-- @return string, error message 

function SliceMate.is_sliceable(instr,attempt_fix)
  TRACE("SliceMate.is_sliceable(instr,attempt_fix)",instr,attempt_fix)

  local instr_name = (instr.name == "") and "Untitled instrument" or instr.name
  local is_sliced = xInstrument.is_sliced(instr)

  if (#instr.samples == 0) or (not is_sliced and #instr.samples > 1) then
    return false, "Instrument needs to contain a single sample,"
      ..("\nbut '%s' contains %d"):format(instr_name,#instr.samples)
  end

  -- Don't trigger via phrase 
  -- TODO allow if available on keyboard while in keymapped mode
  if xInstrument.is_triggering_phrase(instr) then
    return false, "Please avoid using phrases to trigger notes"
  end

  local sample = instr.samples[1]

  if not sample.sample_buffer.has_sample_data then
    return false, "Sample is empty (does not contain audio)"
  end

  if not sample.autoseek then
    if attempt_fix then 
      sample.autoseek = true 
    else
      return false, "Please enable auto-seek on the sample"
    end
  end

  -- TODO support beatsync (different pitch)
  if sample.beat_sync_enabled then
    if attempt_fix then 
      sample.beat_sync_enabled = false 
    else
      return false, "Please disable beat-sync on the sample"
    end
  end

  return true

end

---------------------------------------------------------------------------------------------------
-- obtain current (quantized) position 
-- @return xCursorPos

function SliceMate:get_position()
  TRACE("SliceMate:get_position()")

  local pos = xCursorPos()
  if not self.prefs.quantize_enabled.value then
    return pos
  end

  if not rns.transport.playing  
    or (rns.transport.playing and not rns.transport.follow_player) 
  then 
    xSongPos.decrease_by_lines(1,pos)
  end 

  local choices = {
    [self.prefs.QUANTIZE_AMOUNT.BEAT] = function() xSongPos.next_beat(pos) end,
    [self.prefs.QUANTIZE_AMOUNT.BAR] = function() xSongPos.next_bar(pos) end,
    [self.prefs.QUANTIZE_AMOUNT.BLOCK] = function() xSongPos.next_block(pos) end,
    [self.prefs.QUANTIZE_AMOUNT.PATTERN] = function() xSongPos.next_pattern(pos) end,
    [self.prefs.QUANTIZE_AMOUNT.LINE] = function() xSongPos.increase_by_lines(1,pos) end,
  }

  if (choices[self.prefs.quantize_amount.value]) then 
    choices[self.prefs.quantize_amount.value]()
    pos.line = math.floor(pos.line)
    return pos
  else 
    error("Unexpected quantize amount")
  end

end

---------------------------------------------------------------------------------------------------
-- obtain the sample buffer position from the position of the triggering note / cursor 
-- (perform a few checks before calling the xSample method)
-- @param trigger_pos (xCursorPos)
-- @param cursor_pos (xCursorPos)
-- @param autofix (boolean)
-- @return {
--  frame,
--  sample_idx,
--  instr_idx,
--  notecol
--}

function SliceMate:get_buffer_position(trigger_pos,cursor_pos,autofix)
  TRACE("SliceMate:get_buffer_position(trigger_pos,cursor_pos,autofix)",trigger_pos,cursor_pos,autofix)

  local _patt_idx,_patt,track,_ptrack,line = trigger_pos:resolve()
  if not line then
    return false,"Could not resolve pattern-line"                    
  end

  local notecol = line.note_columns[trigger_pos.column]
  if not notecol then
    return false, "Could not resolve note-column"
  end

  local instr_idx = notecol.instrument_value+1
  local instr = rns.instruments[instr_idx]
  if not instr then
    return false,"Could not resolve instrument"
  end

  -- check if instrument is valid and sliceable
  local is_sliceable,err = SliceMate.is_sliceable(instr,autofix) 
  if not is_sliceable then
    return false, err
  end
  
  -- resolve sample by looking at notecol 
  local sample,sample_idx = nil
  local samples = xKeyZone.get_samples_mapped_to_note(instr,notecol.note_value) 
  if not table.is_empty(samples) then
    sample_idx = samples[1]
  end
  local sample = instr.samples[sample_idx]
  if not sample and autofix then 
    -- don't be so restrictive while autofixing (accept any note)
    sample_idx = 1
    sample = instr.samples[sample_idx]
  end
  if not sample then 
    return false, "Could not resolve sample from note -"
      ..("\nplease ensure that the note (%s) is mapped to a sample"):format(notecol.note_string)
      .."\n(this can be verified from the sampler's keyzone tab)"
  end

  -- ignore Sxx command for root sample 
  local ignore_sxx = (sample_idx == 1) and (#instr.samples > 1) and true or false 

  -- if instr. is sliced and note was a root sample triggered using Sxx, 
  -- we should be looking for a different sample altogether
  if (sample_idx == 1) and (#instr.samples > 0) then 
    local matched_sxx = xLinePattern.get_effect_command(track,line,"0S",trigger_pos.column,true)
    if not table.is_empty(matched_sxx) then 
      local applied_sxx = matched_sxx[#matched_sxx].amount_value
      if (applied_sxx < #instr.samples) then 
        sample_idx = applied_sxx+1
        ignore_sxx = true
      end 
    end 
  end 

  local frame,notecol = 
    xSample.get_buffer_frame_by_notepos(sample,trigger_pos,cursor_pos,ignore_sxx)
  return frame,sample_idx,instr_idx,notecol

end 

---------------------------------------------------------------------------------------------------
-- determine the phrase position/line number at the provided position 
-- @param trigger_pos (xCursorPos)
-- @param cursor_pos (xCursorPos)
-- @return table{
--  phrase_idx: number        -- the phrase index specified by the Zxx command, if any
--  phrase_line: number       -- the resolved phrase line index 
--  note_column_index: number -- the source note-column index 
--  instrument_index: number  -- the source instrument index 
--  zxx_column_index: number  -- the column index of the sxx command, if any
--  sxx_column_index: number  -- the column index of the zxx command
-- } ... or nil when no phrase was matched 

function SliceMate:get_phrase_position(trigger_pos,cursor_pos)
  TRACE("SliceMate:get_phrase_position(trigger_pos,cursor_pos)",trigger_pos,cursor_pos)

  if self.prefs.support_phrases.value then 
    
    local phrase_idx = nil  
    local phrase_offset = 0 
    local zxx_col_idx = nil  
    local sxx_col_idx = nil 
    
    local patt_idx,patt,track,ptrack,line = trigger_pos:resolve()
    if not track then
      return nil,"Could not resolve track"                    
    end
    if not line then
      return nil,"Could not resolve pattern-line"                    
    end
      
    local notecol = line.note_columns[trigger_pos.column]
    if not notecol then
      return nil, "Could not resolve note-column"
    end
  
    local instr_idx = notecol.instrument_value+1
    local instr = rns.instruments[instr_idx]
    if not instr then
      return nil,"Could not resolve instrument"
    end
      
    -- quick check: instr contains phrases? 
    if instr then 
      if (#instr.phrases == 0) then 
        return nil 
      else
        -- examine triggering note:
        
        -- detect explicit Zxx commands
        local visible_only = true -- only search visible columns
        --local notecol_idx = rns.selected_note_column_index
        local zxx_cmd = xLinePattern.get_effect_command(
          track,line,"0Z",trigger_pos.column,visible_only)
        --print("zxx_cmd",rprint(zxx_cmd))
        if not table.is_empty(zxx_cmd) then 
          -- an explicit Zxx command was found 
          -- (prefer note-fx column over fx-column) 
          for k,v in ipairs(zxx_cmd) do 
            if (v.column_type == xEffectColumn.TYPE.EFFECT_NOTECOLUMN) then 
              phrase_idx = v.amount_value
              zxx_col_idx = v.column_index
              break
            end
            phrase_idx = v.amount_value
            zxx_col_idx = v.column_index
          end
        elseif xInstrument.is_triggering_phrase(instr) then 
          -- no zxx - if set to prg/key mode, use the selected phrase 
          -- TODO support key-mapped phrases 
          phrase_idx = xInstrument.get_selected_phrase_index(instr_idx)
        end
        --print("phrase_idx",phrase_idx)

        -- detect offset command 
        local sxx_cmd = xLinePattern.get_effect_command(
          track,line,"0S",trigger_pos.column,visible_only)
        --print("sxx_cmd",rprint(sxx_cmd))
        -- prefer note-fx column over fx-column
        for k,v in ipairs(sxx_cmd) do 
          if (v.column_type == xEffectColumn.TYPE.EFFECT_NOTECOLUMN) then 
            phrase_offset = v.amount_value
            sxx_col_idx = v.column_index
            break
          end
          phrase_offset = v.amount_value
          sxx_col_idx = v.column_index
        end          
        --print("phrase_offset",phrase_offset)
      end
        
    end
    
    local phrase = instr.phrases[phrase_idx]
    if (phrase_idx 
      and phrase_idx > 0
      and phrase
    ) then 
      
      local phrase_line,err = xPhrase.get_line_from_cursor(
        phrase,trigger_pos,cursor_pos,phrase_offset,notecol)
      --print("phrase_line,err",phrase_line,err)
      
      return {
        phrase_line = phrase_line,
        phrase_index = phrase_idx,
        instrument_index = instr_idx,
        zxx_column_index = zxx_col_idx,
        sxx_column_index = sxx_col_idx,
      }
    end 
  end 
  
end  
  
---------------------------------------------------------------------------------------------------
-- insert slice at the cursor-position (sample or phrase, automatically decided)
-- @return boolean, false when slicing failed
-- @return string, error message when failed

function SliceMate:insert_slice()
  TRACE("SliceMate:insert_slice()")

  local autofix = self.prefs.autofix_instr.value
  local cursor_pos = self:get_position()
  local trigger_pos = xNoteCapture.nearest(self.compare_fn)
  if not trigger_pos then
    -- offer to insert note when nothing was found 
    local is_sliceable,err = SliceMate.is_sliceable(rns.selected_instrument,autofix) 
    err = err and "\n\nThe error message received was:\n"..err or ""
    if not is_sliceable and autofix then
      return false,"Unable to insert slice - no notes found near cursor,"
        .."\nand instrument could not automatically be made sliceable."
        ..err
    elseif not is_sliceable then 
      return false,"Unable to insert slice - no notes found near cursor,"
        .."\nand instrument doesn't seem to be sliceable."
        ..err
        .."\n\nHint: enable 'Auto-fix instrument' to fix these issues"
        .."\nautomatically, as they are encountered"
    elseif is_sliceable and self.ui:promp_initial_note_insert() then
      local instr_idx = rns.selected_instrument_index
      local inserted,err = self:insert_sliced_note(cursor_pos,instr_idx,1)
      if not inserted and err then 
        return false,err
      end   
    end 
  else
    
    local phrase_pos,err = self:get_phrase_position(trigger_pos,cursor_pos)
    --print("phrase_pos,err",phrase_pos,err)
    if (phrase_pos ~= nil) then 
      local src_notecol = trigger_pos:get_column()
      local rslt,err = self:insert_sliced_phrase_note(cursor_pos,phrase_pos,src_notecol)
      if not rslt then 
        return false,err
      else
        return true
      end
    end
    
    -- not a phrase, or we don't support phrases: 
    -- determine buffer position 

    local frame,sample_idx,instr_idx,notecol = self:get_buffer_position(
      trigger_pos,cursor_pos,autofix)
    if not frame and sample_idx then 
      return false, ("Unable to insert slice:\n%s"):format(sample_idx) -- error message
    elseif sample_idx then
      local instr = rns.instruments[instr_idx]
      local sample = instr.samples[sample_idx]

      if (frame == 0) then
        return false -- fail silently (existing note?)
      end

      -- if the sample is a slice, offset frame by it's pos
      if (sample_idx > 1) then
        frame = frame + xInstrument.get_slice_marker_by_sample_idx(instr,sample_idx)
      end

      -- fail if the frame is exceeding the buffer size 
      local buffer = instr.samples[1].sample_buffer
      if buffer.has_sample_data then
        if (buffer.number_of_frames < frame) then
          return false, "Can't insert slice - frame exceeded buffer size"
            .. "\n (probably past the end of the sample)"
        end
      end

      local snap = self.slice_snap_threshold
      local slice_idx = xInstrument.get_slice_marker_at_pos(instr,frame,snap)
      if slice_idx then
        -- existing marker
      else 
      
        local transpose_offset = 0
        
        -- about to add first slice?
        if (#instr.samples == 1) then
          -- remember the difference between keyzone transpose and C-4 
          -- (not converted automatically when creating slice)
          local base_note = instr.samples[1].sample_mapping.base_note
          local trigger_note = 48 - notecol.note_value 
          transpose_offset = 48 - base_note - trigger_note
          instr.samples[1].transpose = instr.samples[1].transpose + transpose_offset
        end 

        instr.samples[1]:insert_slice_marker(frame)
        slice_idx = xInstrument.get_slice_marker_at_pos(instr,frame,snap)

        -- if we just added the first slice, modify the source note 
        -- (the note does not change automatically)
        if (#instr.samples == 2) then
          local first_mapping = instr.samples[1].sample_mapping
          notecol.note_value = first_mapping.note_range[1]
        end

        -- as we add additional slices, make sure they inherit the 
        -- properties of the slice that they were derived from 
        -- (usually, they inherit from the root sample)
        if (#instr.samples > 1) then          
          local new_sample = instr.samples[slice_idx+1]
          cReflection.copy_object_properties(sample,new_sample)
          xSample.initialize_loop(new_sample)
        end

      end

      if self.prefs.insert_note.value then
        local inserted,err = self:insert_sliced_note(cursor_pos,instr_idx,slice_idx+1,notecol)
        if not inserted and err then 
          return false,err
        end 
      end

    end
  end 

  return true

end

---------------------------------------------------------------------------------------------------
-- @param cursor_pos (xCursorPos), where to insert 
-- @param instr_idx (number), instrument index 
-- @param sample_idx (number), sample index - mapping decides which note to insert
-- @param [src_notecol] (renoise.NoteColumn), carry over volume/panning when set 


function SliceMate:insert_sliced_note(cursor_pos,instr_idx,sample_idx,src_notecol)
  TRACE("SliceMate:insert_sliced_note(cursor_pos,instr_idx,sample_idx,src_notecol)",cursor_pos,instr_idx,sample_idx,src_notecol)

  local instr = rns.instruments[instr_idx]
  local sample = instr.samples[sample_idx]
  if not sample then
    return false,"Could not resolve sample"
  end

  local _patt_idx,_patt,track,_ptrack,line = cursor_pos:resolve()
  if not line then
    return false,"Could not resolve pattern-line"                    
  end
  local notecol = line.note_columns[cursor_pos.column]
  if not notecol then
    return false,"Could not resolve note-column"
  end 

  notecol.note_value = sample.sample_mapping.base_note
  notecol.instrument_value = instr_idx-1
  if self.prefs.quantize_enabled.value then
    notecol.delay_value = 0
  else
    local fract = cLib.fraction(cursor_pos.line)
    local delay_val = math.floor(fract * 255)
    notecol.delay_value = delay_val
    if (delay_val > 0) then
      track.delay_column_visible = true
    end
  end
  self:propagate_vol_pan(src_notecol,notecol)

end

---------------------------------------------------------------------------------------------------
-- @param cursor_pos (xCursorPos), where to insert 
-- @param phrase_pos (table), as returned by get_phrase_position()
-- @param [src_notecol] (renoise.NoteColumn), carry over volume/panning when set 
-- @return boolean, true when note was inserted 
-- @return string, error message when failed 

function SliceMate:insert_sliced_phrase_note(cursor_pos,phrase_pos,src_notecol)
  TRACE("SliceMate:insert_sliced_phrase_note(cursor_pos,phrase_pos,src_notecol)",cursor_pos,phrase_pos,src_notecol)

  local instr = rns.instruments[phrase_pos.instrument_index]
  local _patt_idx,_patt,track,_ptrack,line = cursor_pos:resolve()
  if not line then
    return false,"Could not resolve pattern-line"                    
  end
  local notecol = line.note_columns[cursor_pos.column]
  if not notecol then
    return false,"Could not resolve note-column"
  end 
  local phrase = instr.phrases[phrase_pos.phrase_index]
  if not phrase then 
    return false,"Could not resolve phrase"
  end

  local lpb_factor = self:get_lpb_factor(phrase)
  --print(">>> lpb_factor",lpb_factor)
  local phrase_line = phrase_pos.phrase_line
  --print(">>> phrase_line #A",phrase_line)
  local fract = cLib.fraction(phrase_pos.phrase_line)
  --print(">>> fract",fract)
  
  -- if phrase is slower than pattern and cursor is positioned 
  -- "between lines", we are unable to slice 
  if (fract > 0) and (lpb_factor < 1) then 
    return false, "Unable to slice the phrase at the current line."
      .."\nPlease navigate to a nearby line which doesn’t show a "
      .."\nwarning triangle (⚠ N/A) and try again"
  end    

  notecol.note_value = src_notecol.note_value 
  notecol.instrument_value = phrase_pos.instrument_index-1
  
  -- delay/shift note if line contains fractional part 
  if (fract > 0) then 
    -- increase line by at least one - 
    phrase_line = math.max(math.floor(phrase_line)+1,
      math.floor(phrase_line) + math.floor(fract * lpb_factor))
    local delay_amount = (phrase_line - phrase_pos.phrase_line) / lpb_factor
    --print(">>> delay_amount",delay_amount)
    notecol.delay_value = math.floor(delay_amount*255)
    track.delay_column_visible = true
  end
  
  -- attempt to apply zxx/sxx to same columns as source   
  local rslt,err = xLinePattern.set_effect_column_command(
    track,line,"0Z",phrase_pos.phrase_index,phrase_pos.zxx_column_index)
  if err then 
    LOG(err)
  end
    
  rslt,err = xLinePattern.set_effect_column_command(
    track,line,"0S",phrase_line-1,phrase_pos.sxx_column_index)
  if err then 
    LOG(err)
  end
    
  self:propagate_vol_pan(src_notecol,notecol)

  return true
  
end

---------------------------------------------------------------------------------------------------
-- retrieve current LPB factor (phrase vs. pattern)
-- NB: using LPB from transport might not reflect value during playback, 
-- we could determine this value by reading from the actual pattern/song (TODO)

function SliceMate:get_lpb_factor(phrase)
  TRACE("SliceMate:get_lpb_factor(phrase)",phrase)

  assert(type(phrase)=="InstrumentPhrase")
  return phrase.lpb / rns.transport.lpb 
  
end  

---------------------------------------------------------------------------------------------------
-- configure note-column with vol/pan from source, or use current keyboard velocity 
-- @param src_notecol (renoise.NoteColumn)
-- @param dest_notecol (renoise.NoteColumn)

function SliceMate:propagate_vol_pan(src_notecol,dest_notecol)
  TRACE("SliceMate:propagate_vol_pan(src_notecol,dest_notecol)",src_notecol,dest_notecol)

  if self.prefs.propagate_vol_pan.value and src_notecol then
    dest_notecol.volume_value = src_notecol.volume_value
    dest_notecol.panning_value = src_notecol.panning_value
  elseif rns.transport.keyboard_velocity_enabled then
    dest_notecol.volume_value = rns.transport.keyboard_velocity 
  end 
  
end  

---------------------------------------------------------------------------------------------------

function SliceMate:get_instrument()
  TRACE("SliceMate:get_instrument()")

  local instr = rns.instruments[self.instrument_index.value]
  if not instr then 
    return false, "Could not resolve instrument with index "..self.instrument_index.value
  end 
  return instr
end

---------------------------------------------------------------------------------------------------

function SliceMate:get_sample()
  TRACE("SliceMate:get_sample()")

  local instr,err = self:get_instrument()
  if not instr then return false,err end

  local sample = instr.samples[self.slice_index.value+1]
  if not sample then
    return false, "Could not resolve slice with index "..self.slice_index.value
  end 
  return sample
end

---------------------------------------------------------------------------------------------------

function SliceMate:attach_to_song()

  if self._song_observables.length then
    for _,observable in pairs(self._song_observables) do
      pcall(function() observable:remove_notifier(self) end)
    end
  end
  self._song_observables:clear()

  local update = function()
    TRACE("SliceMate: song_observable was fired...")
    self.select_requested = true
  end

  self._song_observables:insert(rns.transport.bpm_observable)
  rns.transport.bpm_observable:add_notifier(self, update)

  self._song_observables:insert(rns.transport.lpb_observable)
  rns.transport.lpb_observable:add_notifier(self, update)

  rns.selected_pattern_index_observable:add_notifier(function()
    TRACE("SliceMate: selected_pattern_index_observable fired...")
    self:attach_to_pattern()
  end)

  rns.selected_track_index_observable:add_notifier(function()
    self.ui:update_slice_button()  
  end)

  rns.selected_instrument_index_observable:add_notifier(function()    
    -- detach/attach to sample 
    TRACE("SliceMate: selected_instrument_index_observable fired...",self.instrument_index.value)
    local attached,err = self:attach_to_instrument()
    if not attached and err then 
      LOG("*** "..err)
    end
  end)

  rns.selected_sample_observable:add_notifier(function()
    TRACE("SliceMate: selected_pattern_index_observable fired...")
    self:attach_to_sample()
  end)

end


---------------------------------------------------------------------------------------------------
-- attach to instrument + sample 
-- (basically, everything that can affect the status of an instrument)

function SliceMate:attach_to_instrument()

  local attach,err = self:attach_to_sample()
  if not attach and err then
   LOG("*** "..err)
   return
  end

  local instr,err = self:get_instrument()
  if not instr then
   --LOG("*** "..err)
   return
  end

  if self._instrument_observables.length then
    for _,observable in pairs(self._instrument_observables) do
      pcall(function() observable:remove_notifier(self) end)
    end
  end
  self._sample_observables:clear()

  local update = function()
    TRACE("SliceMate: an instrument observable was fired...",instr.name)
    self.select_requested = true
  end

  self._instrument_observables:insert(instr.samples_observable)
  instr.samples_observable:add_notifier(self, update)

  self._instrument_observables:insert(instr.phrase_playback_mode_observable)
  instr.phrase_playback_mode_observable:add_notifier(self, update)

end

---------------------------------------------------------------------------------------------------

function SliceMate:attach_to_sample()
  TRACE("SliceMate:attach_to_sample()")

  --local sample,err = self:get_sample()
  local sample = rns.selected_sample
  if not sample then return false, "Could not attach to sample - none selected" end 

  if self._sample_observables.length then
    for _,observable in pairs(self._sample_observables) do
      pcall(function() observable:remove_notifier(self) end)
    end
  end
  self._sample_observables:clear()

  local update = function()
    TRACE("SliceMate: a sample observable was fired...",sample.name)
    self.select_requested = true
  end

  self._sample_observables:insert(sample.autoseek_observable)
  sample.autoseek_observable:add_notifier(self, update)

  self._sample_observables:insert(sample.beat_sync_enabled_observable)
  sample.beat_sync_enabled_observable:add_notifier(self, update)

  self._sample_observables:insert(sample.fine_tune_observable)
  sample.fine_tune_observable:add_notifier(self, update)

  self._sample_observables:insert(sample.transpose_observable)
  sample.transpose_observable:add_notifier(self, update)

  self._sample_observables:insert(sample.sample_mapping.base_note_observable)
  sample.sample_mapping.base_note_observable:add_notifier(self, update)

  self._sample_observables:insert(sample.sample_mapping.note_range_observable)
  sample.sample_mapping.note_range_observable:add_notifier(self, update)


end

---------------------------------------------------------------------------------------------------

function SliceMate:handle_pattern_change()
  TRACE("SliceMate:handle_pattern_change()",self)

  self.select_requested = true

end

---------------------------------------------------------------------------------------------------

function SliceMate:attach_to_pattern()
  TRACE("SliceMate:attach_to_pattern()")

  local patt = rns.selected_pattern

  if patt:has_line_notifier(self,self.handle_pattern_change) then
    patt:remove_line_notifier(self,self.handle_pattern_change)
  end

  patt:add_line_notifier(self,self.handle_pattern_change)

end

---------------------------------------------------------------------------------------------------

function SliceMate:on_idle()
  --TRACE("SliceMate:on_idle()")

  if (self.prefs.suspend_while_hidden.value 
    and self.ui and not self.ui:dialog_is_visible()) 
  then 
    return
  end
  
  if self.select_requested
    or self.prefs.autoselect_in_wave.value 
    or self.prefs.autoselect_in_list.value 
    or self.prefs.autoselect_instr.value 
  then
    local curr_cursor_pos = self:get_cursor()
    if rns.transport.playing and not self.prefs.quantize_enabled.value then
      -- while playing, precise mode checks as often as possible 
      self:select(self.select_requested)
      self.select_requested = false
    else 
      -- quantized only checks when line has changed 
      local track_changed = (self.track_idx ~= rns.selected_track_index)
      local column_changed = (self.notecol_idx ~= rns.selected_note_column_index)
      if (curr_cursor_pos ~= self.cursor_pos) 
        or (track_changed or column_changed)
      then
        self:select(self.select_requested)
        self.select_requested = false
      end
    end
    -- still not processed? do it now...
    if self.select_requested then 
      self:select()
      self.select_requested = false
    end 
    self.cursor_pos = curr_cursor_pos
    self.track_idx = rns.selected_track_index
    self.notecol_idx = rns.selected_note_column_index
  end

end
