--[[============================================================================
xStream
============================================================================]]--
--[[

The main xStream class - where it all comes together
.
#

TODO refactor the blockloop tracking into the xStreamPos class
and implement a "refresh_fn" handler for recalculating the read buffer
(see idle method for a partial implementation of this)

]]

--==============================================================================

class 'xStream'

-- all userdata
xStream.FAVORITES_FILE_PATH = "favorites.xml"
xStream.MODELS_FOLDER       = "models/"
xStream.PRESET_BANK_FOLDER  = "presets/"

-- automation interpolation mode
xStream.PLAYMODES = {"Points","Linear","Cubic"}
xStream.PLAYMODE = {
  POINTS = 1,
  LINEAR = 2,
  CUBIC = 3,
}

-- accessible to callback
xStream.OUTPUT_MODE = {
  STREAMING = 1,
  TRACK = 2,
  SELECTION = 3,
}

-- model/preset scheduling 
xStream.SCHEDULES = {"Line","Beat","Bar","Block","Pattern"}
xStream.SCHEDULE = {
  LINE = 1,
  BEAT = 2,
  BAR = 3,
  BLOCK = 4,
  PATTERN = 5,
}

--- choose a mute mode
-- NONE = do nothing except to output 'nothing'
--    note: when combined with 'clear', this makes it possible to 
--    record into a track, using the mute button as a 'output switch'
-- OFF = insert OFF across columns, then nothing
--    TODO when 'clear_undefined' is true, OFF is only written when
--    there is not an existing note at that position
xStream.MUTE_MODES = {"None","Off"}
xStream.MUTE_MODE = {
  NONE = 1,
  OFF = 2,
}

-- options for internal/external MIDI output
xStream.OUTPUT_OPTIONS = {
  INTERNAL_AUTO = "internal_auto",  -- output routed notes, others are raw
  INTERNAL_RAW  = "internal_raw",   -- always output as raw
  --EXTERNAL_MIDI = "external_midi",  -- using PORT_NAME
  --EXTERNAL_OSC  = "external_osc",   -- using OSC_DEVICE_NAME
}

-------------------------------------------------------------------------------
-- constructor

