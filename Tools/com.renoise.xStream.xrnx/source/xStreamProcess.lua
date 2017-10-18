--[[===============================================================================================
xStreamProcess
===============================================================================================]]--
--[[

A single streaming process 

#

This class represents a 'streaming process' - basically a streaming buffer
with additional scheduling & automation-recording features on top. 

The class works with a single track only. If you need multiple tracks, 
use multiple instances of this class. 

]]

--=================================================================================================

class 'xStreamProcess' 

-- accessible to callback
xStreamProcess.OUTPUT_MODE = {
  STREAMING = 1,
  TRACK = 2,
  SELECTION = 3,
}

---------------------------------------------------------------------------------------------------
-- Constructor

function xStreamProcess:__init(xstream)

  self.xstream = xstream

  --- xStreamPos
  self.xpos = xstream.xpos

  --- xStreamPrefs, current settings
  self.prefs = renoise.tool().preferences

  --- enum, one of xStreamProcess.OUTPUT_MODE
  -- usually STREAMING, but temporarily set to a different
  -- value while applying output to TRACK/SELECTION
  self.output_mode = xStreamProcess.OUTPUT_MODE.STREAMING

  --- boolean, evaluate callback while playing
  self.active = property(self.get_active,self.set_active)
  self.active_observable = renoise.Document.ObservableBoolean(false)

  --- boolean, silence output (see also xStreamBuffer.MUTE_MODE)
  self.muted = property(self.get_muted,self.set_muted)
  self.muted_observable = renoise.Document.ObservableBoolean(false)

  --- int, set to true to silence output
  self.track_index = property(self.get_track_index,self.set_track_index)
  self.track_index_observable = renoise.Document.ObservableNumber(1)

  --- xStreamPos.SCHEDULE, active scheduling mode
  self.scheduling = property(self.get_scheduling,self.set_scheduling)
  self.scheduling_observable = renoise.Document.ObservableNumber(xStreamPos.SCHEDULE.BEAT)

  --- int, read-only - set via schedule_item(), 0 means none 
  self.scheduled_favorite_index = property(self.get_scheduled_favorite_index)
  self.scheduled_favorite_index_observable  = renoise.Document.ObservableNumber(0)

  --- int, read-only - set via schedule_item(), 0 means none
  self.scheduled_model_index = property(self.get_scheduled_model_index)
  self.scheduled_model_index_observable = renoise.Document.ObservableNumber(0)

  --- int, read-only - set via schedule_item()
  self.scheduled_model = property(self.get_scheduled_model)
  self._scheduled_model = nil

  --- xSongPos, tells us when/if a scheduled event will occur
  self._scheduled_xinc = nil

  --- int, read-only - set via schedule_item()
  self.scheduled_preset_index = property(self.get_scheduled_preset_index)
  self.scheduled_preset_index_observable = renoise.Document.ObservableNumber(0)

  --- int, read-only - set via schedule_item()
  self.scheduled_preset_bank_index = property(self.get_scheduled_preset_bank_index)
  self.scheduled_preset_bank_index_observable = renoise.Document.ObservableNumber(0)

  --- xStreamModels
  self.models = xStreamModels(self)
  
  -- handle changes to the selected model 
  self.models.selected_model_index_observable:add_notifier(function()
    self:reset()
    if (self.models.selected_model_index == 0) then
      if self.active then
        self:stop()
      end 
    end
    self:attach_to_model()
  end)

  --- xStreamBuffer, track position and handle streaming ...
  self.buffer = xStreamBuffer(self.xpos)
  -- synchronize with preferences
  self.buffer.automation_playmode = self.prefs.automation_playmode.value
  self.prefs.automation_playmode:add_notifier(function()
    TRACE("xStreamProcess - self.automation_playmode_observable fired...")
    self.buffer.automation_playmode = self.prefs.automation_playmode.value
  end)
  self.buffer.include_hidden = self.prefs.include_hidden.value
  self.prefs.include_hidden:add_notifier(function()
    TRACE("xStreamProcess - self.include_hidden_observable fired...")
    self.buffer.include_hidden = self.prefs.include_hidden.value
  end)
  self.buffer.clear_undefined = self.prefs.clear_undefined.value
  self.prefs.clear_undefined:add_notifier(function()
    TRACE("xStreamProcess - self.clear_undefined_observable fired...")
    self.buffer.clear_undefined = self.prefs.clear_undefined.value
  end)
  self.buffer.expand_columns = self.prefs.expand_columns.value
  self.prefs.expand_columns:add_notifier(function()
    TRACE("xStreamProcess - self.expand_columns_observable fired...")
    self.buffer.expand_columns = self.prefs.expand_columns.value
  end)
  self.buffer.mute_mode = self.prefs.mute_mode.value
  self.prefs.mute_mode:add_notifier(function()
    TRACE("xStreamProcess - self.mute_mode_observable fired...")
    self.buffer.mute_mode = self.prefs.mute_mode.value
  end)

  -- preferences -> app --

  self.prefs.scheduling:add_notifier(function()
    self.scheduling_observable.value = self.prefs.scheduling.value
  end)
  self.prefs.writeahead_factor:add_notifier(function()
    xStreamPos.WRITEAHEAD_FACTOR = self.prefs.writeahead_factor.value
  end)

