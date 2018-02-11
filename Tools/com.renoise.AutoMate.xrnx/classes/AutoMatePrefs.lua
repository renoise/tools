--[[===============================================================================================
-- AutoMatePrefs.lua
===============================================================================================]]--

--[[--

# AutoMatePrefs

--]]


--=================================================================================================

class 'AutoMatePrefs'(renoise.Document.DocumentNode)

AutoMatePrefs.TAB_DEVICES = 1
AutoMatePrefs.TAB_PARAMETERS = 2
AutoMatePrefs.TAB_OPTIONS = 3

function AutoMatePrefs:__init()

  renoise.Document.DocumentNode.__init(self)

  -- general options 
  self:add_property("autorun_enabled",    
    renoise.Document.ObservableBoolean(true))

  -- user interface 
  self:add_property("selected_tab",    
    renoise.Document.ObservableNumber(AutoMatePrefs.TAB_PARAMETERS))
  self:add_property("selected_scope",    
    renoise.Document.ObservableNumber(AutoMate.SCOPE.WHOLE_PATTERN))

  -- advanced
  self:add_property("yield_at",    
    renoise.Document.ObservableNumber(xLib.YIELD_AT.NONE))
    
  -- library 
  self:add_property("show_in_library",
    renoise.Document.ObservableNumber(AutoMateLibraryUI.SHOW_IN_LIBRARY.ALL))

  -- generators 
  self:add_property("realtime_generate",
    renoise.Document.ObservableBoolean(false))

  -- transformers 
  self:add_property("realtime_transform",
    renoise.Document.ObservableBoolean(false))


end


