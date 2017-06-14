--[[===============================================================================================
xStreamFavorites
===============================================================================================]]--
--[[

  Favorites are an indexed array, displayed as a two-dimensional grid. 

  This grid functionality means that we can insert items at "any" position:
  if you choose to insert (add) a favorite at position 27, but we only have
  16 items, the array is padded with empty tables {} 

  Other xStream classes should ignore such blank entries. 

]]

--=================================================================================================

class 'xStreamFavorites'

xStreamFavorites.LAUNCH_MODES = {"AUTOMATIC","→ STREAMING","↓ TRACK","↓ SELECTION"}
xStreamFavorites.LAUNCH_MODES_SHORT = {"","→ STR.","↓ TRK.","↓ SEL."}
xStreamFavorites.LAUNCH_MODE = {
  AUTOMATIC = 1,
  STREAMING = 2,
  APPLY_TRACK = 3,
  APPLY_SELECTION = 4,
}

xStreamFavorites.APPLY_MODES = {"PATTERN","SELECTION"}
xStreamFavorites.APPLY_MODE = {
  PATTERN = 1,
  SELECTION = 2,
}

---------------------------------------------------------------------------------------------------

function xStreamFavorites:__init(xstream)
  TRACE("xStreamFavorites:__init(xstream)",xstream)

  -- xStream, owner
  self.xstream = xstream

  -- table<instance of xStreamFavorite or empty table>
	self.items = {}

  -- track when items are added, removed
  self.favorites_observable = renoise.Document.ObservableNumberList()

  -- bool, true whenever a favorite has been edited
  -- (emulates a 'bang' - implemented as an ever-increasing integer value)
  self.modified = property(self.get_modified,self.set_modified)
  self._modified = renoise.Document.ObservableBoolean()
  self.modified_observable = renoise.Document.ObservableBang()

  -- bool, true whenever a favorite has been edited
  -- (emulates a 'bang' - implemented as an ever-increasing integer value)
  self.update_buttons_requested = property(self.get_update_buttons_requested,self.set_update_buttons_requested)
  self.update_buttons_requested_observable = renoise.Document.ObservableNumber(0)

  -- int, updated whenever we trigger a favorite (0 = none)
  self.last_triggered = property(self.get_triggered)
  self.last_triggered_index = property(self.get_last_triggered_index,self.set_last_triggered_index)
  self.last_triggered_index_observable = renoise.Document.ObservableNumber(0)

  -- bool, temporarily true as items are triggered (for UI updates)
  self.got_triggered = property(self.get_got_triggered,self.set_got_triggered)
  self.got_triggered_observable = renoise.Document.ObservableNumber(0)

  -- int, updated when triggering a favorite while in edit mode (0 = none)
  -- this value is set back to default 0 when leaving edit mode 
  self.last_selected_index = property(self.get_last_selected_index,self.set_last_selected_index)
  self.last_selected_index_observable = renoise.Document.ObservableNumber(0)

  -- xStreamFavorite or nil when none
  self.last_selected = property(self.get_last_selected)

  -- bool, when true we edit favorites instead of launching 
  self.edit_mode = property(self.get_edit_mode,self.set_edit_mode)
  self.edit_mode_observable = renoise.Document.ObservableBoolean(false)

  -- int, number of grid columns
  self.grid_columns = property(self.get_grid_columns,self.set_grid_columns)
  self.grid_columns_observable = renoise.Document.ObservableNumber(4)

  -- int, number of grid rows
  self.grid_rows = property(self.get_grid_rows,self.set_grid_rows)
  self.grid_rows_observable = renoise.Document.ObservableNumber(5)

  -- initialize --

  self:fill_page()

end

---------------------------------------------------------------------------------------------------
-- @param model_name (string), unique name of model
-- @param preset_index (int),  preset to dial in - optional
-- @param preset_bank_name (string), preset bank - optional

