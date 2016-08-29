--[[============================================================================
-- PhraseMatePrefs
============================================================================]]--

--[[--

PhraseMate (preferences)

--]]


--==============================================================================

class 'PhraseMatePrefs'(renoise.Document.DocumentNode)

function PhraseMatePrefs:__init()

  renoise.Document.DocumentNode.__init(self)

  -- tool options
  self:add_property("active_tab_index",renoise.Document.ObservableNumber(PhraseMate.UI_TABS.INPUT))
  self:add_property("autostart", renoise.Document.ObservableBoolean(true))
  self:add_property("output_show_collection_report", renoise.Document.ObservableBoolean(true))

  -- read (collection) options
  self:add_property("input_scope", renoise.Document.ObservableNumber(PhraseMate.INPUT_SCOPE.SELECTION_IN_PATTERN))
  self:add_property("input_include_empty_phrases", renoise.Document.ObservableBoolean(true))
  self:add_property("input_include_duplicate_phrases", renoise.Document.ObservableBoolean(true))
  self:add_property("input_replace_collected", renoise.Document.ObservableBoolean(false))
  self:add_property("input_source_instr", renoise.Document.ObservableNumber(PhraseMate.SOURCE_INSTR.CAPTURE_ONCE))
  self:add_property("input_target_instr", renoise.Document.ObservableNumber(PhraseMate.TARGET_INSTR.NEW))
  self:add_property("input_loop_phrases", renoise.Document.ObservableBoolean(false))
  self:add_property("input_create_keymappings", renoise.Document.ObservableBoolean(true))
  self:add_property("input_keymap_range", renoise.Document.ObservableNumber(1))
  self:add_property("input_keymap_offset", renoise.Document.ObservableNumber(0))
  self:add_property("process_slice_mode", renoise.Document.ObservableNumber(PhraseMate.SLICE_MODE.PATTERN))

  -- write (output) options
  self:add_property("anchor_to_selection", renoise.Document.ObservableBoolean(true))
  self:add_property("cont_paste", renoise.Document.ObservableBoolean(true))
  self:add_property("skip_muted", renoise.Document.ObservableBoolean(true))
  self:add_property("expand_columns", renoise.Document.ObservableBoolean(true))
  self:add_property("expand_subcolumns", renoise.Document.ObservableBoolean(true))
  self:add_property("mix_paste", renoise.Document.ObservableBoolean(false))

  -- batch options

  -- preset options

  -- realtime options
  self:add_property("zxx_mode", renoise.Document.ObservableBoolean(false))

end
