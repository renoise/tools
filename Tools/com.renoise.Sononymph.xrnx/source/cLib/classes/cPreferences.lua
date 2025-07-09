--[[===============================================================================================
-- cPreferences
============================================================================]]--

--[[--

Maintain multiple preferences for a tool and switch between them.

##

Each profile is basically a copy of the preferences.xml stored in the
special 'profiles' folder. 

Note: cPreferences stores it's own settings in the root of the this folder


]]

--=================================================================================================

require (_clibroot.."cFilesystem")

class 'cPreferences'

cPreferences.PROFILES_ENABLED = false
cPreferences.ALWAYS_CHOOSE = false

cPreferences.DEFAULT_NAME = "Untitled Profile"

cPreferences.PROFILE_FOLDER = "./profiles/"
cPreferences.BUTTON_H = 26

---------------------------------------------------------------------------------------------------

function cPreferences:__init(...)

  local args = cLib.unpack_args(...)

  --- string, supply to make the launch dialog feel more familiar
  self.tool_name = args.tool_name or "Tool Name"

  --- string, provide name if preferences is based on a class
  self.doc_class_name = args.doc_class_name

  --- number of active instances (read-only)
  self.active_instances = property(self.get_active_instances)

  --- number, the profile we're running
  self.selected_profile_index = nil

  --- table
  self.selected_profile = property(self.get_selected_profile)

  --== callbacks ==--

  --- function, deliver a custom profile to the tool
  -- @param doc, renoise.DocumentNode
  self.launch_callback = args.launch_callback

  --- function, ask the tool to load standard prefs
  self.default_callback = args.default_callback

  --- function, ask the tool not to start
  self.abort_callback = args.abort_callback

  --== self-managed ==--

  --- boolean, if true: detect active instances and choose a profile
  --  (an active instance is a profile launched within the cutoff time)
  --  if false: use the preferences.xml in the bundle path
  --  (in other words, act as a normal tool)
  self.profiles_enabled = property(self.get_profiles_enabled,self.set_profiles_enabled)
  self.profiles_enabled_observable = renoise.Document.ObservableBoolean(cPreferences.PROFILES_ENABLED)

  --- boolean, if true we always show the chooser
  self.always_choose = property(self.get_always_choose,self.set_always_choose)
  self.always_choose_observable = renoise.Document.ObservableBoolean(cPreferences.ALWAYS_CHOOSE)

  --- string, the profile to recall on startup
  self.recall_profile = property(self.get_recall_profile,self.set_recall_profile)
  self.recall_profile_observable = renoise.Document.ObservableString("")

  --== internal ==--

  --- table<string> 
  self.profiles = {}

  --- renoise.Dialog
  self.dialog = nil

  --- renoise.Views.View
  self.dialog_contents = nil

  --- boolean
  self.suppress_saving = false

  --== initialize ==--
  
  self:load_settings()
  self:scan_profiles()
  self:build_dialog()

end

---------------------------------------------------------------------------------------------------
-- Getter/Setters
---------------------------------------------------------------------------------------------------

function cPreferences:get_selected_profile()
  return self.profiles[self.selected_profile_index]
end

---------------------------------------------------------------------------------------------------

function cPreferences:get_profiles_enabled()
  return self.profiles_enabled_observable.value
end

function cPreferences:set_profiles_enabled(val)
  self.profiles_enabled_observable.value = val
  self:save_settings()
end

---------------------------------------------------------------------------------------------------

function cPreferences:get_always_choose()
  return self.always_choose_observable.value
end

function cPreferences:set_always_choose(val)
  self.always_choose_observable.value = val
  self:save_settings()
end

---------------------------------------------------------------------------------------------------

function cPreferences:get_recall_profile()
  return self.recall_profile_observable.value
end

function cPreferences:set_recall_profile(val)
  self.recall_profile_observable.value = val
  self:save_settings()
end

---------------------------------------------------------------------------------------------------

function cPreferences:get_active_instances()
  local count = 0
  for k,v in ipairs(self.profiles) do
    if (v.active) then
      count = count + 1
    end
  end
  return count

end

---------------------------------------------------------------------------------------------------

