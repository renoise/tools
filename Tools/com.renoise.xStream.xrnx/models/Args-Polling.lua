--[[============================================================================
Args-Polling.lua
============================================================================]]--

return {
arguments = {
  {
      name = "instr_idx",
      value = 1,
      properties = {
          min = 1,
          quant = 1,
          max = 255,
          zero_based = true,
          display_as_hex = true,
      },
      bind = "rns.selected_instrument_index_observable",
      description = "Specify the instrument number",
  },
  {
      poll = "rns.selected_note_column_index",
      name = "note_col_idx",
      value = 1,
      properties = {
          min = 0,
          quant = 1,
          max = 12,
      },
      description = "Tracking the selected note-column via polling",
  },
},
presets = {
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- Using polling for non-observable values
-------------------------------------------------------------------------------

-- In another example (API Binding.lua), it was demonstrated how you can 
-- attach arguments to observable properties in the Renoise API via binding. 
-- But what if the value isn't observable? 

-- The answer is to 'poll' the values. This basically works the same as bind,
-- but is implemented in a slightly different way: instead of recieving 
-- instant notifications when the value has changed, we are instead polling
-- the value ourselves, updating the argument when the source has changed. 

-- In this example, we are polling the note-column index...open the model
-- definition (reveal_location) to see how the polling can be specified

xline.note_columns = EMPTY_NOTE_COLUMNS

xline.note_columns[args.note_col_idx] = {
  note_value = math.random(36,60),
  instrument_value = args.instr_idx,
}  













]],
}