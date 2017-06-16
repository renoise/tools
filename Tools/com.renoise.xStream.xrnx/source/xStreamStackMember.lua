--[[===============================================================================================
xStreamStackMember
===============================================================================================]]--

--[[

The stack member manages a model, 

The stack member consists of the streaming buffer, and the input/output configuration


]]
--=================================================================================================

class 'xStreamStackMember'

xStreamStackMember.INPUTS = {"None","Automatic","Selected track","Model A","Model B","Model C","Model D"}
xStreamStackMember.INPUT = {
  NONE = 1, 
  AUTOMATIC = 2, 
  SELECTED_TRACK = 3,  
  MODEL_A = 4, 
  MODEL_B = 5,
  MODEL_C = 6,
  MODEL_D = 7,
}

xStreamStackMember.OUTPUTS = {"None","Automatic","Selected track","Pass on"}
xStreamStackMember.OUTPUT = {
  NONE = 1,
  AUTOMATIC = 2, 
  SELECTED_TRACK = 3,
  PASS_ON = 4,
}

xStreamStackMember.SERIALIZABLE = {
  "member_index",
  "model_name",
  "preset_bank_index",
  "preset_index",
  "input",
  "output",
  --"active",
  "scheduling",
}

---------------------------------------------------------------------------------------------------

function xStreamStackMember:__init(xstream,member_index)
  TRACE("xStreamStackMember:__init(xstream,member_index)",xstream,member_index)

  assert(type(xstream)=="xStream")
  assert(type(member_index)=="number")

  self.prefs = renoise.tool().preferences

  --- xStream 
  self.xstream = xstream

  --- number
  self.member_index = member_index

  --- xStreamModel
  self.model = nil

  --- number, index of xStreamModel (0 = none)
  self.model_index = property(self.get_model_index,self.set_model_index)
  self.model_index_observable = renoise.Document.ObservableNumber(0)

  --- string, unique name of xStreamModel
  self.model_name = property(self.get_model_name)

  --- number, index of selected xStreamModel preset-bank (0 = none)
  self.preset_bank_index = property(self.get_preset_bank_index)

  --- number, index of selected xStreamModel preset (0 = none)
  self.preset_index = property(self.get_preset_index)

  --- xStreamStackMember.INPUT
  self.input = property(self.get_input,self.set_input)
  self.input_observable = renoise.Document.ObservableNumber(xStreamStackMember.INPUT.SELECTED_TRACK)
  --- ObservableString, when set there is some problem with the input 
  self.input_status_observable = renoise.Document.ObservableString("")

  --- xStreamStackMember.OUTPUT
  self.output = property(self.get_output,self.set_output)
  self.output_observable = renoise.Document.ObservableNumber(xStreamStackMember.OUTPUT.AUTOMATIC)
  --- ObservableString, when set there is some problem with the input 
  self.output_status_observable = renoise.Document.ObservableString("")

  --- xStreamBuffer, handles streaming ...
  self.buffer = xStreamBuffer(self.xstream.xpos)

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

  --== events ==--

  self.on_schedule_cleared = renoise.Document.ObservableBang()

  --== notifiers ==--

  --self.buffer.on_buffer_wiped:add_notifier(function()
  --  TRACE("xStreamStackMember - buffer.on_buffer_wiped fired...")
  --  self:write_buffer_output()
  --end)

  -- handle changes to selected model 
  self.model_index_observable:add_notifier(function()
    TRACE("xStreamStackMember - model_index_observable fired...")
    self:_clear_schedule()
    if (self.model_index == 0) then
      self.buffer.active = false
    end
    self:_attach_to_model()
  end)

  -- synchronize with preferences
  self.buffer.automation_playmode = self.prefs.automation_playmode.value
  self.prefs.automation_playmode:add_notifier(function()
    TRACE("xStreamStackMember - self.automation_playmode_observable fired...")
    self.buffer.automation_playmode = self.prefs.automation_playmode.value
  end)
  self.buffer.include_hidden = self.prefs.include_hidden.value
  self.prefs.include_hidden:add_notifier(function()
    TRACE("xStreamStackMember - self.include_hidden_observable fired...")
    self.buffer.include_hidden = self.prefs.include_hidden.value
  end)
  self.buffer.clear_undefined = self.prefs.clear_undefined.value
  self.prefs.clear_undefined:add_notifier(function()
    TRACE("xStreamStackMember - self.clear_undefined_observable fired...")
    self.buffer.clear_undefined = self.prefs.clear_undefined.value
  end)
  self.buffer.expand_columns = self.prefs.expand_columns.value
  self.prefs.expand_columns:add_notifier(function()
    TRACE("xStreamStackMember - self.expand_columns_observable fired...")
    self.buffer.expand_columns = self.prefs.expand_columns.value
  end)
  self.buffer.mute_mode = self.prefs.mute_mode.value
  self.prefs.mute_mode:add_notifier(function()
    TRACE("xStreamStackMember - self.mute_mode_observable fired...")
    self.buffer.mute_mode = self.prefs.mute_mode.value
  end)  


