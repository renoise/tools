--[[===============================================================================================
xStreamStack
===============================================================================================]]--
--[[

A stack of streaming models.

#

The stack takes care of having multiple models working in tandem. 

]]

--=================================================================================================

class 'xStreamStack'

-- accessible to callback
xStreamStack.OUTPUT_MODE = {
  STREAMING = 1,
  TRACK = 2,
  SELECTION = 3,
}

xStreamStack.SERIALIZABLE = {
  "name",
  "file_path",
  "output_mode",
  "selected_member_index",
  "scheduling",
}

xStreamStack.MAX_MEMBERS = 4

---------------------------------------------------------------------------------------------------
-- constructor

function xStreamStack:__init(xstream)
  TRACE("xStreamStack:__init(xstream)",xstream)

  assert(type(xstream)=="xStream")

  self.xstream = xstream

  --- xStreamPrefs, current settings
  self.prefs = renoise.tool().preferences

  --- number, the member/model which is currently displayed (1-MAX_MEMBERS or 0 when none)
  self.selected_member_index = property(self.get_selected_member_index,self.set_selected_member_index) 
  self.selected_member_index_observable = renoise.Document.ObservableNumber(0)

  --- boolean, evaluate callback while playing
  self.active = property(self.get_active,self.set_active)
  self.active_observable = renoise.Document.ObservableBoolean(false)

  --- boolean, silence output (see also xStreamBuffer.MUTE_MODE)
  self.muted = property(self.get_muted,self.set_muted)
  self.muted_observable = renoise.Document.ObservableBoolean(false)

  --- table, xStreamStackMember
  self._members = {}

  --- ObservableBang, fired when members have changed somehow
  -- (things that affect the stack definition, such as members, or the selected index)
  self.changed_observable = renoise.Document.ObservableBang()

  --- string, display in the stack selector
  self.name = property(self.get_name,self.set_name)
  self.name_observable = renoise.Document.ObservableString(xStreamStacks.DEFAULT_NAME)

  --- string, read-only (changes along with the the name, set once file is saved)
  self.file_path = property(self.get_file_path)
  self.file_path_observable = renoise.Document.ObservableString("")

  --- boolean, when true, asterisk is shown in stack selector (+ able to save)
  self.modified = property(self.get_modified,self.set_modified)
  self.modified_observable = renoise.Document.ObservableBoolean()

  --- int, the selected model index, 1-#available_models or 0 when none is selected 
  -- here for convenience - refers to the model of the selected member
  self.selected_model_index = property(self.get_selected_model_index,self.set_selected_model_index)
  self.selected_model_index_observable = renoise.Document.ObservableNumber(0)

  --- xStreamModel, read-only - can be nil
  self.selected_model = property(self.get_selected_model)
  
  --- enum, one of xStreamStack.OUTPUT_MODE
  -- usually STREAMING, but temporarily set to a different
  -- value while applying output to TRACK/SELECTION
  self.output_mode = xStreamStack.OUTPUT_MODE.STREAMING

  --- int, the selected track 
  self.selected_track_index = property(self.get_selected_track_index,self.set_selected_track_index)
  self.selected_track_index_observable = renoise.Document.ObservableNumber(1)

  --- xStreamPos.SCHEDULE, active scheduling mode
  self.scheduling = property(self.get_scheduling,self.set_scheduling)
  self.scheduling_observable = renoise.Document.ObservableNumber(xStreamPos.SCHEDULE.BEAT)

  --- int, read-only - set via schedule_item(), 0 means none 
  self.scheduled_favorite_index = property(self.get_scheduled_favorite_index)
  self.scheduled_favorite_index_observable  = renoise.Document.ObservableNumber(0)

  --== notifiers ==--

  self.prefs.scheduling:add_notifier(function()
    self.scheduling_observable.value = self.prefs.scheduling.value
  end)
  self.prefs.writeahead_factor:add_notifier(function()
    xStreamPos.WRITEAHEAD_FACTOR = self.prefs.writeahead_factor.value
  end)

  -- changing member will also change selected model 
  self.selected_member_index_observable:add_notifier(function()
    --print(">>> process.stack.selected_member_index_observable fired...",self,self.selected_member_index)
    local member = self:get_member_at(self.selected_member_index)
    self.selected_model_index_observable.value = member and member.model_index or 0
  end)

  -- any change to the stack 
  self.changed_observable:add_notifier(function()
    --print(">>> changed_observable fired...",self)
    self.modified_observable.value = true
  end)


