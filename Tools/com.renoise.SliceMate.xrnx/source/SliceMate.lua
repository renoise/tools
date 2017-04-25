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
      --[[
      if matched and not match_all then
        return true
      end
      ]]
    end
    if match_instr then
      if match_all and matched then
        return true
      else
        matched = notecol.instrument_value < 255
      end
      --[[
      if matched and not match_all then
        return true
      end
      ]]
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
-- the main method - obtain the buffer frame from xNotePos

function SliceMate:get_buffer_frame_by_notepos(pos)
  TRACE("SliceMate:get_buffer_frame_by_notepos(pos)",pos)

  local patt_idx,patt,track,ptrack,line = pos:resolve()
  if not line then
    return false,"Could not resolve pattern-line"                    
  end

  local notecol = line.note_columns[pos.column]
  if not notecol then
    return false, "Could not resolve note-column"
  end

  local instr_idx = notecol.instrument_value+1
  local instr = rns.instruments[instr_idx]
  if not instr then
    return false,"Could not resolve instrument"
  end

  local instr_name = (instr.name == "") and "Untitled instrument" or instr.name
  local is_sliced = xInstrument.is_sliced(instr)

  if (#instr.samples == 0) or (not is_sliced and #instr.samples > 1) then
    return false, "Instrument needs to contain a single sample,"
      ..("\nbut '%s' contains %d"):format(instr_name,#instr.samples)
  end

  -- resolve sample by looking at notecol 
  local sample_idx = xInstrument.get_sample_idx_from_note(instr,notecol.note_value) 
  if not sample_idx then
    return false, "Could not resolve sample from note -"
      ..("\nplease ensure that the note (%s) is mapped to a sample"):format(notecol.note_string)
      .."\n(this can be verified from the sampler's keyzone tab)"
  end

  local sample = instr.samples[sample_idx]

  if not sample.autoseek then
    return false, "Can't determine position - please enable auto-seek on the sample"
  end

  -- TODO support beatsync (different pitch)
  if sample.beat_sync_enabled then
    return false, "Can't determine position - please disable beat-sync on the sample"
  end

  if not sample.sample_buffer.has_sample_data then
    return false, "Can't determine position - sample is empty (does not contain audio)"
  end

  -- Don't trigger via phrase 
  -- TODO allow if available on keyboard while in keymapped mode
  if xInstrument.is_triggering_phrase(instr) then
    return false, "Can't determine position - please avoid using phrases to trigger notes"
  end
  
  -- get number of lines to the trigger note
  local current_pos = xSongPos(rns.transport.edit_pos)
  local nearest_pos = xSongPos(pos)
  local diff = xSongPos.get_line_diff(current_pos,nearest_pos)

  -- precise position: subtrack the delay column 
  -- from the original, triggering note
  if track.delay_column_visible then
    if (notecol.delay_value > 0) then
      diff = diff - (notecol.delay_value / 255)
    end
  end
  -- precise position: apply fractional line 
  -- (skip when quantized)
  if not self.prefs.quantize_enabled.value then
    diff = diff + pos.fraction
  end

  local frame = xSample.get_buffer_frame_by_line(sample,diff)
  frame = xSample.get_transposed_frame(notecol.note_value,frame,sample)

  return frame,sample_idx,instr_idx,notecol

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
-- set waveform selection based on the cursor-position

function SliceMate:select(user_selected)
  TRACE("SliceMate:select(user_selected)",user_selected)

  local pos = xNoteCapture.nearest(self.compare_fn)
  if not pos then
    self.instrument_status.value = ""
    self.instrument_index.value = 0  
  else
    local frame,sample_idx,instr_idx,notecol = self:get_buffer_frame_by_notepos(pos)
    if not frame and sample_idx then
      local notecol = pos:get_column()
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

---------------------------------------------------------------------------------------------------

function SliceMate:previous_column()
  xColumns.previous_note_column()
  self.select_requested = true
end

---------------------------------------------------------------------------------------------------

function SliceMate:next_column()
  xColumns.next_note_column()
  self.select_requested = true
end

---------------------------------------------------------------------------------------------------

function SliceMate:previous_note()
  local pos = xNoteCapture.previous(self.compare_fn)
  if pos then
    pos:select()
    self.select_requested = true
  end
end

---------------------------------------------------------------------------------------------------

function SliceMate:next_note()
  local pos = xNoteCapture.next(self.compare_fn)
  if pos then
    pos:select()
    self.select_requested = true
  end
end

---------------------------------------------------------------------------------------------------

function SliceMate:detach_sampler()
  TRACE("SliceMate:detach_sampler()")

  local enum_sampler = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
  local detached = renoise.app().window.instrument_editor_is_detached
  local middle_frame = renoise.app().window.active_middle_frame
  if (middle_frame ~= enum_sampler) then
    renoise.app().window.active_middle_frame = enum_sampler
  else 
    renoise.app().window.instrument_editor_is_detached = not detached
  end  

  renoise.app().window.active_middle_frame = middle_frame

end

---------------------------------------------------------------------------------------------------
-- insert slice at the cursor-position 
-- @return boolean, false when slicing failed
-- @return string, error message when failed

function SliceMate:insert_slice()
  TRACE("SliceMate:insert_slice()")

  local xnotepos = xNotePos()
  local pos = xNoteCapture.nearest(self.compare_fn,xnotepos)
  if not pos then
    return false,"Could not find a sample to slice,"
      .."\nperhaps the track doesn't contain any notes?"
  else
    local frame,sample_idx,instr_idx,notecol = self:get_buffer_frame_by_notepos(pos)
    if not frame and sample_idx then 
      return false, ("Unable to insert slice:\n%s"):format(sample_idx) -- error message
    elseif sample_idx then
      local instr = rns.instruments[instr_idx]
      local sample = instr.samples[sample_idx]

      if (frame == 0) then
        return false, "Can't insert slice where notes are present - "
          .."\nplease set the cursor somewhere else"
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
      if not slice_idx then

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

        if self.prefs.insert_note.value then
          self:insert_sliced_note(xnotepos,instr_idx,slice_idx,notecol)
        end

      else 
        -- existing marker
      end

    end
  end 

  return true

end

---------------------------------------------------------------------------------------------------

function SliceMate:insert_sliced_note(xnotepos,instr_idx,slice_idx,src_notecol)
  TRACE("SliceMate:insert_sliced_note(xnotepos,instr_idx,slice_idx,src_notecol)",xnotepos,instr_idx,slice_idx,src_notecol)

  local instr = rns.instruments[instr_idx]
  local sample_idx = slice_idx+1
  local sample = instr.samples[sample_idx]
  if (sample) then
    local patt_idx,patt,track,ptrack,line = xnotepos:resolve()
    if not line then
        return false,"Could not resolve pattern-line"                    
    end
    local notecol = line.note_columns[xnotepos.column]
    if notecol then
      notecol.note_value = sample.sample_mapping.note_range[1]
      notecol.instrument_value = instr_idx-1
      if not self.prefs.quantize_enabled.value then
        local delay_val = math.floor(xnotepos.fraction * 255)
        notecol.delay_value = delay_val
        if (delay_val > 0) then
          track.delay_column_visible = true
        end
      end
      if self.prefs.propagate_vol_pan.value then
        notecol.volume_value = src_notecol.volume_value
        notecol.panning_value = src_notecol.panning_value
      else
        if rns.transport.keyboard_velocity_enabled then
          notecol.volume_value = rns.transport.keyboard_velocity 
        end
      end
    end
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
    print(">>> a song_observable was fired...")
    self.select_requested = true
  end

  self._song_observables:insert(rns.transport.bpm_observable)
  rns.transport.bpm_observable:add_notifier(self, update)

  self._song_observables:insert(rns.transport.lpb_observable)
  rns.transport.lpb_observable:add_notifier(self, update)

  rns.selected_pattern_index_observable:add_notifier(function()
    --print(">>> selected_pattern_index_observable fired...")
    self:attach_to_pattern()
  end)

  rns.selected_instrument_index_observable:add_notifier(function()    
    -- detach/attach to sample 
    --print(">>> selected_instrument_index_observable fired...",self.instrument_index.value)
    local attached,err = self:attach_to_instrument()
    if not attached and err then 
      LOG("*** "..err)
    end
  end)

  rns.selected_sample_observable:add_notifier(function()
    --print(">>> selected_pattern_index_observable fired...")
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
   LOG("*** "..err)
   return
  end

  if self._instrument_observables.length then
    for _,observable in pairs(self._instrument_observables) do
      pcall(function() observable:remove_notifier(self) end)
    end
  end
  self._sample_observables:clear()

  local update = function()
    --print(">>> an instrument observable was fired...",instr.name)
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
    --print(">>> a sample observable was fired...",sample.name)
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
