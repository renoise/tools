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

  -- tool
  self:add_property("selected_scope", renoise.Document.ObservableNumber(1))
  self:add_property("advanced_settings", renoise.Document.ObservableBoolean(false))
  self:add_property("autostart", renoise.Document.ObservableBoolean(false))

  -- xVoiceSorter
  self:add_property("sort_mode", renoise.Document.ObservableNumber(xVoiceSorter.SORT_MODE.LOW_TO_HIGH))

  -- xVoiceRunner
  self:add_property("split_at_note", renoise.Document.ObservableBoolean(true))
  self:add_property("split_at_note_change", renoise.Document.ObservableBoolean(true))
  self:add_property("split_at_instrument_change", renoise.Document.ObservableBoolean(true))
  self:add_property("stop_at_note_off", renoise.Document.ObservableBoolean(false))
  self:add_property("stop_at_note_cut", renoise.Document.ObservableBoolean(false))
  self:add_property("remove_orphans", renoise.Document.ObservableBoolean(false))

end