end

---------------------------------------------------------------------------------------------------
-- Get/set
---------------------------------------------------------------------------------------------------

function xStreamStack:get_selected_member()
  return self:get_member_at(self.selected_member_index)
end

---------------------------------------------------------------------------------------------------

function xStreamStack:get_selected_member_index()
  return self.selected_member_index_observable.value
end

function xStreamStack:set_selected_member_index(val)
  TRACE("xStreamStack:set_selected_member_index",val)
  self.selected_member_index_observable.value = val 
  self.changed_observable:bang()
end

---------------------------------------------------------------------------------------------------

function xStreamStack:get_active()
  return self.active_observable.value
end

function xStreamStack:set_active(val)
  TRACE("xStreamStack:set_active(val)",val)
  self.active_observable.value = val
  self:maintain_active_state()
  self:maintain_mute_state()
end

---------------------------------------------------------------------------------------------------

function xStreamStack:get_muted()
  return self.muted_observable.value
end

function xStreamStack:set_muted(val)
  TRACE("xStreamStack:set_muted(val)",val)
  self.muted_observable.value = val
  self:maintain_mute_state()

end

---------------------------------------------------------------------------------------------------

function xStreamStack:get_modified()
  return self.modified_observable.value
end

function xStreamStack:set_modified(val)
  TRACE("xStreamStack:set_modified(val)",val)
  self.modified_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamStack:get_name()
  return self.name_observable.value
end

function xStreamStack:set_name(val)
  TRACE("xStreamStack:set_name(val)",val)
  self.name_observable.value = val 
end

---------------------------------------------------------------------------------------------------

function xStreamStack:get_file_path()
  return self.file_path_observable.value
end

---------------------------------------------------------------------------------------------------

function xStreamStack:get_selected_track_index()
  return self.selected_track_index_observable.value
end

function xStreamStack:set_selected_track_index(val)
  TRACE("xStreamStack:set_selected_track_index(val)",val)
  self.selected_track_index_observable.value = val
  
  self:resolve_input_output()
  
end

---------------------------------------------------------------------------------------------------

function xStreamStack:get_scheduling()
  return self.scheduling_observable.value
end

function xStreamStack:set_scheduling(val)
  TRACE("xStreamStack:set_scheduling(val)",val)
  self.scheduling_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamStack:get_scheduled_favorite_index()
  return self.scheduled_favorite_index_observable.value
end

---------------------------------------------------------------------------------------------------
-- Return the currently selected/displayed model among the members 

function xStreamStack:get_selected_model()
  local member = self:get_selected_member()
  if member then 
    return member.model
  end
end

---------------------------------------------------------------------------------------------------

function xStreamStack:get_selected_model_index()
  return self.selected_model_index_observable.value
end

-- Makes the selected member use a specific model
-- @param idx (number), refers to the list of available models
function xStreamStack:set_selected_model_index(idx)
  TRACE("xStreamStack:set_selected_model_index(idx)",idx)

  -- already the active model 
  if (idx == self.selected_model_index_observable.value) then
    return
  end
  
  local member = self:get_selected_member()
  if not member then 
    -- create new member 
    member = xStreamStackMember(self.xstream,self.selected_member_index)
    self:set_member(self.selected_member_index,member)
    --table.insert(self._members,member)
    --print(">>> created member",member)
  end 

  -- this will instantiate the model and set the index
  --print(">>> set_selected_model_index",idx)
  member.model_index = idx 

end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------

function xStreamStack:attach_to_xstream()

  -- detect when the available models change, and update model indices
  self.xstream.models.available_models_changed_observable:add_notifier(function()
    TRACE("xStreamStack - available_models_changed_observable fired...")
    for member in self:members_iter() do
      if member.model then
        local new_model_index = self.xstream.models:get_model_index_by_name(member.model.name)
        if not new_model_index then 
          --print(">>> model was removed, shut it down...")
          self:unset_member(member.member_index)
        elseif (new_model_index ~= member.model_index) then
          --print(">>> stealthily update model index...")
          -- Change the index without instantiating the model anew
          member.model_index_observable.value = new_model_index
        end
      end    
    end    

  end)

