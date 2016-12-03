--[[============================================================================
MP_UI
============================================================================]]--
--[[

User interface for MidiPerformer

]]


class 'MP_UI' (vDialog)

MP_UI.COLOR_LIT = {0xb4,0x1e,0x00}
MP_UI.COLOR_DIMMED = {0x55,0x26,0x1c}
MP_UI.COLOR_DARK = {0x28,0x28,0x28}

-------------------------------------------------------------------------------
-- vDialog
-------------------------------------------------------------------------------

function MP_UI:create_dialog()
  TRACE("MP_UI:create_dialog()")

  return self.vb:column{
    self.vb_content,
  }

end

-------------------------------------------------------------------------------

function MP_UI:show()
  TRACE("MP_UI:show()")

  vDialog.show(self)

end

--------------------------------------------------------------------------------
-- Class methods
--------------------------------------------------------------------------------

function MP_UI:__init(...)

  local args = cLib.unpack_args(...)
  assert(type(args.owner)=="MidiPerformer","Expected 'owner' to be a class instance")

  vDialog.__init(self,...)

  -- instance of main application
  self.owner = args.owner

  -- renoise.ViewBuilder
  self.vb = renoise.ViewBuilder()

  --- MP_Prefs, current settings
  self.prefs = renoise.tool().preferences

  self.options_dialog = MP_OptionsDlg{
    dialog_title = "MidiPerformer Options",
  }

  self.help_dialog = MP_HelpDlg{
    dialog_title = "MidiPerformer Help",
  }

  -- vTable
  self.vtable = nil

  --- boolean, rebuilds rows
  self.update_data_requested = true

  --- boolean, rebuilds columns  
  self.update_columns_requested = true

  --- boolean
  self.update_dialog_requested = true

  -- notifiers --

  self.dialog_visible_observable:add_notifier(function()
  end)

end

-------------------------------------------------------------------------------

function MP_UI:build()
  TRACE("MP_UI:build()")
  
  local vb = self.vb

  local vb_content = vb:column{
    margin = 6,
    spacing = 3,
    vb:row{
      vb:button{
        id = "bt_add_instrument",
        text = "Add selected instrument",
        notifier = function()
          local msg = "To add the currently selected instrument, press 'Add'. \n\nNote also that instruments are automatically added when you specify an input device in the instrument MIDI panel"
          local choice = renoise.app():show_prompt("Add instrument",msg,{"Add","Cancel"})
          if (choice == "Add") then
            table.insert(self.owner.data,MP_Instrument{
              owner = self.owner,
              instr_index = rns.selected_instrument_index,
            })
            self.update_data_requested = true
            self.update_dialog_requested = true
          end
        end,
      },
      vb:button{
        text = "Options",
        notifier = function()
          self.options_dialog:show()
        end,
      },
      vb:button{
        text = "?",
        notifier = function()
          self.help_dialog:show()
        end,
      },

    }
  }

  self.vtable = vTable{
    vb = self.vb,
    id = "vTable",
    width = 590,
    column_defs = self:gather_column_defs(),
    header_defs = {
      REMOVE = {data = " "},
      STATE = {data = "Record"},
      LABEL = {data = "Instrument name"},
      MIDI_IN = {data = "Input Device"},
      MIDI_CHANNEL = {data = "Channel"},
      MIDI_NOTE_FROM = {data = "Start Note"},
      MIDI_NOTE_TO = {data = "End Note"},
      MIDI_TRACK = {data = "Assigned track"},
    },
  }

  vb_content:add_child(self.vtable.view)
  self.vb_content = vb_content

end

-------------------------------------------------------------------------------
-- update the column definitions (devices/tracks/instruments...)