end

---------------------------------------------------------------------------------------------------
-- Getters/setters
---------------------------------------------------------------------------------------------------

function xStreamProcess:get_active()
  return self.active_observable.value
end

function xStreamProcess:set_active(val)
  TRACE("xStreamProcess:set_active(val)",val)
  self.active_observable.value = val
  self:maintain_buffer_mute_state()
end

---------------------------------------------------------------------------------------------------

function xStreamProcess:get_muted()
  return self.muted_observable.value
end

function xStreamProcess:set_muted(val)
  TRACE("xStreamProcess:set_muted(val)",val)
  self.muted_observable.value = val
  self:maintain_buffer_mute_state()

end

---------------------------------------------------------------------------------------------------

function xStreamProcess:get_track_index()
  return self.buffer.track_index 
end

function xStreamProcess:set_track_index(idx)
  self.buffer.track_index = idx
  if self.active then
    self.buffer:update_read_buffer()
  end
end

---------------------------------------------------------------------------------------------------

function xStreamProcess:get_scheduling()
  return self.scheduling_observable.value
end

function xStreamProcess:set_scheduling(val)
  TRACE("xStreamProcess:set_scheduling(val)",val)
  self.scheduling_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamProcess:get_scheduled_favorite_index()
  return self.scheduled_favorite_index_observable.value
end

---------------------------------------------------------------------------------------------------

function xStreamProcess:get_scheduled_model_index()
  return self.scheduled_model_index_observable.value
end

---------------------------------------------------------------------------------------------------

function xStreamProcess:get_scheduled_model()
  return self._scheduled_model
end

---------------------------------------------------------------------------------------------------

function xStreamProcess:get_scheduled_preset_index()
  return self.scheduled_preset_index_observable.value
end

---------------------------------------------------------------------------------------------------

function xStreamProcess:get_scheduled_preset_bank_index()
  return self.scheduled_preset_bank_index_observable.value
end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------
-- Reset is invoked when starting or switching model 

function xStreamProcess:reset()
  TRACE("xStreamProcess:reset()")

  --self.buffer:wipe_futures()
  self.buffer:clear()
  self:clear_schedule()

end

---------------------------------------------------------------------------------------------------
-- Stop live streaming

function xStreamProcess:stop()
  TRACE("xStreamProcess:stop()")
  self.active = false
  self:clear_schedule()
end

---------------------------------------------------------------------------------------------------
-- Activate live streaming 
-- @param playmode, renoise.Transport.PLAYMODE

function xStreamProcess:start(playmode)
  TRACE("xStreamProcess:start(playmode)",playmode)

  if self.active then 
    return 
  end
  self:reset()
  self.active = true

end

---------------------------------------------------------------------------------------------------
-- Called on abrupt position changes - refresh pattern buffer, output 

function xStreamProcess:refresh()
  TRACE("xStreamProcess:refresh()")
  if self.active then
    self.buffer:update_read_buffer()
    self:recompute()
  end
end

---------------------------------------------------------------------------------------------------
-- Called when we need to recompute the immediate output buffer
-- (for example when some condition that affects the output has changed) 

function xStreamProcess:recompute()
  TRACE("xStreamProcess:recompute()")
  self.buffer:wipe_futures()
  self:output()

end 

---------------------------------------------------------------------------------------------------
-- Produce output - can be called periodically

function xStreamProcess:output()
  TRACE("xStreamProcess:output()")

  if self.active and self.models.selected_model then
    if self._scheduled_xinc then
      if (self.xpos.xinc == self._scheduled_xinc) then
        self:apply_schedule()
      end
    end
    local live_mode = true
    self.buffer:write_output(self.xpos.pos,self.xpos.xinc,nil,live_mode)
  end

end

