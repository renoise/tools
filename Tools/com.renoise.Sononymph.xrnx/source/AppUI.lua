
class "AppUI" (vDialog)

AppUI.LABEL_W = 85
AppUI.INPUT_W = 250
AppUI.BUTTON_W = 130
AppUI.DIALOG_W = AppUI.LABEL_W + AppUI.INPUT_W + AppUI.BUTTON_W
AppUI.RENOISE_PLACEHOLDER = "No sample selected"
AppUI.SONONYM_PLACEHOLDER = "-"


---------------------------------------------------------------------------------------------------

function AppUI:__init(...) 
  TRACE("AppUI:__init")

  local args = cLib.unpack_args(...)
  assert(type(args.owner)=="App","Expected 'owner' to be an instance of App")
  
  vDialog.__init(self,...)
  
  -- App
  self.owner = args.owner
  
  -- vDialog
  self.about_dialog = nil
  
  -- vToggleButton
  self.prefs_toggle = nil
    
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
  
end

---------------------------------------------------------------------------------------------------
-- vDialog methods (overridden)

function AppUI:create_dialog()
  TRACE("AppUI:create_dialog()")

  local vb = self.vb
  
  self.prefs_toggle = vToggleButton{
    vb = vb,
    enabled = self.owner.prefs.show_prefs.value, 
    text_enabled = "▾",
    text_disabled = "▴",
    notifier = function()
      self.owner.prefs.show_prefs.value = not self.owner.prefs.show_prefs.value
    end
  }
  
  return vb:column{
    margin = 4,
    spacing = 4,
    vb:column{
      margin = 6,
      spacing = 4,
      style = "group",      
      vb:row{
        vb:text{
          text = "Renoise",
          width = AppUI.LABEL_W - 18,
        },
        vb:button{
          bitmap = "./source/icons/detach.bmp",
          notifier = function()
            self.owner:detach_sampler()
          end
        },    
        vb:row{
          style = "plain",
          vb:text{
            id = "sample_name_renoise",
            --font = "mono",
            text = AppUI.RENOISE_PLACEHOLDER,
            width = AppUI.INPUT_W,
            
          },
        },
        vb:button{
          id = "bt_search",
          text = "Search in Sononym",
          tooltip = "Click to launch a similarity search on this sample",
          --height = 30,
          width = AppUI.BUTTON_W,
          notifier = function()
            local success,err = self.owner:do_search()
            if not success then 
              renoise.app():show_message(err)
            end
          end
        },    
      },    
      vb:row{
        vb:column{
          vb:text{
            id = "label_filename_sononym",
            text = "Sononym",
            width = AppUI.LABEL_W,
          },          
          vb:row{
            self.prefs_toggle.view,
            vb:text{
              text = "Options",
              font = "bold",
            },  
          },
            
        },
        vb:column{
          vb:row{
            style = "plain",
            vb:text{
              id = "filename_sononym",
              --font = "mono",
              text = AppUI.SONONYM_PLACEHOLDER,
              width = AppUI.INPUT_W,
            },
          },
          vb:row{
            --style = "plain",
            vb:text{
              id = "location_path_sononym",
              --font = "mono",
              text = "In folder:",
            },
          },
        },
        vb:column{
          vb:button{
            id = "bt_transfer",
            text = "Transfer to Renoise",
            tooltip = "Click to transfer the selected sample from Sononym",
            --height = 30,
            width = AppUI.BUTTON_W,
            notifier = function()
              local success,err = self.owner:do_transfer()
              if not success then 
                renoise.app():show_message(err)
              end
            end
          },
          vb:row{
            vb:checkbox{
              id = "cb_transfer_toggle",
              --text = "",
              notifier = function()
                local success,err = self.owner:toggle_live_transfer()
                if not success and err then 
                  renoise.app():show_message(err)
                end
              end
            },     
            vb:text{
              text = "Auto-transfer"
            },
          },          
          
        },
        
      },
    
    },
    vb:column{    
      style = "group",
      id = "preferences_content",
      margin = 6,
      vb:horizontal_aligner{
        mode = "justify",
        width = AppUI.DIALOG_W,
        vb:row{
          vb:text{
            text = "Autostart tool",
            width = AppUI.LABEL_W,
          },
          vb:checkbox{
            bind = self.owner.prefs.autostart
          },
        },                
        vb:button{
          text = "How to use",
          width = AppUI.BUTTON_W,
          notifier = function()
            self:launch_howto()
          end
        }
      },    
      vb:space{
        width = AppUI.DIALOG_W,
      },
      vb:column{
        vb:row{
          vb:text{
            text = "Path to exe",
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
          vb:button{
            text = "Detect",
            width = AppUI.BUTTON_W/2,
            notifier = function()
              local choice = renoise.app():show_prompt("Auto-detect path",
                "This will attempt to auto-detect the path to the Sononym executable. "
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
            width = AppUI.BUTTON_W/2,
            notifier = function()
              self.owner:pick_path_to_exe()
            end
          },
        },
        vb:row{
          vb:text{
            text = "Path to config",
            width = AppUI.LABEL_W,
          },
          vb:row{
            style = "plain",
            vb:textfield{
              id = "path_to_config",
              text = "",
              width = AppUI.INPUT_W,
              notifier = function(txt) 
                local success,err = self.owner:set_path_to_config(txt)
                if not success then 
                  renoise.app():show_warning(err)
                end 
              end 
            },
          },
          vb:button{
            text = "Detect",
            width = AppUI.BUTTON_W/2,
            notifier = function()
              local choice = renoise.app():show_prompt("Auto-detect path",
                "This will attempt to auto-detect the path to the Sononym configuration. "
                .."\nAre you sure you want to do this?",
                {"OK","Cancel"})
              if (choice == "OK") then               
                local txt = vb.views["path_to_config"].text
                local success,err = self.owner:set_path_to_config(App.guess_path_to_config())
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
            width = AppUI.BUTTON_W/2,
            notifier = function()
              self.owner:pick_path_to_config()
            end
          },
        },
        vb:row{
          vb:text{
            text = "Status ",
            width = AppUI.LABEL_W,            
          },
          vb:text{
            text = "",
            id = "txt_tool_status",
          },
        },
      
      },
      
    },
    
  }

end

---------------------------------------------------------------------------------------------------

function AppUI:show()
  TRACE("AppUI:show")

  if not self.owner.paths_are_valid then 
    local choice = renoise.app():show_prompt("Configure tool",
      "The tool needs to be configured. Do you want to automatically detect"
      .."\nappropriate paths for the Sononym executable and configuration?",
      {"Yes please!","No, I will enter them manually"})
    if (choice == "Yes please!") then 
      self.owner:autoconfigure()
    end
  end


  vDialog.show(self)
  self.update_requested = true

end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------

function AppUI:update()
  TRACE("AppUI:update")
  
  if not self.dialog or not self.dialog.visible then
    return
  end
  
  local ctrl 
  local vb = self.vb
  
  local buffer = rns.selected_sample 
    and xSample.get_sample_buffer(rns.selected_sample)
  local samplename = rns.selected_sample 
    and xSample.get_display_name(rns.selected_sample,rns.selected_sample_index)
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
  ctrl.text = "Library: ".. (location_path or AppUI.SONONYM_PLACEHOLDER)
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
  
  ctrl = vb.views["preferences_content"]
  ctrl.visible = self.owner.prefs.show_prefs.value
  
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

function AppUI:launch_howto()
  
  if not self.about_dialog then 
    self.about_dialog = AppUIAbout{
      owner = self.owner
    }
  end
    
  self.about_dialog:show()
  
end

---------------------------------------------------------------------------------------------------
-- invoke when a new document becomes available 

function AppUI:attach_to_song()
  
  rns.selected_sample_observable:add_notifier(function()
    self.update_requested = true
  end)
  
end

