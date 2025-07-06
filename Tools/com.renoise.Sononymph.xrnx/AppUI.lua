class "AppUI"

AppUI.LABEL_W = 85
AppUI.INPUT_W = 350
AppUI.BUTTON_W = 130
AppUI.BUTTON_W2 = 150
AppUI.DIALOG_W = AppUI.LABEL_W + AppUI.INPUT_W + AppUI.BUTTON_W
AppUI.RENOISE_PLACEHOLDER = "No sample selected"
AppUI.SONONYM_PLACEHOLDER = "-"

---------------------------------------------------------------------------------------------------
function AppUI:__init(...)
  local args = cLib.unpack_args(...)
  assert(type(args.owner)=="App","Expected 'owner' to be an instance of App")
  
  -- App
  self.owner = args.owner
  
  -- Config paths for dropdown
  self.config_paths = {}
  
  -- Dialog management
  self.dialog = nil
  self.dialog_title = args.dialog_title or "Sononymph"
  self.dialog_content = nil
  self.vb = nil
  
  -- Toggle button state
  self.prefs_toggle_enabled = false
  

  
  -- Update flag
  self.update_requested = false
    
  -- notifications ------------------------------

  self.owner.monitor_active_observable:add_notifier(function()
    self.update_requested = true
  end)
  
  self.owner.prefs.path_to_exe:add_notifier(function()
    self.update_requested = true
  end)
  
  self.owner.prefs.path_to_config:add_notifier(function()
    self.update_requested = true
  end)
  
  self.owner.prefs.show_prefs:add_notifier(function()
    self.update_requested = true
    self.prefs_toggle_enabled = self.owner.prefs.show_prefs.value
  end)
  
  self.owner.selection_in_sononym_observable:add_notifier(function()
    self.update_requested = true
  end)
  
  self.owner.live_transfer_observable:add_notifier(function()
    self.update_requested = true
  end)
  
  self.owner.paths_are_valid_observable:add_notifier(function()
    self.update_requested = true
  end)
  
  -- initialize
  renoise.tool().app_idle_observable:add_notifier(self,self.on_idle)  
  renoise.tool().app_new_document_observable:add_notifier(function()
    self:attach_to_song()
  end)
  
  self:attach_to_song()
  
  -- Initialize toggle state
  self.prefs_toggle_enabled = self.owner.prefs.show_prefs.value
  
end

---------------------------------------------------------------------------------------------------
-- Handle keyboard shortcuts in the dialog
function AppUI:dialog_keyhandler(dialog, key)
  TRACE("AppUI:dialog_keyhandler", key.name, key.modifiers)
  
  -- ESC - Close dialog
  if (key.name == "esc") then
    self:close()
    return key -- Key handled, don't pass to Renoise
  else return key
  end
end

---------------------------------------------------------------------------------------------------
-- create/re-use existing dialog 
function AppUI:show()
  TRACE("AppUI:show()")

  if not self.dialog or not self.dialog.visible then
    if not self.dialog_content then
      self.dialog_content = self:create_dialog()
    end
    self.dialog = renoise.app():show_custom_dialog(
      self.dialog_title, self.dialog_content, function(dialog, key)
        return self:dialog_keyhandler(dialog, key)
      end)
  else
    self.dialog:show()
  end
  
  if not self.owner.paths_are_valid then 
    local app_path = self.owner.prefs.path_to_exe.value
    local config_path = self.owner.prefs.path_to_config.value
    
    -- First-time install: both paths are empty, auto-detect silently
    if (app_path == "" and config_path == "") then
      renoise.app():show_status("First time setup - auto-detecting Sononym paths...")
      self.owner:autoconfigure()
    else
      -- Paths exist but are invalid, show prompt
      local choice = renoise.app():show_prompt("Configure Sononymph",
        "Sononymph needs to be configured. Do you want to automatically detect"
        .."\nthe appropriate paths for the Sononym app and its configuration?",
        {"Detect Automatically","Enter Manually"})
      if (choice == "Detect Automatically") then 
        self.owner:autoconfigure()
      end
    end
  end

  self.update_requested = true
  return true
end

---------------------------------------------------------------------------------------------------
function AppUI:close()
  TRACE("AppUI:close()")

  if self.dialog and self.dialog.visible then
    self.dialog:close()
  end
end

---------------------------------------------------------------------------------------------------
function AppUI:dialog_is_visible()
  return self.dialog and self.dialog.visible or false
end