end

---------------------------------------------------------------------------------------------------
-- Get/set
---------------------------------------------------------------------------------------------------

function xStreamStackMember:get_model_index()
  return self.model_index_observable.value
end

function xStreamStackMember:set_model_index(val)
  TRACE("xStreamStackMember:set_model_index(val)",val)
  if val ~= self.model_index_observable.value then 
    self:_instantiate_model(val)
  end
  self.model_index_observable.value = val

end

---------------------------------------------------------------------------------------------------

function xStreamStackMember:get_model_name()
  if self.model then 
    return self.model.name
  end
end

---------------------------------------------------------------------------------------------------

function xStreamStackMember:get_preset_bank_index()
  if self.model then 
    return self.model.selected_preset_bank_index
  end
end

---------------------------------------------------------------------------------------------------

function xStreamStackMember:get_preset_index()
  if self.model then 
    return self.model.selected_preset_index
  end
end

---------------------------------------------------------------------------------------------------

function xStreamStackMember:get_input()
  return self.input_observable.value
end

function xStreamStackMember:set_input(val)
  TRACE("xStreamStackMember:set_input(val)",val)
  self.input_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamStackMember:get_output()
  return self.output_observable.value
end

function xStreamStackMember:set_output(val)
  TRACE("xStreamStackMember:set_output(val)",val)
  self.output_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamStackMember:get_scheduled_model_index()
  return self.scheduled_model_index_observable.value
end

---------------------------------------------------------------------------------------------------

function xStreamStackMember:get_scheduled_model()
  return self._scheduled_model
end

---------------------------------------------------------------------------------------------------

function xStreamStackMember:get_scheduled_preset_index()
  return self.scheduled_preset_index_observable.value
end

---------------------------------------------------------------------------------------------------

function xStreamStackMember:get_scheduled_preset_bank_index()
  return self.scheduled_preset_bank_index_observable.value
end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------
-- Invoked when cancelling schedule, or scheduled event has happened

function xStreamStackMember:_clear_schedule()
  TRACE("xStreamStackMember:_clear_schedule()")
  self._scheduled_model = nil
  self._scheduled_xinc = nil
  self.scheduled_model_index_observable.value = 0
  self.scheduled_preset_index_observable.value = 0
  self.scheduled_preset_bank_index_observable.value = 0
  self.on_schedule_cleared:bang()
end

---------------------------------------------------------------------------------------------------
-- Switch to scheduled model/preset

function xStreamStackMember:apply_schedule()
  TRACE("xStreamStackMember:apply_schedule()")
  -- remember value (otherwise lost when setting model)
  local preset_index = self.scheduled_preset_index
  local preset_bank_index = self.scheduled_preset_bank_index
  if not self.scheduled_model then
    self:_clear_schedule()
    return
  end
  self.model_index = self.scheduled_model_index
  if preset_bank_index then
    self.model.selected_preset_bank_index = preset_bank_index
  end
  self.model.selected_preset_bank.selected_preset_index = preset_index
  self:_clear_schedule()
