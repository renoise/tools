--[[============================================================================
xStreamUI
============================================================================]]--
--[[

	User-interface for xStream - provides controls for most of the 
  properties and methods available in the application
  
  This class is designed to work exclusively by using notifiers. 

]]

class 'xStreamUI'

xStreamUI.MODEL_CONTROLS = {
  "xStreamAddPreset",
  "xStreamRemovePreset",
  "xStreamApplyLocallyButton",
  "xStreamApplySelectionButton",
  "xStreamApplyTrackButton",
  "xStreamApplyTrackButton",
  "xStreamCallbackCompile",
  "xStreamExportPresetBank",
  "xStreamArgsAddButton",
  --"xStreamArgsRenameButton",
  --"xStreamArgsRemoveButton",
  "xStreamModelArgsToggle",
  "xStreamPresetsToggle",
  "xStreamArgsMoveUpButton",
  "xStreamArgsMoveDownButton",
  "xStreamArgsEditButton",
  "xStreamArgsRandomize",
  "xStreamFavoriteModel",
  "xStreamImportPresetBank",
  "xStreamModelColorPreview",
  "xStreamModelRefresh",
  "xStreamCompactModelColorPreview",
  "xStreamModelRemove",
  "xStreamModelRename",
  "xStreamModelSave",
  "xStreamModelSaveAs",
  "xStreamMuteButton",
  "xStreamPresetBankCreate",
  "xStreamPresetBankSelector",
  "xStreamRevealLocation",
  "xStreamStartPlayButton",
  "xStreamToggleStreaming",
  "xStreamPresetBankRename",
  "xStreamPresetBankRemove",
  "xStreamFavoritePreset",
  "xStreamUpdatePreset",
  "xStreamPresetSelector",
  "xStreamCompactPresetSelector",
  "xStreamArgsSelector",
}

xStreamUI.FAVORITE_EDIT_BUTTONS = {
  "xStreamFavoritesEditButtonInsert",
  "xStreamFavoritesEditButtonMove",
  "xStreamFavoritesEditButtonSwap",
  "xStreamFavoritesEditButtonClear",
  "xStreamFavoritesEditButtonDelete",
}


xStreamUI.SCHEDULE_TEXT = {
  OFF = "▷",
  ON = "▶",
}

xStreamUI.FAVORITE_TEXT = {
  OFF = "   ",
  ON = "★",
  DIMMED = "☆",
}

xStreamUI.START_OPTIONS = {"Manual control","Auto - Play","Auto - Play+Edit"}
xStreamUI.START_OPTION = {
  MANUAL = 1,
  ON_PLAY = 2,
  ON_PLAY_EDIT = 3,
}

--[[
xStreamUI.OPTIONS_ICON = (renoise.API_VERSION <= 4)
  and "Icons/Edit.bmp"
  or  "Icons/Options.bmp"
]]

xStreamUI.EMPTY_FAVORITE_TXT = "-"
xStreamUI.EDIT_RACK_WARNING = "⚠ Warning"
xStreamUI.NO_MODEL_SELECTED = "(Select model)"
xStreamUI.NO_PRESETS_AVAILABLE = "No presets"
xStreamUI.NO_PRESET_BANKS_AVAILABLE = "No preset banks"
xStreamUI.NO_ARGS_AVAILABLE = "No arguments"
xStreamUI.NO_ARG_SELECTED = "(Select argument)"
xStreamUI.NO_FAVORITE_SELECTED = "(Select favorite)"

xStreamUI.ARROW_UP = "▴"
xStreamUI.ARROW_DOWN = "▾"
xStreamUI.ARROW_LEFT = "◂"
xStreamUI.ARROW_RIGHT = "▸"

xStreamUI.FAVORITE_GRID_W = 66
xStreamUI.FAVORITE_GRID_H = 44
xStreamUI.BITMAP_BUTTON_W = 21
xStreamUI.BITMAP_BUTTON_H = 19
xStreamUI.CALLBACK_EDITOR_W = 500 -- 80 characters
xStreamUI.MONO_CHAR_W = 7 -- single character 
xStreamUI.TRANSPORT_BUTTON_W = 28
xStreamUI.PRESET_SELECTOR_W = 110
xStreamUI.ARGS_SELECTOR_W = 201
xStreamUI.ARGS_SLIDER_W = 90
--xStreamUI.ARG_CONTROL_POPUP_W = 141
xStreamUI.MODEL_SELECTOR_W = 126
xStreamUI.MODEL_SELECTOR_COMPACT_W = 127
xStreamUI.FAVORITE_SELECTOR_W = 223
xStreamUI.FLASH_TIME = 0.2
xStreamUI.LINE_HEIGHT = 14
xStreamUI.MAX_BRIGHT_COLOR = 1
xStreamUI.BRIGHTEN_AMOUNT = 0.9
xStreamUI.HIGHLIGHT_AMOUNT = 0.66
xStreamUI.DIMMED_AMOUNT = 0.40
xStreamUI.SELECTED_COLOR = 0.20
xStreamUI.EDIT_RACK_MARGIN = 40
xStreamUI.TOOL_OPTION_W = 130
xStreamUI.TOOL_OPTION_TXT_W = 70
xStreamUI.EDIT_SELECTOR_W = 120
xStreamUI.SMALL_VERTICAL_MARGIN = 6

xStreamUI.ARGS_MIN_VALUE = -99999
xStreamUI.ARGS_MAX_VALUE = 99999

xStreamUI.DEFAULT_PALETTE = {
  {0x60,0xAA,0xCA},{0x9E,0xD6,0x8C},{0xCA,0x87,0x59},{0xC9,0xB3,0x6D},
  {0x50,0x55,0x52},{0x69,0x99,0x7a},{0xa5,0x4a,0x24},{0x93,0x58,0x75},
}

xStreamUI.WELCOME_MSG = [[




          ██╗  ██╗███████╗████████╗██████╗ ███████╗ █████╗ ███╗   ███╗
          ╚██╗██╔╝██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔══██╗████╗ ████║
           ╚███╔╝ ███████╗   ██║   ██████╔╝█████╗  ███████║██╔████╔██║
           ██╔██╗ ╚════██║   ██║   ██╔══██╗██╔══╝  ██╔══██║██║╚██╔╝██║
          ██╔╝ ██╗███████║   ██║   ██║  ██║███████╗██║  ██║██║ ╚═╝ ██║
          ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝
]]

-------------------------------------------------------------------------------
-- constructor
-- @param xstream (xStream)
-- @param vb (renoise.ViewBuilder)
-- @param midi_prefix (string)

function xStreamUI:__init(xstream,vb,midi_prefix)
  TRACE("xStreamUI:__init(xstream,vb,midi_prefix)",xstream,vb,midi_prefix)

  self.xstream = xstream
  self.vb = vb
  self.midi_prefix = midi_prefix

  self.vb_content = nil

  -- bool, any blinking element should use this 
  self.blink_state = false

  -- table<int> temporarily highlighted buttons in favorites
  --  index (int)
  --  clocked (number)
  self.flash_favorite_buttons = {}

  -- delayed display updates
  self.build_favorites_requested = false
  self.update_favorites_requested = false
  self.favorite_edit_rack_requested = false
  self.build_presets_requested = false
  self.update_presets_requested = false
  self.update_models_requested = false
  self.build_models_requested = false
  self.update_color_requested = false
  self.update_model_requested = false
  self.update_launch_model_requested = false
  self.build_args_requested = false
  self.update_args_requested = false

  self.favorite_views = {}
  self.preset_views = {}
  self.model_views = {}
  self.arg_labels = {}
  self.arg_views = {}
  self.arg_bops = {}
  
  self.scheduled_model_index = nil
  self.scheduled_preset_index = nil
  self.scheduled_favorite_index = nil

  -- implementation-specific options --
  -- (relevant for the tool, not xStream itself)

  self.start_option = property(self.get_start_option,self.set_start_option)
  self.start_option_observable = renoise.Document.ObservableNumber(xStreamUI.START_OPTION.ON_PLAY_EDIT)

  self.launch_model = property(self.get_launch_model,self.set_launch_model)
  self.launch_model_observable = renoise.Document.ObservableString("")

  self.autostart = property(self.get_autostart,self.set_autostart)
  self.autostart_observable = renoise.Document.ObservableBoolean(false)

  self.suspend_when_hidden = property(self.get_suspend_when_hidden,self.set_suspend_when_hidden)
  self.suspend_when_hidden_observable = renoise.Document.ObservableBoolean(false)

  self.manage_gc = property(self.get_manage_gc,self.set_manage_gc)
  self.manage_gc_observable = renoise.Document.ObservableBoolean(false)

  -- int, changes with selected model/preset - 0 means not favorited
  -- (not to be confused with the selected favorite in the grid)
  self.selected_favorite_index = property(self.get_selected_favorite_index,self.set_selected_favorite_index)
  self.selected_favorite_index_observable = renoise.Document.ObservableNumber(0)

  self.show_editor = property(self.get_show_editor,self.set_show_editor)
  self.show_editor_observable = renoise.Document.ObservableBoolean(true)

  self.tool_options_visible = property(self.get_tool_options_visible,self.set_tool_options_visible)
  self.tool_options_visible_observable = renoise.Document.ObservableBoolean(false)

  self.model_browser_visible = property(self.get_model_browser_visible,self.set_model_browser_visible)
  self.model_browser_visible_observable = renoise.Document.ObservableBoolean(false)

  self.model_args_visible = property(self.get_model_args_visible,self.set_model_args_visible)
  self.model_args_visible_observable = renoise.Document.ObservableBoolean(false)

  self.presets_visible = property(self.get_presets_visible,self.set_presets_visible)
  self.presets_visible_observable = renoise.Document.ObservableBoolean(false)

  self.favorites_visible = property(self.get_favorites_visible,self.set_favorites_visible)
  self.favorites_visible_observable = renoise.Document.ObservableBoolean(false)

  --self.xstream_options_visible = property(self.get_xstream_options_visible,self.set_xstream_options_visible)
  --self.xstream_options_visible_observable = renoise.Document.ObservableBoolean(false)

  self.editor_visible_lines = property(self.get_editor_visible_lines,self.set_editor_visible_lines)
  self.editor_visible_lines_observable = renoise.Document.ObservableNumber(16)

  self.args_editor_visible = property(self.get_args_editor_visible,self.set_args_editor_visible)
  self.args_editor_visible_observable = renoise.Document.ObservableBoolean(false)

  self.cached_model_args_visible = nil

  -- bool, set immediately after changing the callback string
  self.user_modified_callback = false

  -- renoise.Dialog, wizard-style dialog for creating models
  self.model_dialog = nil

  -- renoise.View
  self.model_dialog_content = nil

  self.model_dialog_page = nil
  self.model_dialog_option = nil

  self.base_color_highlight = xColor.adjust_brightness(xLib.COLOR_BASE,xStreamUI.HIGHLIGHT_AMOUNT)


  -- initialize -----------------------

  self:build()

end

--------------------------------------------------------------------------------
-- build, update everything

function xStreamUI:update()
  TRACE("xStreamUI:update()")

  self:build_favorites()
  self:update_favorite_buttons()
  self:update_favorite_selector()
  self:build_model_list()
  self:update_model_controls()
  self:update_model_list()
  self:update_model_selector()
  self:update_model_title()
  self:build_args()
  self:update_args()
  self:update_args_selector()
  self:update_args_visibility()
  self:build_preset_list()
  self:update_editor()
  self:update_preset_controls()
  self:update_color()

end

--------------------------------------------------------------------------------
-- create new model - create/re-use existing dialog 

function xStreamUI:create_model()

  self.model_dialog_page = 1
  self.model_dialog_option = 1

  if not self.model_dialog or not self.model_dialog.visible then
    if not self.model_dialog_content then
      self.model_dialog_content = self:create_model_dialog()
    end
    self:update_model_dialog()
    self.model_dialog = renoise.app():show_custom_dialog(
        "Create model", self.model_dialog_content)
  else
    self.model_dialog:show()
  end

end

-------------------------------------------------------------------------------
-- @return renoise.Views.Rack

function xStreamUI:create_model_dialog()

  local vb = self.vb

  local PAGE_W = 250
  local PAGE_H = 70
  local TEXT_H = 150

  local add_save_and_close = function(model)
    self.xstream:add_model(model)
    local got_saved,err = model:save()
    if not got_saved and err then
      renoise.app():show_warning(err)
    end
    self.xstream.selected_model_index = #self.xstream.models
    self.model_dialog:close()
    self.model_dialog = nil
  end

  local validate_model_name = function(str_name)
    local str_name_validate = xStreamModel.get_suggested_name(str_name)
    --print("str_name,str_name_validate",str_name,str_name_validate)
    return (str_name == str_name_validate) 
  end

  local navigate_to_model = function()
    local file_path = renoise.app():prompt_for_filename_to_read({"*.lua"},"Open model definition")
    --print("file_path",file_path)
    if (file_path ~= "") then
      -- attempt to load model
      local model = xStreamModel(self.xstream)
      local passed,err = model:load_definition(file_path)
      --print("passed,err",passed,err)
      if not passed and err then
        renoise.app():show_warning(err)
        return
      end
      model.file_path = xStreamModel.get_normalized_file_path(model.name)
      if not validate_model_name(model.name) then
        renoise.app():show_warning("Error: a model already exists with this name")
        return
      end
      add_save_and_close(model)
    end
  end

  local show_prev_page = function()
    if (self.model_dialog_page > 1) then
      self.model_dialog_page = self.model_dialog_page - 1
    end
    self:update_model_dialog()
  end

  local show_next_page = function()

    if (self.model_dialog_page == 1) then

      if (self.model_dialog_option == 2) then -- paste string (clear)
        local view_definition = vb.views["xStreamNewModelDialogDefinition"]
        view_definition.text = ""
      elseif (self.model_dialog_option == 3) then -- locate file (...)
        navigate_to_model()
      end

    elseif (self.model_dialog_page == 2) then

      if (self.model_dialog_option == 1) then -- create from scratch
        -- ensure unique name
        local view_name = vb.views["xStreamNewModelDialogName"]
        if not validate_model_name(view_name.text) then
          renoise.app():show_warning("Error: a model already exists with this name")
          return
        else
          -- we are done - 
          local passed,err = self.xstream:create_model(view_name.text)
          if not passed and err then
            renoise.app():show_warning(err)
            return
          end 
          self.model_dialog:close()
          self.model_dialog = nil
        end
      elseif (self.model_dialog_option == 2) then -- paste string
        -- check for syntax errors
        local view_textfield = vb.views["xStreamNewModelDialogDefinition"]
        local model = xStreamModel(self.xstream)
        local passed,err = model:load_from_string(view_textfield.text)
        if not passed and err then
          renoise.app():show_warning(err)
          model = nil
          return
        else
          add_save_and_close(model)
        end
      elseif (self.model_dialog_option == 3) then -- locate file
        self.model_dialog:close()
        self.model_dialog = nil
      end

    end

    self.model_dialog_page = self.model_dialog_page + 1
    self:update_model_dialog()
  end

  local content = vb:column{
    vb:space{
      width = PAGE_W,
    },
    vb:row{
      margin = 6,
      vb:row{
        vb:space{
          height = PAGE_H,
        },
        vb:column{
          id = "xStreamNewModelDialogPage1",
          vb:text{
            text = "Please choose an option",
          },
          vb:chooser{
            id = "xStreamNewModelDialogOptionChooser",
            value = self.model_dialog_option,
            items = {
              "Create from scratch (empty)",
              "Paste from clipboard",
              "Locate a file on disk",
            },
            notifier = function(idx)
              self.model_dialog_option = idx
            end
          },
        },
        vb:column{
          visible = false,
          id = "xStreamNewModelDialogPage2",
          vb:column{
            id = "xStreamNewModelDialogPage2Option1",
            vb:text{
              text = "Please specify a (unique) name for the model",
            },
            vb:textfield{
              id = "xStreamNewModelDialogName",
              text = "",
              width = PAGE_W-20,
            },
          },
          vb:column{
            id = "xStreamNewModelDialogPage2Option2",
            vb:text{
              text = "Please paste the lua string here",
            },
            vb:multiline_textfield{
              text = "",
              font = "mono",
              id = "xStreamNewModelDialogDefinition",
              height = TEXT_H,
              width = xStreamUI.CALLBACK_EDITOR_W,
            },
          },
          vb:column{
            id = "xStreamNewModelDialogPage2Option3",
            vb:row{
              vb:text{
                text = "Please choose a file",
              },
              vb:button{
                text = "Browse",
                notifier = function()
                  navigate_to_model()
                end
              }
            },

          },
        }
      },
    }
  }
  local navigation = vb:row{
    margin = 6,
    vb:button{
      id = "xStreamNewModelDialogPrevButton",
      text = "Previous",
      active = false,
      notifier = function()
        show_prev_page()
      end
    },
    vb:button{
      id = "xStreamNewModelDialogNextButton",
      text = "Next",
      notifier = function()
        show_next_page()
      end
    },
    vb:button{
      id = "xStreamNewModelDialogCancelButton",
      text = "Cancel",
      notifier = function()
        self.model_dialog:close()
        self.model_dialog = nil
      end
    },
  }

  return vb:column{
    content,
    navigation,
  }

end

-------------------------------------------------------------------------------

