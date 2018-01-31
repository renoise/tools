--[[===============================================================================================
-- AutoMate.lua
===============================================================================================]]--

--[[--

# AutoMate

--]]

--=================================================================================================

class 'AutoMate'

function AutoMate:__init(prefs)
  TRACE("AutoMate:__init(prefs)",prefs)

  assert(type(prefs) == "AutoMatePrefs",
    "Settings needs to be an instance of AutoMatePrefs")

  -- (xAudioDeviceAutomation | xParameterAutomation) current clipboard content 
  self._clipboard = nil
  -- fired when clipboard is updated 
  self.clipboard_observable = renoise.Document.ObservableBang()
  -- (string or nil) set while a sliced process is running 
  self.processing = nil
  -- fired as sliced process state changes
  self.processing_changed_observable = renoise.Document.ObservableBang()

  --- (int) track context
  self.selected_track_idx = property(self._get_track_index,self._set_track_index)
  self._selected_track_idx = 1

  self.selected_device_idx = property(self._get_device_index,self._set_device_index)
  self._selected_device_idx = nil

  self.selected_parameter_idx = property(self._get_parameter_index,self._set_parameter_index)  
  self._selected_parameter_idx = nil

  --- (AutoMateUI) 
  self._ui = AutoMateUI(self)

  --- (bool) when attached to a song
  self._active = false
  
  --- (table)
  self._song_notifiers = table.create()
  self._track_notifiers = table.create()
  self._device_notifiers = table.create()
  
  -- temporarily suppress focus from being set in setter 
  self._suppress_device_focus_sync = false
  self._suppress_param_focus_sync = false

  -- (cProcessSlicer) 
  self.slicer = nil

end

--=================================================================================================
-- App
--=================================================================================================

function AutoMate:show_dialog()
  TRACE("AutoMate:show_dialog()")
  self._ui:show()
end

---------------------------------------------------------------------------------------------------

function AutoMate:hide_dialog()
  TRACE("AutoMate:hide_dialog()")
  self._ui:hide()
end

---------------------------------------------------------------------------------------------------

function AutoMate:is_running()
  if self._ui._dialog then
    return self._ui._dialog.visible
  else
    return false
  end
end

--=================================================================================================
-- Getters and Setters
--=================================================================================================

function AutoMate:_get_track_index()
  return self._selected_track_idx
end

function AutoMate:_set_track_index(idx)
  assert(type(idx)=="number")
  if (idx ~= self._selected_track_idx) then 
    self._ui.update_tracks_requested = true
    self._ui.update_devices_requested = true
    self._ui.update_params_requested = true
    self._selected_track_idx = idx
    rns.selected_track_index = self._selected_track_idx
    self:attach_to_track() 
  end

end

---------------------------------------------------------------------------------------------------

function AutoMate:_get_device_index()
  return self._selected_device_idx
end

function AutoMate:_set_device_index(idx)
  if (idx ~= self._selected_device_idx) then 
    self._ui.update_devices_requested = true    
    self._ui.update_params_requested = true    
    self._ui.update_actions_requested = true   
    self._selected_device_idx = idx
    if not self._suppress_device_focus_sync then
      self:_set_selected_device_in_renoise()
    end
    self:attach_to_device() 
  end  
  self._suppress_device_focus_sync = false

end

---------------------------------------------------------------------------------------------------

function AutoMate:_get_parameter_index()
  return self._selected_parameter_idx
end

