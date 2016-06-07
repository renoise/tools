--[[===========================================================================
Args-Polling.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "instr_idx",
      ["linked"] = false,
      ["value"] = 1,
      ["properties"] = {
          ["min"] = 1,
          ["max"] = 255,
          ["display_as"] = "hex",
          ["zero_based"] = true,
      },
      ["bind"] = "rns.selected_instrument_index_observable",
      ["description"] = "Specify the instrument number",
  },
  {
      ["poll"] = "rns.selected_note_column_index",
      ["locked"] = false,
      ["name"] = "note_col_idx",
      ["linked"] = false,
      ["value"] = 1,
      ["properties"] = {
          ["min"] = 0,
          ["display_as"] = "integer",
          ["max"] = 12,
      },
      ["description"] = "Tracking the selected note-column via polling",
  },
},
presets = {
},
data = {
},
events = {
},
options = {
 color = 0x60AACA,
},
callback = [[
-------------------------------------------------------------------------------
-- Polling (non-observable) properties in Renoise 
-- In the example 'API Binding.lua', it was demonstrated how you can 
-- attach arguments to observable properties in the Renoise API via binding. 
-- But what if the value isn't observable? The answer is to 'poll' the value. 
-- This basically works the same as bind, but instead of recieving 
-- notifications when the value has changed, we are instead polling the 
-- value ourselves (case in point: the 'note_col_idx' argument)
-------------------------------------------------------------------------------
xline.note_columns = EMPTY_NOTE_COLUMNS
xline.note_columns[args.note_col_idx] = {
  note_value = math.random(36,60),
  instrument_value = args.instr_idx,
}
]],
}