---------------------------------------------------------------------------------------------------

function xStreamProcess:maintain_buffer_mute_state()
  TRACE("xStreamProcess:maintain_buffer_mute_state()")

  if self.active then 
    if self.muted and not self.buffer.mute_xinc then
      self.buffer:mute()
    elseif not self.muted and self.buffer.mute_xinc then
      self.buffer:unmute()
    end
  end

end

---------------------------------------------------------------------------------------------------
-- @return xStreamPresets, or false when unable to resolve

function xStreamProcess:get_selected_preset_bank()

  local model = self.models.selected_model
  if not model then 
    return false, "No model is selected"
  end 

  local preset_bank = self.models.selected_model.selected_preset_bank
  if not preset_bank then 
    return false, "No preset bank is selected"
  end 

  return preset_bank

end

---------------------------------------------------------------------------------------------------
-- Attempt to select a preset from the current preset bank 
-- @return boolean, true when able to set 

function xStreamProcess:set_selected_preset_index(idx)
  TRACE("xStreamProcess:set_selected_preset_index(idx)",idx)
  local preset_bank,err = self:get_selected_preset_bank()
  if err then 
    return false, err
  end 
  preset_bank.selected_preset_index = idx
  return true 
end 

---------------------------------------------------------------------------------------------------
-- Attempt to select the previous preset from the current preset bank
-- @return boolean, true when able to set 

function xStreamProcess:select_previous_preset()
  TRACE("xStreamProcess:select_previous_preset()")
  local preset_bank,err = self:get_selected_preset_bank()
  if err then 
    return false, err
  end 
  preset_bank:select_previous()
  return true 
end

---------------------------------------------------------------------------------------------------
-- Attempt to select the previous preset from the current preset bank
-- @return boolean, true when able to set 

function xStreamProcess:select_next_preset()
  TRACE("xStreamProcess:select_next_preset()")
  local preset_bank,err = self:get_selected_preset_bank()
  if err then 
    return false, err
  end 
  preset_bank:select_next()
  return true 
end

---------------------------------------------------------------------------------------------------
-- Schedule model or model+preset
-- @param model_name (string), unique name of model
-- @param preset_index (int),  preset to dial in - optional
-- @param preset_bank_name (string), preset bank - optional, TODO
-- @return true when item got scheduled, false if not
-- @return err (string), the reason scheduling failed

function xStreamProcess:schedule_item(model_name,preset_index,preset_bank_name)
  TRACE("xStreamProcess:schedule_item(model_name,preset_index,preset_bank_name)",model_name,preset_index,preset_bank_name)

  if not self.active then
    return false,"Can't schedule items while inactive"
  end

  assert(model_name,"Required argument missing: model_name")
  assert((type(model_name)=="string"),"Invalid argument type: model_name - expected string")

  local model_index,model = self.models:get_by_name(model_name)
  if not model then
    return false,"Could not schedule, model not found: "..model_name
  end

  self._scheduled_model = model
  self.scheduled_model_index_observable.value = model_index
  
  -- validate preset
  
  if (type(preset_index)=="number") then
    local num_presets = #model.selected_preset_bank.presets
    if (preset_index <= num_presets) then
      self.scheduled_preset_index_observable.value = preset_index
    end
  end

  if preset_bank_name then
    local preset_bank_index = model:get_preset_bank_by_name(preset_bank_name)
    --print("preset_bank_name,preset_bank_index",preset_bank_name,preset_bank_index)
    self.scheduled_preset_bank_index_observable.value = preset_bank_index
    --print("xStreamProcess:schedule_item - self.scheduled_preset_bank_index",preset_bank_index)
  end

  local favorite_idx = self.xstream.favorites:get(model_name,preset_index,preset_bank_name)
  --print("favorite_idx",favorite_idx)
  if favorite_idx then
    self.scheduled_favorite_index_observable.value = favorite_idx
  end

  -- now figure out the time
  if (self.scheduling == xStreamPos.SCHEDULE.LINE) then
    if self._scheduled_model then
      self:apply_schedule() -- set immediately 
    end
  else
    self:compute_scheduling_pos()
  end

  -- if scheduled event is going to take place within the
  -- space of already-computed lines, wipe the buffer
  if self._scheduled_xinc then
    local happening_in_lines = self._scheduled_xinc-self.xpos.xinc
    if (happening_in_lines <= xStreamPos.determine_writeahead()) then
      --print("wipe the buffer")
      self.buffer:wipe_futures()
    end
  end

end