function MP_UI:gather_column_defs()
  TRACE("MP_UI:gather_column_defs()")

  if self.vtable then 
    self.vtable.rebuild_requested = true
  end

  local tracks = {"Current track"}
  for k,v in ipairs(rns.tracks) do
    if (v.type == renoise.Track.TRACK_TYPE_SEQUENCER) 
      or (v.type == renoise.Track.TRACK_TYPE_GROUP)
    then
      table.insert(tracks,v.name)
    else
      break
    end
  end

  local devices = {"None"}
  for k,v in ipairs(renoise.Midi.available_input_devices()) do
    table.insert(devices,v)
  end
  
  local handle_remove = function(elm,val)
    local item = elm.owner:get_item_by_id(elm.item_id)
    local managed,managed_idx = self.owner:get_by_instrument(item.INSTR_INDEX)
    if managed then
      local msg = [[
Are you sure you want to stop managing this instrument?

Choosing OK will remove the MIDI input from the instrument, 
but otherwise leave the instrument intact...]] 
      local choice = renoise.app():show_prompt("Remove entry",msg,{"OK","Cancel"})
      if (choice == "OK") then
        local instr = rns.instruments[managed.instr_index]
        if instr then
          instr.midi_input_properties.device_name = "" 
        end
        table.remove(self.owner.data,managed_idx)
        self.owner.update_states_requested = true
        self.update_data_requested = true 
      end
    end
  end

  local handle_state = function(elm,val)
    local item = elm.owner:get_item_by_id(elm.item_id)
    local managed = self.owner:get_by_instrument(item.INSTR_INDEX)
    if managed then
      managed.manual_arm = not managed.manual_arm
      self.owner.update_states_requested = true
      self.update_data_requested = true 
    end
  end

  local handle_label_click = function(elm,val)
    local item = elm.owner:get_item_by_id(elm.item_id)
    local managed = self.owner:get_by_instrument(item.INSTR_INDEX)
    if managed then
      local track = rns.tracks[managed.track_index]
      if track then
        rns.selected_track_index = managed.track_index 
      end
      local instr = rns.instruments[managed.instr_index]
      if instr then
        rns.selected_instrument_index = managed.instr_index 
      end
    end
  end

  local handle_midi_input = function(elm,val)
    local item = elm.owner:get_item_by_id(elm.item_id)
    local instr = rns.instruments[item.INSTR_INDEX]
    local device_idx = val
    if instr then
      if (device_idx == 1) then
        instr.midi_input_properties.device_name = "" 
      else
        local device_name = devices[device_idx]
        instr.midi_input_properties.device_name = device_name 
      end
    end
  end

  local handle_midi_channel = function(elm,val)
    local item = elm.owner:get_item_by_id(elm.item_id)
    local instr = rns.instruments[item.INSTR_INDEX]
    if instr then
      instr.midi_input_properties.channel = val
    end        
  end

  local handle_midi_note_from = function(elm,val)
    local item = elm.owner:get_item_by_id(elm.item_id)
    local instr = rns.instruments[item.INSTR_INDEX]
    if instr then
      instr.midi_input_properties.note_range = {
        val,
        instr.midi_input_properties.note_range[2]
      }
    end
  end

  local handle_midi_note_to = function(elm,val)
    local item = elm.owner:get_item_by_id(elm.item_id)
    local instr = rns.instruments[item.INSTR_INDEX]
    if instr then
      instr.midi_input_properties.note_range = {
        instr.midi_input_properties.note_range[1],
        val
      }
    end    
  end

  local handle_midi_track = function(elm,val)
    local item = elm.owner:get_item_by_id(elm.item_id)
    local instr = rns.instruments[item.INSTR_INDEX]
    local managed = self.owner:get_by_instrument(item.INSTR_INDEX)
    if managed then
      managed.track_index = val-1
      instr.midi_input_properties.assigned_track = val-1
      self.update_data_requested = true 
    end
  end

  local channel_tostring = function(self,val)
    if (val == 0) then
      return "Any"
    else
      return tostring(val)
    end
  end

  local channel_tonumber = function(self,val)
    if (val == "Any") then
      return 0
    else
      local num = tonumber(val)
      if num then
        return
      end
    end
  end
  
  local note_tostring = function(self,val)
    return xNoteColumn.note_value_to_string(val)
  end

  local note_tonumber = function(self,val)
    return xNoteColumn.note_string_to_value(val)
  end
  
  return {
    {key = "REMOVE", col_width=20, col_type=vTable.CELLTYPE.BUTTON, tooltip="Remove entry", pressed=handle_remove},
    {key = "STATE", col_width=50, col_type=vTable.CELLTYPE.BUTTON, tooltip="Record-armed state", pressed=handle_state},
    {key = "LABEL", col_width=120, col_type=vTable.CELLTYPE.TEXT, tooltip="Instrument name",notifier=handle_label_click},
    {key = "MIDI_IN", col_width=100, col_type=vTable.CELLTYPE.POPUP, tooltip="Select MIDI input port", items=devices, notifier=handle_midi_input},
    {key = "MIDI_CHANNEL", col_width=60, col_type=vTable.CELLTYPE.VALUEBOX, tooltip="Select MIDI channel", tostring=channel_tostring, tonumber=channel_tonumber, min=0, max=16, notifier=handle_midi_channel},
    {key = "MIDI_NOTE_FROM", col_width=60, col_type=vTable.CELLTYPE.VALUEBOX, tooltip="Select MIDI note-range", tostring=note_tostring, tonumber=note_tonumber, min=0, max=119, notifier=handle_midi_note_from},
    {key = "MIDI_NOTE_TO", col_width=60, col_type=vTable.CELLTYPE.VALUEBOX, tooltip="Select MIDI note-range", tostring=note_tostring, tonumber=note_tonumber, min=0, max=119, notifier=handle_midi_note_to},
    {key = "MIDI_TRACK", col_width=120, col_type=vTable.CELLTYPE.POPUP, tooltip="Select track/note routing", items=tracks, notifier=handle_midi_track},
  }