end

---------------------------------------------------------------------------------------------------
-- members iterator that skip empty entries

function xStreamStack:members_iter()
  TRACE("xStreamStack:members_iter()")
  local t = self._members
  local i = 0
  local n = table.getn(t)
  return function ()
    i = i + 1
    while 
      type(t[i])=="table" 
      and table.is_empty(t[i]) 
      and (i <= xStreamStack.MAX_MEMBERS)
    do
      --print(">>> skipped empty member at",i)
      i = i + 1
    end
    
    --print(">>> iterator at index",i)
    if i <= n then 
      return t[i] 
    end
  end
end

---------------------------------------------------------------------------------------------------

function xStreamStack:clear_schedule()
  TRACE("xStreamStack:clear_schedule()")
  for member in self:members_iter() do
    member:_clear_schedule()
  end
end 

---------------------------------------------------------------------------------------------------
-- Regular streaming output 
-- TODO implement stacked buffers - passing between models 

function xStreamStack:output()
  TRACE("xStreamStack:output()")

  if self.active then 
    for member in self:members_iter() do
      member:write_buffer_output()
    end
  end 
  
end

---------------------------------------------------------------------------------------------------
-- When an abrupt change occurred in the stream-position 

function xStreamStack:refresh()
  TRACE("xStreamStack:refresh()")

  for member in self:members_iter() do
    member:refresh()
  end

end

---------------------------------------------------------------------------------------------------
-- Maintain active state for all models

function xStreamStack:maintain_active_state()
  TRACE("xStreamStack:maintain_active_state()")

  for member in self:members_iter() do
    member.buffer.active = self.active
  end

end

---------------------------------------------------------------------------------------------------
-- Maintain mute state for all models

function xStreamStack:maintain_mute_state()
  TRACE("xStreamStack:maintain_mute_state()")

  for member in self:members_iter() do
    if self.muted and not member.buffer.mute_xinc then
      member.buffer:mute()
    elseif not self.muted and member.buffer.mute_xinc then
      member.buffer:unmute()
    end
  end


end

---------------------------------------------------------------------------------------------------

function xStreamStack:apply_to_range(from_line,to_line,pos,xinc)
  TRACE("xStreamStack:apply_to_range(from_line,to_line,pos,xinc)",from_line,to_line,pos,xinc)

  for member in self:members_iter() do
    member:apply_to_range(from_line,to_line,pos,xinc)
  end

end

---------------------------------------------------------------------------------------------------
-- Handle incoming MIDI/voice-manager/argument events - 
-- @param event_key (string), e.g. "midi.note_on"
-- @param arg (number/boolean/string/table) value to pass 

function xStreamStack:handle_event(event_key,arg)
  print("xStreamStack:handle_event(event_key,arg)",event_key,arg)

  for member in self:members_iter() do
    member.model:handle_event(event_key,arg)
  end

end

---------------------------------------------------------------------------------------------------
-- Make members that are linked to the specified one produce new output 

function xStreamStack:rebuffer_linked_members(member_idx)
  print("xStreamStack:rebuffer_linked_members(member_idx)",member_idx)

  local look_for = xStreamStackMember.INPUT.MODEL_A-member_idx+1
  for member in self:members_iter() do
    print("member.input",member.input,look_for)
    if (member.input == look_for) 
      and (member.index > member_idx)
    then 
      print(">>> found member that was linked to provided one",member.member_index,member.model_name)
      member.model.buffer:immediate_output()
    end
  end

end

---------------------------------------------------------------------------------------------------
-- Final step - after loading, before starting 

function xStreamStack:initialize()
  TRACE("xStreamStack:initialize()")

  self:attach_to_xstream()

  for k = 1,xStreamStack.MAX_MEMBERS do
    self:unset_member(k)
  end

end

----------------------------------------------------------------------------------------------------
-- Determine whether any members are defining a model 
-- @return boolean

