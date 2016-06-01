--[[============================================================================
-- xStreamPrefs
============================================================================]]--

--[[

  This is a supporting class for xStream

]]

--==============================================================================

class 'xStreamPrefs'(renoise.Document.DocumentNode)

xStreamPrefs.USER_FOLDER = renoise.tool().bundle_path .. "/userdata/"
xStreamPrefs.VISIBLE_CODE_LINES = 16
xStreamPrefs.WRITEAHEAD = 175

xStreamPrefs.START_OPTIONS = {"Manual control","Auto - Play","Auto - Play+Edit"}
xStreamPrefs.START_OPTION = {
  MANUAL = 1,
  ON_PLAY = 2,
  ON_PLAY_EDIT = 3,
}


-------------------------------------------------------------------------------
-- constructor, initialize with default values

function xStreamPrefs:__init()

  renoise.Document.DocumentNode.__init(self)

  -- general
  self:add_property("autostart", renoise.Document.ObservableBoolean(false))
  self:add_property("launch_model", renoise.Document.ObservableString(""))
  self:add_property("launch_selected_model", renoise.Document.ObservableBoolean(true))
  self:add_property("user_folder", renoise.Document.ObservableString(xStreamPrefs.USER_FOLDER))

  -- input
  self:add_property("midi_multibyte_enabled", renoise.Document.ObservableBoolean(false))
  self:add_property("midi_nrpn_enabled", renoise.Document.ObservableBoolean(false))
  self:add_property("midi_terminate_nrpns", renoise.Document.ObservableBoolean(false))
  self:add_property("midi_inputs", renoise.Document.ObservableStringList())
  self:add_property("midi_outputs", renoise.Document.ObservableStringList())


  -- user interface
  self:add_property("live_coding", renoise.Document.ObservableBoolean(true))
  self:add_property("editor_visible_lines", renoise.Document.ObservableNumber(xStreamPrefs.VISIBLE_CODE_LINES))
  self:add_property("favorites_pinned", renoise.Document.ObservableBoolean(false))
  self:add_property("model_args_visible", renoise.Document.ObservableBoolean(false))
  self:add_property("model_browser_visible", renoise.Document.ObservableBoolean(false))
  self:add_property("presets_visible", renoise.Document.ObservableBoolean(false))
  self:add_property("show_editor", renoise.Document.ObservableBoolean(true))
  self:add_property("tool_options_visible", renoise.Document.ObservableBoolean(false))

  -- streaming
  self:add_property("suspend_when_hidden", renoise.Document.ObservableBoolean(true))
  self:add_property("start_option", renoise.Document.ObservableNumber(xStreamPrefs.START_OPTION.ON_PLAY_EDIT))
  self:add_property("scheduling", renoise.Document.ObservableNumber(xStream.SCHEDULE.BEAT))
  self:add_property("mute_mode", renoise.Document.ObservableNumber(xStream.MUTE_MODE.OFF))
  self:add_property("writeahead_factor", renoise.Document.ObservableNumber(xStreamPrefs.WRITEAHEAD))

  -- output
  self:add_property("automation_playmode", renoise.Document.ObservableNumber(xStream.PLAYMODE.POINTS))
  self:add_property("include_hidden", renoise.Document.ObservableBoolean(false))
  self:add_property("clear_undefined", renoise.Document.ObservableBoolean(true))
  self:add_property("expand_columns", renoise.Document.ObservableBoolean(true))

end

-------------------------------------------------------------------------------
-- apply application settings + attach notifiers

