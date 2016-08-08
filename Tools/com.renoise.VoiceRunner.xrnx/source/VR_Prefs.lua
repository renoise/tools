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
  self:add_property("safe_mode", renoise.Document.ObservableBoolean(true))
  self:add_property("hide_too_many_cols_warning", renoise.Document.ObservableBoolean(false))
  self:add_property("select_all_columns", renoise.Document.ObservableBoolean(false))
  self:add_property("toggle_line_selection", renoise.Document.ObservableBoolean(false))
  --self:add_property("maintain_selected_columns", renoise.Document.ObservableBoolean(true))
  

  -- xVoiceSorter
  self:add_property("sort_mode", renoise.Document.ObservableNumber(xVoiceSorter.SORT_MODE.LOW_TO_HIGH))
  self:add_property("sort_method", renoise.Document.ObservableNumber(xVoiceSorter.SORT_METHOD.NORMAL))
  self:add_property("merge_unique", renoise.Document.ObservableBoolean(false))
  self:add_property("unique_instrument", renoise.Document.ObservableBoolean(true))

  -- xVoiceRunner
  self:add_property("split_at_note", renoise.Document.ObservableBoolean(false))
  self:add_property("split_at_note_change", renoise.Document.ObservableBoolean(true))
  self:add_property("split_at_instrument_change", renoise.Document.ObservableBoolean(false))
  self:add_property("link_ghost_notes", renoise.Document.ObservableBoolean(true))
  self:add_property("link_glide_notes", renoise.Document.ObservableBoolean(true))
  self:add_property("stop_at_note_off", renoise.Document.ObservableBoolean(true))
  self:add_property("stop_at_note_cut", renoise.Document.ObservableBoolean(true))
  self:add_property("remove_orphans", renoise.Document.ObservableBoolean(true))
  self:add_property("create_noteoffs", renoise.Document.ObservableBoolean(true))
  self:add_property("close_open_notes", renoise.Document.ObservableBoolean(true))
  self:add_property("reveal_subcolumns", renoise.Document.ObservableBoolean(true))

  self:reset()

end

-------------------------------------------------------------------------------

function VR_Prefs:reset()

  self.selected_scope.value = 1
  --self.advanced_settings.value = false
  --self.autostart.value = false
  self.safe_mode.value = true
  self.hide_too_many_cols_warning.value = false

  -- xVoiceSorter
  self.sort_mode.value = xVoiceSorter.SORT_MODE.LOW_TO_HIGH
  self.sort_method.value = xVoiceSorter.SORT_METHOD.NORMAL
  self.merge_unique.value = false
  self.unique_instrument.value = true

  -- xVoiceRunner
  self.split_at_note.value = false
  self.split_at_note_change.value = true
  self.split_at_instrument_change.value = false
  self.stop_at_note_off.value = true
  self.stop_at_note_cut.value = true
  self.remove_orphans.value = true
  self.create_noteoffs.value = true
  self.close_open_notes.value = true
  self.reveal_subcolumns.value = true

end