function xStreamStack:contains_model()
  TRACE("xStreamStack:contains_model()")

  for member in self:members_iter() do
    if member.model then 
      return true
    end
  end
  return false

end

----------------------------------------------------------------------------------------------------
-- Retrieve member at provided index 
-- @return xStreamStackMember or nil

function xStreamStack:get_member_at(idx)
  --TRACE("xStreamStack:get_member_at(idx)",idx)
  local member = self._members[idx]
  return type(member)=="xStreamStackMember" and member or nil
end

----------------------------------------------------------------------------------------------------
-- Remove a member, detaching notifiers in the process

function xStreamStack:unset_member(idx)
  TRACE("xStreamStack:unset_member(idx)",idx)

  assert(type(idx)=="number")

  local member = self:get_member_at(idx)
  if member then
    if member.model then
      self.xstream.models:remove(member.model.name,member.member_index)
    end
  end

  self._members[idx] = {} 
  self.changed_observable:bang()

  --print(">>> unset_member...",rprint(self._members))
  --print(">>> idx,self.selected_member_index",idx,self.selected_member_index)
  --print(">>> self.selected_model_index_observable.value",self.selected_model_index_observable.value)

  if (idx == self.selected_member_index) then 
    self.xstream.stack.selected_model_index_observable.value = 0
  end 


end

----------------------------------------------------------------------------------------------------
-- Assign a member to the stack, attach notifiers

function xStreamStack:set_member(idx,member)
  TRACE("xStreamStack:set_member(idx,member)",idx,member)

  assert(type(idx)=="number")
  assert(type(member)=="xStreamStackMember")

  -- always unset before setting 
  self:unset_member(idx)

  self._members[idx] = member 

  local model_index_notifier = function()
    --print(">>> xStreamStack model_index_notifier fired...",self)
    if (idx == self.selected_member_index) then 
      self.xstream.stack.selected_model_index_observable.value = member.model_index
    end 
    self.changed_observable:bang()
  end
  local input_notifier = function()
    --print(">>> xStreamStack input_notifier fired...",self)
    self:resolve_input_output()
    self.changed_observable:bang()
  end
  local output_notifier = function()
    --print(">>> xStreamStack output_notifier fired...",self)
    self:resolve_input_output()
    self.changed_observable:bang()
  end
  --local active_observable = function()
    --print(">>> xStreamStack active_observable fired...",self)
    --self.changed_observable:bang()
    -- don't export this one 
  --end

  cObservable.attach(member.model_index_observable,model_index_notifier)
  cObservable.attach(member.input_observable,input_notifier)
  cObservable.attach(member.output_observable,output_notifier)
  --cObservable.attach(member.buffer.active_observable,active_observable)

  if (idx == self.selected_member_index) then 
    -- select the model 
    self.xstream.stack.selected_model_index_observable.value = member.model_index
  end 

  self.changed_observable:bang()

  member.buffer.active = self.active

end

----------------------------------------------------------------------------------------------------
-- Return selected member, create if not present
-- @return xStreamStackMember

function xStreamStack:allocate_member()
  TRACE("xStreamStack:allocate_member()")

  local member = self:get_selected_member()
  if not member then 
    local member_idx = math.min(1,self.selected_member_index)
    member = xStreamStackMember(self.xstream,member_idx)
    self:set_member(member_idx,member)  
  end 
  return member

end

----------------------------------------------------------------------------------------------------
-- Reset is invoked when starting or switching model 

function xStreamStack:reset()
  TRACE("xStreamStack:reset()")

  for member in self:members_iter() do
    member.buffer:clear()
  end
  
end

----------------------------------------------------------------------------------------------------

function xStreamStack:mute()
  TRACE("xStreamStack:mute()")

  for member in self:members_iter() do
    member.buffer:mute()
  end

end

----------------------------------------------------------------------------------------------------

function xStreamStack:unmute()
  TRACE("xStreamStack:unmute()")

  for member in self:members_iter() do
    member.buffer:unmute()
  end

end

---------------------------------------------------------------------------------------------------
-- Stop live streaming

function xStreamStack:stop()
  TRACE("xStreamStack:stop()")
  self.active = false
  self:clear_schedule()
end

