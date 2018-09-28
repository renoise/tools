
class "App" 

---------------------------------------------------------------------------------------------------

function App:__init(...)
  TRACE("App:__init(...)",...)
    
  local args = cLib.unpack_args(...)
  
  self.tool_name = args.tool_name
  self.tool_version = args.tool_version
  
  self.monitor_active = property(self.get_monitor_active,self.set_monitor_active)
  self.monitor_active_observable = renoise.Document.ObservableBoolean(true)  
  
  -- fire when selection has changed 
  self.selection_in_sononym_observable = renoise.Document.ObservableBang()

  -- true while live transfer is enabled
  self.live_transfer_observable = renoise.Document.ObservableBoolean(false)  

    -- table, selectedFile entry from sononym configuration 
  --  {
  --    filename (string)
  --    locationPath (string)
  --  }
  self.selection_in_sononym = {}

  -- AppPrefs
  self.prefs = args.prefs
  
  -- cFileMonitor, enable when establishing monitoring 
  self.filemon = cFileMonitor{
    polling_interval = self.prefs.polling_interval.value,
  }
  
  --- configure user-interface
  self.ui = AppUI{
    dialog_title = self.app_display_name,
    owner = self,
    waiting_to_show_dialog = args.waiting_to_show_dialog,
  }
  
  -- notifications ------------------------------
  
  self.filemon.changed_observable:add_notifier(function()
    TRACE("*** filemon.changed_observable fired...")
    
    local selection = App.parse_config(self.prefs.path_to_config.value)
    if selection then 
      self.selection_in_sononym = selection
      self.selection_in_sononym_observable:bang()
      if self.live_transfer_observable.value then 
        local success,err = self:do_transfer()
        if not success then 
          LOG(err)
          return 
        end
        self.ui.update_requested = true
      end
    end
  end)
  
  self.prefs.polling_interval:add_notifier(function()
    self.filemon.polling_interval = self.prefs.polling_interval.value
  end)
  
  self.monitor_active_observable:add_notifier(function()
    --self.prefs.monitor_active.value = self.monitor_active_observable.value
    print(">>> self.monitor_active_observable.value",self.monitor_active_observable.value)
  end)
  
  self.live_transfer_observable:add_notifier(function()
    if self.live_transfer_observable.value then 
      local success,err = self:do_transfer()
      if not success then 
        LOG(err)
      end      
    end
  end)
  
  -- initialize 

  local success,err = self:start_monitoring()
  if not success and err then 
    LOG(err)
  end
  
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

function App:get_monitor_active()
  return self.monitor_active_observable.value
end

function App:set_monitor_active(val)
  self.monitor_active_observable.value = val
end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------
-- @return boolean, false when preconditions failed 

function App:toggle_monitoring()
  TRACE("App:toggle_monitoring()")
  
  if not self.monitor_active then 
    return self:start_monitoring()
  else 
    return self:stop_monitoring()
  end 
  
end

---------------------------------------------------------------------------------------------------
-- start monitoring 
-- @return boolean, false when preconditions failed 

function App:start_monitoring()
  -- check if we can monitor
  local success,err = self:can_monitor()
  if not success then 
    return false,err
  end 
  self.filemon.paths = {
    --self.prefs.path_to_exe.value,
    self.prefs.path_to_config.value,
  }    
  self.filemon:start()
  self.monitor_active = true
  return true

end  

---------------------------------------------------------------------------------------------------
-- stop monitoring 
-- @return boolean, false when preconditions failed 

function App:stop_monitoring()
  self.filemon:stop()
  self.monitor_active = false
  return true
end  

---------------------------------------------------------------------------------------------------
-- enable/disable live transfer (Sononym to Renoise)
-- @return boolean, false when preconditions failed 

function App:toggle_live_transfer()

  local success,err = self:can_monitor()
  if not success then 
    return false,err
  end 
  
  if not self.live_transfer_observable.value 
    and self.prefs.show_transfer_warning.value 
  then 
    local choice = renoise.app():show_prompt("Enable auto-transfer?",""
      .."Warning: auto-transfer will automatically replace the selected sample - "
      .."\nare you sure you want to enable this feature?",
      {"Ok","Always (don't show warning)","Cancel"})
    if (choice == "Cancel") then 
      return false
    elseif (choice == "Always (don't show warning)") then 
      self.prefs.show_transfer_warning.value = false
    end
  end
  
  self.live_transfer_observable.value = not self.live_transfer_observable.value
  
  return true
  