end

-------------------------------------------------------------------------------

function MP_UI:update_dialog()
  TRACE("MP_UI:update_dialog()")

  local selected_is_managed = false
  for k,v in ipairs(self.owner.data) do
    if (v.instr_index == rns.selected_instrument_index) then
      selected_is_managed = true
      break
    end
  end
  local ctrl = self.vb.views["bt_add_instrument"]
  ctrl.active = not selected_is_managed

end

-------------------------------------------------------------------------------
-- * Set color of record-arm buttons  
-- * Enable/disable cells:
--   + all midi properties, when midi input is set to "none"
--   + record-arm button, when state is automatically set  

function MP_UI:decorate_table()

  -- derived columns are disabled when no midi input:
  local midi_cols = {
    "MIDI_CHANNEL","MIDI_NOTE_FROM","MIDI_NOTE_TO","MIDI_TRACK"
  }

  for row_idx = 1, self.vtable.num_rows do
    local row_data = self.owner.data[self.vtable.row_offset + row_idx ]
    local instr = nil
    if row_data then
      if (row_data.instr_index) then
        instr = rns.instruments[row_data.instr_index] 
      end
      local lit_if_active = (row_data:determine_state(true) == MidiPerformer.STATE.ARMED)
      local unassigned = (instr.midi_input_properties.device_name=="") and true or false
      for col_idx = 1, #self.vtable.column_defs do
        local cell = self.vtable:get_cell(row_idx,col_idx)
        local col_key = self.vtable.column_defs[col_idx].key
        local is_midi_col = table.find(midi_cols,col_key) and true or false
        if is_midi_col then
          cell.active = not unassigned 
        elseif (col_key == "STATE") then
          cell.color = (row_data.state == MidiPerformer.STATE.ARMED)
            and MP_UI.COLOR_LIT 
            or (row_data.state == MidiPerformer.STATE.UNARMED)
            and MP_UI.COLOR_DARK
            or lit_if_active
            and MP_UI.COLOR_DIMMED
            or MP_UI.COLOR_DARK             
        end
      end
    end
  end

end

-------------------------------------------------------------------------------

function MP_UI:get_expanded_data()
  TRACE("MP_UI:get_expanded_data()")

  local rslt = {}
  for k,v in ipairs(self.owner.data) do
    table.insert(rslt,v:get_expanded())
  end
  table.sort(rslt,function(e1,e2)
    return e1.INSTR_INDEX < e2.INSTR_INDEX
  end)   
  return rslt

end

-------------------------------------------------------------------------------
-- handle periodic tasks

function MP_UI:on_idle()
  --TRACE("MP_UI:on_idle()")

  if self.update_columns_requested then
    self.update_columns_requested = false
    self.update_data_requested = true
    self.vtable.column_defs = self:gather_column_defs()
  end

  if self.update_data_requested then
    self.update_data_requested = false
    self.vtable.data = self:get_expanded_data() 
    self:decorate_table()
  end

  if self.update_dialog_requested then
    self.update_dialog_requested = false
    self:update_dialog()
  end

end


