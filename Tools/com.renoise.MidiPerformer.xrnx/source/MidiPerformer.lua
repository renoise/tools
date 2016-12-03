--[[============================================================================
MidiPerformer
============================================================================]]--
--[[

MidiPerformer application
.
#

]]

class 'MidiPerformer'

MidiPerformer.STATE = {
  UNARMED = 1,  
  ARMED = 2,
  MUTED = 3,
  SILENT = 4,
  UNDEFINED = 5, -- initial state
}

--------------------------------------------------------------------------------

function MidiPerformer:__init(...)

  local args = cLib.unpack_args(...)

  --- MP_Prefs, current settings
  self.prefs = renoise.tool().preferences

  --- string
  self.app_display_name = args.app_display_name

  --- table, data for table/application 
  self.data = {}

  --- configure user-interface
  self.ui = MP_UI{
    dialog_title = self.app_display_name,
    owner = self,
    waiting_to_show_dialog = self.prefs.autoshow.value,
  }

  --- table of functions
  self.instr_handlers = {}

  -- notifications --------------------

  renoise.tool().app_new_document_observable:add_notifier(function()
    rns = renoise.song()
    self:reset()
    self.update_states_requested = true
    self.ui.update_columns_requested = true
    self.ui.update_dialog_requested = true
  end)

  -- MIDI port setup changed
  renoise.Midi.devices_changed_observable():add_notifier(function()
    self.ui.update_columns_requested = true
  end)

  cObservable.attach(renoise.tool().app_idle_observable,self,self.on_idle)

  self.prefs.autoarm_on_edit_enable:add_notifier(function()
    self.update_states_requested = true
  end)

  self.prefs.disable_when_track_silent:add_notifier(function()
    self.update_states_requested = true
  end)

  self.prefs.disable_when_track_muted:add_notifier(function()
    self.update_states_requested = true
  end)

  -- midi mappings --------------------

  self.mappings = {
    manual_arm_track = {}
  }

  for k = 1,32 do
    local str_name = ("Tools:MidiPerformer:Manual Arm #%.2d [Set]"):format(k)
    table.insert(self.mappings.manual_arm_track,str_name)
    renoise.tool():add_midi_mapping {
      name = str_name,
      invoke = function(msg)
        local managed = self.data[k] 
        if managed then
          if (msg:is_switch()) then
            managed.manual_arm = msg.boolean_value
            self.update_states_requested = true
            self.ui.update_data_requested = true
          end
        end
      end
    }    
  end


  -- initialize -----------------------

  self:reset()
  self.ui:build()

end

-------------------------------------------------------------------------------

function MidiPerformer:reset()

  self.data = {}
  self:attach_to_song()
  self:gather_data()
  self:check_track_assignments()
  self.update_states_requested = true
end

-------------------------------------------------------------------------------

function MidiPerformer:gather_data()
  TRACE("MidiPerformer:gather_data()")

  local rslt = self.data
  local instr_indices = self:get_managed_instrument_indices()

  for k,v in ipairs(rns.instruments) do
    if (v.midi_input_properties.device_name ~= "") then
      if not table.find(instr_indices,k) then
        table.insert(self.data,MP_Instrument{
          owner = self,
          instr_index = k,
        })
      end
    end
  end

  self.data = rslt

end

--------------------------------------------------------------------------------

function MidiPerformer:get_managed_instrument_indices()
  TRACE("MidiPerformer:get_managed_instrument_indices")

  local rslt = {}
  for k,v in ipairs(self.data) do
    table.insert(rslt,v.instr_index)
  end
  return rslt
end

--------------------------------------------------------------------------------

function MidiPerformer:get_by_instrument(instr_idx)
  --TRACE("MidiPerformer:get_by_instrument",instr_idx)
  for k,v in ipairs(self.data) do
    if (instr_idx == v.instr_index) then 
      return v,k
    end
  end
end

--------------------------------------------------------------------------------