end

---------------------------------------------------------------------------------------------------
-- Create a new model instance (as a result of a changed model index)

function xStreamStackMember:_instantiate_model(model_idx)
  TRACE("xStreamStackMember:_instantiate_model(model_idx)",model_idx)

  -- remove notifiers from existing model
  if self.model then
    self.model:detach_from_song()
  end

  local model_name = self.xstream.models.available_models[model_idx]
  if not model_name then
    local err = "Failed to instantiate model"
    LOG(err)
    self.model = nil
    return 
  end

  self.model = xStreamModel(self.buffer,self.xstream.voicemgr,self.xstream.output_message)

  local file_path = xStreamModel.get_normalized_file_path(model_name)
  local passed,err = self.model:load_definition(file_path)
  if not passed and err then
    renoise.app():show_warning(err)
    return
  end

  self.xstream.models:add(self.model,self.member_index)

end

---------------------------------------------------------------------------------------------------

function xStreamStackMember:_attach_to_model()
  TRACE("xStreamStackMember:_attach_to_model()")

  if not self.model then 
    LOG("*** xStreamStackMember - Can't attach: no model present")
    return 
  end 

  local name_notifier = function()
    TRACE("xStreamStackMember:_attach_to_model - name_notifier fired...")
    self.xstream.stack_export_requested = true
  end 

  local rebuffer_notifier = function()
    print("xStreamStackMember:_attach_to_model - rebuffer_notifier fired...")
    self.xstream.stack:rebuffer_linked_members(self.member_index)
  end 

  local compiled_notifier = function()
    TRACE("xStreamStackMember:_attach_to_model - compiled_notifier fired...")
    self.buffer.callback = self.model.sandbox.callback
    self.buffer.output_tokens = self.model.output_tokens
    self:write_buffer_output()
  end 

  local preset_index_notifier = function()
    TRACE("xStreamModels - preset_bank.selected_preset_index_observable fired...")
    local preset_idx = self.model.selected_preset_bank.selected_preset_index
    self.model.selected_preset_bank:recall_preset(preset_idx)
    self.xstream.stack_export_requested = true
  end

  local presets_modified_notifier = function()
    TRACE("xStreamModels - selected_preset_bank.modified_observable fired...")
    if self.model.selected_preset_bank.modified then
      self.xstream.preset_bank_export_requested = true
    end
  end

  local preset_bank_notifier = function()
    TRACE("xStreamModels - selected_preset_bank_index_observable fired..")
    local preset_bank = self.model.selected_preset_bank
    cObservable.attach(preset_bank.modified_observable,presets_modified_notifier)
    cObservable.attach(preset_bank.selected_preset_index_observable,preset_index_notifier)
  end

  cObservable.attach(self.model.name_observable,name_notifier)
  cObservable.attach(self.model.on_rebuffer,rebuffer_notifier)
  cObservable.attach(self.model.compiled_observable,compiled_notifier)
  cObservable.attach(self.model.selected_preset_bank_index_observable,preset_bank_notifier)
  preset_bank_notifier()
  
  compiled_notifier()

end

---------------------------------------------------------------------------------------------------
-- Called on abrupt position changes - refresh pattern buffer, output 

function xStreamStackMember:refresh()
  TRACE("xStreamStackMember:refresh()")
  if self.buffer.active then
    self.buffer:refresh_input_buffer()
    --self.buffer:wipe_futures() 
    self:write_buffer_output() 
  end
end

---------------------------------------------------------------------------------------------------
-- Intended to be called by apply_stack_to_range(), which caches additional properties
-- before invoking this method... 
-- @param from_line (int)
-- @param to_line (int) 
-- @param pos (SongPos)
-- @param [xinc] (int) where the callback 'started'

