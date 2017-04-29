--[[============================================================================
VoiceRunner
============================================================================]]--
--[[

User interface for VoiceRunner

]]

local MARGIN = 4
local SPACING = 4
local LABEL_W = 50
local LEFT_PANEL_W = 150
local LARGE_BUTTON_H = 28
local HALF_BUTTON_W = LEFT_PANEL_W/2
local QUARTER_BUTTON_W = LEFT_PANEL_W/4 -2
local PITCH_COLUMN_COL = 48
local PITCH_NAME_COL = 80
local PITCH_NOTE_COL = 60
local PITCH_NOTE_COL = 60
local SORT_COLOR = {0xA0,0xA0,0xA0}
local SELECT_COLOR = nil --{0xDA,0x60,0x2D}

class 'VR_UI' (vDialog)

-------------------------------------------------------------------------------
-- vDialog
-------------------------------------------------------------------------------

function VR_UI:create_dialog()
  TRACE("VR_UI:create_dialog()")

  return self.vb:column{
    self.vb_content,
  }

end

-------------------------------------------------------------------------------

function VR_UI:show()
  TRACE("VR_UI:show()")

  vDialog.show(self)


end

--------------------------------------------------------------------------------
-- Class methods
--------------------------------------------------------------------------------

function VR_UI:__init(...)

  self.dialog_too_many_cols = nil

  local args = cLib.unpack_args(...)
  assert(type(args.owner)=="VR","Expected 'owner' to be a class instance")

  args.dialog_keyhandler = function(__self,dlg,key)
    
    if (key.modifiers == "") then
      local handlers = {
        ["up"] = function()
          self.owner:select_previous_voice_run()
        end,
        ["down"] = function()
          self.owner:select_next_voice_run(nil,nil,true)
        end,
        ["left"] = function()
          self.owner:select_previous_note_column()
        end,
        ["right"] = function()
          self.owner:select_next_note_column()
        end,
      }

      if handlers[key.name] then
        handlers[key.name]()
        return
      end
    end
    return key

  end


  vDialog.__init(self,...)

  -- variables --

  -- renoise.ViewBuilder
  self.vb = renoise.ViewBuilder()

  -- VR (main application)
  self.owner = args.owner

  self.active_tab = renoise.Document.ObservableNumber(2)


  -- notifiers --

  self.dialog_visible_observable:add_notifier(function()
  end)

  self.owner.prefs.advanced_settings:add_notifier(function()
    self:update_advanced_settings()
  end)

  self.owner.prefs.sort_mode:add_notifier(function()
    self:update_sort_mode()
  end)

  -- UI

  self.active_tab:add_notifier(function()
    self:update_tabs()
  end)

  -- initialize --

  --self:build()


end

-------------------------------------------------------------------------------

function VR_UI:update_sort_mode()
  TRACE("VR_UI:update_sort_mode()")

  local val = self.owner.prefs.sort_mode.value
  local custom = (val == xVoiceSorter.SORT_MODE.CUSTOM)
  --self.vb.views["remap_options"].visible = custom
  --self.vb.views["pitch_unique"].visible = (val == xVoiceSorter.SORT_MODE.UNIQUE)
  --self.vb.views["pitch_high_to_low"].visible = (val == xVoiceSorter.SORT_MODE.HIGH_TO_LOW)
  --self.vb.views["pitch_low_to_high"].visible = (val == xVoiceSorter.SORT_MODE.LOW_TO_HIGH)

  if custom then
    self.owner.prefs.advanced_settings.value = true
    self:update_advanced_settings()
  end

end

-------------------------------------------------------------------------------

function VR_UI:update_advanced_settings()
  TRACE("VR_UI:update_advanced_settings()")

  local val = self.owner.prefs.advanced_settings.value
  self.vb.views["advanced_settings"].visible = val

end

-------------------------------------------------------------------------------
--[[
function VR_UI:update_template_popup()
  TRACE("VR_UI:update_template_popup()")

  local t = self:get_templates()
  self.vb.views["template_popup"].items = t

end
-------------------------------------------------------------------------------

function VR_UI:update_tabs()
  TRACE("VR_UI:update_tabs()")

  local val = self.vb.views["tab_switcher"].value
  self.vb.views["tab_track"].visible = (val == 1)
  self.vb.views["tab_pitch"].visible = (val == 2)

end
]]

