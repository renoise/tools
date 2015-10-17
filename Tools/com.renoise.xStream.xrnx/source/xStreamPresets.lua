--[[============================================================================
xStreamPresets
============================================================================]]--
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


class 'xStreamPresets'

xStreamPresets.DEFAULT_BANK_NAME = "Default"

-------------------------------------------------------------------------------

function xStreamPresets:__init(model)

  -- xStreamPresets, owner
  self.model = model

  -- table<table>, the actual entries
	self.presets = {}

  -- string, name of this preset bank (needs to be valid filename)
	self.name = property(self.get_name,self.set_name)
  self.name_observable = renoise.Document.ObservableString(xStreamPresets.DEFAULT_BANK_NAME)

  -- DocumentObservableBoolean, fires when eligible for export
  -- (emulates a 'bang' - implemented as an ever-increasing integer value)
  self.modified = property(self.get_modified,self.set_modified)
  self.modified_observable = renoise.Document.ObservableNumber(0)

  -- ObservableNumberList, notifier fired when items are added/removed 
  self.presets_observable = renoise.Document.ObservableNumberList()

  -- int, active preset (0 when none is active)
  self.selected_preset_index = property(
    self.get_selected_preset_index,self.set_selected_preset_index)
  self.selected_preset_index_observable = renoise.Document.ObservableNumber(0)


end

-------------------------------------------------------------------------------
-- Get/set methods
-------------------------------------------------------------------------------

function xStreamPresets:get_name()
  return self.name_observable.value
end

function xStreamPresets:set_name(val)
  self.name_observable.value = val
end

-------------------------------------------------------------------------------

function xStreamPresets:get_modified()
  return self.modified_observable.value
end

function xStreamPresets:set_modified()
  self.modified_observable.value = self.modified_observable.value + 1
end

-------------------------------------------------------------------------------

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


-------------------------------------------------------------------------------
-- add current/supplied values as new preset 
-- @param t (table) use these values 

