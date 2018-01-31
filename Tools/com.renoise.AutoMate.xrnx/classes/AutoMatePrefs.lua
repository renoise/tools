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

  -- settings
  self:add_property("autorun_enabled",    
    renoise.Document.ObservableBoolean(true))
  self:add_property("selected_tab",    
    renoise.Document.ObservableNumber(AutoMatePrefs.TAB_DEVICES))
  self:add_property("show_options",    
    renoise.Document.ObservableBoolean(false))
    self:add_property("selected_scope",    
    renoise.Document.ObservableNumber(xParameterAutomation.SCOPE.WHOLE_SONG))
    self:add_property("yield_at",    
    renoise.Document.ObservableNumber(xAudioDeviceAutomation.YIELD_AT.NONE))
    

end