---------------------------------------------------------------------------------------------------
-- Activate live streaming 
-- @param playmode, renoise.Transport.PLAYMODE

function xStreamStack:start(playmode)
  TRACE("xStreamStack:start(playmode)",playmode)

  if self.active then 
    return 
  end
  self:clear_schedule()
  self:reset()
  self.active = true

end

---------------------------------------------------------------------------------------------------
-- @return xStreamModelPresets, or false when unable to resolve

function xStreamStack:get_selected_preset_bank()

  local model = self.selected_model
  if not model then 
    return false, "No model is selected"
  end 

  local preset_bank = self.selected_model.selected_preset_bank
  if not preset_bank then 
    return false, "No preset bank is selected"
  end 

  return preset_bank

end

---------------------------------------------------------------------------------------------------
-- Attempt to select a preset from the current preset bank 
-- @return boolean, true when able to set 

function xStreamStack:set_selected_preset_index(idx)
  TRACE("xStreamStack:set_selected_preset_index(idx)",idx)
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

function xStreamStack:select_previous_preset()
  TRACE("xStreamStack:select_previous_preset()")
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

function xStreamStack:select_next_preset()
  TRACE("xStreamStack:select_next_preset()")
  local preset_bank,err = self:get_selected_preset_bank()
  if err then 
    return false, err
  end 
  preset_bank:select_next()
  return true 
end

----------------------------------------------------------------------------------------------------
-- Update member inputs/outputs (e.g. as a result of changing the selected track)

function xStreamStack:resolve_input_output()
  TRACE("xStreamStack:resolve_input_output()")

  local member,err
  for k = 1,xStreamStack.MAX_MEMBERS do
    member = self:get_member_at(k)
    --print(">>> member",member)
    if member then 
      err = self:resolve_input(k)
      member.input_status_observable.value = err or ""
      err = self:resolve_output(k)
      member.output_status_observable.value = err or ""
    end
  end

end


----------------------------------------------------------------------------------------------------
-- Update input for a stack member 
-- @param member_idx (number)
-- @return string, error message when failed 

function xStreamStack:resolve_input(member_idx)
  TRACE("xStreamStack:resolve_input(member_idx)",member_idx)

  local member = self:get_member_at(member_idx)
  if not member then 
    return ("failed to resolve member with index %d"):format(member_idx);
  end 

  -- always reset callback
  member.buffer.input_callback = nil

  -- connect to previous member 
  local connect_member = function(idx)
    --print(">>> resolve_input - connect_member - idx",idx)
    --print(">>> resolve_input - member_idx",member_idx)
    --print(">>> resolve_input - member.input",member.input)

    if (idx >= member.member_index) then
      member.buffer.read_track_index = 0
      LOG("*** same or previous")
      return ("error resolving input for member %d - needs to be same or previous"):format(member.member_index)
    end 

    local target_member = self:get_member_at(idx)
    if not target_member then 
      -- bad routing: set to no track and provide empty lines 
      member.buffer.read_track_index = 0
      member.buffer.input_callback = function(xinc)
        return xLine(xLine.EMPTY_XLINE)
      end      
    else 
      -- set track to member track-index and return its buffer
      member.buffer.read_track_index = target_member.buffer.read_track_index
      member.buffer.input_callback = function(xinc)
        --print(">>> buffer.input_callback - xinc",xinc)
        --print(">>> buffer.input_callback - target_member.member_index",target_member.member_index)
        local xline = target_member.buffer:get_output(xinc)
        --print(">>> buffer.input_callback - xline",xline)
        return xLine(xline) 
      end
    end
  end

  local inputs = {
    [xStreamStackMember.INPUT.NONE] = function()
      member.buffer.read_track_index = 0
    end,
    [xStreamStackMember.INPUT.AUTOMATIC] = function()
      -- TODO consider the following example: 
      -- MODEL_A set to input:  SELECTED_TRACK  
      --                output: AUTOMATIC       
      -- MODEL_B set to input:  SELECTED_TRACK  <== member is skipped 
      --                output: SELECTED_TRACK
      -- MODEL_C set to input: AUTOMATIC        <== receives MODEL_A
      --                output: AUTOMATIC       
      -- MODEL_D set to input:  AUTOMATIC       <== receives MODEL_C
      --                output:                   
      --member.input_observable.value = 
    end,
    [xStreamStackMember.INPUT.SELECTED_TRACK] = function()
      member.buffer.read_track_index = rns.selected_track_index
    end,
    [xStreamStackMember.INPUT.MODEL_A] = function()
      return connect_member(1)
    end,
    [xStreamStackMember.INPUT.MODEL_B] = function()
      return connect_member(2)
    end,
    [xStreamStackMember.INPUT.MODEL_C] = function()
      return connect_member(3)
    end,
    [xStreamStackMember.INPUT.MODEL_D] = function()
      return connect_member(4)
    end,
  }

  if inputs[member.input] then 
    return inputs[member.input]()
  else
    -- specific track 
    local highest_enum_idx = cTable.last(cTable.values(xStreamStackMember.INPUT))    
    member.buffer.read_track_index = member.input - xStreamStackMember.INPUT.MODEL_D
    --print(">>> member.buffer.read_track_index",member.buffer.read_track_index)
  end 

