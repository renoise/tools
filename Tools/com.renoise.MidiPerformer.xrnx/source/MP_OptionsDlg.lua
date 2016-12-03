--[[============================================================================
MP_OptionsDlg
============================================================================]]--
--[[

Options dialog for MidiPerformer

]]

class 'MP_OptionsDlg'  (vDialog)

--------------------------------------------------------------------------------

function MP_OptionsDlg:__init(...)

  self.prefs = renoise.tool().preferences
  vDialog.__init(self,...)

end

-------------------------------------------------------------------------------

function MP_OptionsDlg:create_dialog()

  local vb = self.vb 
  local DIALOG_W = 200

  return vb:column{
    spacing = 3,
    margin = 3,
    vb:column{
      margin = 6,
      style = "group",
      vb:text{
        text = "Tool options",
        font = "bold",
        width = DIALOG_W,
      },
      vb:row{
        vb:checkbox{
          bind = self.prefs.autostart
        },
        vb:text{
          text = "Autostart tool"
        }
      },
      vb:row{
        vb:checkbox{
          bind = self.prefs.autoshow
        },
        vb:text{
          text = "Show dialog on autostart",
        }
      },
      vb:button{
        width = DIALOG_W,
        text = "Restore default settings",
        notifier = function()
          local msg = [[
Are you sure you want to reset the tool to its original settings?
This will reset all tool settings, including warning dialogs]]
          local choice = renoise.app():show_prompt("Reset settings?", msg, {"OK","Cancel"})
          if (choice == "OK") then
            self.prefs:reset()
          end
        end,
      },      
    },
    vb:column{
      margin = 6,        
      style = "group",
      vb:text{
        text = "Enable record-arming when",
        font = "bold",
        width = DIALOG_W,
      },
      vb:row{
        vb:checkbox{
          bind = self.prefs.autoarm_on_edit_enable
        },
        vb:text{
          text = "Edit-mode is enabled in Renoise"
        }
      },
    },    
    vb:column{
      margin = 6,        
      style = "group",
      vb:text{
        text = "Disable record-arming when",
        font = "bold",
        width = DIALOG_W,
      },
      vb:row{
        vb:checkbox{
          bind = self.prefs.disable_when_track_silent
        },
        vb:text{
          text = "Target track is set to -INF volume"
        }
      },
      vb:row{
        vb:checkbox{
          bind = self.prefs.disable_when_track_muted
        },
        vb:text{
          text = "Target track is muted "
        }
      }
    },    
  }

end