function cPreferences:get_profile_names()

  local rslt = {}
  for k,v in ipairs(self.profiles) do
    table.insert(rslt,v.name)
  end
  return rslt

end

---------------------------------------------------------------------------------------------------
-- Class Methods
---------------------------------------------------------------------------------------------------
-- determine which profiles are active/available
-- + create folders when missing

function cPreferences:scan_profiles()

  self.profiles = {}

  local str_path = cPreferences.PROFILE_FOLDER
  
  if not io.exists(str_path) then
    os.mkdir(str_path)
  end

  local dirnames = os.dirnames(str_path)
  for k,v in ipairs(dirnames) do
    local filenames = os.filenames(str_path..v)
    local has_config,active,mtime = false,false,nil
    for k2,v2 in ipairs(filenames) do
      local filestats = io.stat(str_path..v.."/"..v2)

      if (v2 == "preferences.xml") then
        has_config = true
      end
      if (v2 == "active") then
        active = true
        mtime = filestats.mtime
      end
    end
    table.insert(self.profiles,{
      name = v,
      has_config = has_config,
      active = active,
      mtime = mtime,
    })
  end

end

---------------------------------------------------------------------------------------------------

function cPreferences:get_profile_by_name(str_name)

  for k,v in ipairs(self.profiles) do
    if (v.name == str_name) then
      return v,k
    end
  end

end

---------------------------------------------------------------------------------------------------

function cPreferences:attempt_launch()

  local profile,profile_idx = self:get_profile_by_name(self.recall_profile)

  if self.profiles_enabled then
    if profile then
      self:launch_profile(profile_idx)
    elseif self.always_choose then
      self:show_dialog()
      return
    end
  end

  self.default_callback()

end

---------------------------------------------------------------------------------------------------

function cPreferences:close_dialog()

  if (self.dialog and self.dialog.visible) then
    self.dialog:close()
  end
  self.dialog = nil

end

---------------------------------------------------------------------------------------------------

function cPreferences:launch_profile(idx)

  local profile = self.profiles[idx]
  if profile then
    
    -- instantiate as class or scriptingtool prefs? 
    local doc 
    if self.doc_class_name then
      doc = _G[self.doc_class_name]()
    else
      doc = renoise.Document.create("ScriptingToolPreferences"){}
    end

    local prefs_path = cPreferences.PROFILE_FOLDER.."/"..profile.name.."/preferences.xml"
    doc:load_from(prefs_path)

    -- backup existing preferences 
    local tool_prefs_from = renoise.tool().bundle_path.."preferences.xml"
    local tool_prefs_to = renoise.tool().bundle_path.."preferences.xml.old"
    os.move(tool_prefs_from,tool_prefs_to)

    -- create lock file
    local lock_path = cPreferences.PROFILE_FOLDER.."/"..profile.name.."/active"
    local lock_str = "This file indicates that the profile is in use"
    cFilesystem.write_string_to_file(lock_path,lock_str)
    
    self.selected_profile_index = idx
    self.launch_callback(doc)

  end

end

---------------------------------------------------------------------------------------------------
-- save preferences for the selected profile
-- @return boolean,string

function cPreferences:remove_profile(idx)

  local profile = self.profiles[idx]
  if not profile then
    return false, "Can't remove, profile doesn't exist"
  end

  local str_path = cPreferences.PROFILE_FOLDER.."/"..profile.name.."/"
  local success,err = cFilesystem.rmdir(str_path)
  if not success then
    return false,err
  end

  table.remove(self.profiles,idx)
  if (idx == self.selected_profile_index) then
    self.selected_profile_index = nil
  end

end


---------------------------------------------------------------------------------------------------
-- save preferences for the selected profile
-- @return boolean,string

function cPreferences:add_profile(str_name)

  local str_path = cPreferences.PROFILE_FOLDER.."/"..str_name
  local str_path = cFilesystem.ensure_unique_filename(str_path)
  local suggested_name = cFilesystem.get_raw_filename(str_path)

  -- create folder and empty set of preferences
  os.mkdir(str_path)
  local file_out = str_path .."/preferences.xml"

  local doc
  if self.doc_class_name then
    doc = _G[self.doc_class_name]()
  else
    doc = renoise.Document.create("ScriptingToolPreferences"){}
  end
  doc:save_as(file_out)

  return true

