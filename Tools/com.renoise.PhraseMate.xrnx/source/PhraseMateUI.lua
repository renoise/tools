--[[============================================================================
-- PhraseMateUI
============================================================================]]--

--[[--

PhraseMate (user-interface)


TODO

  * use vTabs for overall interface
    + implement toggleable feature
  * use vTable for selected batch targets
  * more detailed "update_submit_buttons" (e.g. "new" tab only when phrase exists)

--]]


--==============================================================================


class 'PhraseMateUI' (vDialog)

PhraseMateUI.UI_MARGIN = 4
PhraseMateUI.UI_SPACING = 3
PhraseMateUI.UI_WIDTH = 246
PhraseMateUI.UI_WIDTH_THIRD = PhraseMateUI.UI_WIDTH/100*25-PhraseMateUI.UI_MARGIN
PhraseMateUI.UI_WIDTH_TWOTHIRD = PhraseMateUI.UI_WIDTH/100*75-PhraseMateUI.UI_MARGIN
PhraseMateUI.UI_KEYMAP_LABEL_W = 90
PhraseMateUI.UI_KEYMAP_CTRL_W = 65
PhraseMateUI.UI_BATCH_LABEL_W = 45
PhraseMateUI.UI_BATCH_TYPE_W = 100
PhraseMateUI.UI_BATCH_OPERATOR_W = 45
PhraseMateUI.UI_BATCH_VALUE_W = 35
PhraseMateUI.UI_BATCH_APPLY_W = 55
PhraseMateUI.UI_BATCH_APPLY_H = 35
PhraseMateUI.ROW_STYLE_SELECTED = "body"
PhraseMateUI.ROW_STYLE_NORMAL = "plain"

--PhraseMateUI.UI_INSTR_LABEL_W = 45
PhraseMateUI.UI_INSTR_POPUP_W = 125
PhraseMateUI.BUTTON_SIZE = 22
PhraseMateUI.UI_PROGRESS_TXT = {"/","-","\\","|"}
PhraseMateUI.TAB_LABELS = {
  "New",
  "Collect",
  "Write",
  "Zxx",
  "Props",
  "Presets",
}
PhraseMateUI.TAB_NAMES = {
  "tab_new",
  "tab_input",
  "tab_output",
  "tab_realtime",
  "tab_props",
  "tab_presets",
}
PhraseMateUI.TABS = {
  NEW = 1,
  COLLECT = 2,
  WRITE = 3,
  ZXX = 4,
  PROPS = 5,
  PRESETS = 6,
}


--------------------------------------------------------------------------------

function PhraseMateUI:__init(...)
  TRACE("PhraseMateUI:__init()")

  self.prefs = renoise.tool().preferences

  local args = cLib.unpack_args(...)
  assert(type(args.owner)=="PhraseMate","Expected 'owner' to be a class instance")

  --- PhraseMate
  self.owner = args.owner

  --- int, position of PhraseMateUI.UI_PROGRESS_TXT
  self.progress_txt_count = 1

  --- table
  self.default_button_color = nil

  --- vTable
  self.vtable_batch = nil

  --- (vSelection)
  self.vtable_selection = vSelection()

  self.batch_toggle = nil

  --- renoise.ViewBuilder
  --self.vb
  --self.dialog
  --self.dialog_content

  self.phrase_props = {}

  self.export_dialog = nil

  vDialog.__init(self,...)

  -- initialize 
  for k,v in ipairs(xPhrase.DOC_PROPS) do
    --print("k,v",k,rprint(v))
    table.insert(self.phrase_props,v.title)
  end

  -- notifiers ------------------------

  self.vtable_selection.index_observable:add_notifier(function()
    print(">>> self.vtable_selection.index_observable fired...")
  end)

  self.prefs.create_keymappings:add_notifier(self.update_keymap,self)


end

-------------------------------------------------------------------------------
-- vDialog
-------------------------------------------------------------------------------

function PhraseMateUI:create_dialog()
  TRACE("PhraseMateUI:create_dialog()")

  return self.vb:column{
    self.vb_content,
  }

end

-------------------------------------------------------------------------------

function PhraseMateUI:show()
  TRACE("PhraseMateUI:show()")

  vDialog.show(self)

  self:show_tab()
  self:update_keymap()
  self:update_realtime()
  self:update_instruments()
  self:update_submit_buttons()

end

-------------------------------------------------------------------------------

