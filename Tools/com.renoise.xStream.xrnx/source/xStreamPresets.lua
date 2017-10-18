--[[===============================================================================================
xStreamPresets
===============================================================================================]]--
--[[

	This class manages argument-presets 

  The default bank is always the first one, and saved along with the model
  when exporting the model definition. Other banks are automatically 
  maintained as external XML files, residing in the ./presets subfolder

  ## Integration with favorites

  If/when you favorite a preset, external banks will feature the bank name 
  as part of the favorite entry. When loading the favorites, such entries
  will automatically load the given preset bank.


]]

--=================================================================================================

class 'xStreamPresets'

xStreamPresets.DEFAULT_BANK_NAME = "Default bank"

---------------------------------------------------------------------------------------------------

function xStreamPresets:__init(model)

  -- xStreamPresets, owner
  self.model = model

  -- table<table>, the actual entries
	self.presets = {}

  -- table<table>, name of each preset
	self.preset_names = {}

  -- string, name of this preset bank (needs to be valid filename)
	self.name = property(self.get_name,self.set_name)
  self.name_observable = renoise.Document.ObservableString(xStreamPresets.DEFAULT_BANK_NAME)

  -- DocumentObservableBang, fires when eligible for export
  self.modified = property(self.get_modified,self.set_modified)
  self._modified = renoise.Document.ObservableBoolean()
  self.modified_observable = renoise.Document.ObservableBang()

  -- ObservableNumberList, notifier fired when items are added/removed 
  self.presets_observable = renoise.Document.ObservableNumberList()

  -- int, active preset (0 when none is active)
  self.selected_preset_index = property(
    self.get_selected_preset_index,self.set_selected_preset_index)
  self.selected_preset_index_observable = renoise.Document.ObservableNumber(0)


end

---------------------------------------------------------------------------------------------------
-- Get/set methods
---------------------------------------------------------------------------------------------------

function xStreamPresets:get_name()
  return self.name_observable.value
end

function xStreamPresets:set_name(val)
  self.name_observable.value = val
end

---------------------------------------------------------------------------------------------------

function xStreamPresets:get_modified()
  return self._modified
end

function xStreamPresets:set_modified()
  self._modified = true
  self.modified_observable:bang()
end

---------------------------------------------------------------------------------------------------

function xStreamPresets:get_selected_preset_index()
  TRACE("xStreamPresets:get_selected_preset_index()")
  return self.selected_preset_index_observable.value
end