end

---------------------------------------------------------------------------------------------------
-- save preferences for the selected profile
-- @return boolean,string

function cPreferences:rename_profile(idx,str_name)

  local profile = self.profiles[idx]
  if not profile then
    return false, "Can't rename, profile doesn't exist"
  end

  local str_path = cPreferences.PROFILE_FOLDER.."/"..str_name
  local str_path = cFilesystem.ensure_unique_filename(str_path)
  local suggested_name = cFilesystem.get_raw_filename(str_path)

  if (str_name ~= suggested_name) then
    return false,"A profile already exist with that name, please choose another one"
  end

  local str_path_old = cPreferences.PROFILE_FOLDER.."/"..profile.name
  cFilesystem.rename(str_path_old,str_path)

  return true

end


---------------------------------------------------------------------------------------------------
-- save preferences for the selected profile
-- @return boolean,string

function cPreferences:update_profile()
  
  local profile = self.selected_profile
  if not profile then
    return false,"Can't update, no profile is selected"
  end
  local doc = renoise.tool().preferences

  local prefs_path = cPreferences.PROFILE_FOLDER.."/"..profile.name.."/preferences.xml"
  local passed,err = doc:save_as(prefs_path)
  if not passed then
    return false,err
  end

  return true

end

---------------------------------------------------------------------------------------------------

function cPreferences:show_dialog()

  if (not self.dialog or not self.dialog.visible) then
    self.dialog = renoise.app():show_custom_dialog(
      ("%s - Select Profile"):format(self.tool_name), self.dialog_contents)
  else
    self.dialog:show()
  end

end

---------------------------------------------------------------------------------------------------

function cPreferences:rebuild_and_show()

  self:close_dialog()
  self:scan_profiles()
  self:build_dialog()
  self:show_dialog()

end

---------------------------------------------------------------------------------------------------