---------------------------------------------------------------------------------------------------
-- Create dialog content using regular Renoise ViewBuilder
function AppUI:create_dialog()
  self.vb = renoise.ViewBuilder() -- Reset the ViewBuilder
  local vb = self.vb
  
  return vb:column{
    margin = 4,
    spacing = 4,
    vb:column{
      margin = 6,
      spacing = 4,
      style = "group",      
      vb:row{
        vb:text{
          text = "Renoise",style="strong",font="bold",
          width = AppUI.LABEL_W - 18,
        },
        vb:button{
          bitmap = "./source/icons/detach.bmp",
          tooltip="Detach/Reattach Sample Editor and show.",
          notifier = function()
            self.owner:detach_sampler()
          end
        },    
        vb:row{
          style = "plain",
          vb:text{
            id = "sample_name_renoise",style="strong",font="bold",
            text = AppUI.RENOISE_PLACEHOLDER,
            width = AppUI.INPUT_W,
          },
        },
        vb:button{
          id = "bt_search",
          text = "Search in Sononym",
          tooltip = "Click to launch a similarity search for this sample",
          width = AppUI.BUTTON_W2,
          notifier = function()
            local success,err = self.owner:do_search()
            if not success then 
              renoise.app():show_message(err or "Search failed")
            end
          end
        },
        vb:button{
          id = "bt_browse",
          text = "Browse Path in Sononym",
          tooltip = "Select a folder and browse it in Sononym",
          width = AppUI.BUTTON_W2,
          notifier = function()
            local success,err = self.owner:do_browse()
            if not success then 
              renoise.app():show_message(err or "Browse failed")
            end
          end
        },    
      },    
      vb:row{
        vb:column{
          vb:text{
            id = "label_filename_sononym",
            text = "Sononym",style="strong",font="bold",
            width = AppUI.LABEL_W,
          },
        },
        vb:column{
          vb:row{
            vb:text{
              id = "filename_sononym",
              text = AppUI.SONONYM_PLACEHOLDER,
              width = AppUI.INPUT_W,style="strong",font="bold",
            },
          },

        },
        vb:column{
          vb:row{
            vb:button{
              id = "bt_transfer",
              text = "Transfer from Sononym",
              tooltip = "Click to transfer the selected sample from Sononym",
              width = AppUI.BUTTON_W2*2,
              notifier = function()
                local success,err = self.owner:do_transfer()
                if not success then 
                  renoise.app():show_message(err or "Transfer failed")
                end
                renoise.app().window.active_middle_frame=renoise.app().window.active_middle_frame
                renoise.app():show_status("Sample successfully loaded.")
              end
            },
          },
        },
      },
      vb:row{
        vb:space{
          width = AppUI.LABEL_W,
        },
        vb:checkbox{
          id = "cb_transfer_toggle",
          notifier = function()
            local success,err = self.owner:toggle_live_transfer()
            if not success and err then 
              renoise.app():show_message(err or "Auto-transfer toggle failed")
            end
          end
        },     
        vb:text{
          text = "Auto-transfer",style="strong",font="bold",
        },
        vb:checkbox{
          bind = self.owner.prefs.autotransfercreatenew,
        },
        vb:text{
          text = "New Instrument",style="strong",font="bold",
        },
        vb:checkbox{
          bind = self.owner.prefs.autotransfercreateslot,
        },
        vb:text{
          text = "New Sample Slot",style="strong",font="bold",
        },
      },
      vb:row{
        vb:button{
          id = "prefs_toggle",
          text = "▴", -- Start with collapsed state
          width = 22,
          notifier = function()
            self.owner.prefs.show_prefs.value = not self.owner.prefs.show_prefs.value
            self.prefs_toggle_enabled = self.owner.prefs.show_prefs.value
            -- Update button text immediately
            local btn = vb.views["prefs_toggle"]
            btn.text = self.prefs_toggle_enabled and "▾" or "▴"
          end
        },
        vb:text{
          text = "Options",style = "strong",font = "bold",width=AppUI.LABEL_W-22,
        },
        vb:text{
          id = "location_path_sononym",
          text = "[Library: ",style="strong",font="bold",
        },
      },
    },
    vb:column{    
      style = "group",
      id = "preferences_content",
      margin = 6,    
      vb:space{
        width = AppUI.DIALOG_W,
      },
      vb:column{
        vb:row{
          vb:text{
            text = "AppPath",style="strong",font="bold",
            width = AppUI.LABEL_W,
          },
          vb:row{
            style = "plain",
            vb:textfield{
              id = "path_to_exe",
              text = "",
              width = AppUI.INPUT_W,
              notifier = function(txt) 
                local success,err = self.owner:set_path_to_exe(txt)
                if not success then 
                  renoise.app():show_warning(err)
                end 
              end 
            },
          },
          vb:row{
            vb:button{
              text = "Detect",
              width = (2 * AppUI.BUTTON_W2) / 3,
              notifier = function()
                local choice = renoise.app():show_prompt("Auto-detect path",
                  "This will attempt to auto-detect the path to the Sononym app. "
                  .."\nAre you sure you want to do this?",
                  {"OK","Cancel"})
                if (choice == "OK") then 
                  local success,err = self.owner:set_path_to_exe(App.guess_path_to_exe())
                  if not success then 
                    if err then 
                      renoise.app():show_warning(err)
                    end
                  end 
                end
              end
            },
            vb:button{
              text = "Browse...",
              width = (2 * AppUI.BUTTON_W2) / 3,
              notifier = function()
                self.owner:pick_path_to_exe()
              end
            },
            vb:button{
              text = "Launch",
              width = (2 * AppUI.BUTTON_W2) / 3,
              notifier = function()
                local success,err = self.owner:launch_sononym()
                if not success and err then 
                  renoise.app():show_warning(err)
                end
              end
            },
          },
        },
        vb:row{
          vb:text{
            text = "ConfigPath",style="strong",font="bold",
            width = AppUI.LABEL_W,
          },
          vb:column{
            -- Container to hold both the textfield and popup
            vb:textfield{
              id = "path_to_config",
              text = "",
              width = AppUI.INPUT_W,
              notifier = function(txt) 
                local success, err = self.owner:set_path_to_config(txt)
                if not success then 
                  renoise.app():show_warning(err)
                end 
              end 
            },
            vb:popup{
              id = "config_path_popup",
              width = AppUI.INPUT_W,
              visible = false, -- Initially hidden
              items = {},
              notifier = function(index)
                local selected_version = self.config_paths[index]
                if selected_version then
                  local success, err = self.owner:set_path_to_config(selected_version.path)
                  if not success then 
                    renoise.app():show_warning(err)
                  end
                  -- Update the textfield with the selected path
                  vb.views["path_to_config"].text = selected_version.path
                  -- Hide the popup and show the textfield
                  vb.views["config_path_popup"].visible = false
                  vb.views["path_to_config"].visible = true
                end
              end
            }
          },
          vb:row{
            vb:button{
              text = "Detect",
              width = (2 * AppUI.BUTTON_W2) / 3,
              notifier = function()
                local choice = renoise.app():show_prompt("Auto-detect path",
                  "This will scan for available Sononym configurations.\nAre you sure you want to do this?",
                  {"OK","Cancel"})
                if (choice == "OK") then               
                  -- Get the list of available configurations
                  local versions = App.find_sononym_versions()
                  if #versions == 0 then
                    renoise.app():show_warning("No Sononym versions found.")
                  elseif #versions == 1 then
                    -- Only one version found - set it directly with full path
                    local version_info = versions[1]
                    local success, err = self.owner:set_path_to_config(version_info.path)
                    if success then
                      renoise.app():show_status("ConfigPath set to: " .. version_info.path)
                      -- Update the textfield display
                      vb.views["path_to_config"].text = version_info.path
                    else
                      renoise.app():show_warning(err or "Failed to set ConfigPath")
                    end
                  else
                    -- Multiple versions found - show dropdown for selection
                    self.config_paths = versions
                    
                    -- Build dropdown items
                    local dropdown_items = {}
                    for i, version_info in ipairs(versions) do
                      table.insert(dropdown_items, "Sononym " .. version_info.version .. " (" .. version_info.path .. ")")
                    end
                    
                    -- Populate the popup menu
                    vb.views["config_path_popup"].items = dropdown_items
                    -- Show the popup and hide the textfield
                    vb.views["config_path_popup"].visible = true
                    vb.views["path_to_config"].visible = false
                    renoise.app():show_status("Multiple versions found - please select one")
                  end
                end               
              end
            },          
            vb:button{
              text = "Browse...",
              width = (2 * AppUI.BUTTON_W2) / 3,
              notifier = function()
                self.owner:pick_path_to_config()
              end
            },
            vb:button{
              text = "Open Path",
              width = (2 * AppUI.BUTTON_W2) / 3,
              notifier = function()
                OpenConfigPath()
              end
            },
          },
        },
        vb:row{
          vb:text{
            text = "Status ",style="strong",font="bold",
            width = AppUI.LABEL_W,            
          },
          vb:text{
            text = "",style="strong",font="bold",
            id = "txt_tool_status",
          },
        },
      },
      vb:row{
        vb:button{
          text = "Full Sononym Documentation",
          width = AppUI.BUTTON_W,
          notifier = function()
            renoise.app():open_url("https://www.sononym.net/docs/")
          end
        },
        vb:button{
          text = "Sononymph Forum Thread",
          width = AppUI.BUTTON_W,
          notifier = function()
            renoise.app():open_url("https://forum.renoise.com/t/new-tool-3-4-sononymph-with-paketti-improvements-renoise-sononym-integration/76581")
          end
        },
        vb:checkbox{
          bind = self.owner.prefs.autostart,
        },
        vb:text{
          text = "Autostart",
          style = "strong",
          font = "bold",
          width = 60,
        },
      },
    },
  }

