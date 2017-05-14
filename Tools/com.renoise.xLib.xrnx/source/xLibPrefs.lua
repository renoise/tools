--[[============================================================================
xLibPrefs
============================================================================]]--

class 'xLibPrefs'(renoise.Document.DocumentNode)

function xLibPrefs:__init()

  renoise.Document.DocumentNode.__init(self)
  self:add_property("autostart", renoise.Document.ObservableBoolean(true))

end

