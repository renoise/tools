--[[============================================================================
ArgsPolling.lua
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
      value = 2,
      properties = {
          min = 0,
          quant = 1,
          max = 12,
      },
      description = "Tracking the selected note-column via polling",
  },
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- Using polling for non-observable values
-- (output to selected note column)
-------------------------------------------------------------------------------

-- In another example (ArgsBinding.lua), it was demonstrated how you can 
-- attach arguments to observable properties in the Renoise API via binding. 
-- But what if the value doesn't come with an observable? 

-- The answer is to 'poll' the values. This basically works the same as bind,
-- but is implemented in a slightly different way: instead of recieving 
-- instant notifications when the value has changed, we are instead polling
-- the value ourselves, updating the argument value as values change. 

-- In this example, we are polling the non-observable note-column index,
-- directing our output into that note column. 

line.note_columns[args.note_col_idx] = {
  note_value = math.random(36,60),
  instrument_value = args.instr_idx,
}  


]],
}