function xStreamFavorites:toggle_item(model_name,preset_index,preset_bank_name)
  TRACE("xStreamFavorites:toggle_item(model_name,preset_index,preset_bank_name)",model_name,preset_index,preset_bank_name)

  preset_bank_name = preset_bank_name or xStreamModelPresets.DEFAULT_BANK_NAME

  -- off
  local matched = false
  --for _,v in ipairs(self.items) do
    local favorite_index = self:get(model_name,preset_index,preset_bank_name)
    if favorite_index then
      self:clear(favorite_index)
      matched = true
    end
  --end

  -- on
  if not matched then
    self:smart_insert(xStreamFavorite{
      model_name = model_name,
      preset_index = preset_index,
      preset_bank_name = preset_bank_name})
  end

end

---------------------------------------------------------------------------------------------------
-- return the index offset of the current page
-- e.g. "16" for page 2 of a a grid with size 4x4

function xStreamFavorites:get_page_offset()

  return 0 -- TODO 

end

---------------------------------------------------------------------------------------------------
-- create empty slots that fill the current page 

function xStreamFavorites:fill_page()
  TRACE("xStreamFavorites:fill_page()")

  local offset = self:get_page_offset()
  local total_slots = self.grid_columns*self.grid_rows

  for i = 1,total_slots do
    local index = i+offset
    local item = self.items[index]
    if type(item) == "nil" then
      self:assign(index,{})
      self.favorites_observable:insert(index)
      --print("fill page - empty table at index",index)
    end
  end

end

---------------------------------------------------------------------------------------------------
-- add favorite with a bit of 'grid intelligence'
-- @param favorite (xStreamFavorite)

