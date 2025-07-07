class "App" 
---------------------------------------------------------------------------------------------------
function App:__init(...)
  TRACE("App:__init(...)",...)
    
  local args = cLib.unpack_args(...)
  
  self.tool_name = args.tool_name
  self.tool_version = args.tool_version
  self.app_display_name = "Sononymph - Paketti Modifications v" .. self.tool_version
  
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

  -- 
  self.paths_are_valid = property(self.get_paths_are_valid)
  self.paths_are_valid_observable = renoise.Document.ObservableBoolean(false)
  
  self.invalid_path_observable = renoise.Document.ObservableString("")
  
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
        renoise.app().window.active_middle_frame=5
      end
    end
  end)
  
  self.prefs.polling_interval:add_notifier(function()
    self.filemon.polling_interval = self.prefs.polling_interval.value
  end)
  
  self.live_transfer_observable:add_notifier(function()
    if self.live_transfer_observable.value then 
      local success,err = self:do_transfer()
      if not success then 
        LOG(err)
      end      
    end
  end)
  
  self.prefs.path_to_exe:add_notifier(function()
    self:check_paths()
  end)
  self.prefs.path_to_config:add_notifier(function()
    self:check_paths()
  end)
  
  -- add notifier to refresh menu when monitor state changes
  self.monitor_active_observable:add_notifier(function()
    register_tool_menu() -- refresh the menu when monitoring state changes
  end)
  
  -- initialize 
  self:check_paths()

  local success,err = self:start_monitoring()
  if not success and err then 
    LOG(err)
  end
  
  
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

function App:get_paths_are_valid()
  return self.paths_are_valid_observable.value 
end

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
  TRACE("App:start_monitoring()")

  if not self.paths_are_valid then 
    TRACE("App:start_monitoring() - paths are not valid, cannot start monitoring")
    return false 
  end

  self.filemon.paths = {
    --self.prefs.path_to_exe.value,
    self.prefs.path_to_config.value,
  }
  -- Start monitoring the query.json file
  
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
  TRACE("App:toggle_live_transfer()")

  if not self.paths_are_valid then 
    return false 
  end
  
  if not self.live_transfer_observable.value 
    and self.prefs.show_transfer_warning.value 
  then 
--[[    local choice = renoise.app():show_prompt("Enable auto-transfer?",""
      .."Auto-transfer will automatically replace the selected sample - "
      .."\nare you sure you want to enable this feature?",
      {"Yes","Yes, and don't show this warning","Cancel"})
    if (choice == "Cancel") then 
      return false
    elseif (choice == "Always (don't show warning)") then ]]--
      self.prefs.show_transfer_warning.value = false
    
  end
  
  self.live_transfer_observable.value = not self.live_transfer_observable.value
  
  return true
  
end

---------------------------------------------------------------------------------------------------
-- check paths and update "paths_are_valid" with result

function App:check_paths()
  TRACE("App:check_paths()")

  local path = self.prefs.path_to_exe.value
  local success,err = App.check_path(path)
  if not success then 
    self.invalid_path_observable.value = path
    self.paths_are_valid_observable.value = false
    return
  end
  
  local path = self.prefs.path_to_config.value
  local success,err = App.check_path(path)
  if not success then 
    self.invalid_path_observable.value = path
    self.paths_are_valid_observable.value = false
    return
  end
  
  self.invalid_path_observable.value = ""
  self.paths_are_valid_observable.value = true
  
end


---------------------------------------------------------------------------------------------------
-- auto-configure tool (invoked when showing GUI without proper configuration)
-- @return boolean, true when 

function App:autoconfigure()
  TRACE("App:autoconfigure()")
  
  local exe_path = App.guess_path_to_exe()
  LOG("*** autoconfigure: detected exe path:", exe_path or "nil")
  local success,err = self:set_path_to_exe(exe_path)
  if not success then 
    LOG("*** autoconfigure: failed to set exe path:", err)
    
    -- Provide helpful error message for Linux
    local platform = os.platform()
    if (platform == "LINUX") then
      local helpful_err = "Sononym executable not found. Please:\n" ..
        "1. Install Sononym from https://www.sononym.net/\n" ..
        "2. Make sure 'sononym' is in your PATH\n" ..
        "3. Or manually set the AppPath to the Sononym executable location\n" ..
        "Original error: " .. (err or "Path does not exist")
      return false, helpful_err
    end
    
    return false,err 
  end 
  
  local config_path = App.guess_path_to_config()
  LOG("*** autoconfigure: detected config path:", config_path or "nil")
  if not config_path then
    LOG("*** autoconfigure: config path is nil - detection failed")
    
    -- Provide helpful error message for Linux
    local platform = os.platform()
    if (platform == "LINUX") then
      local helpful_err = "Sononym configuration directory not found. Please:\n" ..
        "1. Run Sononym at least once to create the configuration\n" ..
        "2. The config should be created at: ~/.config/Sononym/[version]/query.json\n" ..
        "3. Or manually set the ConfigPath to your query.json file location"
      return false, helpful_err
    else
      return false, "No Sononym configuration found - please run Sononym first"
    end
  end
  
  local success,err = self:set_path_to_config(config_path)
  if not success then 
    LOG("*** autoconfigure: failed to set config path:", err)
    return false,err 
  end 
  
  LOG("*** autoconfigure: success - config path set to:", config_path)
  return true

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
    ext = {"Sononym"}
  elseif (platform == "LINUX") then
  ext = {"sononym"}
  end 

  local title = "Choose the location of the Sononym app"
  local file_path = renoise.app():prompt_for_filename_to_read(ext,title)
  if (file_path == "") then
    return 
  end

  self:set_path_to_exe(file_path)
  
end

---------------------------------------------------------------------------------------------------