---------------------------------------------------------------------------------------------------
-- Schedule, or re-schedule (when external conditions change)

function xStreamProcess:compute_scheduling_pos()
  TRACE("xStreamProcess:compute_scheduling_pos()")

  local pos = xSongPos.create(self.xpos.playpos)
  self._scheduled_xinc = self.xpos.xinc

  local xinc = 0
  if (self.scheduling == xStreamPos.SCHEDULE.LINE) then
    error("Scheduling should already have been applied")
  elseif (self.scheduling == xStreamPos.SCHEDULE.BEAT) then
    xinc = xSongPos.next_beat(pos)
  elseif (self.scheduling == xStreamPos.SCHEDULE.BAR) then
    xinc = xSongPos.next_bar(pos)  
  elseif (self.scheduling == xStreamPos.SCHEDULE.BLOCK) then
    xinc = xSongPos.next_block(pos)
  elseif (self.scheduling == xStreamPos.SCHEDULE.PATTERN) then
    -- if we are within a blockloop, do not set a schedule position
    -- (once the blockloop is disabled, this function is invoked)
    if not rns.transport.loop_block_enabled then
      xinc = xSongPos.next_pattern(pos)
    else
      pos = nil
    end
  else
    error("Unknown scheduling mode")
  end

  if pos then
    self._scheduled_xinc = self._scheduled_xinc + xinc
  else 
    self._scheduled_xinc = nil
  end

end

---------------------------------------------------------------------------------------------------
-- Invoked when cancelling schedule, or scheduled event has happened

function xStreamProcess:clear_schedule()
  TRACE("xStreamProcess:clear_schedule()")

  self._scheduled_model = nil
  self._scheduled_xinc = nil
  self.scheduled_model_index_observable.value = 0
  self.scheduled_preset_index_observable.value = 0
  self.scheduled_preset_bank_index_observable.value = 0
  self.scheduled_favorite_index_observable.value = 0

end

---------------------------------------------------------------------------------------------------
-- Switch to scheduled model/preset

function xStreamProcess:apply_schedule()
  TRACE("xStreamProcess:apply_schedule()")

  -- remember value (otherwise lost when setting model)
  local preset_index = self.scheduled_preset_index
  local preset_bank_index = self.scheduled_preset_bank_index

  if not self.scheduled_model then
    self:clear_schedule()
    return
  end

  self.models.selected_model_index = self.scheduled_model_index

  if preset_bank_index then
    self.models.selected_model.selected_preset_bank_index = preset_bank_index
  end

  self.models.selected_model.selected_preset_bank.selected_preset_index = preset_index

  self:clear_schedule()

end

---------------------------------------------------------------------------------------------------
-- Fill pattern-track in selected pattern
 
function xStreamProcess:fill_track()
  TRACE("xStreamProcess:fill_track()")
  
  local patt_num_lines = xPatternSequencer.get_number_of_lines(rns.selected_sequence_index)
  self:apply_to_range(1,patt_num_lines,xStreamProcess.OUTPUT_MODE.TRACK)

end

---------------------------------------------------------------------------------------------------
-- Ensure that selection is valid (not spanning multiple tracks)
-- @return bool
 
function xStreamProcess:validate_selection()
  TRACE("xStreamProcess:validate_selection()")

  local sel = rns.selection_in_pattern
  if not sel then
    return false,"Please create a (single-track) selection in the pattern"
  end
  if (sel.start_track ~= sel.end_track) then
    return false,"Selection must start and end in the same track"
  end

  return true

end

---------------------------------------------------------------------------------------------------
-- Fill pattern-track in selected pattern
-- @param locally (bool) relative to the top of the pattern
 
function xStreamProcess:fill_selection(locally)
  TRACE("xStreamProcess:fill_selection(locally)",locally)

  local passed,err = self.validate_selection()
  if not passed then
    err = "Could not apply model to selection:\n"..err
    renoise.app():show_warning(err)
    return
  end

  --local num_lines = xSongPos.get_number_of_lines(rns.selected_sequence_index)
  local from_line = rns.selection_in_pattern.start_line
  local to_line = rns.selection_in_pattern.end_line
  local xinc = (not locally) and (from_line-1) or 0 

  -- backup settings
  local cached_track_index = self.buffer.track_index

  -- write output
  self.buffer.track_index = rns.selection_in_pattern.start_track
  self:apply_to_range(from_line,to_line,xStreamProcess.OUTPUT_MODE.SELECTION,xinc)

  -- restore settings
  self.buffer.track_index = cached_track_index

end

