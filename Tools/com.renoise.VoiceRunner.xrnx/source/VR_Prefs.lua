--[[============================================================================
VoiceRunner
============================================================================]]--

--[[

Preferences for VoiceRunner

]]

--==============================================================================

class 'VR_Prefs'(renoise.Document.DocumentNode)



-------------------------------------------------------------------------------
-- constructor, initialize with default values

function VR_Prefs:__init()

  renoise.Document.DocumentNode.__init(self)

  self:add_property("selected_scope", renoise.Document.ObservableNumber(1))
  self:add_property("advanced_settings", renoise.Document.ObservableBoolean(false))
  self:add_property("selected_template", renoise.Document.ObservableString(""))
  self:add_property("autostart", renoise.Document.ObservableBoolean(false))
  self:add_property("compact_columns", renoise.Document.ObservableBoolean(true))
  self:add_property("update_visible_columns", renoise.Document.ObservableBoolean(true))
  self:add_property("sort_mode", renoise.Document.ObservableNumber(xVoiceSorter.SORT_MODE.LOW_TO_HIGH))
  self:add_property("split_at_note", renoise.Document.ObservableBoolean(true))
  self:add_property("split_at_instrument", renoise.Document.ObservableBoolean(true))
  self:add_property("stop_at_note_off", renoise.Document.ObservableBoolean(false))

  self:add_property("user_folder", renoise.Document.ObservableString(VR.USER_FOLDER))
  self:add_property("source_instr", renoise.Document.ObservableNumber(VR.SOURCE_INSTR.CAPTURE_ONCE))
  self:add_property("monitor_recording", renoise.Document.ObservableBoolean(false))
  self:add_property("remap_instruments", renoise.Document.ObservableNumber(VR.INSTR_REMAP_MODE.CAPTURE_ONCE))


end