end

--------------------------------------------------------------------------------------------------
-- Update output for a stack member 
-- PASS_ON, when a later member is set to AUTOMATIC or specifically to this one,
-- or SELECTED_TRACK as fallback when not able to resolve member
-- @param member_idx (number)
-- @return string, error message when failed 

function xStreamStack:resolve_output(member_idx)
  TRACE("xStreamStack:resolve_output(member_idx)",member_idx)

  local member = self:get_member_at(member_idx)
  if not member then 
    LOG("*** xStreamStack:resolve_output - Failed to resolve member")
  end 


  --[[
    -- pass on
  local do_pass_on = false
  local model_x = xStreamStackMember.get_input_constant_by_idx(member_idx)
  --print(">>> model_x",model_x)
  for k = member_idx+1,xStreamStack.MAX_MEMBERS do 
    local member = self:get_member_at(k)
    if member then
      if (member.input == xStreamStackMember.INPUT.AUTOMATIC
        or member.input == model_x)
      then
        member.buffer.write_track_index = 
        --return xStreamStackMember.OUTPUT.PASS_ON
      end
    end 
  end
  ]]

  local outputs = {
    [xStreamStackMember.OUTPUT.NONE] = function()
      member.buffer.write_track_index = 0
    end,
    [xStreamStackMember.OUTPUT.AUTOMATIC] = function()
      -- TODO 
    end,
    [xStreamStackMember.OUTPUT.SELECTED_TRACK] = function()
      member.buffer.write_track_index = rns.selected_track_index
    end,
    [xStreamStackMember.OUTPUT.PASS_ON] = function()
      
    end
  }
  
  if outputs[member.output] then 
    outputs[member.output]()
  else
    -- specific track 
    local highest_enum_idx = cTable.last(cTable.values(xStreamStackMember.OUTPUT))
    member.buffer.write_track_index = member.output - highest_enum_idx
    --print(">>> member.buffer.write_track_index",member.buffer.write_track_index)
  end 
  
end

---------------------------------------------------------------------------------------------------
-- Schedule model or model+preset
-- @param model_name (string), unique name of model
-- @param [preset_index] (int),  preset to dial in - optional
-- @param [preset_bank_name] (string), preset bank - optional, TODO
-- @param [member_idx] (number), pointing to xStreamStackMember (use selected if undefined)
-- @return true when item got scheduled
-- @return err (string), the reason scheduling failed