function xStreamFavorites:smart_insert(favorite)
  TRACE("xStreamFavorites:smart_insert(favorite)",favorite)

  assert(type(favorite)=="xStreamFavorite")

  if self.edit_mode and self.last_selected then
    -- slot selected in edit mode, assign here
    self:assign(self.last_selected_index,favorite)
  else
    -- otherwise, assign to first available slot _in page_
    local offset = self:get_page_offset()
    local found_empty_slot_at
    for idx = 1+offset,#self.items do
      if type(self.items[idx])=="table" then
        found_empty_slot_at = idx
        break
      end
    end
    if found_empty_slot_at then
      --print("inserting at first empty slot",found_empty_slot_at)
      self:assign(found_empty_slot_at,favorite)
    else
      -- add at the very end
      --print("add at the very end",#self.items)
      self:add(#self.items,favorite)
    end
  end

end

---------------------------------------------------------------------------------------------------
-- add favorite at given index (pad with empty slots if needed)
-- @param index (int)
-- @param favorite (xStreamFavorite), leave out for empty table

function xStreamFavorites:add(index,favorite)
  TRACE("xStreamFavorites:add(index,favorite)",index,favorite)

  assert(type(index)=="number")
  assert(type(favorite)=="xStreamFavorite" or type(favorite)=="nil")

  -- pad with empty slots
  if (index > #self.items) then
    for _ = #self.items+1,index-1 do 
      table.insert(self.items,{})  
      self.favorites_observable:insert(#self.items)
    end
  end

  -- favorite, or empty slot? 
  local item_to_insert = favorite and favorite or {}

  if index then
    table.insert(self.items,index,item_to_insert)  
  else
    table.insert(self.items,item_to_insert)  
  end
  self.favorites_observable:insert(#self.items)

  self.modified = true

  --print("xStreamFavorites:add",#self.favorites_observable)
  --rprint(self.items)

end

---------------------------------------------------------------------------------------------------
-- remove favorite by index
-- @param index (int)

function xStreamFavorites:remove_by_index(index)
  TRACE("xStreamFavorites:remove_by_index(index)",index)

  assert(type(index)=="number")

  table.remove(self.items,index)
  self.favorites_observable:remove(index)

  -- maintain page
  self:fill_page()

  self.modified = true

  --print("xStreamFavorites:remove_by_index",#self.favorites_observable)
  --rprint(self.items)

end

---------------------------------------------------------------------------------------------------
-- @param index (int)

function xStreamFavorites:clear(index)
  TRACE("xStreamFavorites:clear(index)",index)

  assert(type(index)=="number")

  self.items[index] = {}
  self.modified = true

  --print("xStreamFavorites:clear",#self.favorites_observable)
  --rprint(self.items)

end

---------------------------------------------------------------------------------------------------
-- assign favorite or empty slot to given index
-- @param index (int)
-- @param favorite (xStreamFavorite or empty table)

function xStreamFavorites:assign(index,favorite)
  TRACE("xStreamFavorites:assign(index,favorite)",index,favorite)

  assert(type(index)=="number")

  self.items[index] = favorite
  self.modified = true

  --print("xStreamFavorites:assign",#self.favorites_observable)
  --rprint(self.items)

end

---------------------------------------------------------------------------------------------------
-- remove favorite after having deleted a preset - will also 
-- update other favorites which share this model/preset bank 

function xStreamFavorites:remove_by_name_index(model_name,preset_index,preset_bank_name)
  TRACE("xStreamFavorites:remove_by_name_index(model_name,preset_index,preset_bank_name)",model_name,preset_index,preset_bank_name)

  local matched = false
  local triggered_index = self:get(model_name,preset_index,preset_bank_name)
  --print("triggered_index",triggered_index)
  if triggered_index then
    table.remove(self.items,triggered_index)
    matched = true
  end

  -- update other preset indices
  local modified = false
  for _,v in ipairs(self.items) do
    if (v.model_name == model_name) and
      (v.preset_bank_name == preset_bank_name) 
    then
      if v.preset_index and 
        (v.preset_index >= preset_index)
      then
        v.preset_index = v.preset_index - 1
        modified = true
      end
    end
  end

  if matched or modified then
    self.modified = true
  end

  if matched then
    self.favorites_observable:remove(triggered_index)
  end

  --print("xStreamFavorites:remove_by_name_index",#self.favorites_observable)
  --rprint(self.items)

end

---------------------------------------------------------------------------------------------------
-- friendly names - e.g. for display in popup list
-- return table<string>

function xStreamFavorites:get_names()
  TRACE("xStreamFavorites:get_names()")

  local t = {}
  for k,v in ipairs(self.items) do
    if not (type(v)=="xStreamFavorite") then
      local str_name = ("%.2d:Empty"):format(k)
      table.insert(t,str_name)
    else
      local str_name = ("%.2d:%s - %.2d (%s)"):format(
        k,v.model_name,v.preset_index or 0,v.preset_bank_name)
      table.insert(t,str_name)
      --table.insert(t,v.model_name)
    end
  end
  return t

end

---------------------------------------------------------------------------------------------------
-- retrieve (unique) model+preset combination among favorites
-- @param model_name (string), unique name of model
-- @param preset_index (int),  preset to dial in - optional
-- @param preset_bank_name (string), preset bank - optional
-- @return int or nil if not found 

function xStreamFavorites:get(model_name,preset_index,preset_bank_name)
  --TRACE("xStreamFavorites:get(model_name,preset_index,preset_bank_name)",model_name,preset_index,preset_bank_name)

  if table.is_empty(self.items) then
    return
  end

  if not preset_index then
    preset_index = 0
  end

  if not preset_bank_name then
    preset_bank_name = xStreamModelPresets.DEFAULT_BANK_NAME
  end

  for k,v in ipairs(self.items) do
    if (v.model_name == model_name) and
      (v.preset_index == preset_index) and
      (v.preset_bank_name == preset_bank_name) 
    then
      --print("*** matched",k,model_name,preset_index,preset_bank_name)
      return k
    end
  end

end

---------------------------------------------------------------------------------------------------
-- retrieve any model matching the name, regardless of preset
-- @param model_name (string)
-- @return int or nil if not found 

function xStreamFavorites:get_by_model(model_name)
  --TRACE("xStreamFavorites:get_by_model(model_name)",model_name)

  if table.is_empty(self.items) then
    return
  end

  for k,v in ipairs(self.items) do
    if (v.model_name == model_name) then
      return k
    end
  end

end

---------------------------------------------------------------------------------------------------
-- retrieve models matching the preset_bank_name
-- @param preset_bank_name (string)
-- @return table<int> 

function xStreamFavorites:get_by_preset_bank(preset_bank_name)
  TRACE("xStreamFavorites:get_by_preset_bank(preset_bank_name)",preset_bank_name)

  local t = {}

  if table.is_empty(self.items) then
    return t
  end

  for k,v in ipairs(self.items) do
    if (v.preset_bank_name == preset_bank_name) then
      table.insert(t,k)
    end
  end
  --print("xStreamFavorites:get_by_preset_bank - t...",rprint(t))
  return t

end

---------------------------------------------------------------------------------------------------
-- @param str_old (string)
-- @param str_new (string)
-- @return bool, true when one or more items were renamed

function xStreamFavorites:rename_model(str_old,str_new)
  TRACE("xStreamFavorites:rename_model(str_old,str_new)",str_old,str_new)

  local items_renamed = false

  for _,v in ipairs(self.items) do
    if (v.model_name == str_old) then
      v.model_name = str_new
      items_renamed = true
    end
  end

  return items_renamed

end


---------------------------------------------------------------------------------------------------
-- @param idx (int)
-- @return table or nil if not found

function xStreamFavorites:get_by_index(idx)
  --TRACE("xStreamFavorites:get_by_index(idx)")

  return self.items[idx]

end

---------------------------------------------------------------------------------------------------
-- when triggered via UI - launch if not in edit mode
-- @param idx (int)

function xStreamFavorites:trigger(idx)
  TRACE("xStreamFavorites:trigger(idx)",idx)

  if not self.edit_mode then
    self.last_triggered_index_observable.value = idx
    self.got_triggered = true -- flash 'last triggered' button
    self:launch(idx)
  else
    self.last_selected_index_observable.value = idx
    --self.got_selected_observable.value = true
    --self.got_selected_observable.value = false
  end

end

---------------------------------------------------------------------------------------------------
-- launch favorite 
-- @param idx (int)

function xStreamFavorites:launch(idx)
  TRACE("xStreamFavorites:launch(idx)",idx)

  local favorite = self.items[idx]
  local apply_to_track = false
  local apply_to_selection = false
  local status_msg

  if (type(favorite)~="xStreamFavorite") then
    return
  end

  local _,model = self.xstream.models:get_by_name(favorite.model_name)
  if not model then
    status_msg = ("*** xStream #%.2d [Trigger] - could not launch, model not found"):format(idx)
    --print("status_msg",status_msg)
    renoise.app():show_status(status_msg)
    LOG(status_msg)
    return
  end

  if (favorite.launch_mode == xStreamFavorites.LAUNCH_MODE.AUTOMATIC) then
    if rns.transport.playing then
      self.xstream.stack:schedule_item(favorite.model_name,favorite.preset_index,favorite.preset_bank_name)
      status_msg = "*** xStream #%.2d [Trigger] - %s %.2d:%s - Automatic → STREAMING"
    else
      if not rns.selection_in_pattern then
        status_msg = "*** xStream #%.2d [Trigger] - %s %.2d:%s - Automatic ↓ TRACK"
        apply_to_track = true
      else
        status_msg = "*** xStream #%.2d [Trigger] - %s %.2d:%s - Automatic ↓ SELECTION"
        apply_to_selection = true
      end
    end
  elseif (favorite.launch_mode == xStreamFavorites.LAUNCH_MODE.STREAMING) then
    if rns.transport.playing then
      self.xstream.stack.scheduling = (favorite.schedule_mode) and favorite.schedule_mode or self.xstream.stack.scheduling
      self.xstream.stack:schedule_item(favorite.model_name,favorite.preset_index,favorite.preset_bank_name)
      status_msg = "*** xStream #%.2d [Trigger] - %s %.2d:%s → STREAMING"
    else
      self.xstream:focus_to_favorite(idx)
      status_msg = "*** xStream #%.2d [Trigger] - %s %.2d:%s → STREAMING (stopped)"
    end
  elseif (favorite.launch_mode == xStreamFavorites.LAUNCH_MODE.APPLY_TRACK) then
    status_msg = "*** xStream #%.2d [Trigger] - %s %.2d:%s ↓ TRACK"
    apply_to_track = true
  elseif (favorite.launch_mode == xStreamFavorites.LAUNCH_MODE.APPLY_SELECTION) then
    status_msg = "*** xStream #%.2d [Trigger] - %s %.2d:%s ↓ SELECTION"
    apply_to_selection = true
  end

  if status_msg then
    status_msg = status_msg:format(idx,favorite.model_name,favorite.preset_index,favorite.preset_bank_name)
    --print("status_msg",status_msg)
    renoise.app():show_status(status_msg)
    LOG(status_msg)
  end

  if apply_to_track then
    apply_to_track = true
    self.xstream:focus_to_favorite(idx)
    self.xstream.stack:fill_track()
  elseif apply_to_selection then
    self.xstream:focus_to_favorite(idx)
    local locally = (favorite.apply_mode == xStreamFavorites.APPLY_MODE.SELECTION)
    self.xstream.stack:fill_selection(locally)
  end

end

---------------------------------------------------------------------------------------------------
-- auto-saving of favorites to a predefined location

function xStreamFavorites:save()
  TRACE("xStreamFavorites:save()")
  self:export(self:get_path())
end

---------------------------------------------------------------------------------------------------
-- Get complete path to favorites.xml 
-- @return string 

function xStreamFavorites:get_path()
  TRACE("xStreamFavorites:get_path()")
  return xStreamUserData.USERDATA_ROOT .. xStreamUserData.FAVORITES_FILE_PATH
end

---------------------------------------------------------------------------------------------------
-- @param file_path (string) TODO make option (prompt for file)

function xStreamFavorites:export(file_path)
  TRACE("xStreamFavorites:export(file_path)",file_path)

  local doc = renoise.Document.create("xStreamFavorites"){}

  doc:add_property("grid_columns", renoise.Document.ObservableNumber(self.grid_columns))
  doc:add_property("grid_rows", renoise.Document.ObservableNumber(self.grid_rows))

	local doc_list = renoise.Document.DocumentList()
  doc:add_property("Favorites",doc_list)
  local node_favorite 
  for _,v in ipairs(self.items) do
    --print("export",k,rprint(v))
    --print("v.model_name",v.model_name)
    node_favorite = renoise.Document.create("xStreamFavorite"){}
    node_favorite:add_property("model_name", renoise.Document.ObservableString(v.model_name or ""))
    node_favorite:add_property("preset_index", renoise.Document.ObservableNumber(v.preset_index or 0))
    node_favorite:add_property("preset_bank_name", renoise.Document.ObservableString(v.preset_bank_name or ""))
    node_favorite:add_property("schedule_mode", renoise.Document.ObservableNumber(v.schedule_mode or 0))
    node_favorite:add_property("launch_mode", renoise.Document.ObservableNumber(v.launch_mode or 0))
    node_favorite:add_property("apply_mode", renoise.Document.ObservableNumber(v.apply_mode or 0))
    doc_list:insert(#doc_list+1,node_favorite)
    --print("add_property",node_favorite,k,v)
  end
  
  doc:save_as(file_path)

end

---------------------------------------------------------------------------------------------------
-- @param file_path (string) TODO make option (prompt for file)
-- @return bool, true when succeeded
-- @return string, error message when failed

function xStreamFavorites:import(file_path)
  TRACE("xStreamFavorites:import(file_path)",file_path)

  local fhandle = io.open(file_path,"r")
  if not fhandle then
    return false, "ERROR: Failed to open file handle"
  end

  local str_xml = fhandle:read("*a")
  fhandle:close()
  
  local rslt,err = cParseXML.parse(str_xml)
  if not rslt then
    return false, err
  end

  -- clear existing
  self.items = {}
  for i=#self.favorites_observable,1,-1 do
    --print("removing favorites_observable#",i)
    self.favorites_observable:remove(i)
  end

  local grid_columns = self.grid_columns
  local grid_rows = self.grid_rows


  for _,v in ipairs(rslt.kids) do
    if (v.name == "xStreamFavorites") then
      for __,v2 in ipairs(v.kids) do
        --print("v2",v2,v2.name)
        if (v2.name == "grid_columns") then
          grid_columns = tonumber(v2.kids[1].value)
        elseif (v2.name == "grid_rows") then
          grid_rows = tonumber(v2.kids[1].value)
        elseif (v2.name == "Favorites") then
          for __,v3 in ipairs(v2.kids) do
            --print("v3",v3,v3.name)
            local model_name,preset_index,preset_bank_name,schedule_mode,launch_mode,apply_mode
            for __,v4 in ipairs(v3.kids) do
              if (v4.name == "model_name") then
                model_name = v4.kids[1] and v4.kids[1].value
              elseif (v4.name == "preset_index") then
                preset_index = v4.kids[1] and tonumber(v4.kids[1].value)
                --preset_index = (preset_index > 0) and preset_index or nil
              elseif (v4.name == "preset_bank_name") then
                preset_bank_name = v4.kids[1] and v4.kids[1].value
              elseif (v4.name == "schedule_mode") then
                schedule_mode = v4.kids[1] and tonumber(v4.kids[1].value)
              elseif (v4.name == "launch_mode") then
                launch_mode = v4.kids[1] and tonumber(v4.kids[1].value)
              elseif (v4.name == "apply_mode") then
                apply_mode = v4.kids[1] and tonumber(v4.kids[1].value)
              end
            end
            if model_name then
              self:add(#self.items+1,xStreamFavorite{
                model_name = model_name,
                preset_index = preset_index,
                preset_bank_name = preset_bank_name,
                schedule_mode = schedule_mode,
                launch_mode = launch_mode,
                apply_mode = apply_mode})
            else
              self:add(#self.items+1)
            end
          end
        end
      end
    end
  end

  self.grid_columns = grid_columns
  self.grid_rows = grid_rows

  self:fill_page()

end

---------------------------------------------------------------------------------------------------
-- Get/setter interface
---------------------------------------------------------------------------------------------------

function xStreamFavorites:get_update_buttons_requested()
  return self.update_buttons_requested_observable.value
end

function xStreamFavorites:set_update_buttons_requested()
  self.update_buttons_requested_observable.value = self.update_buttons_requested_observable.value + 1
end

---------------------------------------------------------------------------------------------------

function xStreamFavorites:get_modified()
  return self._modified
end

function xStreamFavorites:set_modified()
  TRACE("xStreamFavorites:set_modified()")
  self._modified = true
  self.modified_observable:bang()
end

---------------------------------------------------------------------------------------------------

function xStreamFavorites:get_triggered()
  local item_idx = self.last_triggered_index_observable.value
  return self.items[item_idx]
end

---------------------------------------------------------------------------------------------------

function xStreamFavorites:get_last_triggered_index()
  return self.last_triggered_index_observable.value
end

function xStreamFavorites:set_last_triggered_index(val)
  self.last_triggered_index_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamFavorites:get_got_triggered()
  return self.last_triggered_index_observable.value
end

function xStreamFavorites:set_got_triggered()
  self.last_triggered_index_observable.value = self.last_triggered_index_observable.value + 1
end

---------------------------------------------------------------------------------------------------

function xStreamFavorites:get_last_selected()
  local item_idx = self.last_selected_index_observable.value
  return self.items[item_idx]
end

---------------------------------------------------------------------------------------------------

function xStreamFavorites:get_last_selected_index()
  return self.last_selected_index_observable.value
end

function xStreamFavorites:set_last_selected_index(val)
  self.last_selected_index_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamFavorites:get_edit_mode()
  return self.edit_mode_observable.value
end

function xStreamFavorites:set_edit_mode(val)
  self.edit_mode_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamFavorites:get_grid_columns()
  return self.grid_columns_observable.value
end

function xStreamFavorites:set_grid_columns(cols)
  assert(type(cols)=="number")
  if (cols ~= self.grid_columns_observable.value) then
    self.modified = true
  end
  self.grid_columns_observable.value = cols
end

---------------------------------------------------------------------------------------------------

function xStreamFavorites:get_grid_rows()
  return self.grid_rows_observable.value
end

function xStreamFavorites:set_grid_rows(rows)
  --print("xStreamFavorites:set_grid_rows(rows)",rows,self.grid_rows_observable.value)
  assert(type(rows)=="number")
  if (rows ~= self.grid_rows_observable.value) then
    self.modified = true
  end
  self.grid_rows_observable.value = rows
end


