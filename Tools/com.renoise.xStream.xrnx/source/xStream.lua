--[[===============================================================================================
xStream
===============================================================================================]]--
--[[

The main xStream class - where it all comes together.

#

]]

--=================================================================================================

class 'xStream'


-- options for internal/external MIDI output
xStream.OUTPUT_OPTIONS = {
  INTERNAL_AUTO = "internal_auto",  -- output routed notes, others are raw
  INTERNAL_RAW  = "internal_raw",   -- always output as raw
  --EXTERNAL_MIDI = "external_midi",  -- using PORT_NAME
  --EXTERNAL_OSC  = "external_osc",   -- using OSC_DEVICE_NAME
}

---------------------------------------------------------------------------------------------------
-- constructor

function xStream:__init(...)
  TRACE("xStream:__init(...)",...)

  local args = cLib.unpack_args(...)

  assert(type(args.midi_prefix)=="string","Expected argument 'midi_prefix' (string)")

  self.tool_name = args.tool_name

  --- xStreamPrefs, current settings
  -- (this needs to be set in advance, in main.lua)
  self.prefs = renoise.tool().preferences

  --- make sure userdata paths are up to date 
  xStreamUserData.USERDATA_ROOT = self.prefs.user_folder.value
  self.prefs.user_folder:add_notifier(function()
    xStreamUserData.USERDATA_ROOT = self.prefs.user_folder.value
    self:load_all_models()
  end)

  --- boolean, evaluate callbacks while playing
  self.active = property(self.get_active,self.set_active)
  self.active_observable = renoise.Document.ObservableBoolean(false)

  --- (bool) keep track of loop block state
  self.block_enabled = rns.transport.loop_block_enabled

  --- bool, flag raised when preset bank is eligible for export
  self.preset_bank_export_requested = false

  --- bool, flag raised when favorites are eligible for export
  self.favorite_export_requested = false

  --- bool, when true we automatically save favorites/presets
  self.autosave_enabled = false
  
  --- xStreamPos
  self.xpos = xStreamPos()  

  -- xStreamProcess
  self.process = xStreamProcess(self)

  self.prefs.scheduling:add_notifier(function()
    self.process.scheduling = self.prefs.scheduling.value
  end)

  self.selected_model = property(self.get_selected_model)
  self.selected_model_index = property(self.get_selected_model_index,self.set_selected_model_index)

  --- xStreamFavorites, favorited model+preset combinations
  self.favorites = xStreamFavorites(self)
  local favorites_notifier = function()    
    TRACE("xStream - favorites.favorites/grid_columns/grid_rows/modified_observable fired..")
    self.favorite_export_requested = true
  end
  self.favorites.favorites_observable:add_notifier(favorites_notifier)
  self.favorites.grid_columns_observable:add_notifier(favorites_notifier)
  self.favorites.grid_rows_observable:add_notifier(favorites_notifier)
  self.favorites.modified_observable:add_notifier(favorites_notifier)

  -- streaming options
  self.suspend_when_hidden = self.prefs.suspend_when_hidden.value
  xStreamPos.WRITEAHEAD_FACTOR = self.prefs.writeahead_factor

  --- xMidiIO, generic MIDI input/output handler
  self.midi_io = xMidiIO{
    midi_inputs = self.prefs.midi_inputs,
    midi_outputs = self.prefs.midi_outputs,
    multibyte_enabled = self.prefs.midi_multibyte_enabled.value,
    nrpn_enabled = self.prefs.midi_nrpn_enabled.value,
    terminate_nrpns = self.prefs.midi_terminate_nrpns.value,
    midi_callback_fn = function(xmsg)
      self:handle_midi_input(xmsg)
    end,
  }
  self.midi_io.midi_inputs_observable:add_notifier(function(arg)
    TRACE("*** self.midi_io.midi_inputs_observable",#self.midi_io.midi_inputs_observable,rprint(self.midi_io.midi_inputs_observable))
    self.prefs.midi_inputs = self.midi_io.midi_inputs_observable
  end)

  self.midi_io.midi_outputs_observable:add_notifier(function(arg)
    TRACE("*** self.midi_io.midi_outputs_observable",#self.midi_io.midi_inputs_observable,rprint(self.midi_io.midi_inputs_observable))
    self.prefs.midi_outputs = self.midi_io.midi_outputs_observable
  end)
  self.prefs.midi_multibyte_enabled:add_notifier(function()
    self.midi_io.interpretor.multibyte_enabled = self.prefs.midi_multibyte_enabled.value
  end)
  self.prefs.midi_nrpn_enabled:add_notifier(function()
    self.midi_io.interpretor.nrpn_enabled = self.prefs.midi_nrpn_enabled.value
  end)
  self.prefs.midi_terminate_nrpns:add_notifier(function()
    self.midi_io.interpretor.terminate_nrpns = self.prefs.midi_terminate_nrpns.value
  end)
  self.prefs.midi_terminate_nrpns:add_notifier(function()
    self.midi_io.interpretor.terminate_nrpns = self.prefs.midi_terminate_nrpns.value
  end)
  
  --- xVoiceManager
  self.voicemgr = xVoiceManager{
    column_allocation = true,
  }  
  self.voicemgr.released_observable:add_notifier(function(arg)
    TRACE("*** voicemgr.released_observable fired...")
    self:handle_voice_events(xVoiceManager.EVENT.RELEASED)
  end)
  self.voicemgr.triggered_observable:add_notifier(function()
    TRACE("*** voicemgr.triggered_observable fired...")
    self:handle_voice_events(xVoiceManager.EVENT.TRIGGERED)
  end)
  self.voicemgr.stolen_observable:add_notifier(function()
    TRACE("*** voicemgr.stolen_observable fired...")
    self:handle_voice_events(xVoiceManager.EVENT.STOLEN)
  end)

  --- xOscClient, internal MIDI routing
  self.osc_client = xOscClient{
    osc_host = self.prefs.osc_client_host.value,
    osc_port = self.prefs.osc_client_port.value,
  }
  self.osc_client.osc_host_observable:add_notifier(function()
    TRACE("*** osc_client.osc_host_observable fired...")
    self.prefs.osc_client_host.value = self.osc_client.osc_host_observable.value
  end)
  self.osc_client.osc_port_observable:add_notifier(function()
    TRACE("*** osc_client.osc_port_observable fired...")
    self.prefs.osc_client_port.value = self.osc_client.osc_port_observable.value
  end)
  self.osc_client._test_failed_observable:add_notifier(function()
    TRACE("*** osc_client._test_failed_observable fired...")
    -- TODO make user aware of the issue
  end)

  --- xStreamUI 
  self.ui = xStreamUI{
    xstream = self,
    waiting_to_show_dialog = self.prefs.autostart.value,
    midi_prefix = args.midi_prefix,
  }
  self.ui.show_editor = self.prefs.show_editor.value
  self.ui.args_panel.visible = self.prefs.model_args_visible.value
  self.ui.presets.visible = self.prefs.presets_visible.value
  self.ui.favorites.pinned = self.prefs.favorites_pinned.value
  self.ui.dialog_visible_observable:add_notifier(function()
    TRACE("xStream  - ui.dialog_visible_observable fired...")
    self.process.models:select_launch_model()
    local file_path = self.favorites:get_path()
    local success,err = self.favorites:import(file_path)
    if not success and err then 
      LOG("*** Failed to import favorites",err)
    end 
    self.autosave_enabled = true
  end)


  --== tool notifications ==--

  renoise.tool().app_new_document_observable:add_notifier(function()
    TRACE("xStream - app_new_document_observable fired...")
    self:attach_to_song()
  end)

  renoise.tool().app_release_document_observable:add_notifier(function()
    TRACE("xStream - app_release_document_observable fired...")
    self:stop()
  end)

  renoise.tool().app_idle_observable:add_notifier(function()    
    self:on_idle()
  end)


  --== initialize ==--

  self:attach_to_song()

  self:load_all_models()

  self.ui:update()

  self.xpos:reset()
  
  self.xpos.callback_observable:add_notifier(function()
    self.process:output()
  end)
  self.xpos.refresh_observable:add_notifier(function()
    self.process:refresh()
  end)

end


---------------------------------------------------------------------------------------------------
-- Getters/Setters
---------------------------------------------------------------------------------------------------
-- Set active state of processes

function xStream:set_active(val)
  TRACE("xStream:set_active(val)",val)
  self.process.active = val
end

function xStream:get_active()
  TRACE("xStream:get_active()")
  return self.process.active
end

---------------------------------------------------------------------------------------------------

function xStream:get_selected_model()
  return self.process.models.selected_model
end

---------------------------------------------------------------------------------------------------

function xStream:get_selected_model_index()
  return self.process.models.selected_model_index
end

function xStream:set_selected_model_index(val)
  self.process.models.selected_model_index = val
end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------
-- Stop live streaming

function xStream:stop()
  TRACE("xStream:stop()")
  self.process:stop()
end

---------------------------------------------------------------------------------------------------
-- Activate live streaming 
-- @param [playmode], renoise.Transport.PLAYMODE - use CONTINUE_PATTERN if not defined

function xStream:start(playmode)
  TRACE("xStream:start(playmode)",playmode)

  if not playmode then 
    playmode = renoise.Transport.PLAYMODE_CONTINUE_PATTERN
  end 

  self.process:start(playmode)
  self.xpos:start(playmode)
end

---------------------------------------------------------------------------------------------------
-- Begin live streaming from pattern start 

function xStream:start_and_play()
  TRACE("xStream:start_and_play()")
  if not rns.transport.playing then
    rns.transport.playback_pos = rns.transport.edit_pos
  end
  self:start(renoise.Transport.PLAYMODE_RESTART_PATTERN)
end

---------------------------------------------------------------------------------------------------
-- (Re)load all models - triggered on startup and when userdata folder has changed

function xStream:load_all_models()
  TRACE("xStream:load_all_models()")

  local models_path = xStreamModels.get_models_path()
  
  self.process:reset()
  self.process.models:remove_all()
  self.process.models:load_all(models_path)

end 

---------------------------------------------------------------------------------------------------
-- Bring focus to the relevant model/preset/bank, 
-- following a selection/trigger in the favorites grid

function xStream:focus_to_favorite(idx)
  TRACE("xStream:focus_to_favorite(idx)",idx)

  local selected = self.favorites.items[idx]
  if not selected then
    return
  end

  self.favorites.last_selected_index = idx

  local model_idx,model = self.process.models:get_by_name(selected.model_name)
  if model_idx then
    --print("about to set model index to",model_idx)
    self.selected_model_index = model_idx
    local bank_names = model:get_preset_bank_names()
    local bank_idx = table.find(bank_names,selected.preset_bank_name)
    if bank_idx then
      --print("about to set preset bank index to",bank_idx)
      model.selected_preset_bank_index = bank_idx
      if selected.preset_index then
        if (selected.preset_index <= #model.selected_preset_bank.presets) then
          --print("about to set preset index to",selected.preset_index,"existing",model.selected_preset_bank.selected_preset_index)
          model.selected_preset_bank.selected_preset_index = selected.preset_index
        end
      else
        LOG("Focus failed - Missing preset")
      end
    else
      LOG("Focus failed - Missing preset bank")
    end
  else
    LOG("Focus failed - Missing model")
  end

end

---------------------------------------------------------------------------------------------------
-- Perform periodic updates

function xStream:on_idle()
  --TRACE("xStream:on_idle()")

  local dialog_visible = self.ui:dialog_is_visible()
  if self.suspend_when_hidden and not dialog_visible then
    --LOG("suspended - prevent idle update")
    return
  end

  -- update user-interface
  if dialog_visible then
    self.ui:on_idle()
  end

  -- track changes to callback, poll arguments
  if self.selected_model then
    self.selected_model:on_idle()
  end

  -- TODO optimize performance by exporting only while not playing
  if self.preset_bank_export_requested then
    self.preset_bank_export_requested = false
    if self.autosave_enabled then
      local preset_bank = self.selected_model.selected_preset_bank
      preset_bank:save()
    end
  elseif self.favorite_export_requested then
    self.favorite_export_requested = false
    if self.autosave_enabled then
      self.favorites:save()
    end
  end

  -- track when blockloop changes (update scheduling)
  if (self.block_enabled ~= rns.transport.loop_block_enabled) then
    --print("xStream - block_enabled changed...")
    self.block_enabled = rns.transport.loop_block_enabled
    if rns.transport.playing then
      self.process:compute_scheduling_pos()
    end
  end

end


---------------------------------------------------------------------------------------------------
-- [app] call when a new document becomes available

function xStream:attach_to_song()
  TRACE("xStream:attach_to_song()")

  self:stop()

  local selected_track_index_notifier = function()
    TRACE("*** selected_track_index_notifier fired...")
    self.process:set_track_index(rns.selected_track_index)
  end

  local playing_notifier = function()
    TRACE("playing_notifier()")

    if not rns.transport.playing then 
      self:stop()
    else 

      -- playback started 

      local dialog_visible = self.ui:dialog_is_visible() 
      if not dialog_visible and self.suspend_when_hidden then
        LOG("Suspended - don't stream")
        return
      end

      if rns.transport.edit_mode then
        if (self.prefs.start_option.value == xStreamPrefs.START_OPTION.ON_PLAY_EDIT) then
          self:start() 
        end
      else
        if (self.prefs.start_option.value == xStreamPrefs.START_OPTION.ON_PLAY) then
          self:start()
        end
      end
    end

  end

  local edit_notifier = function()
    TRACE("edit_notifier()")

    if rns.transport.edit_mode then
      local dialog_visible = self.ui:dialog_is_visible() 
      if not dialog_visible and self.suspend_when_hidden then
        LOG("Suspended - don't stream")
        return
      end
      if rns.transport.playing and
        (self.prefs.start_option.value == xStreamPrefs.START_OPTION.ON_PLAY_EDIT) 
      then
        self:start()
      end
    elseif (self.prefs.start_option.value == xStreamPrefs.START_OPTION.ON_PLAY_EDIT) then
      self:stop()
    end

  end

  cObservable.attach(rns.transport.playing_observable,playing_notifier)
  cObservable.attach(rns.transport.edit_mode_observable,edit_notifier)
  cObservable.attach(rns.selected_track_index_observable,selected_track_index_notifier)

  playing_notifier()
  edit_notifier()
  selected_track_index_notifier()

  if self.selected_model then
    self.selected_model:attach_to_song()
  end

end

---------------------------------------------------------------------------------------------------
--- [app+process]
-- @param xmsg (xMidiMessage)

function xStream:handle_midi_input(xmsg)
  TRACE("xStream:handle_midi_input(xmsg)",xmsg,self)

  if not self.process.active then
    LOG("Stream not active - ignore MIDI input")
    return
  end

  if not self.selected_model then
    LOG("No model selected, ignore MIDI input")
    return
  end

  -- pass to voicemanager (which might redefine the message in case
  -- we have configured it to follow the active track/instrument/etc)
  local _xmsg = self.voicemgr:input_message(xmsg)
  --print("handle_midi_input POST",_xmsg)
  if _xmsg then
    xmsg = _xmsg
  end

  -- pass to event handlers (if any)
  local event_key = "midi."..tostring(xmsg.message_type)
  self.process:handle_event(event_key,xmsg)

end

---------------------------------------------------------------------------------------------------
-- [process]
-- @param evt (xVoiceManager.EVENT)

function xStream:handle_voice_events(evt)
  TRACE("xStream:handle_voice_events(evt)",evt)

  local index = nil
  if (evt == xVoiceManager.EVENT.TRIGGERED) then
    index = self.voicemgr.triggered_index
  elseif (evt == xVoiceManager.EVENT.RELEASED) then
    index = self.voicemgr.released_index
  elseif (evt == xVoiceManager.EVENT.STOLEN) then
    index = self.voicemgr.stolen_index
  else
    error("Unknown xVoiceManager.EVENT")
  end

  local voice = self.voicemgr.voices[index]
  --print("handle_voice_events - voice",voice,index)

  -- only pass when track is right
  --[[
  if not (voice.track_index == self.track_index) then
    LOG("Ignore voice events from other tracks")
    return
  end
  ]]

  -- pass to event handlers (if any)
  local event_key = "voice."..evt
  self.process:handle_event(event_key,{
    index = index,
    type = evt
  })

end

---------------------------------------------------------------------------------------------------
-- this method is meant to be accessible from callbacks

function xStream:output_message(xmsg,mode)
  TRACE("xStream:output_message(xmsg,mode)",xmsg,mode)

  if (mode == xStream.OUTPUT_OPTIONS.INTERNAL_AUTO) then
    return self.osc_client:trigger_auto(xmsg)
  elseif (mode == xStream.OUTPUT_OPTIONS.INTERNAL_RAW) then
    return self.osc_client:trigger_raw(xmsg)
  else
    return false
  end

end

---------------------------------------------------------------------------------------------------

function xStream:__tostring()
  return type(self) 
end

---------------------------------------------------------------------------------------------------
-- Static methods
---------------------------------------------------------------------------------------------------
-- @param str_name (string), e.g. "events.midi.note_on" or "main"
-- @return string, type - "main","data" or "events"
-- @return string, depends on context 
-- @return string, -//-
-- @return string, -//-

function xStream.parse_callback_type(str_name)
  TRACE("xStream:parse_callback_type(str_name)",str_name)

  if (str_name == "main") then
    return xStreamModel.CB_TYPE.MAIN
  elseif (str_name:sub(0,5) == "data.") then
    local key = str_name:sub(6)
    return xStreamModel.CB_TYPE.DATA,key
  elseif (str_name:sub(0,7) == "events.") then
    local key = str_name:sub(8)    
    local parts = cString.split(key,"%.") -- split at dot
    return xStreamModel.CB_TYPE.EVENTS,parts[1],parts[2],parts[3]
  end

end


