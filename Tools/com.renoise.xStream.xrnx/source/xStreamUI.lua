--[[============================================================================
xStreamUI
============================================================================]]--
--[[

	User-interface for xStream - provides controls for most of the 
  properties and methods available in the application

]]

--==============================================================================

class 'xStreamUI' (vDialog)

xStreamUI.COLOR_ENABLED = {0xD0,0xD8,0xD4}
xStreamUI.COLOR_DISABLED = {0x00,0x00,0x00}
xStreamUI.COLOR_BASE = {0x5A,0x5A,0x5A}

-- disable along with model
xStreamUI.MODEL_CONTROLS = {
  "xStreamApplyLocallyButton",
  "xStreamApplySelectionButton",
  "xStreamApplyTrackButton",
  "xStreamApplyTrackButton",
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
  "xStreamCallbackCreate",
  "xStreamCallbackRename",
  "xStreamCallbackRemove",
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
xStreamUI.MODEL_SELECTOR_W = 145
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
-- @param midi_prefix (string)

function xStreamUI:__init(...)
  TRACE("xStreamUI:__init()")

  local args = cLib.unpack_args(...)

  assert(type(args.xstream)=="xStream","Expected 'xStream' to be a class instance")
  assert(type(args.midi_prefix)=="string","Expected 'midi_prefix' to be a string")

  vDialog.__init(self,...)

  --- xStreamPrefs, current settings
  self.prefs = renoise.tool().preferences
  self.midi_prefix = args.midi_prefix
  self.xstream = args.xstream

  -- supporting classes --

  -- views
  self.presets = xStreamUIPresetPanel(self.xstream,self.vb,self)
  self.args_panel  = xStreamUIArgsPanel(self.xstream,self.midi_prefix,self.vb,self)
  self.args_editor = xStreamUIArgsEditor(self.xstream,self.vb)

  -- dialogs
  self.options = xStreamUIOptions(self.xstream)
  self.favorites = xStreamUIFavorites(self.xstream,self.midi_prefix)
  self.create_model_dialog = xStreamUIModelCreate(self)
  self.create_callback_dialog = xStreamUICallbackCreate(self)

  -- content --

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
  self.update_editor_requested = false

  --self.favorite_views = {}
  self.model_views = {}
  
  self.scheduled_model_index = nil
  self.scheduled_preset_index = nil

  -- int, changes with selected model/preset - 0 means not favorited
  -- (not to be confused with the selected favorite in the grid)
  self.selected_favorite_index = property(self.get_selected_favorite_index,self.set_selected_favorite_index)

  self.show_editor = property(self.get_show_editor,self.set_show_editor)
  self.show_editor_observable = renoise.Document.ObservableBoolean(true)

  self.tool_options_visible = property(self.get_tool_options_visible,self.set_tool_options_visible)
  self.tool_options_visible_observable = renoise.Document.ObservableBoolean(false)

  self.compact_mode = property(self.get_compact_mode,self.set_compact_mode)
  self.compact_mode_observable = renoise.Document.ObservableBoolean(false)

  self.model_browser_visible = property(self.get_model_browser_visible,self.set_model_browser_visible)
  self.model_browser_visible_observable = renoise.Document.ObservableBoolean(false)

  self.editor_visible_lines = property(self.get_editor_visible_lines,self.set_editor_visible_lines)
  self.editor_visible_lines_observable = renoise.Document.ObservableNumber(16)

  -- bool, set when user has changed one of the callbacks
  self.user_modified_callback = false

  -- bool, suppress editor notifications 
  self.suppress_editor_notifier = false

  -- string, tells us the type of content in the editor 
  -- valid values are "main", "data.[xStreamArg.full_name]" or "event.[xMidiMessage.TYPE]"
  self.editor_view = "main"

  self.base_color_highlight = cColor.adjust_brightness(xStreamUI.COLOR_BASE,xStreamUI.HIGHLIGHT_AMOUNT)


  --== notifiers ==--

  self.show_editor_observable:add_notifier(function()
    TRACE("xStreamUI - self.show_editor_observable fired...")
    self.prefs.show_editor.value = self.show_editor_observable.value
  end)

  self.tool_options_visible_observable:add_notifier(function()
    TRACE("xStreamUI - self.tool_options_visible_observable fired...")
    self.prefs.tool_options_visible.value = self.tool_options_visible_observable.value
  end)

  self.model_browser_visible_observable:add_notifier(function()
    TRACE("xStreamUI - self.model_browser_visible_observable fired...")
    self.prefs.model_browser_visible.value = self.model_browser_visible
  end)

  self.args_panel.visible_observable:add_notifier(function()
    TRACE("xStreamUI - self.args_panel.visible_observable fired...")
    self.prefs.model_args_visible.value = self.args_panel.visible
  end)

  self.presets.visible_observable:add_notifier(function()
    TRACE("xStreamUI - self.presets.visible_observable fired...")
    self.prefs.presets_visible.value = self.presets.visible
  end)

  self.favorites.pinned_observable:add_notifier(function()
    TRACE("xStreamUI - self.favorites.pinned_observable fired...")
    self.prefs.favorites_pinned.value = self.favorites.pinned
  end)

  self.editor_visible_lines_observable:add_notifier(function()
    TRACE("xStreamUI - self.editor_visible_lines_observable fired...")
    self.prefs.editor_visible_lines.value = self.editor_visible_lines
  end)
  
  self.compact_mode_observable:add_notifier(function()
    TRACE("xStreamUI - compact_mode_observable fired...")
    self.prefs.compact_mode.value = self.compact_mode_observable.value
  end)
  
  --== tool notifications ==--

  renoise.tool().app_new_document_observable:add_notifier(function()
    TRACE("xStreamUI - app_new_document_observable fired...")
    self:attach_to_song()    
  end)

  --== initialize ==--

  self:build()

  -- vDialog --

  self.dialog_visible_observable:add_notifier(function()
    TRACE(">>> xStreamUI.dialog_visible_observable fired...")
  end)

  self.compact_mode = self.prefs.compact_mode.value

end

-------------------------------------------------------------------------------
-- vDialog
-------------------------------------------------------------------------------

function xStreamUI:create_dialog()
  TRACE("xStreamUI:create_dialog()")

  return self.vb:column{
    self.vb_content,
  }

end

-------------------------------------------------------------------------------

function xStreamUI:show()
  TRACE("xStreamUI:show()")

  vDialog.show(self)

  if self.prefs.favorites_pinned.value then
    self.favorites:show()
  end

end


--------------------------------------------------------------------------------
-- xStreamUI
--------------------------------------------------------------------------------
-- build, update everything

function xStreamUI:update()
  TRACE("xStreamUI:update()")

  self.favorites.update_requested = true
  self.update_model_requested = true
  self.build_args_requested = true
  self.build_presets_requested = true

  self:update_color()
  self:update_play_button()
  self:update_active_button()

end

--------------------------------------------------------------------------------

function xStreamUI:update_play_button()
  TRACE(">>> xStreamUI:update_play_button()")
  local vb = self.vb
  local view = vb.views["xStreamStartPlayButton"]
  local color = rns.transport.playing
    and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED
  view.color = color
end

--------------------------------------------------------------------------------

function xStreamUI:update_active_button()
  TRACE("xStreamUI:update_active_button()")
  local vb = self.vb
  local view = vb.views["xStreamToggleStreaming"]
  local color = self.xstream.process.active 
    and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED
  view.color = color
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

  local model_names = self.xstream.process.models:get_names()
  table.insert(model_names,1,xStreamUI.NO_MODEL_SELECTED)
  local view_popup = self.vb.views["xStreamModelSelector"]
  local view_compact_popup = self.vb.views["xStreamCompactModelSelector"]

  local selector_value = (self.xstream.selected_model_index == 0) 
      and 1 or self.xstream.selected_model_index+1

  view_popup.items = model_names
  view_popup.value = selector_value
  view_compact_popup.items = model_names
  view_compact_popup.value = selector_value

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
    view.color = cColor.value_to_color_table(model.color)
    view.active = true
  else
    view.color = {0,0,0}
    view.active = false
  end

end

--------------------------------------------------------------------------------

function xStreamUI:update_editor()
  TRACE("xStreamUI:update_editor()")

  local model = self.xstream.selected_model
  --local view_lines = self.vb.views["xStreamModelEditorNumLines"]
  local view = self.vb.views["xStreamCallbackEditor"]

  --view_lines.value = self.editor_visible_lines
  view.height = self.editor_visible_lines * xStreamUI.LINE_HEIGHT - 6

  -- type popup: include defined userdata + events 
  local vb_type_popup = self.vb.views["xStreamCallbackType"]
  local items = {}
  if model then
    for k,v in pairs(model.data) do
      table.insert(items,("data.%s"):format(k))
    end
    for k,v in pairs(model.events) do
      table.insert(items,("events.%s"):format(k))
    end
  end
  table.sort(items)
  if model then
    table.insert(items,1,"main")
  end
  vb_type_popup.items = items
  vb_type_popup.value = table.find(items,self.editor_view) or 1
  vb_type_popup.active = (#items > 1)

  self:set_editor_content()

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

  local model_names = self.xstream.process.models:get_names()
  local view_callback_panel = self:build_callback_panel()
  --local view_models_panel = self:build_models_panel()
  local view_presets_panel = self.presets:build_panel()
  local view_args_panel = self.args_panel:build()

  local content = vb:row{
    --view_options_panel,
    vb:column{
      id = "xStreamPanel",
      vb:row{ -- xStreamUpperPanel
        id = "xStreamUpperPanel",
        --style = "body",
        margin = 4,
        vb:horizontal_aligner{
          id = "xStreamTransportAligner",
          mode = "justify",
          width = xStreamUI.FULL_PANEL_W,
          vb:row{
            id = "xStreamTransportRow",
            vb:row{
              vb:column{
                id = "xStreamLogo",
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
              vb:popup{ -- compact mode only: model selector
                items = model_names,
                id = "xStreamCompactModelSelector",
                width = xStreamUI.MODEL_SELECTOR_W,
                height = xStreamUI.BITMAP_BUTTON_H,
                visible = false,
                notifier = function(val)
                  self.xstream.selected_model_index = val-1
                end
              },              
              vb:space{
                width = 6,
              },
              vb:button{
                bitmap = "./source/icons/transport_play.bmp",
                tooltip = "Activate streaming and (re-)start playback",
                id = "xStreamStartPlayButton",
                width = xStreamUI.TRANSPORT_BUTTON_W,
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  self.xstream:start_and_play()
                end,
              },
              vb:button{
                bitmap = "./source/icons/transport_stop.bmp",
                tooltip = "Stop streaming and playback",
                id = "xStreamStopButton",
                width = xStreamUI.TRANSPORT_BUTTON_W,
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  rns.transport:stop()
                end,
              },
              vb:button{
                bitmap = "./source/icons/transport_record.bmp",
                tooltip = "Toggle whether streaming is active",
                id = "xStreamToggleStreaming",
                width = xStreamUI.TRANSPORT_BUTTON_W,
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  self.xstream.active = not self.xstream.active
                  --[[
                  if self.xstream.active then
                    self.xstream:stop()
                  else
                    self.xstream:start()
                  end
                  ]]
                end,
              },
              vb:button{
                text = "M",
                tooltip = "Mute/unmute stream",
                id = "xStreamMuteButton",
                width = xStreamUI.TRANSPORT_BUTTON_W,
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  self.xstream.process.muted = not self.xstream.process.muted
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
                notifier = function()
                  self.xstream.process:fill_track()
                end,
              },
              vb:button{
                text = "↓ SEL",
                tooltip = "Apply to the selected lines (relative to top of pattern)",
                id = "xStreamApplySelectionButton",
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  self.xstream.process:fill_selection()
                end,
              },
              vb:button{
                text = "↧ SEL",
                tooltip = "Apply to the selected lines (relative to start of selection)",
                id = "xStreamApplyLocallyButton",
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  self.xstream.process:fill_selection(true)
                end,
              },
            },
          },
          vb:row{       
            --[[
            vb:button{
              tooltip = "Show processes",
              text = "☶ ▾",
              height = xStreamUI.BITMAP_BUTTON_H,
              width = xStreamUI.BITMAP_BUTTON_W,
              notifier = function()
              end
            },
            ]]
            vb:button{
              tooltip = "Show favorites",
              text = "★",
              height = xStreamUI.BITMAP_BUTTON_H,
              width = xStreamUI.BITMAP_BUTTON_W,
              notifier = function()
                self.favorites:show()
              end
            },
            vb:button{
              tooltip = "Show options",
              text = "Options",
              --text = "⚙",
              height = xStreamUI.BITMAP_BUTTON_H,
              notifier = function()
                self.tool_options_visible = not self.tool_options_visible
              end
            },
            vb:button{
              id = "xStreamToggleCompactMode",
              tooltip = "Toggle between compact and full display",
              text = "-",
              height = xStreamUI.BITMAP_BUTTON_H,
              width = xStreamUI.BITMAP_BUTTON_W,
              notifier = function()
                self.compact_mode = not self.compact_mode
              end
            },
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

  self.xstream.process.buffer.callback_status_observable:add_notifier(function()    
    TRACE("xStreamUI - callback_status_observable fired...")
    local str_err = self.xstream.process.buffer.callback_status_observable.value
    local view = self.vb.views["xStreamCallbackStatus"]
    if (str_err == "") then
      view.text = "Syntax OK"
      view.tooltip = ""
    else
      view.text = "⚠ Syntax Error"
      view.tooltip = str_err
    end 

  end)

  self.xstream.process.muted_observable:add_notifier(function()    
    TRACE("xStreamUI - xstream.muted_observable fired...")
    local view = vb.views["xStreamMuteButton"]
    local color = self.xstream.process.muted 
      and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED
    view.color = color
  end)

  self.xstream.process.active_observable:add_notifier(self,xStreamUI.update_active_button)



  -- handle models ----------------------------------------

  self.xstream.process.models.models_observable:add_notifier(function()
    TRACE("xStreamUI - models_observable fired...")
    self.build_models_requested = true
  end)

  local preset_bank_notifier = function()
    TRACE("xStreamUI - preset_bank_notifier fired...")
    self.presets:update_controls()
    self.favorites:update_bank_selector()
  end

  local preset_bank_index_notifier = function()
    TRACE("xStreamUI - model.selected_preset_bank_index_observable fired...")
    local presets_modified_notifier = function()
      TRACE("xStreamUI - presets_modified_notifier fired...")
      self.build_presets_requested = true
      self.favorites:update_preset_selector()
    end
    self.build_presets_requested = true
    self.update_presets_requested = true
    local preset_bank = self.xstream.selected_model.selected_preset_bank
    cObservable.attach(preset_bank.presets_observable,presets_modified_notifier)
    cObservable.attach(preset_bank.modified_observable,presets_modified_notifier)
    cObservable.attach(preset_bank.selected_preset_index_observable,function()    
      TRACE("xStreamUI - preset_bank.selected_preset_index_observable fired...")
      self.update_presets_requested = true
    end)
    cObservable.attach(preset_bank.name_observable,preset_bank_notifier)
  end

  local selected_model_index_notifier = function()
    TRACE("xStreamUI - selected_model_index_notifier fired...",self.xstream.selected_model_index)
    local model = self.xstream.selected_model
    if model then
      --print(">>> #model.args.args",#model.args.args)
      --print(">>> model.data_observable",model.data_observable)
      --print(">>> model.events_observable",model.events_observable)

      cObservable.attach(model.name_observable,function()
        TRACE("xStreamUI - model.name_observable fired...")
        self.build_models_requested = true
      end)
      cObservable.attach(model.modified_observable,function()
        TRACE("xStreamUI - model.modified_observable fired...")
        self.update_models_requested = true
      end)
      cObservable.attach(model.color_observable,function()    
        TRACE("xStreamUI - model.color_observable fired...")
        self.update_color_requested = true
      end)
      cObservable.attach(model.args.selected_index_observable,function()
        TRACE("xStreamUI - selected_arg_notifier fired...")
        self.update_args_requested = true
      end)
      cObservable.attach(model.args.args_observable,function(arg)
        TRACE("xStreamUI - args_observable_notifier fired...",rprint(arg))
        if (arg.type == "remove") then
          self.args_panel:purge_arg_views()
        end
        self.build_args_requested = true
      end)
      cObservable.attach(model.args.modified_observable,function()
        TRACE("xStreamUI - args_modified_notifier fired...")
        self.xstream.selected_model.modified = true
      end)
      cObservable.attach(model.data_observable,function()
        TRACE("xStreamUI - data_observable fired...")
        self.update_editor_requested = true
      end)
      cObservable.attach(model.events_observable,function()
        TRACE("xStreamUI - events_observable fired...")
        self.update_editor_requested = true
      end)
      cObservable.attach(model.sandbox.callback_str_observable,function()
        TRACE("xStreamUI - sandbox.callback_notifier fired...")
        if not self.user_modified_callback then
          self.update_editor_requested = true
        end
      end)
      cObservable.attach(model.preset_banks_observable,preset_bank_notifier)
      cObservable.attach(model.selected_preset_bank_index_observable,preset_bank_index_notifier)
      preset_bank_index_notifier()
      -- select first argument
      if (#model.args.args > 0) then
        model.args.selected_index = 1
      end
    end
    self.update_model_requested = true
    self.editor_view = "main"
    self.update_editor_requested = true

    if vPrompt.color_prompt.dialog and vPrompt.color_prompt.dialog.visible then
      vPrompt.prompt_for_color(color_callback,model.color)
    end

  end
  self.xstream.process.models.selected_model_index_observable:add_notifier(selected_model_index_notifier)
  self.vb_content = content

  selected_model_index_notifier()


  -- handle scheduled items -------------------------------

  self.xstream.process.scheduled_model_index_observable:add_notifier(function()    
    TRACE("xStreamUI - scheduled_model_index_observable fired...",self.xstream.scheduled_model_index)
    if self.scheduled_model_index then
      self:update_scheduled_model(self.scheduled_model_index,xStreamUI.SCHEDULE_TEXT.OFF)
    end
    if (self.xstream.scheduled_model_index == 0) then
      self.scheduled_model_index = nil
    else
      self.scheduled_model_index = self.xstream.scheduled_model_index
    end

  end)

  self.xstream.process.scheduled_preset_index_observable:add_notifier(function()    
    TRACE("xStreamUI - scheduled_preset_index_observable fired...",self.xstream.scheduled_preset_index)
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

  local model_names = self.xstream.process.models:get_names()

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
    vb:horizontal_aligner{
      mode = "justify",
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
          items = model_names,
          id = "xStreamModelSelector",
          width = xStreamUI.MODEL_SELECTOR_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(val)
            self.xstream.selected_model_index = val-1
          end
        },

        vb:button{
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
            self.create_model_dialog:show()
          end,
        },
        vb:button{
          bitmap = "./source/icons/reveal_folder.bmp",
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
        --[[
        vb:text{
          text = "Stack",
          font = "bold",
        },        
        vb:popup{
          items = {"A","B","C","D","E","F"},
          width = 50,
        },  
        ]]      
      }      
    },
    vb:multiline_textfield{
      text = "",
      font = "mono",
      height = 200,
      width = xStreamUI.CALLBACK_EDITOR_W, 
      id = "xStreamCallbackEditor",
      notifier = function(str)
        if self.suppress_editor_notifier then
          return
        end
        if self.xstream.selected_model then
          self.user_modified_callback = true
        end
      end,
    },
    vb:horizontal_aligner{
      id = "xStreamCallbackEditorToolbar",
      width = xStreamUI.CALLBACK_EDITOR_W, 
      mode = "justify",
      vb:row{
        vb:text{
          id = "xStreamCallbackStatus",
          text = "",
        }
      },
      vb:row{
        vb:text{
          text = "View",
        },
        vb:popup{
          id = "xStreamCallbackType",
          --items = {"main","data","note_on","note_off"},
          width = 120,
          notifier = function(idx)
            local vb_elm = vb.views["xStreamCallbackType"]
            self.editor_view = vb_elm.items[idx]
            self:set_editor_content()
          end,
        },
        vb:button{
          bitmap = "./source/icons/add.bmp",
          tooltip = "Create a new callback",
          id = "xStreamCallbackCreate",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.create_callback_dialog:show()
          end,
        },

        vb:button{
          bitmap = "./source/icons/rename.bmp",
          tooltip = "Rename the selected callback",
          id = "xStreamCallbackRename",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local passed,err = self:rename_callback()
            if err then
              renoise.app():show_warning(err)
            end
          end,
        },
        vb:button{
          bitmap = "./source/icons/delete_small.bmp",
          tooltip = "Delete the selected callback",
          id = "xStreamCallbackRemove",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self:remove_callback()
          end,
        },
        --[[
        vb:row{
          id = "xStreamModelEditorNumLinesContainer",
          tooltip = "Number of lines",
          vb:text{
            id = "xStreamEditorNumLinesTitle",
            text = "Lines",
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
        ]]
      },
    },
  }

end

--------------------------------------------------------------------------------
-- update editor with the relevant callback 

function xStreamUI:set_editor_content()
  TRACE("xStreamUI:set_editor_content()")

  local text = nil
  local model = self.xstream.selected_model
  local vb = self.vb

  local vb_remove = vb.views["xStreamCallbackRemove"]
  local vb_rename = vb.views["xStreamCallbackRename"]
  --local vb_create = vb.views["xStreamCallbackCreate"]

  if not model then
    text = xStreamUI.WELCOME_MSG
  else
    local cb_type,cb_key,cb_subtype_or_tab,cb_arg_name = 
      xStream.parse_callback_type(self.editor_view)
    if (cb_type == "main") then
      text = model.sandbox.callback_str 
      vb_rename.active = false
      vb_remove.active = false
    elseif (cb_type == "data") then
      text = model.data_initial[cb_key]
      vb_rename.active = true
      vb_remove.active = true
    elseif (cb_type == "events") then
      -- when argument, we can have four parts
      local cb_name = cb_arg_name and cb_subtype_or_tab.."."..cb_arg_name or cb_subtype_or_tab
      text = model.events[cb_key.."."..cb_name]
      vb_rename.active = false
      vb_remove.active = true
    end
  end

  --rprint(text)

  -- prevent notifier from firing
  local view = self.vb.views["xStreamCallbackEditor"]
  self.suppress_editor_notifier = true
  view.text = text --cString.trim(text).."\n"
  self.suppress_editor_notifier = false

end

--------------------------------------------------------------------------------
-- apply editor text to the relevant callback/data/event

function xStreamUI:apply_editor_content()
  TRACE("xStreamUI:apply_editor_content()")

  local model = self.xstream.selected_model
  if model then
    --print("xStreamUI:on_idle - callback modified")
    local view = self.vb.views["xStreamCallbackEditor"]
    local cb_type,cb_key,cb_subtype_or_tab,cb_arg_name = xStream.parse_callback_type(self.editor_view)
    local trimmed_text = cString.trim(view.text)
    local status_obs = self.xstream.process.buffer.callback_status_observable
    if (cb_type == "main") then
      model.callback_str = trimmed_text
    elseif (cb_type == "data") then
      local def = table.rcopy(model.data_initial)
      def[cb_key] = trimmed_text
      local str_status = model:parse_userdata(def)
      --print("str_status",str_status)
      status_obs.value = str_status
    elseif (cb_type == "events") then
      local def = table.rcopy(model.events)
      local cb_name = cb_arg_name and cb_subtype_or_tab.."."..cb_arg_name or cb_subtype_or_tab
      def[cb_key.."."..cb_name] = trimmed_text
      --print("apply content",cb_key.."."..cb_name)
      local str_status = model:parse_events(def)
      status_obs.value = str_status
    end
    model.modified = true

  end

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
  self.args_panel.disabled = true
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
  self.args_panel.disabled = false

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

  --[[
  self.vb.views["xStreamModelEditorNumLinesContainer"].visible = val
  ]]
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
  self.update_editor_requested = true
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

function xStreamUI:get_compact_mode()
  return self.compact_mode_observable.value
end

function xStreamUI:set_compact_mode(val)
  self.compact_mode_observable.value = val
  local panel = self.vb.views["xStreamLowerPanels"]
  if panel then 
    panel.visible = not val
  end 
  local toggle_bt = self.vb.views["xStreamToggleCompactMode"]
  local selector = self.vb.views["xStreamCompactModelSelector"]
  local logo = self.vb.views["xStreamLogo"]

  selector.visible = false
  logo.visible = false

  toggle_bt.text = val and "+" or "-"
  selector.visible = val
  logo.visible = not val


end

--------------------------------------------------------------------------------

function xStreamUI:delete_model()

  local choice = renoise.app():show_prompt("Delete model",
      "Are you sure you want to delete this model \n"
    .."(this action can not be undone)?",
    {"OK","Cancel"})
  
  if (choice == "OK") then
    local model_idx = self.xstream.selected_model_index
    local success,err = self.xstream.process.models:delete_model(model_idx)
    if not success then
      renoise.app():show_error(err)
    end
  end

end

--------------------------------------------------------------------------------

function xStreamUI:delete_callback()

  local choice = renoise.app():show_prompt("Delete callback",
      "Are you sure you want to delete this callback",{"OK","Cancel"})
  
  if (choice == "OK") then
    -- TODO
  end

end

--------------------------------------------------------------------------------

function xStreamUI:rename_callback(new_name)
  TRACE("xStreamUI:rename_callback(new_name)",new_name)

  local model = self.xstream.selected_model
  if not model then
    return
  end

  local cb_type,cb_key,cb_subtype = xStream.parse_callback_type(self.editor_view)

  if (cb_type ~= xStreamModel.CB_TYPE.DATA) then
    return
  end

  if not new_name then
    new_name = vPrompt.prompt_for_string(cb_subtype or cb_key,
      "Enter a new name","Rename callback")
    if not new_name then
      return true
    end
  end

  -- events contain two parts
  local old_name = cb_subtype and cb_key.."."..cb_subtype or cb_key

  local passed,err = model:rename_callback(old_name,new_name,cb_type)
  if not passed then
    return false,err
  end

  self.editor_view = cb_type.."."..new_name
  --print(">>> self.editor_view",self.editor_view)
  self.user_modified_callback = true


end

--------------------------------------------------------------------------------

function xStreamUI:remove_callback()
  TRACE("xStreamUI:remove_callback()")

  local model = self.xstream.selected_model
  if not model then
    return
  end

  local choice = renoise.app():show_prompt("Remove callback",
      "Are you sure you want to remove this callback?",
    {"OK","Cancel"})
  
  if (choice == "OK") then
    local cb_type,cb_key,cb_subtype = xStream.parse_callback_type(self.editor_view)
    model:remove_callback(cb_type,cb_subtype and cb_key.."."..cb_subtype or cb_key)
    self.update_editor_requested = true
  end

end

--------------------------------------------------------------------------------

function xStreamUI:attach_to_song()

  cObservable.attach(rns.transport.playing_observable,self,xStreamUI.update_play_button)

end

--------------------------------------------------------------------------------
-- only called while visible
 
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
    self:apply_editor_content()
    self.user_modified_callback = false
  end

  -- delayed display updates ------------------------------

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
    self.args_panel:build_args()
  end

  if self.update_args_requested then
    self.update_args_requested = false
    self.args_panel:update()
    self.args_editor:update()
    self.args_panel:update_selector()
    self.args_panel:update_controls()
    self.args_panel:update_visibility()
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

  if self.update_editor_requested then
    self.update_editor_requested = false
    self:update_editor()
  end


end