function MidiPerformer:update_states()
  TRACE("MidiPerformer:update_states()")

  local edit_mode = rns.transport.edit_mode

  for k,v in ipairs(self.data) do
    local instr = rns.instruments[v.instr_index]
    if not instr then
      LOG("*** Could not retrieve managed instrument",v)
    else
      local state_changed = false
      local old_state = v.state
      local new_state = v:determine_state()
      if (old_state ~= new_state) then
        v.state = new_state
        local is_armed = (new_state == MidiPerformer.STATE.ARMED)
        local track_idx = v.track_index or instr.midi_input_properties.assigned_track
        
        -- check if we need to block notes (route to group)
        -- true when rehearsing in manually armed mode
        local group_idx = nil
        if not is_armed then 
          local resolved_track_idx = xInstrument.resolve_midi_track(instr)
          local resolved_track = rns.tracks[resolved_track_idx]
          -- use the nearest group track 
          if resolved_track and (resolved_track.type == renoise.Track.TRACK_TYPE_GROUP) then
            group_idx = resolved_track_idx
          else
            group_idx = xTrack.get_group_track_index(resolved_track_idx,true)
          end
          -- create group if missing 
          if not group_idx and resolved_track 
            and (resolved_track.type == renoise.Track.TRACK_TYPE_SEQUENCER)
          then 
            group_idx = resolved_track_idx+1
            rns:insert_group_at(group_idx)
            rns:add_track_to_group(resolved_track_idx,group_idx)
          end
          instr.midi_input_properties.assigned_track = group_idx
        elseif is_armed then
          instr.midi_input_properties.assigned_track = track_idx
        end
        v.track_index = track_idx 
        self.ui.update_data_requested = true 

        -- enable edit mode or we can't record any notes...
        if is_armed and not rns.transport.edit_mode then 
          rns.transport.edit_mode = true
        end

      end
    end
  end

end

--------------------------------------------------------------------------------

function MidiPerformer:attach_to_song()
  TRACE("MidiPerformer:attach_to_song()")

  cObservable.attach(rns.instruments_observable,self,self.handle_instruments_change)
  cObservable.attach(rns.tracks_observable,self,self.handle_tracks_change)
  cObservable.attach(rns.selected_instrument_observable,self,self.handle_selected_instrument)

  cObservable.attach(rns.transport.edit_mode_observable,function()
    self.update_states_requested = true
    self.ui.update_data_requested = true
  end)

  self:attach_to_instruments()
  self:attach_to_tracks()

end

--------------------------------------------------------------------------------
-- implemented in a way that allows passing the instrument as
-- argument to the handler 

function MidiPerformer:attach_to_instruments()

  self:detach_from_instruments()
  self.instr_handlers = {}

  for k,v in ipairs(rns.instruments) do
    
    local obs = v.name_observable
    local notifier = function()
      self.ui.update_data_requested = true
    end
    obs:add_notifier(notifier)    
    table.insert(self.instr_handlers,notifier)
    
    local obs = v.midi_input_properties.device_name_observable
    local notifier = function()
      local mp_instr = self:get_by_instrument(k)
      --if mp_instr and (v.midi_input_properties.device_name ~= "") then
      --  mp_instr.device_name = v.midi_input_properties.device_name
      --end
      self:gather_data()
      self.ui.update_data_requested = true
    end
    obs:add_notifier(notifier)    
    table.insert(self.instr_handlers,notifier)

    local obs = v.midi_input_properties.channel_observable
    local notifier = function()
      self.ui.update_data_requested = true
    end
    obs:add_notifier(notifier)    
    table.insert(self.instr_handlers,notifier)

    local obs = v.midi_input_properties.note_range_observable
    local notifier = function()
      self.ui.update_data_requested = true
    end
    obs:add_notifier(notifier)    
    table.insert(self.instr_handlers,notifier)

    local obs = v.midi_input_properties.assigned_track_observable
    local notifier = function()
      self.ui.update_data_requested = true
    end
    obs:add_notifier(notifier)    
    table.insert(self.instr_handlers,notifier)

  end

end

--------------------------------------------------------------------------------

function MidiPerformer:detach_from_instruments()

  if table.is_empty(self.instr_handlers) then
    return
  end

  for k,v in ipairs(rns.instruments) do
    for k2,v2 in ipairs(self.instr_handlers) do
      local obs = v.midi_input_properties.device_name_observable  
      if (obs:has_notifier(v2)) then
        obs:remove_notifier(v2)
      end
      local obs = v.midi_input_properties.channel_observable  
      if (obs:has_notifier(v2)) then
        obs:remove_notifier(v2)
      end
      local obs = v.midi_input_properties.note_range_observable  
      if (obs:has_notifier(v2)) then
        obs:remove_notifier(v2)
      end
      local obs = v.midi_input_properties.assigned_track_observable  
      if (obs:has_notifier(v2)) then
        obs:remove_notifier(v2)
      end
    end
  end

end

--------------------------------------------------------------------------------

function MidiPerformer:attach_to_tracks()

  for k,v in ipairs(rns.tracks) do
    
    local obs = v.mute_state_observable
    cObservable.attach(obs,self,self.handle_track_mute_state)

    local obs = v.prefx_volume.value_observable
    cObservable.attach(obs,self,self.handle_track_prefx_volume)

  end

end

-------------------------------------------------------------------------------