end

---------------------------------------------------------------------------------------------------
-- @return boolean, string (error message)

function App:can_monitor()
  --TRACE("App:can_monitor()")

  if not self.prefs.path_to_exe.value or (self.prefs.path_to_exe.value == "") then 
    return false, "Path to executable is not defined"
  end
  
  if not self.prefs.path_to_config.value or (self.prefs.path_to_config.value == "") then 
    return false, "Path to configuration is not defined"
  end
  
  return true 
  
end


---------------------------------------------------------------------------------------------------
-- guess paths (invoked when showing GUI without proper configuration)

function App:autoconfigure()
  print("App:autoconfigure()")
  
  local str = self:guess_path_to_config()
  print(str)
  
  error("***")

  self:set_path_to_exe(App.guess_path_to_exe())
  self:set_path_to_config(self:guess_path_to_config())

end

---------------------------------------------------------------------------------------------------

function App:pick_path_to_exe()
  TRACE("App:pick_path_to_exe()")

  local platform = os.platform()
  local suggested_path = nil
  local ext = {"*.*"}
  if (platform == "WINDOWS") then 
    ext = {"Sononym.exe"}
  elseif (platform == "MACINTOSH") then 
    --ext = {"Sononym"}
  elseif (platform == "LINUX") then
  end 

  local title = "Choose location of Sononym executable"
  local file_path = renoise.app():prompt_for_filename_to_read(ext,title)
  if (file_path == "") then
    return 
  end

  self:set_path_to_exe(file_path)
  
end

---------------------------------------------------------------------------------------------------

function App:set_path_to_exe(file_path)
  print("App:set_path_to_exe(file_path)",file_path)

  file_path = cFilesystem.unixslashes(file_path)
  local success,err = App.check_path(file_path)
  if not success then 
    return false,err
  end
  self.prefs.path_to_exe.value = file_path
end

---------------------------------------------------------------------------------------------------
-- perform an educated guess as to where query.json can be found

function App:guess_path_to_config()
  print("App:guess_path_to_config()")

  local platform = os.platform()
  if (platform == "WINDOWS") then 
    return cFilesystem.get_user_folder() .. "AppData/Roaming/Sononym/query.json"
  elseif (platform == "MACINTOSH") then 
    return cFilesystem.get_user_folder() .. "Library/Application Support/Sononym/query.json"
  elseif (platform == "LINUX") then 
    error("not implemented")
  end 


end

---------------------------------------------------------------------------------------------------

function App:pick_path_to_config()
  TRACE("App:pick_path_to_config()")

  local ext = {"query.json"}
  local title = "Choose location of Sononym configuration"
  local file_path = renoise.app():prompt_for_filename_to_read(ext,title)
  if (file_path == "") then
    return 
  end

  self:set_path_to_config(file_path)

end

---------------------------------------------------------------------------------------------------

function App:set_path_to_config(file_path)
  print("App:set_path_to_config(file_path)",file_path)

  file_path = cFilesystem.unixslashes(file_path)
  local success,err = App.check_path(file_path)
  if not success then 
    return false,err
  end
  self.prefs.path_to_config.value = file_path
  -- immediately start monitoring
  local success,err = self:start_monitoring()
  if not success and err then 
    LOG(err)
  end

end


---------------------------------------------------------------------------------------------------
-- apply the currently selected file in Sononym to the selection in Renoise 
-- TODO replace *selected range* in sample 

function App:do_transfer()
  TRACE("App:do_transfer()")

  -- if any of these are true, instrument gets name of sample 
  local created_instrument = false 
  local instr_named_after_sample = false 
  
  local sample,instr = rns.selected_sample,rns.selected_instrument 
  if not sample then     
    sample = instr:insert_sample_at(1)
    created_instrument = true
  else 
    if (sample.name == instr.name) then 
      instr_named_after_sample = true 
    end
  end
    
  if table.is_empty(self.selection_in_sononym) then 
    return false,"Please define a valid path to the Sononym configuration"
      .. "\n(see tool preferences)"
  end
  
  -- combine filename + locationPath 
  local config_folder,_,__ = cFilesystem.get_path_parts(self.prefs.path_to_config.value)
  local folder,_,__ = cFilesystem.get_path_parts(self.selection_in_sononym.locationPath)
  if (folder == config_folder) then 
    -- internal sononym library means filename is absolute
    folder = ""
  end
  local fpath = string.format("%s%s",folder,self.selection_in_sononym.filename)
  
  local success = sample.sample_buffer:load_from(fpath)
  if not success then 
    return false,"Failed to load sample"
  end
  
  -- update samplename  
  local folder,filename,ext = cFilesystem.get_path_parts(self.selection_in_sononym.filename)
  sample.name = filename
  
  if created_instrument or instr_named_after_sample then 
    instr.name = filename
  end
  
  -- display message in status bar / terminal
  local msg = "Transferred sample: "..fpath
  renoise.app():show_status(msg)
  LOG(msg)
  
  return true
  