--------------------------------------------------------------------------------
-- import templates from the provided folder
-- @return table<string> or nil
--[[
function VR_UI:get_templates()
  TRACE("VR_UI:get_templates()")

  local str_path = self.owner.prefs.user_folder.value .. "templates/"
  --print("*** scan_template_folder - str_path",str_path)

  if not io.exists(str_path) then
    LOG(str_path,"path does not exist, returning")
    return
  end

  local filenames = os.filenames(str_path,"*.lua")
  for k,v in ipairs(filenames) do
    --print("filenames",k,v)
  end

  return filenames

end
]]

-------------------------------------------------------------------------------

function VR_UI:build()
  TRACE("VR_UI:build()")
  
  local vb = self.vb
  --local DIALOG_W = 150

  local vb_content = vb:row{
    margin = MARGIN,
    spacing = SPACING,
    vb:column{
      spacing = SPACING,
      vb:column{
        style = "group",
        margin = MARGIN,
        width = LEFT_PANEL_W,
        vb:chooser{
          width = LEFT_PANEL_W-20,
          items = VR.SCOPES,
          bind = self.owner.prefs.selected_scope,
        },
      },
      vb:column{
        style = "group",
        margin = MARGIN,
        width = LEFT_PANEL_W,
        vb:column{
          vb:row{
            vb:text{
              text = "Sorting",
              width = LABEL_W,
              --font = "bold",
            },
            vb:popup{
              width = LEFT_PANEL_W-56,
              items = xVoiceSorter.SORT_MODES,
              bind = self.owner.prefs.sort_mode,
            },
          },
          vb:row{
            vb:text{
              text = "Method",
              width = LABEL_W,
              --font = "bold",
            },
            vb:popup{
              width = LEFT_PANEL_W-56,
              items = xVoiceSorter.SORT_METHODS,
              bind = self.owner.prefs.sort_method,
            },
          },
        },
       
      },
      vb:row{
        width = LEFT_PANEL_W,
        vb:column{
          vb:button{
            text = "Sort",
            --color = SORT_COLOR,
            midi_mapping = VR.MIDI_MAPPING.SORT_NOTES,
            width = HALF_BUTTON_W,
            height = LARGE_BUTTON_H,
            notifier = function()
              self.owner:do_sort()
            end
          },

          vb:button{
            text = "Select",
            --color = cColor.adjust_brightness(SELECT_COLOR,0.1),
            tooltip = "Select the voice-run at the cursor position",
            midi_mapping = VR.MIDI_MAPPING.SELECT_RUN,
            width = HALF_BUTTON_W,
            height = LARGE_BUTTON_H,
            notifier = function()
              self.owner:select_voice_run()
            end
          },
        },
        vb:column{
          vb:button{
            text = "Merge",
            --color = SORT_COLOR,
            tooltip = "Merge note-columns in selected scope",
            midi_mapping = VR.MIDI_MAPPING.MERGE_NOTES,
            width = HALF_BUTTON_W,
            height = LARGE_BUTTON_H,
            notifier = function()
              -- TODO
              self.owner:do_merge()
            end
          },

          vb:row{
            vb:column{
              --vb:space{
                --height = LARGE_BUTTON_H/2
              --},
              vb:button{
                bitmap = "Icons/ArrowLeft.bmp",
                --color = SELECT_COLOR,
                tooltip = "Select the previous note-column in the pattern",
                midi_mapping = VR.MIDI_MAPPING.SELECT_PREV_NOTECOL,
                width = LARGE_BUTTON_H-5,
                height = LARGE_BUTTON_H,
                notifier = function()
                  self.owner:select_previous_note_column()
                end
              },
            },
            vb:column{
              vb:button{
                bitmap = "Icons/ArrowUp.bmp",
                --color = SELECT_COLOR,
                tooltip = "Select the previous voice-run relative to the cursor position",
                midi_mapping = VR.MIDI_MAPPING.SELECT_PREV_RUN,
                width = LARGE_BUTTON_H,
                height = LARGE_BUTTON_H/2,
                notifier = function()
                  self.owner:select_previous_voice_run()
                end
              },
              vb:button{
                bitmap = "Icons/ArrowDown.bmp",
                --color = SELECT_COLOR,
                tooltip = "Select the next voice-run relative to the cursor position",
                midi_mapping = VR.MIDI_MAPPING.SELECT_NEXT_RUN,
                width = LARGE_BUTTON_H,
                height = LARGE_BUTTON_H/2,
                notifier = function()                  
                  self.owner:select_next_voice_run()
                end
              },
            },
            vb:column{
              --vb:space{
                --height = LARGE_BUTTON_H/2
              --},
              vb:button{
                bitmap = "Icons/ArrowRight.bmp",
                --color = SELECT_COLOR,
                tooltip = "Select the next note-column in the pattern",
                midi_mapping = VR.MIDI_MAPPING.SELECT_NEXT_NOTECOL,
                width = LARGE_BUTTON_H-5,
                height = LARGE_BUTTON_H,
                notifier = function()
                  self.owner:select_next_note_column()
                end
              },
            },
          },
        },
      },

      vb:row{
        vb:checkbox{bind = self.owner.prefs.advanced_settings},
        vb:text{text = "Advanced settings"},
      },

    },
    vb:column{
      id = "advanced_settings",
      --style = "panel",
      spacing = SPACING,

      vb:row{
        spacing = SPACING,
        vb:column{
          width = LEFT_PANEL_W,
          spacing = SPACING,
          vb:column{ -- tool options
            style = "group",
            width = "100%",
            margin = MARGIN,
            --[[
            vb:row{
              vb:text{
                text = "Tool Settings",
                font = "bold",
              },
            },
            ]]
            vb:row{
              vb:checkbox{
                bind = self.owner.prefs.autostart,
              },  
              vb:text{
                text = "Display GUI on startup",
              },
            },
            vb:row{
              --width = "100%",
              vb:button{
                width = LEFT_PANEL_W-10,
                text = "Restore default settings",
                notifier = function()
                  local msg = "Are you sure you want to reset the tool to its original settings? This will include all sorting options and warning dialogs"
                  local choice = renoise.app():show_prompt("Reset settings?", msg, {"OK","Cancel"})
                  if (choice == "OK") then
                    self.owner.prefs:reset()
                  end
                end,
              },
            },
          },
          vb:column{
            style = "group",
            width = "100%",
            margin = 4,
            vb:row{
              vb:text{
                text = "Voice Collection",
                font = "bold",
              },
            },
            --[[
            vb:row{
              vb:checkbox{
                bind = self.owner.prefs.compact_mode,
              },
              vb:text{
                text = "Compact columns",
              },
            },
            vb:row{
              vb:checkbox{
                bind = self.owner.prefs.update_visible_columns,
              },
              vb:text{
                text = "Match visible cols.",
              },
            },
            ]]
            vb:row{
              vb:checkbox{bind = self.owner.prefs.split_at_note},
              vb:text{text = "Split at note"},
            },
            vb:row{
              vb:checkbox{bind = self.owner.prefs.split_at_note_change},
              vb:text{text = "Split at note-change"},
            },
            vb:row{
              vb:checkbox{bind = self.owner.prefs.split_at_instrument_change},
              vb:text{text = "Split at instr-change"},
            },
            vb:row{
              vb:checkbox{bind = self.owner.prefs.link_ghost_notes},
              vb:text{text = "Link ghost-notes"},
            },
            vb:row{
              vb:checkbox{bind = self.owner.prefs.link_glide_notes},
              vb:text{text = "Link glide-notes"},
            },
            vb:row{
              vb:checkbox{bind = self.owner.prefs.stop_at_note_off},
              vb:text{text = "Stop at note-off"},
            },
            vb:row{
              vb:checkbox{bind = self.owner.prefs.stop_at_note_cut},
              vb:text{text = "Stop at note-cut"},
            },
            vb:row{
              vb:checkbox{bind = self.owner.prefs.remove_orphans},
              vb:text{text = "Remove orphans"},
            },
          },
              
        },
        vb:column{
          width = LEFT_PANEL_W,
          spacing = SPACING,
          vb:column{ -- sort options
            style = "group",
            width = "100%",
            margin = 4,
            vb:row{
              vb:text{
                text = "Sort options",
                font = "bold",
              },
            },
            vb:row{
              vb:checkbox{bind = self.owner.prefs.unique_instrument},
              vb:text{text = "Sort instrument too"},
            },
            vb:row{
              vb:checkbox{bind = self.owner.prefs.safe_mode},
              vb:text{text = "Safe mode"},
            },
          },
          vb:column{ -- select options
            style = "group",
            width = "100%",
            margin = 4,
            vb:row{
              vb:text{
                text = "Select options",
                font = "bold",
              },
            },
            --vb:row{
              --vb:checkbox{bind = self.owner.prefs.maintain_selected_columns},
              --vb:text{text = "Maintain columns"},
            --},
            vb:row{
              vb:checkbox{bind = self.owner.prefs.select_all_columns},
              vb:text{text = "Select entire line"},
            },
            vb:row{
              vb:checkbox{bind = self.owner.prefs.toggle_line_selection},
              vb:text{text = "Toggling line-select"},
            },
          },
          vb:column{ -- output options
            style = "group",
            width = "100%",
            margin = 4,
            vb:row{
              vb:text{
                text = "Output options",
                font = "bold",
              },
            },
            vb:row{
              vb:checkbox{bind = self.owner.prefs.create_noteoffs},
              vb:text{text = "Create note-offs"},
            },
            vb:row{
              vb:checkbox{bind = self.owner.prefs.close_open_notes},
              vb:text{text = "Close open notes"},
            },
            vb:row{
              vb:checkbox{bind = self.owner.prefs.reveal_subcolumns},
              vb:text{text = "Reveal sub-columns"},
            },
          },
        },
      }
    },
  }

  self.vb_content = vb_content

  self:update_sort_mode()
  --self:update_template_popup()  
  self:update_advanced_settings()
  --self:update_tabs()