function MidiPerformer:handle_instruments_change(args)
  TRACE("MidiPerformer:instruments_observable fired...",args)

  if (args.type == "insert") then
    for k,v in ipairs(self.data) do
      if (v.instr_index >= args.index) then
        v.instr_index = v.instr_index+1 
      end
    end
  elseif (args.type == "remove") then
    for k,v in ipairs(self.data) do
      if (v.instr_index > args.index) then
        v.instr_index = v.instr_index-1 
      end
    end
  elseif (args.type == "swap") then
    for k,v in ipairs(self.data) do
      if (v.instr_index == args.index1) then
        v.instr_index = args.index2
      elseif (v.instr_index == args.index2) then
        v.instr_index = args.index1
      end      
    end    
  end
  self:attach_to_instruments()
  self.ui.update_columns_requested = true

end

-------------------------------------------------------------------------------

function MidiPerformer:handle_selected_instrument()
  TRACE("MidiPerformer:handle_selected_instrument fired...")
  self.ui.update_dialog_requested = true
end

-------------------------------------------------------------------------------

function MidiPerformer:handle_tracks_change(args)
  TRACE("MidiPerformer:tracks_observable fired...",args)

  if (args.type == "insert") then
    for k,v in ipairs(self.data) do
      if v.track_index and (v.track_index >= args.index) then
        v.track_index = v.track_index+1 
      end
    end  
  elseif (args.type == "remove") then
    for k,v in ipairs(self.data) do
      if v.track_index and (v.track_index > args.index) then
        v.track_index = v.track_index-1 
      end
    end  
  elseif (args.type == "swap") then
    for k,v in ipairs(self.data) do
      if v.track_index then
        if (v.track_index == args.index1) then
          v.track_index = args.index2
        elseif (v.track_index == args.index2) then
          v.track_index = args.index1
        end      
      end      
    end    
  end
  
  self:attach_to_tracks()
  self.ui.update_columns_requested = true
end

-------------------------------------------------------------------------------

function MidiPerformer:handle_track_mute_state()
  TRACE("MidiPerformer:handle_track_mute_state...")
  if (self.prefs.disable_when_track_muted.value) then
    self.update_states_requested = true
  end  
end

-------------------------------------------------------------------------------

function MidiPerformer:handle_track_prefx_volume()
  TRACE("MidiPerformer:handle_track_prefx_volume...")
  if (self.prefs.disable_when_track_silent.value) then
    self.update_states_requested = true
  end    
end

-------------------------------------------------------------------------------

function MidiPerformer:check_track_assignments()
  TRACE("MidiPerformer:check_track_assignments()")

  local has_group_assignment = false
  for k,v in ipairs(self.data) do
    local instr = rns.instruments[v.instr_index]
    if instr then
      local track_idx = xInstrument.resolve_midi_track(instr)
      local track = rns.tracks[track_idx]
      if track and (track.type == renoise.Track.TRACK_TYPE_GROUP) then
        has_group_assignment = true
        break
      end
    end
  end

  if has_group_assignment then
    local do_fix = false
    if self.prefs.autofix_track_assignments.value then
      do_fix = true
    else
      local title = "Nessage from MidiPerformer"
      local vb = renoise.ViewBuilder()
      local view = vb:column{
        margin = 8,
        vb:text{
          text = [[
  One or more instruments have been assigned to group tracks - 
  but notes can't be recorded into such tracks. 
  
  This condition is very likely to have been caused by the tool 
  itself, as it uses group tracks as temporary assignments. 

  Choose 'Fix' to assign the instruments to tracks, or 'Ignore' 
  to leave the assignments as they are. Choosing 'Auto-fix' 
  will attempt to fix any future conditions automatically
  without displaying this dialog.    
  ]],
        },
      }
      local choice = renoise.app():show_custom_prompt(title,view,{"Fix","Auto-fix","Ignore"})
      if (choice == "Auto-fix") then
        self.prefs.autofix_track_assignments.value = true
        do_fix = true
      elseif (choice == "Fix") then
        do_fix = true
      end 
    end
    if do_fix then
      self:fix_track_assignments()
    end
  end

end

-------------------------------------------------------------------------------

function MidiPerformer:fix_track_assignments()
  TRACE("MidiPerformer:fix_track_assignments()")

  for k,v in ipairs(self.data) do
    local instr = rns.instruments[v.instr_index]
    if instr then
      local track_idx = xInstrument.resolve_midi_track(instr)
      local track = rns.tracks[track_idx]
      if track and (track.type == renoise.Track.TRACK_TYPE_GROUP) then
        local seq_track = xTrack.get_first_sequencer_track_in_group(track_idx)
        if seq_track then
          instr.midi_input_properties.assigned_track = seq_track
        end
      end
    end
  end

end

-------------------------------------------------------------------------------

function MidiPerformer:on_idle()
  --TRACE("MidiPerformer:on_idle()")
  if self.update_states_requested then
    self.update_states_requested = false
    self:update_states()
  end
  self.ui:on_idle()
end