end

---------------------------------------------------------------------------------------------------
-- save the selected sample and launch a similarity search 
-- TODO option to save only the *selected range* 
-- @return boolean, true or false,string when failed 

function App:do_search()
  print("App:do_search()")
  
  local success,err = App.check_path(self.prefs.path_to_exe.value)
  if not success then 
    return false,"Please define a valid path to the Sononym executable" 
      .."\n(see tool preferences)"
  end
  
  local tmp_path,err = self:_create_temp()
  if not tmp_path then 
    return false,"Unable to launch search: " .. err 
  end
   
  local path_to_exe = cFilesystem.unixslashes(self.prefs.path_to_exe.value)
  local cmd = string.format('"%s" %s',path_to_exe,cFilesystem.unixslashes(tmp_path))
  local code = os.execute(cmd)
  
  return true
  
end

---------------------------------------------------------------------------------------------------
-- save a copy of the selected sample to the temporary folder
-- @return string, temp filename or nil,string if failed 

function App:_create_temp()

  if not rns.selected_sample then 
    return nil,"No sample is selected"
  end
  
  local buffer = xSample.get_sample_buffer(rns.selected_sample)   
  if not buffer then 
    return nil,"Sample is empty"
  end
  local tmp_path = os.tmpname("flac")
  local success = buffer:save_as(tmp_path,"flac")
  if not success then 
    return nil,"Failed to save sample"
  end
  return tmp_path
end
  

---------------------------------------------------------------------------------------------------

function App:detach_sampler()
  TRACE("App:detach_sampler()")

  local enum_sampler = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
  local middle_frame = renoise.app().window.active_middle_frame
  renoise.app().window.instrument_editor_is_detached = true
  renoise.app().window.active_middle_frame = enum_sampler
  renoise.app().window.active_middle_frame = middle_frame

end

---------------------------------------------------------------------------------------------------
-- Static methods
---------------------------------------------------------------------------------------------------
-- Parse sononym configuration file (query.json) to find currently selected path 
-- @param path (string)
-- @return table {
--  filename (string) 
--  locationPath (string) 
--} 
-- or nil,error message (string) 

function App.parse_config(path)
  TRACE("App.parse_config(path)")

  -- return error if no path is supplied 
  if not path or (path == "") then 
    return nil,"No path is supplied"
  end
  
  -- load the config file 
  local fhandle = io.open(path,"r")
  if not fhandle then
    fhandle:close()
    return nil, "ERROR: Failed to open file handle"
  end

  local str_json = fhandle:read("*a")
  fhandle:close()  
  
  -- parse the string 
  local first,last = nil,nil
  local offset = string.find(str_json,'"selectedFile"')
  str_json = string.sub(str_json,offset)
  
  first,last = string.find(str_json,'"filename":%C*')
  local filename = cFilesystem.unixslashes(string.sub(str_json,first+13,last-2))
  
  first,last = string.find(str_json,'"locationPath":%C*')
  local locationPath = cFilesystem.unixslashes(string.sub(str_json,first+17,last-1))
  
  return {
    filename = filename,
    locationPath = locationPath,
  }
  
end

---------------------------------------------------------------------------------------------------
-- check if path is valid and existing 
-- @return boolean 

function App.check_path(str_path)
  print("App.check_path(str_path)",str_path)
  
  if not str_path or (str_path == "") then 
    return false,"No path specified"
  end 
  
  if not io.exists(str_path) then
    return false,"Path does not exist"
  end
  
  return true 
  
end

---------------------------------------------------------------------------------------------------

function App.guess_path_to_exe()
  print("App.guess_path_to_exe()")

  local platform = os.platform()
  if (platform == "WINDOWS") then 
    error("not implemented")
  elseif (platform == "MACINTOSH") then 
    return "/Applications/Sononym.app/Contents/MacOS/Sononym"
  elseif (platform == "LINUX") then 
    error("not implemented")
  end   

end

