--[[============================================================================
xStreamUI
============================================================================]]--
--[[

	User-interface for xStream - provides controls for most of the 
  properties and methods available in the application

]]

--==============================================================================

class 'xStreamUI'

xStreamUI.COLOR_ENABLED = {0xD0,0xD8,0xD4}
xStreamUI.COLOR_DISABLED = {0x00,0x00,0x00}
xStreamUI.COLOR_BASE = {0x5A,0x5A,0x5A}

xStreamUI.MODEL_CONTROLS = {
  "xStreamApplyLocallyButton",
  "xStreamApplySelectionButton",
  "xStreamApplyTrackButton",
  "xStreamApplyTrackButton",
  "xStreamCallbackCompile",
  "xStreamFavoriteModel",
  "xStreamModelColorPreview",
  "xStreamModelRefresh",
  "xStreamModelRemove",
  "xStreamModelRename",
  "xStreamModelSave",
  "xStreamModelSaveAs",
  "xStreamMuteButton",
  "xStreamRevealLocation",
  "xStreamStartPlayButton",
  "xStreamToggleStreaming",
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

xStreamUI.NO_MODEL_SELECTED = "(Select model)"

xStreamUI.ARROW_UP = "▴"
xStreamUI.ARROW_DOWN = "▾"
xStreamUI.ARROW_LEFT = "◂"
xStreamUI.ARROW_RIGHT = "▸"

xStreamUI.BITMAP_BUTTON_W = 21
xStreamUI.BITMAP_BUTTON_H = 19
xStreamUI.LEFT_PANEL_W = 240
xStreamUI.RIGHT_PANEL_W = 256
xStreamUI.FULL_PANEL_W = xStreamUI.LEFT_PANEL_W + xStreamUI.RIGHT_PANEL_W + 4
xStreamUI.CALLBACK_EDITOR_W = 500 -- 80 characters
xStreamUI.MONO_CHAR_W = 7 -- single character 
xStreamUI.TRANSPORT_BUTTON_W = 28
xStreamUI.MODEL_SELECTOR_W = 165
--xStreamUI.MODEL_SELECTOR_COMPACT_W = 127
xStreamUI.FLASH_TIME = 0.2
xStreamUI.LINE_HEIGHT = 14
xStreamUI.MAX_BRIGHT_COLOR = 1
xStreamUI.BRIGHTEN_AMOUNT = 0.9
xStreamUI.HIGHLIGHT_AMOUNT = 0.66
xStreamUI.DIMMED_AMOUNT = 0.40
xStreamUI.SELECTED_COLOR = 0.20
xStreamUI.EDIT_RACK_MARGIN = 40
xStreamUI.SMALL_VERTICAL_MARGIN = 6

xStreamUI.ARGS_MIN_VALUE = -99999
xStreamUI.ARGS_MAX_VALUE = 99999

xStreamUI.ICON_COMPACT = "./source/icons/minimize.bmp"
xStreamUI.ICON_EXPANDED = "./source/icons/maximize.bmp"

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

  assert(type(xstream)=="xStream","Expected 'xStream' to be a class instance")
  assert(type(vb)=="ViewBuilder","Expected 'vb' to be a class instance")
  assert(type(midi_prefix)=="string","Expected 'midi_prefix' to be a string")

  self.xstream = xstream
  self.vb = vb
  self.midi_prefix = midi_prefix

  self.presets = xStreamUIPresetPanel(xstream,vb,self)
  self.args  = xStreamUIArgsPanel(xstream,midi_prefix,vb,self)
  self.args_editor = xStreamUIArgsEditor(xstream,vb)

  self.options = xStreamUIOptions(xstream)
  self.favorites = xStreamUIFavorites(xstream,midi_prefix)

  self.vb_content = nil

  -- bool, any blinking element should use this 
  self.blink_state = false

  -- delayed display updates
  self.build_presets_requested = false
  self.update_presets_requested = false
  self.update_models_requested = false
  self.build_models_requested = false
  self.update_color_requested = false
  self.update_model_requested = false
  self.build_args_requested = false
  self.update_args_requested = false

  --self.favorite_views = {}
  self.model_views = {}
  
  self.scheduled_model_index = nil
  self.scheduled_preset_index = nil
  --self.scheduled_favorite_index = nil

  -- int, changes with selected model/preset - 0 means not favorited
  -- (not to be confused with the selected favorite in the grid)
  self.selected_favorite_index = property(self.get_selected_favorite_index,self.set_selected_favorite_index)

  self.show_editor = property(self.get_show_editor,self.set_show_editor)
  self.show_editor_observable = renoise.Document.ObservableBoolean(true)

  self.tool_options_visible = property(self.get_tool_options_visible,self.set_tool_options_visible)
  self.tool_options_visible_observable = renoise.Document.ObservableBoolean(false)

  self.model_browser_visible = property(self.get_model_browser_visible,self.set_model_browser_visible)
  self.model_browser_visible_observable = renoise.Document.ObservableBoolean(false)

  --self.favorites_visible = property(self.get_favorites_visible,self.set_favorites_visible)
  --self.favorites_visible_observable = renoise.Document.ObservableBoolean(false)

  self.editor_visible_lines = property(self.get_editor_visible_lines,self.set_editor_visible_lines)
  self.editor_visible_lines_observable = renoise.Document.ObservableNumber(16)

  -- bool, set immediately after changing the callback string
  self.user_modified_callback = false

  -- renoise.Dialog, wizard-style dialog for creating models
  self.model_dialog = nil

  -- renoise.View
  self.model_dialog_content = nil

  self.model_dialog_page = nil
  self.model_dialog_option = nil

  self.base_color_highlight = vColor.adjust_brightness(xStreamUI.COLOR_BASE,xStreamUI.HIGHLIGHT_AMOUNT)


  -- initialize -----------------------

  self:build()

end

--------------------------------------------------------------------------------
-- build, update everything

function xStreamUI:update()
  TRACE("xStreamUI:update()")

  self.favorites.update_requested = true
  self.update_model_requested = true
  self.build_args_requested = true
  self.build_presets_requested = true

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

  local model_names = self.xstream:get_model_names()
  table.insert(model_names,1,xStreamUI.NO_MODEL_SELECTED)
  local view_popup = self.vb.views["xStreamModelSelector"]

  local selector_value = (self.xstream.selected_model_index == 0) 
      and 1 or self.xstream.selected_model_index+1
  view_popup.items = model_names
  view_popup.value = selector_value

  self.favorites:update_model_selector(model_names)
  self.options:update_model_selector(model_names)

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

function xStreamUI:update_scheduled_preset(idx,txt)
  TRACE("xStreamUI:update_scheduled_preset(idx,txt)",idx,txt)

  local str_id = "xStreamModelPresetSchedule"..idx
  local view_bt = self.vb.views[str_id]
  if view_bt then
    view_bt.text = txt
  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_color()
  TRACE("xStreamUI:update_color()")

  local model = self.xstream.selected_model
  local view = self.vb.views["xStreamModelColorPreview"]
  if model then
    view.color = vColor.value_to_color_table(model.color)
    view.visible = true
  else
    view.color = {0,0,0}
    view.visible = false
  end

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

  local view_callback_panel = self:build_callback_panel()
  --local view_models_panel = self:build_models_panel()
  local view_presets_panel = self.presets:build_panel()
  local view_args_panel = self.args:build()

  local content = vb:row{
    --view_options_panel,
    vb:column{
      id = "xStreamPanel",
      vb:row{ -- xStreamUpperPanel
        id = "xStreamUpperPanel",
        style = "panel",
        margin = 4,
        vb:horizontal_aligner{
          id = "xStreamTransportAligner",
          mode = "justify",
          width = xStreamUI.FULL_PANEL_W,
          vb:row{
            id = "xStreamTransportRow",
            vb:row{
              vb:column{
                margin = 2,
                vb:bitmap{
                  bitmap = "./source/icons/logo.png",
                  width = 100,
                  mode = "main_color",
                  tooltip = "Read the xStream documentation",
                  notifier = function()
                    renoise.app():open_url("https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.xStream.xrnx")
                  end,
                },
              },
              vb:space{
                width = 6,
              },
              --[[
              vb:button{
                bitmap = "./source/icons/transport_record.bmp",
                tooltip = "Record streaming (not yet implemented)",
                active = false,
                width = xStreamUI.TRANSPORT_BUTTON_W,
                height = xStreamUI.BITMAP_BUTTON_H,
              },
              ]]
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
          vb:row{
            vb:button{
              tooltip = "Show favorites",
              text = "Favorites",
              height = xStreamUI.BITMAP_BUTTON_H,
              notifier = function()
                self.favorites:show()
              end
            },
            vb:button{
              tooltip = "Show options",
              text = "Options",
              height = xStreamUI.BITMAP_BUTTON_H,
              notifier = function()
                self.tool_options_visible = not self.tool_options_visible
              end
            },
            --[[
            vb:button{
              tooltip = "Toggle compact/full mode [Tab]",
              id = "xStreamToggleExpand",
              width = xStreamUI.BITMAP_BUTTON_W,
              height = xStreamUI.BITMAP_BUTTON_H,
              notifier = function()
                self.show_editor = not self.show_editor
              end,
            },  
            ]]
          },
        },
      },

      vb:row{ -- callback, lower panels
        id = "xStreamLowerPanels",
        vb:column{
          id = "xStreamMiddlePanel",
          view_callback_panel,
          vb:row{ -- xStreamLowerPanelsRack
            id = "xStreamLowerPanelsRack",
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

  local preset_bank_notifier = function()
    TRACE("*** xStreamUI - preset_bank_notifier fired...")
    self.presets:update_controls()
    self.favorites:update_bank_selector()
  end

  local preset_bank_index_notifier = function()
    TRACE("*** xStreamUI - model.selected_preset_bank_index_observable fired...")
    local presets_modified_notifier = function()
      TRACE("*** xStreamUI - presets_modified_notifier fired...")
      self.build_presets_requested = true
      self.favorites:update_preset_selector()
    end
    self.build_presets_requested = true
    self.update_presets_requested = true
    local preset_bank = self.xstream.selected_model.selected_preset_bank
    xObservable.attach(preset_bank.presets_observable,presets_modified_notifier)
    xObservable.attach(preset_bank.modified_observable,presets_modified_notifier)
    xObservable.attach(preset_bank.selected_preset_index_observable,function()    
      TRACE("*** xStreamUI - preset_bank.selected_preset_index_observable fired...")
      self.update_presets_requested = true
    end)
    xObservable.attach(preset_bank.name_observable,preset_bank_notifier)
  end

  local selected_model_index_notifier = function()
    TRACE("*** xStreamUI - selected_model_index_notifier fired...",self.xstream.selected_model_index)
    local model = self.xstream.selected_model
    if model then
      --print(">>> #model.args.args",#model.args.args)
      xObservable.attach(model.name_observable,function()
        TRACE("*** xStreamUI - model.name_observable fired...")
        self.build_models_requested = true
      end)
      xObservable.attach(model.modified_observable,function()
        TRACE("*** xStreamUI - model.modified_observable fired...")
        self.update_models_requested = true
      end)
      xObservable.attach(model.compiled_observable,function()
        TRACE("*** xStreamUI - model.compiled_observable fired...")
        vb.views["xStreamCallbackCompile"].active = self.xstream.selected_model.compiled
      end)
      xObservable.attach(model.color_observable,function()    
        TRACE("*** xStreamUI - model.color_observable fired...")
        self.update_color_requested = true
      end)
      xObservable.attach(model.args.selected_index_observable,function()
        TRACE("*** xStreamUI - selected_arg_notifier fired...")
        self.update_args_requested = true
      end)
      xObservable.attach(model.args.args_observable,function(arg)
        TRACE("*** xStreamUI - args_observable_notifier fired...",rprint(arg))
        if (arg.type == "remove") then
          self.args:purge_arg_views()
        end
        self.build_args_requested = true
      end)
      xObservable.attach(model.args.modified_observable,function()
        TRACE("*** xStreamUI - args_modified_notifier fired...")
        self.xstream.selected_model.modified = true
      end)
      xObservable.attach(model.callback_str_observable,function()
        TRACE("*** xStreamUI - callback_notifier fired...")
        if not self.user_modified_callback then
          --print("... got here")
          self:update_editor()
        end
      end)
      xObservable.attach(model.preset_banks_observable,preset_bank_notifier)
      xObservable.attach(model.selected_preset_bank_index_observable,preset_bank_index_notifier)
      preset_bank_index_notifier()
      -- select first argument
      if (#model.args.args > 0) then
        model.args.selected_index = 1
      end
    end
    self.update_model_requested = true
    self:update_editor()

    if vPrompt.color_prompt.dialog and vPrompt.color_prompt.dialog.visible then
      vPrompt.prompt_for_color(color_callback,model.color)
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
    style = "panel",
    margin = 4,
    vb:space{
      width = xStreamUI.FULL_PANEL_W,
    },
    vb:row{
      vb:row{
        id = "xStreamCallbackHeader",
        vb:button{
          tooltip = "Toggle visiblity of code editor [Tab]",
          text = xStreamUI.ARROW_DOWN,
          id = "xStreamToggleExpand",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.show_editor = not self.show_editor
          end,
        },  
        vb:text{
          text = "Model",
          font = "bold",
        },
        vb:button{
          tooltip = "Pick color",
          id = "xStreamModelColorPreview",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local model_color = self.xstream.selected_model.color
            vPrompt.prompt_for_color(color_callback,model_color,xStreamUI.DEFAULT_PALETTE)
          end,
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

        vb:popup{ -- selector
          items = self.xstream:get_model_names(),
          id = "xStreamModelSelector",
          width = xStreamUI.MODEL_SELECTOR_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(val)
            self.xstream.selected_model_index = val-1
          end
        },

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
      vb:row{
        vb:row{
          id = "xStreamModelEditorNumLinesContainer",
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
      id = "xStreamCallbackEditorToolbar",
      vb:row{
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
    },
  }

end


--------------------------------------------------------------------------------

function xStreamUI:get_expanded_height()
  return self.vb.views["xStreamUpperPanel"].height
    + self.vb.views["xStreamLowerPanels"].height
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

  self.presets.disabled = true
  self.args.disabled = true
  self.args_editor.visible = false

end

--------------------------------------------------------------------------------

function xStreamUI:enable_model_controls()
  TRACE("xStreamUI:enable_model_controls()")

  local view = self.vb.views["xStreamCallbackEditor"]
  if (renoise.API_VERSION > 4) then
    view.active = true
  end

  local args_container = self.vb.views["xStreamArgPresetContainer"]
  args_container.visible = self.presets.visible

  for k,v in ipairs(xStreamUI.MODEL_CONTROLS) do
    local model = self.xstream.selected_model
    if (v == "xStreamModelSave") then
      self.vb.views[v].active = model.modified
    else
      self.vb.views[v].active = true
    end
  end

  self.presets.disabled = false
  self.args.disabled = false

end

--------------------------------------------------------------------------------
-- Get/set methods
--------------------------------------------------------------------------------

function xStreamUI:get_selected_favorite_index()
  return self.favorites.selected_index_observable.value 
end

function xStreamUI:set_selected_favorite_index(val)
  self.favorites.selected_index_observable.value = val
end

--------------------------------------------------------------------------------

function xStreamUI:get_show_editor()
  return self.show_editor_observable.value 
end

function xStreamUI:set_show_editor(val)
  TRACE("xStreamUI:set_show_editor(val)",val)

  assert(type(val) == "boolean", "Wrong argument type")
  self.show_editor_observable.value = val

  self.vb.views["xStreamModelEditorNumLinesContainer"].visible = val
  local view_expand = self.vb.views["xStreamToggleExpand"]
  view_expand.text = val and xStreamUI.ARROW_UP or xStreamUI.ARROW_DOWN
  self.vb.views["xStreamCallbackEditor"].visible = val
  self.vb.views["xStreamCallbackEditorToolbar"].visible = val

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
  if val then
    self.options:show()
  else
    self.options:close()
  end
end

--------------------------------------------------------------------------------
--[[
function xStreamUI:get_favorites_visible()
  return self.favorites_visible_observable.value
end

function xStreamUI:set_favorites_visible(val)
  self.favorites_visible_observable.value = val
end
]]
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

  if self.build_presets_requested then
    self.build_presets_requested = false
    self.presets:build_list()
    self.presets:update_controls()
    self.presets:update_selector()
  end

  if self.build_models_requested then
    self.build_models_requested = false
    self:update_model_selector()
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
    self.args:build_args()
  end

  if self.update_args_requested then
    self.update_args_requested = false
    self.args:update()
    self.args_editor:update()
    self.args:update_selector()
    self.args:update_controls()
    self.args:update_visibility()
  end

  if self.update_models_requested then
    self.update_models_requested = false
    self:update_model_controls()
    self:update_model_selector()
  end

  if self.update_presets_requested then
    self.update_presets_requested = false
    self.presets:update_list()
    self.presets:update_selector()
    self.presets:update_controls()
  end

  if self.update_color_requested then
    self.update_color_requested = false
    self.presets:update_list()
    self.favorites.build_requested = true
    self:update_color()
  end


end