function PhraseMateUI:build()
  TRACE("PhraseMateUI:build()")
  
  local vb = self.vb




  --[[
  local properties_toggle = vArrowButton{
    enabled = self.prefs.input_show_properties_panel.value,
    vb = vb,
  }
  properties_toggle.enabled_observable:add_notifier(function()
    local val = properties_toggle.enabled
    vb.views["properties_panel"].visible = val
    self.prefs.input_show_collection_panel.value = val
  end)
  ]]

  self.vb_content = vb:column{
    margin = PhraseMateUI.UI_MARGIN,
    spacing = 4,
    
    vb:column{
      id = "group_phrase",
      width = "100%",
      vb:column{
        --width = PhraseMateUI.UI_WIDTH+6,
        style = "group",
        --margin = 3,
        margin = PhraseMateUI.UI_MARGIN,

        vb:row{
          vb:column{
            vb:popup{
              id = "ui_realtime_phrase_popup",
              items = {"No phrase selected"},
              width = PhraseMateUI.UI_WIDTH-52,
              midi_mapping = PhraseMate.MIDI_MAPPING.SELECT_PHRASE_IN_INSTR,
              notifier = function(idx)
                local phrase_idx = idx-1
                if rns.selected_instrument.phrases[phrase_idx] 
                  or (phrase_idx == 0)
                then
                  rns.selected_phrase_index = phrase_idx
                else
                  vb.views["ui_realtime_phrase_popup"].value = rns.selected_phrase_index+1
                end
              end
            },
            vb:row{ -- prev/next/mode
              vb:button{
                id = "ui_realtime_prev",
                text = "Prev",
                tooltip = "Select the previous phrase",
                width = 36,
                height = PhraseMateUI.BUTTON_SIZE,
                midi_mapping = PhraseMate.MIDI_MAPPING.PREV_PHRASE_IN_INSTR,
                notifier = function()
                  self.owner:invoke_task(xPhraseManager.select_previous_phrase())
                end
              },
              vb:button{
                id = "ui_realtime_next",
                text = "Next",
                tooltip = "Select the next phrase",
                width = 36,
                height = PhraseMateUI.BUTTON_SIZE,
                midi_mapping = PhraseMate.MIDI_MAPPING.NEXT_PHRASE_IN_INSTR,
                notifier = function()
                  self.owner:invoke_task(xPhraseManager.select_next_phrase())
                end
              },
              vb:space{
                width = 6,
              },
              vb:switch{
                id = "ui_realtime_playback_mode",
                width = 100,
                tooltip = "Choose the phrase playback-mode",
                midi_mapping = PhraseMate.MIDI_MAPPING.SET_PLAYBACK_MODE,
                height = PhraseMateUI.BUTTON_SIZE,
                items = PhraseMate.PLAYBACK_MODES,
                notifier = function(idx)
                  rns.selected_instrument.phrase_playback_mode = idx
                end
              },
            },
          },
          vb:column{
            vb:button{
              id = "ui_delete_phrase",
              text = "−",
              tooltip = "Delete the selected phrase",
              width = PhraseMateUI.BUTTON_SIZE,
              midi_mapping = PhraseMate.MIDI_MAPPING.DELETE_PHRASE,
              notifier = function()
                local rslt,err = self.owner:delete_phrase()
                if err then
                  renoise.app():show_warning(err)
                end
              end,
            },
          },

          vb:column{
            vb:button{
              id = "ui_insert_phrase",
              text = "+",
              tooltip = "Insert a new phrase",
              width = PhraseMateUI.BUTTON_SIZE,
              midi_mapping = PhraseMate.MIDI_MAPPING.INSERT_PHRASE,
              notifier = function()
                local rslt,err = self.owner:insert_phrase()
                if err then
                  renoise.app():show_warning(err)
                end
              end,
            },
            vb:button{
              text = "?",
              tooltip = "Visit github for documentation and source code",
              width = PhraseMateUI.BUTTON_SIZE,
              notifier = function()
                renoise.app():open_url("https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.PhraseMate.xrnx")
              end
            },

          },
        },
      },
    },
    vb:switch{
      width = PhraseMateUI.UI_WIDTH,
      height = PhraseMateUI.BUTTON_SIZE,
      items = PhraseMateUI.TAB_LABELS,
      bind = self.prefs.active_tab_index,
      notifier = function()
        self:show_tab()
      end
    },
    self:build_input_tab(),
    self:build_output_tab(),
    self:build_realtime_tab(),
    self:build_props_tab(),
    self:build_preset_tab(),
    self:build_new_tab(),
    --vb:button{
      --text = "remove trace statements",
      --notifier = function()
        --cDebug.remove_trace_statements()
      --end
    --}

  }

end

-------------------------------------------------------------------------------

