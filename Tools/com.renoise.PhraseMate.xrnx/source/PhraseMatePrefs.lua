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

  -- tool/ui options
  --self:add_property("active_tab_index",renoise.Document.ObservableNumber(PhraseMateUI.TABS.COLLECT))
  self:add_property("active_tab_index",renoise.Document.ObservableNumber(1))
  self:add_property("autostart", renoise.Document.ObservableBoolean(false))
  self:add_property("autostart_hidden", renoise.Document.ObservableBoolean(false))
  self:add_property("output_show_collection_report", renoise.Document.ObservableBoolean(true))
  self:add_property("input_show_collection_panel", renoise.Document.ObservableBoolean(false))
  --self:add_property("input_show_properties_panel", renoise.Document.ObservableBoolean(false))
  self:add_property("preset_show_export_options", renoise.Document.ObservableBoolean(false))

  -- 'new' options (formerly input)
  self:add_property("create_keymappings", renoise.Document.ObservableBoolean(false))
  self:add_property("create_keymap_range", renoise.Document.ObservableNumber(1))
  self:add_property("create_keymap_offset", renoise.Document.ObservableNumber(0))

  -- collect/input options
  self:add_property("input_scope", renoise.Document.ObservableNumber(PhraseMate.INPUT_SCOPE.SELECTION_IN_PATTERN))
  self:add_property("input_include_empty_phrases", renoise.Document.ObservableBoolean(true))
  self:add_property("input_include_duplicate_phrases", renoise.Document.ObservableBoolean(true))
  self:add_property("input_replace_collected", renoise.Document.ObservableBoolean(false))
  self:add_property("input_source_instr", renoise.Document.ObservableNumber(PhraseMate.SOURCE_INSTR.CAPTURE_ONCE))
  self:add_property("input_target_instr", renoise.Document.ObservableNumber(PhraseMate.TARGET_INSTR.NEW))
  self:add_property("input_loop_phrases", renoise.Document.ObservableBoolean(false))
  self:add_property("process_slice_mode", renoise.Document.ObservableNumber(PhraseMate.SLICE_MODE.PATTERN))

  -- write/output options
  --self:add_property("output_use_note_column", renoise.Document.ObservableBoolean(false))
  self:add_property("output_mode", renoise.Document.ObservableNumber(PhraseMate.OUTPUT_SOURCE.SELECTED))
  self:add_property("output_show_settings", renoise.Document.ObservableBoolean(false))
  self:add_property("anchor_to_selection", renoise.Document.ObservableBoolean(true))
  self:add_property("cont_paste", renoise.Document.ObservableBoolean(true))
  self:add_property("skip_muted", renoise.Document.ObservableBoolean(true))
  self:add_property("expand_columns", renoise.Document.ObservableBoolean(true))
  self:add_property("expand_subcolumns", renoise.Document.ObservableBoolean(true))
  self:add_property("output_insert_zxx", renoise.Document.ObservableBoolean(true))

  self:add_property("mix_paste", renoise.Document.ObservableBoolean(false))
  self:add_property("use_custom_note", renoise.Document.ObservableBoolean(false))
  self:add_property("custom_note", renoise.Document.ObservableNumber(48))

  -- realtime options
  self:add_property("zxx_mode", renoise.Document.ObservableBoolean(false))
  self:add_property("zxx_prefer_local", renoise.Document.ObservableBoolean(false))

  -- props/batch options
  self:add_property("props_batch_apply", renoise.Document.ObservableBoolean(false))
  self:add_property("property_name", renoise.Document.ObservableString("lpb"))

  -- preset options
  self:add_property("output_folder", renoise.Document.ObservableString(""))
  self:add_property("use_instr_subfolder", renoise.Document.ObservableBoolean(true))
  self:add_property("prefix_with_index", renoise.Document.ObservableBoolean(false))
  self:add_property("overwrite_on_export", renoise.Document.ObservableBoolean(false))

  -- smart write options
  self:add_property("use_exported_phrases", renoise.Document.ObservableBoolean(false))

end