function xStreamUI:update_model_dialog()

  local vb = self.vb

  -- update page

  local view_page_1       = vb.views["xStreamNewModelDialogPage1"]
  local view_page_2       = vb.views["xStreamNewModelDialogPage2"]
  local view_page_2_opt1  = vb.views["xStreamNewModelDialogPage2Option1"]
  local view_page_2_opt2  = vb.views["xStreamNewModelDialogPage2Option2"]
  local view_page_2_opt3  = vb.views["xStreamNewModelDialogPage2Option3"]
  local view_opt_chooser  = vb.views["xStreamNewModelDialogOptionChooser"]

  view_page_1.visible = false
  view_page_2.visible = false
  view_page_2_opt1.visible = false
  view_page_2_opt2.visible = false
  view_page_2_opt3.visible = false

  if (self.model_dialog_page == 1) then
    view_page_1.visible = true
    view_opt_chooser.value = self.model_dialog_option
  elseif (self.model_dialog_page == 2) then
    view_page_2.visible = true
    if (self.model_dialog_option == 1) then
      view_page_2_opt1.visible = true
      local str_name = xStreamModel.get_suggested_name(xStreamModel.DEFAULT_NAME)       
      local view_name = vb.views["xStreamNewModelDialogName"]
      view_name.text = str_name
    elseif (self.model_dialog_option == 2) then
      view_page_2_opt2.visible = true
    elseif (self.model_dialog_option == 3) then
      view_page_2_opt3.visible = true
    end
  end

  -- update navigation

  local view_prev_button  = vb.views["xStreamNewModelDialogPrevButton"]
  local view_next_button  = vb.views["xStreamNewModelDialogNextButton"]
  view_prev_button.active = (self.model_dialog_page > 1) and true or false
  view_next_button.text = (self.model_dialog_page == 2) and "Done" or "Next"


end

-------------------------------------------------------------------------------

function xStreamUI:build_args_editor()

  local vb = self.vb
  local label_w = 75
  local control_w = 165
  local control_short_w = 80
  local display_as_items = table.copy(xStreamArg.DISPLAYS)
  table.insert(display_as_items,1,"(select)")
  local content = vb:column{
    vb:space{
      height = 6,
    },
    vb:column{
      style = "group",
      margin = 4,
      spacing = 1,
      vb:row{
        tooltip = "Enter a name for the argument - it will be accessed in the"
                .."\ncallback using this syntax: 'args.your_name_here'"
                .."\n(note: xStream will offer to update the callback when you"
                .."\nare assigning a new name to an existing argument)",
        vb:text{
          text = "name",
          font = "mono",
          width = label_w,
        },
        vb:textfield{
          id = "xStreamArgsEditorName",
          value = "...",
          width = control_w,
        },
      },
      vb:row{
        tooltip = "Enter a description for the argument (this will appear"
                .."\nas a tooltip when you hover the mouse over the control)",
        vb:text{
          text = "description",
          font = "mono",
          width = label_w,
        },
        vb:multiline_textfield{
          id = "xStreamArgsEditorDescription",
          text = "...",
          width = control_w,
          height = 34,
        }
      },
      vb:column{ -- bind or poll
        vb:row{
          tooltip = "Determine if the argument is bound to, or polling some"
                  .."\nvalue in Renoise. Choosing either option will cause"
                  .."\nthe value to be automatically set/synchronized"
                  .."\n(note: can restrict min/max to a valid range)",
          vb:text{
            text = "poll/bind",
            font = "mono",
            width = label_w,
          },
          vb:popup{
            id = "xStreamArgsEditorBindOrPoll",
            width = 50,
            items = {
              "off",
              "bind",
              "poll",
            },
            notifier = function(idx)
              local view_text = vb.views["xStreamArgsEditorBindOrPollValue"]
              local view_min = vb.views["xStreamArgsEditorMinValue"]
              local view_max = vb.views["xStreamArgsEditorMaxValue"]
              view_text.active = (idx > 1) 
              view_min.active = (idx ~= 2) 
              view_max.active = (idx ~= 2) 
            end,
          },
          vb:textfield{
            id = "xStreamArgsEditorBindOrPollValue",
            text = "...",
            --font = "mono",
            width = control_w-50,
          },
        },

      },

      vb:column{ -- impacts_buffer
        vb:row{
          tooltip = "When this is enabled, the buffer is recalculated each time"
                  .."\nthe argument value has changed. This ensures that changes"
                  .."\nare written to the pattern as fast as possible"
                  .."\nDefault value is 'enabled'",
          vb:text{
            text = "re-buffer",
            font = "mono",
            width = label_w,
          },
          vb:checkbox{
            id = "xStreamArgsEditorImpactsBuffer",
            value = false,
          },

        },

      },


      vb:row{ -- value-type
        tooltip = "Determine the basic type of value",
        vb:text{
          text = "value-type",
          font = "mono",
          width = label_w,
        },
        vb:popup{
          id = "xStreamArgsEditorType",
          items = xStreamArg.BASE_TYPES,
          notifier = function()
            local view_props = self.vb.views["xStreamArgsEditorPropControls"]
            local view_popup = self.vb.views["xStreamArgsEditorDisplayAs"]
            local view_bop = self.vb.views["xStreamArgsEditorBindOrPoll"]
            local view_bop_value = self.vb.views["xStreamArgsEditorBindOrPollValue"]
            view_props.visible = false
            view_popup.value = 1
            view_bop.value = 1
            view_bop_value.text = ""
          end,
        },
      },
      vb:row{ -- display as
        tooltip = "Choose a supported display/edit control",
        vb:text{
          text = "display_as",
          font = "mono",
          width = label_w,
        },
        vb:popup{
          id = "xStreamArgsEditorDisplayAs",
          items = display_as_items,
          notifier = function(idx)
            --print("idx",idx)
            self:show_relevant_arg_edit_controls(idx-1)
            local view_props = self.vb.views["xStreamArgsEditorPropControls"]
            view_props.visible = true
          end
        },
      },
      vb:column{
        id = "xStreamArgsEditorPropControls",
        vb:row{
          tooltip = "Specify the minimum value"
                  .."\nNote: 'bind' sets this value automatically)",
          id = "xStreamArgsEditorMinValueRow",
          vb:text{
            text = "min",
            font = "mono",
            width = label_w,
          },
          vb:row{
            style = "plain",
            vb:valuefield{
              id = "xStreamArgsEditorMinValue",
              value = 0,
              min = xStreamUI.ARGS_MIN_VALUE,
              max = xStreamUI.ARGS_MAX_VALUE,
              width = control_short_w,
            },
          },
        },
        vb:row{
          id = "xStreamArgsEditorMaxValueRow",
          tooltip = "Specify the maximum value"
                  .."\nNote: 'bind' sets this value automatically)",
          vb:text{
            text = "max",
            font = "mono",
            width = label_w,
          },
          vb:row{
            style = "plain",
            vb:valuefield{
              id = "xStreamArgsEditorMaxValue",
              value = 0,
              min = xStreamUI.ARGS_MIN_VALUE,
              max = xStreamUI.ARGS_MAX_VALUE,
              width = control_short_w,
            },
          },
        },
        vb:row{
          tooltip = "Specify if value is zero-based",
          id = "xStreamArgsEditorZeroBasedRow",
          vb:text{
            text = "zero-based",
            font = "mono",
            width = label_w,
          },
          vb:checkbox{
            id = "xStreamArgsEditorZeroBased",
            value = false,
          },
        },
        vb:row{
          id = "xStreamArgsEditorItemsRow",
          tooltip = "Specify items for a popup/chooser/switch",
          vb:text{
            text = "items",
            font = "mono",
            width = label_w,
          },
          vb:multiline_textfield{
            id = "xStreamArgsEditorItems",
            value = "...",
            width = control_w,
            height = 60,
          },
        },
      },
      vb:column{
        vb:space{
          height = 6,
        },
        vb:row{
          vb:button{
            tooltip = "Remove this argument",
            text = "Remove",
            notifier = function()
              local str_msg = "Are you sure you want to remove this argument?"
                            .."\n(the model might stop working if it's in use...)"
              local choice = renoise.app():show_prompt("Remove argument",str_msg,{"OK","Cancel"})
              if (choice == "OK") then
                local idx = self.xstream.selected_model.args.selected_index
                self.xstream.selected_model.args:remove(idx)
                self.args_editor_visible = false
              end
            end
          },
          vb:button{
            tooltip = "Update the argument with current settings",
            text = "Apply changes",
            notifier = function()
              local applied,err = self:apply_arg_settings()
              if not applied and err then
                renoise.app():show_warning(err)
              elseif applied then
                --self.args_editor_visible = false
              end
            end
          }
        }
      }
    },
  }

  return content

end


--------------------------------------------------------------------------------

function xStreamUI:show_relevant_arg_edit_controls(display_as)
  TRACE("xStreamUI:show_relevant_arg_edit_controls(display_as)",display_as)

  local view_min_value_row  = self.vb.views["xStreamArgsEditorMinValueRow"]
  local view_max_value_row  = self.vb.views["xStreamArgsEditorMaxValueRow"]
  local view_zero_based_row = self.vb.views["xStreamArgsEditorZeroBasedRow"]
  local view_items_row      = self.vb.views["xStreamArgsEditorItemsRow"]

  local supports_min_max = table.find(xStreamArg.SUPPORTS_MIN_MAX,display_as) and true or false
  view_min_value_row.visible = supports_min_max
  view_max_value_row.visible = supports_min_max
  
  local supports_zero_based = table.find(xStreamArg.SUPPORTS_ZERO_BASED,display_as) and true or false
  view_zero_based_row.visible = supports_zero_based

  local items_required = table.find(xStreamArg.REQUIRES_ITEMS,display_as) and true or false
  view_items_row.visible = items_required 

end

--------------------------------------------------------------------------------
-- create arg from the current state of the argument editor 
-- @param arg_index
-- @return table or false 
-- @return string, error message when failed

function xStreamUI:create_arg_descriptor(arg_index,arg_value)

  local view_name           = self.vb.views["xStreamArgsEditorName"]
  local view_description    = self.vb.views["xStreamArgsEditorDescription"]
  local view_type           = self.vb.views["xStreamArgsEditorType"]
  local view_display_as     = self.vb.views["xStreamArgsEditorDisplayAs"]
  local view_buffer         = self.vb.views["xStreamArgsEditorImpactsBuffer"]
  local view_min_value      = self.vb.views["xStreamArgsEditorMinValue"]
  local view_max_value      = self.vb.views["xStreamArgsEditorMaxValue"]
  local view_zero_based     = self.vb.views["xStreamArgsEditorZeroBased"]
  local view_items          = self.vb.views["xStreamArgsEditorItems"]
  local view_bop   = self.vb.views["xStreamArgsEditorBindOrPoll"]
  local view_bop_value = self.vb.views["xStreamArgsEditorBindOrPollValue"]

  local args = self.xstream.selected_model.args
  local str_type = xStreamArg.BASE_TYPES[view_type.value]

  local supported_types = function(t)
    local rslt = {}
    for k,v in ipairs(t) do
      table.insert(rslt,xStreamArg.DISPLAYS[v])
    end
    return ("Unsupported 'display_as' value - please change the value-type."
      .."\nSupported: %s"):format(table.concat(rslt,","))
  end

  -- if we have changed value type, set to default value
  if type(arg_value) ~= str_type then
    if (str_type == "number") then
      arg_value = view_min_value.value
    elseif (str_type == "boolean") then
      arg_value = false
    elseif (str_type == "string") then
      arg_value = ""
    end
  end

  --print("*** xStreamUI:apply_arg_settings - arg_value",arg_value)

  -- *enabled* bind/poll should not contain blank lines

  local arg_bind,arg_poll
  if (view_bop.value == 2) then
    arg_bind = view_bop_value.text
    if (arg_bind == "") then
      local keys = table.concat(xObservable.get_keys_by_type(str_type,"rns."),"\n")
      return false, ("Error: 'bind' needs an observable property, try one of these: \n%s"):format(keys)
    end
  elseif (view_bop.value == 3) then
    arg_poll = view_bop_value.text
    if (arg_poll == "") then
      return false, "Error: 'poll' should reference a property that match the type of value, e.g."
                  .."\n'rns.selected_instrument_index' for a number, or "
                  .."\n'rns.transport.edit_mode' for a boolean value"
    end
  end

  local arg_props = {}
  
  -- validate display_as (correct type)

  local base_type = view_type.value
  local display_as = view_display_as.value-1
  local err
  if (base_type == xStreamArg.BASE_TYPE.NUMBER) then
    if not table.find(xStreamArg.NUMBER_DISPLAYS,display_as) then
      err =  supported_types(xStreamArg.NUMBER_DISPLAYS)
    else
      if table.find(xStreamArg.SUPPORTS_MIN_MAX,display_as) then
        arg_props.min = view_min_value.value
        arg_props.max = view_max_value.value
        if (arg_props.max < arg_props.min) then
          return false, "Error: 'max' needs to be higher than 'min'"
        end
      end
      if table.find(xStreamArg.SUPPORTS_ZERO_BASED,display_as) then
        arg_props["zero_based"] = view_zero_based.value
      end
      if table.find(xStreamArg.REQUIRES_ITEMS,display_as) then
        local arg_items = {}
        for k,v in ipairs(view_items.paragraphs) do
          if (v == "") then
            return false, "Error: 'items' should not contain blank lines"
          end
          table.insert(arg_items,xLib.trim(v))
        end
        arg_props.min = 1
        arg_props.max = #arg_items
        arg_props.items = arg_items
      end
    end
  elseif (base_type == xStreamArg.BASE_TYPE.BOOLEAN) then
    if not table.find(xStreamArg.BOOLEAN_DISPLAYS,display_as) then
      err = supported_types(xStreamArg.BOOLEAN_DISPLAYS)
    end
  elseif (base_type == xStreamArg.BASE_TYPE.STRING) then
    if not table.find(xStreamArg.STRING_DISPLAYS,display_as) then
      err =  supported_types(xStreamArg.STRING_DISPLAYS)
    end
  end
  if err then
    return false, err
  end

  arg_props.display_as = xStreamArg.DISPLAYS[display_as]

  -- validate bind + poll

  if arg_bind then
    local is_valid,err = args:is_valid_bind_value(arg_bind,str_type)
    if not is_valid then
      return false,err
    end
  end

  if arg_poll then
    local is_valid,err = args:is_valid_poll_value(arg_poll)
    if not is_valid then
      return false,err
    end
  end


  -- props: min,max
  --print("arg_value pre",arg_value)

  if type(arg_value)=="number" and arg_props.min and arg_props.max then
    arg_value = math.min(arg_props.max,arg_value)
    arg_value = math.max(arg_props.min,arg_value)
  end

  arg_props.impacts_buffer = view_buffer.value

  -- return table 

  --print("... arg_props",rprint(arg_props))
  --print("arg_value post",arg_value)

  local descriptor = {
    name = view_name.value,
    description = view_description.text,
    value = arg_value,
    bind = arg_bind,
    poll = arg_poll,
    properties = arg_props,
  }

  return descriptor

end

--------------------------------------------------------------------------------
-- @return bool, true when applied
-- @return string, error message when failed

function xStreamUI:apply_arg_settings()
  TRACE("xStreamUI:apply_arg_settings()")

  local model = self.xstream.selected_model
  local arg_idx = model.args.selected_index

  -- changed value type? 
  local old_value = model.args.args[arg_idx].value
  local arg_descriptor,err = self:create_arg_descriptor(arg_idx,old_value)
  if not arg_descriptor then
    return false,err
  end

  --print(">>> arg_descriptor...",rprint(arg_descriptor))

  --print("arg_idx",arg_idx)
  --print("args:replace",args.replace)
  local replaced,err = model.args:replace(arg_idx,arg_descriptor)
  if not replaced and err then
    return false,err
  end

  return true

end

--------------------------------------------------------------------------------

