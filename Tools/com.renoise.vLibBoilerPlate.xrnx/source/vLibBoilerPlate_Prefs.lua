--[[===============================================================================================
vLibBoilerPlate
===============================================================================================]]--

--[[

Preferences for vLibBoilerPlate. Having it as a class means that we can e.g. add 
methods like "reset to factory defaults" or "export to file" (none of which
are present in this barebones example). 

There isn't really a "cost to having it as a class, you can still reference
preferences in the usual manner (hint: this reference is set up in main.lua)

]]

--=================================================================================================

class 'vLibBoilerPlate_Prefs'(renoise.Document.DocumentNode)

function vLibBoilerPlate_Prefs:__init()

  renoise.Document.DocumentNode.__init(self)
  self:add_property("autostart", renoise.Document.ObservableBoolean(true))

end