function xStreamStack:schedule_item(model_name,preset_index,preset_bank_name,member_idx)
  TRACE("xStreamStack:schedule_item(model_name,preset_index,preset_bank_name,member_idx)",model_name,preset_index,preset_bank_name,member_idx)

  if not self.active then
    return false,"Can't schedule items while inactive"
  end

  assert(model_name,"Required argument missing: model_name")
  assert((type(model_name)=="string"),"Invalid argument type: model_name - expected string")

  local model_index,model = self.xstream.models:get_by_name(model_name)
  if not model then
    return false,"Could not schedule, model not found: "..model_name
  end

  if not member_idx then
    member_idx = self.selected_member_index
  end

  local member = self:get_member_at(member_idx)
  if not member then 
    error("Missing member")
  end 

  member._scheduled_model = model
  member.scheduled_model_index_observable.value = model_index
  
  -- validate preset
  
  if (type(preset_index)=="number") then
    local num_presets = #model.selected_preset_bank.presets
    if (preset_index <= num_presets) then
      member.scheduled_preset_index_observable.value = preset_index
    end
  end

  if preset_bank_name then
    local preset_bank_index = model:get_preset_bank_by_name(preset_bank_name)
    --print("preset_bank_name,preset_bank_index",preset_bank_name,preset_bank_index)
    member.scheduled_preset_bank_index_observable.value = preset_bank_index
    --print("xStreamStack:schedule_item - self.scheduled_preset_bank_index",preset_bank_index)
  end

  local favorite_idx = self.xstream.favorites:get(model_name,preset_index,preset_bank_name)
  --print("favorite_idx",favorite_idx)
  if favorite_idx then
    member.scheduled_favorite_index_observable.value = favorite_idx
  end

  -- now figure out the time
  if (member.scheduling == xStreamPos.SCHEDULE.LINE) then
    if member._scheduled_model then
      member:apply_schedule() -- set immediately 
    end
  else
    self:compute_scheduling_pos()
  end

  -- if scheduled event is going to take place within the
  -- space of already-computed lines, wipe the buffer
  if self._scheduled_xinc then
    local happening_in_lines = self._scheduled_xinc-self.xstream.xpos.xinc
    if (happening_in_lines <= xStreamPos.determine_writeahead()) then
      --print("wipe the buffer")
      member.buffer:wipe_futures()
    end
  end

end

---------------------------------------------------------------------------------------------------
-- Schedule, or re-schedule (when external conditions change)

function xStreamStack:compute_scheduling_pos()
  TRACE("xStreamStack:compute_scheduling_pos()")

  local pos = xSongPos.create(self.xstream.xpos.playpos)
  self._scheduled_xinc = self.xstream.xpos.xinc

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
-- Create a serialized version of the stack
-- return table, definition table

function xStreamStack:get_definition()
  TRACE("xStreamStack:get_definition()")

  local def = {}
  for k,v in ipairs(xStreamStack.SERIALIZABLE) do
    def[v] = self[v]
  end
  def.stack = {}
  for member in self:members_iter() do
    table.insert(def.stack,member:get_definition())
  end

  def.selected_member_index = self.selected_member_index

  return def

end

---------------------------------------------------------------------------------------------------
-- Recall state from definition
-- @param def (table)

function xStreamStack:apply_definition(def)
  TRACE("xStreamStack:apply_definition(def)",def)

  --print(">>> xStreamStack - apply_definition...",rprint(def))

  self:initialize()

  local ignored = {
    "file_path",  -- read only
    "selected_member_index", -- applied after members
  }

  for k,v in pairs(def) do
    if not table.find(ignored,k) 
      and table.find(xStreamStack.SERIALIZABLE,k)     
    then 
      self[k] = v
    end
  end

  for k,v in ipairs(def.stack) do
    local member = xStreamStackMember(self.xstream,v.member_index)
    member:apply_definition(v)
    self:set_member(v.member_index,member)
  end

  local member_idx = def.selected_member_index
  if type(member_idx)=="number" then
    self.selected_member_index = member_idx
  end

  self:resolve_input_output()


end

---------------------------------------------------------------------------------------------------
-- Fill pattern-track in selected pattern
 
function xStreamStack:fill_track()
  TRACE("xStreamStack:fill_track()")
  
  local patt_num_lines = xPatternSequencer.get_number_of_lines(rns.selected_sequence_index)
  self:apply_stack_to_range(1,patt_num_lines,xStreamStack.OUTPUT_MODE.TRACK)

end

---------------------------------------------------------------------------------------------------
-- Fill pattern-track in selected pattern
-- @param locally (bool) relative to the top of the pattern
 
