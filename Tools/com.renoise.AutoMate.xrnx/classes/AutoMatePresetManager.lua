--[[===============================================================================================
-- AutoMatePresetManager.lua
===============================================================================================]]--

--[[--

Manage instances of AutoMatePreset 

--]]

--=================================================================================================

class 'AutoMatePresetManager'

---------------------------------------------------------------------------------------------------

function AutoMatePresetManager:__init()
  TRACE("AutoMatePresetManager:__init()")

  --- table<object>
  self.presets = property(self._get_presets,self._set_presets)
  self._presets = {}
  self.presets_observable = renoise.Document.ObservableBang()

  --- object or nil 
  self.selected_preset = property(self._get_selected_preset)
  self._selected_preset = nil
  self.selected_preset_observable = renoise.Document.ObservableBang()

  --- string, name of currently selected preset or nil
  self.selected_preset_name = property(self._get_selected_preset_name,self._set_selected_preset_name)
  self._selected_preset_name = nil
  

end

--=================================================================================================
-- Getters and Setters
--=================================================================================================

function AutoMatePresetManager:_get_presets()
  return self._presets
end  

function AutoMatePresetManager:_set_presets(presets)
  assert(type(presets)=="table")
  self._presets = presets
  self.presets_observable:bang()
end  

---------------------------------------------------------------------------------------------------

function AutoMatePresetManager:_get_selected_preset()
  return self:get_preset_by_name(self.selected_preset_name)
end  

---------------------------------------------------------------------------------------------------

function AutoMatePresetManager:_get_selected_preset_name()
  return self._selected_preset_name
end  

function AutoMatePresetManager:_set_selected_preset_name(name)
  if (name ~= self._selected_preset_name) then 
    local preset = self:get_preset_by_name(name)
    self._selected_preset = preset
    self._selected_preset_name = name
    self.selected_preset_observable:bang()
  end
end  

--=================================================================================================
-- Class methods
--=================================================================================================
-- @param preset (object)

function AutoMatePresetManager:add_preset(preset)
  TRACE("AutoMatePresetManager:add_preset(preset)",preset)
  
  -- ensure a unique name 
  local folder = self:get_path()
  local unique_path = cFilesystem.ensure_unique_filename(folder..preset.name..".lua")
  preset.name = cFilesystem.get_raw_filename(unique_path)

  preset:save(unique_path)

  table.insert(self._presets,preset)
  self.presets_observable:bang()
  
end

---------------------------------------------------------------------------------------------------
-- specify where to load files from 

function AutoMatePresetManager:get_path()
  TRACE("AutoMatePresetManager:get_path()")

  error("override this with your own implementation")

end

---------------------------------------------------------------------------------------------------
-- @param fpath (string), path to preset file 
-- @return object or nil 
-- @return string, error when failed 

function AutoMatePresetManager:load_preset(fpath)
  TRACE("AutoMatePresetManager:load_preset(fpath)",fpath)

  -- attempt to determine/instantiate preset class 
  local cname = cPersistence.determine_type(fpath)
  if not cname then 
    return false, "Could not determine preset type"
  end
  if not rawget(_G,cname) then 
    return false, ("Could not instantiate preset: unknown class '%s'"):format(cname)
  end 
  
  local preset = _G[cname]()
  local success,err = preset:load(fpath)
  if not success and err then 
    return nil, err
  end

  -- NB: this can spawn a prompt!
  local succes,err = self:resolve_name_conflict(fpath)
  if err then 
    LOG(err)
  end

  return preset

end

---------------------------------------------------------------------------------------------------
-- (re-)load all available presets 

function AutoMatePresetManager:load_presets()
  TRACE("AutoMatePresetManager:load_presets()")

  self:remove_all_presets()

  local folder = self:get_path()
  local include_path = true
  local file_ext = {"*.lua"}

  local file_paths = cFilesystem.list_files(folder,file_ext,include_path)
  --print("file_paths",rprint(file_paths))

  for _,v in ipairs(file_paths) do
    local preset,err = self:load_preset(v)
    if not preset and err then 
      renoise.app():show_warning(err)
    else
      table.insert(self._presets,preset)
    end
  end
  self.presets_observable:bang()

end

---------------------------------------------------------------------------------------------------
-- @param names (<string>)

function AutoMatePresetManager:remove_presets(names)
  TRACE("AutoMatePresetManager:remove_presets(names)",names)

  for k,v in ipairs(names) do 
    local matched = false
    for k2,v2 in ipairs(self._presets) do 
      if (v == v2.name) then 
        matched = true
        break
      end
    end
    if matched then 
      local folder = self:get_path()
      local fpath = ("%s%s.lua"):format(folder,v)
      --print("delete from disk",fpath)
      os.remove(fpath)
    end
  end

  self:load_presets()

end

---------------------------------------------------------------------------------------------------

function AutoMatePresetManager:remove_all_presets()
  TRACE("AutoMatePresetManager:remove_all_presets()")

  self._presets = {}
  self.presets_observable:bang()

end

---------------------------------------------------------------------------------------------------
-- @param name (string)
-- @return object,number or nil

function AutoMatePresetManager:get_preset_by_name(name)
  TRACE("AutoMatePresetManager:get_preset_by_name(name)",name)

  for k,v in ipairs(self._presets) do 
    if (v.name == name) then 
      return v,k
    end
  end

end

---------------------------------------------------------------------------------------------------
-- enforce synchronicity between 'internal' name and filename
-- (call this after loading a preset, but before adding it)
-- @param fpath (string)
-- @return boolean, true when no conflict or conflict was resolved
-- @return string, error message when failed 

function AutoMatePresetManager:resolve_name_conflict(fpath)
  TRACE("AutoMatePresetManager:resolve_name_conflict(fpath)",fpath)
  
  local filename = cFilesystem.get_raw_filename(fpath)
  --print("filename",filename)
  local preset = self:get_preset_by_name(filename)
  
  if preset and (preset.name ~= filename) then 
    local title = "AutoMate : Name conflict"
    local message = ("A problem occurred while importing a library preset:"
                  .."\nit needs to have the same name as the file - "
                  .."\n "
                  .."\nThe preset is named '%s'"
                  .."\nBut the file is stored as '%s'"
                  .."\n "
                  .."\nPress OK to fix the problem, or Cancel to skip"
                  ):format(preset.name,filename)
    local choice = renoise.app():show_prompt(title, message,{"OK","Cancel"})
    if (choice == "OK") then 
      -- assign the filename as name and update/save it 
      preset.name = cFilesystem.get_raw_filename(fpath)
      local success,err = preset:save(fpath)
      if not success and err then 
        return nil,err
      end
    else -- Cancel
      return 
    end
  end

  return true

end  

---------------------------------------------------------------------------------------------------
-- rename the preset 

function AutoMatePresetManager:rename_preset(old_name,new_name)
  TRACE("AutoMatePresetManager:rename_preset(old_name,new_name)",old_name,new_name)

  local preset = self:get_preset_by_name(name)
  if not preset then 
    return false,"Could not find the specified preset"
  end    
  
  local old_name = preset.name
  preset.name = new_name
  
  local library_path = AutoMateLibrary.get_path()
  local old_fpath = ("%s%s.lua"):format(library_path,old_name)
  local new_fpath = ("%s%s.lua"):format(library_path,new_name)

  -- rename the existing preset 
  local success,err = os.rename(old_fpath,new_fpath) 
  if not success then 
    return false,err
  end
  
  -- replace old preset with the new one 
  local success,err = preset:save(new_fpath)
  if not success then 
    return false,err
  end

  return true

end