end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------

function AppUI:update()
  if not self.dialog or not self.dialog.visible then
    return
  end
  
  local ctrl 
  local vb = self.vb
  
  local buffer = rns.selected_sample 
    and get_sample_buffer(rns.selected_sample)
  local samplename = rns.selected_sample 
    and get_display_name(rns.selected_sample,rns.selected_sample_index)
  if samplename and not buffer then 
    samplename = samplename .. " (empty)"
  end
  ctrl = vb.views["sample_name_renoise"]
  ctrl.text = samplename or AppUI.RENOISE_PLACEHOLDER
  ctrl.tooltip = ctrl.text
  ctrl.width = AppUI.INPUT_W
  
  local filename = self.owner.selection_in_sononym and self.owner.selection_in_sononym.filename
  ctrl = vb.views["filename_sononym"]
  ctrl.text = filename or AppUI.SONONYM_PLACEHOLDER
  ctrl.tooltip = ctrl.text
  ctrl.width = AppUI.INPUT_W

  local location_path = self.owner.selection_in_sononym.locationPath
    and cFilesystem.get_path_parts(self.owner.selection_in_sononym.locationPath)
  ctrl = vb.views["location_path_sononym"]
  ctrl.text = "[Library: ".. (location_path or AppUI.SONONYM_PLACEHOLDER) .. "]"
  ctrl.tooltip = ctrl.text
  ctrl.width = AppUI.INPUT_W 

  local path_to_exe = self.owner.prefs.path_to_exe.value 
  ctrl = vb.views["path_to_exe"]
  ctrl.text = path_to_exe
  ctrl.tooltip = ctrl.text
  ctrl.width = AppUI.INPUT_W
  
  local path_to_config = self.owner.prefs.path_to_config.value 
  ctrl = vb.views["path_to_config"]
  ctrl.text = path_to_config
  ctrl.tooltip = ctrl.text
  ctrl.width = AppUI.INPUT_W
  
  ctrl = vb.views["bt_transfer"]
  ctrl.active = not self.owner.live_transfer_observable.value 
  
  -- Update the auto-transfer checkbox to reflect current state
  ctrl = vb.views["cb_transfer_toggle"]
  if ctrl then
    ctrl.value = self.owner.live_transfer_observable.value
  end
  
  -- Update preferences section visibility
  ctrl = vb.views["preferences_content"]
  ctrl.visible = self.owner.prefs.show_prefs.value
  
  -- Update toggle button text
  ctrl = vb.views["prefs_toggle"]
  if ctrl then
    ctrl.text = self.prefs_toggle_enabled and "▾" or "▴"
  end
  
  ctrl = self.vb.views["txt_tool_status"]
  local paths_are_valid = self.owner.paths_are_valid_observable.value
  local monitor_active = self.owner.monitor_active_observable.value
  ctrl.text = (paths_are_valid and monitor_active) 
    and "✔ Monitoring for changes..." 
    or "⚠ Invalid path: "..self.owner.invalid_path_observable.value

end

---------------------------------------------------------------------------------------------------
--- handle idle notifications

function AppUI:on_idle()
  
  if self.update_requested then
    self.update_requested = false
    self:update()
  end
  
  local is_visible = self:dialog_is_visible() 
  if not is_visible and self.owner.monitor_active then 
    self.owner:stop_monitoring()
  elseif is_visible and not self.owner.monitor_active then 
    self.owner:start_monitoring()
  end 
  
end



---------------------------------------------------------------------------------------------------
-- invoked when a new document becomes available 
function AppUI:attach_to_song()
  
  rns.selected_sample_observable:add_notifier(function()
    self.update_requested = true
  end)
  
end 