function xStreamPresets:set_selected_preset_index(idx)
  TRACE("xStreamPresets:set_selected_preset_index(idx)",idx)

  if (#self.presets == 0) then
    idx = 0
  end

  if idx and (idx > #self.presets) then
    idx = 0
  end

  self.selected_preset_index_observable.value = idx

end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------
-- Select the previous preset 

function xStreamPresets:select_previous()
  TRACE("xStreamPresets:select_previous()")
  local idx = self.selected_preset_index
  if (idx > 1) then 
    self.selected_preset_index = idx - 1
  end 
end 

---------------------------------------------------------------------------------------------------
-- Select the next preset 

function xStreamPresets:select_next()
  TRACE("xStreamPresets:select_next()")
  local idx = self.selected_preset_index
  if (idx < #self.presets) then 
    self.selected_preset_index = idx + 1
  end 
end 

---------------------------------------------------------------------------------------------------
-- add current/supplied values as new preset 
-- @param t (table) use these values 
-- @return bool, true when preset was added
-- @return err, message when preset was not added 

function xStreamPresets:add_preset(t)
  TRACE("xStreamPresets:add_preset(t)",t)

  if (#self.model.args.args == 0) then
    return false, "Please add one or more arguments to the model - otherwise, a preset have no values to represent!"
  end

  local preset = {}
  local preset_name = ""
  if not t then
    -- add current values
    for _,arg in ipairs(self.model.args.args) do
      preset[arg.full_name] = arg.observable.value
    end
  else
    -- add supplied values
    for k,v in pairs(t) do
      if (k == "name") then
        preset_name = v
      else
        preset[k] = v
      end
    end
  end

  --preset_name = preset_name or "Preset #"..#self.presets

  table.insert(self.presets,preset)
  table.insert(self.preset_names,preset_name)
  self.presets_observable:insert(#self.presets)

  self.modified = true

  return true

end

---------------------------------------------------------------------------------------------------

function xStreamPresets:remove_all_presets()
  TRACE("xStreamPresets:remove_all_presets()")

  for k,v in ripairs(self.presets) do
    self:remove_preset(k)
  end

end

---------------------------------------------------------------------------------------------------
-- @param idx (int)

function xStreamPresets:remove_preset(idx)
  TRACE("xStreamPresets:remove_preset(idx)",idx)

  local preset = self.presets[idx]
  if not preset then
    LOG(("Could not remove preset with index #%d- it doesn't exist"):format(idx))
    return
  end

  table.remove(self.presets,idx)
  table.remove(self.preset_names,idx)
  self.presets_observable:remove(idx)

  -- remove from favorites
  self.model.process.xstream.favorites:remove_by_name_index(self.model.name,idx,self.name)

  if (idx == self.selected_preset_index) then
    self.selected_preset_index = 0
  elseif (idx < self.selected_preset_index) then
    self.selected_preset_index = self.selected_preset_index - 1   
  end

  self.modified = true

end

---------------------------------------------------------------------------------------------------

function xStreamPresets:swap_index(idx1,idx2)

  if (idx1 < 1 and idx2 > 1) then
    return false,"Cannot swap entries - either index is too low"
  elseif (idx1 > #self.presets or idx2 > #self.presets) then
    return false,"Cannot swap entries - either index is too high"
  end

  self.preset_names[idx1],self.preset_names[idx2] = 
    self.preset_names[idx2],self.preset_names[idx1]

  self.presets[idx1],self.presets[idx2] = 
    self.presets[idx2],self.presets[idx1]

  self.presets_observable:swap(idx1,idx2)

  return true


end

---------------------------------------------------------------------------------------------------
-- update a preset with the current set of values
-- @param idx (int)

function xStreamPresets:update_preset(idx)
  TRACE("xStreamPresets:update_preset(idx)",idx)

  local preset = self.presets[idx]
  if not preset then
    LOG("could not find preset with index",idx)
    return
  end

  for _,arg in ipairs(self.model.args.args) do
    preset[arg.full_name] = arg.value
  end

  --rprint(preset)
  self.modified = true

end

---------------------------------------------------------------------------------------------------
-- get preset "display name" - for use in lists, selectors etc.
-- @return string 

function xStreamPresets:get_preset_display_name(idx)
  TRACE("xStreamPresets:get_preset_display_name(idx)",idx)

  if (idx < 1) or (idx > #self.presets) then
    return ""
  end

  if not self.preset_names[idx] or (self.preset_names[idx] == "") then
    return "Preset #"..idx
  else
    return self.preset_names[idx]
  end

end
  

---------------------------------------------------------------------------------------------------
-- recall/activate preset 
-- @param idx (int)
-- @return bool, true when all arguments were recalled
-- @return string, message listing failed arguments or nil if no preset

function xStreamPresets:recall_preset(idx)
  TRACE("xStreamPresets:recall_preset(idx)",idx)

  local preset = self.presets[idx]
  if not preset then
    return false
  end
  
  local failed_args = {}
  for _,arg in ipairs(self.model.args.args) do
    if type(preset[arg.full_name]) ~= "nil" then
      if not arg.locked then
        --print("recalling value - preset[arg.name].value",arg.name,preset[arg.name])
        arg.value = preset[arg.full_name]
        arg.observable.value = preset[arg.full_name]
      end
    else
      table.insert(failed_args,arg.name)
    end
  end

  self.selected_preset_index = idx

  if not table.is_empty(failed_args) then
    local msg = "WARNING: The following arguments could not be recalled: "
      ..table.concat(failed_args,", ")
    LOG(msg)
    return false,msg
  else
    return true
  end

end

---------------------------------------------------------------------------------------------------
-- rename this preset bank (also applies to preset folder, if it exists)
-- @return bool, true when succeeded or user aborted, false when failed
-- @return string, error message when failed

function xStreamPresets:rename(str_name)
  TRACE("xStreamPresets:rename(str_name)",str_name)

  if not str_name then
    str_name = vPrompt.prompt_for_string(self.name,
      "Enter a new name","Rename Preset Bank")
    if not str_name then
      return true
    end
  end

  if not cFilesystem.validate_filename(str_name) then
    return false,"Please avoid using special characters in the name"
  end

  local str_from = self:path_to_xml(self.name)
  if (self.name ~= xStreamPresets.DEFAULT_BANK_NAME) then
    local str_to = self:path_to_xml(str_name)
    if io.exists(str_from) then
      if io.exists(str_to) then
        return false, "Warning: a preset folder with the given name already exists: "..str_to
      end
      local success,err = cFilesystem.rename(str_from,str_to)
      if not success then
        return false, "Error during preset-bank rename: "..err
      end
    end
  end

  local old_name = self.name
  self.name = str_name

  -- favorites might be affected
  local preset_bank_name = self.model.selected_preset_bank.name
  local favorites = self.model.process.xstream.favorites:get_by_preset_bank(old_name)
  if (#favorites > 0) then
    for k,v in ipairs(favorites) do
      self.model.process.xstream.favorites.items[v].preset_bank_name = self.name
    end
    self.model.process.xstream.favorites.update_buttons_requested = true
    self.model.process.xstream.favorites.modified = true
  end

  return true

end

---------------------------------------------------------------------------------------------------
-- @param idx (int)
-- @param str_name (string)
-- @return bool, true when successful
-- @return string, error message when failed

function xStreamPresets:rename_preset(idx,str_name)
  TRACE("xStreamPresets:rename_preset(idx,str_name)",idx,str_name)

  if (idx < 1) or (idx > #self.presets) then
    return false,"Can't rename preset - index is too low or high"
  end

  if not str_name then
    str_name = vPrompt.prompt_for_string(self.preset_names[idx],
      "Enter a name","Rename Preset")
    if not str_name then
      return false
    end
  end

  str_name = cString.sanitize_string(str_name)

  self.preset_names[idx] = str_name
  self.modified = true

  return true

end

---------------------------------------------------------------------------------------------------
-- Import presets from xml file, preserving existing presets

function xStreamPresets:merge()
  TRACE("xStreamPresets:merge()")

  local clear_existing = false
  self:import(clear_existing)

end

---------------------------------------------------------------------------------------------------
-- Import all presets from xml file
-- @param file_path (string), prompt user if not defined
-- @param clear_existing (bool)
-- @return bool, true when import was (at least partially) successful
-- @return string, error message when failed

function xStreamPresets:import(file_path,clear_existing)
  TRACE("xStreamPresets:import(file_path,clear_existing)",file_path,clear_existing)

  if not file_path then
    local ext = {"*.xml"}
    local title = "Import preset bank"
    file_path = renoise.app():prompt_for_filename_to_read(ext,title)
    if (file_path == "") then
      LOG("Aborted loading...")
      return false
    end
  end

  local fhandle = io.open(file_path,"r")
  if not fhandle then
    fhandle:close()
    return false, "ERROR: Failed to open file handle"
  end

  local str_xml = fhandle:read("*a")
  fhandle:close()

  local rslt,err = cParseXML.parse(str_xml)
  if not rslt then
    return false, rslt
  end

  if clear_existing then
    for i = #self.presets,1,-1 do
      self:remove_preset(i)
    end
  end

  if table.is_empty(rslt) then
    return false,"no presets available in file"
  end

  local last_inserted_preset_index = 0

  local arg_names = self.model.args:get_names()

  for _,v in ipairs(rslt.kids) do
    if (v.name == "xStreamPresets") then
      for __,v2 in ipairs(v.kids) do
        if (v2.name == "Presets") then
          for k3,v3 in ipairs(v2.kids) do
            if (v3.name == "Preset") then
              local preset = {}
              local preset_name = ""
              for ___,v4 in ipairs(v3.kids) do
                if (v4.name == "name") then
                  -- name is a special entry
                  preset_name = v4.kids[1] and v4.kids[1].value
                else
                  local arg_name = xStreamPresets.parse_xml_arg_name(v4.name)
                  local arg_index = table.find(arg_names,arg_name)
                  if arg_index then
                    -- make sure we cast to right type, 
                    -- as XML are always defined as strings
                    local arg_type = type(self.model.args.args[arg_index].value)
                    if (arg_type == "number") then
                      preset[arg_name] = tonumber(v4.kids[1].value)
                    elseif (arg_type == "boolean") then
                      preset[arg_name] = (v4.kids[1].value == "true") and true or false
                    else 
                      preset[arg_name] = v4.kids[1].value
                    end
                  end
                end
              end
              table.insert(self.presets,preset)
              table.insert(self.preset_names,preset_name)
              self.presets_observable:insert(k3)
              last_inserted_preset_index = k3
            end
          end
        end
      end
    end
  end

  self.selected_preset_index = last_inserted_preset_index
  self.modified = true

  return true

end

---------------------------------------------------------------------------------------------------

function xStreamPresets:path_to_xml(str_name)
  TRACE("xStreamPresets:path_to_xml(str_name)",str_name)
  assert(type(str_name)=="string")
  return ("%s/%s.xml"):format(self:path_to_xml_folder(),str_name)
end

---------------------------------------------------------------------------------------------------

function xStreamPresets:path_to_xml_folder()
  TRACE("xStreamPresets:path_to_xml_folder()")
  local preset_bank_folder = xStreamPresets.get_preset_bank_path()
  return ("%s%s"):format(preset_bank_folder,self.model.name)
end

---------------------------------------------------------------------------------------------------
-- auto-saving of external preset banks to a predefined location
-- @return bool, true when saved
-- @return string, error message when failed

function xStreamPresets:save()
  TRACE("xStreamPresets:save()")

  if (self.name == xStreamPresets.DEFAULT_BANK_NAME) then
    return
  end

  local file_path = self:path_to_xml(self.name)

  local success,err = cFilesystem.makedir(file_path)
  if not success then
    return false,err
  end

  return self:export(file_path)

end

---------------------------------------------------------------------------------------------------
-- export all presets
-- @param file_path (string), provide a name (prompt user if not defined)
-- @return bool, true when export was successful

function xStreamPresets:export(file_path)
  TRACE("xStreamPresets:export(file_path)",file_path)

  if not file_path then
    local ext = "xml"
    local title = "Export all presets"
    file_path = renoise.app():prompt_for_filename_to_write(ext,title)
    if (file_path == "") then
      return true
    end
  end

  -- create XML document
  local doc = renoise.Document.create("xStreamPresets"){}
	local doc_list = renoise.Document.DocumentList()
  doc:add_property("Presets",doc_list)

  for k,v in ipairs(self.presets) do
    local node = renoise.Document.create("xStreamPreset"){}
    for k2,v2 in pairs(v) do
      --print("add_property",k2,v2)
      local safe_name = xStreamPresets.store_xml_arg_name(k2)
      --print(">>> safe_name",safe_name)
      node:add_property(safe_name,v2)
    end
    --print("add name property",self.preset_names[k])
    node:add_property("name",self.preset_names[k] or "")
    doc_list:insert(#doc_list+1,node)
  end

  local success,err = doc:save_as(file_path)
  if not success then
    return false,err
  end 

  return true

end

---------------------------------------------------------------------------------------------------
-- remove our xml file 

function xStreamPresets:remove_xml()

  if (self.name == xStreamPresets.DEFAULT_BANK_NAME) then
    return
  end

  local file_path = self:path_to_xml(self.name)
  if io.exists(file_path) then
    local success,err = os.remove(file_path)
    if not success then
      LOG("Failed to remove preset bank: "..err)
    end
  end

end

---------------------------------------------------------------------------------------------------
-- [Static] Function to make argument names safe for XML 
-- (they can contain dots)

function xStreamPresets.store_xml_arg_name(val)
  return val:gsub("%p","_dot_")
end

---------------------------------------------------------------------------------------------------
-- [Static] Function to load 'safe' argument name from XML

function xStreamPresets.parse_xml_arg_name(val)
  return val:gsub("_dot_",".")
end

---------------------------------------------------------------------------------------------------
-- [Static] Retrieve root path for preset banks 

function xStreamPresets.get_preset_bank_path()
  return xStreamUserData.USERDATA_ROOT..xStreamUserData.PRESET_BANK_FOLDER
end