function PhraseMateUI:build_props_tab()

  local vb = self.vb

  self.batch_toggle = vArrowButton{
    enabled = self.prefs.props_batch_apply.value,
    vb = vb,
  }
  self.batch_toggle.enabled_observable:add_notifier(function()
    local val = self.batch_toggle.enabled
    self.vtable_batch.view.visible = val
    self.prefs.props_batch_apply.value = val
  end)

  self.vtable_batch = vTable{
    id = "vTable_batch",
    vb = vb,
    visible = self.batch_toggle.enabled,
    width = PhraseMateUI.UI_WIDTH-1,
    row_height = 17,
    --cell_style = "group",
    cell_style = "invisible",
    column_defs = {
      {
        key = "CHECKED",
        col_width=20, 
        col_type=vTable.CELLTYPE.CHECKBOX,
        notifier=function(elm,checked)
          --print("CHECKED - elm,checked",elm,checked)          
          --print("CHECKED - elm[vDataProvider.ID]",elm[vDataProvider.ID])          
          local item = elm.owner:get_item_by_id(elm[vDataProvider.ID])
          if item then
            item.CHECKED = checked
          end
        end
      },
      {
        key = "NAME",
        col_type=vTable.CELLTYPE.TEXT,
        col_width = 150, 
        notifier = function(elm)
          --print("elm",rprint(elm))
          local item = elm.owner:get_item_by_id(elm[vDataProvider.ID])
          if item then
            rns.selected_phrase_index = item.INDEX
          end
        end
      },
      {
        key = "VALUE",
        col_type=vTable.CELLTYPE.STRING,
        col_width = 60, 
      },
    },
    header_defs = {
      CHECKED = {
        data = true,
        col_type=vTable.CELLTYPE.CHECKBOX, 
        active=true, 
        notifier=function(elm,checked)
          self:set_batch_checked_state(elm,checked)
        end
      },
      NAME = {
        data = "De/select all",
      },
      VALUE = {
        data = "Value",
      }
    },
    data = {}
  }


  local property_w = PhraseMateUI.UI_WIDTH - (PhraseMateUI.UI_WIDTH_THIRD + PhraseMateUI.UI_BATCH_APPLY_W + 7)
  local editfield_w = PhraseMateUI.UI_WIDTH - (PhraseMateUI.UI_BATCH_APPLY_W + 15)

  self.editfield = vEditField{
    vb = vb,
    id = "vEditField",
    width = editfield_w,
    value = xPhrase.DOC_PROPS[1],
  }

  return vb:column{ 
    id = "tab_props",
    visible = false,
    
    spacing = PhraseMateUI.UI_SPACING,
    vb:column{
      style = "group",
      width = PhraseMateUI.UI_WIDTH,
      vb:horizontal_aligner{
        mode = "justify",
        width = "100%",
        margin = PhraseMateUI.UI_MARGIN,
        vb:row{
          vb:column{
            vb:row{
              vb:text{
                text = "Modify",
                font = "bold",
                width = PhraseMateUI.UI_WIDTH_THIRD,
              },
              vb:popup{
                id = "ui_phrase_props",
                items = self.phrase_props,
                width = property_w,
                --width = PhraseMateUI.UI_BATCH_TYPE_W,
                notifier = function(idx)
                  --[[
                  local phrase = rns.selected_phrase
                  if phrase then
                    local cval = table.rcopy(xPhrase.DOC_PROPS[idx])
                    cval.value = phrase[cval.name]
                    self.editfield:set_value(cval)
                  end
                  ]]
                  self:update_editfield()
                  self:update_batch_table()
                end
              },
            },
            vb:row{
              vb:space{
                width = 7,
              },
              self.editfield.view,
            }
          },
          vb:button{
            text = "Apply",
            width = PhraseMateUI.UI_BATCH_APPLY_W,
            height = PhraseMateUI.UI_BATCH_APPLY_H,
            notifier = function()
              self:apply_batch_properties()
            end
          },
        },

      },
    },
    vb:horizontal_aligner{
      mode = "justify",
      vb:row{
        self.batch_toggle.view,
        vb:text{
          text = "Batch-apply",
        }
      },
      vb:row{
        vb:checkbox{
          visible = false,
          notifier = function()
            
          end
        },
        vb:text{
          text = "⚠ Some issue",
        }
      },
    },
    self.vtable_batch.view,

  }

end

--------------------------------------------------------------------------------