---------------------------------------------------------------------------------------------------
-- Fill pattern-track for the selected line
-- @param locally (bool) relative to the top of the pattern
 
function xStreamProcess:fill_line(locally)
  TRACE("xStreamProcess:fill_line(locally)",locally)

  local from_line = rns.transport.edit_pos.line
  local xinc = (not locally) and (from_line-1) or 0 

  -- backup settings
  local cached_track_index = self.buffer.track_index

  -- write output
  self.buffer.track_index = rns.selected_track_index
  self:apply_to_range(from_line,from_line,xStreamProcess.OUTPUT_MODE.SELECTION,xinc)

  -- restore settings
  self.buffer.track_index = cached_track_index

end


---------------------------------------------------------------------------------------------------
-- Write output to a range in the selected pattern,  
-- temporarily switching to a different set of buffers
-- @param from_line (int)
-- @param to_line (int) 
-- @param mode (xStreamProcess.OUTPUT_MODE)
-- @param [xinc] (int) where the callback 'started'

function xStreamProcess:apply_to_range(from_line,to_line,mode,xinc)
  TRACE("xStreamProcess:apply_to_range(from_line,to_line,mode,xinc)",from_line,to_line,mode,xinc)

  assert(type(from_line)=="number")
  assert(type(to_line)=="number")
  assert(type(mode)=="number")

  local pos = {
    sequence = rns.transport.edit_pos.sequence,
    line = from_line
  }

  if not xinc then 
    xinc = 0
  end

  local live_mode = false
  local num_lines = to_line-from_line+1

  self:reset()

  -- backup settings
  local cached_active = self.active
  local cached_buffer = self.buffer.output_buffer
  local cached_read_buffer = self.buffer.pattern_buffer
  local cached_pos = self.xpos.pos
  local cached_xsongpos = xSongPos.get_defaults()
  -- ignore any kind of loop (those are for realtime only)
  xSongPos.set_defaults({
    bounds = xSongPos.OUT_OF_BOUNDS.CAP,
    loop = xSongPos.LOOP_BOUNDARY.NONE,
    block = xSongPos.BLOCK_BOUNDARY.NONE,
  })
  -- write output
  self.output_mode = mode -- NB: models can access this value
  self.active = true
  self.xpos.pos.line = from_line
  self.buffer:write_output(pos,xinc,num_lines,live_mode)

  -- restore settings
  self.active = cached_active
  self.buffer.output_buffer = cached_buffer
  self.buffer.pattern_buffer = cached_read_buffer
  self.xpos.pos = cached_pos
  xSongPos.set_defaults(cached_xsongpos)

  self.output_mode = xStreamProcess.OUTPUT_MODE.STREAMING

end


---------------------------------------------------------------------------------------------------
-- @param arg_name (string), e.g. "tab.my_arg" or "my_arg"
-- @param val (number/boolean/string)

function xStreamProcess:handle_arg_events(arg_name,val)
  TRACE("xStreamProcess:handle_arg_events(arg_name,val)",arg_name,val)

  -- pass to event handlers (if any)
  local event_key = "args."..arg_name
  self:handle_event(event_key,val)

end

---------------------------------------------------------------------------------------------------
-- @param event_key (string), e.g. "midi.note_on"
-- @param arg (number/boolean/string/table) value to pass 

function xStreamProcess:handle_event(event_key,arg)
  TRACE("xStreamProcess:handle_event(event_key,arg)",event_key,arg)

  if not self.models.selected_model then
    LOG("*** WARNING Can't handle events - no model was selected")
    return
  end

  local handler = self.models.selected_model.events_compiled[event_key]
  if handler then
    --print("about to handle event",event_key,arg,self.models.selected_model.name)
    local passed,err = pcall(function()
      handler(arg)
    end)
    if not passed then
      LOG("*** Error while handling event",err)
    end
  --else
  --  LOG("*** could not locate handler for event",event_key)
  end

end

---------------------------------------------------------------------------------------------------

function xStreamProcess:attach_to_model()
  TRACE("xStreamProcess:attach_to_model()")

  if not self.models.selected_model then 
    return 
  end 

  local compiled_notifier = function()
    TRACE("xStreamProcess:attach_to_model - compiled_notifier fired...")
    local model = self.models.selected_model
    self.buffer.callback = model.sandbox.callback
    self.buffer.output_tokens = model.output_tokens
    self:recompute()
  end 

  cObservable.attach(self.models.selected_model.compiled_observable,compiled_notifier)
  
  compiled_notifier()

end