function xStreamStack:fill_selection(locally)
  TRACE("xStreamStack:fill_selection(locally)",locally)

  local passed,err = xStreamStack.validate_selection()
  if not passed then
    err = "Could not apply model to selection:\n"..err
    renoise.app():show_warning(err)
    return
  end

  local from_line = rns.selection_in_pattern.start_line
  local to_line = rns.selection_in_pattern.end_line
  local xinc = (not locally) and (from_line-1) or 0 

  self:apply_stack_to_range(from_line,to_line,xStreamStack.OUTPUT_MODE.SELECTION,xinc)

end

---------------------------------------------------------------------------------------------------
-- Fill pattern-track for the selected line
-- @param locally (bool) relative to the top of the pattern
 
function xStreamStack:fill_line(locally)
  TRACE("xStreamStack:fill_line(locally)",locally)

  local from_line = rns.transport.edit_pos.line
  local xinc = (not locally) and (from_line-1) or 0 

  self:apply_stack_to_range(from_line,from_line,xStreamStack.OUTPUT_MODE.SELECTION,xinc)

end


---------------------------------------------------------------------------------------------------
-- Write output to a range in the selected pattern,  
-- temporarily switching to a different set of buffers
-- @param from_line (int)
-- @param to_line (int) 
-- @param mode (xStreamStack.OUTPUT_MODE)
-- @param [xinc] (int) where the callback 'started'

function xStreamStack:apply_stack_to_range(from_line,to_line,mode,xinc)
  TRACE("xStreamStack:apply_stack_to_range(from_line,to_line,mode,xinc)",from_line,to_line,mode,xinc)

  assert(type(from_line)=="number")
  assert(type(to_line)=="number")
  assert(type(mode)=="number")


  local pos = rns.transport.edit_pos
  pos.line = from_line

  if not xinc then 
    xinc = 0
  end

  self:reset()
  self:clear_schedule()

  -- backup settings
  local cached_active = self.active
  local cached_pos = self.xstream.xpos.pos
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
  self.xstream.xpos.pos.line = from_line

  self:apply_to_range(from_line,to_line,pos,xinc)

  -- restore settings
  self.active = cached_active
  self.xstream.xpos.pos = cached_pos
  xSongPos.set_defaults(cached_xsongpos)

  self.output_mode = xStreamStack.OUTPUT_MODE.STREAMING

end


---------------------------------------------------------------------------------------------------

function xStreamStack:__tostring()
  return type(self) 
end


---------------------------------------------------------------------------------------------------
-- Static methods
---------------------------------------------------------------------------------------------------
-- look for certain "things" to confirm that this is a valid definition
-- @param str_def (string)
-- @return bool
--[[
function xStreamStack.looks_like_definition(str_def)

  local pre = '\[?\"?'
  local post = '\]?\"?[%s]*=[%s]*{'

  if not string.find(str_def,"return[%s]*{") or
    not string.find(str_def,pre.."stack"..post) or
    not string.find(str_def,pre.."name"..post) or
    not string.find(str_def,pre.."persist"..post) 
  then
    return false
  else
    return true
  end

end
]]

---------------------------------------------------------------------------------------------------
-- return the path to the internal models 
-- @param str_name (string)

function xStreamStack.get_normalized_file_path(str_name)
  local stacks_folder = xStreamStacks.FOLDER_NAME
  return ("%s%s.lua"):format(stacks_folder,str_name)
end

---------------------------------------------------------------------------------------------------
-- ensure that the name is unique (e.g. when creating new stacks)
-- @param str_name (string)
-- @return string

function xStreamStack.get_suggested_name(str_name)
  TRACE("xStreamStack.get_suggested_name(str_name)",str_name)

  local model_file_path = xStreamStack.get_normalized_file_path(str_name)
  local str_path = cFilesystem.ensure_unique_filename(model_file_path)
  local suggested_name = cFilesystem.get_raw_filename(str_path)
  return suggested_name

end

---------------------------------------------------------------------------------------------------
-- Ensure that selection is valid (not spanning multiple tracks)
-- @return bool
 
function xStreamStack.validate_selection()
  TRACE("xStreamStack.validate_selection()")

  local sel = rns.selection_in_pattern
  if not sel then
    return false,"Please create a (single-track) selection in the pattern"
  end
  if (sel.start_track ~= sel.end_track) then
    return false,"Selection must start and end in the same track"
  end

  return true

end