function cPreferences:build_dialog()

  local vb = renoise.ViewBuilder()

  -- show session time as "XX minutes ago" when 
  -- time difference is less than one hour...
  local human_time_display = function(mtime)
    local time_diff = os.difftime(os.time(),mtime)
    if (time_diff < 3600) then
      return ("%d minutes ago"):format(time_diff/60)
    else
      return os.date("%c",mtime)
    end
  end

  local items = {}
  for k,v in ipairs(self.profiles) do
    local mtime_display = human_time_display(v.mtime)
    local str_suffix = ""
    if v.active then
      str_suffix = (" - Last session was %s"):format(mtime_display) or ""
    elseif not v.has_config then
      str_suffix = " - using default settings"
    end
    table.insert(items,v.name..str_suffix)
  end

  local vb_submit_buttons = vb:row{
    vb:button{
      text = "Proceed",
      height = cPreferences.BUTTON_H,
      notifier = function()
        if not vb.views.profile_chooser then
          self.default_callback()
        else
          local idx = vb.views.profile_chooser.value
          if (idx == 1) then
            self.default_callback()
          else
            self:launch_profile(idx-1)
          end
        end
        self:close_dialog()
      end,
    },
    vb:button{
      text = "Add...",
      height = cPreferences.BUTTON_H,
      notifier = function()
        local str_name = cPreferences.DEFAULT_NAME
        str_name = vPrompt.prompt_for_string(str_name,"Enter name","Add Profile") 
        if not str_name then
          return
        end
        local success,err = self:add_profile(str_name)
        if err then
          renoise.app():show_warning(err)
        else
          self:rebuild_and_show()
        end
      end,
    },
    vb:button{
      id = "xprefs_remove_bt",
      text = "Remove",
      active = false,
      visible = not table.is_empty(items) and true or false,
      height = cPreferences.BUTTON_H,
      notifier = function()
        local msg = "Are you sure you want to remove this profile?"
        local choice = renoise.app():show_prompt("Remove Profile",msg,{"OK","Cancel"})
        if (choice == "OK") then
          local idx = vb.views.profile_chooser.value
          local success,err = self:remove_profile(idx-1)
          if err then
            renoise.app():show_warning(err)
          else
            self:rebuild_and_show()
          end
        end
      end,
    },
    vb:button{
      id = "xprefs_rename_bt",
      text = "Rename",
      active = false,
      visible = not table.is_empty(items) and true or false,
      height = cPreferences.BUTTON_H,
      notifier = function()
        local idx = vb.views.profile_chooser.value
        local str_name = self.profiles[idx-1].name
        str_name = vPrompt.prompt_for_string(str_name,"Enter name","Rename Profile") 
        local success,err = self:rename_profile(idx-1,str_name)
        if err then
          renoise.app():show_warning(err)
        else
          self:rebuild_and_show()
        end

      end,
    },
    vb:button{
      text = "Don't Launch",
      height = cPreferences.BUTTON_H,
      notifier = function()          
        if self.abort_callback then
          self.abort_callback()
        end
        self:close_dialog()

      end,
    },

  }

  if table.is_empty(items) then
    self.dialog_contents = vb:column{
      margin = 6,
      spacing = 6,
      vb:row{
        vb:text{
          text = ("%s supports configuration profiles,"
          .."\nbut no profiles have yet been defined."
          .."\n"
          .."\nClick 'Proceed' to launch with current settings,"
          .."\nor 'Add Profile' to create a new profile."):format(self.tool_name),
        },
      },
      vb:row{
        vb:checkbox{
          value = not self.always_choose,
          notifier = function(val)
            self.always_choose = not val
          end
        },
        vb:text{
          text = "Do not show this dialog"
        },
      },
      vb_submit_buttons,
    }

  else
    table.insert(items,1,"Launch tool with current settings")
    local profile_index = 1
    if (self.recall_profile ~="") then
      local tmp_idx = table.find(items,self.recall_profile)
      if tmp_idx then
        profile_index = tmp_idx
      end
    end
    self.dialog_contents = vb:column{
      margin = 6,
      spacing = 6,
      vb:row{
        vb:text{
          text = ("%s supports configuration profiles - "
          .."\nplease select one before launching:"):format(self.tool_name),
        },
      },
      vb:row{
        margin = 6,
        vb:chooser{
          id = "profile_chooser",
          items = items,
          value = profile_index,
          notifier = function(idx)
            if (idx == 1) then
              vb.views.xprefs_remove_bt.active = false
              vb.views.xprefs_rename_bt.active = false
            else
              vb.views.xprefs_remove_bt.active = true
              vb.views.xprefs_rename_bt.active = true
            end
          end,
        },
      },
      vb:row{
        vb:checkbox{
          value = not self.always_choose,
          notifier = function(val)
            self.always_choose = not val
            if val then
              local idx = vb.views.profile_chooser.value
              if (idx == 1) then
                self.recall_profile = ""
              else
                local profile = self.profiles[idx-1]
                self.recall_profile = profile.name
              end
            else
              self.recall_profile = ""
            end
          end
        },
        vb:text{
          text = "Remember this choice"
        },
      },

      vb_submit_buttons,
    }

  end


end

---------------------------------------------------------------------------------------------------

function cPreferences:load_settings()

  local doc = renoise.Document.create("cPreferencesSettings"){}
  doc:add_property("profiles_enabled", renoise.Document.ObservableBoolean(cPreferences.PROFILES_ENABLED))
  doc:add_property("always_choose", renoise.Document.ObservableBoolean(cPreferences.ALWAYS_CHOOSE))
  doc:add_property("recall_profile", renoise.Document.ObservableString(""))

  local success,err = doc:load_from(cPreferences.PROFILE_FOLDER.."settings.xml")
  if success then
    self.suppress_saving = true
    self.profiles_enabled = doc:property('profiles_enabled').value
    self.always_choose = doc:property('always_choose').value
    self.recall_profile = doc:property('recall_profile').value
    self.suppress_saving = false
  end


end

---------------------------------------------------------------------------------------------------

function cPreferences:save_settings()
  
  if self.suppress_saving then
    return 
  end

  local doc = renoise.Document.create("cPreferencesSettings"){}
  doc:add_property("profiles_enabled", self.profiles_enabled)
  doc:add_property("always_choose", self.always_choose)
  doc:add_property("recall_profile", renoise.Document.ObservableString(self.recall_profile))

  local success,err = doc:save_as(cPreferences.PROFILE_FOLDER.."settings.xml")

end

