--[[============================================================================
xStream
============================================================================]]--
--[[

  The main xStream class - where it all comes together

  TODO refactor the blockloop tracking into the xStreamPos class
  and implement a "refresh_fn" handler for recalculating the read buffer
  (see idle method for a partial implementation of this)

]]

--==============================================================================

class 'xStream'

xStream.FAVORITES_FILE_PATH = "./favorites.xml"
xStream.MODELS_FOLDER       = "./models/"
xStream.PRESET_BANK_FOLDER  = "./presets/"

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
xStream.SCHEDULES = {"None","Beat","Bar","Block","Pattern"}
xStream.SCHEDULE = {
  NONE = 1,
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

-------------------------------------------------------------------------------
-- constructor

function xStream:__init()

  -- xStreamUI, built-in user interface
  self.ui = nil

  -- xStreamPos, set up our streaming handler
  self.stream = xStreamPos()
  self.stream.callback_fn = function()
    if self.active then
      self:do_output(self.stream.writepos,nil,true)
    end
  end
  self.stream.refresh_fn = function()
    if self.active then
      self:update_read_buffer()
    end
  end

  -- int, writeahead amount
  self.writeahead = 0

  -- table<xLine>, output buffer
  self.buffer = {}

  -- Content is read from the pattern as new content is requested from the 
  -- callback method - this ensures that the callback always has a
  -- fully populated line to work on. But unlike the output buffer, the
  -- read buffer is not cleared when arguments change - it should be read
  -- only *once*. 
  -- table<xLine descriptor>, input buffer
  self.read_buffer = {}

  -- int, keep track of the highest/lowest line in our buffers
  self.highest_buffer_idx = 0
  self.lowest_buffer_idx = 0

  --self.highest_read_buffer_idx = 0

  -- xSongPos.OUT_OF_BOUNDS, handle song boundaries
  self.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP

  -- xSongPos.BLOCK_BOUNDARY, handle block boundaries
  self.block_mode = xSongPos.BLOCK_BOUNDARY.SOFT

  -- xSongPos.LOOP_BOUNDARY, handle pattern/seq.loop boundaries
  self.loop_mode = xSongPos.LOOP_BOUNDARY.SOFT

  -- enum, one of xStream.OUTPUT_MODE
  -- usually STREAMING, but temporarily set to a different
  -- value while applying output to TRACK/SELECTION
  self.output_mode = xStream.OUTPUT_MODE.STREAMING

  -- (bool) keep track of loop block state
  self.block_enabled = rns.transport.loop_block_enabled

  -- string, last file path from where we imported models ('load_models')
  self.last_models_path = nil

  -- bool, true if we want xStream to manage garbage collection
  self.manage_gc = false

  -- bool, flag raised when preset bank is eligible for export
  self.preset_bank_export_requested = false

  -- bool, flag raised when favorites are eligible for export
  self.favorite_export_requested = false

  -- bool, when true we automatically save favorites/presets
  self.autosave_enabled = false
  
  -- xStream.PLAYMODE (string-based enum)
  self.automation_playmode = property(self.get_automation_playmode,self.set_automation_playmode)
  self.automation_playmode_observable = renoise.Document.ObservableNumber(xStream.PLAYMODE.LINEAR)

  -- int, decrease this if you are experiencing dropouts during heavy UI
  -- operations in Renoise (such as opening a plugin GUI) 
  self.writeahead_factor = property(self.get_writeahead_factor,self.set_writeahead_factor)
  self.writeahead_factor_observable = renoise.Document.ObservableNumber(300)

  -- string, value depends on success/failure during last callback 
  -- "" = no problem
  -- "Some error occurred" = description of error 
  self.callback_status_observable = renoise.Document.ObservableString("")

  -- bool, when true we compile the callback on-the-fly
  self.live_coding = property(self.get_live_coding,self.set_live_coding)
  self.live_coding_observable = renoise.Document.ObservableBoolean(false)

  -- int, decide which track to target (0 = none)
  self.track_index = property(self.get_track_index,self.set_track_index)
  self.track_index_observable = renoise.Document.ObservableNumber(0)

  -- renoise.DeviceParameter, selected automation parameter (can be nil)
  self.device_param = property(self.get_device_param,self.set_device_param)
  self._device_param = nil

  -- int, derived from device_param (0 = none)
  self.device_param_index_observable = renoise.Document.ObservableNumber(0)

  -- boolean, whether to include hidden (not visible) columns
  self.include_hidden = property(self.get_include_hidden,self.set_include_hidden)
  self.include_hidden_observable = renoise.Document.ObservableBoolean(false)

  -- boolean, determine how to respond to 'undefined' content
  self.clear_undefined = property(self.get_clear_undefined,self.set_clear_undefined)
  self.clear_undefined_observable = renoise.Document.ObservableBoolean(true)

  -- boolean, whether to expand (sub-)columns when writing data
  self.expand_columns = property(self.get_expand_columns,self.set_expand_columns)
  self.expand_columns_observable = renoise.Document.ObservableBoolean(true)

  -- xStream.MUTE_MODE, controls how muting is done
  self.mute_mode = property(self.get_mute_mode,self.set_mute_mode)
  self.mute_mode_observable = renoise.Document.ObservableNumber(xStream.MUTE_MODE.OFF)

  -- bool, set to true to silence output
  self.muted = property(self.get_muted,self.set_muted)
  self.muted_observable = renoise.Document.ObservableBoolean(false)

  -- xStream.SCHEDULE, active scheduling mode
  self.scheduling = property(self.get_scheduling,self.set_scheduling)
  self.scheduling_observable = renoise.Document.ObservableNumber(xStream.SCHEDULE.BEAT)

  -- int, read-only - set via schedule_item(), 0 means none 
  self.scheduled_favorite_index = property(self.get_scheduled_favorite_index)
  self.scheduled_favorite_index_observable  = renoise.Document.ObservableNumber(0)

  -- int, read-only - set via schedule_item(), 0 means none
  self.scheduled_model_index = property(self.get_scheduled_model_index)
  self.scheduled_model_index_observable = renoise.Document.ObservableNumber(0)

  -- int, read-only - set via schedule_item()
  self.scheduled_model = property(self.get_scheduled_model)
  self._scheduled_model = nil

  -- xSongPos, tells us when/if a scheduled event will occur
  -- updated as external conditions change: for example, if we had 
  -- scheduled something to happen at the 'next pattern' and in 
  -- the meantime, pattern loop was enabled 
  self._scheduled_pos = nil

  -- int, read-only - set via schedule_item()
  self.scheduled_preset_index = property(self.get_scheduled_preset_index)
  self.scheduled_preset_index_observable = renoise.Document.ObservableNumber(0)

  -- int, read-only - set via schedule_item()
  self.scheduled_preset_bank_index = property(self.get_scheduled_preset_bank_index)
  self.scheduled_preset_bank_index_observable = renoise.Document.ObservableNumber(0)

  self.suspend_when_hidden = property(self.get_suspend_when_hidden,self.set_suspend_when_hidden)
  self.suspend_when_hidden_observable = renoise.Document.ObservableBoolean(true)

    -- int, the line at which output got muted
  self.mute_pos = nil

  -- int, 'undefined' line to insert after output got muted 
  self.empty_xline = xLine({
    note_columns = {},
    effect_columns = {},
  })

  -- bool, true when we should output during live streaming 
  self.active = property(self.get_active,self.set_active)
  self.active_observable = renoise.Document.ObservableBoolean(false)

  -- table<xStreamModel>, registered models 
  self.models = {}

  -- xStreamFavorites, favorited model+preset combinations
  self.favorites = xStreamFavorites(self)

  -- table<int>, receive notification when models are added/removed
  -- the table itself contains just the model indices
  self.models_observable = renoise.Document.ObservableNumberList()

  -- int, the model index, 1-#models or 0 when none are available
  self.selected_model_index = property(self.get_selected_model_index,self.set_selected_model_index)
  self.selected_model_index_observable = renoise.Document.ObservableNumber(0)

  -- xStreamModel, read-only - nil when none are available
  self.selected_model = nil

  -- initialize -----------------------

  self:determine_writeahead()

  -- always run during idle
  renoise.tool().app_idle_observable:add_notifier(function()
    self:on_idle()
  end)

  -- automatic saving of favorites
  local favorites_notifier = function()    
    TRACE("*** xStream - favorites.favorites/grid_columns/grid_rows/modified_observable fired..")
    self.favorite_export_requested = true
  end
  self.favorites.favorites_observable:add_notifier(favorites_notifier)
  self.favorites.grid_columns_observable:add_notifier(favorites_notifier)
  self.favorites.grid_rows_observable:add_notifier(favorites_notifier)
  self.favorites.modified_observable:add_notifier(favorites_notifier)

  renoise.tool().app_new_document_observable:add_notifier(function()
    TRACE("*** xStream - app_new_document_observable fired...")
    self:attach_to_song()
  end)
  self:attach_to_song()

end

-------------------------------------------------------------------------------
-- class methods
-------------------------------------------------------------------------------
-- create new model from scratch
-- @param str_name (string)
-- @return bool, true when model got created
-- @return string, error message on failure

function xStream:create_model(str_name)
  TRACE("xStream:create_model(str_name)",str_name)

  assert(type(str_name) == "string")

  local model = xStreamModel(self)
  model.name = str_name
  --[[
  xStreamModel.get_suggested_name(model.name)       
  local str_name,err = vDialog.prompt_for_string(str_name,
    "Enter a name for the model","Create Model")
  if not str_name then
    return
  end
  ]]

  local str_name_validate = xStreamModel.get_suggested_name(str_name)
  --print(">>> str_name,str_name_validate",str_name,str_name_validate)
  if (str_name ~= str_name_validate) then
    return false,"Error: a model already exists with this name."
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

function xStream:add_model(model)
  TRACE("xStream:add_model(model)")

  model.xstream = self
  table.insert(self.models,model)
  self.models_observable:insert(#self.models)

end

-------------------------------------------------------------------------------
-- remove all models

function xStream:remove_models()
  TRACE("xStream:remove_models()")

  for k,_ in ripairs(self.models) do
    self:remove_model(k)
  end 

end

-------------------------------------------------------------------------------
-- remove specific model from list
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
-- delete from disk, the remove from list
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
-- load all models (files ending with .lua) in a given folder
-- log potential errors during parsing

function xStream:load_models(str_path)
  TRACE("xStream:load_models(str_path)",str_path)

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
     LOG(log_msg.."WARNING One or more models failed to load during startup")
  end

  -- save the path for later use
  -- (when creating 'virtual' models, this is where they will be saved)
  self.last_models_path = str_path

end

-------------------------------------------------------------------------------
-- return table<string>

function xStream:get_model_names()
  TRACE("xStream:get_model_names()")

  local t = {}
  for _,v in ipairs(self.models) do
    table.insert(t,v.modified and v.name.."*" or v.name)
  end
  return t

end

-------------------------------------------------------------------------------
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

  if (self.scheduling == xStream.SCHEDULE.NONE) then
    if self._scheduled_model then
      self:apply_schedule() -- set immediately 
    end
    --print("*** xStream.SCHEDULE.NONE - applied preset,model...")
  else
    self:compute_scheduling_pos()
  end

  -- if scheduled event is going to take place within the
  -- space of already-computed lines, wipe the buffer
  if self._scheduled_pos then
    local happening_in_lines = self._scheduled_pos.lines_travelled
      - (self.stream.writepos.lines_travelled)
    --print("happening_in_lines",happening_in_lines)
    if (happening_in_lines <= self.writeahead) then
      --print("wipe the buffer")
      self:wipe_futures()
    end
  end

end

-------------------------------------------------------------------------------
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

  if (self.scheduling == xStream.SCHEDULE.NONE) then
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
  self:wipe_futures()
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
    xObservable.attach(preset_bank.presets_observable,preset_observable_notifier)
    xObservable.attach(preset_bank.modified_observable,presets_modified_notifier)
    xObservable.attach(preset_bank.selected_preset_index_observable,preset_index_notifier)
  end
  if self.selected_model then
    xObservable.attach(self.selected_model.args.args_observable,args_observable_notifier)
    xObservable.attach(self.selected_model.selected_preset_bank_index_observable,preset_bank_notifier)
    preset_bank_notifier()
  end

end

-------------------------------------------------------------------------------

function xStream:get_live_coding()
  return self.live_coding_observable.value
end

function xStream:set_live_coding(val)
  self.live_coding_observable.value = val
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

function xStream:get_writeahead_factor()
  return self.writeahead_factor_observable.value
end

function xStream:set_writeahead_factor(val)
  TRACE("xStream:set_writeahead_factor(val)",val)

  self.writeahead_factor_observable.value = val

  self:determine_writeahead()

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

  local changed = (val ~= self.muted_observable.value)
  self.muted_observable.value = val

  if not changed then
    return
  end

  if not val then
    return
  end

  -- we have muted the track 
  -- stop output and (optionally) write OFF across columns

  self:wipe_futures()

  local line = self.stream.writepos.lines_travelled
  if rns.transport.playing then
    line = line+2
  end
  self.mute_pos = line

  local function produce_note_off()
    local note_cols = {}
    local note_col_count = self:get_visible_note_cols()
    for _ = 1,note_col_count do
      table.insert(note_cols,{
        note_value = xNoteColumn.NOTE_OFF_VALUE,
        instrument_value = xLinePattern.EMPTY_VALUE,
        volume_value = xLinePattern.EMPTY_VALUE,
        panning_value = xLinePattern.EMPTY_VALUE,
        delay_value = 0,
      })
    end
    return note_cols
  end

  local xline = {}

  if (self.mute_mode == xStream.MUTE_MODE.OFF) then
    xline.note_columns = produce_note_off()
  end

  local mute_xline = xLine(xline)
  self.buffer[self.mute_pos] = mute_xline
  self.buffer[self.mute_pos+1] = mute_xline
  self.highest_buffer_idx = math.max(self.mute_pos+1,self.highest_buffer_idx)

  self:do_output(self.stream.writepos)

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

function xStream:get_suspend_when_hidden()
  return self.suspend_when_hidden_observable.value
end

function xStream:set_suspend_when_hidden(val)
  self.suspend_when_hidden_observable.value = val
end

-------------------------------------------------------------------------------

function xStream:get_active()
  return self.active_observable.value
end

function xStream:set_active(val)
  self.active_observable.value = val
end

-------------------------------------------------------------------------------
-- will produce output for the next number of lines
-- @param xpos (xSongPos), needs to be a valid position in the song
-- @param num_lines (int), use writeahead if not defined
-- @param live_mode (bool), skip playpos when true

function xStream:do_output(xpos,num_lines,live_mode)
  TRACE("xStream:do_output(xpos)",xpos,num_lines,live_mode)

  if not self.selected_model then
    return
  end

  -- apply scheduled model/preset
  if self._scheduled_pos then
    if (xSongPos(self.stream.playpos) == self._scheduled_pos) then
      --print("apply scheduled model/preset",self.stream.playpos,self._scheduled_pos,self._scheduled_pos.lines_travelled)
      self:apply_schedule()
    end
  end

  if not num_lines then
    num_lines = rns.transport.playing and self.writeahead or 1
  end

  -- purge old content from buffers
  self:wipe_past()

  -- generate new content as needed
  if not self.muted then
    local has_content,missing_from = 
      self:has_content(xpos.lines_travelled,num_lines-1)
    if not has_content then
      self:get_content(
        missing_from,num_lines-(missing_from-xpos.lines_travelled),xpos)
    end
  end

  local tmp_pos -- temp line-by-line position

  -- TODO decide this elsewhere (optimize)
  local patt_num_lines = xSongPos.get_pattern_num_lines(xpos.sequence)

  --local param = nil
  local phrase = nil
  local ptrack_auto = nil
  local last_auto_seq_idx = nil

  for i = 0,num_lines-1 do
    tmp_pos = xSongPos({sequence=xpos.sequence,line=xpos.line+i})
    tmp_pos.bounds_mode = self.bounds_mode
    if (tmp_pos.line > patt_num_lines) then
      -- exceeded pattern
      if (self.loop_mode ~= xSongPos.LOOP_BOUNDARY.NONE) then
        -- normalize the songpos and redial 
        --print("*** exceeded pattern PRE",tmp_pos,num_lines-i)
        tmp_pos.lines_travelled = xpos.lines_travelled + i - 1
        tmp_pos:normalize()
        --print("*** exceeded pattern POST",tmp_pos,num_lines-i)
        self:do_output(tmp_pos,num_lines-i)
      end
      return
    else
      local cached_line = tmp_pos.line
      if rns.transport.loop_block_enabled and 
        (self.block_mode ~= xSongPos.BLOCK_BOUNDARY.NONE) 
      then
        tmp_pos.line = tmp_pos:enforce_block_boundary("increase",xpos.line,i)
        if (cached_line ~= tmp_pos.line) then
          -- exceeded block loop, redial with new position
          tmp_pos.lines_travelled = xpos.lines_travelled + i
          --print("*** exceeded block loop",tmp_pos,num_lines-i)
          self:do_output(tmp_pos,num_lines-i)
          return
        end
      end

      if live_mode and (tmp_pos.line+1 == rns.transport.playback_pos.line) then
        --print("*** skip output",xpos.lines_travelled+i,tmp_pos)
      else
        --print("*** write output",xpos.lines_travelled+i,tmp_pos)
        
        local travelled = xpos.lines_travelled+i
        local xline = nil

        if self.muted and (travelled > self.mute_pos+1) then
          --print("*** mute output - travelled",travelled)
          xline = self.empty_xline
        else
          -- normal output
          --print("*** normal output - travelled,tmp_pos",travelled,tmp_pos)
          xline = self.buffer[travelled]

          -- check if we can/need to resolve automation
          if type(xline)=="xLine" then
            if self.device_param and xline.automation then
              if (tmp_pos.sequence ~= last_auto_seq_idx) then
                last_auto_seq_idx = tmp_pos.sequence
                --print("*** last_auto_seq_idx",last_auto_seq_idx)
                ptrack_auto = self:resolve_automation(tmp_pos.sequence)
              end
            end
            --print("*** ptrack_auto",ptrack_auto)
            if ptrack_auto then
              --print("param.value_quantum",param.value_quantum)
              if (self.device_param.value_quantum == 0) then
                ptrack_auto.playmode = self.automation_playmode
              end
            end
          end

        end

        --print("*** do_write - travelled,line,xline",travelled,tmp_pos.line,xline.effect_columns[1].amount_value)
        if type(xline)=="xLine" then
          local success,err = pcall(function()
            xline:do_write(
              tmp_pos.sequence,
              tmp_pos.line,
              self.track_index,
              phrase,
              ptrack_auto,
              patt_num_lines,
              self.selected_model.output_tokens,
              self.include_hidden,
              self.expand_columns,
              self.clear_undefined)
          end)
          if not success then
            LOG("WARNING: an error occurred while writing pattern-line - "..err)
          end
        else
          LOG("WARNING Missing xline on output",tmp_pos,xpos.lines_travelled)
        end
      end

    end    
  end

end

-------------------------------------------------------------------------------
-- check if buffer has content for the specified range
-- @param pos (int), index in buffer 
-- @param num_lines (int)
-- @return bool, true when all content is present
-- @return int, (when not present) the first missing index 

function xStream:has_content(pos,num_lines)
  TRACE("xStream:has_content(pos,num_lines)",pos,num_lines)

  for i = pos,pos+num_lines do
    if not (self.buffer[i]) then
      --print("*** has_content - missing from",i)
      return false,i
    end
  end

  return true

end

-------------------------------------------------------------------------------
-- retrieve content from our callback method + pattern
-- @param pos (int), internal line count
-- @param num_lines (int) 
-- @param xpos (xSongPos) read from this position (when not previously read)
-- @return table<xLine>

function xStream:get_content(pos,num_lines,xpos)
  TRACE("xStream:get_content(pos,num_lines)",pos,num_lines)

  if not self.selected_model.callback then
    error("No callback method has been specified")
  end

  local read_pos = nil
  if self.stream.readpos then
    read_pos = self.stream.readpos
    --print("*** read_pos - self.readpos",self.stream.readpos)
    --print("*** read_pos - self.stream.writepos",self.stream.writepos)
  else
    read_pos = xSongPos(xpos)
    print("*** read_pos - xSongPos(xpos)",xpos)
  end

  -- special case: if the pattern was deleted from the song, the read_pos
  -- might be referring to a non-existing pattern - in such a case,
  -- we re-initialize to the current position
  -- TODO "proper" align of readpos via patt-seq notifications in xStreamPos 
  if not rns.sequencer.pattern_sequence[read_pos.sequence] then
    LOG("Missing pattern sequence - was removed from song?")
    read_pos = xSongPos(rns.transport.playback_pos)
  end

  for i = 0, num_lines-1 do

    local buffer_idx = pos+i
    local xline

    -- retrieve existing content --------------------------

    local has_read_buffer = self.read_buffer[buffer_idx]
    if has_read_buffer then 
      --print("*** xStream:get_content - retrieve from read buffer",buffer_idx)
      xline = self.read_buffer[buffer_idx]
      --rprint(xline)
      print("*** xStream:get_content - retrieved from read buffer",buffer_idx,"=",xline.effect_columns[1].amount_value)
    else
      xline = xLine.do_read(
        read_pos.sequence,read_pos.line,self.include_hidden,self.track_index)
      self.read_buffer[buffer_idx] = table.rcopy(xline) -- TODO rcopy needed ?
      print("*** xStream:get_content - fresh fetch - read_pos",read_pos,"buffer_idx",buffer_idx,"fx-col amount_value",xline.effect_columns[1].amount_value)
    end
    --self.highest_read_buffer_idx = math.max(buffer_idx,self.highest_read_buffer_idx)
    --print("IN  ",buffer_idx,read_pos,xline.note_columns[1].note_string)

    -- handle scheduling ----------------------------------

    local callback = nil
    local change_to_scheduled = false
    if self._scheduled_pos and self._scheduled_model then
      local compare_to = 1 + read_pos.lines_travelled - num_lines + i
      if (self._scheduled_pos.lines_travelled <= compare_to) then
        change_to_scheduled = true
        --print("*** xStream:get_content, scheduled - read_pos,scheduled_pos,compare_to",read_pos,self._scheduled_pos.lines_travelled,compare_to)
      end
    end
    if change_to_scheduled then
      callback = self._scheduled_model.callback
      -- TODO apply preset arguments 
    else
      callback = self.selected_model.callback
    end

    -- process the callback -------------------------------
    local buffer_content = nil
    local success,err = pcall(function()
      buffer_content = callback(buffer_idx,xLine(xline),xSongPos(read_pos))
    end)
    if not success and err then
      LOG("ERROR: please review the callback function - "..err)
      -- TODO display runtime errors separately (runtime_status)
      self.callback_status_observable.value = err
      --self.buffer[buffer_idx] = xLine({})
    elseif success then
      -- we might have redefined the xline (or parts of it) in our  
      -- callback method - convert everything into class instances...
      -- TODO check against 'user_redefined_xline'
      local success,err = pcall(function()
        self.buffer[buffer_idx] = xLine.apply_descriptor(buffer_content)
      end)
      if not success and err then
        LOG("ERROR: an error occurred while converting xline - "..err)
        self.buffer[buffer_idx] = self.empty_xline
      end

    end
    self.highest_buffer_idx = math.max(buffer_idx,self.highest_buffer_idx)

    if not has_read_buffer then
      read_pos:increase_by_lines(1)
    end

  end

  self.stream.readpos = read_pos
  print("*** POST-get-content readpos",self.stream.readpos)

end

-------------------------------------------------------------------------------
-- get visible note columns in the associated track
-- @return int

function xStream:get_visible_note_cols()
  TRACE("xStream:get_visible_note_cols()")

  local track = rns.tracks[self.track_index]
  assert(track,"Trying to access a non-existing track")

  return track.visible_note_columns

end

-------------------------------------------------------------------------------
-- get visible note columns in the associated track
-- @return int

function xStream:get_visible_effect_cols()
  TRACE("xStream:get_visible_effect_cols()")

  local track = rns.tracks[self.track_index]
  assert(track,"Trying to access a non-existing track")

  return track.visible_effect_columns

end

-------------------------------------------------------------------------------
-- resolve (or create) automation for parameter in the provided seq-index
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

  local automation = ptrack:find_automation(self.device_param)
  
  -- create if not present 
  if not automation then
    automation = ptrack:create_automation(self.device_param)
  end

  return automation

end

-------------------------------------------------------------------------------
-- clear various buffers, prepare for new output

function xStream:reset()
  TRACE("xStream:reset()")

  if self.manage_gc then
    collectgarbage("stop")
  else
    --collectgarbage("restart")
    --collectgarbage()
  end

  self.buffer = {}
  self.highest_buffer_idx = 0
  self.lowest_buffer_idx = 0

  self.read_buffer = {}
  self.stream.readpos = nil

  -- revert data to initial state
  if self.selected_model then
    self.selected_model.env.data = 
      table.rcopy(self.selected_model.data_initial)
  end

  self:clear_schedule()

end

-------------------------------------------------------------------------------
-- activate live streaming 

function xStream:start()
  TRACE("xStream:start()")

  self:reset()
  self.active = true
  self.stream:start()

end

-------------------------------------------------------------------------------
-- activate live streaming and begin playback
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
-- stop live streaming

function xStream:stop()
  TRACE("xStream:stop()")

  self.active = false
  self:clear_schedule()

  if self.manage_gc then
    collectgarbage("restart")
    collectgarbage()
  end

end

-------------------------------------------------------------------------------
-- mute output, but continue progression in the background
-- @param mute_mode (xStream.MUTE_MODE)

function xStream:mute(mute_mode)
  TRACE("xStream:mute(mute_mode)",mute_mode)

  if mute_mode then
    self.mute_mode = mute_mode
  end

  -- the rest is handled by set_muted()
  self.muted = true

end

-------------------------------------------------------------------------------
-- unmute output, when already muted

function xStream:unmute()

  -- the rest is handled by set_muted()
  self.muted = false

end

-------------------------------------------------------------------------------
-- update all content ahead of our position
-- method is called when xStreamPos is changing position 'abruptly'

function xStream:update_read_buffer()
  print("xStream:update_read_buffer()")

  if self.stream.readpos then
    
    print(">>> xStream:update_read_buffer - self.stream.readpos",self.stream.readpos)
    print(">>> xStream:update_read_buffer - self.stream.playpos",self.stream.playpos)
    for k = 0,self.writeahead-1 do
      local buffer_idx = self.stream.readpos.lines_travelled
      self.read_buffer[buffer_idx] = xLine.do_read(
        self.stream.readpos.sequence,self.stream.readpos.line,self.include_hidden,self.track_index)
      print(">>> xStream:update_read_buffer -- ",buffer_idx,"line in pattern",self.stream.readpos,self.read_buffer[buffer_idx].effect_columns[1].amount_value)
      self.stream.readpos:increase_by_lines(1)
    end

    --self.stream.readpos.lines_travelled = self.stream.readpos.lines_travelled - self.writeahead
    self:wipe_futures()
  end

end

-------------------------------------------------------------------------------
-- forget all output ahead of our current write-position
-- method is automatically called when callback arguments have changed,
-- and will cause fresh line(s) to be created in the next cycle
-- (see also xStreamArgs)

function xStream:wipe_futures()
  TRACE("xStream:wipe_futures()")

  -- do not wipe while muted
  if self.muted then
    return
  end

  local from_idx = self.stream.writepos.lines_travelled
  if rns.transport.playing then
    -- when live streaming, exclude current line
    from_idx = from_idx+1
  end

  for i = from_idx,self.highest_buffer_idx do
    self.buffer[i] = nil
    --print("*** wiped buffer at",i)
  end

  self.highest_buffer_idx = self.stream.writepos.lines_travelled
  --print("*** self.highest_buffer_idx",self.highest_buffer_idx)

end

-------------------------------------------------------------------------------
-- wipe all data behind our current write-position
-- (see also xStreamArgs)

function xStream:wipe_past()
  TRACE("xStream:wipe_past()")

  local from_idx = self.stream.writepos.lines_travelled - 1
  for i = from_idx,self.lowest_buffer_idx,-1 do
    self.buffer[i] = nil
    self.read_buffer[i] = nil
    --print("*** wipe_past - cleared buffers at ",i)
  end

  self.lowest_buffer_idx = from_idx
  --print("lowest_buffer_idx ",from_idx)

end

--------------------------------------------------------------------------------
-- decide the writeahead amount, depending on the song tempo

function xStream:determine_writeahead()
  TRACE("xStream:determine_writeahead()")

  local bpm = rns.transport.bpm
  local lpb = rns.transport.lpb

  --self.writeahead = math.ceil(math.max(2,(bpm*lpb)/self.writeahead_factor))
  self.writeahead = 5
  self.stream.writeahead = self.writeahead

end

-------------------------------------------------------------------------------
-- perform periodic updates

function xStream:on_idle()
  --TRACE("xStream:on_idle()")

  -- user interface 
  if self.ui then
    self.ui:on_idle()
  end

  -- track changes to callback, poll arguments
  if self.selected_model then
    self.selected_model:on_idle()
  end

  if rns.transport.playing then
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
    print("*** xStream - block_enabled changed...")
    self.block_enabled = rns.transport.loop_block_enabled
    if rns.transport.playing then
      self:compute_scheduling_pos()
    end
  end


end

-------------------------------------------------------------------------------
-- call when a new document becomes available

function xStream:attach_to_song()
  TRACE("xStream:attach_to_song()")

  self:stop()

  local tempo_notifier = function()
    TRACE("*** tempo_notifier fired...")
    self:determine_writeahead()
  end

  rns.transport.bpm_observable:add_notifier(tempo_notifier)
  rns.transport.lpb_observable:add_notifier(tempo_notifier)

  self.stream:attach_to_song()

  if self.selected_model then
    self.selected_model:attach_to_song()
  end

end

-------------------------------------------------------------------------------
-- fill pattern-track in selected pattern
 
function xStream:fill_track()
  TRACE("xStream:fill_track()")
  
  local patt_num_lines = xSongPos.get_pattern_num_lines(rns.selected_sequence_index)
  self.output_mode = xStream.OUTPUT_MODE.TRACK
  self:apply_to_range(1,patt_num_lines)

  self.output_mode = xStream.OUTPUT_MODE.STREAMING

end

-------------------------------------------------------------------------------
-- ensure that selection is valid (not spanning multiple tracks)
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
-- fill pattern-track in selected pattern
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
  local travelled = (not locally) and (from_line-1) or 0 

  -- backup settings
  local cached_track_index = self.track_index

  -- write output
  self.track_index = rns.selection_in_pattern.start_track
  self.output_mode = xStream.OUTPUT_MODE.SELECTION
  self:apply_to_range(from_line,to_line,travelled)

  -- restore settings
  self.track_index = cached_track_index
  self.output_mode = xStream.OUTPUT_MODE.STREAMING

end

-------------------------------------------------------------------------------
-- apply the callback to a range in the selected pattern,  
-- temporarily switching to a different set of buffers
-- @param from_line (int)
-- @param to_line (int) 
-- @param travelled (int) where the callback 'started', use from_line if nil

function xStream:apply_to_range(from_line,to_line,travelled)
  TRACE("xStream:apply_to_range(from_line,to_line,travelled)",from_line,to_line,travelled)

  local xpos = xSongPos({
    sequence = rns.transport.edit_pos.sequence,
    line = from_line
  })
  if travelled then
    xpos.lines_travelled = travelled
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
  local cached_buffer = self.buffer
  local cached_read_buffer = self.read_buffer
  local cached_readpos = self.stream.readpos
  local cached_bounds_mode = self.bounds_mode
  local cached_block_mode = self.block_mode
  local cached_loop_mode = self.loop_mode

  -- write output
  self.active = true
  self.bounds_mode = xpos.out_of_bounds
  self.block_mode = xpos.block_boundary
  self.loop_mode = xpos.loop_boundary
  self:do_output(xpos,num_lines,live_mode)

  -- restore settings
  self.active = cached_active
  self.buffer = cached_buffer
  self.read_buffer = cached_read_buffer
  self.stream.readpos = cached_readpos
  self.bounds_mode = cached_bounds_mode
  self.block_mode = cached_block_mode
  self.loop_mode = cached_loop_mode

end

-------------------------------------------------------------------------------
-- take the current buffer and create an instrument phrase from it
-- instrument numbers are treated as sample indices - this might not be what
-- you expect, if you enable sample columns in the resulting phrase
--[[
function xStream:export_to_phrase(instr_idx)
  TRACE("xStream:export_to_phrase(instr_idx)",instr_idx)

  if table.is_empty(self.buffer) then
    renoise.app():show_message("There is no recording to export")
    return
  end

  local xphrase_mgr = xPhraseMgr()
  xphrase_mgr.default_range = 6
  xphrase_mgr.instr_idx = instr_idx

  local note_range,phrase_idx = xphrase_mgr:get_available_slot()
  --print("note_range,phrase_idx",rprint(note_range),phrase_idx)
  if not note_range then
    LOG("Failed to allocate a phrase (no more room left?)")
  end

  local num_lines = math.min(512,self.highest_buffer_idx)
  TRACE("num_lines",num_lines)

  local instr = rns.instruments[xphrase_mgr.instr_idx]
  local phrase = instr:insert_phrase_at(phrase_idx)
  assert(phrase,"Failed to create phrase")
  phrase.mapping.note_range = {
    note_range[1],
    note_range[2]
  }
  phrase.mapping.base_note = note_range[1]
  phrase:clear() -- remove the default C-4 note

  for i = 0,num_lines-1 do
    if (self.buffer[i]) then
      self.buffer[i]:do_write(
        {line = i+1},
        nil, -- track_index
        phrase,
        nil, -- ptrack_auto
        nil,  -- patt_num_lines
        self.selected_model.output_tokens,
        self.include_hidden,
        self.expand_columns,
        self.clear_undefined)
    end
  end

  phrase.number_of_lines = num_lines
  rns.selected_phrase_index = phrase_idx

end


-------------------------------------------------------------------------------
-- save to file, using an internal representation of the recording
-- will prompt you for a location & file name

function xStream:export_to_file()
  TRACE("xStream:export_to_file()")

  if table.is_empty(self.buffer) then
    renoise.app():show_message("There is no recording to export")
    return
  end

  local file_path = renoise.app():prompt_for_filename_to_write("xml", "Export stream as...")
  --print("file_path",file_path)

  -- TODO export session to file


end
]]

