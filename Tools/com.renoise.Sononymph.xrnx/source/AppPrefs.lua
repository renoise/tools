class 'AppPrefs'(renoise.Document.DocumentNode)

---------------------------------------------------------------------------------------------------
-- constructor, initialize with default values

function AppPrefs:__init()

  renoise.Document.DocumentNode.__init(self)

  self:add_property("autostart", renoise.Document.ObservableBoolean(false))
  self:add_property("polling_interval", renoise.Document.ObservableNumber(1))
  self:add_property("path_to_exe", renoise.Document.ObservableString(""))
  self:add_property("path_to_config", renoise.Document.ObservableString(""))
  self:add_property("show_transfer_warning", renoise.Document.ObservableBoolean(true))
  self:add_property("show_search_warning", renoise.Document.ObservableBoolean(true))
  self:add_property("show_prefs", renoise.Document.ObservableBoolean(true))
  
end

