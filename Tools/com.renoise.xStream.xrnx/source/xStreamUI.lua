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
xStreamUI.COLOR_BASE = {0x30,0x34,0x32}

-- disable along with model
xStreamUI.MODEL_CONTROLS = {
  "xStreamApplyLineButton",
  "xStreamApplyLineLocallyButton",
  "xStreamApplySelectionButton",
  "xStreamApplySelectionLocallyButton",
  "xStreamApplyTrackButton",
  "xStreamApplyTrackButton",
  "xStreamFavoriteModel",
  "xStreamModelColorPreview",
  "xStreamModelRefresh",
  "xStreamModelRemove",
  "xStreamModelRename",
  "xStreamPresetRename",
  "xStreamModelSave",
  "xStreamModelSaveAs",
  "xStreamMuteButton",
  "xStreamRevealLocation",
  "xStreamStartPlayButton",
  "xStreamStopButton",
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
xStreamUI.BITMAP_BUTTON_H = 20
xStreamUI.PRESET_PANEL_W = 196
xStreamUI.ARGS_PANEL_W = 256
xStreamUI.FULL_PANEL_W = xStreamUILuaEditor.EDITOR_W 
xStreamUI.TRANSPORT_BUTTON_W = 28
xStreamUI.MODEL_SELECTOR_W = 145
xStreamUI.FLASH_TIME = 0.2
xStreamUI.MAX_BRIGHT_COLOR = 1
xStreamUI.BRIGHTEN_AMOUNT = 0.9
xStreamUI.HIGHLIGHT_AMOUNT = 0.66
xStreamUI.DIMMED_AMOUNT = 0.40
xStreamUI.SELECTED_COLOR = 0.20
xStreamUI.EDIT_RACK_MARGIN = 40
xStreamUI.SMALL_VERTICAL_MARGIN = 6
xStreamUI.MIN_SPACING = -3

xStreamUI.ARGS_MIN_VALUE = -99999
xStreamUI.ARGS_MAX_VALUE = 99999

xStreamUI.ICON_COMPACT = "./source/icons/minimize.bmp"
xStreamUI.ICON_EXPANDED = "./source/icons/maximize.bmp"

xStreamUI.DEFAULT_PALETTE = {
  {0x60,0xAA,0xCA},{0x9E,0xD6,0x8C},{0xCA,0x87,0x59},{0xC9,0xB3,0x6D},
  {0x50,0x55,0x52},{0x69,0x99,0x7a},{0xa5,0x4a,0x24},{0x93,0x58,0x75},
}

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
  self.global_toolbar = xStreamUIGlobalToolbar(self.xstream,self.vb)
  self.model_toolbar = xStreamUIModelToolbar(self.xstream,self.vb)
  self.presets = xStreamUIPresetPanel(self.xstream,self.vb,self)
  self.args_panel  = xStreamUIArgsPanel(self.xstream,self.midi_prefix,self.vb,self)
  self.args_editor = xStreamUIArgsEditor(self.xstream,self.vb)
  self.lua_editor = xStreamUILuaEditor(self.xstream,self.vb)

  -- dialogs
  --self.options = xStreamUIOptions(self.xstream)
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


  self.compact_mode = property(self.get_compact_mode,self.set_compact_mode)
  self.compact_mode_observable = renoise.Document.ObservableBoolean(false)

  self.model_browser_visible = property(self.get_model_browser_visible,self.set_model_browser_visible)
  self.model_browser_visible_observable = renoise.Document.ObservableBoolean(false)

  -- bool, set when user has changed one of the callbacks
  self.user_modified_callback = false

  --== notifiers ==--

  self.show_editor_observable:add_notifier(function()
    TRACE("xStreamUI - self.show_editor_observable fired...")
    self.prefs.show_editor.value = self.show_editor_observable.value
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

  self.model_toolbar:update_color()
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

function xStreamUI:update_model_selector()
  TRACE("xStreamUI:update_model_selector()")

  local model_names = self.xstream.process.models:get_names()
  table.insert(model_names,1,xStreamUI.NO_MODEL_SELECTED)
  local view_popup = self.vb.views["xStreamModelSelector"] -- in model_toolbar
  local view_compact_popup = self.vb.views["xStreamCompactModelSelector"]

  local selector_value = (self.xstream.selected_model_index == 0) 
      and 1 or self.xstream.selected_model_index+1

  view_popup.items = model_names
  view_popup.value = selector_value
  view_compact_popup.items = model_names
  view_compact_popup.value = selector_value

  self.favorites:update_model_selector(model_names)
  self.global_toolbar.options:update_model_selector(model_names)

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

  local view_global_toolbar = self.global_toolbar:build()
  local view_model_toolbar = self.model_toolbar:build()
  local view_lua_editor = self.lua_editor:build()
  local view_presets_panel = self.presets:build_panel()
  local view_args_panel = self.args_panel:build()

  local content = vb:column{
    id = "xStreamPanel",
    view_global_toolbar,
    vb:row{ -- callback, lower panels
      id = "xStreamLowerPanels",
      style = "body",
      vb:column{
        id = "xStreamMiddlePanel",
        vb:column{
          style = "panel",
          view_model_toolbar,
          view_lua_editor,
        },
        vb:row{ -- xStreamLowerPanelsRack
          id = "xStreamLowerPanelsRack",
          view_presets_panel,
          view_args_panel,
        },
      },
    },
  }
  

  -- avoid 'flashing' on startup as textfield does not
  -- become inactive right away, only once model is set...
  self.lua_editor.active = false


  -- add notifier methods ---------------------------------


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
    self.lua_editor.editor_view = "main"
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

function xStreamUI:disable_model_controls()
  TRACE("xStreamUI:disable_model_controls()")

  self.lua_editor.active = false

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

  self.lua_editor.active = true

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

  local view_expand = self.vb.views["xStreamToggleExpand"]
  view_expand.text = val and xStreamUI.ARROW_UP or xStreamUI.ARROW_DOWN

  local view_lines_container = self.vb.views["xStreamModelEditorNumLinesContainer"]
  view_lines_container.visible = val

  self.lua_editor.visible = val

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
  local selector = self.global_toolbar.vb.views["xStreamCompactModelSelector"]
  local logo = self.vb.views["xStreamLogo"] -- global toolbar

  selector.visible = false
  logo.visible = false

  toggle_bt.text = val and "▾" or "▴"
  selector.visible = val
  logo.visible = not val

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
    self.lua_editor:apply_editor_content()
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
    self.model_toolbar:update_color()
  end

  if self.build_args_requested then
    self.build_args_requested = false
    self.update_args_requested = true
    self.args_panel:build_args()
  end

  if self.update_args_requested then
    self.update_args_requested = false
    self.args_panel:update_all()
    self.args_editor:update()
  end

  if self.update_models_requested then
    self.update_models_requested = false
    self.model_toolbar:update()
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
    self.model_toolbar:update_color()
  end

  if self.update_editor_requested then
    self.update_editor_requested = false
    self.lua_editor:update()
  end


end

