--[[============================================================================
ScaleMate_Prefs
============================================================================]]--
--[[

Preferences for ScaleMate

]]

--==============================================================================

class 'ScaleMate_Prefs'(renoise.Document.DocumentNode)

function ScaleMate_Prefs:__init()

  renoise.Document.DocumentNode.__init(self)
  self:add_property("write_to_pattern", renoise.Document.ObservableBoolean(true))

end