function App:set_path_to_exe(file_path)
  TRACE("App:set_path_to_exe(file_path)",file_path)

  file_path = cFilesystem.unixslashes(file_path)
  self.prefs.path_to_exe.value = file_path
  local success,err = App.check_path(file_path)
  if not success then 
    self:stop_monitoring()
    return false,err
  end
  return true
end

---------------------------------------------------------------------------------------------------

function App:pick_path_to_config()
  TRACE("App:pick_path_to_config()")

  local ext = {"query.json"}
  local title = "Choose the location of the Sononym configuration file"
  local file_path = renoise.app():prompt_for_filename_to_read(ext,title)
  if (file_path == "") then
    return 
  end

  self:set_path_to_config(file_path)

end

---------------------------------------------------------------------------------------------------

function App:set_path_to_config(file_path)
  TRACE("App:set_path_to_config(file_path)",file_path)

  file_path = cFilesystem.unixslashes(file_path)
  self.prefs.path_to_config.value = file_path  
  local success,err = App.check_path(file_path)
  if not success then 
    self:stop_monitoring()
    return false,err
  end
  -- immediately start monitoring
  local success,err = self:start_monitoring()
  if not success and err then 
    LOG(err)
    return false,err
  end
  return true

end


---------------------------------------------------------------------------------------------------
-- Helper function to copy sample settings (for slice-aware transfer)
function App:copy_sample_settings(source_sample, target_sample)
  if not source_sample or not target_sample then
    return false
  end
  
  -- Copy basic sample properties
  target_sample.transpose = source_sample.transpose
  target_sample.fine_tune = source_sample.fine_tune
  target_sample.volume = source_sample.volume
  target_sample.panning = source_sample.panning
  target_sample.beat_sync_enabled = source_sample.beat_sync_enabled
  target_sample.beat_sync_lines = source_sample.beat_sync_lines
  target_sample.beat_sync_mode = source_sample.beat_sync_mode
  target_sample.new_note_action = source_sample.new_note_action
  target_sample.oneshot = source_sample.oneshot
  target_sample.mute_group = source_sample.mute_group
  target_sample.autoseek = source_sample.autoseek
  target_sample.autofade = source_sample.autofade
  
  -- Copy loop settings
  target_sample.loop_mode = source_sample.loop_mode
  target_sample.loop_start = math.min(source_sample.loop_start, target_sample.sample_buffer.number_of_frames - 1)
  target_sample.loop_end = math.min(source_sample.loop_end, target_sample.sample_buffer.number_of_frames)
  
  return true
end

---------------------------------------------------------------------------------------------------
-- Helper function to copy slice settings (for slice-aware transfer)
function App:copy_slice_settings(source_slice, target_slice)
  if not source_slice or not target_slice then
    return false
  end
  
  target_slice.transpose = source_slice.transpose
  target_slice.fine_tune = source_slice.fine_tune
  target_slice.volume = source_slice.volume
  target_slice.panning = source_slice.panning
  target_slice.beat_sync_enabled = source_slice.beat_sync_enabled
  target_slice.beat_sync_lines = source_slice.beat_sync_lines
  target_slice.beat_sync_mode = source_slice.beat_sync_mode
  target_slice.new_note_action = source_slice.new_note_action
  target_slice.oneshot = source_slice.oneshot
  target_slice.mute_group = source_slice.mute_group
  target_slice.autoseek = source_slice.autoseek
  target_slice.autofade = source_slice.autofade
  
  return true
end