function xStreamStackMember:apply_to_range(from_line,to_line,pos,xinc)
  TRACE("xStreamStackMember:apply_to_range(from_line,to_line,pos,xinc)",from_line,to_line,pos,xinc)

  if not self.buffer.active then 
    LOG("*** apply_to_range - skip output, member is not active")
    return
  end

  TRACE(">>> xStreamStackMember:apply_to_range - from_line/to_line",from_line,to_line)
  TRACE(">>> xStreamStackMember:apply_to_range - pos,xinc",pos,xinc)
  TRACE(">>> xStreamStackMember:apply_to_range - member_index",self.member_index)

  local live_mode = false
  local num_lines = to_line-from_line+1

  -- backup settings
  local cached_buffer = self.buffer.output_buffer
  local cached_read_buffer = self.buffer.input_buffer

  -- write output
  self.xstream.xpos.pos.line = from_line
  self.buffer:write_output(pos,xinc,num_lines,live_mode)

  -- restore settings
  self.buffer.output_buffer = cached_buffer
  self.buffer.input_buffer = cached_read_buffer


end


---------------------------------------------------------------------------------------------------
-- Produce output - can be called periodically

function xStreamStackMember:write_buffer_output()
  TRACE("xStreamStackMember:write_buffer_output()",self.model_name)
  if self.buffer.active then
    local xpos = self.xstream.xpos
    if self._scheduled_xinc then
      if (xpos.xinc == self._scheduled_xinc) then
        self:apply_schedule()
      end
    end
    local live_mode = true
    self.buffer:write_output(xpos.pos,xpos.xinc,nil,live_mode)
  end
end

---------------------------------------------------------------------------------------------------

function xStreamStackMember:toggle_mute()
  TRACE("xStreamStackMember:toggle_mute()")
  if self.muted and not self.buffer.mute_xinc then
    self.buffer:mute()
  elseif not self.muted and self.buffer.mute_xinc then
    self.buffer:unmute()
  end
end

---------------------------------------------------------------------------------------------------
-- Obtain serializable definition 
-- @return table 

function xStreamStackMember:get_definition()
  TRACE("xStreamStackMember:get_definition()")

  -- class props
  local def = {}
  for k,v in ipairs(xStreamStackMember.SERIALIZABLE) do
    def[v] = self[v]
  end

  -- model args
  --[[
  local args = {}
  for k,v in ipairs(self.model.args.args) do 
    table.insert(args,v:get_definition())
  end
  def.args = args
  ]]

  return def

end

---------------------------------------------------------------------------------------------------
-- Recall state from definition
-- @param def (table)

function xStreamStackMember:apply_definition(def)
  TRACE("xStreamStackMember:apply_definition(def)",def)

  local ignored = {
    "model_name",
    "preset_index",
    "preset_bank_index",
  }

  for k,v in pairs(def) do
    if not table.find(ignored,k) 
      and table.find(xStreamStackMember.SERIALIZABLE,k) 
    then
      self[k] = v
    end
  end

  -- special treatment 
  -- 1. "model_name" is used for obtaining model index
  -- 2. setting model index will instantiate the model 
  -- 3. once the model has loaded, we can set the preset 

  local model_idx = self.xstream.models:get_model_index_by_name(def.model_name)
  --print(">>> model_idx",model_idx)
  if model_idx then 
    self.model_index = model_idx
    self.model.selected_preset_bank_index = def.preset_index
    self.model.selected_preset_index = def.preset_index
  else 
    LOG("*** Warning: failed to recall model with this name:",def.model_name)
  end 
end

---------------------------------------------------------------------------------------------------

function xStreamStackMember:__tostring()
  return type(self)
end

---------------------------------------------------------------------------------------------------
-- Static methods
---------------------------------------------------------------------------------------------------
-- @param idx (number) between 1-MAX_MEMBERS
-- @return xStreamStackMember.INPUT (A/B/C/D)

function xStreamStackMember.get_input_constant_by_idx(idx)
  assert(type(idx)=="number")
  -- number of constants before MODEL_X
  local offset = 3
  if (idx >= xStreamStackMember.INPUT.MODEL_A-offset)
   or (idx <= xStreamStackMember.INPUT.MODEL_D-offset)
  then
    return idx+offset
  end
end