function xStreamUI:get_args_label_w()

  if not self.xstream.selected_model then
    return 1
  end

  local args = self.xstream.selected_model.args
  local arg_max_length = 0
  for k,arg in ipairs(args.args) do
    arg_max_length = math.max(arg_max_length,#arg.name)
  end
  return (arg_max_length > 0) and arg_max_length*xStreamUI.MONO_CHAR_W or 30

end

--------------------------------------------------------------------------------
-- (re-)build list of arguments 

function xStreamUI:build_args()
  TRACE("xStreamUI:build_args()")

  if not self.xstream.selected_model then
    --print("*** No model selected")
    return
  end

  local vb = self.vb
  local args = self.xstream.selected_model.args

  local vb_container = vb.views["xStreamArgsContainer"]
  for k,v in ipairs(self.arg_views) do
    vb_container:remove_child(v)
  end

  self.arg_labels = {}
  self.arg_bops = {}
  self.arg_views = {}

  if (args.length == 0) then
    return
  end

  local args_label_w = self:get_args_label_w()

  local slider_width = xStreamUI.ARGS_SLIDER_W
  local full_width = xStreamUI.ARGS_SELECTOR_W
  local items_width = xStreamUI.ARGS_SELECTOR_W-60

  -- add a custom control for each argument
  for k,arg in ipairs(args.args) do

    -- custom number/string converters 
    local fn_tostring = nil
    local fn_tonumber = nil
    
    --print("arg.properties",rprint(arg.properties))
    local display_as = table.find(xStreamArg.DISPLAYS,arg.properties.display_as) 

    if display_as == xStreamArg.DISPLAY_AS.HEX then
      fn_tostring = function(val)
        local hex_digits = xLib.get_hex_digits(arg.properties.max) 
        val = arg.properties.zero_based and val-1 or val
        return ("%."..tostring(hex_digits).."X"):format(val)
      end 
      fn_tonumber = function(str)
        local val = tonumber(str, 16)
        val = arg.properties.zero_based and val+1 or val
        return val
      end
    elseif display_as == xStreamArg.DISPLAY_AS.PERCENT then
      fn_tostring = function(val)
        return ("%.3f %%"):format(val)
      end 
      fn_tonumber = function(str)
        return tonumber(string.sub(str,1,#str-1))
      end
    elseif display_as == xStreamArg.DISPLAY_AS.NOTE then
      fn_tostring = function(val)
        return xNoteColumn.note_value_to_string(math.floor(val))
      end 
      fn_tonumber = function(str)
        return xNoteColumn.note_string_to_value(str)
      end
    elseif display_as == xStreamArg.DISPLAY_AS.INTEGER then
      fn_tostring = function(val)
        return ("%d"):format(val)
      end 
      fn_tonumber = function(str)
        return tonumber(str)
      end
    else
      fn_tostring = function(val)
        val = arg.properties.zero_based and val-1 or val
        return ("%s"):format(val)
      end 
      fn_tonumber = function(str)
        local val = tonumber(str)
        val = arg.properties.zero_based and val+1 or val
        return val
      end
    end
    local model_name = self.xstream.selected_model.name

    local view_label = vb:text{
      text = arg.name,
      width = args_label_w,
      font = "mono",
    }

    local view_bop = vb:bitmap{
      bitmap = "./source/icons/bind_or_poll.bmp",
      mode = "body_color",
      --width = xStreamUI.BITMAP_BUTTON_W,
      height = xStreamUI.BITMAP_BUTTON_H-1,
    }

    local view_label_rack = vb:row{
      vb:checkbox{
        visible = false,
        notifier = function()
          self.xstream.selected_model.args.selected_index = k
        end,
      },
      view_label,
    }

    local view = vb:row{
      --[[
      vb:button{
        bitmap = "./source/icons/delete_small.bmp",
        notifier = function()
          self.xstream.selected_model.args:remove(k)
        end,
      },
      ]]
      vb:column{
        vb:space{
          height = 2,
        },
        vb:checkbox{
          bind = arg.locked_observable,
          width = 14,
          height = 14,
          tooltip = "Lock value - can still be changed manually," 
                  .."\nbut prevents changes when switching presets"
                  .."\nor receiving values from the Renoise API.",
        },
      }
    }

    if (type(arg.observable) == "ObservableNumber") then

      if arg.properties.items then -- select (default to popup)
        display_as = display_as or xStreamArg.DISPLAY_AS.POPUP

        if (display_as == xStreamArg.DISPLAY_AS.POPUP) then
          --print("display_as popup",arg.name)
          view:add_child(vb:row{
            tooltip = arg.description,
            view_label_rack,
            vb:popup{
              items = arg.properties.items,
              value = arg.value,
              width = items_width,
              bind = arg.observable,
            },
            view_bop,
          })
        elseif (display_as == xStreamArg.DISPLAY_AS.CHOOSER) then
          view:add_child(vb:row{
            tooltip = arg.description,
            view_label_rack,
            vb:chooser{
              items = arg.properties.items,
              value = arg.value,
              width = items_width,
              bind = arg.observable,
            },
            view_bop,
          })
        elseif (display_as == xStreamArg.DISPLAY_AS.SWITCH) then
          view:add_child(vb:row{
            tooltip = arg.description,
            view_label_rack,
            vb:switch{
              items = arg.properties.items,
              value = arg.value,
              width = items_width,
              bind = arg.observable,
            },
            view_bop,
          })
        else    
          LOG("Unsupported 'display_as' property - please review this argument:"..arg.name)
        end
      elseif (display_as == xStreamArg.DISPLAY_AS.INTEGER) 
        or (display_as == xStreamArg.DISPLAY_AS.HEX) 
      then -- whole numbers
        view:add_child(vb:row{
          tooltip = arg.description,
          view_label_rack,
          vb:valuebox{
            tostring = fn_tostring,
            tonumber = fn_tonumber,
            value = arg.value,
            min = arg.properties.min or xStreamUI.ARGS_MIN_VALUE,
            max = arg.properties.max or xStreamUI.ARGS_MAX_VALUE,
            bind = arg.observable,
          },
          view_bop,
        })
      else -- floating point (default to minislider)
        view:add_child(vb:row{
          tooltip = arg.description,
          view_label_rack,
        })

        display_as = display_as or xStreamArg.DISPLAY_AS.MINISLIDER

        if (display_as == xStreamArg.DISPLAY_AS.MINISLIDER) 
          or (display_as == xStreamArg.DISPLAY_AS.PERCENT) 
          or (display_as == xStreamArg.DISPLAY_AS.NOTE) 
        then
          view:add_child(vb:row{
            vb:minislider{
              value = arg.value,
              width = slider_width,
              height = 17,
              min = arg.properties.min or xStreamUI.ARGS_MIN_VALUE,
              max = arg.properties.max or xStreamUI.ARGS_MAX_VALUE,
              bind = arg.observable,
            },
            view_bop,
          })
        elseif (display_as == xStreamArg.DISPLAY_AS.ROTARY) then
          view:add_child(vb:row{
            vb:rotary{
              value = arg.value,
              height = 24,
              min = arg.properties.min or xStreamUI.ARGS_MIN_VALUE,
              max = arg.properties.max or xStreamUI.ARGS_MAX_VALUE,
              bind = arg.observable,
            },
            view_bop,
          })
        end

        -- add value readout after control
        view:add_child(vb:valuefield{
          tostring = fn_tostring,
          tonumber = fn_tonumber,
          value = arg.value,
          min = arg.properties.min or xStreamUI.ARGS_MIN_VALUE,
          max = arg.properties.max or xStreamUI.ARGS_MAX_VALUE,
          bind = arg.observable,
        })
      end
    elseif (type(arg.observable) == "ObservableBoolean") then
      display_as = display_as or xStreamArg.DISPLAY_AS.CHECKBOX
      if (display_as == xStreamArg.DISPLAY_AS.CHECKBOX) then
        view:add_child(vb:row{
          tooltip = arg.description,
          view_label_rack,
          vb:checkbox{
            value = arg.value,
            bind = arg.observable,
          },
          view_bop,
        })
      end
    elseif (type(arg.observable) == "ObservableString") then
      display_as = display_as or xStreamArg.DISPLAY_AS.TEXTFIELD
      if (display_as == xStreamArg.DISPLAY_AS.TEXTFIELD) then
        view:add_child(vb:row{
          tooltip = arg.description,
          view_label_rack,
          vb:textfield{
            text = arg.value,
            width = full_width,
            bind = arg.observable,
          },
          view_bop,
        })
      end
    end

    if view then
      table.insert(self.arg_bops,view_bop)
      table.insert(self.arg_labels,view_label)
      table.insert(self.arg_views,view)
      vb_container:add_child(view)
    end

  end

end


--------------------------------------------------------------------------------

function xStreamUI:update_args()

  local model = self.xstream.selected_model

  -- show message if not args
  local view_msg = self.vb.views["xStreamArgsNoneMessage"]
  if model then
    view_msg.visible = self.model_args_visible 
      and (#model.args.args == 0) 
  else
    view_msg.visible = self.model_args_visible and true or false
  end

  -- update labels
  for k,v in ipairs(self.arg_labels) do
    v.text = model and model.args.args[k].name or ""
    v.font = model and (k == model.args.selected_index) 
      and "bold" or "mono"
  end

  -- update bops
  for k,v in ipairs(self.arg_bops) do
    local bop = model and model.args.args[k]:get_bop()
    v.visible = (model and bop) and true or false
    v.tooltip = (model and bop) and "This argument is bound to/polling '"..bop.."'" or ""
  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_args_controls()

  local view_up = self.vb.views["xStreamArgsMoveUpButton"]
  local view_down = self.vb.views["xStreamArgsMoveDownButton"]
  local view_edit = self.vb.views["xStreamArgsEditButton"]

  local model = self.xstream.selected_model
  local has_selected = (model and model.args.selected_index > 0) and true or false
  view_up.active = has_selected
  view_down.active = has_selected
  view_edit.active = has_selected


end

--------------------------------------------------------------------------------

function xStreamUI:update_args_selector()
  TRACE("xStreamUI:update_args_selector()")

  local model = self.xstream.selected_model
  local view_popup = self.vb.views["xStreamArgsSelector"]
  if model and (#model.args.args > 0) then
    local items = model.args:get_names()
    table.insert(items,1,xStreamUI.NO_ARG_SELECTED)
    view_popup.items = items
    view_popup.value = model.args.selected_index+1
  else
    view_popup.items = {xStreamUI.NO_ARGS_AVAILABLE}
    view_popup.value = 1
  end

end

--------------------------------------------------------------------------------
-- if compact mode, display a single argument at a time

function xStreamUI:update_args_visibility()
  TRACE("xStreamUI:update_args_visibility()")

  for k,v in ipairs(self.arg_views) do
    if not self.xstream.selected_model then
      v.visible = false
    elseif self.model_args_visible 
      and not self.args_editor_visible
    then 
      v.visible = true
    else
      v.visible = (k == self.xstream.selected_model.args.selected_index)
    end
  end

  local args_label_w = self:get_args_label_w()
  for k,v in ipairs(self.arg_labels) do
    v.width = (self.model_args_visible and not self.args_editor_visible) and args_label_w or 2
    v.visible = self.model_args_visible
  end

  --self.vb.views["xStreamArgsPanel"].width = xStreamUI.ARGS_SELECTOR_W

end

--------------------------------------------------------------------------------
-- (re-)build and update list of models 

function xStreamUI:build_model_list()
  TRACE("xStreamUI:build_model_list()")

  local vb = self.vb
  local vb_container = vb.views["xStreamModelContainer"]

  local count = 1
  while self.model_views[count] do
    self.model_views[count]:remove_child(
      vb.views["xStreamModelSchedule"..count])
    vb.views["xStreamModelSchedule"..count] = nil
    self.model_views[count]:remove_child(
      vb.views["xStreamModelSelect"..count])
    vb.views["xStreamModelSelect"..count] = nil
    self.model_views[count]:remove_child(
      vb.views["xStreamModelFavorite"..count])
    vb.views["xStreamModelFavorite"..count] = nil
    count = count + 1
  end

  for k,v in ipairs(self.model_views) do
    vb_container:remove_child(v)
  end

  self.model_views = {}

  for k,v in ipairs(self.xstream.models) do
  
    local row = vb:row{
      vb:button{
        text = xStreamUI.SCHEDULE_TEXT.OFF, 
        id = "xStreamModelSchedule"..k,
        tooltip = "Schedule this model",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          self.xstream:schedule_item(v.name)
        end,
      },
      vb:button{
        text = "", 
        id = "xStreamModelSelect"..k,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          --print("*** xStreamUI - model selector (list) - selected_model_index =",k)
          self.xstream.selected_model_index = k
        end,
      },
      vb:button{
        text = "", 
        id = "xStreamModelFavorite"..k,
        tooltip = "Favorite this model (toggle)",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          self.xstream.favorites:toggle_item(v.name)
        end,
      },
    }
    vb_container:add_child(row)
    table.insert(self.model_views,row)
    self:update_model_list_row(k)

  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_args_editor()
  TRACE("xStreamUI:update_args_editor()")

  if not self.xstream.selected_model then
    --print("*** xStreamUI:update_args_editor - no model selected...")
    return
  end

  if not self.args_editor_visible then
    --print("*** xStreamUI:update_args_editor - editor not visible")
    return
  end

  --local view_locked       = self.vb.views["xStreamArgsEditorLocked"]
  local view_name         = self.vb.views["xStreamArgsEditorName"]
  local view_description  = self.vb.views["xStreamArgsEditorDescription"]
  local view_type         = self.vb.views["xStreamArgsEditorType"]
  local view_display_as   = self.vb.views["xStreamArgsEditorDisplayAs"]
  local view_buffer       = self.vb.views["xStreamArgsEditorImpactsBuffer"]
  local view_props        = self.vb.views["xStreamArgsEditorPropControls"]
  local view_min_value    = self.vb.views["xStreamArgsEditorMinValue"]
  local view_max_value    = self.vb.views["xStreamArgsEditorMaxValue"]
  local view_zero_based   = self.vb.views["xStreamArgsEditorZeroBased"]
  local view_items        = self.vb.views["xStreamArgsEditorItems"]
  local view_poll_or_bind = self.vb.views["xStreamArgsEditorBindOrPoll"]
  local view_bop_value    = self.vb.views["xStreamArgsEditorBindOrPollValue"]

  local has_selected = (self.xstream.selected_model.args.selected_index > 0)

  view_name.active = has_selected
  view_description.active = has_selected
  view_type.active = has_selected
  view_display_as.active = has_selected
  view_buffer.active = has_selected
  --view_props.active = has_selected
  view_min_value.active = has_selected
  view_max_value.active = has_selected
  view_zero_based.active = has_selected
  view_items.active = has_selected
  view_poll_or_bind.active = has_selected
  view_bop_value.active = has_selected

  local arg = self.xstream.selected_model.args.selected_arg
  if not arg then
    --print("*** xStreamUI:update_args_editor - no arg selected...")
    return
  end
  
  -- TODO deduce valid range from all known renoise observables (xObservable)
  if (view_poll_or_bind.value == 1) then
    view_min_value.active = true
  else
    view_min_value.active = false
    view_min_value.value = 1
  end

  --view_locked.value = arg.locked
  view_name.text = arg.name
  view_description.text = arg.description or ""
  
  local base_type
  if (type(arg.observable) == "ObservableNumber") then
    base_type = xStreamArg.BASE_TYPE.NUMBER
  elseif (type(arg.observable) == "ObservableBoolean") then
    base_type = xStreamArg.BASE_TYPE.BOOLEAN
  elseif (type(arg.observable) == "ObservableString") then
    base_type = xStreamArg.BASE_TYPE.STRING
  else
    --print("unexpected base type",arg.observable,type(arg.observable))
    return
  end
  view_type.value = base_type

  view_props.visible = true

  -- supply a default display 
  local display_as = table.find(xStreamArg.DISPLAYS,arg.properties.display_as)
  if not display_as then
    if (base_type == xStreamArg.BASE_TYPE.NUMBER) then
      display_as = arg.properties.items and xStreamArg.DISPLAY_AS.POPUP
        or xStreamArg.DISPLAY_AS.FLOAT
    elseif (base_type == xStreamArg.BASE_TYPE.BOOLEAN) then
      display_as = xStreamArg.DISPLAY_AS.CHECKBOX
    elseif (base_type == xStreamArg.BASE_TYPE.STRING) then
      display_as = xStreamArg.DISPLAY_AS.STRING
    end
  end
  --print("display_as",display_as)
  view_display_as.value = display_as+1

  local bop_value,bop_str
  if (arg.bind_str) then
    bop_value = 2
    bop_str = arg.bind_str
  elseif (arg.poll_str) then
    bop_value = 3
    bop_str = arg.poll_str
  else
    bop_value = 1
    bop_str = ""
  end
  view_poll_or_bind.value = bop_value
  view_bop_value.active = (bop_value > 1)
  view_bop_value.text = bop_str

  view_buffer.value = arg.properties.impacts_buffer

  self:show_relevant_arg_edit_controls(display_as)
  
  view_min_value.value = arg.properties.min or xStreamUI.ARGS_MIN_VALUE
  view_max_value.value = arg.properties.max or xStreamUI.ARGS_MAX_VALUE
  view_zero_based.value = arg.properties.zero_based or false
  view_items.text = arg.properties.items and table.concat(arg.properties.items,"\n") or ""
  
end

--------------------------------------------------------------------------------
-- manually compute width of header - for some reason,
-- can't get the aligner to do the job 

function xStreamUI:resize_upper_panel()
  TRACE("xStreamUI:resize_upper_panel()")

  local val = self.show_editor
  if val then
    self.vb.views["xStreamTransportAligner"].width = -8 +
      self.vb.views["xStreamLowerPanels"].width
  else
    self.vb.views["xStreamTransportAligner"].width = -7 + 
      math.max(self.vb.views["xStreamFavoritesPanel"].width,
        self.vb.views["xStreamTransportRow"].width + 
          self.vb.views["xStreamToggleExpand"].width)
  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_model_title()
  TRACE("xStreamUI:update_model_title()")

  local model = self.xstream.selected_model
  local view_name = self.vb.views["xStreamCallbackName"]
  if model then
    view_name.text = ("%s %s"):format(
      model.file_path, model.modified and "*" or "")
  else
    view_name.text = ""
  end
end

--------------------------------------------------------------------------------

function xStreamUI:update_model_list()
  TRACE("xStreamUI:update_model_list()")
  for k,v in ipairs(self.xstream.models) do
    self:update_model_list_row(k)
  end
end

--------------------------------------------------------------------------------

function xStreamUI:update_model_list_row(model_idx)
  TRACE("xStreamUI:update_model_list_row(model_idx)",model_idx)

  local model = self.xstream.models[model_idx]
  if not model then 
    return
  end

  local selected = (self.xstream.selected_model_index == model_idx) 

  local view_bt = self.vb.views["xStreamModelSchedule"..model_idx]
  if view_bt then
    view_bt.color = selected and self.base_color_highlight or xLib.COLOR_DISABLED
  end

  local view_bt = self.vb.views["xStreamModelSelect"..model_idx]
  if view_bt then
    view_bt.text = ("%s%s"):format(model.name,(model.modified) and "*" or "")
    local model_color = selected and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED
    if (model.color > 0) then
      model_color = xColor.value_to_color_table(model.color)
      if selected then
        model_color = xColor.adjust_brightness(model_color,xStreamUI.BRIGHTEN_AMOUNT)
      end
    end
    view_bt.color = model_color
    view_bt.width = xStreamUI.MODEL_SELECTOR_W-xStreamUI.BITMAP_BUTTON_W-1
  end

  local view_bt = self.vb.views["xStreamModelFavorite"..model_idx]
  if view_bt then
    view_bt.color = selected and self.base_color_highlight or xLib.COLOR_DISABLED
    local str_text
    local favorited_model = self.xstream.favorites:get(model.name)
    if favorited_model then
      str_text = xStreamUI.FAVORITE_TEXT.ON
    elseif self.xstream.favorites:get_by_model(model.name) then
      str_text = xStreamUI.FAVORITE_TEXT.DIMMED
    else
      str_text = xStreamUI.FAVORITE_TEXT.OFF
    end
    view_bt.text = str_text
  end

  --print("update_model_list_row - got here")

end

--------------------------------------------------------------------------------

function xStreamUI:update_model_controls()
  TRACE("xStreamUI:update_model_controls()")

  local model = self.xstream.selected_model
  local save_bt = self.vb.views["xStreamModelSave"]
  local fav_bt = self.vb.views["xStreamFavoriteModel"]

  if model then
    save_bt.active = self.xstream.selected_model.modified
    local favorite_idx = self.xstream.favorites:get(model.name) 
    fav_bt.text = (favorite_idx) and xStreamUI.FAVORITE_TEXT.ON or xStreamUI.FAVORITE_TEXT.DIMMED
    if favorite_idx then
      self.selected_favorite_index = favorite_idx
    else
      self.selected_favorite_index = 0
    end
  else
    self.selected_favorite_index = 0
  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_model_selector()
  TRACE("xStreamUI:update_model_selector()")

  local view_popup = self.vb.views["xStreamModelSelector"]
  local model_names = self.xstream:get_model_names()
  table.insert(model_names,1,xStreamUI.NO_MODEL_SELECTED)
  self.vb.views["xStreamFavoriteModelSelector"].items = model_names
  view_popup.items = model_names
  view_popup.value = (self.xstream.selected_model_index == 0) 
    and 1 or self.xstream.selected_model_index+1
  
  --> compact popup
  local view_popup_compact = self.vb.views["xStreamCompactModelSelector"]
  view_popup_compact.items = view_popup.items
  view_popup_compact.value = view_popup.value

  --> launch models
  --local view_launch_models = self.vb.views["xStreamImplLaunchModel"]
  --view_launch_models.items = view_popup.items
  --view_launch_models.value = view_popup.value
  --self:set_launch_model(self.launch_model)

end

--------------------------------------------------------------------------------
-- activate the launch model

function xStreamUI:select_launch_model()

  for k,v in ipairs(self.xstream.models) do
    if (v.file_path == self.launch_model) then
      self.xstream.selected_model_index = k
    end
  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_launch_model_selector()

  local view_launch_models = self.vb.views["xStreamImplLaunchModel"]
  view_launch_models.items = self.xstream:get_model_names()
  for k,v in ipairs(self.xstream.models) do
    if (v.file_path == self.launch_model) then
      view_launch_models.value = k
    end
  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_preset_selector()
  TRACE("xStreamUI:update_preset_selector()")

  local model = self.xstream.selected_model
  local view_popup = self.vb.views["xStreamPresetSelector"]
  local view_popup_compact = self.vb.views["xStreamCompactPresetSelector"]

  if model then
    local preset_bank = model.selected_preset_bank
    local t = {}
    local t_compact = {}
    if (#model.selected_preset_bank.presets > 0) then
      -- gather preset names
      t = {"Select preset"}
      t_compact = {"Select"}
      for k,v in ipairs(preset_bank.presets) do
        local preset_name = model.selected_preset_bank:get_preset_display_name(k)
        table.insert(t,preset_name)
        table.insert(t_compact,("%.02d - %s"):format(k,preset_bank.name))
      end
    end
    view_popup.items = t
    view_popup_compact.items = t_compact

    view_popup.value = (preset_bank.selected_preset_index == 0) 
      and 1 or preset_bank.selected_preset_index+1

    view_popup_compact.value = (preset_bank.selected_preset_index == 0) 
      and 1 or preset_bank.selected_preset_index+1

  else
    view_popup.items = {}
    view_popup.value = 1
    view_popup_compact.items = {}
    view_popup_compact.value = 1
  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_scheduled_model(idx,txt)
  TRACE("xStreamUI:update_scheduled_model(idx,txt)",idx,txt)

  local str_id = "xStreamModelSchedule"..idx
  local view_bt = self.vb.views[str_id]
  if view_bt then
    view_bt.text = txt
  end

end

--------------------------------------------------------------------------------
-- (re-)build preset buttons

function xStreamUI:build_preset_list()
  TRACE("xStreamUI:build_preset_list()")

  if not self.xstream.selected_model then
    return
  end
  
  local vb = self.vb
  local model = self.xstream.selected_model

  local vb_container = vb.views["xStreamArgPresetContainer"]

  -- remove all existing buttons 
  local count = 1
  while self.preset_views[count] do
    self.preset_views[count]:remove_child(
      vb.views["xStreamModelPresetDelete"..count])
    vb.views["xStreamModelPresetDelete"..count] = nil
    self.preset_views[count]:remove_child(
      vb.views["xStreamModelPresetSchedule"..count])
    vb.views["xStreamModelPresetSchedule"..count] = nil
    self.preset_views[count]:remove_child(
      vb.views["xStreamModelPresetRecall"..count])
    vb.views["xStreamModelPresetRecall"..count] = nil
    self.preset_views[count]:remove_child(
      vb.views["xStreamModelPresetUpdate"..count])
    vb.views["xStreamModelPresetUpdate"..count] = nil
    self.preset_views[count]:remove_child(
      vb.views["xStreamPresetListMoveUpButton"..count])
    vb.views["xStreamPresetListMoveUpButton"..count] = nil
    self.preset_views[count]:remove_child(
      vb.views["xStreamPresetListMoveDownButton"..count])
    vb.views["xStreamPresetListMoveDownButton"..count] = nil
    self.preset_views[count]:remove_child(
      vb.views["xStreamModelPresetFavorite"..count])
    vb.views["xStreamModelPresetFavorite"..count] = nil
    count = count + 1
  end

  for k,v in ipairs(self.preset_views) do
    vb_container:remove_child(v)
  end


  self.preset_views = {}

  if (model.args.length == 0) then
    return
  end

  --local preset_names = model.selected_preset_bank.preset_names
  
  for k = 1,#model.selected_preset_bank.presets do
    
    local preset_name = model.selected_preset_bank:get_preset_display_name(k)

    local row = vb:row{
      vb:button{
        --text = "-",
        bitmap = "./source/icons/delete_small.bmp",
        id = "xStreamModelPresetDelete"..k,
        tooltip = "Remove this preset",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          model.selected_preset_bank:remove_preset(k)
          --self:build_preset_list()
        end
      },
      vb:button{
        text = xStreamUI.SCHEDULE_TEXT.OFF,
        id = "xStreamModelPresetSchedule"..k,
        tooltip = "Schedule this preset",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          self.xstream:schedule_item(model.name,k)
        end,
      },
      vb:button{
        text = preset_name,
        id = "xStreamModelPresetRecall"..k,
        tooltip = "Activate this preset",
        width = xStreamUI.PRESET_SELECTOR_W, ---xStreamUI.BITMAP_BUTTON_W+1,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          model.selected_preset_bank.selected_preset_index = k
        end,
      },
      vb:button{
        id = "xStreamPresetListMoveUpButton"..k,
        bitmap = "./source/icons/move_up.bmp",
        tooltip = "Move preset up in list",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          local presets = self.xstream.selected_model.selected_preset_bank
          --local preset_index = presets.selected_preset_index
          local got_moved,_ = presets:swap_index(k,k-1)
          if got_moved then
            presets.selected_preset_index = k - 1
          end
        end
      },
      vb:button{
        id = "xStreamPresetListMoveDownButton"..k,
        bitmap = "./source/icons/move_down.bmp",
        tooltip = "Move preset down in list",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          local presets = self.xstream.selected_model.selected_preset_bank
          --local preset_index = presets.selected_preset_index
          local got_moved,_ = presets:swap_index(k,k+1)
          if got_moved then
            presets.selected_preset_index = k + 1
          end
        end
      },
      vb:button{
        --text = "Update",
        bitmap = "./source/icons/update.bmp",
        id = "xStreamModelPresetUpdate"..k,
        tooltip = "Update this preset with the current settings",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          model.selected_preset_bank:update_preset(k)
        end
      },

      vb:button{
        text = "", 
        id = "xStreamModelPresetFavorite"..k,
        tooltip = "Favorite this preset (toggle)",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          local preset_bank_name = model.selected_preset_bank.name
          self.xstream.favorites:toggle_item(model.name,k,preset_bank_name)
        end,
      },

    }
    vb_container:add_child(row)
    table.insert(self.preset_views,row)
    self:update_preset_list_row(k)

  end


end

--------------------------------------------------------------------------------
-- update visual state of preset buttons

function xStreamUI:update_preset_list()
  TRACE("xStreamUI:update_preset_list()")

  local vb = self.vb
  for k = 1, #self.preset_views do
    if (vb.views["xStreamModelPresetRecall"..k]) then
      self:update_preset_list_row(k)
    end
  end

end

--------------------------------------------------------------------------------
-- update preset+preset bank controls (except the preset selector)

function xStreamUI:update_preset_controls()
  TRACE("xStreamUI:update_preset_controls()")

  local model = self.xstream.selected_model
  if not model then
    return
  end

  local vb = self.vb
  local is_default = model:is_default_bank()
  local preset_index = model.selected_preset_bank.selected_preset_index

  local view_popup      = vb.views["xStreamPresetBankSelector"]
  local rename_bank_bt  = vb.views["xStreamPresetBankRename"]
  local remove_bank_bt  = vb.views["xStreamPresetBankRemove"]
  local rename_bt       = vb.views["xStreamPresetRename"]
  local remove_bt       = vb.views["xStreamRemovePreset"]
  local favorite_bt     = vb.views["xStreamFavoritePreset"]
  local update_bt       = vb.views["xStreamUpdatePreset"]

  -- populate bank selector 
  local preset_bank_names = model:get_preset_bank_names()
  view_popup.items = preset_bank_names
  view_popup.value = model.selected_preset_bank_index

  -- buttons available only for non-default banks
  rename_bank_bt.active = not is_default
  remove_bank_bt.active = not is_default

  local favorite_idx = self.xstream.favorites:get(
    model.name,
    preset_index,
    model.selected_preset_bank.name) 

  -- buttons that depend on a selected preset
  local has_selected = (preset_index > 0)
  rename_bt.active = has_selected
  remove_bt.active = has_selected
  favorite_bt.active = has_selected
  update_bt.active = has_selected

  favorite_bt.text = (favorite_idx and has_selected) and 
    xStreamUI.FAVORITE_TEXT.ON or xStreamUI.FAVORITE_TEXT.DIMMED

  if favorite_idx then
    --print("update_preset_controls - favorite_idx",favorite_idx)
    self.selected_favorite_index = favorite_idx
  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_preset_list_row(idx)
  --TRACE("xStreamUI:update_preset_list_row(idx)",idx)

  local model = self.xstream.selected_model
  if not model then
    return
  end

  local preset_bank_name = model.selected_preset_bank.name
  local selected = (model.selected_preset_bank.selected_preset_index == idx)
  local base_color = selected and self.base_color_highlight or xLib.COLOR_DISABLED

  local view_bt

  view_bt = self.vb.views["xStreamModelPresetDelete"..idx]
  view_bt.color = base_color

  view_bt = self.vb.views["xStreamModelPresetSchedule"..idx]
  view_bt.color = base_color

  view_bt = self.vb.views["xStreamModelPresetRecall"..idx]
  local preset_color = base_color
  if (model.color > 0) then
    preset_color = xColor.value_to_color_table(model.color)
    if selected then
      preset_color = xColor.adjust_brightness(preset_color,xStreamUI.BRIGHTEN_AMOUNT)
    end
  end
  view_bt.color = preset_color
  view_bt.text = model.selected_preset_bank:get_preset_display_name(idx)
  view_bt.width = xStreamUI.PRESET_SELECTOR_W

  view_bt = self.vb.views["xStreamPresetListMoveUpButton"..idx]
  view_bt.color = base_color

  view_bt = self.vb.views["xStreamPresetListMoveDownButton"..idx]
  view_bt.color = base_color

  view_bt = self.vb.views["xStreamModelPresetUpdate"..idx]
  view_bt.color = base_color

  view_bt = self.vb.views["xStreamModelPresetFavorite"..idx]
  if view_bt then
    view_bt.color = base_color
    view_bt.text = self.xstream.favorites:get(model.name,idx,preset_bank_name) and 
      xStreamUI.FAVORITE_TEXT.ON or xStreamUI.FAVORITE_TEXT.OFF
  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_scheduled_preset(idx,txt)
  TRACE("xStreamUI:update_scheduled_preset(idx,txt)",idx,txt)

  local str_id = "xStreamModelPresetSchedule"..idx
  local view_bt = self.vb.views[str_id]
  if view_bt then
    view_bt.text = txt
  end

end

--------------------------------------------------------------------------------
-- create favorites grid 

function xStreamUI:build_favorites()
  TRACE("xStreamUI:build_favorites()")
  
  local vb = self.vb
  local vb_container = vb.views["xStreamFavoritesContainer"]

  for k,v in ipairs(self.favorite_views) do
    v.parent:remove_child(v.view)
  end

  self.favorite_views = {}

  local vb_grid = vb:column{}
  local item_idx = 0

  for row = 1,self.xstream.favorites.grid_rows do
    
    local vb_row = vb:row{}
    for col = 1,self.xstream.favorites.grid_columns do
      
      item_idx = item_idx + 1

      local vb_cell = vb:button{
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          local idx = col+((row-1)*self.xstream.favorites.grid_columns)
          self.xstream.favorites:trigger(idx)
        end,
        midi_mapping = self.midi_prefix..
          ("Favorite #%.2d [Trigger]"):format(item_idx)

      }
      vb_row:add_child(vb_cell)
      table.insert(self.favorite_views,{
        view = vb_cell,
        parent = vb_row
      })

    end

    vb_grid:add_child(vb_row)

  end

  vb_container:add_child(vb_grid)
  table.insert(self.favorite_views,{
    view = vb_grid,
    parent = vb_container
  })

end

--------------------------------------------------------------------------------

function xStreamUI:update_favorite_buttons()
  TRACE("xStreamUI:update_favorite_buttons()")

  for idx,_ in ipairs(self.favorite_views) do
    self:update_favorite_button(idx)
  end

  self.vb.views["xStreamCompactFavorite"].text = (self.selected_favorite_index > 0)
    and xStreamUI.FAVORITE_TEXT.ON or xStreamUI.FAVORITE_TEXT.DIMMED

end

--------------------------------------------------------------------------------
-- display the favorite information using color, text and symbols
-- @param idx (int), the favorite index
-- @param brightness (number, between 0-1) override color when blinking

function xStreamUI:update_favorite_button(idx,brightness)
  --TRACE("xStreamUI:update_favorite_button(idx,brightness)",idx,brightness)

  local vb_table = self.favorite_views[idx]
  if not vb_table then
    return
  end

  local view_bt = vb_table.view
  if not view_bt or not (type(view_bt)=="Button")then
    return
  end

  local favorite = self.xstream.favorites:get_by_index(idx)
  local str_txt = xStreamUI.EMPTY_FAVORITE_TXT
  local na_prefix = "⚠"
  local color = table.rcopy(xLib.COLOR_DISABLED)
  if not (type(favorite)=="xStreamFavorite") then
    str_txt = xStreamUI.EMPTY_FAVORITE_TXT
  else
    --print("favorite",rprint(favorite))
    local model_idx,model = self.xstream:get_model_by_name(favorite.model_name)
    if not model then
      -- Display as 
      -- N/A: Model Name (soft wrapped)
      -- 
      str_txt = ("%s %s"):format(na_prefix,xLib.soft_wrap(favorite.model_name))
    else
      color = xColor.value_to_color_table(model.color)
      local str_launch_mode = xStreamFavorites.LAUNCH_MODES_SHORT[favorite.launch_mode]
      --print("favorite.launch_mode",favorite.launch_mode)
      --print("str_launch_mode",str_launch_mode)
      local is_automatic = (favorite.launch_mode == xStreamFavorites.LAUNCH_MODE.AUTOMATIC)
      local is_default_bank = (favorite.preset_bank_name == xStreamPresets.DEFAULT_BANK_NAME)
      local preset_bank_index = model:get_preset_bank_by_name(favorite.preset_bank_name)
      local preset_bank = model.preset_banks[preset_bank_index]
      if favorite.preset_index and (favorite.preset_index ~= 0) then
        local preset_exists = (preset_bank and preset_bank.presets[favorite.preset_index])
        local final_prefix = (preset_bank and preset_exists) and "" or na_prefix
        if is_default_bank then
          -- Display as
          -- Model Name
          -- [N/A] #Preset Launch
          str_txt = ("%s\n%s %.2d %s"):format(
            favorite.model_name,final_prefix,favorite.preset_index,str_launch_mode)
        else
          -- Display as, when automatic (two lines)
          -- Model Name
          -- [N/A] #Preset Bank Launch
          --
          -- or, when not automatic launch (three lines)
          -- Model Name
          -- [N/A] #Preset Bank
          -- [Launch]
          local str_patt = is_automatic
            and "%s\n%s %.2d:%s%s" or "%s\n%s %.2d:%s\n%s"
          str_txt = (str_patt):format(
            favorite.model_name,final_prefix,favorite.preset_index,favorite.preset_bank_name,str_launch_mode)
        end
      else -- no preset 
        if is_default_bank then
          -- Display as 
          -- Model Name (soft wrapped)
          -- [Launch]
          str_txt = is_automatic
            and ("%s"):format(xLib.soft_wrap(favorite.model_name))
            or ("%s\n%s"):format(favorite.model_name,str_launch_mode)
        else
          -- Display as 
          -- Model Name 
          -- [N/A] Bank
          -- [Launch]
          local final_prefix = (preset_bank) and "" or na_prefix
          str_txt = is_automatic
            and ("%s\n%s%s"):format(favorite.model_name,final_prefix,favorite.preset_bank_name)
            or ("%s\n%s%s\n%s"):format(favorite.model_name,final_prefix,favorite.preset_bank_name,str_launch_mode)
        end
      end
    end
  end

  if brightness then
    color = xColor.adjust_brightness(color,brightness)
  else
    if (idx == self.selected_favorite_index) then
      color = xColor.adjust_brightness(color,xStreamUI.SELECTED_COLOR) -- dark
    elseif (idx == self.xstream.favorites.last_selected_index) then
      color = xColor.adjust_brightness(color,xStreamUI.BRIGHTEN_AMOUNT) -- light
    end
  end

  view_bt.color = color
  view_bt.text = str_txt
  view_bt.width = xStreamUI.FAVORITE_GRID_W
  view_bt.height = xStreamUI.FAVORITE_GRID_H

end

--------------------------------------------------------------------------------

function xStreamUI:update_color()
  TRACE("xStreamUI:update_color()")

  local model = self.xstream.selected_model
  local view = self.vb.views["xStreamModelColorPreview"]
  if model then
    view.color = xColor.value_to_color_table(model.color)
    view.visible = true
  else
    view.color = {0,0,0}
    view.visible = false
  end

  -- duplicate --> compact 
  self.vb.views["xStreamCompactModelColorPreview"].color = view.color

end

--------------------------------------------------------------------------------

function xStreamUI:update_editor()
  TRACE("xStreamUI:update_editor()")

  local view_lines = self.vb.views["xStreamModelEditorNumLines"]
  local view = self.vb.views["xStreamCallbackEditor"]

  view_lines.value = self.editor_visible_lines
  view.height = self.editor_visible_lines * xStreamUI.LINE_HEIGHT - 6

  view.text = self.xstream.selected_model 
    and self.xstream.selected_model.callback_str or xStreamUI.WELCOME_MSG

end

--------------------------------------------------------------------------------
-- invoked by "got_triggered" and when manually selecting via popup

function xStreamUI:do_select_favorite(idx)
  TRACE("xStreamUI:do_select_favorite(idx)",idx)

  if not self.xstream.favorites.items[idx] then
    return
  end

  local favorite_selector = self.vb.views["xStreamFavoriteSelector"]
  local selector_index = idx+1
  if (selector_index > #favorite_selector.items) then
    return
  end

  favorite_selector.value = idx+1

  -- provide immediate feedback for triggered button 
  table.insert(self.flash_favorite_buttons,{index=idx,clocked=os.clock()})
  self:update_favorite_button(idx,xStreamUI.MAX_BRIGHT_COLOR)

end

--------------------------------------------------------------------------------
-- display the right editing controls

function xStreamUI:update_favorite_edit_rack()
  TRACE("xStreamUI:update_favorite_edit_rack()")

  local favorite = self.xstream.favorites.last_selected --or 
    --self.xstream.favorites.last_triggered

  local vb = self.vb
  local launch_rack = vb.views["xStreamFavoritesLaunchRack"]
  local anchor_rack = vb.views["xStreamFavoritesAnchorRack"]
  local schedule_rack = vb.views["xStreamFavoritesScheduleRack"]
  local view_edit_rack = vb.views["xStreamFavoritesEditRack"]

  anchor_rack.visible = false
  schedule_rack.visible = false

  self:enable_favorite_edit_buttons()

  launch_rack.visible = true
  view_edit_rack.visible = self.xstream.favorites.edit_mode

  local launch_popup = vb.views["xStreamFavoritesLaunchPopup"]
  launch_popup.value = favorite and favorite.launch_mode or 1

  if (type(favorite)=="xStreamFavorite") then
    if (favorite.launch_mode == xStreamFavorites.LAUNCH_MODE.AUTOMATIC) then
      --
    elseif (favorite.launch_mode == xStreamFavorites.LAUNCH_MODE.STREAMING) then
      schedule_rack.visible = true
      local schedule_popup = vb.views["xStreamFavoritesSchedulePopup"]
      schedule_popup.value = favorite.schedule_mode
      --print("schedule_popup.value",favorite.schedule_mode)
    elseif (favorite.launch_mode == xStreamFavorites.LAUNCH_MODE.APPLY_TRACK) then
      -- 
    elseif (favorite.launch_mode == xStreamFavorites.LAUNCH_MODE.APPLY_SELECTION) then
      anchor_rack.visible = true
      local anchor_popup = vb.views["xStreamFavoritesAnchorPopup"]
      anchor_popup.value = favorite.apply_mode
    end
  end

  local view_edit_buttons = vb.views["xStreamFavoritesEditButtons"]
  view_edit_buttons.visible = self.xstream.favorites.edit_mode 

  -- update selectors -------------------------------------

  self:update_favorite_selector()
  self:update_edit_rack_model_selector()
  self:update_edit_rack_bank_selector()
  self:update_edit_rack_preset_selector()

  -- update warnings --------------------------------------

  --self:update_edit_rack_status(self.xstream.favorites.last_selected_index)


  --print("*** update_favorite_edit_rack - got here")

end

--------------------------------------------------------------------------------

function xStreamUI:update_edit_rack_model_selector()
  TRACE("xStreamUI:update_edit_rack_model_selector()")

  local favorite_idx = self.xstream.favorites.last_selected_index
  local favorite = self.xstream.favorites.items[favorite_idx]

  local model_selector = self.vb.views["xStreamFavoriteModelSelector"]
  local model_status = self.vb.views["xStreamFavoriteModelStatus"]
  
  if type(favorite) ~= "xStreamFavorite" then
    model_selector.value = 1
    return
  end

  local model_idx,model = self.xstream:get_model_by_name(favorite.model_name)
  --print("model_idx,model",model_idx,model)
  if not model then
    model_status.text = xStreamUI.EDIT_RACK_WARNING
    model_status.tooltip = "This model is not available"
  else
    model_status.text = ""
    model_status.tooltip = ""
    model_selector.value = model_idx+1
    model_selector.width = xStreamUI.EDIT_SELECTOR_W
  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_edit_rack_bank_selector()
  TRACE("xStreamUI:update_edit_rack_bank_selector()")

  local favorite_idx = self.xstream.favorites.last_selected_index
  local favorite = self.xstream.favorites.items[favorite_idx]

  local bank_selector = self.vb.views["xStreamFavoriteBankSelector"]
  local bank_status = self.vb.views["xStreamFavoriteBankStatus"]
  
  if type(favorite) ~= "xStreamFavorite" then
    bank_selector.value = 1
    bank_selector.active = false
    return
  else
    bank_selector.active = true
  end

  local model_idx,model = self.xstream:get_model_by_name(favorite.model_name)
  --print("model_idx,model",model_idx,model)

  if not model then
    bank_status.text = xStreamUI.EDIT_RACK_WARNING
    bank_selector.items = {xStreamUI.NO_PRESET_BANKS_AVAILABLE}
  else
    bank_selector.items = model:get_preset_bank_names()
    --print("favorite.preset_bank_name",favorite.preset_bank_name)
    local preset_bank_index = model:get_preset_bank_by_name(favorite.preset_bank_name)
    if preset_bank_index then
      bank_selector.value = preset_bank_index
      bank_selector.width = xStreamUI.EDIT_SELECTOR_W
      bank_status.text = ""
      bank_status.tooltip = ""
    else
      bank_status.text = xStreamUI.EDIT_RACK_WARNING
      bank_status.tooltip = "This preset bank is not available"
    end
  end

end
--------------------------------------------------------------------------------

function xStreamUI:update_edit_rack_preset_selector()
  TRACE("xStreamUI:update_edit_rack_preset_selector()")

  local favorite_idx = self.xstream.favorites.last_selected_index
  local favorite = self.xstream.favorites.items[favorite_idx]

  local preset_selector = self.vb.views["xStreamFavoritePresetSelector"]
  local preset_status = self.vb.views["xStreamFavoritePresetStatus"]
  local items_set = false

  if type(favorite)=="xStreamFavorite" then

    preset_selector.active = true

    local model_idx,model = self.xstream:get_model_by_name(favorite.model_name)

    if model then
      --print("favorite.preset_bank_name",favorite.preset_bank_name)
      local preset_bank_index = model:get_preset_bank_by_name(favorite.preset_bank_name)
      if preset_bank_index then
        -- gather preset names
        local preset_bank = model.preset_banks[preset_bank_index]
        local preset_names = (#preset_bank.presets == 0) and 
          {xStreamUI.NO_PRESETS_AVAILABLE} or {"Select preset"}
        for k,v in ipairs(preset_bank.presets) do
          table.insert(preset_names,("Preset %.02d"):format(k))
        end
        --rprint(preset_names)
        preset_selector.items = preset_names
        local preset_index = (favorite.preset_index > 0) and favorite.preset_index+1 or 1
        if (preset_index <= #preset_selector.items) then
          preset_selector.value = preset_index
          preset_selector.width = xStreamUI.EDIT_SELECTOR_W
        else
          preset_selector.value = 1
        end
        items_set = true
      end
    end
  else
    
    preset_selector.value = 1
    preset_selector.active = false

  end

  if not items_set then
    preset_selector.items = {xStreamUI.NO_PRESETS_AVAILABLE}
    preset_selector.value = 1
  end

end

--------------------------------------------------------------------------------
-- apply a single property to a favorite (existing or empty)

function xStreamUI:apply_property_to_favorite(favorite_idx,prop_name,prop_value)
  TRACE("xStreamUI:apply_property_to_favorite(favorite_idx,prop_name,prop_value)",favorite_idx,prop_name,prop_value)

  local favorite = self.xstream.favorites.items[favorite_idx]
  if not favorite then
    return
  end

  local is_empty = false
  if type(favorite)~="xStreamFavorite" then
    favorite = xStreamFavorite()
    is_empty = true
  end

  if (favorite[prop_name] == prop_value) then
    return
  end

  --self:update_edit_rack_status(favorite_idx,prop_name,prop_value)

  favorite[prop_name] = prop_value
  self.xstream.favorites.modified = true
  self.favorite_edit_rack_requested = true

  -- update controls (favorite icon)
  if self.xstream.selected_model then
    if (favorite.model_name == self.xstream.selected_model.name) then
      self:update_model_controls() 
      self:update_preset_list() 
      if (favorite.preset_bank_name == self.xstream.selected_model.selected_preset_bank.name) then
        self:update_preset_controls() 
      end
    end
  end

  if (favorite.model_name ~= "") and 
    (favorite.model_name ~= xStreamUI.NO_MODEL_SELECTED) 
  then
    if is_empty then
      self.xstream.favorites:assign(favorite_idx,favorite)
    end
  else
    self.xstream.favorites:clear(favorite_idx)
  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_favorite_selector()
  TRACE("xStreamUI:update_favorite_selector()")

  local favorite_selector = self.vb.views["xStreamFavoriteSelector"]
  local favorite_names = self.xstream.favorites:get_names()
  table.insert(favorite_names,1,xStreamUI.NO_FAVORITE_SELECTED)
  favorite_selector.items = favorite_names

end

--------------------------------------------------------------------------------
-- create user interface 

function xStreamUI:build()
  TRACE("xStreamUI:build()")

  if self.vb_content then
    --print("xStreamUI has already been built")
    return
  end

  local vb = self.vb

  -- misc. helper functions -------------------------------

  local color_callback = function(t)
    self.xstream.selected_model.color = t
  end

  -- construct the main view ------------------------------

  local view_options_panel = self:build_options_panel()
  local view_callback_panel = self:build_callback_panel()
  local view_favorites_panel = self:build_favorites_panel()
  local view_models_panel = self:build_models_panel()
  local view_presets_panel = self:build_presets_panel()
  local view_args_panel = self:build_args_panel()

  local content = vb:row{
    view_options_panel,
    vb:column{
      id = "xStreamPanel",
      vb:row{ -- xStreamUpperPanel
        id = "xStreamUpperPanel",
        style = "panel",
        margin = 4,

        vb:horizontal_aligner{
          id = "xStreamTransportAligner",
          mode = "justify",
          vb:row{
            id = "xStreamTransportRow",
            vb:row{
              vb:button{
                bitmap = "./source/icons/transport_record.bmp",
                tooltip = "Record streaming (not yet implemented)",
                active = false,
                width = xStreamUI.TRANSPORT_BUTTON_W,
                height = xStreamUI.BITMAP_BUTTON_H,
              },
              vb:button{
                bitmap = "./source/icons/transport_play.bmp",
                tooltip = "Activate streaming and (re-)start playback [Space]",
                id = "xStreamStartPlayButton",
                width = xStreamUI.TRANSPORT_BUTTON_W,
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function(val)
                  self.xstream:start_and_play()
                end,
              },
              vb:button{
                --bitmap = "Icons/Browser_RenoisePhraseFile.bmp",
                text = "≣↴",
                tooltip = "Toggle whether streaming is active",
                id = "xStreamToggleStreaming",
                width = xStreamUI.TRANSPORT_BUTTON_W,
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function(val)
                  if self.xstream.active then
                    self.xstream:stop()
                  else
                    self.xstream:start()
                  end
                end,
              },
              vb:button{
                --text = "mute",
                --bitmap = "Icons/TrackIsMuted.bmp",
                --bitmap = "Icons/Mixer_ShowMute.bmp",
                text = "M",
                tooltip = "Mute/unmute stream",
                id = "xStreamMuteButton",
                width = xStreamUI.TRANSPORT_BUTTON_W,
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function(val)
                  self.xstream.muted = not self.xstream.muted
                end,
              },
            },
            vb:space{
              width = 6,
            },
            vb:row{
              vb:button{
                text = "↓ TRK",
                tooltip = "Apply to the selected track",
                id = "xStreamApplyTrackButton",
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function(val)
                  self.xstream:fill_track()
                end,
              },
              vb:button{
                text = "↓ SEL",
                tooltip = "Apply to the selected lines (relative to top of pattern)",
                id = "xStreamApplySelectionButton",
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  self.xstream:fill_selection()
                end,
              },
              vb:button{
                text = "↧ SEL",
                tooltip = "Apply to the selected lines (relative to start of selection)",
                id = "xStreamApplyLocallyButton",
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  self.xstream:fill_selection(true)
                end,
              },
            },
          },
          vb:button{
            tooltip = "Toggle compact/full mode [Tab]",
            id = "xStreamToggleExpand",
            width = xStreamUI.BITMAP_BUTTON_W,
            height = xStreamUI.BITMAP_BUTTON_H,
            notifier = function()
              self.show_editor = not self.show_editor
            end,
          },        
        },
      },

      vb:row{ -- compact model
        id = "xStreamModelCompact",
        style = "panel",
        margin = 4,
        vb:button{
          tooltip = "Assign a color to this model",
          id = "xStreamCompactModelColorPreview",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local model_color = self.xstream.selected_model.color
            xDialog.prompt_for_color(color_callback,model_color,xStreamUI.DEFAULT_PALETTE)
          end,
        },
        vb:text{
          font = "bold",
          text = "Model",
        },
        vb:popup{
          tooltip = "Choose between models",
          items = self.xstream:get_model_names(),
          id = "xStreamCompactModelSelector",
          width = xStreamUI.MODEL_SELECTOR_COMPACT_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(val)
            self.xstream.selected_model_index = val-1
          end
        },
        vb:popup{
          tooltip = "Choose between model presets (switch to full mode to select bank)",
          items = {},
          id = "xStreamCompactPresetSelector",
          width = 60,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(idx)
            local preset_bank = self.xstream.selected_model.selected_preset_bank
            preset_bank.selected_preset_index = idx-1
          end
        },
        vb:button{
          text = xStreamUI.FAVORITE_TEXT.ON,
          tooltip = "Add selected model/preset to favorites",
          id = "xStreamCompactFavorite",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(val)
            local model = self.xstream.selected_model
            local preset_bank_name, preset_index
            if model then
              preset_bank_name = model.selected_preset_bank.name
              preset_index = model.selected_preset_bank.selected_preset_index
            end
            self.xstream.favorites:toggle_item(model.name,preset_index,preset_bank_name)
          end,
        },
      },
      vb:row{ -- callback, lower panels
        id = "xStreamLowerPanels",
        vb:column{
          id = "xStreamMiddlePanel",
          vb:row{
            view_callback_panel,
            view_favorites_panel,
          },
          vb:row{ -- xStreamLowerPanelsRack
            id = "xStreamLowerPanelsRack",
            view_models_panel,
            view_presets_panel,
            view_args_panel,
          },
        },
      },
    },
  }
  

  -- avoid 'flashing' on startup as textfield does not
  -- become inactive right away, only once model is set...
  if (renoise.API_VERSION > 4) then
    vb.views["xStreamCallbackEditor"].active = false
  end


  -- add notifier methods ---------------------------------

  self.selected_favorite_index_observable:add_notifier(function()
    TRACE("*** xStreamUI - selected_favorite_index_observable fired...",self.selected_favorite_index)
    self.update_favorites_requested = true

  end)

  self.xstream.writeahead_factor_observable:add_notifier(function()
    TRACE("*** xStreamUI - self.xstream.writeahead_factor_observable fired...",self.xstream.writeahead_factor)
    local view = self.vb.views["xStreamImplWriteAheadFactor"]
    view.value = self.xstream.writeahead_factor
  end)

  self.xstream.callback_status_observable:add_notifier(function()    
    TRACE("*** xStreamUI - xstream.callback_status_observable fired...")
    local str_err = self.xstream.callback_status_observable.value
    local view = self.vb.views["xStreamCallbackStatus"]
    if (str_err == "") then
      view.text = "Syntax OK"
      view.tooltip = ""
    else
      view.text = "⚠ Syntax Error"
      view.tooltip = str_err
    end 

  end)

  self.xstream.muted_observable:add_notifier(function()    
    TRACE("*** xStreamUI - xstream.muted_observable fired...")
    local view = vb.views["xStreamMuteButton"]
    local color = self.xstream.muted 
      and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED
    view.color = color
  end)

  self.xstream.active_observable:add_notifier(function()    
    TRACE("*** xStreamUI - xstream.active_observable fired...")
    local view = vb.views["xStreamToggleStreaming"]
    local color = self.xstream.active 
      and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED
    view.color = color
  end)

  self.xstream.stream.just_started_playback_observable:add_notifier(function()    
    TRACE("*** xStreamUI - xstream.stream.just_started_playback_observable fired...")
    -- briefly flash play button when playback was triggered programatically
    local view = vb.views["xStreamStartPlayButton"]
    view.color = (self.xstream.stream.just_started_playback > 0)
      and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED
  end)

  -- handle models ----------------------------------------

  self.xstream.models_observable:add_notifier(function()
    TRACE("*** xStreamUI - models_observable fired...")
    self.build_models_requested = true
  end)

  local model_name_notifier = function()
    TRACE("*** xStreamUI - model.name_observable fired...")
    self.build_models_requested = true
  end
  
  local model_modified_notifier = function()
    TRACE("*** xStreamUI - model.modified_observable fired...")
    self.update_models_requested = true
  end
  
  local model_compiled_notifier = function()
    TRACE("*** xStreamUI - model.compiled_observable fired...")
    local view = vb.views["xStreamCallbackCompile"]
    view.active = self.xstream.selected_model.compiled
  end

  local model_color_notifier = function()    
    TRACE("*** xStreamUI - model.color_observable fired...")
    self.update_color_requested = true
  end

  local callback_notifier = function()
    TRACE("*** xStreamUI - callback_notifier fired...")
    if not self.user_modified_callback then
      --print("... got here")
      self:update_editor()
    end
  end

  local selected_arg_notifier = function()
    TRACE("*** xStreamUI - model.args.selected_index fired...")
    self.update_args_requested = true
  end

  local args_modified_notifier = function()
    TRACE("*** xStreamUI - model.args.selected_index fired...")
    self.build_args_requested = true
  end

  --[[
  local args_modified_notifier = function()
    TRACE("*** xStreamUI - args_modified_notifier fired...")
    self:build_args()
    --self:update_args()
    --self:update_args_selector()
    --self:update_args_visibility()
    self.update_args_requested = true
  end
  ]]

  local preset_bank_notifier = function()
    TRACE("*** xStreamUI - model.preset_banks/name_observable fired...")
    self:update_preset_controls()
    self:update_edit_rack_bank_selector()
  end

  local presets_modified_notifier = function()
    TRACE("*** xStreamUI - preset_bank.presets_observable fired...")
    self.build_presets_requested = true
    self:update_edit_rack_preset_selector()
  end

  local preset_index_notifier = function()    
    TRACE("*** xStreamUI - preset_bank.selected_preset_index_observable fired...")
    self.update_presets_requested = true
  end

  local preset_bank_index_notifier = function()
    TRACE("*** xStreamUI - model.selected_preset_bank_index_observable fired...")
    self.build_presets_requested = true
    self.update_presets_requested = true
    local preset_bank = self.xstream.selected_model.selected_preset_bank
    xLib.attach_to_observable(preset_bank.presets_observable,presets_modified_notifier)
    xLib.attach_to_observable(preset_bank.modified_observable,presets_modified_notifier)
    xLib.attach_to_observable(preset_bank.selected_preset_index_observable,preset_index_notifier)
    xLib.attach_to_observable(preset_bank.name_observable,preset_bank_notifier)
  end

  local selected_model_index_notifier = function()
    TRACE("*** xStreamUI - selected_model_index_notifier fired...",self.xstream.selected_model_index)

    local model = self.xstream.selected_model
    if model then
      xLib.attach_to_observable(model.name_observable,model_name_notifier)
      xLib.attach_to_observable(model.modified_observable,model_modified_notifier)
      xLib.attach_to_observable(model.compiled_observable,model_compiled_notifier)
      xLib.attach_to_observable(model.color_observable,model_color_notifier)
      xLib.attach_to_observable(model.args.selected_index_observable,selected_arg_notifier)
      xLib.attach_to_observable(model.args.args_observable,args_modified_notifier)
      xLib.attach_to_observable(model.callback_str_observable,callback_notifier)
      xLib.attach_to_observable(model.preset_banks_observable,preset_bank_notifier)
      xLib.attach_to_observable(model.selected_preset_bank_index_observable,preset_bank_index_notifier)
      preset_bank_index_notifier()
      -- select first argument
      if (#model.args.args > 0) then
        model.args.selected_index = 1
      end
    end
    self.update_model_requested = true
    self:update_editor()

    if xDialog.color_prompt.dialog and xDialog.color_prompt.dialog.visible then
      xDialog.prompt_for_color(color_callback,model.color)
    end

  end
  self.xstream.selected_model_index_observable:add_notifier(selected_model_index_notifier)
  self.vb_content = content

  selected_model_index_notifier()


  -- handle scheduled items -------------------------------

  self.xstream.scheduled_model_index_observable:add_notifier(function()    
    TRACE("*** xStreamUI - scheduled_model_index_observable fired...",self.xstream.scheduled_model_index)
    if self.scheduled_model_index then
      self:update_scheduled_model(self.scheduled_model_index,xStreamUI.SCHEDULE_TEXT.OFF)
    end
    if (self.xstream.scheduled_model_index == 0) then
      self.scheduled_model_index = nil
    else
      self.scheduled_model_index = self.xstream.scheduled_model_index
    end

  end)

  self.xstream.scheduled_preset_index_observable:add_notifier(function()    
    TRACE("*** xStreamUI - scheduled_preset_index_observable fired...",self.xstream.scheduled_preset_index)
    if self.scheduled_preset_index then
      self:update_scheduled_preset(self.scheduled_preset_index,xStreamUI.SCHEDULE_TEXT.OFF)
    end
    if (self.xstream.scheduled_preset_index == 0) then
      self.scheduled_preset_index = nil
    else
      self.scheduled_preset_index = self.xstream.scheduled_preset_index
    end

  end)


  -- handle favorites -------------------------------------

  self.xstream.scheduled_favorite_index_observable:add_notifier(function()    
    TRACE("*** xStreamUI - scheduled_favorite_index_observable fired...",self.xstream.scheduled_favorite_index)
    if (self.xstream.scheduled_favorite_index == 0) then
      self:update_favorite_button(self.scheduled_favorite_index)
      self.scheduled_favorite_index = nil
    else
      self.scheduled_favorite_index = self.xstream.scheduled_favorite_index
    end
  end)

  local build_favorites_handler = function()
    TRACE("*** xStreamUI - favorites/grid_rows/grid_columns_observable fired...")
    self.build_favorites_requested = true
  end

  self.xstream.favorites.favorites_observable:add_notifier(build_favorites_handler)
  self.xstream.favorites.grid_rows_observable:add_notifier(build_favorites_handler)
  self.xstream.favorites.grid_columns_observable:add_notifier(build_favorites_handler)

  self.xstream.favorites.modified_observable:add_notifier(function()
    TRACE("*** xStreamUI - favorites.modified_observable fired...")
    self.update_favorites_requested = true
    self.update_models_requested = true
    self.update_presets_requested = true

  end)

  self.xstream.favorites.got_triggered_observable:add_notifier(function()
    TRACE("*** xStreamUI - favorites.got_triggered_observable fired...")
    if self.xstream.favorites.got_triggered_observable.value then
      local idx = self.xstream.favorites.last_triggered_index
      self:update_favorite_edit_rack()
      self:do_select_favorite(idx)
    end
  end)

  self.xstream.favorites.last_selected_index_observable:add_notifier(function()
    TRACE("*** xStreamUI - favorites.last_selected_index_observable fired...")
    local idx = self.xstream.favorites.last_selected_index
    self:update_favorite_edit_rack()

    self:do_select_favorite(idx)

    if self.previous_selected_index then
      self:update_favorite_button(self.previous_selected_index)
    end
    self.previous_selected_index = idx

  end)

  self.xstream.favorites.edit_mode_observable:add_notifier(function()
    TRACE("*** xStreamUI - favorites.edit_mode_observable fired...")
    self:update_favorite_edit_rack()
    if not self.xstream.favorites.edit_mode then
      self.xstream.favorites.last_selected_index = 0
    end
  end)

  self.xstream.favorites.update_buttons_requested_observable:add_notifier(function()
    TRACE("*** xStreamUI - favorites.update_buttons_requested_observable fired...")
    self:update_favorite_buttons()
  end)

  self.build_favorites_requested = true
  self.build_models_requested = true

end



--------------------------------------------------------------------------------

function xStreamUI:build_callback_panel()

  -- misc. helper functions -------------------------------

  local color_callback = function(t)
    self.xstream.selected_model.color = t
  end

  local vb = self.vb
  return vb:column{
    id = "xStreamCallbackPanel",
    style = "panel",
    margin = 4,
    vb:horizontal_aligner{
      mode = "justify",
      vb:row{
        id = "xStreamCallbackHeader",
        vb:button{
          tooltip = "Pick color",
          id = "xStreamModelColorPreview",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local model_color = self.xstream.selected_model.color
            xDialog.prompt_for_color(color_callback,model_color,xStreamUI.DEFAULT_PALETTE)
          end,
        },
        vb:text{
          text = "",
          id = "xStreamCallbackName",
          font = "bold",
        },
      },        
      vb:row{
        tooltip = "Number of lines",
        vb:text{
          id = "xStreamEditorNumLinesTitle",
          text = "lines",
        },
        vb:valuebox{
          min = 12,
          max = 51,
          id = "xStreamModelEditorNumLines",
          notifier = function(val)
            self.editor_visible_lines = val
          end,
        }
      }
    },
    vb:multiline_textfield{
      text = "",
      font = "mono",
      height = 200,
      width = xStreamUI.CALLBACK_EDITOR_W, 
      id = "xStreamCallbackEditor",
      notifier = function(str)
        if self.xstream.selected_model then
          --print("*** changed callback via textfield...")
          self.user_modified_callback = true
        end
      end,
    },
    vb:row{
      vb:row{
        vb:button{
          text = "compile",
          tooltip = "Compile the callback (will check for errors)",
          id = "xStreamCallbackCompile",
          active = false,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local model = self.xstream.selected_model
            local view = vb.views["xStreamCallbackEditor"]
            local passed,err = model:compile(view.text)
            if not passed then
              renoise.app():show_warning(err)
              self.xstream.callback_status_observable.value = err
            else
              self.xstream.callback_status_observable.value = ""
            end
          end,
        },
        -- hackaround for clickable text
        vb:checkbox{
          value = false,
          visible = false,  
          notifier = function()
            if (self.xstream.callback_status_observable.value ~= "") then
              renoise.app():show_warning(
                "The callback returned the following error:\n"
                ..self.xstream.callback_status_observable.value
                .."\n\n(you can also see these messages in the scripting console)")
            end
          end
        },
        vb:text{
          id = "xStreamCallbackStatus",
          text = "",
        }
      },
      vb:row{
        tooltip = "Compile the callback as you type",
        id = "xStreamLiveCoding",
        vb:checkbox{
          bind = self.xstream.live_coding_observable
        },
        vb:text{
          text = "live coding"
        },
      },
    },
  }

end

--------------------------------------------------------------------------------

function xStreamUI:build_favorites_panel()

  local vb = self.vb
  return vb:column{ 
    id = "xStreamFavoritesPanel",
    style = "panel",
    margin = 4,
    vb:row{ -- toggle, size controls
      vb:row{
        vb:row{ -- toggle/label 
          vb:button{
            tooltip = "Toggle favorite grid on/off",
            id = "xStreamFavoritesToggle",
            width = xStreamUI.BITMAP_BUTTON_W,
            height = xStreamUI.BITMAP_BUTTON_H,
            notifier = function()
              self.favorites_visible = not self.favorites_visible
            end,
          },
          vb:text{
            id = "xStreamFavoritesLabel",
            text = "Favorites",
            font = "bold",
          },
        },
        vb:row{
          id = "xStreamFavoriteTriggerButton",
          vb:space{
            width = xStreamUI.FAVORITE_SELECTOR_W-120,
          },
          vb:button{
            text = "Trigger selected",
            notifier = function()
              self.xstream.favorites:trigger(self.xstream.favorites.last_selected_index)
            end
          },
        },
        vb:row{
          id = "xStreamFavoritesSize",
          vb:space{
            width = 16,
          },  
          vb:text{
            text = "size",
          },
          vb:valuebox{
            min = 1,
            max = 16,
            bind = self.xstream.favorites.grid_columns_observable,
            width = 50,
          },
          vb:text{
            text = "x",
          },
          vb:valuebox{
            min = 1,
            max = 16,
            bind = self.xstream.favorites.grid_rows_observable,
            width = 50,
          },
        },
      },
    },
    --[[
    vb:space{
      height = 4,
    },
    ]]
    vb:column{
      id = "xStreamFavoritesContainer",
      --[[
      vb:space{
        height = 4,
      },
      ]]
    },
    vb:column{
      id = "xStreamFavoritesLowerToolbar",
      vb:row{
        vb:row{ -- edit
          id = "xStreamFavoritesEditToggleRow",
          vb:row{
            tooltip = "Toggle editing of favorites",
            id = "xStreamFavoritesEditToggle",
            vb:text{
              text = "Edit",
            },
            vb:checkbox{
              bind = self.xstream.favorites.edit_mode_observable,
            },
          },
        },
        vb:column{ 
          vb:column{ -- buttons
            id = "xStreamFavoritesEditButtons",
            visible = self.xstream.favorites.edit_mode,
            vb:row{
              vb:button{
                text = "insert",
                tooltip = "Insert a new favorite at the selected position",
                id = "xStreamFavoritesEditButtonInsert",
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  local favorite_idx = self.xstream.favorites.last_selected_index
                  if favorite_idx then
                    self.xstream.favorites:add(favorite_idx+1)
                    self.xstream.favorites.last_selected_index = favorite_idx+1
                  end                        
                end,
              },
              vb:button{
                text = "move",
                id = "xStreamFavoritesEditButtonMove",
                active = false,
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  renoise.app():show_message("Not yet implemented")
                end,
              },
              vb:button{
                text = "swap",
                id = "xStreamFavoritesEditButtonSwap",
                active = false,
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  renoise.app():show_message("Not yet implemented")
                end,
              },
              vb:button{
                text = "clear",
                tooltip = "Clear favorite at the selected position",
                id = "xStreamFavoritesEditButtonClear",
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  local favorite_idx = self.xstream.favorites.last_selected_index
                  if favorite_idx then
                    self.xstream.favorites:clear(favorite_idx)
                  end
                end,
              },
              vb:button{
                text = "delete",
                id = "xStreamFavoritesEditButtonDelete",
                tooltip = "Delete favorite from the selected position",
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  local favorite_idx = self.xstream.favorites.last_selected_index
                  if favorite_idx then
                    self.xstream.favorites:remove_by_index(favorite_idx)
                  end
                end,
              },
            },
            vb:space{
              height = xStreamUI.SMALL_VERTICAL_MARGIN,
            },
          },
          vb:popup{ -- selector
            items = {},
            tooltip = "Select among available favorites",
            id = "xStreamFavoriteSelector",
            width = xStreamUI.FAVORITE_SELECTOR_W,
            height = xStreamUI.BITMAP_BUTTON_H,
            notifier = function(val)
              self.xstream.favorites.last_selected_index = val-1
            end
          }
        },
      },
      vb:row{
        id = "xStreamFavoritesEditRack",
        visible = false,
        vb:column{
          vb:row{
            id = "xStreamFavoritesLaunchRack",
            visible = false,
            vb:column{
              vb:space{
                height = xStreamUI.SMALL_VERTICAL_MARGIN,
              },
              vb:row{
                vb:text{
                  text = "Model",
                  width = xStreamUI.EDIT_RACK_MARGIN,
                },
                vb:popup{
                  items = {},
                  id = "xStreamFavoriteModelSelector",
                  notifier = function(val)
                    local favorite_idx = self.xstream.favorites.last_selected_index
                    local popup = self.vb.views["xStreamFavoriteModelSelector"]
                    self:apply_property_to_favorite(favorite_idx,"model_name",popup.items[val])
                  end
                },
                vb:text{
                  text = "",
                  id = "xStreamFavoriteModelStatus",
                },

              },
              vb:row{
                vb:text{
                  text = "bank",
                  width = xStreamUI.EDIT_RACK_MARGIN,
                },
                vb:popup{
                  items = {},
                  id = "xStreamFavoriteBankSelector",
                  notifier = function(val)
                    local favorite_idx = self.xstream.favorites.last_selected_index
                    local popup = self.vb.views["xStreamFavoriteBankSelector"]
                    self:apply_property_to_favorite(favorite_idx,"preset_bank_name",popup.items[val])
                  end
                },
                vb:text{
                  text = "",
                  id = "xStreamFavoriteBankStatus",
                },
              },
              vb:row{
                vb:text{
                  text = "Preset",
                  width = xStreamUI.EDIT_RACK_MARGIN,
                },
                vb:popup{
                  items = {},
                  id = "xStreamFavoritePresetSelector",
                  notifier = function(val)
                    local favorite_idx = self.xstream.favorites.last_selected_index
                    self:apply_property_to_favorite(favorite_idx,"preset_index",val-1)
                  end
                },
                vb:text{
                  text = "",
                  id = "xStreamFavoritePresetStatus",
                },
              },
            },
          },
          vb:space{
            height = xStreamUI.SMALL_VERTICAL_MARGIN,
          },
          vb:row{

            vb:row{
              vb:text{
                text = "launch",
                width = xStreamUI.EDIT_RACK_MARGIN,
              },
              vb:popup{
                items = xStreamFavorites.LAUNCH_MODES,
                tooltip = "Determine the 'launch behavior' of the selected favorite"
                        .."\nAUTOMATIC - automatically use streaming when playing, or apply when stopped"
                        .."\nSTREAMING - always use streaming, with customizable scheduling"
                        .."\nAPPLY_TRACK - always apply to selected track"
                        .."\nAPPLY_SELECTION - always apply to selection in track",
                id = "xStreamFavoritesLaunchPopup",
                width = 86,
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function(val)
                  local favorite = self.xstream.favorites.last_selected
                  if favorite then
                    if (favorite.launch_mode ~= val) then
                      favorite.launch_mode = val
                      self.xstream.favorites.modified = true
                      self.favorite_edit_rack_requested = true
                    end
                  end
                end
              },
            },
            vb:row{
              id = "xStreamFavoritesScheduleRack",
              tooltip = "Choose between available scheduling modes (applies to streaming mode only)",
              visible = false,
              vb:text{
                text = "scheduling",
              },
              vb:popup{
                items = xStream.SCHEDULES,
                value = xStream.SCHEDULE.BEAT,
                id = "xStreamFavoritesSchedulePopup",
                width = 64,
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function(val)
                  local favorite = self.xstream.favorites.last_selected
                  if favorite then
                    if (favorite.schedule_mode ~= val) then
                      favorite.schedule_mode = val
                      self.xstream.favorites.modified = true
                      self.favorite_edit_rack_requested = true
                    end
                  end
                end
              },
            },
            vb:row{
              id = "xStreamFavoritesAnchorRack",
              tooltip = "Choose 'anchoring' when applying to selection (offline mode only)"
                      .."\nPATTERN - relative to top of pattern"
                      .."\nSELECTION - relative to start of selection",
              visible = false,
              vb:text{
                text = "anchor",
              },
              vb:popup{
                items = xStreamFavorites.APPLY_MODES,
                value = xStreamFavorites.APPLY_MODE.PATTERN,
                id = "xStreamFavoritesAnchorPopup",
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function(val)
                  local favorite = self.xstream.favorites.last_selected
                  if favorite then
                    if (favorite.apply_mode ~= val) then
                      favorite.apply_mode = val
                      self.xstream.favorites.modified = true
                      self.favorite_edit_rack_requested = true
                    end
                  end
                end
              },
            },
          },
        },
      },
    },
  }

end

--------------------------------------------------------------------------------

function xStreamUI:build_options_panel()

  local vb = self.vb
  return vb:column{ -- options 
    vb:column{ -- header
      style = "panel",
      margin = 4, 
      vb:row{
        vb:button{
          tooltip = "Toggle xStream options",
          --bitmap = xStreamUI.OPTIONS_ICON,
          text = "☰",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.tool_options_visible = not self.tool_options_visible
          end,
        },
        vb:text{
          text="tool options",
          font = "bold",
          id = "xStreamImplOptionsTitle",
          visible = self.tool_options_visible,
          width = xStreamUI.TOOL_OPTION_W-xStreamUI.BITMAP_BUTTON_W,
        },
      }
    },
    vb:column{ -- panel
      id = "xStreamImplOptionsPanel",
      --visible = self.tool_options_visible.value,
      vb:column{ -- tool options
        style = "panel",
        margin = 4,
        vb:column{
          tooltip = "Decide when/how xStream should enable streaming",
          --width = "100%",
          vb:text{
            text="Enable streaming"
          },
          vb:row{
            vb:popup{
              bind = self.start_option_observable,
              items = xStreamUI.START_OPTIONS,
              width = xStreamUI.TOOL_OPTION_W,
            },
          },
        },
        vb:column{
          tooltip = "Decide which model (if any) to select on startup",
          vb:text{
            text= "Launch with model"
          },
          vb:popup{
            items = {xStreamUI.NO_MODEL_SELECTED},
            id = "xStreamImplLaunchModel",
            notifier = function(idx)
              self.launch_model = self.xstream.models[idx].file_path
            end,
            width = xStreamUI.TOOL_OPTION_W,
          },
        },
        vb:row{
          tooltip = "Make xStream launch when Renoise starts",
          vb:checkbox{
            bind = self.autostart_observable,
          },
          vb:text{
            text="Autostart tool",
          },

        },
        vb:row{
          tooltip = "Make xStream suspend output when dialog is hidden",
          vb:checkbox{
            id = "xStreamImplSuspend",
            notifier = function(checked)
              self.suspend_when_hidden = checked
            end,
          },
          vb:text{
            text="Suspend when hidden",
          },

        },
        vb:row{
          tooltip = "Make xStream handle (disable) lua garbage collection. Use with caution!",
          vb:checkbox{
            id = "xStreamImplManageGarbage",
            notifier = function(checked)
              --self.manage_gc.value = checked
              self.xstream.manage_gc = checked
            end,
          },
          vb:text{
            text="Handle memory",
          },
        },

        vb:row{
          tooltip = "Control how far ahead xStream should produce output (smaller = longer)",
          vb:text{
            text="Writeahead",
            width = xStreamUI.TOOL_OPTION_TXT_W,
          },
          vb:valuebox{
            id = "xStreamImplWriteAheadFactor",
            min = 125,
            max = 400,
            --bind = self.xstream.writeahead_factor_observable
            value = self.xstream.writeahead_factor,
            notifier = function(val)
              self.xstream.writeahead_factor = val
            end
          },
        },
      },
      vb:column{ -- realtime options
        style = "panel",
        margin = 4,

        vb:row{
          tooltip = "The active track at which xStream will produce output",
          vb:text{
            text = "track_index",
            width = xStreamUI.TOOL_OPTION_TXT_W,
          },
          vb:valuebox{
            min = 0,
            max = 255,
            bind = self.xstream.track_index_observable,
          },
        },
        vb:row{
          tooltip = "The automation device-parameter where automation is written",
          vb:text{
            text = "param_index",
            width = xStreamUI.TOOL_OPTION_TXT_W,
          },
          vb:valuebox{
            min = 0,
            max = 255,
            bind = self.xstream.device_param_index_observable,
          },
        },
        vb:row{
          tooltip = "Determine how muting works",
          vb:text{
            text = "mute_mode",
            width = xStreamUI.TOOL_OPTION_TXT_W,
          },
          vb:popup{
            items = xStream.MUTE_MODES,
            width = 60,
            height = xStreamUI.BITMAP_BUTTON_H,
            bind = self.xstream.mute_mode_observable,
          },
        },
        vb:row{
          tooltip = "Scheduling of models/presets",
          vb:text{
            text = "scheduling",
            width = xStreamUI.TOOL_OPTION_TXT_W,
          },
          vb:popup{
            items = xStream.SCHEDULES,
            width = 60,
            height = xStreamUI.BITMAP_BUTTON_H,
            bind = self.xstream.scheduling_observable,
          },
        },
        vb:row{
          tooltip = "Whether to include hidden columns when writing output",
          vb:checkbox{
            bind = self.xstream.include_hidden_observable,
          },
          vb:text{
            text = "include_hidden",
          },
        },
        vb:row{
          tooltip = "Whether to clear undefined values, columns",
          vb:checkbox{
            bind = self.xstream.clear_undefined_observable,
          },
          vb:text{
            text = "clear_undefined",
          },
        },
        vb:row{
          tooltip = "Automatically reveal (sub-)columns with output",
          vb:checkbox{
            bind = self.xstream.expand_columns_observable,
          },
          vb:text{
            text = "expand_columns",
          },
        },
      },

      vb:column{ -- stats
        margin = 4,
        width = "100%",
        vb:text{
          text= "Stats",
          font = "bold",

        },
        vb:text{
          text= "",
          id = "xStreamImplStats",
        },
      },
    },
  }

end

--------------------------------------------------------------------------------

function xStreamUI:build_models_panel()

  local vb = self.vb
  return vb:column{ 
    style = "panel",
    margin = 4,
    vb:row{ -- header
      vb:button{
        text=xStreamUI.ARROW_DOWN,
        id = "xStreamModelBrowserToggle",
        tooltip = "Toggle visibility of model list",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          self.model_browser_visible = not self.model_browser_visible
        end,
      },
      vb:text{
        text = "Models",
        font = "bold",
      },
    },
    vb:row{ -- selector
      vb:popup{
        items = self.xstream:get_model_names(),
        id = "xStreamModelSelector",
        width = xStreamUI.MODEL_SELECTOR_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function(val)
          self.xstream.selected_model_index = val-1
        end
      },
      vb:button{
        text = xStreamUI.FAVORITE_TEXT.ON,
        tooltip = "Add this model to the favorites",
        id = "xStreamFavoriteModel",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function(val)
          local model = self.xstream.selected_model
          self.xstream.favorites:toggle_item(model.name)
        end,
      },
    },
    vb:row{ -- controls

      vb:row{
        vb:button{
          --text = "‒",
          --bitmap = "./source/icons/delete.bmp",
          bitmap = "./source/icons/delete_small.bmp",
          tooltip = "Delete the selected model",
          id = "xStreamModelRemove",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self:delete_model()
          end,
        },
        vb:button{
          bitmap = "./source/icons/add.bmp",
          tooltip = "Create a new model",
          id = "xStreamModelCreate",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local passed,err = self:create_model()
            if not passed and err then
              renoise.app():show_warning(err)
            end 
          end,
        },
        --[[
        vb:button{
          --text = "load",
          bitmap = "./source/icons/open.bmp",
          tooltip = "Import model definitions from a folder",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local str_path = renoise.app():prompt_for_path("Select folder containing models")
            if (str_path ~= "") then
              self.xstream:load_models(str_path)
            end
          end,
        },
        ]]
        vb:button{
          bitmap = "./source/icons/reveal_folder.bmp",
          --bitmap = "Icons/Browser_Search.bmp",
          tooltip = "Reveal the folder in which the definition is located",
          id = "xStreamRevealLocation",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.xstream.selected_model:reveal_location()          
          end,
        },        

        vb:button{
          bitmap = "./source/icons/save.bmp",
          --bitmap = "Icons/Browser_ScriptFile.bmp",
          tooltip = "Overwrite the existing definition",
          id = "xStreamModelSave",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local passed,err = self.xstream.selected_model:save()
            if not passed and err then
              renoise.app():show_warning(err)
            end 
          end,
        },
        vb:button{
          bitmap = "./source/icons/rename.bmp",
          tooltip = "Rename the selected model",
          id = "xStreamModelRename",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local success,err = self.xstream.selected_model:rename()          
            if not success then
              renoise.app():show_warning(err)
            else
              self:update()
            end
          end,
        },
        vb:button{
          bitmap = "./source/icons/save_as.bmp",
          tooltip = "Save model under a new name",
          id = "xStreamModelSaveAs",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local passed,err = self.xstream.selected_model:save_as()          
            if not passed and err then
              renoise.app():show_warning(err)
            end 
          end,
        },        
        vb:button{
          bitmap = "./source/icons/refresh.bmp",
          tooltip = "(Re-)load the selected model from disk",
          id = "xStreamModelRefresh",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local success,err = self.xstream.selected_model:refresh()
            if success then
              self:update()
            else
              renoise.app():show_warning(err)
            end

          end,
      },        

      },
    },
    vb:space{
      height = xStreamUI.SMALL_VERTICAL_MARGIN,
    },
    vb:column{
      id = 'xStreamModelContainer',
      tooltip = "Click to activate a model",
      visible = self.model_browser_visible
    }
  }

end

--------------------------------------------------------------------------------

function xStreamUI:build_presets_panel()
  
  local vb = self.vb
  return vb:column{
    style = "panel",
    margin = 4,
    vb:row{
      vb:button{
        text=xStreamUI.ARROW_DOWN,
        id = "xStreamPresetsToggle",
        tooltip = "Toggle visibility of preset list",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          self.presets_visible = not self.presets_visible
        end,
      },
      vb:text{
        text = "Presets",
        font = "bold",
      },
    },
    vb:row{
      vb:bitmap{
        bitmap = "./source/icons/preset_bank.bmp",
        mode = "body_color",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
      },
      vb:popup{
        items = {xStreamPresets.DEFAULT_BANK_NAME},
        tooltip = "Choose between available preset banks",
        id = "xStreamPresetBankSelector",
        width = xStreamUI.PRESET_SELECTOR_W, -- xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function(idx)
          local model = self.xstream.selected_model
          model.selected_preset_bank_index = idx
        end
      },
      vb:row{
        vb:button{
          --text = "‒",
          --bitmap = "./source/icons/delete.bmp",
          bitmap = "./source/icons/delete_small.bmp",
          tooltip = "Remove selected preset bank",
          id = "xStreamPresetBankRemove",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local choice = renoise.app():show_prompt("Delete preset bank",
                "Are you sure you want to delete this preset bank \n"
              .."(this action can not be undone)?",
              {"OK","Cancel"})
            if (choice == "OK") then
              local model = self.xstream.selected_model
              local preset_bank_index = model.selected_preset_bank_index
              local success = model:remove_preset_bank(preset_bank_index)
              if success then
                model.selected_preset_bank_index = 1
              end
            end
          end,
        },

        vb:button{
          bitmap = "./source/icons/add.bmp",
          tooltip = "Create a new preset bank",
          id = "xStreamPresetBankCreate",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local model = self.xstream.selected_model
            local success = model:add_preset_bank()
            if success then
              model.selected_preset_bank_index = #model.preset_banks
              model.selected_preset_bank.modified = true
            end
          end,
        },
        vb:button{
          bitmap = "./source/icons/rename.bmp",
          tooltip = "Rename the selected preset bank",
          id = "xStreamPresetBankRename",
          active = false,
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local success,err = self.xstream.selected_model.selected_preset_bank:rename()
            if not success then
              renoise.app():show_warning(err)
            end 
          end,
        },
        vb:button{
          bitmap = "./source/icons/open.bmp",
          tooltip = "Import/merge presets into selected bank",
          id = "xStreamImportPresetBank",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(val)
            self.xstream.selected_model.selected_preset_bank:import()
          end,
        },
        vb:button{
          bitmap = "./source/icons/save.bmp",
          tooltip = "Export selected preset bank",
          id = "xStreamExportPresetBank",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local success,err = self.xstream.selected_model.selected_preset_bank:export()
            if not success then
              renoise.app():show_warning(err)
            end 
          end
        },

      },
    },
    vb:row{
      vb:bitmap{
        bitmap = "./source/icons/presets.bmp",
        --bitmap = "./source/icons/InstrumentBox.bmp",
        mode = "body_color",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
      },
      vb:popup{
        items = {},
        id = "xStreamPresetSelector",
        tooltip = "Choose between available presets",
        width = xStreamUI.PRESET_SELECTOR_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function(idx)
          local preset_bank = self.xstream.selected_model.selected_preset_bank
          preset_bank.selected_preset_index = idx-1
        end
      },
      vb:button{
        --text = "‒",
        --bitmap = "./source/icons/delete.bmp",
        bitmap = "./source/icons/delete_small.bmp",
        tooltip = "Remove the selected preset",
        id = "xStreamRemovePreset",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function(val)
          local model = self.xstream.selected_model
          local preset_idx = model.selected_preset_bank.selected_preset_index
          model.selected_preset_bank:remove_preset(preset_idx)
        end,
      },
      vb:button{
        bitmap = "./source/icons/add.bmp",
        tooltip = "Add new preset with the current settings",
        id = "xStreamAddPreset",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function(val)
          local model = self.xstream.selected_model
          local added,err = model.selected_preset_bank:add_preset()
          if not added then
            renoise.app():show_warning(err)
          else
            self.xstream.selected_model.selected_preset_bank.selected_preset_index = #model.selected_preset_bank.presets
          end
        end,
      },
      vb:button{
        bitmap = "./source/icons/rename.bmp",
        tooltip = "Assign a new name to this preset",
        id = "xStreamPresetRename",
        active = false,
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          local presets = self.xstream.selected_model.selected_preset_bank
          local success,err = presets:rename_preset(presets.selected_preset_index)
          if not success and err then
            renoise.app():show_warning(err)
          end
        end,
      },

      vb:button{
        bitmap = "./source/icons/update.bmp",
        tooltip = "Update preset with current settings",
        id = "xStreamUpdatePreset",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function(val)
          local model = self.xstream.selected_model
          local preset_idx = model.selected_preset_bank.selected_preset_index
          model.selected_preset_bank:update_preset(preset_idx)
        end,
      },

      vb:button{
        text = xStreamUI.FAVORITE_TEXT.ON,
        tooltip = "Add preset to favorites",
        id = "xStreamFavoritePreset",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function(val)
          local model = self.xstream.selected_model
          local preset_idx = model.selected_preset_bank.selected_preset_index
          local preset_bank_name = model.selected_preset_bank.name
          self.xstream.favorites:toggle_item(model.name,preset_idx,preset_bank_name)
        end,
      },          

    },
    vb:space{
      height = xStreamUI.SMALL_VERTICAL_MARGIN,
    },
    vb:column{
      tooltip = "Available presets for this model",
      id = 'xStreamArgPresetContainer',
      -- add buttons here..
    },
  }  
  
end

--------------------------------------------------------------------------------

function xStreamUI:build_args_panel()

  local vb = self.vb
  return vb:column{
    style = "panel",
    id = "xStreamArgsPanel",
    margin = 4,
    height = 100,
    vb:row{
      --mode = "justify",
      vb:row{
        vb:button{
          text=xStreamUI.ARROW_DOWN,
          id = "xStreamModelArgsToggle",
          tooltip = "Toggle visibility of argument list",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.model_args_visible = not self.model_args_visible
          end,
        },
        vb:text{
          text = "Args",
          font = "bold",
        },
      },
      vb:space{
        width = 6,
      },
      vb:row{
        vb:button{
          bitmap = "./source/icons/add.bmp",
          tooltip = "Create new argument",
          id = "xStreamArgsAddButton",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local idx = self.xstream.selected_model.args.selected_index+1
            --print("self.xstream.selected_model.args.selected_index",self.xstream.selected_model.args.selected_index)
            local added,err = self.xstream.selected_model.args:add(nil,idx)
            --print(">>> args added,err",added,err)
            if not added then
              if err then
                renoise.app():show_warning(err)
              end
            else 
              self.xstream.selected_model.args.selected_index = idx
              self.args_editor_visible = true
            end
          end,
        },
        vb:button{
          id = "xStreamArgsMoveUpButton",
          bitmap = "./source/icons/move_up.bmp",
          tooltip = "Move argument up in list",
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local args = self.xstream.selected_model.args
            local got_moved,_ = args:swap_index(args.selected_index,args.selected_index-1)
            if got_moved then
              args.selected_index = args.selected_index - 1
            end
          end
        },
        vb:button{
          id = "xStreamArgsMoveDownButton",
          bitmap = "./source/icons/move_down.bmp",
          tooltip = "Move argument down in list",
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local args = self.xstream.selected_model.args
            local got_moved,_ = args:swap_index(args.selected_index,args.selected_index+1)
            if got_moved then
              args.selected_index = args.selected_index + 1
            end
          end
        },
        vb:button{
          id = "xStreamArgsEditButton",
          text = "Edit",
          tooltip = "Edit selected argument",
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.args_editor_visible = not self.args_editor_visible
          end
        },
        vb:button{
          id = "xStreamArgsRandomize",
          text = "Random",--"☢ Rnd",
          tooltip = "Randomize all unlocked parameters",
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            if self.xstream.selected_model then
              self.xstream.selected_model.args:randomize()
            end
          end
        },
      },
    },
    vb:row{
      id = "xStreamArgsSelectorRack",
      vb:popup{
        items = {},
        id = "xStreamArgsSelector",
        tooltip = "Choose between available arguments",
        width = xStreamUI.ARGS_SELECTOR_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function(idx)
          local model = self.xstream.selected_model
          if model then
            model.args.selected_index = idx-1
          end
        end,
      },
    },
    vb:text{
      id = "xStreamArgsNoneMessage",
      text = "There are no arguments to display",
    },
    vb:column{
      id = 'xStreamArgsContainer',
    },
    vb:space{
      id = 'xStreamArgsVerticalSpacer',
      height = 7,
    },
    vb:column{
      id = 'xStreamArgsEditorRack',
      visible = self.args_editor_visible,
      self:build_args_editor(),
    },
    --[[
    ]]
  }

end

--------------------------------------------------------------------------------

function xStreamUI:get_expanded_height()
  return self.vb.views["xStreamUpperPanel"].height
    + self.vb.views["xStreamLowerPanels"].height
end

--------------------------------------------------------------------------------

function xStreamUI:get_compact_height()
  return self.vb.views["xStreamFavoritesPanel"].height 
end

--------------------------------------------------------------------------------

function xStreamUI:disable_model_controls()
  TRACE("xStreamUI:disable_model_controls()")

  local view = self.vb.views["xStreamCallbackEditor"]
  if (renoise.API_VERSION > 4) then
    view.active = false
  end

  local args_container = self.vb.views["xStreamArgPresetContainer"]
  args_container.visible = false

  for k,v in ipairs(xStreamUI.MODEL_CONTROLS) do
    self.vb.views[v].active = false
  end

  self.args_editor_visible = false

end

--------------------------------------------------------------------------------

function xStreamUI:enable_model_controls()
  TRACE("xStreamUI:enable_model_controls()")

  local view = self.vb.views["xStreamCallbackEditor"]
  if (renoise.API_VERSION > 4) then
    view.active = true
  end

  local args_container = self.vb.views["xStreamArgPresetContainer"]
  args_container.visible = self.presets_visible

  for k,v in ipairs(xStreamUI.MODEL_CONTROLS) do
    local model = self.xstream.selected_model
    if (v == "xStreamModelSave") then
      self.vb.views[v].active = model.modified
    else
      self.vb.views[v].active = true
    end
  end

end

--------------------------------------------------------------------------------

function xStreamUI:enable_favorite_edit_buttons()
  for k,v in ipairs(xStreamUI.FAVORITE_EDIT_BUTTONS) do
    self.vb.views[v].active = true
  end
end

--------------------------------------------------------------------------------

function xStreamUI:disable_favorite_edit_buttons()
  for k,v in ipairs(xStreamUI.FAVORITE_EDIT_BUTTONS) do
    self.vb.views[v].active = false
  end
end


--------------------------------------------------------------------------------
-- Get/set methods
--------------------------------------------------------------------------------

function xStreamUI:get_start_option()
  return self.start_option_observable.value 
end

function xStreamUI:set_start_option(val)
  self.start_option_observable.value = val

end

--------------------------------------------------------------------------------

function xStreamUI:get_launch_model()
  return self.launch_model_observable.value 
end

function xStreamUI:set_launch_model(val)
  self.launch_model_observable.value = val
  self.update_launch_model_requested = true
end

--------------------------------------------------------------------------------

function xStreamUI:get_autostart()
  return self.autostart_observable.value 
end

function xStreamUI:set_autostart(val)
  self.autostart_observable.value = val
end

--------------------------------------------------------------------------------

function xStreamUI:get_suspend_when_hidden()
  return self.suspend_when_hidden_observable.value 
end

function xStreamUI:set_suspend_when_hidden(val)
  self.suspend_when_hidden_observable.value = val
end

--------------------------------------------------------------------------------

function xStreamUI:get_manage_gc()
  return self.manage_gc_observable.value 
end

function xStreamUI:set_manage_gc(val)
  self.manage_gc_observable.value = val
end

--------------------------------------------------------------------------------

function xStreamUI:get_selected_favorite_index()
  return self.selected_favorite_index_observable.value 
end

function xStreamUI:set_selected_favorite_index(val)
  self.selected_favorite_index_observable.value = val
end

--------------------------------------------------------------------------------

function xStreamUI:get_show_editor()
  return self.show_editor_observable.value 
end

function xStreamUI:set_show_editor(val)
  TRACE("xStreamUI:set_show_editor(val)",val)

  assert(type(val) == "boolean", "Wrong argument type")
  self.show_editor_observable.value = val

  local views = {
    --"xStreamMiddlePanel",
    "xStreamLowerPanelsRack",
    "xStreamCallbackPanel",
  }

  for k,v in ipairs(views) do
     self.vb.views[v].visible = val
  end

  local view_expand = self.vb.views["xStreamToggleExpand"]
  view_expand.bitmap = val and "./source/icons/minimize.bmp" or "./source/icons/maximize.bmp"

  self.vb.views["xStreamPanel"].height = val 
    and self:get_expanded_height() 
    or self:get_compact_height() 

  self:set_favorites_visible(self.favorites_visible)
  self.vb.views["xStreamModelCompact"].visible = not val

  self:resize_upper_panel()

  
end
--------------------------------------------------------------------------------

function xStreamUI:get_editor_visible_lines()
  return self.editor_visible_lines_observable.value
end

function xStreamUI:set_editor_visible_lines(val)
  self.editor_visible_lines_observable.value = val
  self:update_editor()
end

--------------------------------------------------------------------------------

function xStreamUI:get_tool_options_visible()
  return self.tool_options_visible_observable.value
end

function xStreamUI:set_tool_options_visible(val)

  local view_panel = self.vb.views["xStreamImplOptionsPanel"]
  local view_title = self.vb.views["xStreamImplOptionsTitle"]
  --local view_arrow = vb.views["xStreamImplOptionsTitleArrow"]

  view_panel.visible = val
  view_title.visible = val
  --view_arrow.text = visible and "â–¸" or "â—‚"

  --[[
  local view_browser = self.vb.views["xStreamModelContainer"]
  local view_arrow = self.vb.views["xStreamModelBrowserToggle"]

  view_browser.visible = val
  view_arrow.text = val and xStreamUI.ARROW_UP or xStreamUI.ARROW_DOWN
  ]]

  self.tool_options_visible_observable.value = val

end

--------------------------------------------------------------------------------

function xStreamUI:get_model_browser_visible()
  return self.model_browser_visible_observable.value
end

function xStreamUI:set_model_browser_visible(val)
  TRACE("xStreamUI:set_model_browser_visible(val)",val)

  local view_browser = self.vb.views["xStreamModelContainer"]
  local view_arrow = self.vb.views["xStreamModelBrowserToggle"]

  view_browser.visible = val
  view_arrow.text = val and xStreamUI.ARROW_UP or xStreamUI.ARROW_DOWN

  self.model_browser_visible_observable.value = val

end

--------------------------------------------------------------------------------

function xStreamUI:get_model_args_visible()
  return self.model_args_visible_observable.value
end

function xStreamUI:set_model_args_visible(val)
  TRACE("xStreamUI:set_model_args_visible(val)",val)

  -- compacting is another way of hiding the args editor
  --if not val then
    self.args_editor_visible = false
  --end

  local view_arrow = self.vb.views["xStreamModelArgsToggle"]
  local view_popup = self.vb.views["xStreamArgsSelectorRack"]
  local view_spacer = self.vb.views["xStreamArgsVerticalSpacer"]

  view_arrow.text = val and xStreamUI.ARROW_UP or xStreamUI.ARROW_DOWN
  view_popup.visible = not val

  self.model_args_visible_observable.value = val
  self:update_args()
  self:update_args_visibility()
  view_spacer.visible = not val 


end

--------------------------------------------------------------------------------

function xStreamUI:get_args_editor_visible()
  return self.args_editor_visible_observable.value
end

function xStreamUI:set_args_editor_visible(val)
  TRACE("xStreamUI:set_args_editor_visible(val)",val)

  --local view_arrow = self.vb.views["xStreamModelArgsToggle"]
  --local view = self.vb.views["xStreamArgsContainer"]
  local view_button = self.vb.views["xStreamArgsEditButton"]
  local view_popup = self.vb.views["xStreamArgsSelectorRack"]
  local view_editor = self.vb.views["xStreamArgsEditorRack"]
  local view_spacer = self.vb.views["xStreamArgsVerticalSpacer"]
  local view_arrow = self.vb.views["xStreamModelArgsToggle"]

  if val and not self.model_args_visible then
    view_arrow.text = xStreamUI.ARROW_UP 
  elseif not self.model_args_visible then
    view_arrow.text = xStreamUI.ARROW_DOWN
  end

  --view.visible = not val
  view_button.color = val and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED
  if val and self.model_args_visible then
    view_popup.visible = true
  elseif not val and self.model_args_visible then
    view_popup.visible = false
  end
  view_editor.visible = val

  view_spacer.visible = not val 

  self.args_editor_visible_observable.value = val

  self:update_args_editor()
  self:update_args_visibility()

end

--------------------------------------------------------------------------------

function xStreamUI:get_presets_visible()
  return self.presets_visible_observable.value
end

function xStreamUI:set_presets_visible(val)
  TRACE("xStreamUI:set_presets_visible(val)",val)

  local view_browser = self.vb.views["xStreamArgPresetContainer"]
  local view_arrow = self.vb.views["xStreamPresetsToggle"]

  view_browser.visible = val
  view_arrow.text = val and xStreamUI.ARROW_UP or xStreamUI.ARROW_DOWN

  self.presets_visible_observable.value = val

end

--------------------------------------------------------------------------------

function xStreamUI:get_favorites_visible()
  return self.favorites_visible_observable.value
end

function xStreamUI:set_favorites_visible(val)

  local views = {
    "xStreamFavoritesEditButtons",
    "xStreamFavoritesContainer",
  }

  for k,v in ipairs(views) do
    --print("k,v",k,v)
    self.vb.views[v].visible = val
  end

  local view_toggle = self.vb.views["xStreamFavoritesToggle"]
  view_toggle.text = val and xStreamUI.ARROW_LEFT or xStreamUI.ARROW_RIGHT

  self.favorites_visible_observable.value = val

  -- also depending on expanded mode
  self.vb.views["xStreamFavoritesLabel"].visible = true
  self.vb.views["xStreamFavoriteTriggerButton"].visible = false
  self.vb.views["xStreamFavoritesSize"].visible = false
  self.vb.views["xStreamFavoritesLowerToolbar"].visible = true

  if self.favorites_visible then
    self.vb.views["xStreamFavoritesSize"].visible = true
    if self.show_editor then
    else
    end
  else
    if self.show_editor then
      self.vb.views["xStreamFavoritesLabel"].visible = false
      self.vb.views["xStreamFavoritesLowerToolbar"].visible = false
   else
      self.vb.views["xStreamFavoriteTriggerButton"].visible = true
    end
  end

  self:update_favorite_selector()
  self:update_favorite_edit_rack()
  self:resize_upper_panel()

end

--------------------------------------------------------------------------------

function xStreamUI:delete_model()

  local choice = renoise.app():show_prompt("Delete model",
      "Are you sure you want to delete this model \n"
    .."(this action can not be undone)?",
    {"OK","Cancel"})
  
  if (choice == "OK") then
    local model_idx = self.xstream.selected_model_index
    local success,err = self.xstream:delete_model(model_idx)
    if not success then
      renoise.app():show_error(err)
    end
  end

end

--------------------------------------------------------------------------------

function xStreamUI:on_idle()

  -- scheduling: blinking stuff ---------------------------

  local blink_state = (math.floor(os.clock()*4)%2 == 0) 
  if (blink_state ~= self.blink_state) then

    self.blink_state = blink_state

    if self.scheduled_model_index then
      self:update_scheduled_model(
        self.scheduled_model_index, (blink_state) and xStreamUI.SCHEDULE_TEXT.OFF or xStreamUI.SCHEDULE_TEXT.ON)
    end

    if self.scheduled_preset_index then
      self:update_scheduled_preset(
        self.scheduled_preset_index, (blink_state) and xStreamUI.SCHEDULE_TEXT.OFF or xStreamUI.SCHEDULE_TEXT.ON)
    end

    if self.scheduled_favorite_index then
      self:update_favorite_button(
        self.scheduled_favorite_index, (not blink_state) and xStreamUI.DIMMED_AMOUNT)
    end

  end

  -- delayed update of callback string --------------------

  if self.user_modified_callback then
    local model = self.xstream.selected_model
    if model then
      --print("*** xStreamUI:on_idle - callback modified")
      local view = self.vb.views["xStreamCallbackEditor"]
      model.callback_str = view.text --.. "\n"
    end
    self.user_modified_callback = false
  end

  -- delayed display updates ------------------------------
  -- TODO optimize by turning into mini-scheduling system

  if self.build_favorites_requested then
    self.build_favorites_requested = false
    self:build_favorites()
    self:update_favorite_buttons()
    self:update_favorite_selector()
    self:update_model_list()
    self:update_model_controls()
    self:update_preset_list()
    self:update_preset_controls()
    self:resize_upper_panel()
  end

  if self.build_presets_requested then
    self.build_presets_requested = false
    self:build_preset_list()
    self:update_preset_controls()
    self:update_preset_selector()

  end

  if self.build_models_requested then
    self.build_models_requested = false
    self:update_model_selector()
    self:build_model_list()
  end

  if self.update_favorites_requested then
    self.update_favorites_requested = false
    self:update_favorite_buttons()
    self:update_favorite_selector()
  end

  if self.update_model_requested then
    if self.xstream.selected_model then
      self:enable_model_controls()
    else
      self:disable_model_controls()
    end
    self.update_model_requested = false
    self.update_models_requested = true
    self:update_model_selector()
    self.build_args_requested = true
    self.update_args_requested = true
    self:update_color()
  end

  if self.build_args_requested then
    self.build_args_requested = false
    self.update_args_requested = true
    self:build_args()
  end

  if self.update_args_requested then
    self.update_args_requested = false
    self:update_args()
    self:update_args_editor()
    self:update_args_selector()
    self:update_args_controls()
    self:update_args_visibility()
  end

  if self.update_launch_model_requested then
    self.update_launch_model_requested = false
    self:update_launch_model_selector()
  end

  if self.update_models_requested then
    self.update_models_requested = false
    self:update_model_controls()
    self:update_model_list()
    self:update_model_title()
  end

  if self.favorite_edit_rack_requested then
    self.favorite_edit_rack_requested = false
    self:update_favorite_edit_rack()
    self:update_favorite_button(self.xstream.favorites.last_selected_index)
  end

  if self.update_presets_requested then
    self.update_presets_requested = false
    self:update_preset_list()
    self:update_preset_selector()
    self:update_preset_controls()
  end

  if self.update_color_requested then
    self.update_color_requested = false
    self:update_model_list()
    self:update_preset_list()
    self:build_favorites()
    self:update_favorite_buttons()
    self:update_favorite_selector()
    self:update_color()
  end

  -- briefly flashing buttons -----------------------------

  for k,v in ripairs(self.flash_favorite_buttons) do
    if (v.clocked < os.clock() - xStreamUI.FLASH_TIME) then
      if (v.index ~= self.scheduled_favorite_index) then
        self:update_favorite_button(v.index)
      end
      table.remove(self.flash_favorite_buttons,k)
    end
  end

  
  -- display some stats -----------------------------------

  local view = self.vb.views["xStreamImplStats"]
  local str_stat = ("Memory usage: %.2f Mb"):format(collectgarbage("count")/1024)
    ..("\nLines Travelled: %d"):format(self.xstream.stream.writepos.lines_travelled)
    ..("\nWriteahead: %d lines"):format(self.xstream.writeahead)
    ..("\nSelected model: %s"):format(self.xstream.selected_model and self.xstream.selected_model.name or "N/A") 
    ..("\nStream active: %s"):format(self.xstream.active and "true" or "false") 
    ..("\nStream muted: %s"):format(self.xstream.muted and "true" or "false") 
  view.text = str_stat


end

