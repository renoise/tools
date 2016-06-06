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

