--[[============================================================================
-- PhraseMateUI
============================================================================]]--

--[[--

PhraseMate (user-interface)


TODO

  * use vTabs for overall interface
    + implement toggleable feature

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
PhraseMateUI.SOURCE_ITEMS = {"➜ Autocapture","➜ Capture All Instr.","➜ Selected Instrument"}
PhraseMateUI.TARGET_ITEMS = {"➜ Same Instrument","➜ New Instrument(s)"}

--PhraseMateUI.UI_INSTR_LABEL_W = 45
PhraseMateUI.UI_INSTR_POPUP_W = 125
PhraseMateUI.BUTTON_SIZE = 22
PhraseMateUI.UI_PROGRESS_TXT = {"/","-","\\","|"}
PhraseMateUI.TAB_LABELS = {
  "Read",
  "Write",
  "Zxx",
  "Props",
  "Preset",
  "Prefs",
}
PhraseMateUI.TAB_NAMES = {
  "tab_input",
  "tab_output",
  "tab_realtime",
  "tab_props",
  "tab_presets",
  "tab_prefs",
}
PhraseMateUI.TABS = {
  COLLECT = 1,
  WRITE = 2,
  ZXX = 3,
  PROPS = 4,
  PRESETS = 5,
  PREFS = 6,
}


--------------------------------------------------------------------------------

function PhraseMateUI:__init(...)
  TRACE("PhraseMateUI:__init()")

  self.prefs = renoise.tool().preferences

  local args = cLib.unpack_args(...)
  assert(type(args.owner)=="PhraseMate","Expected 'owner' to be a class instance")

  --- PhraseMate
  self.owner = args.owner

  --- vTable
  self.vtable_batch = nil

  --- vArrowButton
  self.batch_toggle = nil

  --- vArrowButton
  self.export_toggle = nil

  --- int, position of PhraseMateUI.UI_PROGRESS_TXT
  self.progress_txt_count = 1

  --- table
  self.default_button_color = nil

  --- table, titles of xPhrase.DOC_PROPS (for use in popup)
  self.phrase_props = {}

  --- string, scheduled message for status bar
  self.status_update = nil  

  --- bool, perform UI update on next idle
  self.update_requested = false 

  -- initialize -----------------------

  --- vEditField
  self.editfield = nil


  vDialog.__init(self,...)

  for k,v in ipairs(xPhrase.DOC_PROPS) do
    table.insert(self.phrase_props,v.title)
  end

  -- notifiers --

  self.prefs.create_keymappings:add_notifier(self.update_keymap,self)
  --self.prefs.use_custom_note:add_notifier(self.update_output_tab_note,self)
  --self.prefs.custom_note:add_notifier(self.update_output_tab_note,self)

  renoise.tool().app_new_document_observable:add_notifier(function()
    self:attach_to_song()
  end)

  renoise.tool().app_idle_observable:add_notifier(function()
    if self.update_requested then
      self.update_requested = false
      self:instrument_change_handler()      
    end
    if self.status_update then
      renoise.app():show_status(self.status_update)
      self:update_submit_buttons()
      self.status_update = nil
    end

    --print("self.searchfield.edit_mode",self.searchfield.edit_mode)

  end)


end

--------------------------------------------------------------------------------

function PhraseMateUI:keyhandler(dialog,key)
  TRACE("PhraseMateUI:keyhandler(dialog,key)",dialog,key)

  -- check if key is handled by vSelection
  if (self.prefs.active_tab_index.value == PhraseMateUI.TABS.PROPS) then
    if self.vtable_batch.visible then
      if not self.vtable_batch.selection:keyhandler(key) then
        return
      end
    end
  end

end

--------------------------------------------------------------------------------

function PhraseMateUI:attach_to_song()
  TRACE("PhraseMateUI:attach_to_song()")

  local schedule_update = function ()
    --print("schedule_update()")
    self.vtable_batch.selection.index = rns.selected_phrase_index
    self.update_requested = true
  end

  cObservable.attach(rns.selected_instrument_observable,function()
    local instr = rns.selected_instrument
    cObservable.attach(instr.phrase_playback_mode_observable,schedule_update)
    self:instrument_change_handler()
  end)

  cObservable.attach(rns.instruments_observable,self.instrument_change_handler,self)
  cObservable.attach(rns.selected_phrase_observable,schedule_update)

  self:instrument_change_handler()

end

--------------------------------------------------------------------------------
-- update things when changed/added/removed instr's or phrases

function PhraseMateUI:instrument_change_handler()
  TRACE("PhraseMateUI:instrument_change_handler()")

  self:update_realtime()
  self:update_props_tab()
  self:update_collect_tab()
  self:update_submit_buttons()
  --self:update_output_tab_note()

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
  self:update_realtime()
  self:update_keymap()
  self:update_props_tab()
  self:update_preset_tab()
  self:update_collect_tab()
  self:update_submit_buttons()

  self:attach_to_song()

end

-------------------------------------------------------------------------------

function PhraseMateUI:build()
  TRACE("PhraseMateUI:build()")
  
  local vb = self.vb

  self.vb_content = vb:column{
    margin = PhraseMateUI.UI_MARGIN,
    spacing = 4,
    
    vb:column{
      id = "group_phrase",
      width = "100%",
      vb:column{
        style = "group",
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
                local phrase_idx = rns.selected_phrase_index
                local rslt,err = self.owner:delete_phrase(phrase_idx)
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
    self:build_prefs_tab(),
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
  TRACE("PhraseMateUI:build_props_tab()")

  local vb = self.vb

  self.batch_toggle = vArrowButton{
    enabled = self.prefs.props_batch_apply.value,
    vb = vb,
  }
  self.batch_toggle.enabled_observable:add_notifier(function()
    self:update_props_tab()
  end)

  self.vtable_batch = vTable{
    id = "vTable_batch",
    vb = vb,
    visible = self.batch_toggle.enabled,
    width = PhraseMateUI.UI_WIDTH-2,
    row_height = 17,
    --cell_style = "group",
    cell_style = "invisible",
    column_defs = {
      {
        key = "CHECKED",
        col_width=20, 
        col_type=vTable.CELLTYPE.CHECKBOX,
        notifier=function(elm,checked)
          local item = elm.owner:get_item_by_id(elm[vDataProvider.ID])
          if item then
            item.CHECKED = checked
          end
        end
      },
      {
        key = "NAME",
        col_type=vTable.CELLTYPE.TEXT,
        col_width = "auto", 
        notifier = function(elm)
          local item = elm.owner:get_item_by_id(elm[vDataProvider.ID])
          if item then
            --rns.selected_phrase_index = item.INDEX
            self.vtable_batch.selection:set_index(item.INDEX)
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
  self.vtable_batch.selection.index_observable:add_notifier(function()
    --print(">>> self.vtable_batch.selection.index_observable fired...")
    rns.selected_phrase_index = self.vtable_batch.selection.index
    self.update_requested = true
  end)
  --self.vtable_batch.on_scroll:add_notifier(function()

  --end

  local property_w = PhraseMateUI.UI_WIDTH - (PhraseMateUI.UI_WIDTH_THIRD + PhraseMateUI.UI_BATCH_APPLY_W + 7)
  local editfield_w = PhraseMateUI.UI_WIDTH - (PhraseMateUI.UI_BATCH_APPLY_W + 15)

  self.editfield = vEditField{
    vb = vb,
    id = "vEditField",
    width = editfield_w,
    value = xPhrase.DOC_PROPS[1],
  }

  local _,phrase_prop_idx = cDocument.get_property(xPhrase.DOC_PROPS,self.prefs.property_name.value)

  return vb:column{ 
    id = "tab_props",
    visible = false,
    --style = "plain",
    --width = PhraseMateUI.UI_WIDTH,
    spacing = PhraseMateUI.UI_SPACING,
    vb:column{
      style = "group",
      width = PhraseMateUI.UI_WIDTH,
      vb:row{
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
                value = phrase_prop_idx,
                width = property_w,
                notifier = function(idx)
                  self:update_editfield()
                  self:update_batch_table()
                  self.prefs.property_name.value = xPhrase.DOC_PROPS[idx].name

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
        vb:space{
          width = 1,
        },
        vb:button{
          id = "batch_table_refresh",
          text = "Refresh",
          visible = false,
          notifier = function()
            self:update_batch_table()
          end
        }
      }
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
          font = "bold",
          width = PhraseMateUI.UI_WIDTH_THIRD,
        },
        vb:popup{
          id = "ui_source_popup",
          items = self:get_source_instr(),
          value = self.prefs.input_source_instr.value,
          width = PhraseMateUI.UI_INSTR_POPUP_W,
          notifier = function(idx)
            if (idx > #PhraseMateUI.SOURCE_ITEMS) then
              self.prefs.input_source_instr.value = #PhraseMateUI.SOURCE_ITEMS+1
            else
              self.prefs.input_source_instr.value = idx
            end
          end
        },
      },
      vb:row{
        vb:text{
          text = "Target",
          font = "bold",
          width = PhraseMateUI.UI_WIDTH_THIRD,
        },
        vb:popup{
          id = "ui_target_popup",
          items = self:get_target_instr(),
          value = self.prefs.input_target_instr.value,
          width = PhraseMateUI.UI_INSTR_POPUP_W,
          notifier = function(idx)
            if (idx > #PhraseMateUI.TARGET_ITEMS) then
              self.prefs.input_target_instr.value = #PhraseMateUI.TARGET_ITEMS+1
            else
              self.prefs.input_target_instr.value = idx
            end
          end
        },
      },
    },
    vb:column{
      style = "group",
      width = PhraseMateUI.UI_WIDTH,
      vb:space{
        width = PhraseMateUI.UI_WIDTH,
      },
      vb:row{
        vb:space{
          width = PhraseMateUI.UI_WIDTH_THIRD,
        },
        vb:column{
          margin = PhraseMateUI.UI_MARGIN,
          --width = "100%",
          vb:row{
            collection_toggle.view,
            vb:text{
              text = "Advanced settings",
              --font = "bold",
            },
          },
          vb:column{
            id = "collection_panel",
            visible = self.prefs.input_show_collection_panel.value,
            vb:row{
              tooltip = "Decide if phrases without content are skipped during collection",
              vb:checkbox{
                bind = self.prefs.input_include_empty_phrases,
              },
              vb:text{
                text = "Collect empty phrases"
              },
            },
            vb:row{
              tooltip = "Decide if duplicate phrases are skipped",
              vb:checkbox{
                bind = self.prefs.input_include_duplicate_phrases,
              },
              vb:text{
                text = "Keep duplicate phrases"
              },
            },
            vb:row{
              tooltip = "After collecting notes, insert a phrase trigger-note in their place",
              vb:checkbox{
                bind = self.prefs.input_replace_collected,
              },
              vb:text{
                text = "Replace notes with Zxx"
              },
            },
          },
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

    vb:column{ 
      spacing = PhraseMateUI.UI_SPACING,
      width = "100%",
      --[[
      vb:row{
        tooltip = "Use selected note-column as trigger",
        vb:checkbox{
          bind = self.prefs.output_use_note_column,
        },
        vb:text{
          text = "Use selected note-column as trigger",
        }
      },
      ]]
      --[[
      vb:row{
        style = "group",
        margin = PhraseMateUI.UI_MARGIN,
        vb:text{
          text = "Notes",
          font = "bold",
          width = PhraseMateUI.UI_WIDTH_THIRD,
        },
        vb:column{
          id = "ui_output_note_and_scale",
          width = PhraseMateUI.UI_WIDTH_TWOTHIRD,
          vb:row{ -- note
            vb:checkbox{
              id = "ui_output_note_cb",
              active = false,
              tooltip = "(TODO) Determine phrase note:"
                    .."\nChecked   = custom (specify via valuebox)"
                    .."\nUnchecked = automatic (use phrase base-note)",
              bind = self.prefs.use_custom_note,
            },
            vb:valuebox{
              id = "ui_output_note",
              active = false,
              tonumber = function(val)
                return xNoteColumn.note_string_to_value(val)
              end,
              tostring = function(val)
                return xNoteColumn.note_value_to_string(val)
              end,
              notifier = function(val)
                self:update_output_tab_note()
              end
            },
          },
          vb:row{ -- scale
            vb:checkbox{
              tooltip = "(TODO) Restrict to scale",
              active = false,
              notifier = function()
                
              end
            },
            vb:popup{
              id = "ui_select_scale_key",
              active = false,
              items = xScale.SCALE_NAMES,
            },
          },

        },
      },
      ]]

      vb:row{
        style = "group",
        margin = PhraseMateUI.UI_MARGIN,
        vb:text{
          text = "Output",
          font = "bold",
          width = PhraseMateUI.UI_WIDTH_THIRD,
        },

        vb:column{
          id = "ui_output_settings",
          width = PhraseMateUI.UI_WIDTH_TWOTHIRD,
          vb:row{
            tooltip = "When writing to a selection, this option determines if the output is written relative to the position of the selection, or starting from the top of the pattern",
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
            tooltip = "Show additional note/effect-columns if required by source phrase (only applies to track-wide output)",
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
            tooltip = "Insert Z00 commands (makes resulting notes ignore phrases)",
            vb:checkbox{
              bind = self.prefs.output_insert_zxx
            },
            vb:text{
              text = "Insert Z00 commands",
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
      },
    },
    vb:column{
      vb:button{
        id = "ui_output_to_selection",
        text = "Write to selection",
        width = PhraseMateUI.UI_WIDTH,
        height = PhraseMateUI.BUTTON_SIZE,
        notifier = function()
          self.owner:apply_to_selection()
        end
      },
      vb:button{
        id = "ui_output_to_track",
        text = "Write to track",
        width = PhraseMateUI.UI_WIDTH,
        height = PhraseMateUI.BUTTON_SIZE,
        notifier = function()
          self.owner:apply_to_track()
        end
      },
      vb:button{
        id = "ui_smart_write",
        text = "Smart Write...",
        width = PhraseMateUI.UI_WIDTH,
        height = PhraseMateUI.BUTTON_SIZE,
        notifier = function()
          self.owner:show_smart_dialog()
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
          text = "Live monitoring of pattern",
        },
      },
      --[[
      vb:row{
        vb:checkbox{
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
      ]]
      vb:column{
        margin = PhraseMateUI.UI_MARGIN,
        vb:text{
          text = [[
Inserts Zxx commands into the first
available note/effect column, when  
the following conditions are met:
* Phrase is set to program playback
* Edit-mode is enabled in Renoise
* Instrument is selected]],
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
      self.prefs.output_folder.value = val
    end,
  }

  self.export_toggle = vArrowButton{
    enabled = self.prefs.preset_show_export_options.value,
    vb = vb,
  }
  self.export_toggle.enabled_observable:add_notifier(function()
    self:update_preset_tab()
  end)

  return vb:column{ 
    id = "tab_presets",
    visible = false,
    width = PhraseMateUI.UI_WIDTH,
    spacing = PhraseMateUI.UI_SPACING,
    vb:column{ 
      width = "100%",
      spacing = PhraseMateUI.UI_SPACING,
      vb:row{
        style = "group",
        --width = PhraseMateUI.UI_WIDTH,
        width = "100%",
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
          --[[
          vb:text{
            text = "Note that settings in 'New' applies"
                .."\nto any imported phrases",
            font = "italic",
          }
          ]]
        },
      },
      vb:column{
        style = "group",
        margin = PhraseMateUI.UI_MARGIN,
        --width = PhraseMateUI.UI_WIDTH,
        width = "100%",
        vb:row{
          vb:text{
            text = "Export",
            font = "bold",
            width = PhraseMateUI.UI_WIDTH_THIRD,
          },

          vb:column{
            width = PhraseMateUI.UI_WIDTH_TWOTHIRD,

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
                self.owner:show_export_dialog()
              end
            },

            vb:row{
              self.export_toggle.view,
              vb:text{
                text = "Show export settings",
                --font = "bold",
              },
            },
            vb:column{
              id = "ui_export_settings_panel",
              vb:row{
                vb:text{
                  text = "Path",
                  width = 40,
                },
                vpath_output.view,
              },
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

function PhraseMateUI:build_prefs_tab()

  local vb = self.vb
  return vb:column{ 
    id = "tab_prefs",
    visible = false,
    width = "100%",
    spacing = PhraseMateUI.UI_SPACING,
    vb:column{
      style = "group",
      margin = PhraseMateUI.UI_MARGIN,
      width = "100%",
      vb:column{
        width = "100%",
        vb:horizontal_aligner{
          width = "100%",
          mode = "justify",
          vb:text{
            text = "General settings",
            font = "bold",
          },
          vb:button{
            text = "Docs & source code",
            tooltip = "Visit github for documentation and source code",
            width = PhraseMateUI.BUTTON_SIZE,
            notifier = function()
              renoise.app():open_url("https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.PhraseMate.xrnx")
            end
          },
        },

        vb:row{
          tooltip = "Choose whether this dialog should be shown when Renoise is launched",
          vb:checkbox{
            bind = self.prefs.autostart,
          },
          vb:text{
            text = "Autostart tool "
          },
        },
        vb:row{
          tooltip = "Decide how often to create undo points while processing:"
                .."\nDisabled - perform processing in a single step"
                .."\nPattern - create an undo point once per pattern"
                .."\nPattern-Track - create undo point per track in pattern"
                .."\n\nEnable this feature if you experience warning dialogs"
                .."\ncomplaining that 'script is taking too long'",
          vb:text{
            text = "Processing,undo",
            --width = PhraseMateUI.UI_KEYMAP_LABEL_W,
          },
          vb:popup{
            width = 80,
            items = PhraseMate.SLICE_MODES,
            bind = self.prefs.process_slice_mode,
          },
        },

      },
    },
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

function PhraseMateUI:show_tab()
  TRACE("PhraseMateUI:show_tab()")

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
        self:update_collect_tab()
      elseif (self.prefs.active_tab_index.value == PhraseMateUI.TABS.WRITE) then
        self:update_output_tab()
      elseif (self.prefs.active_tab_index.value == PhraseMateUI.TABS.ZXX) then
        --self:update_realtime()
      elseif (self.prefs.active_tab_index.value == PhraseMateUI.TABS.PROPS) then
        self:update_props_tab()
      elseif (self.prefs.active_tab_index.value == PhraseMateUI.TABS.PRESETS) then
        self:update_preset_tab()
      end
    end
  end

  self:update_submit_buttons()

end

--------------------------------------------------------------------------------

function PhraseMateUI:update_keymap()
  TRACE("PhraseMateUI:update_keymap()")

  local vb = self.vb
  local active = self.prefs.create_keymappings.value
  vb.views["ui_create_keymap_range"].active = active
  vb.views["ui_create_keymap_offset"].active = active

end

--------------------------------------------------------------------------------
-- update 'realtime' display of phrase properties
-- invoked when instrument/phrase is changed

function PhraseMateUI:update_realtime()
  TRACE("PhraseMateUI:update_realtime()")

  --print("update_realtime",self)

  local vb = self.vb
  local instr = rns.selected_instrument
  local instr_has_phrases = (#instr.phrases > 0) and true or false
  vb.views["ui_realtime_playback_mode"].value = instr.phrase_playback_mode
  vb.views["ui_realtime_prev"].active = instr_has_phrases and xPhraseManager.can_select_previous_phrase()
  vb.views["ui_realtime_next"].active = instr_has_phrases and xPhraseManager.can_select_next_phrase()
  vb.views["ui_realtime_phrase_popup"].items = PhraseMateUI.get_phrase_list("No phrase selected",true)
  vb.views["ui_realtime_phrase_popup"].value = instr_has_phrases and rns.selected_phrase_index+1 or 1
  vb.views["ui_delete_phrase"].active = (instr_has_phrases and rns.selected_phrase_index > 0) and true or false
  
end

--------------------------------------------------------------------------------
-- update submit buttons during processing (show progress/ability to cancel)

function PhraseMateUI:update_submit_buttons()
  TRACE("PhraseMateUI:update_submit_buttons()")

  local vb = self.vb
  local input_submit = vb.views["ui_input_submit"]
  local output_to_selection = vb.views["ui_output_to_selection"]
  local output_to_track = vb.views["ui_output_to_track"]
  local vb_smart_write = vb.views["ui_smart_write"]

  if (self.prefs.active_tab_index.value == PhraseMateUI.TABS.COLLECT) then
    input_submit.text = self.owner.process_slicer and self.owner.process_slicer:running()
      and ("Collecting %s [Cancel]"):format(PhraseMateUI.UI_PROGRESS_TXT[self.progress_txt_count])
      or "Collect phrases"

  elseif (self.prefs.active_tab_index.value == PhraseMateUI.TABS.WRITE) then
    local running = self.owner.process_slicer and self.owner.process_slicer:running()
    output_to_selection.active = not running
    output_to_track.active = not running
    vb_smart_write.active = not running
  end

end

--------------------------------------------------------------------------------

function PhraseMateUI:update_output_tab()
  TRACE("PhraseMateUI:update_output_tab()")

  --self:update_output_tab_note()

end

--------------------------------------------------------------------------------
--[[
function PhraseMateUI:update_output_tab_note()
  TRACE("PhraseMateUI:update_output_tab_note()")

  local vb = self.vb
  local use_custom = self.prefs.use_custom_note.value
  local selected_note = rns.selected_phrase
    and rns.selected_phrase.base_note or 48

  local note = nil
  if self.prefs.use_custom_note.value then
    note = self.prefs.custom_note.value
  else
    note = selected_note
  end

  --print("note",note)
  --print("selected_note",selected_note)

  vb.views["ui_output_note_cb"].value = use_custom
  vb.views["ui_output_note"].active = use_custom
  vb.views["ui_output_note"].value = note

end
]]

--------------------------------------------------------------------------------

function PhraseMateUI:update_props_tab()
  TRACE("PhraseMateUI:update_props_tab()")

  if (self.prefs.active_tab_index.value ~= PhraseMateUI.TABS.PROPS) then
    return
  end

  local val = self.batch_toggle.enabled
  self.vtable_batch.view.visible = val
  self.prefs.props_batch_apply.value = val
  self.vb.views["batch_table_refresh"].visible = val

  self:update_editfield()
  self:update_batch_table()

end

--------------------------------------------------------------------------------

function PhraseMateUI:update_preset_tab()
  TRACE("PhraseMateUI:update_preset_tab()")

  if (self.prefs.active_tab_index.value ~= PhraseMateUI.TABS.PRESETS) then
    return
  end

  local val = self.export_toggle.enabled
  self.vb.views["ui_export_settings_panel"].visible = val
  self.prefs.preset_show_export_options.value = val

end

--------------------------------------------------------------------------------
---

function PhraseMateUI:update_editfield()
  TRACE("PhraseMateUI:update_editfield()")

  local phrase = rns.selected_phrase
  if phrase then
    local prop_idx = self.vb.views["ui_phrase_props"].value
    local cval = table.rcopy(xPhrase.DOC_PROPS[prop_idx])
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
  local header_checked = true
  self.vtable_batch.data = data
  self.vtable_batch.visible = self.batch_toggle.enabled
  self:update_batch_table_styling()

  --self.vb.views["tab_props"].width = PhraseMateUI.UI_WIDTH
  --self.vtable_batch.width = PhraseMateUI.UI_WIDTH

end

--------------------------------------------------------------------------------
-- decorate selection rows (visible on next update)

function PhraseMateUI:update_batch_table_styling()
  TRACE("PhraseMateUI:update_batch_table_styling()")

  local sel_indices = self.vtable_batch.selection.indices
  --print("sel_indices",rprint(sel_indices))
  for k,v in ipairs(self.vtable_batch.data) do
    if (table.find(sel_indices,v.INDEX)) then
      v.__row_style = PhraseMateUI.ROW_STYLE_SELECTED
    else
      v.__row_style = PhraseMateUI.ROW_STYLE_NORMAL
    end
  end
  self.vtable_batch:request_update()

end

--------------------------------------------------------------------------------

function PhraseMateUI:get_source_instr()
  TRACE("PhraseMateUI:get_source_instr()")

  local rslt = table.copy(PhraseMateUI.SOURCE_ITEMS)
  for k = 1,127 do
    local instr = rns.instruments[k]
    local instr_name = instr and instr.name or ""
    table.insert(rslt,("%.2X %s"):format(k-1,instr_name))
  end
  return rslt

end

--------------------------------------------------------------------------------

function PhraseMateUI:get_target_instr()
  TRACE("PhraseMateUI:get_target_instr()")

  local rslt = table.copy(PhraseMateUI.TARGET_ITEMS)
  for k = 1,127 do
    local instr = rns.instruments[k]
    local instr_name = instr and instr.name or ""
    table.insert(rslt,("%.2X %s"):format(k-1,instr_name))
  end
  return rslt

end

--------------------------------------------------------------------------------

function PhraseMateUI:set_batch_checked_state(elm,checked)
  TRACE("PhraseMateUI:set_batch_checked_state(elm,checked)",elm,checked)

  self.vtable_batch.header_defs.CHECKED.data = checked
  for k,v in ipairs(self.vtable_batch.data) do
    v.CHECKED = checked
  end
  self.vtable_batch:request_update()

end

--------------------------------------------------------------------------------

function PhraseMateUI:update_collect_tab()
  TRACE("PhraseMateUI:update_collect_tab()")

  local vb = self.vb

  vb.views["ui_source_popup"].items = self:get_source_instr()
  vb.views["ui_target_popup"].items = self:get_target_instr()
  if (self.prefs.input_target_instr.value < 3) then
    vb.views["ui_target_popup"].value = self.prefs.input_target_instr.value
  end

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
    local item = self.vtable_batch.data[k]
    local checked = false
    if (item and type(item.CHECKED)=="boolean") then
      checked = item.CHECKED
    end
    table.insert(data,{
      NAME = v,
      CHECKED = checked,
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
  local prop = xPhrase.DOC_PROPS[vb_popup.value]
  local prop_name = prop.name

  -- decorate value - for example, when number is enum 
  -- or has a tostring converter

  local enums = prop.value_enums
  local tostr_fn = prop.value_tostring

  if enums then
    return enums[phrase[prop_name]]
  elseif tostr_fn then
    return tostr_fn(phrase[prop_name])
  else
    local val = phrase[prop_name]
    if (type(val) == "number") then
      if prop.value_quantum and (prop.value_quantum == 1) then
        if prop.zero_based then
          val = val-1
        end
      else
        -- reduce floating point (fuzzy == too long)
        val = string.format("%.4f",val)
      end
    end
    return val
  end


end

--------------------------------------------------------------------------------
-- apply properties to a collection of phrases 

function PhraseMateUI:apply_batch_properties()
  TRACE("PhraseMateUI:apply_batch_properties()")

  local instr = rns.selected_instrument
  local vb_popup = self.vb.views["ui_phrase_props"]
  local prop_name = xPhrase.DOC_PROPS[vb_popup.value].name

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
  --print("phrase_indices",rprint(phrase_indices))

  -- if no items are checked, use the selected row 
  if table.is_empty(phrase_indices) then
    if not self.vtable_batch.selection.index then
      renoise.app():show_warning("Please select one or more phrases from the list below")
    else
      table.insert(phrase_indices,self.vtable_batch.selection.index)
    end
  end

  local operator_value = self.editfield:get_operator_value()
  if not operator_value then -- SET
    operator_value = self.editfield.value.value
  end
  local rslt,err = self.owner:apply_properties(instr,prop_name,self.editfield.operator,operator_value,phrase_indices)
  if err then
    renoise.app():show_warning(err)
  end

  self:update_batch_table()
  self:update_editfield()

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