function xStreamPrefs:apply(xstream)

  -- ui options
  xstream.ui.show_editor = self.show_editor.value
  xstream.ui.args.visible = self.model_args_visible.value
  xstream.ui.presets.visible = self.presets_visible.value
  xstream.ui.favorites.pinned = self.favorites_pinned.value
  xstream.ui.editor_visible_lines = self.editor_visible_lines.value

  -- streaming options
  xstream.scheduling = self.scheduling.value
  xstream.mute_mode = self.mute_mode.value
  xstream.suspend_when_hidden = self.suspend_when_hidden.value
  xstream.writeahead_factor = self.writeahead_factor.value

  -- output outputs
  xstream.automation_playmode = self.automation_playmode.value
  xstream.include_hidden = self.include_hidden.value
  xstream.clear_undefined = self.clear_undefined.value
  xstream.expand_columns = self.expand_columns.value

  -- prefs --> application 

  self.scheduling:add_notifier(function()
    TRACE("*** xStreamUI - xstream.scheduling fired...")
    xstream.scheduling_observable.value = self.scheduling.value
  end)

  -- application --> prefs

  xstream.automation_playmode_observable:add_notifier(function()
    TRACE("*** main.lua - xstream.automation_playmode_observable fired...")
    self.automation_playmode.value = xstream.automation_playmode_observable.value
  end)

  xstream.writeahead_factor_observable:add_notifier(function()
    TRACE("*** main.lua - xstream.writeahead_factor_observable fired...")
    self.writeahead_factor.value = xstream.writeahead_factor_observable.value
  end)

  xstream.include_hidden_observable:add_notifier(function()
    TRACE("*** main.lua - xstream.include_hidden_observable fired...")
    self.include_hidden.value = xstream.include_hidden_observable.value
  end)

  xstream.clear_undefined_observable:add_notifier(function()
    TRACE("*** main.lua - xstream.clear_undefined_observable fired...")
    self.clear_undefined.value = xstream.clear_undefined_observable.value
  end)

  xstream.expand_columns_observable:add_notifier(function()
    TRACE("*** main.lua - xstream.expand_columns_observable fired...")
    self.expand_columns.value = xstream.expand_columns_observable.value
  end)

  xstream.active_observable:add_notifier(function()
    TRACE("*** main.lua - xstream.active_observable fired...")
    register_tool_menu()
  end)

  xstream.mute_mode_observable:add_notifier(function()
    TRACE("*** xStreamUI - xstream.mute_mode_observable fired...")
    self.mute_mode.value = xstream.mute_mode_observable.value
  end)

  xstream.ui.show_editor_observable:add_notifier(function()
    TRACE("*** xStreamUI - xstream.ui.show_editor_observable fired...")
    self.show_editor.value = xstream.ui.show_editor_observable.value
  end)

  xstream.ui.tool_options_visible_observable:add_notifier(function()
    TRACE("*** xStreamUI - xstream.ui.tool_options_visible_observable fired...")
    self.tool_options_visible.value = xstream.ui.tool_options_visible_observable.value
  end)

  xstream.ui.model_browser_visible_observable:add_notifier(function()
    TRACE("*** xStreamUI - xstream.ui.model_browser_visible_observable fired...")
    self.model_browser_visible.value = xstream.ui.model_browser_visible
  end)

  xstream.ui.args.visible_observable:add_notifier(function()
    TRACE("*** xStreamUI - xstream.ui.args.visible_observable fired...")
    self.model_args_visible.value = xstream.ui.args.visible
  end)

  xstream.ui.presets.visible_observable:add_notifier(function()
    TRACE("*** xStreamUI - xstream.ui.presets.visible_observable fired...")
    self.presets_visible.value = xstream.ui.presets.visible
  end)

  xstream.ui.favorites.pinned_observable:add_notifier(function()
    TRACE("*** xStreamUI - xstream.ui.favorites.pinned_observable fired...")
    self.favorites_pinned.value = xstream.ui.favorites.pinned
  end)

  xstream.ui.editor_visible_lines_observable:add_notifier(function()
    TRACE("*** xStreamUI - xstream.ui.editor_visible_lines_observable fired...")
    self.editor_visible_lines.value = xstream.ui.editor_visible_lines
  end)

end

