--[[============================================================================
MP_Prefs
============================================================================]]--

--[[

Preferences for MidiPerformer

TODO autoshow

]]

--==============================================================================

class 'MP_Prefs'(renoise.Document.DocumentNode)

function MP_Prefs:__init()

  renoise.Document.DocumentNode.__init(self)
  self:add_property("autostart", renoise.Document.ObservableBoolean(true))
  self:add_property("autoshow", renoise.Document.ObservableBoolean(true))
  self:add_property("autofix_track_assignments", renoise.Document.ObservableBoolean(true))
  self:add_property("autoarm_on_edit_enable", renoise.Document.ObservableBoolean(true))
  self:add_property("disable_when_track_silent", renoise.Document.ObservableBoolean(true))
  self:add_property("disable_when_track_muted", renoise.Document.ObservableBoolean(true))
  self:reset()

end

-------------------------------------------------------------------------------

function MP_Prefs:reset()

  self.autostart.value = true
  self.autoshow.value = true
  self.autofix_track_assignments.value = false
  self.autoarm_on_edit_enable.value = false
  self.disable_when_track_silent.value = true
  self.disable_when_track_muted.value = true

end