end

-------------------------------------------------------------------------------
-- prompt user for which note-columns to keep (when too many...)
-- @param callback_fn, function to invoke - using VR_Template as argument

function VR_UI:show_too_many_cols_dialog(callback_fn)
  TRACE("VR_UI:show_too_many_cols_dialog(callback_fn)",callback_fn)

  if self.dialog_too_many_cols 
    and self.dialog_too_many_cols.visible
  then
    self.dialog_too_many_cols:show()
    return
  end

  local required_cols = self.owner.xsorter.required_cols
  local template = VR_Template()
  template:set(required_cols)
  for k = 1,#template.entries do
    template.entries[k].active = (k <= 12) and true or false
  end

  --print("self.owner.safe_mode",self.owner.safe_mode)
  if not self.owner.safe_mode then
    callback_fn(template)
    return
  end

  local vb = self.vb
  local vb_template = vb:column{
    margin = 6,
    style = "group",
    width = "100%",
  }

  for k,v in ipairs(required_cols) do
    local instr = rns.instruments[v.instrument_value+1]
    local active = (k <= 12) and true or false
    vb_template:add_child(vb:row{
      vb:checkbox{
        value = active,
        notifier = function(val)
          local entries,indices = template:get_entries({
            note_value = v.note_value,
            instrument_value = v.instrument_value,
          })
          if not table.is_empty(indices) then
            for k,v in ipairs(indices) do
              template.entries[v].active = val
            end
          end
        end
      },
      vb:text{
        width = 50,
        text = ("%.2d - %s"):format(k,xNoteColumn.note_value_to_string(v.note_value))
      },
      vb:text{
        text = instr and instr.name or "N/A"
      },
    })
  end

  local content_view = vb:column{
    margin = 6,
    spacing = 6,
    vb:text{
      text =  "It's not possible to create more "
          .."\nthan 12 note-columns per track."
          .."\nPlease select which notes to keep:"
    },
    vb_template,
    vb:row{
      vb:button{
        height = LARGE_BUTTON_H,
        width = HALF_BUTTON_W,
        text = "OK",
        notifier = function()
          local entries,indices = template:get_entries({
            active = true,
          })
          if (#indices > 12) then
            renoise.app():show_warning("Please select no more than 12 columns")     
          else
            callback_fn(template)
            self.dialog_too_many_cols:close()
          end
        end
      },
      vb:button{
        height = LARGE_BUTTON_H,
        width = HALF_BUTTON_W,
        text = "Cancel",
        notifier = function()
          self.dialog_too_many_cols:close()
        end
      }
    }
  }

  self.dialog_too_many_cols = renoise.app():show_custom_dialog("VoiceRunner", content_view)

end
