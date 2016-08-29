--[[============================================================================
-- PhraseMateUI
============================================================================]]--

--[[--

PhraseMate (user-interface)

--]]


--==============================================================================


class 'PhraseMateUI' (vDialog)

PhraseMateUI.UI_WIDTH = 216
PhraseMateUI.UI_KEYMAP_LABEL_W = 90
PhraseMateUI.UI_KEYMAP_CTRL_W = 65
PhraseMateUI.UI_INSTR_LABEL_W = 45
PhraseMateUI.UI_INSTR_POPUP_W = 125
PhraseMateUI.BUTTON_H = 22
PhraseMateUI.UI_PROGRESS_TXT = {"/","-","\\","|"}
PhraseMateUI.TAB_LABELS = {
  "Read",
  "Write",
  "Zxx",
  "Batch",
  "Presets",
}

--------------------------------------------------------------------------------

function PhraseMateUI:__init(...)
  TRACE("PhraseMateUI:__init()")

  self.prefs = renoise.tool().preferences

  local args = xLib.unpack_args(...)
  assert(type(args.owner)=="PhraseMate","Expected 'owner' to be a class instance")

  --- PhraseMate
  self.owner = args.owner

  --- int, position of PhraseMateUI.UI_PROGRESS_TXT
  self.progress_txt_count = 1

  --- renoise.ViewBuilder
  --self.vb
  --self.dialog
  --self.dialog_content

  vDialog.__init(self,...)


  -- notifiers ------------------------

  self.prefs.input_create_keymappings:add_notifier(self.update_keymap)


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
  self.vb_content = vb:column{
    margin = 6,
    spacing = 4,
    
    vb:column{
      id = "group_phrase",
      width = "100%",
      vb:column{
        width = PhraseMateUI.UI_WIDTH+6,
        style = "group",
        margin = 3,
        vb:horizontal_aligner{
          mode = "justify",
          vb:text{              
            id = "ui_realtime_phrase_name_header",
            text = "Current Phrase",
            font = "bold",
          },
          vb:button{
            text = "?",
            tooltip = "Visit github for documentation and source code",
            notifier = function()
              renoise.app():open_url("https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.PhraseMate.xrnx")
            end
          }
        },
        vb:text{              
          id = "ui_realtime_phrase_name",
          text = "",
        },
        vb:row{
          vb:button{
            id = "ui_realtime_prev",
            text = "Prev",
            tooltip = "Select the previous phrase",
            width = 36,
            height = PhraseMateUI.BUTTON_H,
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
            height = PhraseMateUI.BUTTON_H,
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
            height = PhraseMateUI.BUTTON_H,
            items = PhraseMate.PLAYBACK_MODES,
            notifier = function(idx)
              rns.selected_instrument.phrase_playback_mode = idx
            end
          },
        },
      },

    },

    vb:switch{
      width = PhraseMateUI.UI_WIDTH,
      height = PhraseMateUI.BUTTON_H,
      items = PhraseMateUI.TAB_LABELS,
      bind = self.prefs.active_tab_index,
      notifier = function()
        self:show_tab()
      end
    },

    vb:column{
      id = "tab_input",
      visible = false,
      width = "100%",
      --margin = 6,
      spacing = 3,
      vb:row{
        margin = 6,
        style = "group",
        width = "100%",
        vb:chooser{
          width = "100%",
          items = PhraseMate.INPUT_SCOPES,
          bind = self.prefs.input_scope,
        },
      },
      vb:column{
        style = "group",
        margin = 6,
        width = "100%",
        vb:row{
          vb:text{
            text = "Source",
            width = PhraseMateUI.UI_INSTR_LABEL_W,
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
            width = PhraseMateUI.UI_INSTR_LABEL_W,
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
      vb:column{
        style = "group",
        margin = 6,
        width = "100%",
        vb:row{
          vb:button{
            text = "▾",
            notifier = function()

            end,
          },
          vb:text{
            text = "Collection",
            font = "bold",
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
      vb:column{
        style = "group",
        margin = 6,
        width = "100%",
        vb:text{
          text = "Phrase properties",
          font = "bold",
        },
        vb:row{
          tooltip = "Choose whether to loop collected phrases",
          vb:checkbox{
            bind = self.prefs.input_loop_phrases,
          },
          vb:text{
            text = "Loop collected phrases"
          },
        },
        vb:row{
          tooltip = "Choose whether to create keymappings for the new phrases",
          vb:checkbox{
            bind = self.prefs.input_create_keymappings,
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
              id = "ui_input_keymap_range",
              width = PhraseMateUI.UI_KEYMAP_CTRL_W,
              min = 1,
              max = 119,
              bind = self.prefs.input_keymap_range,
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
              id = "ui_input_keymap_offset",
              width = PhraseMateUI.UI_KEYMAP_CTRL_W,
              min = 0,
              max = 119,
              bind = self.prefs.input_keymap_offset,
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
      vb:button{
        id = "ui_input_submit",
        text = "",
        width = "100%",
        height = 22,
        notifier = function()
          if self.owner.process_slicer and self.owner.process_slicer:running() then
            self.owner.process_slicer:stop()
          else
            self.owner:invoke_task(self.owner:collect_phrases())
          end
        end
      },
    },
    vb:column{ 
      id = "tab_output",
      visible = false,
      width = "100%",
      spacing = 3,
      vb:column{ 
        style = "group",
        margin = 3,
        width = "100%",
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
          height = 22,
          notifier = function()
            self.owner:apply_to_selection()
          end
        },
        vb:button{
          id = "ui_output_to_track",
          text = "Write to track",
          width = "100%",
          height = 22,
          notifier = function()
            self.owner:apply_to_track()
          end
        },
      },
    },
    vb:column{ 
      id = "tab_realtime",
      visible = false,
      width = "100%",
      spacing = 3,
      vb:column{
        style = "group",
        margin = 3,
        width = "100%",
        tooltip = "Insert Zxx commands into the first available effect column when the following conditions are met:"
                .."\n* Phrase is set to program playback"
                .."\n* Edit-mode is enabled in Renoise",
        vb:row{
          vb:checkbox{
            bind = self.prefs.zxx_mode
          },
          vb:text{
            text = "Monitor changes to pattern "
                .."\nand insert Zxx commands as"
                .."\nnotes are entered."
          },
        },
        vb:text{
          text = "Note: realtime is active only while "
              .."\nEdit Mode is enabled in Renoise, "
              .."\nand phrase is set to Prg mode...",
          font = "italic",
        },
      },
    },

    vb:column{ 
      id = "tab_batch",
      visible = false,
      width = "100%",
      spacing = 3,
      vb:column{},
    },
    vb:column{ 
      id = "tab_presets",
      visible = false,
      width = "100%",
      spacing = 3,
      vb:column{},
    },
    --vb:button{
      --text = "remove trace statements",
      --notifier = function()
        --xDebug.remove_trace_statements()
      --end
    --}

  }

end

--------------------------------------------------------------------------------
--[[
function PhraseMateUI:show_preferences()

  --rns = renoise.song()

  local vb = self.vb

  if dialog and dialog.visible then
    dialog:show()
  else
    --vb = renoise.ViewBuilder()


    local keyhandler = function(dialog,key)
      --print("dialog,key",dialog,key)
      return key
    end

    dialog = renoise.app():show_custom_dialog(
      "PhraseMate", dialog_content, keyhandler)
  end

  self:show_tab()
  self:update_keymap()
  self:update_realtime()
  self:update_instruments()
  self:update_submit_buttons()

end
]]

-------------------------------------------------------------------------------
-- Class methods
--------------------------------------------------------------------------------

function PhraseMateUI:update_keymap()
  TRACE("PhraseMateUI:update_keymap()")

  --if not vb then return end
  local vb = self.vb

  local active = self.prefs.input_create_keymappings.value
  vb.views["ui_input_keymap_range"].active = active
  vb.views["ui_input_keymap_offset"].active = active

end


--------------------------------------------------------------------------------
--[[
function PhraseMateUI:update_instruments()
  TRACE("PhraseMateUI:update_instruments()")

  --if not vb then return end
  local vb = self.vb
  local active = self.prefs.input_create_keymappings.value
  vb.views["ui_input_keymap_range"].active = active
  vb.views["ui_input_keymap_offset"].active = active

end
]]
--------------------------------------------------------------------------------

function PhraseMateUI:update_realtime()
  TRACE("PhraseMateUI:update_realtime()")

  --if not vb then return end
  local vb = self.vb
  local instr = rns.selected_instrument
  local instr_has_phrases = (#instr.phrases > 0) and true or false
  vb.views["ui_realtime_playback_mode"].value = instr.phrase_playback_mode
  vb.views["ui_realtime_prev"].active = instr_has_phrases and xPhraseManager.can_select_previous_phrase()
  vb.views["ui_realtime_next"].active = instr_has_phrases and xPhraseManager.can_select_next_phrase()
  vb.views["ui_realtime_phrase_name"].text = ("%.2X : %s"):format(
    rns.selected_phrase_index, instr_has_phrases and rns.selected_phrase and rns.selected_phrase.name or "N/A")

end

--------------------------------------------------------------------------------

function PhraseMateUI:show_tab()
  TRACE("PhraseMateUI:show_tab()")

  --if not vb then return end
  local vb = self.vb
  local tabs = {
    vb.views["tab_input"],
    vb.views["tab_output"],
    vb.views["tab_realtime"],
    vb.views["tab_batch"],
    vb.views["tab_presets"],
  }

  for k,v in ipairs(tabs) do
    v.visible = (self.prefs.active_tab_index.value == k) and true or false
  end

end

--------------------------------------------------------------------------------
-- update submit buttons during processing (show progress/ability to cancel)

function PhraseMateUI:update_submit_buttons()
  TRACE("PhraseMateUI:update_submit_buttons()")

  --if not vb then return end
  local vb = self.vb
  local input_submit = vb.views["ui_input_submit"]
  local output_to_selection = vb.views["ui_output_to_selection"]
  local output_to_track = vb.views["ui_output_to_track"]

  if (self.prefs.active_tab_index.value == PhraseMate.UI_TABS.INPUT) then
    input_submit.text = self.owner.process_slicer and self.owner.process_slicer:running()
      and ("Collecting %s [Cancel]"):format(PhraseMateUI.UI_PROGRESS_TXT[self.progress_txt_count])
      or "Collect phrases"

  elseif (self.prefs.active_tab_index.value == PhraseMate.UI_TABS.OUTPUT) then
    local running = self.owner.process_slicer and self.owner.process_slicer:running()
    output_to_selection.active = not running
    output_to_track.active = not running

  end


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

  local active = self.prefs.input_create_keymappings.value
  vb.views["ui_input_keymap_range"].active = active
  vb.views["ui_input_keymap_offset"].active = active

end