function PhraseMateUI:build_input_tab()

  local vb = self.vb

  local collection_toggle = vArrowButton{
    enabled = self.prefs.input_show_collection_panel.value,
    vb = vb,
  }
  collection_toggle.enabled_observable:add_notifier(function()
    local val = collection_toggle.enabled
    vb.views["collection_panel"].visible = val
    self.prefs.input_show_collection_panel.value = val
  end)


  return vb:column{ 
    id = "tab_input",
    visible = false,
    width = "100%",
    --margin = 6,
    spacing = PhraseMateUI.UI_SPACING,
    vb:column{
      style = "group",
      margin = PhraseMateUI.UI_MARGIN,
      width = "100%",
      vb:row{
        collection_toggle.view,
        vb:text{
          text = "Settings",
          font = "bold",
        },
      },
      vb:column{
        id = "collection_panel",
        visible = self.prefs.input_show_collection_panel.value,
        vb:row{
          tooltip = "Decide how often to create undo points while processing:"
                .."\nDisabled - perform processing in a single step"
                .."\nPattern - create an undo point once per pattern"
                .."\nPattern-Track - create undo point per track in pattern"
                .."\n\nEnable this feature if you experience warning dialogs"
                .."\ncomplaining that 'script is taking too long'",
          vb:text{
            text = "Sliced processing",
            width = PhraseMateUI.UI_KEYMAP_LABEL_W,
          },
          vb:popup{
            width = 80,
            items = PhraseMate.SLICE_MODES,
            bind = self.prefs.process_slice_mode,
          },
        },
        vb:row{
          tooltip = "During collection of phrases, skip phrases without content",
          vb:checkbox{
            bind = self.prefs.input_include_empty_phrases,
          },
          vb:text{
            text = "Include empty phrases"
          },
        },
        vb:row{
          tooltip = "During collection of phrases, detect if phrase is duplicate and skip",
          vb:checkbox{
            bind = self.prefs.input_include_duplicate_phrases,
          },
          vb:text{
            text = "Include duplicate phrases"
          },
        },
        vb:row{
          tooltip = "After collecting notes, insert a phrase trigger-note in their place",
          vb:checkbox{
            bind = self.prefs.input_replace_collected,
          },
          vb:text{
            text = "Replace notes with phrase"
          },
        },
      },
    },

    vb:row{
      margin = PhraseMateUI.UI_MARGIN,
      style = "group",
      width = "100%",
      vb:text{
        text = "Scope",
        font = "bold",
        width = PhraseMateUI.UI_WIDTH_THIRD
      },
      vb:chooser{
        width = PhraseMateUI.UI_WIDTH_TWOTHIRD,
        items = PhraseMate.INPUT_SCOPES,
        bind = self.prefs.input_scope,
      },
    },
    vb:column{
      style = "group",
      margin = PhraseMateUI.UI_MARGIN,
      width = "100%",
      vb:row{
        vb:text{
          text = "Source",
          width = PhraseMateUI.UI_WIDTH_THIRD,
        },
        vb:popup{
          id = "ui_source_popup",
          items = self.owner:get_source_instr(),
          value = self.prefs.input_source_instr.value,
          width = PhraseMateUI.UI_INSTR_POPUP_W,
          notifier = function(idx)
            if (idx > #PhraseMate.UI_SOURCE_ITEMS) then
              self.prefs.input_source_instr.value = #PhraseMate.UI_SOURCE_ITEMS+1
            else
              self.prefs.input_source_instr.value = idx
            end
          end
        },
      },
      vb:row{
        vb:text{
          text = "Target",
          width = PhraseMateUI.UI_WIDTH_THIRD,
        },
        vb:popup{
          id = "ui_target_popup",
          items = self.owner:get_target_instr(),
          value = self.prefs.input_target_instr.value,
          width = PhraseMateUI.UI_INSTR_POPUP_W,
          notifier = function(idx)
            if (idx > #PhraseMate.UI_TARGET_ITEMS) then
              self.prefs.input_target_instr.value = #PhraseMate.UI_TARGET_ITEMS+1
            else
              self.prefs.input_target_instr.value = idx
            end
          end
        },
      },
    },
    vb:button{
      id = "ui_input_submit",
      text = "",
      width = "100%",
      height = PhraseMateUI.BUTTON_SIZE,
      notifier = function()
        if self.owner.process_slicer and self.owner.process_slicer:running() then
          self.owner.process_slicer:stop()
        else
          self.owner:invoke_task(self.owner:collect_phrases())
        end
      end
    },
  }

end

--------------------------------------------------------------------------------

function PhraseMateUI:build_output_tab()

  local vb = self.vb
  return vb:column{ 
    id = "tab_output",
    visible = false,
    width = "100%",
    spacing = PhraseMateUI.UI_SPACING,
    vb:column{ 
      style = "group",
      margin = 3,
      width = "100%",
      vb:row{
        tooltip = "Use selected note-column as trigger",
        vb:checkbox{
          bind = self.prefs.output_use_note_column,
        },
        vb:text{
          text = "Use selected note-column as trigger",
        }
      },

      vb:row{
        tooltip = "When writing to a selection, this option determines if the output is written relative to the top of the selection, or the top of the pattern",
        vb:checkbox{
          bind = self.prefs.anchor_to_selection
        },
        vb:text{
          text = "Anchor to selection",
        }
      },
      vb:row{
        tooltip = "When source phrase is shorter than pattern/selection, repeat in order to fill",
        vb:checkbox{
          bind = self.prefs.cont_paste
        },
        vb:text{
          text = "Continuous paste",
        }
      },
      vb:row{
        tooltip = "Skip note-columns when they are muted in the phrase (and clear pattern, unless mix-paste is enabled)",
        vb:checkbox{
          bind = self.prefs.skip_muted
        },
        vb:text{
          text = "Skip muted columns",
        }
      },
      vb:row{
        tooltip = "Show additional note columns if required by source phrase",
        vb:checkbox{
          bind = self.prefs.expand_columns
        },
        vb:text{
          text = "Expand columns",
        }
      },
      vb:row{
        tooltip = "Show sub-columns (VOL/PAN/DLY/FX) if required by source phrase",
        vb:checkbox{
          bind = self.prefs.expand_subcolumns
        },
        vb:text{
          text = "Expand sub-columns",
        }
      },
      vb:row{
        tooltip = "Attempt to keep existing content when producing output (works the same as Mix-Paste in the advanced edit panel)",
        vb:checkbox{
          bind = self.prefs.mix_paste
        },
        vb:text{
          text = "Mix-Paste",
        }
      },
    },
    vb:column{
      width = "100%",
      vb:button{
        id = "ui_output_to_selection",
        text = "Write to selection",
        width = "100%",
        height = PhraseMateUI.BUTTON_SIZE,
        notifier = function()
          self.owner:apply_to_selection()
        end
      },
      vb:button{
        id = "ui_output_to_track",
        text = "Write to track",
        width = "100%",
        height = PhraseMateUI.BUTTON_SIZE,
        notifier = function()
          self.owner:apply_to_track()
        end
      },
    },
  }
end

--------------------------------------------------------------------------------

function PhraseMateUI:build_realtime_tab()

  local vb = self.vb
  return vb:column{ 
    id = "tab_realtime",
    visible = false,
    width = "100%",
    spacing = PhraseMateUI.UI_SPACING,
    vb:column{
      style = "group",
      margin = 3,
      width = "100%",
      vb:row{
        vb:checkbox{
          bind = self.prefs.zxx_mode
        },
        vb:text{
          text = "(Active) Monitor changes to pattern",
        },
      },
      vb:row{
        vb:checkbox{
          --bind = self.prefs.zxx_mode
          active = false,
        },
        vb:text{
          text = "TODO Applies to selected instr. only",
        },
      },
      vb:row{
        vb:checkbox{
          bind = self.prefs.zxx_prefer_local,
          active = false,
        },
        vb:text{
          text = "TODO Prefer Zxx in local note-column ",

        },
      },
      vb:column{
        margin = PhraseMateUI.UI_MARGIN,
        vb:text{
          text = [[
Inserts Zxx commands into the first
available note/effect column, when  
the following conditions are met:
* Phrase is set to program playback
* Edit-mode is enabled in Renoise
* Instrument is selected (optional)]],
          font = "italic",
        },
      },
    },
  }

end

--------------------------------------------------------------------------------

function PhraseMateUI:build_preset_tab()

  local vb = self.vb

  local vpath_output = vPathSelector{
    id = "vPathSelector",
    vb = vb,
    width = PhraseMateUI.UI_WIDTH_TWOTHIRD - (40),
    path_token = "⚠ Please select a path!",
    path = self.prefs.output_folder.value,
    notifier = function(val)
      --print(">>> vpath_output.notifier...",val)
      self.prefs.output_folder.value = val
    end,
  }

  return vb:column{ 
    id = "tab_presets",
    visible = false,
    width = "100%",
    spacing = PhraseMateUI.UI_SPACING,
    vb:column{ 
      width = "100%",
      spacing = PhraseMateUI.UI_SPACING,
      vb:row{
        style = "group",
        width = PhraseMateUI.UI_WIDTH,
        margin = PhraseMateUI.UI_MARGIN,
        vb:text{
          text = "Import",
          font = "bold",
          width = PhraseMateUI.UI_WIDTH_THIRD,
        },
        vb:column{
          width = PhraseMateUI.UI_WIDTH_TWOTHIRD,
          vb:button{
            text = "Import from file",
            width = "100%",
            height = PhraseMateUI.BUTTON_SIZE,
            notifier = function()
              local file_list = renoise.app():prompt_for_multiple_filenames_to_read({"*.xrnz"},"Import presets")
              self:import_presets(file_list)
            end
          },
          vb:button{
            text = "Import from folder",
            width = "100%",
            height = PhraseMateUI.BUTTON_SIZE,
            notifier = function()
              local str_path = renoise.app():prompt_for_path("Locate preset folder")
              local file_list = cFilesystem.list_files(str_path,{"*.xrnz"})
              self:import_presets(file_list)
            end
          },
          vb:text{
            text = "Note that settings in 'New' applies"
                .."\nto any imported phrases",
            font = "italic",
          }
        },
      },
      vb:column{
        style = "group",
        margin = PhraseMateUI.UI_MARGIN,
        width = PhraseMateUI.UI_WIDTH,
        vb:row{
          vb:text{
            text = "Export",
            font = "bold",
            width = PhraseMateUI.UI_WIDTH_THIRD,
          },

          vb:column{
            width = PhraseMateUI.UI_WIDTH_TWOTHIRD,
            vb:row{
              vb:text{
                text = "Path",
                width = 40,
              },
              vpath_output.view,
              --self.vpath_output.browse_button,
            },

            vb:button{
              text = "Export preset",
              width = "100%",
              height = PhraseMateUI.BUTTON_SIZE,
              notifier = function()
                local indices = {rns.selected_phrase_index}
                self:export_presets(indices)
              end
            },
            vb:button{
              text = "Export (multiple)",
              width = "100%",
              height = PhraseMateUI.BUTTON_SIZE,
              notifier = function()
                self:show_export_dialog()
              end
            },

            vb:column{
              --style = "group",
              vb:row{
                vb:checkbox{
                  value = self.prefs.overwrite_on_export.value,
                  notifier = function(val)
                    self.prefs.overwrite_on_export.value = val
                  end,
                },
                vb:text{
                  text = "Overwrite existing presets"
                }
              },
              vb:row{
                vb:checkbox{
                  value = self.prefs.use_instr_subfolder.value,
                  notifier = function(val)
                    self.prefs.use_instr_subfolder.value = val
                  end,
                },
                vb:text{
                  text = "Put in folder named after instr."
                }
              },
              vb:row{
                vb:checkbox{
                  value = self.prefs.prefix_with_index.value,
                  notifier = function(val)
                    self.prefs.prefix_with_index.value = val
                  end,
                },
                vb:text{
                  text = "Prefix with phrase index"
                }
              },
            },

          },
        },
      },
    },
  }
  
end

--------------------------------------------------------------------------------

function PhraseMateUI:build_new_tab()

  local vb = self.vb
  return vb:column{ 
    id = "tab_new",
    visible = false,
    width = "100%",
    spacing = PhraseMateUI.UI_SPACING,
    vb:column{
      style = "group",
      margin = PhraseMateUI.UI_MARGIN,
      width = "100%",
      vb:column{
        width = "100%",
        vb:text{
          text = "New Phrase settings",
          font = "bold",
        },
        vb:text{
          text = "Applies to newly created phrases, as a result"
                .."\nof importing, collecting or creating phrases)",
          font = "italic",
        },

        vb:space{
          height = 6,
        },

      },
      vb:column{
        id = "properties_panel",
        vb:row{
          tooltip = "Choose whether to enable loop for new phrases",
          vb:checkbox{
            bind = self.prefs.input_loop_phrases,
          },
          vb:text{
            text = "Enable loop"
          },
        },
        vb:row{
          tooltip = "Choose whether to create keymappings for the new phrases",
          vb:checkbox{
            bind = self.prefs.create_keymappings,
          },
          vb:text{
            text = "Create keymap"
          },
        },
        vb:column{
          id = "keymap_options",
          vb:row{
            tooltip = "Choose how many semitones each mapping should span",
            vb:space{
              width = 20,
            },
            vb:text{
              text = "Semitone range",
              width = PhraseMateUI.UI_KEYMAP_LABEL_W,
            },
            vb:valuebox{
              id = "ui_create_keymap_range",
              width = PhraseMateUI.UI_KEYMAP_CTRL_W,
              min = 1,
              max = 119,
              bind = self.prefs.create_keymap_range,
            }
          },
          vb:row{
            tooltip = "Choose starting note for the new mappings",
            vb:space{
              width = 20,
            },
            vb:text{
              text = "Starting offset",
              width = PhraseMateUI.UI_KEYMAP_LABEL_W,
            },
            vb:valuebox{
              id = "ui_create_keymap_offset",
              width = PhraseMateUI.UI_KEYMAP_CTRL_W,
              min = 0,
              max = 119,
              bind = self.prefs.create_keymap_offset,
              tostring = function(val)
                return xNoteColumn.note_value_to_string(math.floor(val))
              end,
              tonumber = function(str)
                return xNoteColumn.note_string_to_value(str)
              end,
            },
          },
        },
      },


    },

  }
end


-------------------------------------------------------------------------------
-- Class methods
--------------------------------------------------------------------------------

function PhraseMateUI:update_keymap()
  TRACE("PhraseMateUI:update_keymap()")

  local vb = self.vb
  local active = self.prefs.create_keymappings.value
  vb.views["ui_create_keymap_range"].active = active
  vb.views["ui_create_keymap_offset"].active = active

end

--------------------------------------------------------------------------------
-- invoked when instrument/phrase is changed

function PhraseMateUI:update_realtime()
  TRACE("PhraseMateUI:update_realtime()")

  local vb = self.vb
  local instr = rns.selected_instrument
  local instr_has_phrases = (#instr.phrases > 0) and true or false
  vb.views["ui_realtime_playback_mode"].value = instr.phrase_playback_mode
  vb.views["ui_realtime_prev"].active = instr_has_phrases and xPhraseManager.can_select_previous_phrase()
  vb.views["ui_realtime_next"].active = instr_has_phrases and xPhraseManager.can_select_next_phrase()
  vb.views["ui_realtime_phrase_popup"].items = PhraseMateUI.get_phrase_list("No phrase selected",true)
  vb.views["ui_realtime_phrase_popup"].value = instr_has_phrases and rns.selected_phrase_index+1 or 1
  vb.views["ui_delete_phrase"].active = (instr_has_phrases and rns.selected_phrase_index > 0) and true or false
  --vb.views["ui_insert_phrase"].active = (instr_has_phrases and rns.selected_phrase_index > 0) and true or false
  
  self:update_props()
  --self:update_batch_table_styling()

end

--------------------------------------------------------------------------------

function PhraseMateUI:show_tab()
  TRACE("PhraseMateUI:show_tab()")

  --print(">>> self.prefs.active_tab_index.value",self.prefs.active_tab_index.value)

  local vb = self.vb
  local tabs = {}
  for k,v in ipairs(PhraseMateUI.TAB_NAMES) do
    --print("v",k,v)
    table.insert(tabs,vb.views[v])
  end

  for k,v in ipairs(tabs) do
    v.visible = (self.prefs.active_tab_index.value == k) and true or false
    if v.visible then
      if (self.prefs.active_tab_index.value == PhraseMateUI.TABS.COLLECT) then
        --self:update_realtime()
      elseif (self.prefs.active_tab_index.value == PhraseMateUI.TABS.WRITE) then

      elseif (self.prefs.active_tab_index.value == PhraseMateUI.TABS.ZXX) then
        self:update_realtime()
      elseif (self.prefs.active_tab_index.value == PhraseMateUI.TABS.PROPS) then
        self:update_props()
      end
    end
  end

end

--------------------------------------------------------------------------------
-- update submit buttons during processing (show progress/ability to cancel)

function PhraseMateUI:update_submit_buttons()
  TRACE("PhraseMateUI:update_submit_buttons()")

  local vb = self.vb
  local input_submit = vb.views["ui_input_submit"]
  local output_to_selection = vb.views["ui_output_to_selection"]
  local output_to_track = vb.views["ui_output_to_track"]

  if (self.prefs.active_tab_index.value == PhraseMateUI.TABS.COLLECT) then
    input_submit.text = self.owner.process_slicer and self.owner.process_slicer:running()
      and ("Collecting %s [Cancel]"):format(PhraseMateUI.UI_PROGRESS_TXT[self.progress_txt_count])
      or "Collect phrases"

  elseif (self.prefs.active_tab_index.value == PhraseMateUI.TABS.WRITE) then
    local running = self.owner.process_slicer and self.owner.process_slicer:running()
    output_to_selection.active = not running
    output_to_track.active = not running

  end


end

--------------------------------------------------------------------------------
---

function PhraseMateUI:update_editfield()
  TRACE("PhraseMateUI:update_editfield()")

  local phrase = rns.selected_phrase
  if phrase then
    local prop_idx = self.vb.views["ui_phrase_props"].value
    local cval = table.rcopy(xPhrase.DOC_PROPS[prop_idx])
    --local cval = table.rcopy()
    cval.value = phrase[cval.name]
    self.editfield:set_value(cval)
  else
    self.editfield:update()
  end
  self.editfield.active = phrase and true or false

end

--------------------------------------------------------------------------------

function PhraseMateUI:update_batch_table()
  TRACE("PhraseMateUI:update_batch_table()")

  local data = self:get_vtable_phrase_data()
  --print("data",rprint(data))

  local header_checked = true
  --print(">>> self.vtable_batch.visible",self.vtable_batch.visible)
  self.vtable_batch:set_header_def("CHECKED","value",header_checked)
  self.vtable_batch:update()

  self.vtable_batch.data = data
  self.vtable_batch.visible = self.batch_toggle.enabled

  self:update_batch_table_styling()

  --print("self.vtable.data",rprint(self.vtable.data))

end



--------------------------------------------------------------------------------
-- decorate selection rows (visible on next update)

function PhraseMateUI:update_batch_table_styling()
  TRACE("PhraseMateUI:update_batch_table_styling()")

  for k,v in ipairs(self.vtable_batch.data) do
    --print(">>> v.INDEX",v.INDEX)
    if (v.INDEX == rns.selected_phrase_index) then
      self.vtable_selection:set_index(v.INDEX)
      if (table.find(self.vtable_selection.indices,v.INDEX)) then
        v.__row_style = PhraseMateUI.ROW_STYLE_SELECTED
      else
        v.__row_style = PhraseMateUI.ROW_STYLE_NORMAL
      end
      self.vtable_batch:request_update()
      break
    end
  end


end

--------------------------------------------------------------------------------

function PhraseMateUI:update_props()
  TRACE("PhraseMateUI:update_props()")

  --print(">>> self.prefs.active_tab_index.value,PhraseMateUI.TABS.PROPS",self.prefs.active_tab_index.value,PhraseMateUI.TABS.PROPS)

  if (self.prefs.active_tab_index.value ~= PhraseMateUI.TABS.PROPS) then
    return
  end

  self:update_editfield()
  self:update_batch_table()

end

--------------------------------------------------------------------------------

function PhraseMateUI:set_batch_checked_state(elm,checked)

  self.vtable_batch.header_defs.CHECKED.data = checked
  for k,v in ipairs(self.vtable_batch.data) do
    v.CHECKED = checked
  end
  self.vtable_batch:request_update()

end

--------------------------------------------------------------------------------

function PhraseMateUI:update_instruments()
  TRACE("PhraseMateUI:update_instruments()")

  --if not vb then return end
  local vb = self.vb

  vb.views["ui_source_popup"].items = self.owner:get_source_instr()
  vb.views["ui_target_popup"].items = self.owner:get_target_instr()
  if (self.prefs.input_target_instr.value < 3) then
    vb.views["ui_target_popup"].value = self.prefs.input_target_instr.value
  end

  local active = self.prefs.create_keymappings.value
  vb.views["ui_create_keymap_range"].active = active
  vb.views["ui_create_keymap_offset"].active = active

end

--------------------------------------------------------------------------------

function PhraseMateUI:show_export_dialog()
  TRACE("PhraseMateUI:show_export_dialog()")

  --if (self.prefs.output_folder.value == "") then
    --return false,"Please select a valid output path"
  --end

  if not self.export_dialog then
    self.export_dialog = PhraseMateExportDialog{
      dialog_title = "PhraseMate: Export presets",
      owner = self,
    }
  end

  self.export_dialog:show()

end


--------------------------------------------------------------------------------

function PhraseMateUI:import_presets(file_list)

  if not file_list or table.is_empty(file_list) then
    return
  end

  local rslt,err = self.owner:import_presets(file_list)
  if err then
    renoise.app():show_warning(err)
  else
    local str_list = "\n"
    for k,v in ipairs(file_list) do
      str_list = str_list .. "\n"..cFilesystem.get_raw_filename(v) 
    end
    renoise.app():show_message("The following phrases were imported:"..str_list)
  end

end

--------------------------------------------------------------------------------
-- provide feedback during export process

function PhraseMateUI:export_presets(indices)
  TRACE("PhraseMateUI:export_presets(indices)",indices)

  --print("indices",rprint(indices))

  local rslt,err = self.owner:export_presets(indices)
  --print("rslt,err",rslt,err)
  if err then
    if (err == xPhrase.ERROR.FILE_EXISTS) then
      local msg = "Do you want to overwrite the existing file(s)?\n\n%s"
      local prefix = self.prefs.prefix_with_index.value
      --local folder = self.prefs.output_folder.value
      local phrase_idx = prefix and indices[1]
      local phrase = rns.selected_instrument.phrases[phrase_idx or rns.selected_phrase_index]
      local preset_filepath = xPhrase.get_preset_filepath("",phrase,phrase_idx)
      local choice = renoise.app():show_prompt("Overwrite files",msg:format(preset_filepath),{"OK","Cancel"})
      if (choice == "OK") then
        self.owner:export_presets(indices,true)
      end
    elseif (err == xPhrase.ERROR.MISSING_PHRASE) then
      local msg = "The instrument contains no phrases, or no phrase was selected"
      renoise.app():show_warning(msg)
    elseif (err == xPhrase.ERROR.MISSING_INSTRUMENT) then
      local msg = "Can't export - no instrument is selected"
      renoise.app():show_warning(msg)
    else
      renoise.app():show_warning(err)
    end
  end

end

--------------------------------------------------------------------------------
-- get list of phrases, formatted for display in vTable
-- @return table

function PhraseMateUI:get_vtable_phrase_data()
  TRACE("PhraseMateUI:get_vtable_phrase_data()")

  local data = {}
  local phrase_list = PhraseMateUI.get_phrase_list(nil,nil,false)
  for k,v in ipairs(phrase_list) do
    table.insert(data,{
      NAME = v,
      CHECKED = true,
      INDEX = k,
      VALUE = tostring(self:get_phrase_property(k)),
    })
  end

  return data

end

--------------------------------------------------------------------------------
-- get the property (value) of the currently selected property type
-- (as in: selected by the editfield component)

function PhraseMateUI:get_phrase_property(phrase_idx)
  TRACE("PhraseMateUI:get_phrase_property(phrase_idx)",phrase_idx)

  local phrase = rns.selected_instrument.phrases[phrase_idx]
  if not phrase then
    error("Could not locate phrase")
  end

  local vb_popup = self.vb.views["ui_phrase_props"]
  local prop_name = xPhrase.DOC_PROPS[vb_popup.value].name

  -- TODO decorate value - for example, when number is enum 
  -- or has a tostring converter

  local enums = xPhrase.DOC_PROPS[vb_popup.value].value_enums
  local tostr_fn = xPhrase.DOC_PROPS[vb_popup.value].value_tostring

  if enums then
    return enums[phrase[prop_name]]
  elseif tostr_fn then
    return tostr_fn(phrase[prop_name])
  else
    return phrase[prop_name]
  end


end

--------------------------------------------------------------------------------
-- set phrase properties based on editfield component 

function PhraseMateUI:apply_batch_properties()
  TRACE("PhraseMateUI:apply_batch_properties()")

  local instr = rns.selected_instrument
  local vb_popup = self.vb.views["ui_phrase_props"]
  local prop_name = xPhrase.DOC_PROPS[vb_popup.value].name
  local operator = self.editfield.operator
  local prop_value = self.editfield.value.value
  print("operator",operator)
  print("prop_name",prop_name)
  print("prop_value",prop_value)

  local phrase_indices = {}
  if self.batch_toggle.enabled then
    for k,v in ipairs(self.vtable_batch.data) do
      if v.CHECKED then
        table.insert(phrase_indices,v.INDEX)
      end
    end
  else
    table.insert(phrase_indices,rns.selected_phrase_index)
  end
  print("phrase_indices",rprint(phrase_indices))

  local rslt,err = self.owner:apply_properties(instr,prop_name,operator,prop_value,phrase_indices)
  if err then
    renoise.app():show_warning(err)
  end

  self:update_batch_table()

end

--------------------------------------------------------------------------------
-- Static Methods
--------------------------------------------------------------------------------
-- @return table

function PhraseMateUI.get_phrase_list(prepend,numbered,pad_to_max)
  TRACE("PhraseMateUI.get_phrase_list()",prepend,numbered,pad_to_max)

  local rslt = {}

  if not (type(pad_to_max)=="boolean") then
    pad_to_max = true
  end

  if prepend then
    table.insert(rslt,"No phrase selected")
  end

  for k,v in ipairs(rns.selected_instrument.phrases) do
    if numbered then
      table.insert(rslt,("%.2X - %s"):format(k,v.name))
    else
      table.insert(rslt,v.name)
    end
  end

  if pad_to_max then
    for k = #rslt,xPhraseManager.MAX_NUMBER_OF_PHRASES do
      if numbered then
        table.insert(rslt,("%.2X - N/A"):format(k))
      else
        table.insert(rslt,"N/A")
      end
    end
  end

  return rslt

end