function xStreamPresets:add_preset(t)
  TRACE("xStreamPresets:add_preset(t)",t)

  local preset = {}
  if not t then
    for _,arg in ipairs(self.model.args.args) do
      preset[arg.name] = arg.observable.value
    end
  else
    for k,v in pairs(t) do
      preset[k] = v
    end
  end

  table.insert(self.presets,preset)
  self.presets_observable:insert(#self.presets)

  self.modified = true

end

-------------------------------------------------------------------------------

function xStreamPresets:remove_all_presets()
  TRACE("xStreamPresets:remove_all_presets()")

  for k,v in ripairs(self.presets) do
    self:remove_preset(k)
  end

end

-------------------------------------------------------------------------------
-- @param idx (int)

function xStreamPresets:remove_preset(idx)
  TRACE("xStreamPresets:remove_preset(idx)",idx)

  local preset = self.presets[idx]
  if not preset then
    LOG(("Could not remove preset with index #%d- it doesn't exist"):format(idx))
    return
  end

  table.remove(self.presets,idx)
  self.presets_observable:remove(idx)

  -- remove from favorites
  self.model.xstream.favorites:remove_by_name_index(self.model.name,idx,self.name)

  if (idx == self.selected_preset_index) then
    self.selected_preset_index = 0
  elseif (idx < self.selected_preset_index) then
    self.selected_preset_index = self.selected_preset_index - 1   
  end

  self.modified = true

end

-------------------------------------------------------------------------------
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
    preset[arg.name] = arg.value
  end

  --rprint(preset)
  self.modified = true

end


-------------------------------------------------------------------------------
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
    if type(preset[arg.name]) ~= "nil" then
      if not arg.locked then
        --print("recalling value - preset[arg.name].value",arg.name,preset[arg.name])
        arg.value = preset[arg.name]
        arg.observable.value = preset[arg.name]
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

-------------------------------------------------------------------------------
-- rename this preset bank (also applies to preset folder, if it exists)
-- @return bool, true when succeeded or user aborted, false when failed
-- @return string, error message when failed

function xStreamPresets:rename(str_name)
  TRACE("xStreamPresets:rename(str_name)",str_name)

  if not str_name then
    str_name = xDialog.prompt_for_string(self.name,
      "Enter a new name","Rename Preset Bank")
    if not str_name then
      return true
    end
  end

  if not xFilesystem.validate_filename(str_name) then
    return false,"Please avoid using special characters in the name"
  end

  local str_from = self:path_to_xml(self.name)
  if (self.name ~= xStreamPresets.DEFAULT_BANK_NAME) then
    local str_to = self:path_to_xml(str_name)
    if io.exists(str_from) then
      if io.exists(str_to) then
        return false, "Warning: a preset folder with the given name already exists: "..str_to
      end
      local success,err = os.move(str_from,str_to)
      if not success then
        return false, "Error during preset-bank rename: "..err
      end
    end
  end

  local old_name = self.name
  self.name = str_name

  -- favorites might be affected
  local preset_bank_name = self.model.selected_preset_bank.name
  local favorites = self.model.xstream.favorites:get_by_preset_bank(old_name)
  if (#favorites > 0) then
    for k,v in ipairs(favorites) do
      self.model.xstream.favorites.items[v].preset_bank_name = self.name
    end
    self.model.xstream.favorites.update_buttons_requested = true
    self.model.xstream.favorites.modified = true
  end

  return true

end


-------------------------------------------------------------------------------
-- import presets from xml file, preserving existing presets

function xStreamPresets:merge()
  
  local clear_existing = false
  self:import(clear_existing)

end

-------------------------------------------------------------------------------
-- import all presets from xml file
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

  local success,rslt = xParseXML.parse(str_xml)
  if not success then
    return false, rslt
  end
  --print("rslt",rprint(rslt))

  if clear_existing then
    for i = #self.presets,1,-1 do
      self:remove_preset(i)
    end
  end

  local last_inserted_preset_index = 0

  local arg_names = {}
  for _,arg in ipairs(self.model.args.args) do
    table.insert(arg_names,arg.name)
  end
  --print("arg_names",rprint(arg_names))

  for _,v in ipairs(rslt) do
    if (v.label == "xStreamPresets") then
      for __,v2 in ipairs(v) do
        --print("v2",v2)
        if (v2.label == "Presets") then
          for k3,v3 in ipairs(v2) do
            --print("v3",v3)
            if (v3.label == "Preset") then
              local preset = {}
              for ____,v4 in ipairs(v3) do
                --print("v4",v4)
                local arg_index = table.find(arg_names,v4.label)
                if arg_index then
                  -- make sure we cast to right type, 
                  -- as XML are always defined as strings
                  local arg_type = type(self.model.args.args[arg_index].value)
                  if (arg_type == "number") then
                    preset[v4.label] = tonumber(v4[1])
                  elseif (arg_type == "boolean") then
                    preset[v4.label] = (v4[1] == "true") and true or false
                  else 
                    preset[v4.label] = v4[1]
                  end
                else
                  --print("*** reject - ",v4.label)
                end
              end
              table.insert(self.presets,preset)
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

-------------------------------------------------------------------------------

function xStreamPresets:path_to_xml(str_name)
  TRACE("xStreamPresets:path_to_xml(str_name)",str_name)
  assert(type(str_name)=="string")
  return ("%s/%s.xml"):format(self:path_to_xml_folder(),str_name)
end

-------------------------------------------------------------------------------

function xStreamPresets:path_to_xml_folder()
  return ("%s%s"):format(xStream.PRESET_BANK_FOLDER,self.model.name)
end

-------------------------------------------------------------------------------
-- auto-saving of external preset banks to a predefined location
-- @return bool, true when saved
-- @return string, error message when failed

function xStreamPresets:save()

  if (self.name == xStreamPresets.DEFAULT_BANK_NAME) then
    return
  end

  --local model_name = self.model.name
  --local file_path = ("%s%s/%s.xml"):format(xStream.PRESET_BANK_FOLDER,model_name,self.name)
  local file_path = self:path_to_xml(self.name)

  local success,err = xFilesystem.makedir(file_path)
  if not success then
    return false,err
  end

  return self:export(file_path)

end

-------------------------------------------------------------------------------
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
      node:add_property(k2,v2)
    end
    doc_list:insert(#doc_list+1,node)
  end

  local success,err = doc:save_as(file_path)
  if not success then
    return false,err
  end 

  return true

end

-------------------------------------------------------------------------------
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