function xStream:__init(...)

  local args = xLib.unpack_args(...)

  assert(type(args.midi_prefix)=="string","Expected argument 'midi_prefix' (string)")

  --- xStreamPrefs, current settings
  self.prefs = renoise.tool().preferences

  --- xStreamBuffer
  self.buffer = xStreamBuffer(self)

  --- xSongPos.OUT_OF_BOUNDS, handle song boundaries
  self.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP

  --- xSongPos.BLOCK_BOUNDARY, handle block boundaries
  self.block_mode = xSongPos.BLOCK_BOUNDARY.SOFT

  --- xSongPos.LOOP_BOUNDARY, handle pattern/seq.loop boundaries
  self.loop_mode = xSongPos.LOOP_BOUNDARY.SOFT

  --- enum, one of xStream.OUTPUT_MODE
  -- usually STREAMING, but temporarily set to a different
  -- value while applying output to TRACK/SELECTION
  self.output_mode = xStream.OUTPUT_MODE.STREAMING

  --- (bool) keep track of loop block state
  self.block_enabled = rns.transport.loop_block_enabled

  --- string, last file path from where we imported models ('load_models')
  self.last_models_path = nil

  --- bool, flag raised when preset bank is eligible for export
  self.preset_bank_export_requested = false

  --- bool, flag raised when favorites are eligible for export
  self.favorite_export_requested = false

  --- bool, when true we automatically save favorites/presets
  self.autosave_enabled = false
  
  --- xStream.PLAYMODE (string-based enum)
  self.automation_playmode = property(self.get_automation_playmode,self.set_automation_playmode)
  self.automation_playmode_observable = renoise.Document.ObservableNumber(xStream.PLAYMODE.LINEAR)

  --- string, value depends on success/failure during last callback 
  -- "" = no problem
  -- "Some error occurred" = description of error 
  self.callback_status_observable = renoise.Document.ObservableString("")

  --- int, decide which track to target (0 = none)
  self.track_index = property(self.get_track_index,self.set_track_index)
  self.track_index_observable = renoise.Document.ObservableNumber(0)

  --- renoise.DeviceParameter, selected automation parameter (can be nil)
  self.device_param = property(self.get_device_param,self.set_device_param)
  self._device_param = nil

  --- int, derived from device_param (0 = none)
  self.device_param_index_observable = renoise.Document.ObservableNumber(0)

  --- boolean, whether to include hidden (not visible) columns
  self.include_hidden = property(self.get_include_hidden,self.set_include_hidden)
  self.include_hidden_observable = renoise.Document.ObservableBoolean(false)

  --- boolean, determine how to respond to 'undefined' content
  self.clear_undefined = property(self.get_clear_undefined,self.set_clear_undefined)
  self.clear_undefined_observable = renoise.Document.ObservableBoolean(true)

  --- boolean, whether to expand (sub-)columns when writing data
  self.expand_columns = property(self.get_expand_columns,self.set_expand_columns)
  self.expand_columns_observable = renoise.Document.ObservableBoolean(true)

  --- xStream.MUTE_MODE, controls how muting is done
  self.mute_mode = property(self.get_mute_mode,self.set_mute_mode)
  self.mute_mode_observable = renoise.Document.ObservableNumber(xStream.MUTE_MODE.OFF)

  --- bool, set to true to silence output
  self.muted = property(self.get_muted,self.set_muted)
  self.muted_observable = renoise.Document.ObservableBoolean(false)

  --- xStream.SCHEDULE, active scheduling mode
  self.scheduling = property(self.get_scheduling,self.set_scheduling)
  self.scheduling_observable = renoise.Document.ObservableNumber(xStream.SCHEDULE.BEAT)

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
  -- updated as external conditions change: for example, if we had 
  -- scheduled something to happen at the 'next pattern' and in 
  -- the meantime, pattern loop was enabled 
  self._scheduled_pos = nil

  --- int, read-only - set via schedule_item()
  self.scheduled_preset_index = property(self.get_scheduled_preset_index)
  self.scheduled_preset_index_observable = renoise.Document.ObservableNumber(0)

  --- int, read-only - set via schedule_item()
  self.scheduled_preset_bank_index = property(self.get_scheduled_preset_bank_index)
  self.scheduled_preset_bank_index_observable = renoise.Document.ObservableNumber(0)

  --- bool, true when we should output during live streaming 
  self.active = property(self.get_active,self.set_active)
  self.active_observable = renoise.Document.ObservableBoolean(false)

  --- table<xStreamModel>, registered models 
  self.models = {}

  --- xStreamFavorites, favorited model+preset combinations
  self.favorites = xStreamFavorites(self)

  --- table<int>, receive notification when models are added/removed
  -- the table itself contains just the model indices
  self.models_observable = renoise.Document.ObservableNumberList()

  --- int, the model index, 1-#models or 0 when none are available
  self.selected_model_index = property(self.get_selected_model_index,self.set_selected_model_index)
  self.selected_model_index_observable = renoise.Document.ObservableNumber(0)

  --- xStreamModel, read-only - nil when none are available
  self.selected_model = nil

  -- supporting classes --

  --- xStreamPos, set up our streaming handler
  self.stream = xStreamPos()
  self.stream.callback_fn = function()
    if self.active and self.selected_model then
      if self._scheduled_pos then
        if (xSongPos(self.stream.playpos) == self._scheduled_pos) then
          --print("apply scheduled model/preset",self.stream.playpos,self._scheduled_pos,self._scheduled_pos.lines_travelled)
          self:apply_schedule()
        end
      end
      local live_mode = true
      self.buffer:write_output(self.stream.writepos,nil,live_mode)
    end
  end
  self.stream.refresh_fn = function()
    --print("*** xStream - abrupt position-change")
    if self.active then
      self.buffer:update_read_buffer()
    end
  end

  --- xStreamUI, built-in user interface
  self.ui = nil
  
  --- xMidiIO, generic MIDI input/output handler
  self.midi_io = nil

  -- xOscClient, internal MIDI routing
  self.osc_client = nil

  ---  xVoiceManager
  self.voicemgr = nil


  -- initialize --

  self.stream:determine_writeahead()

  self.osc_client = xOscClient{
    osc_host = self.prefs.osc_client_host.value,
    osc_port = self.prefs.osc_client_port.value,
    first_run = self.prefs.osc_client_first_run.value,
  }

  self.ui = xStreamUI{
    xstream = self,
    waiting_to_show_dialog = self.prefs.autostart.value,
    midi_prefix = args.midi_prefix,
  }

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

  self.voicemgr = xVoiceManager{
    column_allocation = true,
  }

  -- [app] favorites

  local favorites_notifier = function()    
    TRACE("*** xStream - favorites.favorites/grid_columns/grid_rows/modified_observable fired..")
    self.favorite_export_requested = true
  end
  self.favorites.favorites_observable:add_notifier(favorites_notifier)
  self.favorites.grid_columns_observable:add_notifier(favorites_notifier)
  self.favorites.grid_rows_observable:add_notifier(favorites_notifier)
  self.favorites.modified_observable:add_notifier(favorites_notifier)

  --vDialog.__init(self,...)

  self:load_models(self.prefs.user_folder.value..xStream.MODELS_FOLDER)


  -- apply preferences --

  -- ui options
  self.ui.show_editor = self.prefs.show_editor.value
  self.ui.args_panel.visible = self.prefs.model_args_visible.value
  self.ui.presets.visible = self.prefs.presets_visible.value
  self.ui.favorites.pinned = self.prefs.favorites_pinned.value
  self.ui.editor_visible_lines = self.prefs.editor_visible_lines.value

  -- streaming options
  self.scheduling = self.prefs.scheduling.value
  self.mute_mode = self.prefs.mute_mode.value
  self.suspend_when_hidden = self.prefs.suspend_when_hidden.value
  self.stream.writeahead_factor = self.prefs.writeahead_factor.value

  -- output outputs
  self.automation_playmode = self.prefs.automation_playmode.value
  self.include_hidden = self.prefs.include_hidden.value
  self.clear_undefined = self.prefs.clear_undefined.value
  self.expand_columns = self.prefs.expand_columns.value

  -- preferences -> app --

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
  self.prefs.scheduling:add_notifier(function()
    self.scheduling_observable.value = self.prefs.scheduling.value
  end)

  -- xStream app --

  self.automation_playmode_observable:add_notifier(function()
    TRACE("*** main.lua - self.automation_playmode_observable fired...")
    self.prefs.automation_playmode.value = self.automation_playmode_observable.value
  end)

  self.stream.writeahead_factor_observable:add_notifier(function()
    TRACE("*** main.lua - self.stream.writeahead_factor_observable fired...")
    self.prefs.writeahead_factor.value = self.stream.writeahead_factor_observable.value
  end)

  self.include_hidden_observable:add_notifier(function()
    TRACE("*** main.lua - self.include_hidden_observable fired...")
    self.prefs.include_hidden.value = self.include_hidden_observable.value
  end)

  self.clear_undefined_observable:add_notifier(function()
    TRACE("*** main.lua - self.clear_undefined_observable fired...")
    self.prefs.clear_undefined.value = self.clear_undefined_observable.value
  end)

  self.expand_columns_observable:add_notifier(function()
    TRACE("*** main.lua - self.expand_columns_observable fired...")
    self.prefs.expand_columns.value = self.expand_columns_observable.value
  end)

  self.mute_mode_observable:add_notifier(function()
    TRACE("*** selfUI - self.mute_mode_observable fired...")
    self.prefs.mute_mode.value = self.mute_mode_observable.value
  end)

  -- xStream UI --

  self.ui.show_editor_observable:add_notifier(function()
    TRACE("*** selfUI - self.ui.show_editor_observable fired...")
    self.prefs.show_editor.value = self.ui.show_editor_observable.value
  end)

  self.ui.tool_options_visible_observable:add_notifier(function()
    TRACE("*** selfUI - self.ui.tool_options_visible_observable fired...")
    self.prefs.tool_options_visible.value = self.ui.tool_options_visible_observable.value
  end)

  self.ui.model_browser_visible_observable:add_notifier(function()
    TRACE("*** selfUI - self.ui.model_browser_visible_observable fired...")
    self.prefs.model_browser_visible.value = self.ui.model_browser_visible
  end)

  self.ui.args_panel.visible_observable:add_notifier(function()
    TRACE("*** selfUI - self.ui.args_panel.visible_observable fired...")
    self.prefs.model_args_visible.value = self.ui.args_panel.visible
  end)

  self.ui.presets.visible_observable:add_notifier(function()
    TRACE("*** selfUI - self.ui.presets.visible_observable fired...")
    self.prefs.presets_visible.value = self.ui.presets.visible
  end)

  self.ui.favorites.pinned_observable:add_notifier(function()
    TRACE("*** selfUI - self.ui.favorites.pinned_observable fired...")
    self.prefs.favorites_pinned.value = self.ui.favorites.pinned
  end)

  self.ui.editor_visible_lines_observable:add_notifier(function()
    TRACE("*** selfUI - self.ui.editor_visible_lines_observable fired...")
    self.prefs.editor_visible_lines.value = self.ui.editor_visible_lines
  end)

  self.ui.dialog_visible_observable:add_notifier(function()
    TRACE("*** xStream - ui.dialog_visible_observable fired...")
    self:select_launch_model()
    self.favorites:import("./favorites.xml")
    self.autosave_enabled = true
  end)

  self.ui.dialog_became_active_observable:add_notifier(function()
    TRACE("*** xStream - ui.dialog_became_active_observable fired...")
  end)

  self.ui.dialog_resigned_active_observable:add_notifier(function()
    TRACE("*** xStream - ui.dialog_resigned_active_observable fired...")
  end)

  -- midi I/O --

  self.midi_io.midi_inputs_observable:add_notifier(function(arg)
    TRACE("*** self.midi_io.midi_inputs_observable",#self.midi_io.midi_inputs_observable,rprint(self.midi_io.midi_inputs_observable))
    self.prefs.midi_inputs = self.midi_io.midi_inputs_observable
  end)

  self.midi_io.midi_outputs_observable:add_notifier(function(arg)
    TRACE("*** self.midi_io.midi_outputs_observable",#self.midi_io.midi_inputs_observable,rprint(self.midi_io.midi_inputs_observable))
    self.prefs.midi_outputs = self.midi_io.midi_outputs_observable
  end)

  -- voicemgr --

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

  -- osc client --

  self.osc_client.first_run_observable:add_notifier(function()
    TRACE("*** osc_client.first_run_observable fired...")
    self.prefs.osc_client_first_run.value = self.osc_client.first_run_observable.value
  end)
  self.osc_client.osc_host_observable:add_notifier(function()
    TRACE("*** osc_client.osc_host_observable fired...")
    self.prefs.osc_client_host.value = self.osc_client.osc_host_observable.value
  end)
  self.osc_client.osc_port_observable:add_notifier(function()
    TRACE("*** osc_client.osc_port_observable fired...")
    self.prefs.osc_client_port.value = self.osc_client.osc_port_observable.value
  end)

  -- tool --

  renoise.tool().app_new_document_observable:add_notifier(function()
    TRACE("*** xStream - app_new_document_observable fired...")
    self:attach_to_song()
  end)

  renoise.tool().app_release_document_observable:add_notifier(function()
    TRACE("*** xStream - app_release_document_observable fired...")
    self:stop()
  end)

  renoise.tool().app_idle_observable:add_notifier(function()    
    self:on_idle()
  end)


  self:attach_to_song()

end

-------------------------------------------------------------------------------
-- class methods
-------------------------------------------------------------------------------
-- [app] create new model from scratch
-- @param str_name (string)
-- @return bool, true when model got created
-- @return string, error message on failure

function xStream:create_model(str_name)
  TRACE("xStream:create_model(str_name)",str_name)

  assert(type(str_name) == "string")

  local model = xStreamModel(self)
  model.name = str_name

  local str_name_validate = xStreamModel.get_suggested_name(str_name)
  --print(">>> str_name,str_name_validate",str_name,str_name_validate)
  if (str_name ~= str_name_validate) then
    return false,"*** Error: a model already exists with this name."
  end

  model.modified = true
  model.name = str_name
  model.file_path = ("%s%s.lua"):format(self.last_models_path,str_name)
  model:parse_definition({
    callback = [[-------------------------------------------------------------------------------
-- Empty configuration
-------------------------------------------------------------------------------

-- Use this as a template for your own creations. 
--xline.note_columns[1].note_string = "C-4"
    
]],
  })

  self:add_model(model)
  self.selected_model_index = #self.models
  
  local got_saved,err = model:save()
  if not got_saved and err then
    return false,err
  end

  return true

end

-------------------------------------------------------------------------------
-- [app] 

function xStream:add_model(model)
  TRACE("xStream:add_model(model)")

  model.xstream = self
  table.insert(self.models,model)
  self.models_observable:insert(#self.models)

end

-------------------------------------------------------------------------------
-- [app] remove all models

function xStream:remove_models()
  TRACE("xStream:remove_models()")

  for k,_ in ripairs(self.models) do
    self:remove_model(k)
  end 

end

-------------------------------------------------------------------------------
-- [app] remove specific model from list
-- @param model_idx (int)

function xStream:remove_model(model_idx)
  TRACE("xStream:remove_model(model_idx)",model_idx)

  if (model_idx == self.selected_model_index) then
    if self.active then
      self:stop()
    end 
  end

  table.remove(self.models,model_idx)
  self.models_observable:remove(model_idx)

  if (self.selected_model_index == model_idx) then
    --print("remove_model - selected_model_index = 0")
    self.selected_model_index = 0
  end

end

-------------------------------------------------------------------------------
-- [app] delete from disk, the remove from list
-- @param model_idx (int)
-- @return bool, true when we deleted the file
-- @return string, error message when failed

function xStream:delete_model(model_idx)
  TRACE("xStream:delete_model(model_idx)",model_idx)

  local model = self.models[model_idx]
  --print("model",model,"model.file_path",model.file_path)
  local success,err = os.remove(model.file_path)
  if not success then
    return false,err
  end

  self:remove_model(model_idx)

  return true

end

-------------------------------------------------------------------------------
-- [app] load all models (files ending with .lua) in a given folder
-- log potential errors during parsing

function xStream:load_models(str_path)
  TRACE("xStream:load_models(str_path)",str_path)

  assert(type(str_path)=="string","Expected string as argument")

  if not io.exists(str_path) then
    LOG("*** Could not open model, folder does not exist:"..str_path)
    return
  end

  local log_msg = ""
  for _, filename in pairs(os.filenames(str_path, "*.lua")) do
    --print("...",filename)
    local model = xStreamModel(self)
    local model_file_path = str_path..filename
    local passed,err = model:load_definition(model_file_path)
    --print("passed,err",passed,err)
    if not passed then
      log_msg = log_msg .. err .. "\n"
    else
      --print("Add model",filename)
      self:add_model(model)
    end
  end

  if (log_msg ~= "") then
     LOG(log_msg.."*** WARNING One or more models failed to load during startup")
  end

  -- save the path for later use
  -- (when creating 'virtual' models, this is where they will be saved)
  self.last_models_path = str_path

end

-------------------------------------------------------------------------------
-- [app] 
-- @param no_asterisk (bool), don't add asterisk to modified models
-- return table<string>

function xStream:get_model_names(no_asterisk)
  TRACE("xStream:get_model_names(no_asterisk)",no_asterisk)

  local t = {}
  for _,v in ipairs(self.models) do
    if no_asterisk then
      table.insert(t,v.name)
    else
      table.insert(t,v.modified and v.name.."*" or v.name)
    end
  end
  return t

end

-------------------------------------------------------------------------------
-- [app] 
-- bring focus to the relevant model/preset/bank, 
-- following a selection/trigger in the favorites grid

function xStream:focus_to_favorite(idx)
  TRACE("xStream:focus_to_favorite(idx)",idx)

  local selected = self.favorites.items[idx]
  if not selected then
    return
  end

  self.favorites.last_selected_index = idx

  local model_idx,model = self:get_model_by_name(selected.model_name)
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

-------------------------------------------------------------------------------
-- [app] 
-- @param model_name (string)
-- @return int (index) or nil
-- @return xStreamModel or nil

function xStream:get_model_by_name(model_name)
  --TRACE("xStream:get_model_by_name(model_name)",model_name)

  if not self.models then
    return 
  end

  for k,v in ipairs(self.models) do
    if (v.name == model_name) then
      return k,v
    end
  end

end

-------------------------------------------------------------------------------
-- [process]
-- schedule model or model+preset
-- @param model_name (string), unique name of model
-- @param preset_index (int),  preset to dial in - optional
-- @param preset_bank_name (string), preset bank - optional, TODO
-- @return true when item got scheduled, false if not
-- @return err (string), the reason scheduling failed

function xStream:schedule_item(model_name,preset_index,preset_bank_name)
  TRACE("xStream:schedule_item(model_name,preset_index,preset_bank_name)",model_name,preset_index,preset_bank_name)

  if not self.active then
    return false,"Can't schedule items while inactive"
  end

  assert(model_name,"Required argument missing: model_name")
  assert((type(model_name)=="string"),"Invalid argument type: model_name - expected string")

  local model_index,model = self:get_model_by_name(model_name)
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
    --print("xStream:schedule_item - self.scheduled_preset_bank_index",preset_bank_index)
  end

  local favorite_idx = self.favorites:get(model_name,preset_index,preset_bank_name)
  --print("favorite_idx",favorite_idx)
  if favorite_idx then
    self.scheduled_favorite_index_observable.value = favorite_idx
  end

  -- now figure out the time
  self._scheduled_pos = nil

  if (self.scheduling == xStream.SCHEDULE.LINE) then
    if self._scheduled_model then
      self:apply_schedule() -- set immediately 
    end
    --print("*** xStream.SCHEDULE.LINE - applied preset,model...")
  else
    self:compute_scheduling_pos()
  end

  -- if scheduled event is going to take place within the
  -- space of already-computed lines, wipe the buffer
  if self._scheduled_pos then
    local happening_in_lines = self._scheduled_pos.lines_travelled
      - (self.stream.writepos.lines_travelled)
    --print("happening_in_lines",happening_in_lines)
    if (happening_in_lines <= self.stream.writeahead) then
      --print("wipe the buffer")
      self.buffer:wipe_futures()
    end
  end

end

-------------------------------------------------------------------------------
-- [process]
-- schedule, or re-schedule (when external conditions change)

function xStream:compute_scheduling_pos()
  TRACE("xStream:compute_scheduling_pos()")

  self._scheduled_pos = xSongPos(self.stream.playpos)
  self._scheduled_pos.lines_travelled = self.stream.writepos.lines_travelled

  self._scheduled_pos.bounds_mode = self.bounds_mode
  self._scheduled_pos.block_boundary = self.block_mode
  self._scheduled_pos.loop_boundary = self.loop_mode

  --print("*** xStream.SCHEDULE.PATTERN - PRE self._scheduled_pos",self._scheduled_pos)
  if self._scheduled_pos then
    --print("*** xStream.SCHEDULE.PATTERN - PRE self._scheduled_pos.lines_travelled",self._scheduled_pos.lines_travelled)
  end

  if (self.scheduling == xStream.SCHEDULE.LINE) then
    error("Scheduling should already have been applied")
  elseif (self.scheduling == xStream.SCHEDULE.BEAT) then
    self._scheduled_pos:next_beat()
    --print("*** xStream.SCHEDULE.BEAT - self._scheduled_pos",self._scheduled_pos)
  elseif (self.scheduling == xStream.SCHEDULE.BAR) then
    self._scheduled_pos:next_bar()
    --print("*** xStream.SCHEDULE.BAR - self._scheduled_pos",self._scheduled_pos)
  elseif (self.scheduling == xStream.SCHEDULE.BLOCK) then
    self._scheduled_pos:next_block()
    --print("*** xStream.SCHEDULE.BLOCK - self._scheduled_pos",self._scheduled_pos)
  elseif (self.scheduling == xStream.SCHEDULE.PATTERN) then
    -- if we are within a blockloop, do not set a schedule position
    -- (once the blockloop is disabled, this function is invoked)
    if not rns.transport.loop_block_enabled then
      self._scheduled_pos:next_pattern()
      --print("*** xStream.SCHEDULE.PATTERN - self._scheduled_pos",self._scheduled_pos)
    else
      self._scheduled_pos = nil
    end
  else
    error("Unknown scheduling mode")
  end

  --print("*** xStream.SCHEDULE.PATTERN - POST self._scheduled_pos",self._scheduled_pos)
  if self._scheduled_pos then
    --print("*** xStream.SCHEDULE.PATTERN - POST self._scheduled_pos.lines_travelled",self._scheduled_pos.lines_travelled)
  end

end

-------------------------------------------------------------------------------
-- [process]
-- invoked when cancelling schedule, or scheduled event has happened

function xStream:clear_schedule()
  TRACE("xStream:clear_schedule()")

  self._scheduled_model = nil
  self._scheduled_pos = nil
  self.scheduled_model_index_observable.value = 0
  self.scheduled_preset_index_observable.value = 0
  self.scheduled_preset_bank_index_observable.value = 0
  self.scheduled_favorite_index_observable.value = 0

end

-------------------------------------------------------------------------------
-- [process]
-- switch to scheduled model/preset

function xStream:apply_schedule()
  TRACE("xStream:apply_schedule()")

  -- remember value (otherwise lost when setting model)
  local preset_index = self.scheduled_preset_index
  local preset_bank_index = self.scheduled_preset_bank_index

  if not self.scheduled_model then
    self:clear_schedule()
    return
  end

  self.selected_model_index = self.scheduled_model_index

  if preset_bank_index then
    self.selected_model.selected_preset_bank_index = preset_bank_index
  end

  self.selected_model.selected_preset_bank.selected_preset_index = preset_index

  self:clear_schedule()

end

-------------------------------------------------------------------------------
-- get/set methods
-------------------------------------------------------------------------------

function xStream:get_selected_model_index()
  return self.selected_model_index_observable.value
end

-------------------------------------------------------------------------------

function xStream:set_selected_model_index(idx)
  TRACE("xStream:set_selected_model_index(idx)",idx)

  if (#self.models == 0) then
    error("there are no available models")
  end

  if (idx > #self.models) then
    error(("selected_model_index needs to be less than %d"):format(#self.models))
  end

  self:clear_schedule()

  if (idx == self.selected_model_index_observable.value) then
    return
  end
  
  -- remove notifiers
  if self.selected_model then
    self.selected_model:detach_from_song()
  end

  -- update value
  self.selected_model = (idx > 0) and self.models[idx] or nil
  if self.selected_model then
    self.selected_model:attach_to_song()
  end
  --print("set_selected_model_index - selected_model_index =",idx)
  self.selected_model_index_observable.value = idx
  self.buffer:wipe_futures()
  self:reset()

  -- attach notifiers -------------------------------------

  local args_observable_notifier = function()
    TRACE("*** xStream - args.args_observable_notifier fired...")
    self.selected_model.modified = true
  end

  local preset_index_notifier = function()
    TRACE("*** xStream - preset_bank.selected_preset_index_observable fired...")
    local preset_idx = self.selected_model.selected_preset_bank.selected_preset_index
    self.selected_model.selected_preset_bank:recall_preset(preset_idx)
  end

  local preset_observable_notifier = function()
    TRACE("*** xStream - preset_bank.presets_observable fired...")
    if self.selected_model:is_default_bank() then
      self.selected_model.modified = true
    end
  end

  local presets_modified_notifier = function()
    TRACE("*** xStream - selected_preset_bank.modified_observable fired...")
    if self.selected_model.selected_preset_bank.modified then
      self.preset_bank_export_requested = true
    end
  end

  local preset_bank_notifier = function()
    TRACE("*** xStream - selected_preset_bank_index_observable fired..")
    local preset_bank = self.selected_model.selected_preset_bank
    cObservable.attach(preset_bank.presets_observable,preset_observable_notifier)
    cObservable.attach(preset_bank.modified_observable,presets_modified_notifier)
    cObservable.attach(preset_bank.selected_preset_index_observable,preset_index_notifier)
  end

  if self.selected_model then
    cObservable.attach(self.selected_model.args.args_observable,args_observable_notifier)
    cObservable.attach(self.selected_model.selected_preset_bank_index_observable,preset_bank_notifier)
    preset_bank_notifier()
    self.selected_model.args:fire_startup_arguments()
  end

end

-------------------------------------------------------------------------------

function xStream:get_track_index()
  return self.track_index_observable.value
end

function xStream:set_track_index(val)
  self.track_index_observable.value = val
end


-------------------------------------------------------------------------------

function xStream:get_device_param()
  return self._device_param
end

function xStream:set_device_param(val)
  self._device_param = val

  local param_idx
  if val then
    param_idx = xAudioDevice.resolve_parameter(val,self.track_index)
  end
  self.device_param_index_observable.value = param_idx or 0

  --print("xStream:set_device_param - device_param",self._device_param)
  --print("xStream:set_device_param - device_param_index_observable.value",self.device_param_index_observable.value)

end

-------------------------------------------------------------------------------

function xStream:get_clear_undefined()
  return self.clear_undefined_observable.value
end

function xStream:set_clear_undefined(val)
  self.clear_undefined_observable.value = val
end

-------------------------------------------------------------------------------

function xStream:get_include_hidden()
  return self.include_hidden_observable.value
end

function xStream:set_include_hidden(val)
  self.include_hidden_observable.value = val
end

-------------------------------------------------------------------------------

function xStream:get_automation_playmode()
  return self.automation_playmode_observable.value
end

function xStream:set_automation_playmode(val)
  self.automation_playmode_observable.value = val
end

-------------------------------------------------------------------------------

function xStream:get_expand_columns()
  return self.expand_columns_observable.value
end

function xStream:set_expand_columns(val)
  self.expand_columns_observable.value = val
end

-------------------------------------------------------------------------------

function xStream:get_mute_mode()
  return self.mute_mode_observable.value
end

function xStream:set_mute_mode(val)
  self.mute_mode_observable.value = val
end

-------------------------------------------------------------------------------

function xStream:get_muted()
  return self.muted_observable.value
end

function xStream:set_muted(val)
  TRACE("xStream:set_muted(val)",val)
  self.muted_observable.value = val
  if val then
    self.buffer:mute()
  else
    self.buffer:unmute()
  end

end

-------------------------------------------------------------------------------

function xStream:get_scheduling()
  return self.scheduling_observable.value
end

function xStream:set_scheduling(val)
  TRACE("xStream:set_scheduling(val)",val)
  self.scheduling_observable.value = val
end

-------------------------------------------------------------------------------

function xStream:get_scheduled_favorite_index()
  return self.scheduled_favorite_index_observable.value
end

-------------------------------------------------------------------------------

function xStream:get_scheduled_model_index()
  return self.scheduled_model_index_observable.value
end

-------------------------------------------------------------------------------

function xStream:get_scheduled_model()
  return self._scheduled_model
end

-------------------------------------------------------------------------------

function xStream:get_scheduled_preset_index()
  return self.scheduled_preset_index_observable.value
end

-------------------------------------------------------------------------------

function xStream:get_scheduled_preset_bank_index()
  return self.scheduled_preset_bank_index_observable.value
end

-------------------------------------------------------------------------------

function xStream:get_active()
  return self.active_observable.value
end

function xStream:set_active(val)
  self.active_observable.value = val
end

--------------------------------------------------------------------------------
-- Class methods
--------------------------------------------------------------------------------
-- [process] activate the launch model

function xStream:select_launch_model()
  TRACE("xStream:select_launch_model()")

  for k,v in ipairs(self.models) do
    if (v.file_path == self.prefs.launch_model.value) then
      self.selected_model_index = k
    end
  end

end

-------------------------------------------------------------------------------
-- [app] resolve (or create) automation for parameter in the provided seq-index
-- can return nil if trying to create automation on non-automateable parameter
-- note: automation is per-pattern, changes as we move through the sequence
-- @param seq_idx (int)
-- @return renoise.PatternTrackAutomation or nil

function xStream:resolve_automation(seq_idx)
  TRACE("xStream:resolve_automation(seq_idx)",seq_idx)
 
  local patt_idx = rns.sequencer:pattern(seq_idx)
  local patt = rns.patterns[patt_idx]
  assert(patt,"Could not find pattern")
  --local param = self.device.parameters[self.param_index]
  --assert(param,"Could not find device parameter")
  assert(self.device_param,"Could not find device parameter")

  if not self.device_param.is_automatable then
    return
  end

  local ptrack = patt.tracks[self.track_index]
  assert(ptrack,"Could not find pattern-track")

  return xAutomation.get_or_create_automation(ptrack,self.device_param)

end

-------------------------------------------------------------------------------
-- [process] clear various buffers, prepare for new output

function xStream:reset()
  TRACE("xStream:reset()")

  self.buffer:clear()
  self.stream:reset()

  --if self.selected_model then
    --self.selected_model:reset()
  --end

  self:clear_schedule()

end

-------------------------------------------------------------------------------
-- [process] activate live streaming 

function xStream:start()
  TRACE("xStream:start()")

  self:reset()
  self.active = true
  self.stream:start()

end

-------------------------------------------------------------------------------
-- [process] activate live streaming and begin playback
-- (use this method instead of the native Renoise functionality in order 
-- to make the first line play back - otherwise it's too late...)

function xStream:start_and_play()
  TRACE("xStream:start_and_play()")

  if not rns.transport.playing then
    rns.transport.playback_pos = rns.transport.edit_pos
  end

  self:start()
  self.stream:play()

end

-------------------------------------------------------------------------------
-- [process] stop live streaming

function xStream:stop()
  TRACE("xStream:stop()")

  self.active = false
  self:clear_schedule()

end

-------------------------------------------------------------------------------
-- [app] perform periodic updates

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

  if self.active then
    self.stream:track_pos()
  end

  -- TODO optimize this by exporting only while not playing
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
    --print("*** xStream - block_enabled changed...")
    self.block_enabled = rns.transport.loop_block_enabled
    if rns.transport.playing then
      self:compute_scheduling_pos()
    end
  end

end


-------------------------------------------------------------------------------
-- [app] call when a new document becomes available

function xStream:attach_to_song()
  TRACE("xStream:attach_to_song()")

  self:stop()

  local tempo_notifier = function()
    TRACE("*** tempo_notifier fired...")
    self.stream:determine_writeahead()
  end

  local selected_track_index_notifier = function()
    TRACE("*** selected_track_index_notifier fired...")
    self.track_index = rns.selected_track_index
    if self.active then
      self.buffer:update_read_buffer()
    end
  end

  local device_param_notifier = function()
    self.device_param = rns.selected_parameter  
  end

  local playing_notifier = function()
    TRACE("playing_notifier()")

    if not rns.transport.playing then 
      self:stop()
    elseif not self.active then 

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

  rns.transport.bpm_observable:add_notifier(tempo_notifier)
  rns.transport.lpb_observable:add_notifier(tempo_notifier)
  cObservable.attach(rns.transport.playing_observable,playing_notifier)
  cObservable.attach(rns.transport.edit_mode_observable,edit_notifier)
  cObservable.attach(rns.selected_track_index_observable,selected_track_index_notifier)
  cObservable.attach(rns.selected_parameter_observable,device_param_notifier) 

  playing_notifier()
  edit_notifier()
  selected_track_index_notifier()
  device_param_notifier()

  self.stream:attach_to_song()

  if self.selected_model then
    self.selected_model:attach_to_song()
  end

end

-------------------------------------------------------------------------------
-- [process] fill pattern-track in selected pattern
 
function xStream:fill_track()
  TRACE("xStream:fill_track()")
  
  local patt_num_lines = xSongPos.get_pattern_num_lines(rns.selected_sequence_index)
  self.output_mode = xStream.OUTPUT_MODE.TRACK
  self:apply_to_range(1,patt_num_lines)

  self.output_mode = xStream.OUTPUT_MODE.STREAMING

end

-------------------------------------------------------------------------------
-- [app] ensure that selection is valid (not spanning multiple tracks)
-- @return bool
 
function xStream:validate_selection()
  TRACE("xStream:validate_selection()")

  local sel = rns.selection_in_pattern
  if not sel then
    return false,"Please create a (single-track) selection in the pattern"
  end
  if (sel.start_track ~= sel.end_track) then
    return false,"Selection must start and end in the same track"
  end

  return true

end

-------------------------------------------------------------------------------
-- [process] fill pattern-track in selected pattern
-- @param locally (bool) relative to the top of the pattern
 
function xStream:fill_selection(locally)
  TRACE("xStream:fill_selection(locally)",locally)

  local passed,err = self.validate_selection()
  if not passed then
    renoise.app():show_warning(err)
    return
  end

  --local num_lines = xSongPos.get_pattern_num_lines(rns.selected_sequence_index)
  local from_line = rns.selection_in_pattern.start_line
  local to_line = rns.selection_in_pattern.end_line
  local xinc = (not locally) and (from_line-1) or 0 

  -- backup settings
  local cached_track_index = self.track_index

  -- write output
  self.track_index = rns.selection_in_pattern.start_track
  self.output_mode = xStream.OUTPUT_MODE.SELECTION
  self:apply_to_range(from_line,to_line,xinc)

  -- restore settings
  self.track_index = cached_track_index
  self.output_mode = xStream.OUTPUT_MODE.STREAMING

end

-------------------------------------------------------------------------------
-- [process] apply the callback to a range in the selected pattern,  
-- temporarily switching to a different set of buffers
-- @param from_line (int)
-- @param to_line (int) 
-- @param xinc (int) where the callback 'started', use from_line if nil

function xStream:apply_to_range(from_line,to_line,xinc)
  TRACE("xStream:apply_to_range(from_line,to_line,xinc)",from_line,to_line,xinc)

  local xpos = xSongPos({
    sequence = rns.transport.edit_pos.sequence,
    line = from_line
  })
  if xinc then
    xpos.lines_travelled = xinc
  end
  -- ignore any kind of loop (realtime only)
  xpos.out_of_bounds = xSongPos.OUT_OF_BOUNDS.CAP
  xpos.block_boundary = xSongPos.BLOCK_BOUNDARY.NONE
  xpos.loop_boundary = xSongPos.LOOP_BOUNDARY.NONE

  local live_mode = false -- start from first line
  local num_lines = to_line-from_line+1

  self:reset()

  -- backup settings
  local cached_active = self.active
  local cached_buffer = self.buffer.output_buffer
  local cached_read_buffer = self.buffer.pattern_buffer
  local cached_readpos = self.stream.readpos
  local cached_bounds_mode = self.bounds_mode
  local cached_block_mode = self.block_mode
  local cached_loop_mode = self.loop_mode

  -- write output
  self.active = true
  self.stream.readpos.line = from_line
  self.bounds_mode = xpos.out_of_bounds
  self.block_mode = xpos.block_boundary
  self.loop_mode = xpos.loop_boundary
  self.buffer:write_output(xpos,num_lines,live_mode)

  -- restore settings
  self.active = cached_active
  self.buffer.output_buffer = cached_buffer
  self.buffer.pattern_buffer = cached_read_buffer
  self.stream.readpos = cached_readpos
  self.bounds_mode = cached_bounds_mode
  self.block_mode = cached_block_mode
  self.loop_mode = cached_loop_mode

end


-------------------------------------------------------------------------------
--- [app+process]
-- @param xmsg (xMidiMessage)

function xStream:handle_midi_input(xmsg)
  TRACE("xStream:handle_midi_input(xmsg)",xmsg,self)

  if not self.active then
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
  self:handle_event(event_key,xmsg)

end

-------------------------------------------------------------------------------
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
  self:handle_event(event_key,{
    index = index,
    type = evt
  })

end

-------------------------------------------------------------------------------
-- [process]
-- @param arg_name (string), e.g. "tab.my_arg" or "my_arg"
-- @param val (number/boolean/string)

function xStream:handle_arg_events(arg_name,val)
  TRACE("xStream:handle_arg_events(arg_name,val)",arg_name,val)

  -- pass to event handlers (if any)
  local event_key = "args."..arg_name
  self:handle_event(event_key,val)

end

-------------------------------------------------------------------------------
-- [process]
-- @param event_key (string), e.g. "midi.note_on"
-- @param arg (number/boolean/string/table) value to pass 

function xStream:handle_event(event_key,arg)
  TRACE("xStream:handle_event(event_key,arg)",event_key,arg)

  if not self.selected_model then
    LOG("*** WARNING Can't handle events - no model was selected")
    return
  end

  local handler = self.selected_model.events_compiled[event_key]
  if handler then
    --print("about to handle event",event_key,arg,self.selected_model.name)
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

-------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- Static methods
--------------------------------------------------------------------------------
-- @param str_name (string), e.g. "events.midi.note_on" or "main"
-- @return string, type - "main","data" or "events"
-- @return string, depends on context 
-- @return string, -//-
-- @return string, -//-

function xStream.parse_callback_type(str_name)

  if (str_name == "main") then
    return xStreamModel.CB_TYPE.MAIN
  elseif (str_name:sub(0,5) == "data.") then
    local key = str_name:sub(6)
    return xStreamModel.CB_TYPE.DATA,key
  elseif (str_name:sub(0,7) == "events.") then
    local key = str_name:sub(8)    
    local parts = xLib.split(key,"%.") -- split at dot
    return xStreamModel.CB_TYPE.EVENTS,parts[1],parts[2],parts[3]
  end

end


