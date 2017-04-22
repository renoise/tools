--[[============================================================================
SliceMate
============================================================================]]--

--[[

Preferences for SliceMate

]]

--==============================================================================

class 'SliceMate_Prefs'(renoise.Document.DocumentNode)

function SliceMate_Prefs:__init()

  renoise.Document.DocumentNode.__init(self)
  self:add_property("autostart", renoise.Document.ObservableBoolean(true))
  self:add_property("show_on_launch", renoise.Document.ObservableBoolean(true))

  self:add_property("autoselect_instr", renoise.Document.ObservableBoolean(true))
  self:add_property("autoselect_in_wave", renoise.Document.ObservableBoolean(true))
  self:add_property("autoselect_in_list", renoise.Document.ObservableBoolean(true))
  self:add_property("quantize_enabled", renoise.Document.ObservableBoolean(false))
  self:add_property("insert_note", renoise.Document.ObservableBoolean(true))
  self:add_property("propagate_vol_pan", renoise.Document.ObservableBoolean(true))
  self:add_property("note", renoise.Document.ObservableBoolean(true))
  self:add_property("instrument", renoise.Document.ObservableBoolean(true))
  self:add_property("volume", renoise.Document.ObservableBoolean(false))
  self:add_property("panning", renoise.Document.ObservableBoolean(false))
  self:add_property("delay", renoise.Document.ObservableBoolean(false))
  self:add_property("match_all_criteria", renoise.Document.ObservableBoolean(true))
  self:add_property("show_tool_options", renoise.Document.ObservableBoolean(false))
  self:add_property("show_slice_options", renoise.Document.ObservableBoolean(false))
  
  self:reset()

end

-------------------------------------------------------------------------------

function SliceMate_Prefs:reset()

  self.autostart.value = true

end