---------------------------------------------------------------------------------------------------
-- Slice-aware sample loading (preserves slice markers and settings)
function App:load_sample_with_slice_preservation(sample, fpath)
  TRACE("App:load_sample_with_slice_preservation()")
  
  -- Check if the current sample has slice markers
  if #sample.slice_markers == 0 then
    -- No slices, use normal loading
    TRACE("No slice markers found, using normal loading")
    return pcall(function()
      sample.sample_buffer:load_from(fpath)
    end)
  end
  
  TRACE("Found slice markers, using slice-aware loading")
  local original_instrument = rns.selected_instrument
  
  -- Save slice markers and sample settings
  local saved_markers = {}
  for _, marker in ipairs(sample.slice_markers) do
    table.insert(saved_markers, marker)
  end
  local saved_sample = sample
  
  -- Load the new sample
  local success, err = pcall(function()
    sample.sample_buffer:load_from(fpath)
  end)
  
  if not success then
    return false, err
  end
  
  -- Get the new sample length
  local new_sample = rns.selected_sample
  if not new_sample then
    return false, "Failed to get new sample after loading"
  end
  
  local new_sample_length = new_sample.sample_buffer.number_of_frames
  
  -- Filter markers to fit within the new sample length
  local valid_markers = {}
  for _, marker in ipairs(saved_markers) do
    if marker <= new_sample_length then
      table.insert(valid_markers, marker)
    end
  end
  
  -- Apply the valid slice markers
  if #valid_markers > 0 then
    new_sample.slice_markers = valid_markers
    
    -- Copy sample settings
    self:copy_sample_settings(saved_sample, new_sample)
    
    -- Copy slice settings for each individual slice sample
    for i = 2, math.min(#original_instrument.samples, #rns.selected_instrument.samples) do
      if original_instrument.samples[i] and rns.selected_instrument.samples[i] then
        self:copy_slice_settings(original_instrument.samples[i], rns.selected_instrument.samples[i])
      end
    end
    
    TRACE("Applied", #valid_markers, "slice markers and settings to new sample")
  else
    TRACE("No valid slice markers could be applied to new sample")
  end
  
  return true
end

---------------------------------------------------------------------------------------------------
-- apply the currently selected file in Sononym to the selection in Renoise 
function App:do_transfer()
  TRACE("App:do_transfer()")

  -- if any of these are true, instrument gets name of sample 
  local created_instrument = false 
  local instr_named_after_sample = false 


if self.prefs.autotransfercreateslot.value then
  renoise.song().selected_instrument:insert_sample_at(#renoise.song().selected_instrument.samples+1)
  renoise.song().selected_sample_index = #renoise.song().selected_instrument.samples
elseif self.prefs.autotransfercreatenew.value then
  renoise.song():insert_instrument_at(renoise.song().selected_instrument_index+1)
  renoise.song().selected_instrument_index = renoise.song().selected_instrument_index + 1
end
  
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
  
  local fpath
  if (folder == config_folder) then 
    -- internal sononym library means filename is relative to the library folder
    -- Remove 'sononym.db' from locationPath to get the base folder
    local library_base = string.gsub(self.selection_in_sononym.locationPath, "sononym%.db$", "")
    fpath = cFilesystem.unixslashes(library_base .. self.selection_in_sononym.filename)
  else
    -- external path, filename should be combined with folder
    fpath = cFilesystem.unixslashes(folder .. self.selection_in_sononym.filename)
  end
  
  TRACE("Constructed file path:", fpath)
  
  -- If the constructed path doesn't exist, try alternative constructions
  if not io.exists(fpath) then
    TRACE("Primary path doesn't exist, trying alternatives...")
    
    -- Try treating the filename as an absolute path
    local alt_path1 = cFilesystem.unixslashes(self.selection_in_sononym.filename)
    if io.exists(alt_path1) then
      TRACE("Found file using filename as absolute path:", alt_path1)
      fpath = alt_path1
    else
      -- Try combining with the directory containing sononym.db
      local alt_path2 = cFilesystem.unixslashes(folder .. "/" .. self.selection_in_sononym.filename)
      if io.exists(alt_path2) then
        TRACE("Found file using folder + filename with slash:", alt_path2)
        fpath = alt_path2
      else
        -- Try fuzzy directory matching
        local library_base = string.gsub(self.selection_in_sononym.locationPath, "sononym%.db$", "")
        if io.exists(library_base) then
          local dirs = os.dirnames(library_base)
          if dirs and #dirs > 0 then
            local target_dir = string.match(self.selection_in_sononym.filename, "([^/]+)")
            if target_dir then
              TRACE("Fuzzy matching for missing directory:", target_dir)
              for _, dir in ipairs(dirs) do
                -- Look for directories that contain "tesla" or similar patterns
                if string.find(string.lower(dir), "tesla") or 
                   string.find(string.lower(dir), string.lower(target_dir:sub(1, math.min(5, #target_dir)))) then
                  local remaining_path = string.match(self.selection_in_sononym.filename, "[^/]+/(.+)")
                  if remaining_path then
                    local candidate_path = cFilesystem.unixslashes(library_base .. dir .. "/" .. remaining_path)
                    TRACE("Testing fuzzy match:", candidate_path)
                    if io.exists(candidate_path) then
                      TRACE("*** FUZZY MATCH FOUND! Using:", candidate_path)
                      fpath = candidate_path
                      break
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  
  -- Check if the file exists before attempting to load
  if not io.exists(fpath) then
    TRACE("File not found at constructed path:", fpath)
    TRACE("Original filename:", self.selection_in_sononym.filename)
    TRACE("Original locationPath:", self.selection_in_sononym.locationPath)
    
    -- Debug: Check what's actually in the parent directory
    local parent_dir = string.match(fpath, "(.+)/[^/]+$")
    if parent_dir and io.exists(parent_dir) then
      TRACE("Parent directory exists:", parent_dir)
      local files = os.filenames(parent_dir, {"*.*"})
      if files and #files > 0 then
        TRACE("Files in parent directory:")
        for i, file in ipairs(files) do
          if i <= 10 then -- Show first 10 files
            TRACE("  -", file)
          end
        end
        if #files > 10 then
          TRACE("  ... and", #files - 10, "more files")
        end
      else
        TRACE("No files found in parent directory")
      end
      
      -- Check for directories
      local dirs = os.dirnames(parent_dir)
      if dirs and #dirs > 0 then
        TRACE("Subdirectories in parent:")
        for i, dir in ipairs(dirs) do
          if i <= 10 then -- Show first 10 directories
            TRACE("  -", dir)
          end
        end
      end
    else
      TRACE("Parent directory does not exist:", parent_dir or "nil")
      
      -- Check if the library base directory exists
      local library_base = string.gsub(self.selection_in_sononym.locationPath, "sononym%.db$", "")
             if io.exists(library_base) then
         TRACE("Library base directory exists:", library_base)
         local dirs = os.dirnames(library_base)
         if dirs and #dirs > 0 then
           TRACE("Directories in library base:")
           for i, dir in ipairs(dirs) do
             if i <= 10 then
               TRACE("  -", dir)
             end
           end
           
           -- Try to find directories that might match the missing one
           local target_dir = string.match(self.selection_in_sononym.filename, "([^/]+)")
           if target_dir then
             TRACE("Looking for directory similar to:", target_dir)
             local candidates = {}
             for _, dir in ipairs(dirs) do
               -- Case insensitive partial match
               if string.find(string.lower(dir), string.lower(target_dir:sub(1, 5))) or
                  string.find(string.lower(target_dir), string.lower(dir:sub(1, 5))) then
                 table.insert(candidates, dir)
               end
             end
             
             if #candidates > 0 then
               TRACE("Potential matching directories:")
               for _, candidate in ipairs(candidates) do
                 TRACE("  *", candidate)
                 -- Try this candidate
                 local candidate_path = cFilesystem.unixslashes(library_base .. candidate .. "/" .. string.match(self.selection_in_sononym.filename, "[^/]+/(.+)"))
                 TRACE("    Testing path:", candidate_path)
                 if io.exists(candidate_path) then
                   TRACE("    *** FOUND MATCH! Using:", candidate_path)
                   fpath = candidate_path
                   break
                 end
               end
             else
               TRACE("No similar directories found")
             end
           end
         end
       else
         TRACE("Library base directory does not exist:", library_base)
       end
    end
    
    return false,"File does not exist:\n" .. fpath
  end
  
  -- Use slice-aware loading to preserve slice markers and settings
  local success,err = pcall(function()
    return self:load_sample_with_slice_preservation(sample, fpath)
  end)
  
  if not success then 
    TRACE("Loading failed with error:", err)
    return false,"Failed to load sample:\n"..tostring(err)
  end
  
  if not err then
    TRACE("Loading failed - load_sample_with_slice_preservation returned false")
    return false,"Failed to load sample: unknown error"
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
  
  -- Force auto-transfer to kick you to sample editor view on middle frame
  if self.live_transfer_observable.value then
    renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
    TRACE("Auto-transfer: switched to Sample Editor view")
  end
  
  return true
  
end

---------------------------------------------------------------------------------------------------
-- save the selected sample and launch a similarity search 
-- TODO option to save only the *selected range* 
-- @return boolean, true or false,string when failed 

function App:do_search()
  TRACE("App:do_search()")
  
  -- check if there's a sample selected first
  if not rns.selected_sample then 
    renoise.app():show_status("There is no sample, doing nothing.")
    return false,"There is no sample selected, doing nothing."
  end
  
  -- show important notice the first time 
  if self.prefs.show_search_warning.value then 
    local choice = renoise.app():show_prompt("Important notice",""
      .."Please make sure that Sononym is running before launching a search"
      .."\n(NB: this message is only shown once!)"
      ,{"Start Search","Cancel"})
    if (choice == "Cancel") then 
      return false
    else
      self.prefs.show_search_warning.value = false
    end
  end
    
  local success,err = App.check_path(self.prefs.path_to_exe.value)
  if not success then 
    return false,"Please define a valid path to the Sononym executable" 
      .."\n(see AppPath in Options, use Detect or Browse.)"
  end
  
  local tmp_path,err = self:_create_temp()
  if not tmp_path then 
    return false,"Unable to Launch Search: " .. err 
  end
   
local path_to_exe=cFilesystem.unixslashes(self.prefs.path_to_exe.value)
local tmp_path=cFilesystem.unixslashes(tmp_path)


  local path_to_exe = cFilesystem.unixslashes(self.prefs.path_to_exe.value)
  local cmd = string.format('"%s" %s',path_to_exe,cFilesystem.unixslashes(tmp_path))
print (cmd)
  local code = os.execute(cmd .. " &")

return true
end

---------------------------------------------------------------------------------------------------
-- select a folder and launch Sononym to browse it
function App:do_browse()
  TRACE("App:do_browse()")
  
  local success,err = App.check_path(self.prefs.path_to_exe.value)
  if not success then 
    return false,"Please define a valid path to the Sononym executable" 
      .."\n(see AppPath in Options, use Detect or Browse.)"
  end
  
  -- Let user select a folder to browse
  local folder_path = renoise.app():prompt_for_path("Select Folder to Browse in Sononym")
  if folder_path == "" then
    return false -- User cancelled
  end
  
  local path_to_exe = cFilesystem.unixslashes(self.prefs.path_to_exe.value)
  local browse_path = cFilesystem.unixslashes(folder_path)
  
  -- Launch Sononym with the folder path to enter browse mode
  local cmd = string.format('"%s" "%s"', path_to_exe, browse_path)
  TRACE("Launching Sononym browse mode:", cmd)
  
  local success = pcall(function()
    os.execute(cmd)
  end)
  
  if success then
    renoise.app():show_status("Launched Sononym in browse mode for: " .. folder_path)
    return true
  else
    return false, "Failed to launch Sononym in browse mode"
  end
end

---------------------------------------------------------------------------------------------------
-- launch Sononym application

function App:launch_sononym()
  TRACE("App:launch_sononym()")
  
  local success,err = App.check_path(self.prefs.path_to_exe.value)
  if not success then 
    return false,"Please define a valid path to the Sononym executable" 
      .."\n(see AppPath in Options, use Detect or Browse.)"
  end
  
  local path_to_exe = cFilesystem.unixslashes(self.prefs.path_to_exe.value)
  local cmd = string.format('"%s"',path_to_exe)
  print("Launching Sononym: " .. cmd)
  local code = os.execute(cmd .. " &") -- run in background
  
  renoise.app():show_status("Sononym launched.")
  return true
end

---------------------------------------------------------------------------------------------------
-- save a copy of the selected sample to the temporary folder
-- @return string, temp filename or nil,string if failed 

function App:_create_temp()

  if not rns.selected_sample then 
    return nil,"No sample is selected."
  end
  
  local buffer = get_sample_buffer(rns.selected_sample)   
  if not buffer then 
    return nil,"Sample is empty."
  end
  local tmp_path = os.tmpname("flac")
  local success = buffer:save_as(tmp_path,"flac")
  if not success then 
    return nil,"Failed to save sample."
  end
  return tmp_path
end

---------------------------------------------------------------------------------------------------
function App:detach_sampler()
  TRACE("App:detach_sampler()")

  -- First, check if the middle frame is not 5, set it to 5
  if renoise.app().window.active_middle_frame ~= 5 then
    renoise.app().window.active_middle_frame = 5
     renoise.app().window.instrument_editor_is_detached = false
    renoise.app().window.active_middle_frame = 5
    return
  end

  -- If the middle frame is already 5, toggle the instrument editor detachment
  if renoise.app().window.instrument_editor_is_detached then
    -- Re-attach the instrument editor
   
  else
    -- Detach the instrument editor
    renoise.app().window.instrument_editor_is_detached = true
  end
end


---------------------------------------------------------------------------------------------------
-- Manual trigger for testing file monitoring (useful for debugging)
function App:test_config_parsing()
  TRACE("App:test_config_parsing() - manually parsing config file")
  
  -- First check if the file exists and show its modification time
  local config_path = self.prefs.path_to_config.value
  local file_stats = io.stat(config_path)
  if file_stats then
    TRACE("*** Config file exists, mtime:", file_stats.mtime)
  else
    TRACE("*** Config file does not exist!")
    return
  end
  
  local selection = App.parse_config(config_path)
  if selection then 
    TRACE("*** test parse - found selection:", selection.filename, selection.locationPath)
    TRACE("*** test parse - live transfer status:", self.live_transfer_observable.value)
    TRACE("*** test parse - monitor active:", self.monitor_active)
    self.selection_in_sononym = selection
    self.selection_in_sononym_observable:bang()
    if self.live_transfer_observable.value then 
      TRACE("*** test parse - live transfer enabled, transferring...")
      local success,err = self:do_transfer()
      if not success then 
        LOG("Test transfer failed:", err)
      else
        LOG("Test transfer succeeded")
      end
    else
      TRACE("*** test parse - live transfer disabled")
    end
  else
    TRACE("*** test parse - failed to parse config")
  end
end

---------------------------------------------------------------------------------------------------
-- Debug function to check what's in the query.json file
function App:debug_query_json()
  TRACE("App:debug_query_json() - showing current query.json content")
  
  local config_path = self.prefs.path_to_config.value
  if not config_path or config_path == "" then
    LOG("No config path set")
    return
  end
  
  local file_stats = io.stat(config_path)
  if not file_stats then
    LOG("Config file does not exist:", config_path)
    return
  end
  
  LOG("Config file mtime:", file_stats.mtime)
  
  -- Read and show the file content
  local file = io.open(config_path, "r")
  if file then
    local content = file:read("*all")
    file:close()
    LOG("Query.json content:")
    LOG(content)
    
    -- Try to parse it
    local selection = App.parse_config(config_path)
    if selection then
      LOG("Parsed selection:", selection.filename, selection.locationPath)
    else
      LOG("Failed to parse selection")
    end
  else
    LOG("Could not read config file")
  end
end

---------------------------------------------------------------------------------------------------
-- Debug detected Sononym versions
function App:debug_versions()
  TRACE("App:debug_versions()")
  
  local versions = App.find_sononym_versions()
  local base_path
  local debug_info = {}
  table.insert(debug_info, "=== Sononym Version Detection ===")
  table.insert(debug_info, "Found " .. #versions .. " version(s):")
  
  if #versions == 0 then
    table.insert(debug_info, "No Sononym versions detected")
    table.insert(debug_info, "Make sure Sononym is installed and has been run at least once")
  end
  
  local platform = os.platform()
  if (platform == "WINDOWS") then 
    base_path = cFilesystem.get_user_folder() .. "AppData/Roaming/Sononym/"
  elseif (platform == "MACINTOSH") then 
    base_path = cFilesystem.get_user_folder() .. "Library/Application Support/Sononym/"
  elseif (platform == "LINUX") then 
    base_path = cFilesystem.get_user_folder() .. ".config/Sononym/"
  end
  
  table.insert(debug_info, "Checked base path: " .. (base_path or "N/A"))
  if base_path then
    table.insert(debug_info, "Base path exists: " .. (io.exists(base_path) and "YES" or "NO"))
    
    if io.exists(base_path) then
      local dirs = os.dirnames(base_path)
      if dirs and #dirs > 0 then
        table.insert(debug_info, "Found " .. #dirs .. " subdirectories:")
        for _, dir in ipairs(dirs) do
          table.insert(debug_info, "  - " .. dir)
        end
      else
        table.insert(debug_info, "No subdirectories found in base path")
      end
    end
  end
  
  if #versions > 0 then
    table.insert(debug_info, "\nDetected versions:")
    for i, version_info in ipairs(versions) do
      table.insert(debug_info, "  " .. i .. ". Version " .. version_info.version)
      table.insert(debug_info, "     Path: " .. version_info.path)
      table.insert(debug_info, "     Exists: " .. (io.exists(version_info.path) and "YES" or "NO"))
      
      if io.exists(version_info.path) then
        local file_stat = io.stat(version_info.path)
        if file_stat then
          table.insert(debug_info, "     Size: " .. file_stat.size .. " bytes")
          table.insert(debug_info, "     Modified: " .. os.date("%Y-%m-%d %H:%M:%S", file_stat.mtime))
        end
      end
    end
  end
  
  table.insert(debug_info, "\nCurrent config path: " .. self.prefs.path_to_config.value)
  table.insert(debug_info, "Current config exists: " .. (io.exists(self.prefs.path_to_config.value) and "YES" or "NO"))
  
  renoise.app():show_message(table.concat(debug_info, "\n"))
end

---------------------------------------------------------------------------------------------------
-- Search for selected sample in Sononym
function App:search_selected_sample()
  local success,err = self:do_search()
  if not success and err then
    renoise.app():show_message(err or "Search failed")
  end
end

---------------------------------------------------------------------------------------------------
-- Load currently selected sample from Sononym
-- @param show_prompt (boolean) - if true, shows status messages; if false, loads silently
function App:load_selected_sample_from_sononym(show_prompt)
  
  -- Get the current selection directly from Sononym's JSON using the proper function
  local current_selection = App.parse_config(self.prefs.path_to_config.value)
  if not current_selection then
    renoise.app():show_message("Failed to get Sononym selection.\nMake sure Sononym has a file selected.")
    return
  end
  
  local sample_name = string.match(current_selection.filename, "([^/]+)$") or current_selection.filename
  local full_path
  
  -- Check if this is already an absolute path (temp files) or needs to be constructed
  if string.match(current_selection.filename, "^/") or string.match(current_selection.filename, "^[A-Za-z]:") then
    -- This is already a full absolute path (temp file)
    full_path = current_selection.filename
  else
    -- This is a relative path, construct it using the database location
    local clean_path = current_selection.locationPath:gsub("sononym%.db$", "")
    full_path = clean_path .. current_selection.filename
  end
  
  TRACE("Selected Sample Full path: " .. full_path)
  
  local choice = "Load Sample"  -- Default to load
  
  if show_prompt then
    choice = renoise.app():show_prompt("Load Sample from Sononym",
      "Sample: " .. sample_name .. "\n\nPath: " .. full_path,
      {"Load Sample", "Cancel"})
    TRACE("User choice: " .. choice)
  else
    TRACE("No prompt mode - loading directly")
  end
    
  if choice == "Load Sample" then
    -- Load the sample directly using the full path - bypass all the configuration nonsense
    if not io.exists(full_path) then
      TRACE("Failed to load sample: File does not exist at " .. full_path)
      renoise.app():show_message("Failed to load sample:\nFile does not exist:\n" .. full_path)
      return
    end
    
    -- Load directly into Renoise - create new instrument
    local success, err = pcall(function()
      -- Create a new instrument using the correct API
      rns:insert_instrument_at(rns.selected_instrument_index + 1)
      rns.selected_instrument_index = rns.selected_instrument_index + 1
      
      -- Insert a new sample slot in the new instrument
      rns.selected_instrument:insert_sample_at(1)
      rns.selected_sample_index = 1
      
      -- Load the sample into the new sample slot
      local sample = rns.selected_instrument.samples[1]
      sample.sample_buffer:load_from(full_path)
      
      -- Set sample name to the filename (without path)
      sample.name = sample_name
      
      -- Set instrument name to the filename as well for easy identification
      rns.selected_instrument.name = sample_name
    end)
    
    if not success then
      TRACE("Failed to load sample: " .. tostring(err))
      renoise.app():show_message("Failed to load sample:\n" .. tostring(err))
    else
      TRACE("Sample loaded: " .. sample_name)
      renoise.app():show_status("Sample loaded: " .. sample_name)
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Load currently selected sample from Sononym directly to the selected sample slot
-- This function is specifically for Sample Navigator context
function App:load_selected_sample_to_selected_slot()
  TRACE("App:load_selected_sample_to_selected_slot()")
  
  -- Check if there's a selected sample slot
  if not rns.selected_sample then
    renoise.app():show_message("No sample slot selected.\nPlease select a sample slot first.")
    return false
  end
  
  -- Get the current selection directly from Sononym's JSON
  local current_selection = App.parse_config(self.prefs.path_to_config.value)
  if not current_selection then
    renoise.app():show_message("Failed to get Sononym selection.\nMake sure Sononym has a file selected.")
    return false
  end
  
  -- Get the sample instance
  local sample = rns.selected_sample
  local sample_name = string.match(current_selection.filename, "([^/]+)$") or current_selection.filename
  
  -- Construct the full path (reusing the logic from do_transfer)
  local config_folder,_,__ = cFilesystem.get_path_parts(self.prefs.path_to_config.value)
  local folder,_,__ = cFilesystem.get_path_parts(current_selection.locationPath)
  
  local fpath
  if (folder == config_folder) then 
    -- internal sononym library means filename is relative to the library folder
    -- Remove 'sononym.db' from locationPath to get the base folder
    local library_base = string.gsub(current_selection.locationPath, "sononym%.db$", "")
    fpath = cFilesystem.unixslashes(library_base .. current_selection.filename)
  else
    -- external path, filename should be combined with folder
    fpath = cFilesystem.unixslashes(folder .. current_selection.filename)
  end
  
  TRACE("Selected Sample Full path for sample slot: " .. fpath)
  
  -- If the constructed path doesn't exist, try alternative constructions
  if not io.exists(fpath) then
    TRACE("Primary path doesn't exist, trying alternatives...")
    
    -- Try treating the filename as an absolute path
    local alt_path1 = cFilesystem.unixslashes(current_selection.filename)
    if io.exists(alt_path1) then
      TRACE("Found file using filename as absolute path:", alt_path1)
      fpath = alt_path1
    else
      -- Try combining with the directory containing sononym.db
      local alt_path2 = cFilesystem.unixslashes(folder .. "/" .. current_selection.filename)
      if io.exists(alt_path2) then
        TRACE("Found file using folder + filename with slash:", alt_path2)
        fpath = alt_path2
      end
    end
  end
  
  -- Check if the file exists before attempting to load
  if not io.exists(fpath) then
    TRACE("File not found at constructed path:", fpath)
    renoise.app():show_message("Failed to load sample:\nFile does not exist:\n" .. fpath)
    return false
  end
  
  -- Load the sample directly into the selected sample slot
  local success,err = pcall(function()
    return self:load_sample_with_slice_preservation(sample, fpath)
  end)
  
  if not success then 
    TRACE("Loading failed with error:", err)
    renoise.app():show_message("Failed to load sample:\n"..tostring(err))
    return false
  end
  
  if not err then
    TRACE("Loading failed - load_sample_with_slice_preservation returned false")
    renoise.app():show_message("Failed to load sample: unknown error")
    return false
  end
  
  -- Update sample name  
  local folder,filename,ext = cFilesystem.get_path_parts(current_selection.filename)
  sample.name = filename
  
  -- Display message in status bar
  local msg = "Loaded sample to selected slot: "..filename
  renoise.app():show_status(msg)
  TRACE(msg)
  
  return true
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
    return nil, "ERROR: Failed to open file handle"
  end

  local str_json = fhandle:read("*a")
  fhandle:close()  
  
  -- parse the string 
  local first,last = nil,nil
  local offset = string.find(str_json,'"selectedFile"')
  if not offset then
    return nil, "ERROR: selectedFile not found in config"
  end
  str_json = string.sub(str_json,offset)
  
  first,last = string.find(str_json,'"filename":%C*')
  if not first or not last then
    return nil, "ERROR: filename not found in config"
  end
  local filename = cFilesystem.unixslashes(string.sub(str_json,first+13,last-2))
  
  first,last = string.find(str_json,'"locationPath":%C*')
  if not first or not last then
    return nil, "ERROR: locationPath not found in config"
  end
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
  TRACE("App.check_path(str_path)",str_path)
  
  if not str_path or (str_path == "") then 
    return false,"No path specified"
  end 
  
  if not io.exists(str_path) then
    return false,"Path does not exist"
  end
  
  return true 
  
end

---------------------------------------------------------------------------------------------------
-- attempt to resolve the location of the Sononym executable 
function App.guess_path_to_exe()
  TRACE("App.guess_path_to_exe()")

  local platform = os.platform()
  if (platform == "WINDOWS") then 
    -- spawn terminal to obtain windows environment variable
    local cmd = "echo %PROGRAMFILES%"
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    return cFilesystem.unixslashes(cString.trim(s).."/Sononym/Sononym.exe")
  elseif (platform == "MACINTOSH") then 
    return "/Applications/Sononym.app/Contents/MacOS/Sononym"
  elseif (platform == "LINUX") then 
    -- First try the standard location
    local standard_path = "/usr/bin/sononym"
    LOG("Linux - checking standard path:", standard_path)
    if io.exists(standard_path) then
      LOG("Linux - found Sononym at standard path:", standard_path)
      return standard_path
    end
    
    -- If not found, use 'which' to search PATH
    LOG("Linux - standard path not found, trying 'which' command")
    
    -- First test if io.popen works at all in Renoise
    LOG("Linux - testing io.popen functionality")
    local test_success, test_handle = pcall(io.popen, "echo test")
    if test_success and test_handle then
      local test_result = test_handle:read("*line")
      test_handle:close()
      LOG("Linux - io.popen test result:", test_result or "(empty)")
      if not test_result or cString.trim(test_result) ~= "test" then
        LOG("Linux - io.popen is not working properly in Renoise environment")
      end
    else
      LOG("Linux - io.popen is not available or restricted in Renoise environment")
    end
    
    -- Try multiple approaches to find the executable
    local search_commands = {
      "which sononym",
      "command -v sononym",
      "type -p sononym"
    }
    
    for _, cmd in ipairs(search_commands) do
      LOG("Linux - trying command:", cmd)
      local success, handle = pcall(io.popen, cmd)
      if success and handle then
        local result = handle:read("*line")
        handle:close()
        
        -- Trim whitespace from result
        if result then
          result = cString.trim(result)
        end
        
        LOG("Linux - command result:", result or "(empty)")
        if result and result ~= "" then
          LOG("Linux - checking if path exists:", result)
          if io.exists(result) then
            LOG("Found Sononym via '" .. cmd .. "' at:", result)
            return cFilesystem.unixslashes(result)
          else
            LOG("Linux - path returned by command doesn't exist:", result)
          end
        end
      else
        LOG("Linux - failed to execute command:", cmd)
      end
    end
    
    LOG("Linux - all search commands failed or returned no results")
    
    -- Try some common alternative locations
    local user = os.getenv("USER") or "user"
    local home = os.getenv("HOME") or ("/home/" .. user)
    local alt_paths = {
      "/usr/local/bin/sononym",
      "/opt/sononym/sononym",
      "/opt/Sononym/sononym",
      home .. "/.local/bin/sononym",
      home .. "/bin/sononym",
      home .. "/Applications/Sononym/sononym",
      "/snap/bin/sononym",
      "/var/lib/flatpak/exports/bin/sononym"
    }
    
    for _, alt_path in ipairs(alt_paths) do
      LOG("Linux - checking alternative path:", alt_path)
      if io.exists(alt_path) then
        LOG("Linux - found Sononym at alternative path:", alt_path)
        return alt_path
      end
    end
    
    LOG("Linux - Sononym executable not found in any standard locations")
    -- Fallback to standard path (even if it doesn't exist, for user reference)
    return standard_path
  end   

end

---------------------------------------------------------------------------------------------------
-- find all available Sononym versions and their query.json files
function App.find_sononym_versions()
  TRACE("App.find_sononym_versions()")
  
  local platform = os.platform()
  local base_path
  
  if (platform == "WINDOWS") then 
    base_path = cFilesystem.get_user_folder() .. "AppData/Roaming/Sononym/"
  elseif (platform == "MACINTOSH") then 
    base_path = cFilesystem.get_user_folder() .. "Library/Application Support/Sononym/"
  elseif (platform == "LINUX") then 
    local user_folder = cFilesystem.get_user_folder()
    -- Ensure user_folder ends with "/" for proper path construction
    if not string.match(user_folder, "/$") then
      user_folder = user_folder .. "/"
    end
    base_path = user_folder .. ".config/Sononym/"
    LOG("Linux - User folder:", user_folder)
    LOG("Linux - Base path:", base_path)
  else
    return {}
  end
  
  local versions = {}
  
  -- Check if base Sononym directory exists
  if not io.exists(base_path) then
    LOG("Sononym base directory not found:", base_path)
    return versions
  end
  
  LOG("Scanning for Sononym versions in:", base_path)
  
  -- Look for version directories (like 1.5.5, 1.5.6, etc.)
  local dirs = os.dirnames(base_path)
  if dirs then
    LOG("Found", #dirs, "directories in", base_path)
    for _, dir in ipairs(dirs) do
      LOG("Checking directory:", dir)
      -- Check if this looks like a version number (starts with digit and contains dots)
      -- This will match patterns like: 1.5.5, 1.5.6, 2.0.0, 1.6.0-beta, etc.
      if string.match(dir, "^%d+%.%d+") then
        local query_path = base_path .. dir .. "/query.json"
        LOG("Testing query.json path:", query_path)
        if io.exists(query_path) then
          table.insert(versions, {
            version = dir,
            path = query_path
          })
          LOG("Found Sononym version:", dir, "with query.json at", query_path)
        else
          LOG("query.json not found at:", query_path)
        end
      else
        LOG("Directory", dir, "doesn't match version pattern")
      end
    end
  else
    LOG("No directories found in", base_path)
  end
  
  -- Sort versions (newest first) using proper version comparison
  table.sort(versions, function(a, b)
    -- Split version strings into numbers for proper comparison
    local a_parts = {}
    local b_parts = {}
    
    for num in string.gmatch(a.version, "%d+") do
      table.insert(a_parts, tonumber(num))
    end
    
    for num in string.gmatch(b.version, "%d+") do
      table.insert(b_parts, tonumber(num))
    end
    
    -- Compare version parts (major, minor, patch)
    for i = 1, math.max(#a_parts, #b_parts) do
      local a_part = a_parts[i] or 0
      local b_part = b_parts[i] or 0
      
      if a_part ~= b_part then
        return a_part > b_part  -- Higher version number comes first
      end
    end
    
    return false -- Equal versions
  end)
  
  return versions
end

---------------------------------------------------------------------------------------------------
-- attempt to resolve the location of 'query.json' with version detection
function App.guess_path_to_config()
  TRACE("App.guess_path_to_config()")
  
  local versions = App.find_sononym_versions()
  LOG("*** guess_path_to_config: found", #versions, "versions")
  
  if #versions == 0 then
    -- No versions found at all
    LOG("No Sononym versions detected - check if Sononym is installed")
    
    -- On Linux, provide a helpful fallback suggestion
    local platform = os.platform()
    if (platform == "LINUX") then
      local user_folder = cFilesystem.get_user_folder()
      if not string.match(user_folder, "/$") then
        user_folder = user_folder .. "/"
      end
      local fallback_path = user_folder .. ".config/Sononym/"
      LOG("Linux fallback: try looking in", fallback_path)
      -- Check if the base directory exists but no versions were found
      if io.exists(fallback_path) then
        LOG("Base Sononym directory exists but no version directories found")
        -- Look for any query.json files in subdirectories
        local dirs = os.dirnames(fallback_path)
        if dirs then
          for _, dir in ipairs(dirs) do
            local query_path = fallback_path .. dir .. "/query.json"
            LOG("Fallback - checking:", query_path)
            if io.exists(query_path) then
              LOG("Found query.json in non-standard directory:", dir, "-> returning:", query_path)
              return query_path
            end
          end
        end
      end
    end
    
    LOG("*** guess_path_to_config: returning nil (no versions found)")
    return nil
  else
    -- Always return newest version - UI will handle multiple version selection
    local newest_version = versions[1]
    LOG("Auto-selected newest Sononym version:", newest_version.version, "at", newest_version.path)
    LOG("*** guess_path_to_config: returning path:", newest_version.path)
    return newest_version.path
  end
end



--local prefs = AppPrefs()
local prefs = AppPrefs()
renoise.tool().preferences = prefs



function OpenConfigPath()

--print (prefs.path_to_config)
local config_path = renoise.tool().preferences.path_to_config.value
local directory_path = config_path:match("(.*/)")
oprint(os.platform())
oprint(directory_path)
oprint(config_path)
  local command
local os_name = os.platform()

  if os_name == "WINDOWS" then command = 'start "" "' .. directory_path .. '"'
  elseif os_name == "MACINTOSH" then command = 'open "' .. directory_path .. '"'
  else os_name = 'xdg-open "' .. directory_path .. '"' end
  os.execute(command)


end



function flip_a_coin(file_path)
  -- Open the file containing the JSON
  local file = io.open(file_path, "r")
  
  if not file then
    renoise.app():show_status("Error: Cannot open file at " .. file_path)
    return nil, nil
  end
  
  -- Read the entire file content as a string
  local queryjsonvariable = file:read("*all")
  file:close()

  -- NOTE: Sononym's query.json only contains the currently selected file,
  -- not all search results. For true randomness, user needs to have 
  -- search results displayed in Sononym first.
  
  -- Extract the selected filename from the JSON
  local selected_filename = queryjsonvariable:match('"filename"%s*:%s*"([^"]+)"')
  if not selected_filename then
    renoise.app():show_status("Error: No filename found in Sononym selection.")
    return nil, nil
  end

  -- Extract just the filename without path for display
  local display_name = string.match(selected_filename, "([^/]+)$") or selected_filename

  -- Check if this is already an absolute path (temp files) or needs to be constructed
  local full_path
  if string.match(selected_filename, "^/") or string.match(selected_filename, "^[A-Za-z]:") then
    -- This is already a full absolute path (temp file)
    full_path = selected_filename
  else
    -- This is a relative path, construct it using the database location
    local selectedLocationPath = queryjsonvariable:match('"selectedLocationPath"%s*:%s*"([^"]+)"')
    if not selectedLocationPath then
      renoise.app():show_status("Error: selectedLocationPath not found.")
      return nil, nil
    end
    
    -- Remove 'sononym.db' from selectedLocationPath to get base path
    local clean_path = selectedLocationPath:gsub("sononym%.db$", "")
    full_path = clean_path .. selected_filename
  end
  
  return display_name, full_path
end

-- flip_a_coin(renoise.tool().preferences.path_to_config.value) -- Removed auto-call 