function AutoMate:_set_parameter_index(param_idx)
  TRACE("AutoMate:_set_parameter_index(param_idx)",param_idx)
  if (param_idx ~= self._selected_parameter_idx) then 
    self._ui.update_params_requested = true    
    self._ui.update_actions_requested = true    
    self._selected_parameter_idx = param_idx
    -- check if index refers to the special 'bypass' parameter
    -- (we can't access, set that one due to API limitation)
    if param_idx and (param_idx > 0) then
      if not self._suppress_param_focus_sync then 
        self:_set_selected_parameter_in_renoise()
      end
    end
  end    
  self._suppress_param_focus_sync = false
  

end

--=================================================================================================
-- Observables
--=================================================================================================

--- Detach from song document (remove notifiers)

function AutoMate:detach_from_song()
  TRACE("AutoMate:detach_from_song()")

  local new_song = false
  self._active = false
  self:_remove_notifiers(new_song,self._song_notifiers)

end

---------------------------------------------------------------------------------------------------

function AutoMate:attach_to_song(new_song)
  TRACE("AutoMate:attach_to_song(new_song)",new_song)

  self._active = true
  self:_remove_notifiers(new_song,self._song_notifiers)

  self._song_notifiers:insert(rns.tracks_observable)
  rns.tracks_observable:add_notifier(self,
    function()
      --print("*** AutoMate:tracks_observable fired...")
      self:_track_notifier()
      self._ui.update_tracks_requested = true
    end
  )

  self._song_notifiers:insert(rns.selected_track_observable)
  rns.selected_track_observable:add_notifier(self,self._track_notifier)
  
  self._song_notifiers:insert(rns.selected_track_device_observable)
  rns.selected_track_device_observable:add_notifier(self,self._device_notifier)

  self._song_notifiers:insert(rns.selected_automation_device_observable)
  rns.selected_automation_device_observable:add_notifier(self,self._device_notifier)

  self._song_notifiers:insert(rns.selected_automation_parameter_observable)
  rns.selected_automation_parameter_observable:add_notifier(self,self._param_notifier)

  -- initialize 
  self:_track_notifier()
  self:_device_notifier()
  self:_param_notifier()
  self:attach_to_track(new_song) 
  self.update_requested = true

end

---------------------------------------------------------------------------------------------------

function AutoMate:attach_to_track(new_song)
  TRACE("AutoMate:attach_to_track(new_song)",new_song)

  self:_remove_notifiers(new_song,self._track_notifiers)

  local sel_trk = self:_resolve_track()

  self._track_notifiers:insert(sel_trk.devices_observable)
  sel_trk.devices_observable:add_notifier(self,
    function(_,args)
      --print("*** AutoMate:devices_observable fired...",rprint(args))
      -- maintain device index
      -- TODO refactor into cLib
      if (args.type == "remove") then
        if (self._selected_device_idx == args.index) then
          self.selected_device_idx = nil
        elseif (self._selected_device_idx >= args.index) then
          self.selected_device_idx = self._selected_device_idx - 1
        end
      elseif (args.type == "insert") then
        if (self._selected_device_idx > args.index) then
          self.selected_device_idx = self._selected_device_idx + 1
        end
      elseif (args.type == "swap") then
        if (self._selected_device_idx == args.index1) then
          self.selected_device_idx = args.index2
        elseif (self._selected_device_idx == args.index2) then
          self.selected_device_idx = args.index1
        end
      end
      --print("self._selected_device_idx",self._selected_device_idx)
      self._ui.update_devices_requested = true
    end
  )

end

---------------------------------------------------------------------------------------------------

function AutoMate:attach_to_device()
  TRACE("AutoMate:attach_to_device()")

  self:_remove_notifiers(false,self._device_notifiers)

  local device = self:_resolve_device()
  --print("attach_to_device - device.name",device and device.name)    
  if device then
    for k,param in ipairs(device.parameters) do 
      self._device_notifiers:insert(param.is_automated_observable)
      param.is_automated_observable:add_notifier(self,
        function()
          --print("*** AutoMate:is_automated_observable fired...")
          self._ui.update_params_requested = true
        end
      )
    end
  end

end

---------------------------------------------------------------------------------------------------
-- decide if we should update when selection in renoise has changed

function AutoMate:_track_notifier()
  self.selected_track_idx = rns.selected_track_index
  self._ui.update_tracks_requested = true     
  self._ui.update_devices_requested = true
  self._ui.update_params_requested = true
end

function AutoMate:_param_notifier()
  self._suppress_device_focus_sync = true
  self._suppress_param_focus_sync = true
  self.selected_parameter_idx = self:_get_selected_parameter_index_in_renoise()
  self._ui.update_params_requested = true    
  self:_track_notifier()
end

function AutoMate:_device_notifier()
  self._suppress_device_focus_sync = true
  self._suppress_param_focus_sync = true
  self.selected_device_idx = self:_get_selected_device_index_in_renoise()
  self._ui.update_devices_requested = true
  self:_param_notifier()
  self:_track_notifier()
end

---------------------------------------------------------------------------------------------------
-- Detach all attached notifiers in list, but don't even try to detach 
-- when a new song arrived - old observables will no longer be alive then...
-- @param new_song (bool), true to leave existing notifiers alone
-- @param observables (table) 

function AutoMate:_remove_notifiers(new_song,observables)
  TRACE("AutoMate:_remove_notifiers()",new_song,#observables)

  if (not new_song) then
    for _,observable in pairs(observables) do
      pcall(function() observable:remove_notifier(self) end)
    end
  end
    
  observables:clear()

end

--=================================================================================================
-- Focus & Selection
--=================================================================================================

-- resolve selected track
-- @param track_idx (number), if undefined, use current 
-- @return renoise.Track or nil

function AutoMate:_resolve_track(track_idx)
  return rns.tracks[track_idx or self.selected_track_idx]
end

---------------------------------------------------------------------------------------------------
-- resolve selected device 
-- @param device_idx (number), if undefined, use current 
-- @param track_idx (number), if undefined, use current 
-- @return renoise.AudioDevice or nil

function AutoMate:_resolve_device(device_idx,track_idx)
  local trk = self:_resolve_track()
  --print("self._selected_device_idx",self._selected_device_idx)
  return trk.devices[device_idx or self._selected_device_idx]
end

---------------------------------------------------------------------------------------------------
-- resolve selected parameter 
-- @return renoise.DeviceParameter or nil

function AutoMate:_resolve_parameter()
  TRACE("AutoMate:_resolve_parameter()")
  return self:_resolve_parameter_from_idx(self._selected_parameter_idx)
end

---------------------------------------------------------------------------------------------------
-- resolve parameter from current track/device
-- @param param_idx (number), if undefined, return first one
-- @param device_idx (number), if undefined, use current 
-- @param track_idx (number), if undefined, use current 
-- @return renoise.DeviceParameter or nil

function AutoMate:_resolve_parameter_from_idx(param_idx,device_idx,track_idx)
  TRACE("AutoMate:_resolve_parameter_from_idx(param_idx,device_idx,track_idx)",param_idx,device_idx,track_idx)
  local device = self:_resolve_device(device_idx)
  print("device",device)
  if device then 
    if not param_idx then 
      for k,v in ipairs(device.parameters) do 
        return v
      end
    else
      return device.parameters[param_idx]
    end
  end
end

---------------------------------------------------------------------------------------------------
-- set focus to the selected device 
-- (including dsp panel workaround: select automation parameter in order to set device)

function AutoMate:_set_selected_device_in_renoise()
  TRACE("AutoMate:_set_selected_device_in_renoise()")
  local param = self:_resolve_parameter()  
  if not param or not param.is_automatable then 
    -- provide fallback, or selection starts to act funny...
    param = self:_resolve_parameter_from_idx()  
  end
  if self._selected_device_idx then 
    rns.selected_automation_parameter = (param and param.is_automatable) and param or nil
    rns.selected_device_index = self._selected_device_idx
  end
  
end

---------------------------------------------------------------------------------------------------
-- get the selected device in renoise - depends on the visible panel 
-- @param track_idx (number), specify when passive mode 

function AutoMate:_get_selected_device_index_in_renoise(track_idx)
  TRACE("AutoMate:_get_selected_device_index_in_renoise(track_idx)",track_idx)
  local rns_app = renoise.app()
  local frame_dsps = renoise.ApplicationWindow.LOWER_FRAME_TRACK_DSPS
  local frame_auto = renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION

  if (rns_app.window.active_lower_frame == frame_dsps) then 
    return rns.selected_device_index 
  elseif (rns_app.window.active_lower_frame == frame_auto) then 
    local device = rns.selected_automation_device 
    if device then 
      return xAudioDevice.resolve_device(device,track_idx or self.selected_track_idx)
    else 
      local param = rns.selected_automation_parameter
      if param then 
        return xAudioDevice.resolve_parameter(param,track_idx or self.selected_track_idx)
      end
    end
  end

end

---------------------------------------------------------------------------------------------------
-- @return number or nil 

function AutoMate:_get_selected_parameter_index_in_renoise()
  TRACE("AutoMate:_get_selected_parameter_index_in_renoise()")
  local device = rns.selected_automation_device 
  local param = rns.selected_automation_parameter 
  if (device and param and param.is_automatable) then
    return xAudioDevice.get_param_index(device,param)
  end
end

---------------------------------------------------------------------------------------------------
-- make the automation-parameter in renoise match ours...

function AutoMate:_set_selected_parameter_in_renoise()
  TRACE("AutoMate:_set_selected_parameter_in_renoise()")
  local param = self:_resolve_parameter()
  if param and not param.is_automatable then 
    -- avoid that selected_automation_device gets modified,
    -- as this would get picked up and unset the device
    return 
  end
  rns.selected_automation_parameter = param
end

---------------------------------------------------------------------------------------------------

function AutoMate:select_next_track()
  TRACE("AutoMate:select_next_track()")
  local wrap_pattern = false
  xTrack.jump_to_next_track(self._selected_track_idx,wrap_pattern)
end

---------------------------------------------------------------------------------------------------

function AutoMate:select_previous_track()
  TRACE("AutoMate:select_previous_track()")
  local wrap_pattern = false
  xTrack.jump_to_previous_track(self._selected_track_idx,wrap_pattern)
end

---------------------------------------------------------------------------------------------------

function AutoMate:select_next_device()
  TRACE("AutoMate:select_next_device()")
  local track = self:_resolve_track()
  if self._selected_device_idx and (self._selected_device_idx < #track.devices) then 
    self.selected_device_idx = self._selected_device_idx + 1
  else
    self.selected_device_idx = 1
  end
end

---------------------------------------------------------------------------------------------------

function AutoMate:select_previous_device()
  TRACE("AutoMate:select_previous_device()")
  if self._selected_device_idx and (self._selected_device_idx > 0) then 
    self.selected_device_idx = self._selected_device_idx - 1
  else
    self.selected_device_idx = 0
  end
end

---------------------------------------------------------------------------------------------------

function AutoMate:select_next_parameter()
  TRACE("AutoMate:select_next_parameter()")
  local device = self:_resolve_device()
  if (self._selected_parameter_idx < #device.parameters) then 
    self.selected_parameter_idx = self._selected_parameter_idx + 1
  end
end

---------------------------------------------------------------------------------------------------

function AutoMate:select_previous_parameter()
  TRACE("AutoMate:select_previous_parameter()")
  if (self._selected_parameter_idx > 0) then 
    self.selected_parameter_idx = self._selected_parameter_idx - 1
  end
end

---------------------------------------------------------------------------------------------------

function AutoMate:select_next_scope()
  TRACE("AutoMate:select_next_scope()")

  local get_range_with_prompt = function()
    local seq_range = self:_create_range()
    if not seq_range then 
      renoise.app():show_message("Please select a range")
    end
    return seq_range
  end 

  local scope = prefs.selected_scope.value 

  if (scope == xParameterAutomation.SCOPE.WHOLE_SONG) then 
    -- do nothing
  elseif (scope == xParameterAutomation.SCOPE.WHOLE_PATTERN) then
    xPatternSequencer.goto_next()
  elseif (scope == xParameterAutomation.SCOPE.SELECTION_IN_PATTERN) then 
    local seq_range = get_range_with_prompt()
    if seq_range then 
      seq_range = xSequencerSelection.shift_forward(seq_range)
      xSequencerSelection.apply_to_pattern(seq_range)
    end
  elseif (scope == xParameterAutomation.SCOPE.SELECTION_IN_SEQUENCE) then 
    local seq_range = get_range_with_prompt()
    if seq_range then 
      local shift_by = xSequencerSelection.get_selected_range_length()
      xSequencerSelection.shift_by_indices(seq_range,shift_by)
      rns.sequencer.selection_range = {
        seq_range.start_sequence,
        seq_range.end_sequence,
      }
    end

  end

end

---------------------------------------------------------------------------------------------------

function AutoMate:select_previous_scope()
  TRACE("AutoMate:select_previous_scope()")

  local get_range_with_prompt = function()
    local seq_range = self:_create_range()
    if not seq_range then 
      renoise.app():show_message("Please select a range")
    end
    return seq_range
  end 
  
  local scope = prefs.selected_scope.value 
  if (scope == xParameterAutomation.SCOPE.WHOLE_SONG) then 
    -- do nothing
  elseif (scope == xParameterAutomation.SCOPE.WHOLE_PATTERN) then
    xPatternSequencer.goto_previous()
  elseif (scope == xParameterAutomation.SCOPE.SELECTION_IN_PATTERN) then 
    local seq_range = get_range_with_prompt()
    if seq_range then 
      seq_range = xSequencerSelection.shift_backward(seq_range)
      xSequencerSelection.apply_to_pattern(seq_range)
    end
  elseif (scope == xParameterAutomation.SCOPE.SELECTION_IN_SEQUENCE) then 
    local seq_range = get_range_with_prompt()
    if seq_range then 
      local shift_by = -xSequencerSelection.get_selected_range_length()
      xSequencerSelection.shift_by_indices(seq_range,shift_by)
      rns.sequencer.selection_range = {
        seq_range.start_sequence,
        seq_range.end_sequence,
      }
    end

  end

end

--=================================================================================================
-- Clipboard Actions 
-- (make sure all methods here can be executed passively)
--=================================================================================================
-- @param done_callback (function(success,msg_or_err)), invoked once done

function AutoMate:copy(done_callback)
  TRACE("AutoMate:copy(done_callback)",done_callback)

  local invoke_done_callback = function(clipboard,msg_or_err) 
    --print("invoke_done_callback - clipboard,msg_or_err",clipboard,msg_or_err)
    self.processing = nil
    self.processing_changed_observable:bang()
    -- NB: assign only when there are actual points!
    -- (even if we did a check for "is_automated", there might be 
    -- no points collected, due to the existence of pattern automation)
    if clipboard and clipboard:has_points() then 
      self._clipboard = clipboard
      self.clipboard_observable:bang()
    else
      msg_or_err = "Nothing was copied to the clipboard"
    end
    if done_callback then 
      local rslt = clipboard and true or false
      done_callback(rslt,msg_or_err)
    end
  end

  local seq_range = self:_create_range()
  if not seq_range then         
    invoke_done_callback(false,"Please select a range first")
    return 
  end
  
  local clipboard = nil
  local scope = prefs.selected_scope.value
  local yield_at = prefs.yield_at.value

  -- support passive operation
  local track_idx,device_idx,param_idx = self:_get_current_focus()

  local do_process_device = function()
    print("do_process_device")
    clipboard = xAudioDevice.copy_automation(track_idx,device_idx,seq_range,scope,yield_at)
    local msg = clipboard and ("Copied automation (%d parameters)"):format(#clipboard.parameters) or nil
    invoke_done_callback(clipboard)
  end

  local do_process_parameter = function(param)
    print("do_process_parameter",param)
    clipboard = xParameterAutomation.copy(param,seq_range,track_idx,device_idx,scope,yield_at)
    local msg = clipboard and ("Copied automation (%d points)"):format(#clipboard.points) or nil
    invoke_done_callback(clipboard,msg)
  end

  if (prefs.selected_tab.value == AutoMatePrefs.TAB_DEVICES) then 
    local device = self:_resolve_device()
    if not device or not xAudioDevice.is_automated(device) then 
      invoke_done_callback(false,"The selected device isn't automated, nothing to copy...")
    else
      if (yield_at == xAudioDeviceAutomation.YIELD_AT.NONE) then
        do_process_device()
      else
        self.slicer = ProcessSlicer(do_process_device)
        self.processing = "Copying device automation..."
        self.processing_changed_observable:bang()        
        self.slicer:start()
      end
    end
  else--if (prefs.selected_tab.value == AutoMatePrefs.TAB_PARAMETERS) then 
    local param = self:_resolve_parameter_from_idx(param_idx,device_idx,track_idx)
    print("param_idx",param_idx,param)
    if not param then 
      if done_callback then
        done_callback(false,"No parameter was found")
      end
    else
      if (yield_at == xAudioDeviceAutomation.YIELD_AT.NONE) then
        do_process_parameter(param)
      else
        self.slicer = ProcessSlicer(do_process_parameter,param)
        self.processing = "Copying param. automation..."
        self.processing_changed_observable:bang()
        self.slicer:start()
      end
    end
  end

end

---------------------------------------------------------------------------------------------------
-- @param done_callback (function(success,msg_or_err)), invoked once done

function AutoMate:paste(done_callback)
  TRACE("AutoMate:paste(done_callback)",done_callback)

  local invoke_done_callback = function(success,msg_or_err) 
    --print("invoke_done_callback - success,msg_or_err",success,msg_or_err)
    self.processing = nil
    if success then 
      self.processing_changed_observable:bang()
    end
    if done_callback then 
      done_callback(success,msg_or_err)
    end
  end
  
  -- TODO supply context (for operation in context-menu)
  local device_tab_selected = (prefs.selected_tab.value == AutoMatePrefs.TAB_DEVICES)
  --local param_tab_selected = (prefs.selected_tab.value == AutoMatePrefs.TAB_PARAMETERS)
  
  -- verify clipboard, provide feedback 
  local clipboard = self._clipboard
  local err_msg = nil
  if not clipboard then 
    err_msg = "Nothing available on the clipboard"
  elseif device_tab_selected then 
    if (type(clipboard)=="xParameterAutomation") then
      err_msg = "The clipboard contains parameter automation. Only device automation can be pasted here"
    end
  else--if param_tab_selected then 
    if (type(clipboard)=="xAudioDeviceAutomation") then
      err_msg = "The clipboard contains device automation. Only parameter automation can be pasted here"
    end
  end
  if err_msg then 
    invoke_done_callback(false,err_msg)
    return
  end

  local yield_at = prefs.yield_at.value
  local apply_mode = xParameterAutomation.APPLY_MODE.REPLACE

  -- support passive operation
  local track_idx,device_idx,param_idx = self:_get_current_focus()
  print(">>> track_idx,device_idx,param_idx",track_idx,device_idx,param_idx)

  -- determine our output-range (based on source scope)
  local seq_range = nil
  if (clipboard.scope == xParameterAutomation.SCOPE.WHOLE_SONG) then 
    seq_range = xSequencerSelection.get_entire_range()
  elseif (clipboard.scope == xParameterAutomation.SCOPE.WHOLE_PATTERN) then 
    seq_range = xSequencerSelection.get_selected_index()
  elseif (clipboard.scope == xParameterAutomation.SCOPE.SELECTION_IN_SEQUENCE) then 
    seq_range = xSequencerSelection.get_selected_range()
  elseif (clipboard.scope == xParameterAutomation.SCOPE.SELECTION_IN_PATTERN) then 
    seq_range = xSequencerSelection.get_pattern_selection()
  end
  
  local do_process_device = function()
    print("do_process_device")
    local success,err_msg = xAudioDevice.paste_automation(clipboard,track_idx,device_idx,seq_range,apply_mode,yield_at)
    invoke_done_callback(success,err_msg)
  end

  local do_process_parameter = function(param)
    print("do_process_parameter",param)
    local success,err_msg = xParameterAutomation.paste(clipboard,apply_mode,param,seq_range,track_idx,yield_at)
    invoke_done_callback(success,err_msg)
  end
  
  local success = nil
  if device_tab_selected then 
    if (yield_at == xAudioDeviceAutomation.YIELD_AT.NONE) then
      do_process_device()
    else
      self.slicer = ProcessSlicer(do_process_device)
      self.processing = "Pasting device automation..."
      self.processing_changed_observable:bang()
      self.slicer:start()
    end
  else--if param_tab_selected then 
    local param = self:_resolve_parameter_from_idx(param_idx,device_idx,track_idx)
    if (yield_at == xAudioDeviceAutomation.YIELD_AT.NONE) then
      do_process_parameter(param)
    else
      self.slicer = ProcessSlicer(do_process_parameter,param)
      self.processing = "Pasting param. automation..."
      self.processing_changed_observable:bang()
      self.slicer:start()
    end
  end

end

---------------------------------------------------------------------------------------------------
-- @param done_callback (function - success(boolean), msg_or_err(string) )

function AutoMate:clear(done_callback)
  TRACE("AutoMate:clear()")
  
  local seq_range = self:_create_range()
  if not seq_range then 
    local err_msg = "Please select a range before copying"
    if done_callback then 
      done_callback(false,err_msg)
    end
  end

  -- support passive operation
  local track_idx,device_idx,param_idx = self:_get_current_focus()
  print(">>> track_idx,device_idx,param_idx",track_idx,device_idx,param_idx)
  
  if (prefs.selected_tab.value == AutoMatePrefs.TAB_DEVICES) then 
    local device = self:_resolve_device()
    if device then
      xAudioDevice.clear_automation(track_idx,device,seq_range)
    end
  else--if (prefs.selected_tab.value == AutoMatePrefs.TAB_PARAMETERS) then 
    local param = self:_resolve_parameter_from_idx(param_idx,device_idx,track_idx)
    if param then
      xParameterAutomation.clear(track_idx,param,seq_range)
    end
  end

  if done_callback then 
    done_callback(true)
  end

end

---------------------------------------------------------------------------------------------------
-- cut the specified range 
-- technically, the combination of "copy" and "clear" actions

function AutoMate:cut()
  TRACE("AutoMate:cut()")

  self:copy(function(success,msg_or_err)
    if success then 
      self:clear()
    end
    if msg_or_err then 
      renoise.app():show_message(msg_or_err)
    end
  end)
  
end

---------------------------------------------------------------------------------------------------
-- return current track, device and parameter index according to the current 'focus'
-- (which is determined by the application when having attached itself to the song - 
-- otherwise, from Renoise itself)

function AutoMate:_get_current_focus()
  if self._active then
    return self._selected_track_idx,
      self._selected_device_idx,
      self._selected_parameter_idx
  else 
    return rns.selected_track_index,
      self:_get_selected_device_index_in_renoise(rns.selected_track_index),
      self:_get_selected_parameter_index_in_renoise()
  end
end

---------------------------------------------------------------------------------------------------
-- obtain a sequencer-selection range representing the scope 
-- @return table (xSequencerSelection) or nil if no selection/range

function AutoMate:_create_range()
  TRACE("AutoMate:_create_range()")

  local rslt = nil

  if (prefs.selected_scope.value == xParameterAutomation.SCOPE.WHOLE_SONG) then 
    rslt = xSequencerSelection.get_entire_range()
  elseif (prefs.selected_scope.value == xParameterAutomation.SCOPE.WHOLE_PATTERN) then 
    rslt = xSequencerSelection.get_selected_index()
  elseif (prefs.selected_scope.value == xParameterAutomation.SCOPE.SELECTION_IN_SEQUENCE) then 
    rslt = xSequencerSelection.get_selected_range()
  elseif (prefs.selected_scope.value == xParameterAutomation.SCOPE.SELECTION_IN_PATTERN) then 
    rslt = xSequencerSelection.get_pattern_selection()
  end

  return rslt

end  


