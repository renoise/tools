--[[============================================================================
SliceMate
============================================================================]]--

--[[

Preferences for SliceMate

]]

--==============================================================================

class 'SliceMate_Prefs'(renoise.Document.DocumentNode)

SliceMate_Prefs.QUANTIZE_AMOUNT = {  
  LINE = 1, 
  BEAT = 2,
  BAR = 3,
  BLOCK = 4,
  PATTERN = 5,
}
SliceMate_Prefs.QUANTIZE_LABELS = {  
  "Line",
  "Beat",
  "Bar",
  "Block",
  "Pattern",
}

SliceMate_Prefs.LIMIT_FILL = {  
  SONG = 1,
  PATTERN = 2,
  SEQUENCE_SELECTION = 3,
  PATTERN_SELECTION = 4,
}
SliceMate_Prefs.LIMIT_FILL_LABELS = {  
  "Whole Song",
  "Whole Pattern",
  "Selection in Sequence",
  "Selection in Pattern",
}


SliceMate_Prefs.SLICE_NAV_MODE = {  
  QUANTIZE = 1,
  SLICE = 2,
  FRAMES = 3,
}

function SliceMate_Prefs:__init()

  renoise.Document.DocumentNode.__init(self)
  -- tool options
  self:add_property("autostart", renoise.Document.ObservableBoolean(true))
  self:add_property("suspend_while_hidden", renoise.Document.ObservableBoolean(true))
  -- slice settings
  self:add_property("autoselect_instr", renoise.Document.ObservableBoolean(true))
  self:add_property("autoselect_in_wave", renoise.Document.ObservableBoolean(true))
  self:add_property("autoselect_in_list", renoise.Document.ObservableBoolean(true))
  self:add_property("autofix_instr", renoise.Document.ObservableBoolean(false))
  self:add_property("quantize_enabled", renoise.Document.ObservableBoolean(false))
  self:add_property("quantize_amount", renoise.Document.ObservableNumber(SliceMate_Prefs.QUANTIZE_AMOUNT.BEAT))
  self:add_property("insert_note", renoise.Document.ObservableBoolean(true))
  self:add_property("propagate_vol_pan", renoise.Document.ObservableBoolean(true))
  self:add_property("support_phrases", renoise.Document.ObservableBoolean(true))
  self:add_property("limit_fill", renoise.Document.ObservableNumber(SliceMate_Prefs.LIMIT_FILL.SONG))
  -- remember UI state
  --self:add_property("show_tool_options", renoise.Document.ObservableBoolean(false))
  self:add_property("show_options", renoise.Document.ObservableBoolean(false))
  
  self:reset()

end

-------------------------------------------------------------------------------

function SliceMate_Prefs:reset()

  self.autostart.value = true

end

